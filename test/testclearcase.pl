#!/usr/bin/env cqperl

=pod

=head1 NAME $RCSfile: testclearcase.pl,v $

Test Clearcase

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 2.1 $

=item Created:

Tue Apr 10 13:14:15 CDT 2007

=item Modified:

$Date: 2011/01/09 01:01:32 $

=back

=head1 SYNOPSIS

 Usage: testclearcase.pl: [-us|age] [-ve|rbose]
                          [-c|onfig <file>] [-b|ase] [-uc|m]

 Where:
   -v|erbose:       Display progress output
   -d|ebug:         Display debug info
   -us|age:         Display usage

   -c|onfig <file>: Config file (Default: testclearcase.conf)
   -[no]b|ase:      Perform base Clearcase tests (Default: base)
   -[no]uc|m:       Perform UCM Clearcase tests (Default: noucm)
   -[no]clean:      Cleanup after yourself (Default: clean)

=head1 DESCRIPTION  

Clearcase smoke tests. Perform simple Clearcase operations to validate that
Clearcase minimally works.

If -ucm is specified then additional UCM related tests are performed.

=cut

use strict;
use warnings;

use Cwd;
use FindBin;
use Getopt::Long;
use Term::ANSIColor qw(:constants);

use lib "$FindBin::Bin/../lib";

use Clearcase;
use Clearcase::Element;
use Clearcase::View;
use Clearcase::Views;
use Clearcase::Vob;
use Clearcase::Vobs;

use Clearcase::UCM;
use Clearcase::UCM::Activity;
use Clearcase::UCM::Baseline;
use Clearcase::UCM::Component;
use Clearcase::UCM::Folder;
use Clearcase::UCM::Project;
use Clearcase::UCM::Pvob;
use Clearcase::UCM::Stream;

use DateUtils;
use Display;
use GetConfig;
use Logger;
use OSDep;
use TimeUtils;
use Utils;

# Globals
my $VERSION = '2.1';

my (@ucmobjs, $order);

my (
  $test_vob,
  $test_view,
  $test_pvob,
  $test_folder,
  $test_project,
  $test_activity,
  $test_baseline,
  $test_component,,
  $test_devstream,
  $test_intstream,
  $test_devview,
  $test_intview,
);

my ($vbs, $vws, %default_opts, %opts);

my ($script) = ($FindBin::Script =~ /^(.*)\.pl/);

my $log = Logger->new;

# LogOpts: Log the %opts has to the log file so we can tell the options used for
# this run.
sub LogOpts() {
  $log->msg(
    "$script v$VERSION run at " 
  . YMDHM
  . ' with the following options:'
  );

  for (sort keys %opts) {
    if (ref $opts{$_} eq 'ARRAY') {
      my $name = $_;
      $log->msg("$name:\t$_") for (@{$opts{$_}});
    } else {
      $log->msg("$_:\t$opts{$_}");
    }  # if
  } # for
  
  return;
} # LogOpts

sub CreateVob($) {
  my ($tag) = @_;

  my $vobname = Clearcase::vobname $tag;

  $log->msg ("Creating vob $tag");

  my $newvob = Clearcase::Vob->new($tag);

  my ($status, @output) = $newvob->create($opts{vobhost}, "$opts{vobstore}/$vobname.vbs");

  $log->log($_) for (@output);

  return ($status, $newvob);
} # CreateVob

sub CreatePvob($) {
  my ($tag) = @_;

  my $vobname = Clearcase::vobname $tag;

  my $pvob = Clearcase::UCM::Pvob->new($tag);

  #my ($status, @output) = $pvob->create($opts{vobhost}, "$opts{vobstore}/$vobname.vbs", 'A test Pvob');
  my ($status, @output) = $pvob->create($opts{vobhost}, "$opts{vobstore}/$vobname.vbs");

  $log->log($_) for (@output);

  push @ucmobjs, $pvob unless $status;

  return ($status, $pvob);
} # CreatePvob

sub MountVob($) {
  my ($vob) = @_;

  $log->msg('Mounting vob ' . $vob->tag);

  # Create mount directory
  my ($status, @output);
  
  ($status, @output) = Execute 'mkdir -p ' . $vob->tag . ' 2>&1' unless -d $vob->tag;

  $log->log($_) for (@output);

  ($status, @output) = $vob->mount;

  $log->log($_) for (@output);

  return $status;
} # MountVob

