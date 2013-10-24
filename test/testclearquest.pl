#!/usr/bin/perl
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

   -use|rname:  Username to open database with (Default: from config file) 
   -p|assword:  Password to open database with (Default: from config file) 
   -da|tabase:  Database to open (Default: from config file)
   -db|set:     Database Set to use (Default: from config file)
   -m|odule:    Type of Clearquest module to use. Must be one of 'api', 
                'client', or 'rest'. The 'api' module can only be used if
                Clearquest is installed locally. The 'client' module can only
                be successful if a corresponding server is running. And the 
                'rest' module can only be used if a CQ Web server has been set
                up and configured (Default: rest)
   -s|erver:    For module = client or rest this is the name of the server that
                will be providing the service
   -p|ort:      For module = client, this is the point on the server to talk
                through.


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

use lib "$FindBin::Bin/../lib";

use Clearquest;
use Display;
use TimeUtils;
use Utils;

my ($cq, %opts);

sub displayRecord (%) {
  my (%record) = @_;
  
  display '-' x 79;
  
  foreach (keys %record) {
    display_nolf "$_: ";
  
    if (ref $record{$_} eq 'ARRAY') {
      display join ", ", @{$record{$_}};
    } elsif ($record{$_}) {
      display $record{$_};
    } else {
      display "<undef>";
    } # if
  } # foreach
  
  return;
} # displayRecord

sub displayResults (@) {
  my (@records) = @_;
  
  if (@records) {
    displayRecord %$_ foreach (@records);
  } else {
    display "Did not find any records";
  } # if
  
  return;
} # displayResults

sub testGetRecord ($$;@) {
  my ($table, $key, @fields) = @_;
  
  my $startTime = time;
  
  display "Testing get table: $table key: $key";
  
  displayRecord $cq->get ($table, $key, @fields);
  
  display_duration $startTime;
  
  return;
} # testGetRecord

sub testFindRecord ($$;@) {
  my ($table, $condition, @fields) = @_;
  
  my $startTime = time;
  
  display "Testing find table: $table condition: $condition";
  
  my ($result, $nbrRecs) = $cq->find ($table, $condition, @fields);

  display "$nbrRecs records qualified";

  while (my %record = $cq->getNext ($result)) {
    displayRecord %record;
  } # while
  
  display_duration $startTime;
  
  return;
} # testFindRecord

sub testModifyRecord ($$;%) {
  my ($table, $key, %update) = @_;
  
  my $startTime = time;
  
  display "Testing modify table: $table key: $key";
  
  $cq->modify ($table, $key, undef, \%update);
  
  $cq->checkErr;
  
  display_duration $startTime;
  
  return;
} # testModifyRecord

sub testChangeState ($$) {
  my ($table, $key) = @_;
  
  my $startTime = time;
  
  my %record = $cq->get ($table, $key, ('State'));
  
  $cq->checkErr ("Unable to find $table where key = $key");
    
  return if $cq->error;

  my ($action, %update);
  
  if ($record{State} eq 'Assigned') {
    $action                  = 'AdminAssignToSubmit';
    $update{Stability_Issue} = 'User Fault';
  } else {
    $action                  = 'Assign';
    $update{Stability_Issue} = 'Assert';
  } # if
  
  display "Testing change state table: $table key: $key action: $action";
  
  $cq->modify ($table, $key, $action, \%update);
  
  $cq->checkErr;
  
  display_duration $startTime; 
  
  return; 
} # testChangeState

sub testAddRecord ($%) {
  my ($table, %record) = @_;
  
  my $startTime = time;
  
  display "Testing adding table: $table";
  
  $cq->add ($table, \%record, qw(Projects VersionStr));
  
  $cq->checkErr;
  
  display_duration $startTime;  
  
  return;
} # testAddRecord

sub testDeleteRecord ($$) {
  my ($table, $key) = @_;
  
  my $startTime = time;
  
  display "Testing deleting table: $table key: $key";
  
  $cq->delete ($table, $key);
  
  $cq->checkErr;

  display_duration $startTime;
  
  return;
} # testDeleteRecord

## Main
GetOptions (
  \%opts,
  usage   => sub { Usage },
  verbose => sub { set_verbose },
  debug   => sub { set_debug },
  'get',
  'add',
  'modify',
  'change',
  'delete',
  'module=s',
  'username=s',
  'password=s',
  'database=s',
  'dbset=s',
  'server=s',
  'port=i',
) || Usage;

my $processStartTime = time;

local $| = 1;

# Translate any options to ones that the lib understands
$opts{CQ_USERNAME} = delete $opts{username};
$opts{CQ_PASSWORD} = delete $opts{password};
$opts{CQ_DATABASE} = delete $opts{database};
$opts{CQ_DBSET}    = delete $opts{dbset};
$opts{CQ_SERVER}   = delete $opts{server};
$opts{CQ_PORT}     = delete $opts{port};
$opts{CQ_MODULE}   = delete $opts{module};

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

$cq = Clearquest->new (%opts);

display_nolf 'Connecting to Clearquest database ' . $cq->connection;

unless ($cq->connect) {
  $cq->checkErr ('Unable to connect to database ' . $cq->connection);
  
  if ($cq->module eq 'client') {
    display 'Unable to connect to server '
          . $cq->server ()
          . ':'
          . $cq->port ();
  } # if
  
  exit $cq->error;
} else {
  display '';
  display_duration $startTime;
} # unless

$cq->setOpts (emptyStringForUndef => 1);

if ($opts{get}) {
  # Get record by key
  testGetRecord 'Project', 'Athena';

  # Get record by condition
  testFindRecord 'VersionInfo', 'Deprecated = 1';

  # Get record by key with field list
  testFindRecord 'VersionInfo', 'VersionStr = 1.0', ('VersionStr',   'Deprecated');

  # Get record by condition with field list
  testFindRecord 'CategorySub', 'Category="Software"', ('Category', 'CategoryType', 'SubCategory');
} # if

if ($opts{add}) {
  # Add a record
  testAddRecord    'VersionInfo', (
    VersionStr => '2.0',
    Projects   => ['Island', '21331', 'Hera'],
    Visibility => 'Nokia Corporation',
  );
} # if

if ($opts{modify}) {
  # Modify a record
  testModifyRecord ('VersionInfo', '1.0', (
    Deprecated => 1,
    Projects   => ['Island', 'Athena'],
  ));
} # if

if ($opts{change}) {
  # Change State
  testChangeState 'Defect', 'apd00000034';
} # if

if ($opts{add}) {
  # Delete that record
  testDeleteRecord 'VersionInfo', '2.0';
} # if

display_nolf 'Total process time ';

display_duration $processStartTime;
