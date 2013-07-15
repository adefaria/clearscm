#!/usr/bin/perl
################################################################################
#
# File:         $RCSfile: BinMerge.pm,v $
# Revision:	$Revision: 1.4 $
# Description:  This module will perform a merge checking for any merge
#		conflicts and grouping them at the end. This allows the
#		majority of a large merge to happen and the user can resolve
#		the conflicts at a later time.
#
#		This module also assists in performing binary merges for the
#		common case. With a binary merge one cannot easily merge the
#		binary code. Most often it's a sitatution where the user will
#		either accept the source or the destination binary file as
#		a whole. In cases where there is only a 2 way merge, this
#		script offers the user the choice to accept 1 binary file
#		or the other or to abort this binary merge. Binary merges
#		conflicts greater than 2 way are not handled.
#
#		This was made into a module so that it could be easily called
#		from UCMCustom.pl. There is also a corresponding bin_merge
#		script which essentially calls this module
#
# Dependencies: This module depends on PerlTk. As such it must be run
#		from ccperl or a Perl that has the PerlTk module
#		installed. Additionally it uses the Clearcase
#		cleartool command which is assumed to be in PATH.
# Author:       Andrew@ClearSCM.com
# Created:      Thu Nov  3 10:55:51 PST 2005
# Modified:	$Date: 2011/03/10 23:47:31 $
# Language:     perl
#
# (c) Copyright 2005, ClearSCM, Inc. all rights reserved
#
################################################################################
package BinMerge;

use strict;
use warnings;

use base 'Exporter';
use File::Spec;
use Tk;
use Tk::Dialog;
use OSDep;

our @EXPORT = qw (
  Merge
  Rebase
);

our ($me);