sub DestroyVob($) {
  my ($vob) = @_;

  my ($status, @output);

  ($status, @output) = $Clearcase::CC->execute('cd');

  $log->msg('Unmounting vob ' . $vob->tag);

  ($status, @output) = $vob->umount;

  $log->msg('Removing vob ' . $vob->tag);

  ($status, @output) = $vob->remove;

  $log->log($_) for (@output);

  return $status;
} # DestroyVob

sub CreateView($) {
  my ($tag) = @_;

  $log->msg("Creating view $tag");

  my $view = Clearcase::View->new($tag);

  my ($status, @output) = $view->create($opts{viewhost}, "$opts{viewstore}/$tag.vws");

  $log->log($_) for (@output);

  return ($status, $view);
} # CreateView

sub SetView($) {
  my ($view) = @_;

  $log->msg('Setting view ' . $view->tag);

  my ($status, @output) = $view->set;

  $log->log($_) for (@output);

  return $status;
} # SetView

sub DestroyView($) {
  my ($view) = @_;

  $log->msg('Removing view ' . $view->tag);

  my ($status, @output) = $Clearcase::CC->execute('cd');

  $log->log($_) for (@output);

  chdir $ENV{HOME}
    or $log->err("Unable to chdir $ENV{HOME}", 1);

  ($status, @output) = $view->remove;

  $log->log($_) for (@output);

  return $status;
} # DestroyView

sub CreateViewPrivateFiles(@) {
  my (@elements) = @_;

  $log->msg('Creating test files');

  for (@elements) {
    my $file;

    $log->msg("Creating $_");

    open $file, '>>', $_
      or $log->err("Unable to open $_ for writing - $!", 1);

    print $file "This is file $_\n";

    close $file;
  } # for
  
  return;
} # CreateViewPrivateFiles

sub CheckOut($) {
  my ($element) = @_;

  my ($status, @output);

  if (ref $element eq 'ARRAY') {
    for (@{$element}) {
      $log->msg("Checking out $_");

      my $newElement = Clearcase::Element->new($_);

      ($status, @output) = $newElement->checkout;

      $log->log($_) for (@output);

      $log->err("Unable to check out $_", $status) if $status;
    } # for
  } else {
    $log->msg("Checking out $element");

    my $newElement = Clearcase::Element->new($element);

    ($status, @output) = $newElement->checkout;

    $log->log($_) for (@output);

    $log->err("Unable to check out $element", $status) if $status;
  } # if
  
  return;
} # CheckOut

sub CheckIn($) {
  my ($element) = @_;

  my ($status, @output);

  if (ref $element eq 'ARRAY') {
    for (@{$element}) {
      $log->msg("Checking in $_");

      my $newElement = Clearcase::Element->new($_);

      ($status, @output) = $newElement->checkin;

      $log->log($_) for (@output);

      $log->err("Unable to check in $_", $status) if $status;
    } # for
  } else {
    $log->msg("Checking in $element");

    my $newElement = Clearcase::Element->new($element);

    ($status, @output) = $newElement->checkin;

    $log->log($_) for (@output);

    $log->err("Unable to check in $element", $status) if $status;
  } # if
  
  return;
} # CheckIn

sub ComparingFiles(@) {
  my (@elements) = @_;

  for (@elements) {
    my @lines = ReadFile $_;

    $log->err("Element $_ should contain only two lines", 2) if scalar @lines != 2;
  } # for

  return;
} # ComparingFiles

sub MakeElements(@) {
  my (@elements) = @_;

  for (@elements) {
    $log->msg("Mkelem $_");

    my $newElement = Clearcase::Element->new($_);

    my ($status, @output) = $newElement->mkelem;

    $log->log($_) for (@output);

    $log->err("Unable to make $_ an element", $status) if $status;
  } # for
  
  return;
} # MakeElements

