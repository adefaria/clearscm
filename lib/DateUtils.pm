=pod

=head1 NAME $RCSfile: DateUtils.pm,v $

Simple date/time utilities

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.32 $

=item Created

Thu Jan  5 11:06:49 PST 2006

=item Modified

$Date: 2013/02/21 05:01:17 $

=back

=head1 SYNOPSIS

Simple date and time utilities for often used date/time functionality.

  my $ymd = YMD;
  my $ymdhm = YMDHM;
  my $timestamp = timestamp;

=head1 DESCRIPTION

Often you just want to simply and quickly get date or date and time in
a YMD or YMDHM format. Note the YMDHM format defined here is YMD\@H:M
and is not well suited for a filename. The timestamp routine returns
YMD_HM.

=head1 ROUTINES

The following routines are exported:

=cut

package DateUtils;

use strict;
use warnings;

use base 'Exporter';

use Carp;
use Time::Local;

use Display;
use Utils;

our @EXPORT = qw (
  Add
  Age
  Compare
  DateToEpoch
  EpochToDate
  FormatDate
  FormatTime
  MDY
  SQLDatetime2UnixDatetime
  SubtractDays
  Today2SQLDatetime
  UnixDatetime2SQLDatetime
  UTCTime
  YMD
  YMDHM
  YMDHMS
  timestamp
  ymdhms
);

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

my $SECS_IN_MIN  = 60;
my $SECS_IN_HOUR = $SECS_IN_MIN * 60; 
my $SECS_IN_DAY  = $SECS_IN_HOUR * 24;

# Forwards
sub Today2SQLDatetime ();
sub DateToEpoch ($);
sub EpochToDate ($);

sub ymdhms {
  my ($time) = @_;

  $time ||= time;

  my (
    $sec,
    $min,
    $hour,
    $mday,
    $mon,
    $year,
    $wday,
    $yday,
    $isdst
  ) = localtime ($time);

  # Adjust month
  $mon++;

  # Adjust year
  $year += 1900;

  # Zero preface month, day, hour and minute
  $mon  = '0' . $mon  if $mon  < 10;
  $mday = '0' . $mday if $mday < 10;
  $hour = '0' . $hour if $hour < 10;
  $min  = '0' . $min  if $min  < 10;
  $sec  = '0' . $sec  if $sec  < 10;

  return $year, $mon, $mday, $hour, $min, $sec;
} # ymdhms

sub julian ($$$) {
  my ($year, $month, $day) = @_;

  my $days = 0;
  my $m    = 1;

  foreach (@months) {
    last if $m >= $month;
    $m++;
    $days += $_;
  } # foreach

  return $days + $day;
} # julian

sub _is_leap_year ($) {
  my ($year) = @_;
  
  return 0 if $year % 4;
  return 1 if $year % 100;
  return 0 if $year % 400;
  
  return 1; 
} # _is_leap_year

sub Add ($%) {
  my ($datetime, %parms) = @_;
  
=pod

=head2 Add ($datetime, %parms)

Add to a datetime

Parameters:

=for html <blockquote>

=over

=item $datetime

Datetime in SQLDatetime format to manipulate.

=item %parms

Hash of parms. Acceptable values are of the following format:

 seconds => $seconds
 minutes => $minutes
 hours   => $hours
 days    => $days
 month   => $month
 
Note that month will simply increment the month number, adjusting for overflow
of year if appropriate. Therefore a date of 2/28/2001 would increase by 1 month
to yield 3/28/2001. And, unfortunately, an increase of 1 month to 1/30/2011 
would incorrectly yeild 2/30/2011!

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item New datetime

=back

=for html </blockquote>

=cut

  my @validKeys = (
    'seconds',
    'minutes',
    'hours',
    'days',
    'months',
  );
  
  foreach (keys %parms) {
    unless (InArray ($_, @validKeys)) {
      croak "Invalid key in DateUtils::Add: $_";
    } # unless
  } # foreach
  
  my $epochTime = DateToEpoch $datetime;
  
  my $amount = 0;
  
  $parms{seconds} ||= 0;
  $parms{minutes} ||= 0;
  $parms{hours}   ||= 0;
  $parms{days}    ||= 0;
  
  $amount += $parms{days}    * $SECS_IN_DAY;
  $amount += $parms{hours}   * $SECS_IN_HOUR;
  $amount += $parms{minutes} * $SECS_IN_MIN;
  $amount += $parms{seconds};
    
  $epochTime += $amount;

  $datetime = EpochToDate $epochTime;
  
  if ($parms{month}) {
    my $years  = $parms{month} / 12;
    my $months = $parms{month} % 12;
     
    my $month = substr $datetime, 5, 2;
    
    $years += ($month + $months) / 12;
    substr ($datetime, 5, 2) = ($month + $months) % 12;
    
    substr ($datetime, 0, 4) = substr ($datetime, 0, 4) + $years;
  } # if
  
  return $datetime;
} # Add

