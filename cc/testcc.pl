#!/bin/bin/perl

=pod

=head1 NAME $RCSfile: testcc.pl,v $

Test Clearcase

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.6 $

=item Created:

Tue Apr 10 13:14:15 CDT 2007

=item Modified:

$Date: 2011/01/09 01:01:32 $

=back

=head1 SYNOPSIS

 Usage testcc.pl: [-u|sage] [-ve|rbose] [-d|ebug]
                  [-c|onfig <file>] [-vi|ewstore <viewstore>] 
                  [-vo|bstore <vobstore>]

 Where:
   -u|sage:     Displays usage
 
   -ve|rbose:   Be verbose
   -d|ebug:     Output debug messages

   -c|onfig <file>: Config file (Default: testcc.conf)
   -vi|ewstore:     Path to view storage area
   -vo|bstore:      Path to vob storage area

=head1 DESCRIPTION  

Clearcase smoke tests. Perform simple Clearcase operations to validate that
Clearcase minimally works

=cut

use strict;
use warnings;

use FindBin;
use Getopt::Long;
use Cwd;
use Term::ANSIColor qw(:constants);

my $libs;

BEGIN {
  $libs = $ENV{SITE_PERLLIB} ? $ENV{SITE_PERLLIB} : "$FindBin::Bin/../lib";

  die "Unable to find libraries\n" 
    unless -d $libs;
} # BEGIN

use lib $libs;

use Clearcase;
use Clearcase::Element;
use Clearcase::View;
use Clearcase::Views;
use Clearcase::Vob;
use Clearcase::Vobs;
use DateUtils;
use Display;
use GetConfig;
use Logger;
use OSDep;
use Utils;

# Globals
my $VERSION = '2.0';

my ($vbs, $vws, %default_opts, %opts);

my $log      = Logger->new;
my $view     = $Clearcase::VIEWTAG_PREFIX;
my $view_tag = $FindBin::Script;
my $vob      = $ENV{TMP} ? $ENV{TMP} : "/tmp"; # Private vob - mount to /tmp!
my $vob_tag  = $view_tag;

my ($test_view, $test_vob);

# LogOpts: Log the %opts has to the log file so we can tell the options used for
# this run.
sub LogOpts () {
  $log->msg (
    "$FindBin::Script v$VERSION run at " 
  . YMDHM
  . " with the following options:"
  );

  foreach (sort keys %opts) {
    if (ref $opts{$_} eq "ARRAY") {
      my $name = $_;
      $log->msg ("$name:\t$_") foreach (@{$opts{$_}});
    } else {
      $log->msg ("$_:\t$opts{$_}");
    }  # if
  } # foreach
  
  return;
} # LogOpts

sub CreateVob () {
  $log->msg ("Creating vob $vob/$vob_tag");

  $test_vob = Clearcase::Vob->new ("$vob/$vob_tag");

  my ($status, @output) = $test_vob->create ($opts{vobhost}, $vbs);

  $log->log ($_) foreach (@output);

  if ($status != 0) {
    if ($output[0] =~ /already exists/) {
      $log->warn ("Vob " . $test_vob->tag . " already exists");
      return 0;
    } # if
  } # if

  return $status;
} # CreateVob

sub MountVob () {
  $log->msg ("Mounting vob " . $test_vob->tag);

  # Create mount directory
  my ($status, @output) = Execute "mkdir -p " . $test_vob->tag . " 2>&1";

  $log->log ($_) foreach (@output);

  ($status, @output) = $test_vob->mount;

  $log->log ($_) foreach (@output);

  return $status;
} # MountVob

sub DestroyVob () {
  my ($status, @output);

  ($status, @output) = $Clearcase::CC->execute ("cd");

  $log->msg ("Unmounting vob " . $test_vob->tag);

  ($status, @output) = $test_vob->umount;

  $log->msg ("Removing vob " . $test_vob->tag);

  ($status, @output) = $test_vob->remove;

  $log->log ($_) foreach (@output);

  ($status, @output) = Execute "rmdir " . $test_vob->tag;

  $log->log ($_)
    foreach (@output);

  return $status;
} # DestroyVob

sub CreateView () {
  $log->msg ("Creating view $view_tag");

  $test_view = Clearcase::View->new ($view_tag);

  my ($status, @output) = $test_view->create ($opts{viewhost}, $vws);

  $log->log ($_) foreach (@output);

  if ($status != 0) {
    if ($output[0] =~ /already exists/) {
      $log->warn ("View " . $test_view->tag . " already exists");
      return 0;
    } # if
  } # if

  return $status;
} # CreateView

sub SetView () {
  $log->msg ("Setting view $test_view->tag");

  my ($status, @output) = $test_view->set;

  $log->log ($_) foreach (@output);

  return $status;
} # SetView

sub DestroyView () {
  $log->msg ("Removing view " . $test_view->tag);

  my ($status, @output) = $Clearcase::CC->execute ("cd");

  $log->log ($_) foreach (@output);

  chdir $ENV{HOME}
    or $log->err ("Unable to chdir $ENV{HOME}", 1);

  ($status, @output) = $test_view->remove;

  $log->log ($_) foreach (@output);

  return $status;
} # DestroyView

sub CreateViewPrivateFiles (@) {
  my (@elements) = @_;

  $log->msg ("Creating test files");

  foreach (@elements) {
    my $file;

    $log->msg ("Creating $_");

    open $file, ">>", $_
      or $log->err ("Unable to open $_ for writing - $!", 1);

    print $file "This is file $_\n";

    close $file;
  } # foreach
  
  return;
} # CreateViewPrivateFiles