sub RunTests() {
  # Simple tests:
  #
  #   . Create a few elements
  #   . Check them in
  #   . Check them out
  #   . Modify them
  #   . Check them in
  #
  # Assumptions:
  #
  #   . $vob_tag is already created
  #   . $view_tag is already created
  #   . View is set and we are in the vob
  #   . There are no vob elements for @elements
  my @elements = (
    'cctest.h',
    'ccsetup.c',
    'cctest.c',
    'Makefile',
  );

  $log->msg("$script: Start Base Clearcase Tests");
  $log->msg('Removing test files');

  unlink $_ for (@elements);

  $log->msg('Creating view private files');

  CreateViewPrivateFiles @elements;

  $log->msg('Making elements');

  CheckOut      '.';
  MakeElements  @elements;
  CheckIn       \@elements;
  CheckIn       '.';

  $log->msg('Checking out files');

  CheckOut \@elements;

  $log->msg('Modifying files');

  CreateViewPrivateFiles @elements;

  $log->msg('Checking in files');

  CheckIn \@elements;

  $log->msg('Comparing files');

  ComparingFiles @elements;

  $log->msg("$script: End Base Clearcase Tests");

  return 0;
} # RunTests

sub Cleanup(;$$$) {
  my ($view, $vob) = @_;

  my $status = 0;

  $log->msg('Cleaning up');

  if ($view && $view->exists) {
    $status += DestroyView($view);
  } # if

  if ($vob && $vob->exists) {
    $status += DestroyVob($vob);
  } # if

  return $status;
} # Cleanup

sub CleanupUCM() {
  my $status = 0;

  # Need to remove UCM objects in the opposite order in which we created them
  for (reverse @ucmobjs) {
    my ($rc, @output);

    if (ref $_ eq 'Clearcase::UCM::Pvob') {
      $log->msg('Removing Pvob ' . $_->tag);

      $status += DestroyVob $_;
    } else {
      $log->msg('Removing ' . ref ($_) . ' ' . $_->name);

      ($rc, @output) = $_->remove;

      $status += $rc;
    } # if
  } # for

  return $status;
} # CleanupUCM

sub SetupTest($$) {
  my ($vob_tag, $view_tag) = @_;
  
  my ($status, @output);

  $log->msg('Setup test environment');

  my $view = Clearcase::View->new($view_tag);

  if ($view->exists) {
    $log->msg('Removing old view ' . $view_tag);

    ($status, @output) = $view->remove;

    $log->err('Unable to remove old view ' . $view->tag, $status) if $status;
  } # if

  ($status, $test_view) = CreateView($view_tag);

  return $status if $status != 0;

  $status = $test_view->start;

  my $vob = Clearcase::Vob->new($vob_tag);

  if ($vob->exists) {
    $log->msg('Removing old vob ' . $vob_tag);

    ($status, @output) = DestroyVob($vob);

    $log->err('Unable to remove old vob '. $vob->tag, $status) if $status;
  } # if

  ($status, $test_vob) = CreateVob($vob_tag);

  return $status if $status != 0;

  $status = MountVob($test_vob);

  return $status if $status != 0;

  my $dir = $Clearcase::VIEWTAG_PREFIX . '/' . $test_view->tag . $test_vob->tag;

  chdir $dir
    or $log->err("Unable to chdir to $dir", ++$status);

  ($status, @output) = $Clearcase::CC->execute("cd $dir");

  if ($status != 0) {
    $log->log($_) for (@output);
  } # if

  return $status;
} # SetupTest

sub SetupUCMTest() {
  my $status;

  $log->msg("Creating UCM Pvob $Clearcase::VOBTAG_PREFIX/tc.pvob");

  ($status, $test_pvob) = CreatePvob("$Clearcase::VOBTAG_PREFIX/tc.pvob"); 
  
  return $status;
} # SetupUCMTest

sub CreateUCMProject() {
  # Get the root folder to put this project into (may create folders later)
  my $folder = Clearcase::UCM::Folder->new('tc.folder', $test_pvob);

  $test_project = Clearcase::UCM::Project->new('tc.project', $folder, $test_pvob);

  $log->msg('Creating UCM Project tc.project');

  my ($status, @output) = $test_project->create();

  $log->log($_) for (@output);

  push @ucmobjs, $test_project unless $status;

  return $status;
} # CreateUCMProject