sub Age ($) {
  my ($timestamp) = @_;

=pod

=head2 Age ($timestamp)

Determines how old something is given a timestamp

Parameters:

=for html <blockquote>

=over

=item $timestamp:

Timestamp to age from (Assumed to be earlier than today)

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Number of days between $timestamp and today

=back

=for html </blockquote>

=cut

  my $today      = Today2SQLDatetime;
  my $today_year = substr $today, 0, 4;
  my $month      = substr $today, 5, 2;
  my $day        = substr $today, 8, 2;
  my $today_days = julian $today_year, $month, $day;

  my $timestamp_year = substr $timestamp, 0, 4;
  $month             = substr $timestamp, 5, 2;
  $day               = substr $timestamp, 8, 2;
  my $timestamp_days = julian $timestamp_year, $month, $day;

  if ($timestamp_year > $today_year or
      ($timestamp_days > $today_days and $timestamp_year == $today_year)) {
    return;
  } else {
    my $leap_days = 0;

    for (my $i = $timestamp_year; $i < $today_year; $i++) {
	
      $leap_days++ if $i % 4 == 0;
    } # for

    $today_days += 365 * ($today_year - $timestamp_year) + $leap_days;
    return $today_days - $timestamp_days;
  } # if
} # Age

sub Compare ($$) {
  my ($date1, $date2) = @_;
  
=pod

=head2 Compare ($date2, $date2)

Compares two datetimes returning -1 if $date1 < $date2, 0 if equal or 1 if
$date1 > $date2

Parameters:

=for html <blockquote>

=over

=item $date1

Date 1 to compare

=item $date2

Date 2 to compare

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item -1 if $date1 < $date2, 0 if equal or 1 if $date1 > $date2

=back

=for html </blockquote>

=cut

  return DateToEpoch ($date1) <=> DateToEpoch ($date2);
} # Compare

sub DateToEpoch ($) {
  my ($date) = @_;
  
=pod

=head2 DateToEpoch ($datetime)

Converts a datetime to epoch

Parameters:

=for html <blockquote>

=over

=item $datetime

Datetime to convert to an epoch

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item $epoch

=back

=for html </blockquote>

=cut

  my $year    = substr $date,  0, 4;
  my $month   = substr $date,  5, 2;
  my $day     = substr $date,  8, 2;
  my $hour    = substr $date, 11, 2;
  my $minute  = substr $date, 14, 2;
  my $seconds = substr $date, 17, 2;
  
  my $days;

  for (my $i = 1970; $i < $year; $i++) {
    $days += _is_leap_year ($i) ? 366 : 365;
  } # for
  
  my @monthDays = (
    0,
    31, 
    59,
    90,
    120,
    151,
    181,
    212,
    243,
    273,
    304,
    334,
  );
  
  $days += $monthDays[$month - 1];
  
  $days++
    if _is_leap_year ($year) and $month > 2;
    
 $days += $day - 1;
  
  return ($days   * $SECS_IN_DAY)
       + ($hour   * $SECS_IN_HOUR)
       + ($minute * $SECS_IN_MIN)
       + $seconds;
} # DateToEpoch

