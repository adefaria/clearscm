#!/usr/bin/env cqperl
use strict;
use warnings;

=pod

=head1 NAME $RCSfile: testclearquest.pl,v $

Test the Clearquest libary

This script tests various functions of the Clearquest library

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 2.8 $

=item Created:

Mon Nov 12 16:50:44 PST 2012

=item Modified:

$Date: 2013/03/14 23:39:39 $

=back

=head1 SYNOPSIS

 Usage: testclearquest.pl [-u|sage] [-v|erbose] [-d|ebug]
                          [-get] [-add] [-modify] [-change] [-delete]
                          [-username <username>] [-password <password>]
                          [-database <dbname>] [-dbset <dbset>]
                          [-module] [-server <server>] [-port <port>]

 Where:
   -usa|ge:     Displays usage
   -v|erbose:   Be verbose
   -de|bug:     Output debug messages

   -get:        Test get
   -add:        Test add
   -modify:     Test modify
   -change:     Test change
   -delete:     Test delete

   -use|rname:  Username to open database with (Default: CQ_USERNAME or from
                config file)
   -p|assword:  Password to open database with (Default: CQ_PASSWORD or from
                config file)
   -da|tabase:  Database to open (Default: CQ_DATABASE or from config file)
   -db|set:     Database Set to use (Default: CQ_DBSET or from config file)



=head1 Options

Options are keep in the cq.conf file in etc. They specify the default options
listed below. Or you can export the option name to the env(1) to override the
defaults in cq.conf. Finally you can programmatically set the options when you
call new by passing in a %parms hash. To specify the %parms hash key remove the
CQ_ portion and lc the rest.

=for html <blockquote>

=over

=item CQ_SERVER

Clearquest server to talk to (Default: From cq.conf)

=item CQ_PORT

Port to connect to (Default: From cq.conf)

=item CQ_WEBHOST

The web host to contact with leading http:// (Default: From cq.conf)

=item CQ_DATABASE

Name of database to connect to (Default: From cq.conf)

=item CQ_USERNAME

User name to connect as (Default: From cq.conf)

=item CQ_PASSWORD

Password for CQREST_USERNAME (Default: From cq.conf)

=item CQ_DBSET

Database Set name (Default: From cq.conf)

=back

=cut

use FindBin;
use Getopt::Long;
use Pod::Usage;

use lib "$FindBin::Bin/../lib";

use Clearquest;
use Clearcase::View;
use Clearcase::UCM::Activity;
use Clearcase::UCM::Stream;
use Clearcase::UCM::Project;
use Clearcase::UCM::Pvob;
use DateUtils;
use Display;
use Logger;
use OSDep;
use TimeUtils;
use Utils;

my ($cq, %opts, $log, $createView, $test_pvob, $test_project);

my $status  = 0;
my $project = 'tc.project';

sub displayRecord(%) {
  my (%record) = @_;

  $log->msg('-' x 79);

  for (keys %record) {
    $log->msg("$_: ", 1);

    if (ref $record{$_} eq 'ARRAY') {
      $log->msg(join ", ", @{$record{$_}});
    } elsif ($record{$_}) {
      $log->msg($record{$_});
    } else {
      $log->msg('<undef>');
    } # if
  } # for

  return;
} # displayRecord

sub displayResults(@) {
  my (@records) = @_;

  if (@records) {
    displayRecord %$_ foreach (@records);
  } else {
    $log->msg('Did not find any records');
  } # if

  return;
} # displayResults

sub GetRecord($$;@) {
  my ($table, $key, @fields) = @_;

  $log->msg("Gettng table: $table key: $key");

  my %record = $cq->get($table, $key, @fields);

  if ($cq->checkErr) {
  	$log->err($cq->errmsg);
  } else {
    displayRecord %record;
  } # if

  return $cq->error;
} # GetRecord

sub FindRecord($$;@) {
  my ($table, $condition, @fields) = @_;

  my $status;

  $log->msg("Finding table: $table condition: $condition");

  my ($result, $nbrRecs) = $cq->find($table, $condition, @fields);

  $log->msg("$nbrRecs records qualified");

  while (my %record = $cq->getNext($result)) {
    unless ($cq->error) {
      # Store away the createView.pl script location
      $createView = $record{ws_cr_view} if $table eq 'Platform_Options';

      displayRecord %record;

      $status += $cq->error;
    } # unless
  } # while

  return $status
} # FindRecord

sub ModifyRecord($$;%) {
  my ($table, $key, %update) = @_;

  $log->msg("Modifying table: $table key: $key");

  $cq->modify($table, $key, undef, \%update);

  $log->err($cq->errmsg) if $cq->checkErr;

  return $cq->error;
} # ModifyRecord

