#!/usr/bin/perl
use strict;
use warnings;

my $windows	= $^O =~ /MSWin/ ? "yes" : "no";
my $vob_server	= "rtnlprod01";

sub VobSize {
  my $vob = shift;

  my @space;

  if ($windows eq "yes") {
    @space = `cleartool space $vob 2>&1`;
  } else {
    @space = `cleartool space \\$vob 2>&1`;
  } # if

  foreach (@space) {
    chomp; chop if /\r/;
    if (/Subtotal $/) {
      my ($size) = split;
      return $size;
    } # if
  } # foreach

  return 0;
} # VobSize

my (
  $vob,
  $size,
  $count,
  $total_size
);

format STDOUT_TOP =
 Nbr VOB                            Size
---- ----------------------- -----------
.
format STDOUT =
@>>) @<<<<<<<<<<<<<<<<<<<<<< @>>>>>> Meg
$count,$vob,$size
.

format TOTAL_TOP =
---- ----------------------- -----------
.

format TOTAL_LINE =
Total vob size:              @>>>>>> Meg
$total_size
.

my @vobs = `cleartool lsvob -short -host $vob_server`;

foreach $vob (sort (@vobs)) {
  $count++;
  chomp $vob; chop $vob if $vob =~ /\r/;

  $size = VobSize $vob;

  $total_size += $size;

  write; $- = 1;
} # foreach

$~ = "TOTAL_TOP";
write; $- = 1;

$~ = "TOTAL_LINE";
write; $- = 1;