sub CreateUCMIntStream() {
  $test_intstream = Clearcase::UCM::Stream->new('tc.intstream', $test_pvob);

  $log->msg('Creating UCM Stream tc.intstream');

  my ($status, @output) = $test_intstream->create($test_project, '-integration');

  $log->log($_) for (@output);

  push @ucmobjs, $test_intstream unless $status;

  return $status;
} # CreateUCMIntStream

sub CreateUCMDevStream() {
  $test_devstream = Clearcase::UCM::Stream->new('tc.devstream', $test_pvob);

  $log->msg('Creating UCM Stream tc.devstream');

  my ($status, @output) = $test_devstream->create($test_project);

  $log->log($_) for (@output);

  push @ucmobjs, $test_devstream unless $status;

  return $status;
} # CreateUCMIntStream

sub CreateUCMComponent() {
  $test_component = Clearcase::UCM::Component->new('tc.component', $test_pvob);

  $log->msg('Creating UCM Component tc.component');

  my ($status, @output) = $test_component->create(
    "$Clearcase::VIEWTAG_PREFIX/" . $test_intview->tag . $test_vob->tag
  );

  $log->log($_) for (@output);

  push @ucmobjs, $test_component unless $status;

  return $status;
} # CreateUCMComponent

sub AddModifiableComponent() {
  my ($status, @output) = $Clearcase::CC->execute(
    'chproj -nc -amodcomp ' . $test_component->name . '@' . $test_pvob->tag .
    ' '                     . $test_project->name   . '@' . $test_pvob->tag
  );

  $log->log($_) for (@output);

  return $status;
} # AddModifiableCOmponent

sub CreateUCMIntView() {
  $log->msg("Creating UCM Int View tc.intview");

  $test_intview = Clearcase::View->new('tc.intview');

  my ($status, @output) = $test_intview->create(
    $opts{viewhost}, "$opts{viewstore}/tc.intview.vws",
    '-stream ' . $test_intstream->name . '@' . $test_pvob->tag
  );

  $log->log($_) for (@output);

  push @ucmobjs, $test_intview unless $status;

  $test_intview->start unless $status;

  return $status;
} # CreateUCMIntView

sub CreateUCMDevView() {
  $log->msg("Creating UCM Dev View tc.devview");

  $test_devview = Clearcase::View->new('tc.devview');

  my ($status, @output) = $test_devview->create(
    $opts{viewhost}, "$opts{viewstore}/tc.devview.vws",
    '-stream ' . $test_devstream->name . '@' . $test_pvob->tag
  );

  $log->log($_) for (@output);

  push @ucmobjs, $test_devview unless $status;

  $test_devview->start unless $status;

  return $status;
} # CreateUCMDevView

sub CreateUCMBaseline() {
  $test_baseline = Clearcase::UCM::Baseline->new('tc.baseline', $test_pvob);

  $log->msg('Creating UCM Baseline tc.baseline');

  my ($status, @output) = $test_baseline->create($test_intview, undef, '-identical');

  $log->log($_) for (@output);

  push @ucmobjs, $test_baseline unless $status;

  return $status;
} # CreateUCMBaseline

sub CreateUCMActivity() {
  $test_activity = Clearcase::UCM::Activity->new('tc.activity', $test_pvob);

  $log->msg('Creating UCM Activity tc.activity');

  my ($status, @output) = $test_activity->create($test_devstream, 'A UCM Test Activity');

  $log->log($_) for (@output);

  push @ucmobjs, $test_activity unless $status;

  return $status;
} # CreateUCMActivity

sub RebaseStream($$;$) {
  my ($stream, $baseline, $opts) = @_;

  my ($status, @output) = $stream->rebase($baseline, $opts);

  $log->log($_) for (@output);

  return $status;
} # RebaseStream

sub RecommendBaseline($) {
  my ($baseline) = @_;

  my ($status, @output) = $test_intstream->recommend($baseline);

  $log->log($_) for (@output);

  return $status;
} # RecommentBaseline