sub EpochToDate ($) {
  my ($epoch) = @_;
  
=pod

=head2 EpochToDate ($epoch)

Converts an epoch to a datetime

Parameters:

=for html <blockquote>

=over

=item $epoch

Epoch to convert to a datetime

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item $datetime

=back

=for html </blockquote>

=cut

  my $year = 1970;
  my ($month, $day, $hour, $minute, $seconds);
  my $leapYearSecs = 366 * $SECS_IN_DAY;
  my $yearSecs     = $leapYearSecs - $SECS_IN_DAY;
  
  while () {
    my $amount = _is_leap_year ($year) ? $leapYearSecs : $yearSecs;
    
    last
      if $amount > $epoch;
      
    $epoch -= $amount;
    $year++;
  } # while
  
  my $leapYearAdjustment = _is_leap_year ($year) ? 1 : 0;
  
  if ($epoch >= (334 + $leapYearAdjustment) * $SECS_IN_DAY) {
    $month = '12';
    $epoch -= (334 + $leapYearAdjustment) * $SECS_IN_DAY;
  } elsif ($epoch >= (304 + $leapYearAdjustment) * $SECS_IN_DAY) {
    $month = '11';
    $epoch -= (304 + $leapYearAdjustment) * $SECS_IN_DAY;
  } elsif ($epoch >= (273 + $leapYearAdjustment) * $SECS_IN_DAY) {
    $month = '10';
    $epoch -= (273 + $leapYearAdjustment) * $SECS_IN_DAY;
  } elsif ($epoch >= (243 + $leapYearAdjustment) * $SECS_IN_DAY) {
    $month = '09';
    $epoch -= (243 + $leapYearAdjustment) * $SECS_IN_DAY;
  } elsif ($epoch >= (212 + $leapYearAdjustment) * $SECS_IN_DAY) {
    $month = '08';
    $epoch -= (212 + $leapYearAdjustment) * $SECS_IN_DAY;
  } elsif ($epoch >= (181 + $leapYearAdjustment) * $SECS_IN_DAY) {
    $month = '07';
    $epoch -= (181 + $leapYearAdjustment) * $SECS_IN_DAY;
  } elsif ($epoch >= (151 + $leapYearAdjustment) * $SECS_IN_DAY) {
    $month = '06';
    $epoch -= (151 + $leapYearAdjustment) * $SECS_IN_DAY;
  } elsif ($epoch >= (120 + $leapYearAdjustment) * $SECS_IN_DAY) {
    $month = '05';
    $epoch -= (120 + $leapYearAdjustment) * $SECS_IN_DAY;
  } elsif ($epoch >= (90 + $leapYearAdjustment) * $SECS_IN_DAY) {
    $month = '04';
    $epoch -= (90 + $leapYearAdjustment) * $SECS_IN_DAY;
  } elsif ($epoch >= (59 + $leapYearAdjustment) * $SECS_IN_DAY) {
    $month = '03';
    $epoch -= (59 + $leapYearAdjustment) * $SECS_IN_DAY;
  } elsif ($epoch >= 31 * $SECS_IN_DAY) {
    $month = '02';
    $epoch -= 31 * $SECS_IN_DAY;
  } else {
    $month = '01';
  } # if

  $day     = int (($epoch / $SECS_IN_DAY) + 1);
  $epoch   = $epoch % $SECS_IN_DAY;
  $hour    = int ($epoch / $SECS_IN_HOUR);
  $epoch   = $epoch % $SECS_IN_HOUR;
  $minute  = int ($epoch / $SECS_IN_MIN);
  $seconds = $epoch % $SECS_IN_MIN;
  
  $day     = "0$day"     if $day     < 10;
  $hour    = "0$hour"    if $hour    < 10;
  $minute  = "0$minute"  if $minute  < 10;
  $seconds = "0$seconds" if $seconds < 10;
  
  return "$year-$month-$day $hour:$minute:$seconds";
} # EpochToDate

