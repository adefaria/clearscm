#!/usr/brcm/ba/bin/perl
use strict;
use warnings;

use FindBin;
use Getopt::Long;

use lib "$FindBin::Bin/../lib";

use Clearquest::REST;
use Display;
use Utils;

my $cq;

=pod

Usage $FindBin::Script: [-get] [-add] [-modify] [-change] [-delete]

=cut

END {
  # Always remember to call disconnect for any instanciated Clearquest::REST
  # object
  $cq->disconnect if $cq;
} # END

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
} # displayRecord

sub displayResults (@) {
  my (@records) = @_;
  
  if (@records) {
    displayRecord %$_ foreach (@records);
  } else {
    display "Did not find any records";
  } # if
} # displayResults

sub testGetRecord ($$;@) {
  my ($table, $key, @fields) = @_;
  
  display "Testing get table: $table key: $key";
  
  displayRecord $cq->get ($table, $key, @fields);  
} # testGetRecord

sub testFindRecord ($$;@) {
  my ($table, $condition, @fields) = @_;
  
  display "Testing find table: $table condition: $condition";
  
  my ($result, $nbrRecs) = $cq->find ($table, $condition, @fields);

  display "$nbrRecs records qualified";

  while (my %record = $cq->getNext ($result)) {
    displayRecord %record;
  } # while
} # testFindRecord

sub testModifyRecord ($$;%) {
  my ($table, $key, %update) = @_;
  
  display "Testing modify table: $table key: $key";
  
  my $errmsg = $cq->modify ($table, $key, undef, %update);
  
  display $errmsg;
} # testModifyRecord

sub testChangeState ($$) {
  my ($table, $key) = @_;
  
  my %record = $cq->get ($table, $key, ('State'));

  my ($action, %update);
  
  if ($record{State} eq 'Assigned') {
    $action                  = 'AdminAssignToSubmit';
    $update{Stability_Issue} = 'User Fault';
  } else {
    $action                  = 'Assign';
    $update{Stability_Issue} = 'Assert';
  } # if
  
  display "Testing change state table: $table key: $key action: $action";
  
  my $errmsg = $cq->modify ($table, $key, $action, %update);
  
  display $errmsg;
} # testChangeState

sub testAddRecord ($%) {
  my ($table, %record) = @_;
  
  display "Testing adding table: $table";
  
  my $errmsg = $cq->add ($table, %record);
  
  display $errmsg;
} # testAddRecord

sub testDeleteRecord ($$) {
  my ($table, $key) = @_;
  
  display "Testing deleting table: $table key: $key";
  
  my $errmsg = $cq->delete ($table, $key);
  
  display $errmsg;
} # testDeleteRecord

my %opts;

GetOptions (
  \%opts,
  'get',
  'add',
  'modify',
  'change',
  'delete'
) || Usage;

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

$cq = Clearquest::REST->new;

if ($opts{get}) {
  # Get record by key
  testGetRecord 'Project', 'Athena';

  # Get record by condition
  testFindRecord 'VersionInfo', 'Deprecated = 1';

  # Get record by key with field list
  testFindRecord 'VersionInfo', 'VersionStr = 1.0', ('VersionStr',   'Deprecated');

  # Get record by condition with field list
  testFindRecord 'CategorySub', 'Category="Customer-HW"', ('Category', 'CategoryType', 'SubCategory');
} # if

if ($opts{add}) {
  # Add a record
  testAddRecord    'VersionInfo', (
    VersionStr => '2.0',
    Projects   => {
      Project  => ['Island', '21331', 'Hera'],
    },
    Visibility => 'Nokia Corporation',
  );
} # if

if ($opts{modify}) {
  # Modify a record
  testModifyRecord ('VersionInfo', '1.0', (
    Deprecated => 1,
    Projects   => { 
      Project => ['Island', 'Athena'],
    },
  ));
} # if

if ($opts{change}) {
  # Change State
  testChangeState 'Defect', 't_sbx00018584';
} # if

if ($opts{add}) {
  # Delete that record
  testDeleteRecord 'VersionInfo', '2.0';
} # if

display "done";
