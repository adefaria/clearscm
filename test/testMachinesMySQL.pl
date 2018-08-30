#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Long;
use Pod::Usage; 

use FindBin;

use lib "$FindBin::Bin/../lib";

use Display;
use Machines::MySQL;
use Utils;

my %opts = (
  usage    => sub { podusage() } ,
  hostname => $ENV{HOST}     || 'localhost',
  username => $ENV{USERNAME} ? $ENV{USERNAME} : $ENV{USER},
  password => $ENV{PASSWORD},
  database => 0,
);

sub AddSystems($) {
  my ($machines) = @_;

  my @machines = $machines->ReadSystemsFile;

  for (@machines) {
    my ($err, $msg) = $machines->AddSystem(%$_);

    error ($msg) if $err;
  } # for
} # AddSystems

GetOptions (
  \%opts,
  'usage',
  'host=s',
  'username=s',
  'password=s',
  'database',
  'filename=s',
);

my $machines;

unless ($opts{database}) {
  require Machines; Machines->import;

  $machines = Machines->new(filename => $opts{filename});
} else {
  require Machines::MySQL; Machines::MySQL->import;

  $machines = Machines::MySQL->new;
} # if

#for ($machines->select ("os = '2.4.21-50.Elsmp'")) {

if (ref($machines) eq 'Machines') {
  display "From file:";
} elsif (ref($machines) eq 'Machines::MySQL') {
  display "From database";
} # if

my %records = $machines->select;

for (sort keys %records) {
  display "Would execute command on $_ ($records{$_}{model})";
} # for

display "done";
