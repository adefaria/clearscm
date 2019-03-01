#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Display;
use CmdLine;

sub _is_leap_year($) {
  my ($year) = @_;

  return 0 if $year % 4;
  return 1 if $year % 100;
  return 0 if $year % 400;

  return 1; 
} # _is_leap_year

sub MDYHMS2SQLDatetime($) {
  my ($datetime) = @_;

  $datetime =~ s/^\s+|\s+$//g;

  my ($year, $mon, $day, $hour, $min, $sec, $ampm);

  # For datetime format of MM/DD/YYYY HH:MM:SS [Am|Pm]
  if ($datetime =~ /^(\d{1,2})\/(\d{1,2})\/(\d{4}) (\d{1,2}):(\d{1,2}):(\d{1,2}) (\w{2})$/) {
    $mon   = $1;
    $day   = $2;
    $year  = $3;
    $hour  = $4;
    $min   = $5;
    $sec   = $6;
    $ampm  = $7;
  # For datetime format of MM/DD/YYYY HH:MM:SS
  } elsif ($datetime =~ /^(\d{1,2})\/(\d{1,2})\/(\d{4}) (\d{1,2}):(\d{1,2}):(\d{1,2})$/){
    $mon   = $1;
    $day   = $2;
    $year  = $3;
    $hour  = $4;
    $min   = $5;
    $sec   = $6;
  # For datetime format of MM/DD/YYYY
  } elsif ($datetime =~ /^(\d{1,2})\/(\d{1,2})\/(\d{4})$/) {
    $mon   = $1;
    $day   = $2;
    $year  = $3;
    $hour  = '00';
    $min   = '00';
    $sec   = '00';
  } else {
    return
  } # if

  # Range checks
  return if $mon  > 12 or $mon  <= 0;
  return if $day  > 31 or $day  <= 0;
  return if $hour > 23 or $hour <  0;
  return if $min  > 59 or $min  <  0;

  if ($day >= 31 and ($mon == 2
                   or $mon == 4
                   or $mon == 6
                   or $mon == 9
                   or $mon == 11)) {
    return;
  } # if

  return if $day >  29 and  $mon == 2;
  return if $day == 29 and  $mon == 2 and not _is_leap_year($year);

  # Convert to 24 hour time if necessary
  $hour += 12 if $ampm and $ampm =~ /pm/i;

  # Add any leading zeros
  $mon  = "0$mon"  if length $mon  == 1;
  $day  = "0$day"  if length $day  == 1;
  $hour = "0$hour" if length $hour == 1;
  $min  = "0$min"  if length $min  == 1;
  $sec  = "0$sec"  if length $sec  == 1;

  return "$year-$mon-$day $hour:$min:$sec";
} # MDYHMS2SQLDatetime

local $| = 1;

$CmdLine::cmdline->set_prompt('Enter datetime:');

while () {
  my $datetime = $CmdLine::cmdline->get;

  last unless defined $datetime;
  last if $datetime =~ /(exit|quit|e|q)/i;

  if ($datetime) {
    my $newdatetime = MDYHMS2SQLDatetime $datetime;

    if ($newdatetime) {
      display $newdatetime;
    } else {
      error "Date $datetime is invalid";
    } # if
  } # if
} # while
