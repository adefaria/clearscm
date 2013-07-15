#!/usr/bin/perl

=pod

=head1 NAME $RCSfile: Element.pl,v $

This trigger will update CCDB when element versions are added or removed or 
otherwise changed. The intent of this trigger is to keep CCDB's changeset table
up to date with respect to the element.

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.6 $

=item Created:

Fri Mar 11 17:45:57 PST 2011

=item Modified:

$Date: 2011/04/02 00:34:01 $

=back

=head1 DESCRIPTION

This trigger will update the CCDB when element versions are added or removed. It
is implemented as a post operation trigger on the checkin, checkout, lnname
and rmelem as well as a pre operation trigger on checkin, uncheckout and rmver.
This is because Clearcase creates a version that contains the string 
"CHECKEDOUT" in order to list it in the change set. Thus we add it to CCDB. 
However when a check in occurs for this element we need to remove the
"CHECKEDOUT" record and add the newly versioned version.

Also, lnname is trapped to handle when elments are moved, either through the
cleartool move command or in the odd circumstance of orphaning an element. You
can orphan an element in various ways. For example, if you check out a
directory, add an element to source control (mkelem) then cancel the directory
checkout there is no place for this new element to go! It's orphaned. In such
cases Clearcase will move the element to the vobs lost+found directory, 
attaching the element's oid to the end of the element name.

This trigger should be attached to all UCM component vobs (i.e. vobs that have
UCM components but not pvobs) that you wish CCDB to monitor. If using
mktriggers.pl the triggers defintion are:

 Trigger:        CCDB_ELEMENT_PRE
   Description:  Updates CCDB when an element's version is changed
   Type:         -element -all
   Opkinds:      -preop checkin,uncheckout,rmver
   ScriptEngine: Perl
   Script:       Element.pl
   Vobs:         base
 EndTrigger 
 
 Trigger:        CCDB_ELEMENT_POST
   Description:  Updates CCDB when an element's version is changed
   Type:         -element -all
   Opkinds:      -postop checkin,checkout,lnname,rmelem
   ScriptEngine: Perl
   Script:       Element.pl
   Vobs:         base
 EndTrigger

=cut

use strict;
use warnings;

use FindBin;
use File::Basename;
use Data::Dumper;
  
$Data::Dumper::Indent = 0;

use lib $FindBin::Bin, "$FindBin::Bin/../lib", "$FindBin::Bin/../../lib";

use TriggerUtils;
use CCDBService;

# I would like to use Clearcase but doing so causes a problem when the trigger
# is run from Clearcase Explorer - something about my use of open3 :-(

my $VERSION  = '$Revision: 1.6 $';
  ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);

triglog 'Starting trigger';

my ($activity, $pvob);

if ($ENV{CLEARCASE_ACTIVITY}) {
  ($activity, $pvob) = split /\@/, $ENV{CLEARCASE_ACTIVITY};

  trigdie 'Activity name not known', 1
    unless $activity;

  trigdie 'Pvob name not known', 1
    unless $pvob;
  
  $pvob = vobname $pvob;
} # if

my ($elementName) = 
  split /$ENV{CLEARCASE_XN_SFX}/, $ENV{CLEARCASE_XPN};
  
my ($cmd, $status, @output, $currVersion, $prevVersion);

unless ($ENV{CLEARCASE_OP_KIND} eq 'rmelem') {
  triglog "Getting current version for $elementName";
  
 # Get the current, real version using describe;
  $cmd = "describe -fmt \"%Vn\" $elementName";

  @output = `cleartool $cmd`; chomp @output;
  $status = $?;

  trigdie "Unable to execute $cmd (Status: $status)\n"
        . join ("\n", @output), $status
    if $status;
    
  $output[0] =~ s/\\/\//g;
  
  $currVersion = $output[0];
  
  triglog "currVersion = $currVersion";
    
  triglog "Getting previous version for $elementName";

  $cmd = "describe -fmt \"%PVn\" $elementName";

  @output = `cleartool $cmd`; chomp @output;
  $status = $?;

  trigdie "Unable to execute $cmd\n"
        . join ("\n", @output), $status
    if $status;
  
  $output[0] ||= '';  

  $output[0] =~ s/\\/\//g;
  
  $prevVersion = $output[0];

  triglog "prevVersion = $prevVersion";
} # unless

# Flip '\' -> '/'
$elementName =~ s/\\/\//g;

# Remove any trailing '/' or '/.' in $elementName
$elementName =~ s/(.*)\/\.*$/$1/;

# Collapse any '/./' -> '/'
$elementName =~ s/\/\.\//\//g;

# Remove VIEWTAG_PREFIX
$elementName = removeViewTag $elementName;

triglog "elementName: $elementName";

my $CCDBService = CCDBService->new;

trigdie 'Unable to connect to CCDBService', 1
  unless $CCDBService->connectToServer;
  
my ($err, $msg, $request);

triglog "CLEARCASE_OP_KIND: $ENV{CLEARCASE_OP_KIND}";