sub AssignWOR($) {
  my ($key) = @_;

  my %record = $cq->get('WOR', $key, ('State'));

  return $cq->error if $cq->checkErr("Unable to find WOR where key = $key");

  my ($action, %update);

  if ($record{State} ne 'Submitted') {
    $log->err("Cannot assign $key - not in submitted state");

    return 1;
  } # if

  $action               = 'Assign';
  $update{PlannedStart} = Today2SQLDatetime;
  $update{ucm_project}  = $project;

  $log->msg("Testing change WOR state of $key action: $action");

  $cq->modify('WOR', $key, $action, \%update);

  $log->err($cq->errmsg) if $cq->checkErr;

  return $cq->error;
} # AssignWOR

sub ActivateWOR($) {
  my ($key) = @_;

  my %record = $cq->get('WOR', $key, ('State'));

  return $cq->error if $cq->checkErr("Unable to find WOR where key = $key");

  my ($action, %update);

  if ($record{State} ne 'Assessing') {
    $log->err("Cannot activate $key - not in Assessing state");

    return 1;
  } # if

  $action = 'Activate';

  $log->msg("Testing change WOR state of $key action: $action");

  $cq->modify('WOR', $key, $action);

  $log->err($cq->errmsg) if $cq->checkErr;

  return $cq->error;
} # ActivateWOR

sub AddRecord($$;$$) {
  my ($table, $record, $ordering, $returnField) = @_;

  $returnField ||= 'id';

  $log->msg("Adding table: $table");

  my $dbid = $cq->add($table, $record, @$ordering);

  if ($cq->checkErr) {
    $log->err($cq->errmsg);

    return;
  } else {
    my %record = $cq->getDBID($table, $dbid, ($returnField));

    return $record{$returnField};
  } # if
} # AddRecord

sub DeleteRecord($$) {
  my ($table, $key) = @_;

  $log->msg("Deleting table: $table key: $key");

  $cq->delete($table, $key);

  $log->err($cq->errmsg) if $cq->checkErr;

  return $cq->error;
} # DeleteRecord

sub CreateWOR() {
  # Try to add a WOR - the following fields are required and some may need 
  # to be added to stateless records in order for this to succeed. Once you
  # can add a WOR through the  Clearquest client successfully you should be
  # able to come up with the values of these  required fields. There are,
  # however, sometimes when you need to specify ordering to have some fields
  # set before other fields.
  my %WOR = (
    headline           => 'Test WOR',
    description        => 'This is a test WOR created programmatically',
    project            => 'MUOS',
    RCLC_name          => 'Test RCLC',
    Prod_Arch1         => 'testcode : N/A',
    work_product_name  => '10 - Software',
    #Engr_target        => 'Test Engineering Target',
    work_code_name     => 'RAN-RW2',
  );

  return AddRecord('WOR', \%WOR, ['project', 'Prod_Arch1']);
} # CreateWOR

sub CreateView($) {
  my ($WORID) = @_;

  my ($status, @output) = Execute "$createView $WORID 2>&1";

  $log->log($_) for @output;

  return $status;
} # CreateView

sub Cleanup($) {
  my ($WORID) = @_;

  my ($status, @output) = (0, ());
  my $rc = 0;

  # Remove views created
  my @tags = (
    "$ENV{USER}_${project}_intview",
    "$ENV{USER}_${WORID}_devview",
  );

  for (@tags) {
    my $view = Clearcase::View->new($_);

    $log->msg('Removing ' . $view->name);

    ($rc, @output) = $view->remove;

    $status++ if $rc;

    $log->log($_) for @output;
  } # for

  # Remove streams that were created
  my @streams = (
    "$ENV{USER}_${WORID}_${project}_dev",
  );

  for my $stream (@streams) {
    my $activity = Clearcase::UCM::Activity->new($WORID, $test_pvob);

    $log->msg('Removing ' . $activity->name);

    ($rc, @output) = $activity->remove;

    $status += $rc;

    $log->log($_) for @output;

    # Streams are downshifted
    my $stream = Clearcase::UCM::Stream->new(lc $stream, $test_pvob);

    $log->msg('Removing ' . $stream->name);

    ($rc, @output) = $stream->remove;

    $log->log($_) for @output;

    $status++ if $rc;
  } # for

  return $status;
} # Cleanup

## Main
GetOptions(
  \%opts,
  usage   => sub { pod2usage },
  help    => sub { pod2usage (-verbose => 2)},
  verbose => sub { set_verbose },
  debug   => sub { set_debug },
  'get',
  'add',
  'modify',
  'change',
  'delete',
  'username=s',
  'password=s',
  'database=s',
  'dbset=s',
) || pod2usage;

