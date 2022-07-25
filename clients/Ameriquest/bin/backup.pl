#!/usr/bin/perl
#################################################################################
#
# File:         backup.pl
# Description:  This script performs backups of vobs. By backup we mean that it
#		will lock a vob then copy that vobs storage area to another area
#		on disk then unlock the vob.
# Author:       Andrew@DeFaria.com
# Created:      June 23, 2004
# Language:     Perl
# Warnings:	Since we use Windows commands like xcopy this script will only
#		work under Windows.
#
# (c) Copyright 2004, Andrew@DeFaria.com, all rights reserved.
#
################################################################################
use strict;
use warnings;

my $me = $0;

$me =~ s/\.\///;

my $backup_loc	= "d:\\backup";
my $history_loc	= "d:\\vobstore\\backup";
my $from_loc	= "d:\\";
my $vob_server	= "rtnlprod01";
my $day_nbr	= (localtime ()) [6]; # Day # of week.
my $total_size;

# Options
my $verbose	= "no";

sub Duration {
  use integer;

  my $start_time = shift;
  my $end_time   = shift;

  my $hours;
  my $minutes;
  my $seconds = $end_time - $start_time;

  if ($seconds eq 0) {
    return "less than a second";
  } elsif ($seconds eq 1) {
    return "a second";
  } elsif ($seconds < 60) {
    return "$seconds seconds";
  } elsif ($seconds < (60 * 60)) {
    $minutes = $seconds / 60;
    $seconds = $seconds % 60;
    my $minutes_string = ($minutes eq 1) ? "minute" : "minutes";
    my $seconds_string = ($seconds eq 1) ? "second" : "seconds";
    return "$minutes $minutes_string $seconds $seconds_string";
  } else {
    $hours   = $seconds / (60 * 60);
    $seconds = $seconds % (60 * 60);
    $minutes = $seconds / 60;
    $seconds = $seconds % 60;
    my $hours_string   = ($hours   eq 1) ? "hour"   : "hours";
    my $minutes_string = ($minutes eq 1) ? "minute" : "minutes";
    my $seconds_string = ($seconds eq 1) ? "second" : "seconds";
    return "$hours $hours_string $minutes $minutes_string $seconds $seconds_string";
  } # fi
} # Duration

sub Usage {
  print "Usage $me: [-v]";
  print "\nWhere:\n";
  print "\t-v\tVerbose\n";
  exit 1;
} # Usage

sub verbose {
  my $msg = shift;

  print "$msg\n" if $verbose eq "yes";
} # verbose

sub warning {
  my $msg = shift;

  print "$me: WARNING: $msg\n";
} # warning

sub error {
  my $msg	= shift;
  my $errno	= shift;

  print "$me: ERROR ";
  print "# $errno: " if defined $errno;
  print "$msg\n";

  exit $errno if defined $errno;
} # error

sub VobSize {
  my $vob = shift;

  my $size	= 0;
  my $cleartext	= 0;
  my @space	= `cleartool space $vob 2> NUL`;

  foreach (@space) {
    if (/Subtotal $/) {
      ($size) = split;
    } # if
    if (/cleartext/) {
      ($cleartext) = split;
    } # if
  } # foreach

  return $size - $cleartext;
} # VobSize

sub LockVobs {
  my @vobs = @_;

  my $status = 0;

  foreach (@vobs) {
    chomp;
    my $return_code = system "cleartool lock vob:$_ > NUL 2>&1";
    warning "Unable to lock vob $_" if $return_code ne 0;
    $status += $return_code;
  } # foreach

  return $status;
} # LockVobs

sub UnlockVobs {
  my @vobs = @_;

  my $status = 0;

  foreach (@vobs) {
    my $return_code = system "cleartool unlock vob:$_ > NUL 2>&1";
    warning "Unable to unlock vob $_" if $return_code ne 0;
    $status += $return_code;
  } # foreach

  return $status;
} # UnlockVobs

sub MoveOldStorage {
  my $vob_storage_basename = shift;

  my $storage		= "$backup_loc\\$vob_storage_basename";
  my $old_storage_loc	= "$history_loc\\$day_nbr\\$vob_storage_basename";
  my @output;

  if (-e $old_storage_loc) {
    @output = `rmdir /s /q $old_storage_loc`;

    if ($? ne 0) {
      error "Error in removing old storage area $old_storage_loc";
      error (join "\n", @output);
    } else {
      verbose "Removed old storage area $old_storage_loc";
    } # if
  } # if

  @output = `move $storage $old_storage_loc`;

  if ($? ne 0) {
    error "Error in moving storage area $storage to $old_storage_loc";
    error (join "\n", @output);
  } else {
    verbose "Moved old storage $storage to $old_storage_loc";
  } # if
} # MoveOldStorage

sub CopyStorage {
  my $vob			= shift;
  my $from			= shift;
  my $vob_storage_basename	= shift;

  my $to	= "$backup_loc\\$vob_storage_basename";
  my $size	= VobSize $vob;

  $total_size += $size;
  verbose "Copying $vob ($size meg) from $from -> $to";

  my $start_time = time;

  MoveOldStorage $vob_storage_basename if -e $to;

  # Copy storage but exclude any file containing strings found in the
  # d:\backup\exclude.strings file See
  # http://www-1.ibm.com/support/docview.wss?rs=0&q1=being-deleted&uid=swg21129318&loc=en_US&cs=utf-8&cc=us&lang=en
  # for more info.
  my @output = `xcopy $from $to /q /e /i /h /k /x /exclude:d:\\backup\\exclude.strings`;

  my $end_time = time;

  if ($? ne 0) {
    print "Error in copy of vob $vob\n";
    print @output;
  } else {
    verbose "Copying of $vob ($size meg) took " . Duration $start_time, $end_time;
  } # if
} # CopyStorage

# Get parms
while ($#ARGV >= 0) {
  if ($ARGV [0] eq "-v") {
    $verbose = "yes";
    shift;
    next;
  } # if

  if ($ARGV [0] ne "") {
    error "Unknown option: \"" . $ARGV [0] . "\"\n";
    Usage;
  } # if
} # while

# Iterrate through the list of vobs
my $start_time = time;

my @vobs = `cleartool lsvob -short -host $vob_server 2> NUL`;

warning "Unable to lock all vobs" if (LockVobs @vobs) ne 0;

foreach (@vobs) {
  chomp;
  my $line = `cleartool lsvob $_ 2> NUL`;
  chomp $line;
  $line =~ s/\//\\/g;

  my $storage;

  if ($line =~ m/(\\\\\S*)/) {
    $storage = $1;
  } # if

  $storage =~ s/\\\\$vob_server\\/$from_loc/;

  my $vob_storage_basename = substr ($storage, rindex ($storage, "\\") + 1);

  CopyStorage $_, $storage, $vob_storage_basename;
} # foreach

warning "Unable to unlock all vobs" if (UnlockVobs @vobs) ne 0;

my $end_time = time;

verbose "Total of $total_size meg copied in: " . Duration $start_time, $end_time;
# All done...
exit 0;