sub UTCTime ($) {
  my ($datetime) = @_;
  
=pod

=head2 UTCTime ($epoch)

Converts an epoch to UTC Time

Parameters:

=for html <blockquote>

=over

=item $epoch

Epoch to convert to a datetime

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item $datetime

=back

=for html </blockquote>

=cut

  my @localtime = localtime;
  my ($sec, $min, $hour, $mday, $mon, $year) = gmtime (
    DateToEpoch ($datetime) - (timegm (@localtime) - timelocal (@localtime))
  );
      
  $year += 1900;
  $mon++;

  $sec  = '0' . $sec  if $sec  < 10;  
  $min  = '0' . $min  if $min  < 10;  
  $hour = '0' . $hour if $hour < 10;  
  $mon  = '0' . $mon  if $mon  < 10;
  $mday = '0' . $mday if $mday < 10;
      
  return "$year-$mon-${mday}T$hour:$min:${sec}Z";  
} # UTCTime

sub UTC2Localtime ($) {
  my ($utcdatetime) = @_;
  
  # If the field does not look like a UTC time then just return it.
  return $utcdatetime unless $utcdatetime =~ /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/;

  $utcdatetime =~ s/T/ /;
  $utcdatetime =~ s/Z//;

  my @localtime = localtime;

  return EpochToDate (
    DateToEpoch ($utcdatetime) + (timegm (@localtime) - timelocal (@localtime))
  );
} # UTC2Localtime

sub FormatDate ($) {
  my ($date) = @_;

=pod

=head2 FormatDate ($date)

Formats date

Parameters:

=for html <blockquote>

=over

=item $date:

Date in YYYYMMDD

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Returns a date in MM/DD/YYYY format

=back

=for html </blockquote>

=cut

  return substr ($date, 4, 2)
       . "/"
       . substr ($date, 6, 2)
       .  "/"
       . substr ($date, 0, 4);
} # FormatDate

sub FormatTime ($) {
  my ($time) = @_;

=pod

=head2 FormatTime ($time)

Formats Time

Parameters:

=for html <blockquote>

=over

=item $time:

Time in in HH:MM format (24 hour format)

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Time in HH:MM [Am|Pm] format

=back

=for html </blockquote>

=cut

  my $hours   = substr $time, 0, 2;
  my $minutes = substr $time, 3, 2;
  my $AmPm    = $hours > 12 ? "Pm" : "Am";

  $hours = $hours - 12 if $hours > 12;

  return "$hours:$minutes $AmPm";
} # FormatTime

sub MDY (;$) {
  my ($time) = @_;

=pod

=head2 MDY ($time)

Returns MM/DD/YYYY for $time

Parameters:

=for html <blockquote>

=over

=item $time:

Time in Unix time format (Default: current time)

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Date in MM/DD/YYYY

=back

=for html </blockquote>

=cut

  my ($year, $mon, $mday) = ymdhms $time;

  return "$mon/$mday/$year";
} # MDY

sub SQLDatetime2UnixDatetime ($) {
  my ($sqldatetime) = @_;

=pod

=head2 SQLDatetime2UnixDatetime ($sqldatetime)

Converts an SQL formatted date to a Unix (localtime) formatted date)

Parameters:

=for html <blockquote>

=over

=item $sqldatetime:

Date and time stamp in SQL format

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Returns a Unix formated date and time (a la localtime)

=back

=for html </blockquote>

=cut

  my %months = (
    "01" => "Jan",
    "02" => "Feb",
    "03" => "Mar",
    "04" => "Apr",
    "05" => "May",
    "06" => "Jun",
    "07" => "Jul",
    "08" => "Aug",
    "09" => "Sep",
    "10" => "Oct",
    "11" => "Nov",
    "12" => "Dec"
  );

  my $year  = substr $sqldatetime, 0, 4;
  my $month = substr $sqldatetime, 5, 2;
  my $day   = substr $sqldatetime, 8, 2;
  my $time  = FormatTime (substr $sqldatetime, 11);

  return $months{$month} . " $day, $year \@ $time";
} # SQLDatetime2UnixDatetime

