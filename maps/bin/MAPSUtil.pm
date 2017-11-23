#!/usr/bin/perl
################################################################################
#
# File:         $RCSfile: MAPSUtil.pm,v $
# Revision:     $Revision: 1.1 $
# Description:  MAPS Utilities
# Author:       Andrew@DeFaria.com
# Created:      Fri Nov 29 14:17:21  2002
# Modified:     $Date: 2013/06/12 14:05:47 $
# Language:     perl
#
# (c) Copyright 2000-2006, Andrew@DeFaria.com, all rights reserved.
#
################################################################################
package MAPSUtil;

use strict;
use vars qw (@ISA @EXPORT);

BEGIN {
  $ENV{TZ}='America/Los_Angeles';
} # BEGIN

@ISA = qw (Exporter);

@EXPORT = qw (
  FormatDate
  FormatTime
  SQLDatetime2UnixDatetime
  SubtractDays
  Today2SQLDatetime
  UnixDatetime2SQLDatetime
);

sub Today2SQLDatetime;

sub FormatDate {
  my ($date) = @_;

  return substr ($date, 5, 2)  . '/' .
         substr ($date, 8, 2)  . '/' .
         substr ($date, 0, 4);
} # FormatDate

sub FormatTime {
  my ($time) = @_;

  my $hours   = substr $time, 0, 2;

  $hours = substr $hours, 1, 1 if $hours < 10;

  my $minutes = substr $time, 3, 2;
  my $seconds = substr $time, 6, 2;
  my $AmPm    = $hours > 12 ? 'Pm' : 'Am';

  $hours = $hours - 12 if $hours > 12;

  return "$hours:$minutes:$seconds $AmPm";
} # FormatTime

sub SQLDatetime2UnixDatetime {
  my ($sqldatetime) = @_;

  my %months = (
    '01' => 'Jan',
    '02' => 'Feb',
    '03' => 'Mar',
    '04' => 'Apr',
    '05' => 'May',
    '06' => 'Jun',
    '07' => 'Jul',
    '08' => 'Aug',
    '09' => 'Sep',
    '10' => 'Oct',
    '11' => 'Nov',
    '12' => 'Dec',
  );

  my $year  = substr $sqldatetime, 0, 4;
  my $month = substr $sqldatetime, 5, 2;
  my $day   = substr $sqldatetime, 8, 2;
  my $time  = FormatTime substr $sqldatetime, 11;

  return $months {$month} . " $day, $year \@ $time";
} # SQLDatetime2UnixDatetime

sub SubtractDays {
  my ($timestamp,$nbr_of_days) = @_;

  my @months = (
    31, # January
    28, # February
    31, # March
    30, # April
    31, # May
    30, # June
    31, # July
    31, # August
    30, # September
    31, # October
    30, # November
    31  # Descember
  );

  my $year  = substr $timestamp, 0, 4;
  my $month = substr $timestamp, 5, 2;
  my $day   = substr $timestamp, 8, 2;

  # Convert to Julian
  my $days = 0;
  my $m    = 1;

  for (@months) {
    last if $m >= $month;
    $m++;
    $days += $_;
  } # for

  # Subtract $nbr_of_days
  $days += $day - $nbr_of_days;

  # Compute $days_in_year
  my $days_in_year;

  # Adjust if crossing year boundary
  if ($days <= 0) {
    $year--;
    $days_in_year = (($year % 4) eq 0) ? 366 : 365;
    $days = $days_in_year + $days;
  } else {
    $days_in_year = (($year % 4) eq 0) ? 366 : 365;
  } # if

  # Convert back
  $month = 0;

  while ($days > 28) {
    # If remaining days is less than the current month then last
    last if ($days <= $months[$month]);

    # Subtract off the number of days in this month
    $days -= $months[$month++];
  } # while

  # Prefix month with 0 if necessary
  $month++;
  if ($month < 10) {
    $month = '0' . $month;
  } # if

  # Prefix days with 0 if necessary
  if ($days == 0) { 
     $days = '01';
  } elsif ($days < 10) {
    $days = '0' . $days;
  } # if  

  return $year . '-' . $month . '-' . $days . substr $timestamp, 10;
} # SubtractDays

sub UnixDatetime2SQLDatetime {
  my $datetime = shift;

  my $orig_datetime = $datetime;
  my %months = (
    'Jan' => '01',
    'Feb' => '02',
    'Mar' => '03',
    'Apr' => '04',
    'May' => '05',
    'Jun' => '06',
    'Jul' => '07',
    'Aug' => '08',
    'Sep' => '09',
    'Oct' => '10',
    'Nov' => '11',
    'Dec' => '12',
  );

  # Some mailers neglect to put the leading day of the week field in.
  # Check for this and compensate.
  my $dow = substr $datetime, 0, 3;

  if ($dow ne 'Mon' &&
      $dow ne 'Tue' &&
      $dow ne 'Wed' &&
      $dow ne 'Thu' &&
      $dow ne 'Fri' &&
      $dow ne 'Sat' &&
      $dow ne 'Sun') {
    $datetime = 'XXX, ' . $datetime;
  } # if

  # Some mailers have day before month. We need to correct this
  my $day = substr $datetime, 5, 2;

  if ($day =~ /\d /) {
    $day = '0' . (substr $day, 0, 1);
    $datetime = (substr $datetime, 0, 5) . $day . (substr $datetime, 6);
  } # if

  if ($day !~ /\d\d/) {
    $day = substr $datetime, 8, 2;
  } # if

  # Check for 1 digit date
  if ((substr $day, 0, 1) eq ' ') {
    $day = '0' . (substr $day, 1, 1);
    $datetime = (substr $datetime, 0, 8) . $day . (substr $datetime, 10);
  } # if

  my $year  = substr $datetime, 20, 4;

  if ($year !~ /\d\d\d\d/) {
    $year = substr $datetime, 12, 4;
    if ($year !~ /\d\d\d\d/) {
      $year = substr $datetime, 12, 2;
    } #if
  } # if

  # Check for 2 digit year. Argh!
  if (length $year == 2 or (substr $year, 2, 1) eq ' ') {
      $year = '20' . (substr $year, 0, 2);
      $datetime = (substr $datetime, 0, 12) . '20' . (substr $datetime, 12);
  } # if

  my $month_name = substr $datetime, 4, 3;

  if (!defined $months {$month_name}) {
    $month_name = substr $datetime, 8, 3;
  } # if
  my $month = $months {$month_name};

  my $time  = substr $datetime, 11, 8;

  if ($time !~ /\d\d:\d\d:\d\d/) {
    $time = substr $datetime, 17, 8
  } # if

  if (!defined $year) {
    print "WARNING: Year undefined for $orig_datetime\nReturning today's date\n";
    return Today2SQLDatetime;
  } # if
  if (!defined $month) {
    print "Month undefined for $orig_datetime\nReturning today's date\n";
    return Today2SQLDatetime;
  } # if
  if (!defined $day) {
    print "Day undefined for $orig_datetime\nReturning today's date\n";
    return Today2SQLDatetime;
  } # if
  if (!defined $time) {
    print "Time undefined for $orig_datetime\nReturning today's date\n";
    return Today2SQLDatetime;
  } # if

  return "$year-$month-$day $time";
} # UnixDatetime2SQLDatetime

sub Today2SQLDatetime {
  return UnixDatetime2SQLDatetime scalar localtime;
} # Today2SQLDatetime

1;