BEGIN {
  # Extract relative path and basename from script name.
  $0 =~ /(.*)[\/\\](.*)/;

  $me = (!defined $2) ? $0 : $2;
  $me =~ s/\.pl$//;

  # Remove .pl for Perl scripts that have that extension
  $me         =~ s/\.pl$//;
} # BEGIN

  use Display;
  use Logger;
  use OSDep;

  my $version = "1.0";
  my $user = $ENV {USERNAME};

  my $main;
  my $selection_file = "$me.selection.$$";

  sub ReadFile {
    my $filename = shift;

    # Sometimes people foolishly undef $/
    local $/ = "\n";

    open my $file, '<', $filename
      or error "Unable to open $filename ($!)", 1;

    my @lines = <$file>;

    close $file;
    
    my @cleansed_lines;

    foreach (@lines) {
      chomp;
      chop if /\r/;
      push @cleansed_lines, $_ if !/^#/; # Discard comment lines
    } # foreach

    return @cleansed_lines;
  } # ReadFile

  sub Error {
    my $msg = shift;

    my $err = $main->Dialog (
      -title   => "Error",
      -text    => $msg,
      -buttons => [ "OK" ]
    );

    $err->Show;
    
    return;
  } # Error

  sub CheckSelection {
    my $list = shift;

    my @entries = $list->curselection;

    if (scalar @entries == 0) {
      Error "Nothing selected!";
      return;
    } # if

    my $selected = $list->get ($entries [0]);

    # Write selection out to file and exit
    open my $file, '>', $selection_file
      or die "Unable to open $selection_file\n";

    print $file "$selected\n";

    close $file;

    # Close prompt window
    $main->destroy;
    
    return;
  } # CheckSelection

  sub Help {
    my $text;

    $text  = "A merge conflict has been detected between two binary files. ";
    $text .= "Please pick the version that you want to be the result of this ";
    $text .= "merge.\n\nNote you can pick any of these versions and the result ";
    $text .= "will be that that version will be considered the new version ";
    $text .= "overwriting the previous version.\n\nIf this is not what you want ";
    $text .= "then select the Cancel button and regenerate this binary file ";
    $text .= "so that it is the result of what you want for this merge.\n\n";
    $text .= "Copyright ? 2005 - All rights reserved\n";
    $text .= "Andrew DeFaria <Andrew\@ClearSCM.com>";

    my $desc = $main->Dialog (
      -title   => "Help",
      -text    => $text,
      -buttons => [ "OK" ]
    );

    $desc->Show;
    
    return;
  } # Help

  sub Cancel {
    $main->destroy;
    
    return;
  } # Cancel

  sub VersionTree {
    my $file = shift;

    my $cmd =  "cleartool lsvtree -graphical $file";

    if ($^O =~ /mswin|cygwin/i) {
      system "start /b $cmd";
    } else {
      my $pid = fork;

      return if $pid;

      system $cmd;
      exit;
    } # if
    
    return;
  } # VersionTree

  # Create a ListBox widget in $parent, dynamically sizing it to the length of 
  # the longest entry in @list.
  sub CreateList {
    my ($parent, @list) = @_;

    my $list = $parent->Scrolled ("Listbox",
      -scrollbars => "osoe",
      -width      => 70,
      -height     => 5,
    )->pack;

    # Insert entries from @list into the new ListBox, $list
    foreach (@list) {
      $list->insert ("end", $_);
    } # foreach

    $list->pack;

    return $list;
  } # CreateList

  sub CreateButtons {
    my ($parent, $list, $file) = @_;
    my $one   = $parent->Frame->pack (-side => "left", -pady => 2, -padx => 2);
    my $two   = $parent->Frame->pack (-side => "left", -pady => 2, -padx => 2);
    my $three = $parent->Frame->pack (-side => "left", -pady => 2, -padx => 2);
    my $four  = $parent->Frame->pack (-side => "left", -pady => 2, -padx => 2);

    my $ok = $one->Button (
      -text    => "OK",
      -command => [ \&CheckSelection, $list ]
    )->pack;

    my $cancel = $two->Button (
      -text    => "Cancel",
      -command => [ \&Cancel ]
    )->pack;

    my $help = $three->Button (
      -text    => "Help",
      -command => \&Help
    )->pack;

    my $vtree = $four->Button (
      -text    => "Version Tree",
      -command => [ \&VersionTree, $file ]
    )->pack;
    
    return;
  } # CreateButtons

  sub PromptUser {
    my ($element, @versions) = @_;

    debug "ENTER: PromptUser";

    # Create main window
    $main = MainWindow->new;

    # Title window
    $main->title ("Resolve merge conflict for binary element");

    # Create the main window using containers
    my $top     = $main->Frame->pack (-side => "top", -fill => "x");
    my $prompt  = $top->Frame->pack  (-side => "left", -pady => 5, -padx => 5);
    my $list    = $main->Frame->pack (-side => "left");
    my $buttons = $list->Frame->pack (-side => "bottom");

    # Label it
    my $prompt_str = <<"END";
A binary merge conflict has been detected between two versions of

$element

Please pick the version that you want to be the result of this merge. Note you 
can pick any of these versions and the result will be that that version will be
considered the new version overwriting the previous version. If this is not what
you want then select the Cancel button here and regenerate this binary file so
that it is the result of what you want for this merge.
END

    $prompt->Message (-text => $prompt_str, -width => 500)->pack;

    my $version_list = CreateList $list, @versions;

    CreateButtons $buttons, $version_list, $element;

    # Make sure the window pops to the top
    # Trying really hard... :-)
    $main->update;
    $main->deiconify;
    $main->update;
    $main->raise;
    $main->update;
    $main->focusForce;
    $main->update;

    MainLoop;

    open my $result, '<', $selection_file
      or return;

    my @lines = <$result>;

    close $result;

    unlink $selection_file;

    if (@lines) {
      chomp $lines[0];
      return $lines[0];
    } else {
      return;
    } # if
    
    return;
  } # PromptUser

  # The merging of directories could, in theory, unearth other elements inside
  # those directories thus causing further merging. Here we keep merging
  # directories until there are no directories to merge.
  sub MergeDirectories {
    my ($log, $path, $branch) = @_;

    my $cmds = "$me.$$.cmds";
    my $cmd  = "cleartool findmerge $path -nc -type d -fversion $branch " .
      "-log $cmds -print > $NULL 2>&1";

    debug "ENTER: MergeDirectories (<log>, $path, $branch)";

    my @lines;

    while () {
      $log->msg ("Searching for directories that need merging...");

      debug "Performing: $cmd";

      my $status = $log->logcmd ($cmd);

      return $status if $status != 0;

      @lines = ReadFile $cmds;

      last if scalar @lines == 0;

      $log->msg ("Performing directory merges...");

      foreach (@lines) {
	    $log->log ($_);
        debug "Performing: $_";
        $status = $log->logcmd ($_);

        return $status if $status != 0;
      } # foreach
    } # while

    $log->msg ("All directories merged.");

    # Clean up
    unlink $cmds;

    debug "EXIT: MergeDirectories (<log>, $path, $branch)";

    return 0;
  } # MergeDirectories

  # Here we'll attempt to merge file individually using -abort. This tells
  # cleartool findmerge to only merge that which is can automatically merge. For
  # every merge failure we'll push an entry onto @merge_conflicts.
  sub MergeFiles {
    my ($log, $path, $branch) = @_;

    my $cmds = "$me.$$.cmds";
    my $cmd  = "cleartool findmerge $path -nc -type f -fversion $branch " .
      "-log $cmds -print > $NULL 2>&1";

    debug "ENTER: MergeFiles (<log>, $path, $branch)";

    $log->msg ("Merging files...");

    $log->logcmd ($cmd);

    my @lines = ReadFile $cmds;
    my @merge_conflicts;

    foreach my $file_merge_cmd (@lines) {
      my %merge_conflict;

      my $file_to_merge;
      
      if ($file_merge_cmd =~ /cleartool findmerge (.*) -fver/) {
        $file_to_merge = $1;
      } # if

      # Add -abort to this variable, which use for execution. We keep
      # the old variable to put in the return array.
      my $file_merge_cmd_abort = "$file_merge_cmd -abort 2>&1";

      debug "Performing $file_merge_cmd_abort";
      $log->msg ($file_merge_cmd_abort);

      # Capture the output from the merge and parse it. If there's
      # just a merge conflict then "*** No Automatic Decision
      # possible" and "merge: Warning: *** Aborting.." are present in
      # the output. If the merge fails because of binary files then
      # nothing is in the output. Either way, if Clearcase is unable
      # to merge the status returned is non zero. We can then
      # differentiate between resolvable merge conflicts and
      # unresolvable merge conflicts (binary files). Format
      # %merge_conflicts to indicate the type and push it on
      # @merge_conflicts to return to the caller.
      #
      # Also find merges that will not work because the element is
      # checked out reserved somewhere else.
      my @output = `$file_merge_cmd_abort`;
      my $status = $?;

      # Put output in the logfile
      chomp @output;
      foreach (@output) {
	$log->log ($_);
      } # foreach

      if ($status == 0) {
        # If $status eq 0 then the merge was successful! Next merge!
        $log->msg ("Auto merged $file_to_merge");
        next;
      } # if

      # Check for errors
      my @errors = grep {/\*\*\* /} @output;
      my @reserved = grep {/is checked out reserved/} @output;

      if (scalar @reserved > 0) {
        if ($reserved [0] =~ /view (\S+)\./) {
	      $log->err ("Unable to merge $file_to_merge because it is checked out reserved in the view $1");
        } # if
        
        next;
      } # if

      $merge_conflict {cmd}  = $file_merge_cmd;

      # Differentiate between binary merge conflicts and non binary
      # merge conflicts
      if (scalar @errors > 0) {
        $merge_conflict {type} = "regular";
        $log->msg ("Delaying regular conflicting merge for " . $file_to_merge);
      } else {
        $log->msg ("Delaying binary merge for " . $file_to_merge);
        $merge_conflict {type} = "binary";
      } # if

      push @merge_conflicts, \%merge_conflict;
    } # foreach

    my $nbr_conflicts = scalar @merge_conflicts;

    if ($nbr_conflicts == 0) {
      $log->msg ("All files merged");
    } elsif ($nbr_conflicts == 1) {
      $log->msg ("$nbr_conflicts merge conflict found");
    } else {
      $log->msg ("$nbr_conflicts merge conflicts found");
    } # if

    # Clean up
    unlink $cmds;

    debug "EXIT: MergeFiles (<log>, $path, $branch)";

    return @merge_conflicts;
  } # MergeFiles

  sub GetRebaseDirs {
    my $log      = shift;
    my $baseline = shift;

    $log->msg ("Finding directories that need rebasing...");

    my $cmd = "cleartool rebase -long -preview ";

    if (!defined $baseline) {
      $cmd .= "-recommended";
    } else {
      $cmd .= "-baseline $baseline";
    } # if

    $log->msg ("Performing command: $cmd");

    my @output = `$cmd`;
    chomp @output;

    my %rebase_dirs;

    return %rebase_dirs if $? != 0;

    # Now parse the files to be merged collecting information
    foreach (@output) {
      if (/\s*(\S*)\@\@(\S*)/) {
	    my $element = $1;
        my $ver     = $2;

        # Directories only
        next if !-d $element;

        $log->msg ("Directory Element: $element Version: $ver");
        $rebase_dirs {$element} = $ver;
      } # if
    } # foreach

    return %rebase_dirs;
  } # GetRebaseDirs

  sub GetRebaseFiles {
    my $log      = shift;
    my $baseline = shift;

    $log->msg ("Finding files that need rebasing...");

    my $cmd = "cleartool rebase -long -preview ";

    if (!defined $baseline) {
      $cmd .= "-recommended";
    } else {
      $cmd .= "-baseline $baseline";
    } # if

    $log->msg ("Performing command: $cmd");

    my @output = `$cmd`;

    return if $? != 0;

    chomp @output;

    my %rebase_files;

    # Now parse the files to be merged collecting information
    foreach (@output) {
      if (/\s*(\S*)\@\@(\S*)/) {
        my $element = $1;
        my $ver     = $2;

        # Files only
        next if !-f $element;
        
        $log->msg ("Element: $element Version: $ver");
        $rebase_files {$element} = $ver;
      } # if
    } # foreach

    return %rebase_files;
  } # GetRebaseFiles

  sub RebaseDirectories {
    my $log      = shift;
    my $baseline = shift;;

    debug "ENTER: RebaseDirectories";

    $log->msg ("Rebasing directories");

    my $rebase_status = 0;
    my %rebase_dirs;

    # Keep rebasing directories until there are no more
    while (%rebase_dirs = GetRebaseDirs $log, $baseline) {
      foreach my $element (keys %rebase_dirs) {
        # First checkout file if necessary - ignore errors
        my @output = `cleartool checkout -nc $element > $NULL 2>&1`;
        
        my $cmd = "cleartool merge -abort -to $element -version ${rebase_dirs {$element}} 2>&1";
        
        @output = `$cmd`;
        my $status = $?;
        
        # Put output in the logfile
        chomp @output;
        
        foreach (@output) {
          $log->log ($_);
        } # foreach
        
        if ($status == 0) {
          # If $status eq 0 then the merge was successful! Next merge!
          $log->msg ("Auto merged $element");
          next;
        } # if
        
        # Check for errors
        my @errors = grep {/\*\*\* /} @output;
        my @reserved = grep {/is checked out reserved/} @output;
        
        # TODO: This is broke!
        my $file_to_merge;
        if (scalar @reserved > 0) {
          if ($reserved [0] =~ /view (\S+)\./) {
            $log->err ("Unable to merge $file_to_merge because it is checked out reserved in the view $1");
            $rebase_status++;
          } # if
          
          next;
        } # if
      } # foreach
    } # while

    debug "Returning $rebase_status from RebaseDirectories";
    return $rebase_status;
  } # RebaseDirectories

  sub RebaseFiles {
    my ($log, $baseline, %rebase_elements) = @_;

    debug "ENTER: RebaseFiles";

    # TODO: This is broke too
    my @merge_conflicts;

    $log->msg ("Rebasing elements");

    foreach my $element (keys %rebase_elements) {
      # First checkout file if necessary - ignore errors
      my @output = `cleartool checkout -nc $element > $NULL 2>&1`;

      my $cmd = "cleartool merge -abort -to $element -version ${rebase_elements {$element}} 2>&1";

      @output = `$cmd`;
      my $status = $?;

      # Put output in the logfile
      chomp @output;
      foreach (@output) {
        $log->log ($_);
      } # foreach

      if ($status == 0) {
        # If $status eq 0 then the merge was successful! Next merge!
        $log->msg ("Auto merged $element");
        next;
      } # if

      # Check for errors
      my @errors = grep {/\*\*\* /} @output;
      my @reserved = grep {/is checked out reserved/} @output;

      # TODO: This is broke too
      my ($file_to_merge, $merge_conflict, %merge_conflict, @merge_conflicts);
      
      if (scalar @reserved > 0) {
        if ($reserved [0] =~ /view (\S+)\./) {
          $log->err ("Unable to merge $file_to_merge because it is checked out reserved in the view $1");
        } # if
        
        next;
      } # if

      # Differentiate between binary merge conflicts and non binary
      # merge conflicts
      if (scalar @errors > 0) {
        $merge_conflict {type} = "regular";
        $log->msg ("Delaying regular conflicting merge for " . $element);
      } else {
        $log->msg ("Delaying binary merge for " . $element);
        $merge_conflict {type} = "binary";
      } # if

      push @merge_conflicts, \%merge_conflict;
    } # foreach

    my $nbr_conflicts = scalar @merge_conflicts;

    if ($nbr_conflicts == 0) {
      $log->msg ("All files merged");
    } elsif ($nbr_conflicts == 1) {
      $log->msg ("$nbr_conflicts merge conflict found");
    } else {
      $log->msg ("$nbr_conflicts merge conflicts found");
    } # if

    debug "EXIT: RebaseFiles";

    return @merge_conflicts;
  } # RebaseFiles

  sub Rebase {
    my ($baseline, $verbose, $debug) = @_;

    if ($verbose) {
      Display::set_verbose;
      Logger::set_verbose;
    } # if

    set_debug if $debug;

    my $log = Logger->new (
      name        => "$me.$$",
      disposition => "temp",
      path        => $ENV{TMP}
    );

    $log->msg ("BinMerge (rebase) $version started at " . localtime);

    if (!defined $baseline) {
      $log->msg ("Baseline: RECOMMENDED");
    } else {
      $log->msg ("Baseline: $baseline");
    } # if

    my $rebase_status = RebaseDirectories $log, $baseline;

    my @merge_conflicts = RebaseFiles $log, $baseline;

    # more to come...
    return;
  } # Rebase

  sub Merge {
    my ($branch, $path, $verbose, $debug) = @_;

    if ($verbose) {
      Display::set_verbose;
      Logger::set_verbose;
    } # if

    set_debug if $debug;

    error "Must specify a branch" if !defined $branch;
    $path = "." if !defined $path;

    my $log = Logger->new (
      name        => "$me.$$",
      disposition => "temp",
      path        => $ENV{TMP}
    );

    $log->msg ("BinMerge $version started at " . localtime);
    my $merge_status = 0;

    $merge_status = MergeDirectories $log, $path, $branch;

    my @merge_conflicts = MergeFiles $log, $path, $branch;

    my (@binary_merge_conflicts, @text_merge_conflicts);
    my $merge_conflict;

    # Separate the bin merges from the text merges.
    while (@merge_conflicts) {
      my %merge_conflict = %{shift @merge_conflicts};

      if ($merge_conflict {type} eq "binary") {
	# Since we can't merge binary files, change -merge to
	# -print. Later we'll use the -print output to present the
	# user options...
	$merge_conflict {cmd} =~ s/ -merge / -print /;
	push @binary_merge_conflicts, $merge_conflict {cmd};
      } else {
	# For text merges we can merge but we want to merge
	# graphically.
	$merge_conflict {cmd} =~ s/ -merge / -gmerge /;
	push @text_merge_conflicts, $merge_conflict {cmd};
      } # if
    } # while;

    # Now process the text merges
    foreach my $merge_conflict (@text_merge_conflicts) {
      # Now try the merge so that diffmerge comes up allowing the user
      # to resolve the conflicts for this element.
      my $file_to_merge;
      
      if ($merge_conflict =~ /cleartool findmerge (.*) -fver/) {
         $file_to_merge = $1;
      } # if
      
      $file_to_merge =~ s/\\\\/\\/g;

      debug "Performing $merge_conflict";
      my $status = $log->logcmd ("$merge_conflict 2>&1");

      if ($status != 0) {
        $log->err ("$user did not resolve merge conflicts in $file_to_merge");
        $merge_status++;
      } else {
        $log->msg ("$user resolved conflicts in merge of $file_to_merge");
      } # if
    } # foreach

    # Now process the binary ones...
    foreach my $merge_conflict (@binary_merge_conflicts) {
      # Now try to handle the binary merge conflicts. Best we can do
      # is to present the user the with the various versions that
      # could be taken as a whole along with an option to not
      # merge. If they select a specific version then we simply draw a
      # merge arrow.

      my @selections;

      # First let's do the merge command again capturing the output
      # which has a format like:
      #
      # Needs Merge "firefox.exe" [to \main\adefaria_Andrew\CHECKEDOUT
      # from \main\Andrew_Integration\2 base \main\adefaria_Andrew\1]
      #
      # From this we'll get the $from and $to to present to the user.
      my $file_to_merge;
      
      if ($merge_conflict =~ /cleartool findmerge (.*) -fver/) {
        $file_to_merge = $1;
      } # if
      
      debug "Performing $merge_conflict";
      my @output = `$merge_conflict 2>&1`;

      my ($to, $from);
      
      if ($output [0] =~ /to (\S*) from (\S*)/) {
        $to   = $1;
        $from = $2;
      } # if
      
      push @selections, $from;
      push @selections, $to;

      my $choice = PromptUser $file_to_merge, @selections;

      if (!defined $choice) {
	$log->err ("$user aborted binary merge of $file_to_merge");
	next;
      } # if

      chomp $choice;
      # I don't know why the above doesn't remove the trailing \n so let's
      # chop it off if it exists!
      chop $choice if $choice =~ /\n/;

      my $cmd;

      # At this point the merge process has checked out the file in
      # the current view but is unable to perform the merge because
      # this is a binary file. If the user chooses the $from version
      # then they are saying that the $from version should be brought
      # into the current view and a merge arrow drawn from $from ->
      # $to.
      #
      # If, however, they choose the CHECKEDOUT version then what we
      # want to do is to cancel the current checkout and draw a merge
      # arrow from the predecessor to $to.
      if ($choice eq $from) {
        # Need to copy the $from version to the checkedout version here.
        debug "Copying $file_to_merge\@\@$choice to current view";
        open my $from, '<', "$file_to_merge\@\@$choice"
          or error "Unable to open $file_to_merge\@\@$choice", 1;
        binmode $from;

        open my $to, '>', "$file_to_merge"
          or error "Unable to open $file_to_merge\@\@$to", 2;
        binmode $to;

        while (<$from>) {
          print $to $_;
        } # while

        close $from;
        close $to;

        $log->msg ("$user chose to link from $choice -> $file_to_merge" .
               " in the current view");
        $cmd = "cleartool merge -to \"$file_to_merge\"" .
                " -ndata \"$file_to_merge\@\@$choice\"";
      } else {
        # Need to cancel the checkout then determine what version
        # Clearcase reverts to. WARNING: This might doesn't work
        # for a snapshot view.
        debug "Canceling checkout for $file_to_merge";
        @output = `cleartool unco -rm $file_to_merge 2>&1`;

        error "Unable to cancel checkout of $file_to_merge", 3 if $? != 0;

        @output = `cleartool ls -s $file_to_merge`;

        chomp $output [0];

        if ($output [0] =~ /\@\@(.*)/) {
          $choice = $1;
        } # if 
    
        debug "Drawing merge arrow from $file_to_merge\@\@$from -> $choice";
        $log->msg ("$user chose to link $file_to_merge from $from -> $choice");
	    $cmd = "cleartool merge -to \"$file_to_merge\"\@\@$choice\" -ndata \"$file_to_merge\@\@$from\"";
      } # if

      # Draw merge arrow
      my $status = $log->logcmd ($cmd);

      error "Unable to draw merge arrow ($cmd)" if $status != 0;

      $merge_status += $status;
    } # foreach

    if ($merge_status > 0) {
      $log->err ("There were problems with the merge. Please review " .
	$log->fullname . " for more infomation");
    } # if

    return $merge_status
  } # Merge

1;