my $processStartTime = time;

# Since we are creating private vobs (to avoid complications with having to
# know and code the registry password when making public vobs), we'll simply
# change $Clearcase::VOBTAG_PREFIX
if ($ARCHITECTURE !~ /win/i) {
  $Clearcase::VOBTAG_PREFIX = $ENV{TMP} || '/tmp';
} # if

local $| = 1;

# Translate any options to ones that the lib understands
map {$opts{$_} = $Clearquest::OPTS{$_}} keys %Clearquest::OPTS;

$opts{CQ_USERNAME} = delete $opts{username} if $opts{username};
$opts{CQ_PASSWORD} = delete $opts{password} if $opts{password};
$opts{CQ_DATABASE} = delete $opts{database} if $opts{database};
$opts{CQ_DBSET}    = delete $opts{dbset}    if $opts{dbset};
$opts{CQ_SERVER}   = delete $opts{server}   if $opts{server};
$opts{CQ_PORT}     = delete $opts{port}     if $opts{port};
$opts{CQ_MODULE}   = delete $opts{module}   if $opts{module};

# If nothing is set then do everything
unless ($opts{get}    or
        $opts{add}    or
        $opts{modify} or
        $opts{change} or
        $opts{delete}
  ) {
  $opts{get} = $opts{add} = $opts{modify} = $opts{change} = 1;
} # unless

# If we are testing add or delete then toggle on the other one
$opts{delete} = 1 if $opts{add};
$opts{add}    = 1 if $opts{delete};

my $startTime = time;

$log = Logger->new;

$cq = Clearquest->new(%opts);

$log->msg('Connecting to Clearquest database ' . $cq->connection . '...', 1);

unless ($cq->connect) {
  $cq->checkErr('Unable to connect to database ' . $cq->connection, undef, $log);

  if ($cq->module eq 'client') {
    $log->msg('Unable to connect to server ' . $cq->server() . ':' . $cq->port());
  } # if

  exit $cq->error;
} else {
  $log->msg('connected');
  display_duration $startTime, $log;
} # unless

$cq->setOpts(emptyStringForUndef => 1);

# Check a few required stateless records
if ($opts{get}) {
  # Get record by key
  $status += GetRecord 'Project', 'MUOS- EC';

  # Get record by condition
  $status += FindRecord 'Platform_Options', 'Platform = "Unix"';

  # Get record by condition with field list
  $status += FindRecord 'Roles', 'Rank = "Supervisor"', ('user_name', 'teams.Name',   'Rank');
} # if

if ($opts{add}) {
  my %component = (
    Name        => $FindBin::Script,
    Description => 'This is a test component',
  );

  AddRecord('Component', \%component, undef, 'name');

  $status++ if $cq->error;
} # if

if ($opts{modify}) {
  # Modify a record
  my $newDescription = 'This is a modified test component';

  $status += ModifyRecord('Component', $FindBin::Script, (Description => $newDescription));

  # Make sure the modification happened
  my %component = $cq->get('Component', $FindBin::Script, ('Description'));

  $log->err('Modification of Component.Description failed!')
    if $component{Description} ne $newDescription;
} # if

DeleteRecord 'Component', $FindBin::Script if $opts{add};

$log->msg('Enable tc.project for integration with Clearquest');

$test_pvob    = Clearcase::UCM::Pvob->new("${Clearcase::VOBTAG_PREFIX}tc.pvob");
$test_project = Clearcase::UCM::Project->new('tc.project', 'tc.folder', $test_pvob);

my ($rc, @output) = $test_project->change("-force -crmenable $opts{CQ_DATABASE}");

$status += $rc;

$log->log($_) for @output;

$log->msg('Create WOR');

my $WORID = CreateWOR;

unless ($WORID) {
  $status++;

  exit $status;
} else {
  $log->msg("Created WOR $WORID");
} # unless

if ($opts{change}) {
  my $worStatus;

  $worStatus += AssignWOR   $WORID;
  $worStatus += ActivateWOR $WORID;

  $status += $worStatus;

  unless ($worStatus) {
    # If we weren't able to assign and activate the WOR then there's no need
    # to create the view and no need to clean up unless we created the view.
    $worStatus = CreateView $WORID;

    $status += Cleanup($WORID) unless $worStatus;

    $status += $worStatus;
  } # unless
} # if

if ($status) {
  $log->err('Clearquest tests FAILED');
} else {
  $log->msg('Clearquest tests PASSED');
} # if

$log->msg('Total process time ', 1);

display_duration $processStartTime, $log;

exit $status;
