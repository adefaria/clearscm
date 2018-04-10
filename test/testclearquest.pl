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
use Logger;
use TimeUtils;
use Utils;

my ($cq, %opts, $log);

sub displayRecord (%) {
  my (%record) = @_;
  
  $log->msg ('-' x 79);
  
  for (keys %record) {
    $log->msg ("$_: ", 1);
  
    if (ref $record{$_} eq 'ARRAY') {
      $log->msg (join ", ", @{$record{$_}});
    } elsif ($record{$_}) {
      $log->msg ($record{$_});
    } else {
      $log->msg ('<undef>');
    } # if
  } # for
  
  return;
} # displayRecord

sub displayResults (@) {
  my (@records) = @_;
  
  if (@records) {
    displayRecord %$_ foreach (@records);
  } else {
    $log->msg ('Did not find any records');
  } # if
  
  return;
} # displayResults

sub testGetRecord ($$;@) {
  my ($table, $key, @fields) = @_;
  
  my $startTime = time;
  
  $log->msg ("Testing get table: $table key: $key");
  
  displayRecord $cq->get ($table, $key, @fields);
  
  display_duration $startTime, $log;
  
  return;
} # testGetRecord

sub testFindRecord ($$;@) {
  my ($table, $condition, @fields) = @_;
  
  my $startTime = time;
  
  $log->msg ("Testing find table: $table condition: $condition");
  
  my ($result, $nbrRecs) = $cq->find ($table, $condition, @fields);

  $log->msg ("$nbrRecs records qualified");

  while (my %record = $cq->getNext($result)) {
    displayRecord %record;
  } # while
  
  display_duration $startTime, $log;
  
  return;
} # testFindRecord

sub testModifyRecord ($$;%) {
  my ($table, $key, %update) = @_;
  
  my $startTime = time;
  
  $log->msg ("Testing modify table: $table key: $key");
  
  $cq->modify ($table, $key, undef, \%update);
  
  $cq->checkErr;
  
  display_duration $startTime, $log;
  
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
  
  $log->msg ("Testing change state table: $table key: $key action: $action");
  
  $cq->modify ($table, $key, $action, \%update);
  
  $cq->checkErr;
  
  display_duration $startTime, $log; 
  
  return; 
} # testChangeState

sub testAddRecord ($%) {
  my ($table, %record) = @_;
  
  my $startTime = time;
  
  $log->msg ("Testing adding table: $table");
  
  $cq->add ($table, \%record);
  
  $cq->checkErr;
  
  display_duration $startTime, $log;
  
  return;
} # testAddRecord

sub testDeleteRecord ($$) {
  my ($table, $key) = @_;
  
  my $startTime = time;
  
  $log->msg ("Testing deleting table: $table key: $key");
  
  $cq->delete ($table, $key);
  
  $cq->checkErr;

  display_duration $startTime, $log;
  
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

$log = Logger->new;

$cq = Clearquest->new (%opts);

$log->msg ('Connecting to Clearquest database ' . $cq->connection, 1);

unless ($cq->connect) {
  $cq->checkErr ('Unable to connect to database ' . $cq->connection, undef, $log);
  
  if ($cq->module eq 'client') {
    $log->msg ('Unable to connect to server ' . $cq->server () . ':' . $cq->port ());
  } # if
  
  exit $cq->error;
} else {
  $log->msg ('');
  display_duration $startTime, $log;
} # unless

$cq->setOpts (emptyStringForUndef => 1);

if ($opts{get}) {
  # Get record by key
  testGetRecord 'WOR', 'XTST100000019'; 

  # Get record by condition
  testFindRecord 'WOR', 'Owner = "ccadm"';

  # Get record by key with field list
  testFindRecord 'WOR', 'Owner = "ccadm"', ('id', 'Headline',   'Owner');

  # Get record by condition with field list
  testFindRecord 'WOR', 'Owner = "ccadm"', ('id', 'Headline', 'Owner');
} # if

if ($opts{add}) {
  # Add a record
  testAddRecord    'Component', (
    Name          => $FindBin::Script,
    Description   => 'This is a test component',
  );
} # if

if ($opts{modify}) {
  # Modify a record
  my $newDescription = 'This is a modified test component';

  testModifyRecord ('Component', $FindBin::Script, (Description => $newDescription));

  # Make sure the modification happened
  my %component = $cq->get ('Component', $FindBin::Script, ('Description'));

  if ($component{Description} ne $newDescription) {
    $log->err ('Modification of Component.Description failed!');
  } # if
} # if

if ($opts{change}) {
  # Change State
  testChangeState 'Defect', 'apd00000034';
} # if

if ($opts{add}) {
  # Delete that record
  testDeleteRecord 'Component', $FindBin::Script;
} # if

$log->msg ('Total process time ', 1);

display_duration $processStartTime, $log;