sub RunUCMTests() {
  my $status = 0;

  $log->msg("$script: Start UCM Clearcase Tests");

  $status += CreateUCMProject;
  $status += CreateUCMIntStream;
  $status += CreateUCMDevStream;
  $status += CreateUCMIntView;
  $status += CreateUCMDevView;
  $status += CreateUCMComponent;
  $status += AddModifiableComponent;
  $status += RebaseStream($test_intstream, 'tc.component_INITIAL', '-complete');
  $status += RecommendBaseline('tc.component_INITIAL');
  $status += CreateUCMBaseline;
  $status += RebaseStream($test_devstream, 'tc.baseline', '-complete');
  $status += CreateUCMActivity;
  
  $log->msg("$script: End UCM Clearcase Tests");

  return $status;
} # RunUCMTests

## Main
my $startTime = time;
my $conf_file = "$FindBin::Bin/$script.conf";
my $status    = 0;

$opts{base}  = 1;
$opts{clean} = 1;

GetOptions(
  \%opts,
  'verbose' => sub { set_verbose },
  'debug'   => sub { set_debug },
  'usage'   => sub { Usage },
  'config=s',
  'base!',
  'ucm!',
  'clean!',
) or Usage;

# Read the config file
if (-f $conf_file) {
  %default_opts = GetConfig $conf_file;
} else {
  $log->err("Unable to find config file $conf_file", 1);
} # if

# Overlay default opts if not specified
for (keys %default_opts) {
  $opts{$_} = $default_opts{$_} if !$opts{$_};
} # for

$log->msg("$script: Start");

LogOpts;

# Since we are creating private vobs (to avoid complications with having to
# know and code the registry password when making public vobs), we'll simply
# change $Clearcase::VOBTAG_PREFIX
$Clearcase::VOBTAG_PREFIX = $ENV{TMP} || '/tmp';

if ($opts{base}) {
  $status = SetupTest "$Clearcase::VOBTAG_PREFIX/tc.vob", 'tc.view';

  if ($status == 0) {
    $status += RunTests;
  } else {
    $log->err('Tests not run. Failure occurred in SetupTest - check logfile');
  } # if

  # Note if we are doing UCM tests then we need the view and vob here...
  $status += Cleanup($test_view, $test_vob) if $opts{clean} and !$opts{ucm};

  if ($status != 0) {
    $log->err("$script: Failed (Base Clearcase)");
  } else {
    $log->msg("$script: Passed (Base Clearcase)");
  } # if
} # if

if ($opts{ucm}) {
  $status = SetupUCMTest;

  if ($status == 0) {
    $status += RunUCMTests;
  } else {
    $log->err('UCM Tests not run. Failure occurred in SetupUCMTest - check logfile');
  } # if

  if ($opts{clean}) {
    $status += CleanupUCM;
    $status += Cleanup($test_view, $test_vob);
  } # if

  if ($status != 0) {
    $log->err("$script Failed (UCM Clearcase)");
  } else {
    $log->msg("$script: Passed (UCM Clearcase)");
  } # if
} # if

display_duration $startTime, $log;

$log->msg("$script: End");

exit $status;

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

L<Term::ANSIColor|Term::ANSIColor>

=head2 ClearSCM Perl Modules

=begin man 

 Clearcase
 Clearcase::Element
 Clearcase::View
 Clearcase::Views
 Clearcase::Vob
 Clearcase::Vobs
 DateUtils
 Display
 GetConfig
 Logger
 OSDep
 Utils

=end man

=begin html

<blockquote>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Clearcase.pm">Clearcase</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Clearcase/Element.pm">Element</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Clearcase/View.pm">View</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Clearcase/Views.pm">Views</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Clearcase/Vob.pm">Vob</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Clearcase/Vobs.pm">Vobs</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Clearcase/UCM.pm">UCM</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Clearcase/UCM/Activity.pm">Activity</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Clearcase/UCM/Baseline.pm">Baseline</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Clearcase/UCM/Component.pm">Component</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Clearcase/UCM/Project.pm">Project</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Clearcase/UCM/Pvob.pm">Pvob</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Clearcase/UCM/Stream.pm">Stream</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/DateUtils.pm">DateUtils</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Display.pm">Display</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/GetConfig.pm">GetConfig</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Logger.pm">Logger</a><br>
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