if ($ENV{CLEARCASE_OP_KIND} eq 'checkin' or
    $ENV{CLEARCASE_OP_KIND} eq 'checkout') {
  triglog "Processing $ENV{CLEARCASE_OP_KIND}";

  # If checking in a version then we used to have a "CHECKEDOUT" version. We
  # need to remove that if found first. Unfortunately a checkin can fail so
  # we'll scribble on the filesystem to tell the postop to remove it.
  if ($ENV{CLEARCASE_OP_KIND}     eq 'checkin' and
      $ENV{CLEARCASE_TRTYPE_KIND} eq 'pre-operation') {
    exit 0
      if $currVersion !~ /CHECKEDOUT/;
      
    # Create a file ending in .CHECKEDOUT that indicates the version of the of
    # the previously checked out element that we need to remove from the 
    # database in the postop. However elements can be files or directories.
    # For a directory create a ".CHECKEDOUT" file in the directory element.
    my $filename  = $TriggerUtils::VIEWTAG_PREFIX;
       $filename .= "$ENV{CLEARCASE_VIEW_TAG}$elementName";
       $filename .= '/' if -d $filename;
       $filename .= '.CHECKEDOUT';
    
    open my $file, '>', $filename
      or trigdie "Unable to open $filename for writing - $!", 1;
    
    print $file "$currVersion\n";
    
    close $file;
    
    exit 0;
  } else {
    # Look for CHECKEDOUT file to indicate we must remove that from the database
    my $checkedOutFile  = $TriggerUtils::VIEWTAG_PREFIX;
       $checkedOutFile .= "$ENV{CLEARCASE_VIEW_TAG}$elementName";
       $checkedOutFile .= '/' if -d $checkedOutFile;
       $checkedOutFile .= '.CHECKEDOUT';
    
    if (-e $checkedOutFile) {
      open my $file, '<', $checkedOutFile
        or trigdie "Unable to open $checkedOutFile - $!", 1;
        
      my $version = <$file>; chomp $version;
      
      close $file;
      
      unlink $checkedOutFile;
      
      $request = "DeleteChangeset $activity $elementName $version $pvob";

      triglog "Executing request: $request";
            
      ($err, $msg) = $CCDBService->execute ($request);

      trigdie "Unable to execute request: $request\n"
            . join ("\n", @$msg), $err
        if $err;
    } # if
  
    # Add this to the changeset
    my $changeset = Dumper {
      activity => $activity,
      element  => $elementName,
      version  => $currVersion,
      pvob     => $pvob,
    };
  
    # Squeeze out extra spaces
    $changeset =~ s/ = /=/g;
    $changeset =~ s/ => /=>/g;
  
    $request = "AddChangeset $changeset";
  } # if
} elsif ($ENV{CLEARCASE_OP_KIND} eq 'uncheckout' or
         $ENV{CLEARCASE_OP_KIND} eq 'rmver') {
  triglog "Processing $ENV{CLEARCASE_OP_KIND}";
  
  $request = "DeleteChangeset $activity $elementName $currVersion $pvob";
} elsif ($ENV{CLEARCASE_OP_KIND} eq 'lnname') {
  triglog "Processing $ENV{CLEARCASE_OP_KIND}";
  
  # Exit if the previous operation (CLEARCASE_POP_KIND) was not an rmname. The
  # user could just be doing an lnname. We want to capture only moves which, by
  # definition need to be an rmname followed by an lnname. (What is an lnname
  # followed by an rmname?!? The mktrtype man page is confusing on this...)
  exit 0
    if $ENV{CLEARCASE_POP_KIND} ne 'rmname';

  # Surprisingly Clearcase does not set CLEARCASE_ACTIVITY when a move is done
  # in a UCM context! This may be because a move in a UCM context can only be
  # done within the context of a view set to an activity. So let's get our
  # current activity...
  my $cmd    = 'lsactivity -cact -fmt "%Xn"';
  my @output = `cleartool $cmd`;
  my $status = $?;
  
  trigdie "Unable to execute $cmd (Status: $status)\n"
        . join ("\n", @output), $status
    if $status;
  
  my ($activity, $pvob) = split /\@/, $output[0];
  
  # Remove 'activity:' from $activity
  $activity = substr $activity, 9;
  
  # Fix $pvob
  $pvob = vobname $pvob;
  
  # Fix $ENV{CLEARCASE_PN2}
  my $oldName = $ENV{CLEARCASE_PN2};
  
  # Switch "\"'s -> "/"'s
  $oldName =~ s/\\/\//g;
  
  # Remove the viewtag
  $oldName = removeViewTag $oldName;
    
  # Now update CCDB to reflect the move
  my $update = Dumper {
    element => $elementName,
  };
  
  # Squeeze out extra spaces
  $update =~ s/ = /=/g;
  $update =~ s/ => /=>/g;
  
  triglog "Updating $oldName -> $elementName";
  
  $request = "UpdateChangeset $activity $oldName % $pvob $update";
} elsif ($ENV{CLEARCASE_OP_KIND} eq 'rmelem') {
  # If we are doing rmelem then remove all traces of this element
  triglog "Processing rmelem";
  
  $request = "DeleteElementAll $elementName";
} # if

triglog "Executing request: $request";

($err, $msg) = $CCDBService->execute ($request);

trigdie "Unable to execute request: $request\n" 
      . join ("\n", @$msg), $err
  if $err;
  
$CCDBService->disconnectFromServer;

triglog 'Ending trigger';

exit 0;

=pod

=head1 CONFIGURATION AND ENVIRONMENT

DEBUG: If set then $debug is set to this level.

VERBOSE: If set then $verbose is set to this level.

TRACE: If set then $trace is set to this level.

=head1 DEPENDENCIES

=head2 Perl Modules

L<FindBin>

L<Data::Dumper|Data::Dumper>

=head2 ClearSCM Perl Modules

=begin man 

 CCDBSerivce
 TriggerUtils

=end man

=begin html

<blockquote>
<a href="http://clearscm.com/php/cvs_man.php?file=CCDB/lib/CCDBService.pm">CCDBService</a><br>
<a href="http://clearscm.com/php/cvs_man.php?file=CCDB/triggers/TriggerUtils.pm">TriggerUtils</a><br>
</blockquote>

=end html

=head1 BUGS AND LIMITATIONS

There are no known bugs in this script

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011, ClearSCM, Inc. All rights reserved.

=cut