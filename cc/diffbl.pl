#!ccperl

=pod

=head1 NAME $RCSfile: diffbl.pl,v $

GUI DiffBL

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.7 $

=item Created:

Mon Oct 25 11:10:47 PDT 2008

=item Modified:

$Date: 2011/08/31 21:57:06 $

=back

=head1 SYNOPSIS

 Usage cqperl diffbl.pl: [-u|sage] [-v|erbose] [-d|ebug]
                         [-[baseline1|bl1] <bl1>]
                         [-[baseline2|bl2] <bl2>]
                         [-p|vob <pvob>]

 Where:
   -u|sage:      Displays usage
   -ve|rbose:    Be verbose
   -d|ebug:      Output debug messages
   -bl1 <bl1>    Full baseline 1 to use in the comparison
   -bl2 <bl2>    Full baseline 2 to use in the comparison
   -p|vob <pvob> Pvob to use

=head2 DESCRIPTION

This script provides a Perl/Tk GUI application to compare baselines. It provides
several benefits over IBM/Rational's graphical diffbl (cleartool diffbl -g ...).
First, it assists you in finding baselines to compare whereas diffbl -g requires
that you find the baselines yourself. When diffbl.pl is run you are presented
with a GUI that you can use to find baselines by either using the dropdown to
select pvobs, streams and ultimately baselines. You can also simply type part
the name and diffbl.pl will narrow down the list of pvobs, streams or baselines
in the drop down. This allows you to easily find the baselines you wish to
compare.

Additionally, IBM/Rational's diffbl -g -version often shows extremely long, but
technically accurate version extended pathnames where the user thinks more along
the lines of "path to element in a vob" only. diffbl.pl shows shorter, more
easily comprehenable pathnames. diffbl.pl also shows only the latest version of
the element. Thus if foo.c changed with version 3, 4 and 5 then you see just
foo.c and it represents foo.c version 5.

Finally, diffbl.pl provides a way to save the list of elements that have changed
in a file.

diffbl.pl also provides right click menu options to easily show the elements
properties, compare to previous, show the version tree and history of the
element.

=cut

use strict;
use warnings;

use FindBin;
use Cwd;
use Getopt::Long;

use lib "$FindBin::Bin/../CCDB/lib", "$FindBin::Bin/../lib";

use DiffBLUI;
use Display;
use Utils;
use OSDep;

use Clearcase;
use Clearcase::View;

$DiffBLUI::SELECTED{pvob} = $ENV{pvob} 
                          ? Clearcase::vobname ($ENV{pvob})
                          : '8800_projects';

our $view;
my $currentStream;

my ($bl1, $bl2);

END {
  $view->remove
    if $view;
} # END

# Should this be moved to Clearcase.pm?
sub ccerror ($$@) {
  my ($msg, $status, @output) = @_;

  Tkerror join ("\n", "$msg (Status: $status)", "\n", @output);

  exit $status;
} # ccerror

sub mkview () {
  my $user  = $ARCH eq 'windows' ? $ENV{USERNAME} : $ENV{USER};

  my $viewname = "${user}_$FindBin::Script";

  Tkmsg "Creating a view to work in", -1;

  my $newView = Clearcase::View->new ($viewname);

  # If the streams have changed then we need to recreate the view.
  $currentStream ||= $DiffBLUI::SELECTED{stream};

  if ($currentStream ne $DiffBLUI::SELECTED{stream}) {
    $newView->remove;
    $currentStream = $DiffBLUI::SELECTED{stream};
  } # if

  # The create method needs to support additional parameters such as -stream so
  # we have to do this by hand right now...
  my ($status, @output) = 
    $Clearcase::CC->execute (
      "mkview -tag $viewname -stream $DiffBLUI::SELECTED{stream}\@" .
      "$Clearcase::VOBTAG_PREFIX$DiffBLUI::SELECTED{pvob} -stgloc -auto"
    );

  unless (grep {/already exists/} @output) {
    if ($status) {
      ccerror ("Unable to create view $viewname", $status, @output);
    } # if
  } # unless

  $newView->updateViewInfo;

  # Start the view
  ($status, @output) = $newView->start;

  ccerror ('Unable startview ' . $newView->tag, $status, @output)
    if $status;

  Tkmsg 'Done';

  return $newView;
} # mkview