sub CheckOut ($) {
  my ($element) = @_;

  my ($status, @output);

  if (ref $element eq "ARRAY") {
    foreach (@{$element}) {
      $log->msg ("Checking out $_");

      my $newElement = Clearcase::Element->new ($_);

      ($status, @output) = $newElement->checkout;

      $log->log ($_) foreach (@output);
      $log->err ("Unable to check out $_", $status) if $status;
    } # foreach
  } else {
    $log->msg ("Checking out $element");

    my $newElement = Clearcase::Element->new ($element);

    ($status, @output) = $newElement->checkout;

    $log->log ($_) foreach (@output);
    $log->err ("Unable to check out $element", $status) if $status;
  } # if
  
  return;
} # CheckOut

sub CheckIn ($) {
  my ($element) = @_;

  my ($status, @output);

  if (ref $element eq "ARRAY") {
    foreach (@{$element}) {
      $log->msg ("Checking in $_");

      my $newElement = Clearcase::Element->new ($_);

      ($status, @output) = $newElement->checkin;

      $log->log ($_) foreach (@output);
      $log->err ("Unable to check in $_", $status) if $status;
    } # foreach
  } else {
    $log->msg ("Checking in $element");

    my $newElement = Clearcase::Element->new ($element);

    ($status, @output) = $newElement->checkin;

    $log->log ($_) foreach (@output);
    $log->err ("Unable to check in $element", $status) if $status;
  } # if
  
  return;
} # CheckIn

sub ComparingFiles (@) {
  my (@elements) = @_;

  foreach (@elements) {
    my @lines = ReadFile $_;

    $log->err ("Element $_ should contain only two lines", 2) if scalar @lines != 2;
  } # foreach
  
  return;
} # ComparingFiles

sub MakeElements (@) {
  my (@elements) = @_;

  foreach (@elements) {
    $log->msg ("Mkelem $_");

    my $newElement = Clearcase::Element->new ($_);

    my ($status, @output) = $newElement->mkelem;

    $log->log ($_) foreach (@output);
    $log->err ("Unable to make $_ an element", $status) if $status;
  } # foreach
  
  return;
} # MakeElements

sub RunTests () {
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
    "cctest.h",
    "ccsetup.c",
    "cctest.c",
    "Makefile",
  );

  $log->msg ("Removing test files");

  unlink $_ foreach (@elements);

  $log->msg ("Creating view private files");

  CreateViewPrivateFiles        $log, @elements;

  $log->msg ("Making elements");

  CheckOut      '.';
  MakeElements  @elements;
  CheckIn       \@elements;
  CheckIn       '.';

  $log->msg ("Checking out files");

  CheckOut \@elements;

  $log->msg ("Modifying files");

  CreateViewPrivateFiles @elements;

  $log->msg ("Checking in files");

  CheckIn \@elements;

  $log->msg ("Comparing files");

  ComparingFiles @elements;

  $log->msg ("$FindBin::Script: End Tests");

  return 0;
} # RunTests

sub Cleanup () {
  my $status = 0;

  $log->msg ("Cleaning up");

  if ($test_view && $test_view->exists) {
    $status += DestroyView;
  } # if

  if ($test_vob && $test_vob->exists) {
    $status += DestroyVob;
  } # if

  return $status;
} # Cleanup

sub SetupTest () {
  $log->msg ("Setup test environment");

  my $status += CreateVob;

  return $status if $status != 0;

  $status += MountVob;

  return $status if $status != 0;

  $status += CreateView;

  return $status if $status != 0;

  $status += $test_view->start;

  my $dir = $Clearcase::VIEWTAG_PREFIX . $test_view->tag . $test_vob->tag;

  chdir $dir
    or $log->err ("Unable to chdir to $dir", $status++);

  my @output;
  
  ($status, @output) = $Clearcase::CC->execute ("cd $dir");

  if ($status != 0) {
    $log->log ($_) foreach (@output);
    $log->err ("Unable to chdir to $dir", $status);
  } # if

  return $status;
} # SetupTest

my $conf_file = "$FindBin::Script.conf";

GetOptions (
  \%opts,
  "v|verbose"           => sub { set_verbose },
  "u|usage"             => sub { Usage },
  "c|onfig=s",
  "n|etpath=s",
  "viewstore=s",
  "vobstore=s",
) or Usage;

# Read the config file
if (-f $conf_file) {
  %default_opts = GetConfig $conf_file;
} else {
  $log->err ("Unable to find config file $conf_file", 1);
} # if

# Overlay default opts if not specified
foreach (keys %default_opts) {
  $opts{$_} = $default_opts{$_} if !$opts{$_};
} # foreach

$vws = "$opts{viewstore}/$view_tag.vws";
$vbs = "$opts{vobstore}/$vob_tag.vbs";

$log->msg ("START: $FindBin::Script (v$VERSION)");

LogOpts;

my $status = SetupTest;

if ($status == 0) {
  $status += RunTests;
} else {
  $log->err ("Tests not run. Failure occured in SetupTest - check logfile");
} # if

$status += Cleanup;

if ($status != 0) {
  $log->err ("$FindBin::Script failed");
} else {
  $log->msg ("$FindBin::Script passed");
} # if

$log->msg ("END: $FindBin::Script (v$VERSION)");

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
<a href="http://clearscm.com/php/scm_man.php?file=lib/Clearcase/Vobspm">Vobs</a><br>
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