sub SubtractDays ($$) {
  my ($timestamp, $nbr_of_days) = @_;

=pod

=head2 SubtractDays ($timestamp, $nbr_of_days)

Subtracts $nbr_of_days from $timestamp

Parameters:

=for html <blockquote>

=over

=item $timestamp:

Timestamp to subtract days from

=back

=over

=item $nbr_of_days:

=back

Number of days to subtract from $timestamp

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item SQL format date $nbr_of_days ago

=back

=for html </blockquote>

=cut

  my $year  = substr $timestamp, 0, 4;
  my $month = substr $timestamp, 5, 2;
  my $day   = substr $timestamp, 8, 2;

  # Convert to Julian
  my $days = julian $year, $month, $day;

  # Subtract $nbr_of_days
  $days -= $nbr_of_days;

  # Compute $days_in_year
  my $days_in_year;

  # Adjust if crossing year boundary
  if ($days <= 0) {
    $year--;
    $days_in_year = (($year % 4) == 0) ? 366 : 365;
    $days = $days_in_year + $days;
  } else {
    $days_in_year = (($year % 4) == 0) ? 366 : 365;
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
    $month = "0" . $month;
  } # if

  # Prefix days with  0 if necessary
  if ($days == 0) {
    $days = "01";
  } elsif ($days < 10) {
    $days = "0" . $days;
  } # if

  return $year . "-" . $month . "-" . $days . substr $timestamp, 10;
} # SubtractDays

sub Today2SQLDatetime () {

=pod

=head2 Today2SQLDatetime ($datetime)

Returns today's date in an SQL format

Parameters:

=for html <blockquote>

=over

=item None

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item SQL formated time stamp for today

=back

=for html </blockquote>

=cut

  return UnixDatetime2SQLDatetime (scalar (localtime));
} # Today2SQLDatetime

sub UnixDatetime2SQLDatetime ($) {
  my ($datetime) = @_;

=pod

=head2 UnixDatetime2SQLDatetime ($datetime)

Converts a Unix (localtime) date/time stamp to an SQL formatted
date/time stamp

Parameters:

=for html <blockquote>

=over

=item $datetime:

Unix formated date time stamp

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item SQL formated time stamp

=back

=for html </blockquote>

=cut

  my $orig_datetime = $datetime;
  my %months = (
    Jan => '01',
    Feb => '02',
    Mar => '03',
    Apr => '04',
    May => '05',
    Jun => '06',
    Jul => '07',
    Aug => '08',
    Sep => '09',
    Oct => '10',
    Nov => '11',
    Dec => '12',
  );

  # Some mailers neglect to put the leading day of the week field in.
  # Check for this and compensate.
  my $dow = substr $datetime, 0, 3;

  if ($dow ne 'Mon' and
      $dow ne 'Tue' and
      $dow ne 'Wed' and
      $dow ne 'Thu' and
      $dow ne 'Fri' and
      $dow ne 'Sat' and
      $dow ne 'Sun') {
    $datetime = 'XXX, ' . $datetime;
  } # if

  # Some mailers have day before month. We need to correct this
  my $day = substr $datetime, 5, 2;

  if ($day =~ /\d /) {
    $day      = '0' . (substr $day, 0, 1);
    $datetime = (substr $datetime, 0, 5) . $day . (substr $datetime, 6);
  } # if

  if ($day !~ /\d\d/) {
    $day = substr $datetime, 8, 2;
  } # if

  # Check for 1 digit date
  if ((substr $day, 0, 1) eq ' ') {
    $day      = '0' . (substr $day, 1, 1);
    $datetime = (substr $datetime, 0, 8) . $day . (substr $datetime, 10);
  } elsif ((substr $day, 1, 1) eq ' ') {
    $day      = '0' . (substr $day, 0, 1);
    $datetime = (substr $datetime, 0, 8) . $day . (substr $datetime, 9);
  } # if

  my $year = substr $datetime, 20, 4;

  if ($year !~ /\d\d\d\d/) {
    $year = substr $datetime, 12, 4;
    if ($year !~ /\d\d\d\d/) {
      $year = substr $datetime, 12, 2;
    } #if
  } # if

  # Check for 2 digit year. Argh!
  if (length $year == 2 or (substr $year, 2, 1) eq ' ') {
    $year     = '20' . (substr $year, 0, 2);
    $datetime = (substr $datetime, 0, 12) . '20' . (substr $datetime, 12);
  } # if

  my $month_name = substr $datetime, 4, 3;

  unless ($months{$month_name}) {
    $month_name = substr $datetime, 8, 3;
  } # unless
  
  my $month = $months{$month_name};
  my $time  = substr $datetime, 11, 8;

  if ($time !~ /\d\d:\d\d:\d\d/) {
    $time = substr $datetime, 17, 8
  } # if

  unless ($year) {
    warning "Year undefined for $orig_datetime\nReturning today's date";
    return Today2SQLDatetime;
  } # unless
    
  unless ($month) {
    warning "Month undefined for $orig_datetime\nReturning today's date";
    return Today2SQLDatetime;
  } # unless
  
  unless ($day) {
    warning "Day undefined for $orig_datetime\nReturning today's date";
    return Today2SQLDatetime;
  } # unless

  unless ($time) {
    warning "Time undefined for $orig_datetime\nReturning today's date";
    return Today2SQLDatetime;
  } # unless

  return "$year-$month-$day $time";
} # UnixDatetime2SQLDatetime