sub compareBaselines () {
  unless ($DiffBLUI::SELECTED{pvob}) {
    Tkerror 'Project Vob must be selected';
    return;
  } # unless

  unless ($DiffBLUI::SELECTED{fromBaseline}) {
    Tkerror 'From baseline must be selected';
    return;
  } # unless

  unless ($DiffBLUI::SELECTED{toBaseline}) {
    Tkerror 'To baseline must be selected';
    return;
  } # unless

  DiffBLUI::busy;
  
  if ($DiffBLUI::MODE eq 'versions') {
    $DiffBLUI::integrationActivitiesCheck->configure (-state => 'disable');
  } else {
    $DiffBLUI::integrationActivitiesCheck->configure (-state => 'normal');
  }
  
  # Create a view to work in.
  $view = mkview;

  # Get into the view context 
  my $view_context = $Clearcase::VIEWTAG_PREFIX . '/' . $view->tag;
  my $cwd          = getcwd;

  # For my Cygwin environment - translate that path back into a Windows path
  if ($ARCH eq 'cygwin') {
    my @cwd = `cygpath -w $cwd`;
    chomp @cwd;

    $cwd = $cwd[0];
  } # if

  my ($status, @output) = $Clearcase::CC->execute ("cd \"$view_context\"");

  ccerror "Unable to set view context to $view_context", $status, @output
    if $status;

  Tkmsg 'Comparing baselines (This may take a while)', -1;
  
  %DiffBLUI::LINES= ();

  my $cmd  = "diffbl -$DiffBLUI::MODE ";
     $cmd .= $DiffBLUI::SELECTED{fromBaseline};
     $cmd .= "\@$Clearcase::VOBTAG_PREFIX$DiffBLUI::SELECTED{pvob} "; 
     $cmd .= $DiffBLUI::SELECTED{toBaseline};
     $cmd .= "\@$Clearcase::VOBTAG_PREFIX$DiffBLUI::SELECTED{pvob}";

  ($status, @output) = $Clearcase::CC->execute ($cmd);

  ccerror "Unable to perform command $cmd", $status, @output
    if $status;

  Tkmsg 'Done';
  
  my $viewtag = $Clearcase::VIEWTAG_PREFIX . '/' . $view->tag;

  foreach (@output) {
    # Skip lines that don't have either <<, >>, <- or -> at the beginning
    next unless /^(\<\-|\>\>|\<\<|\-\>)\s/;

    if ($DiffBLUI::MODE eq 'activities') {
      if (/\W+\s+(.*)\@/) {
        $DiffBLUI::LINES{$1} = $1;
      } # if
    } else {
      # Change those silly '\'s -> '/'s 
      s/\\/\//g;
  
      # Extract the pathname and strip off the version. Note we use a hash here
      # to get uniqueness based on the element name and only store the last 
      # version checked in. It is very possible, for example, that there is foo
      # versions 1, 2 and 3 but we want to more simply just report that foo 
      # changed - not that foo changed 3 times.
      if (/\W+\s+(.*)$Clearcase::SFX/) {
        my $elementName = $1;

        # Remove view path and tagname from $elementName
        $elementName =~ s/$viewtag//;

        $DiffBLUI::LINES{$elementName} = $elementName;
      } # if
    } # if
  } # foreach

  ($status, @output) = $Clearcase::CC->execute ("cd \"$cwd\"");

  ccerror "Unable to set view context to $cwd", $status, @output
    if $status;

  displayLines;
  
  DiffBLUI::unbusy;

  Tkmsg 'Done', 1;
  
  return;
} # compareBaselines

# Main
GetOptions (
  'usage'           => sub { Usage },
  'verbose'         => sub { set_verbose },
  'debug'           => sub { set_debug },
  'baseline1|bl1=s' => \$bl1,
  'baseline2|bl2=s' => \$bl2,
  'pvob=s'          => \$DiffBLUI::SELECTED{pvob},
) or Usage "Invalid parameter";

createUI;

=pod

=head1 CONFIGURATION AND ENVIRONMENT

DEBUG: If set then $debug is set to this level.

VERBOSE: If set then $verbose is set to this level.

TRACE: If set then $trace is set to this level.

=head1 DEPENDENCIES

=head2 Perl Modules

L<Cwd>

L<FindBin>

L<Getopt::Long|Getopt::Long>

=head2 ClearSCM Perl Modules

=begin man 

 Clearcase
 Clearcase::View
 DiffBLUI
 Display
 OSDep
 Utils

=end man

=begin html

<blockquote>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Clearcase.pm">Clearcase</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Clearcase/View.pm">Clearcase::View</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=cc/DiffBLUI.pm">DiffBLUI</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Display.pm">Display</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/OSDep.pm">OSDep</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Utils.pm">Utils</a><br>
</blockquote>

=end html

=head1 BUGS AND LIMITATIONS

There are no known bugs in this script

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, ClearSCM, Inc. All rights reserved.

=cut