sub YMD (;$) {
  my ($time) = @_;

=pod

=head2 YMD ($time)

Returns the YMD in a format of YYYYMMDD

Parameters:

=for html <blockquote>

=over

=item $time:

Time to convert to YYYYMMDD (Default: Current time)

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Date in YYYYMMDD format

=back

=for html </blockquote>

=cut

  my ($year, $mon, $mday) = ymdhms $time;

  return "$year$mon$mday";
} # YMD

sub YMDHM (;$) {
  my ($time) = @_;

=pod

=head2 YMDHM ($time)

Returns the YMD in a format of YYYYMMDD@HH:MM

Parameters:

=for html <blockquote>

=over

=item $time:

Time to convert to YYYYMMDD@HH:MM (Default: Current time)

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Date in YYYYMMDD@HH:MM format

=back

=for html </blockquote>

=cut

  my ($year, $mon, $mday, $hour, $min) = ymdhms $time;

  return "$year$mon$mday\@$hour:$min";
} # YMDHM

sub YMDHMS (;$) {
  my ($time) = @_;

=pod

=head2 YMDHMS ($time)

Returns the YMD in a format of YYYYMMDD@HH:MM:SS

Parameters:

=for html <blockquote>

=over

=item $time:

Time to convert to YYYYMMDD@HH:MM:SS (Default: Current time)

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Date in YYYYMMDD@HH:MM:SS format

=back

=for html </blockquote>

=cut

  my ($year, $mon, $mday, $hour, $min, $sec) = ymdhms $time;

  return "$year$mon$mday\@$hour:$min:$sec";
} # YMDHMS

sub timestamp (;$) {
  my ($time) = @_;

=pod

=head2 timestamp ($time)

Returns the YMD in a format of YYYYMMDD_HHMM

Parameters:

=for html <blockquote>

=over

=item $time:

Time to convert to YYYYMMDD_HHMMSS (Default: Current time)

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Date in YYYYMMDD_HHMMSS format

=back

=for html </blockquote>

=cut

  my ($year, $mon, $mday, $hour, $min, $sec) = ymdhms $time;

  return "$year$mon${mday}_$hour$min$sec";
} # timestamp

1;

=head2 DEPENDENCIES

=head3 Perl Modules

=for html <p><a href="/php/cvs_man.php?file=lib/Display.pm">Display</a></p>

=head1 INCOMPATABILITIES

None yet...

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head1 LICENSE AND COPYRIGHT

This Perl Module is freely available; you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation; either version 2 of the
License, or (at your option) any later version.

This Perl Module is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License (L<http://www.gnu.org/copyleft/gpl.html>) for more
details.

You should have received a copy of the GNU General Public License
along with this Perl Module; if not, write to the Free Software Foundation,
Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
reserved.

=cut
