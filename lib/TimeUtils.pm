=pod

=head1 NAME $RCSfile: TimeUtils.pm,v $

Common time utilities

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.13 $

=item Created

Fri Mar 12 10:17:44 PST 2004

=item Modified

$Date: 2012/11/13 23:34:13 $

=back

=head1 SYNOPSIS

This module seeks to handle time and duration entities in a simple
manner. Given a time(3) structure we have routines to format out, in a
human readable form, a duration.

 my $startTime = time;

 # Do something that takes time...

 # Display how long that took
 display_duration $startTime;

 # Displays how long that took into $log (See Logger.pm)
 display_duration $startTime, $log;

 # Get a date timestamp for today
 my $yyyymmdd = format_yyyymmdd;

 # Get a human readable duration between $startTime 
 # and the current time
 my $duration = howlong $startTime, time;

=head1 DESCRIPTION

This module exports a few time/duration related routines

=head1 ROUTINES

The following routines are exported:

=cut

package TimeUtils;

use strict;
use warnings;

use base "Exporter";
use File::Spec;

our @EXPORT = qw (
  display_duration
  format_yyyymmdd
  howlong
);

use Display;
use Logger;

sub howlong ($;$) {
  my ($start_time, $end_time) = @_;

=pod

=head2 howlong ($start_time, $end_time)

Returns a string that represents a human readable version of the
duration of time between $start_time and $end_time. For example, "1
hour, 10 minues and 5 seconds".

Parameters:

=for html <blockquote>

=over

=item $start_time

Time that represents the start time of the time period.

=item $end_time

Time that represents the end time of the time period. (Default;
Current time)

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item $duration string

=back

=for html </blockquote>

=cut

  $end_time ||= time;

  return if $start_time > $end_time;

  my $difference = $end_time - $start_time;

  my $seconds_per_min  = 60;
  my $seconds_per_hour = 60 * $seconds_per_min;
  my $seconds_per_day  = $seconds_per_hour * 24;

  my $days    = 0;
  my $hours   = 0;
  my $minutes = 0;
  my $seconds = 0;

  if ($difference > $seconds_per_day) {
    $days       = int ($difference / $seconds_per_day);
    $difference = $difference % $seconds_per_day;
  } # if

  if ($difference > $seconds_per_hour) {
    $hours      = int ($difference / $seconds_per_hour);
    $difference = $difference % $seconds_per_hour;
  } # if

  if ($difference > $seconds_per_min) {
    $minutes    = int ($difference / $seconds_per_min);
    $difference = $difference % $seconds_per_min;
  } # if

  $seconds = $difference;

  my $day_str  = '';
  my $hour_str = '';
  my $min_str  = '';
  my $sec_str  = '';
  my $duration = '';

  if ($days > 0) {
    $day_str  = $days == 1 ? '1 day' : "$days days";
    $duration = $day_str;
  } # if

  if ($hours > 0) {
    $hour_str = $hours == 1 ? '1 hour' : "$hours hours";

    if ($duration ne '') {
      $duration .= ' ' . $hour_str;
    } else {
      $duration = $hour_str;
    } # if
  } # if

  if ($minutes > 0) {
    $min_str = $minutes == 1 ? '1 minute' : "$minutes minutes";

    if ($duration ne '') {
      $duration .= ' ' . $min_str;
    } else {
      $duration = $min_str;
    } # if
  } # if

  if ($seconds > 0) {
    $sec_str = $seconds == 1 ? '1 second' : "$seconds seconds";

    if ($duration ne '') {
      $duration .= ' ' . $sec_str;
    } else {
      $duration = $sec_str;
    } # if
  } # if

  if ($duration eq '' and $seconds == 0) {
    $duration = 'under 1 second';
  } # if

  return $duration;
} # howlong

sub display_duration ($;$) {
  my ($start_time, $log) = @_;

=pod

=head2 display_duration ($start_time, $log)

Displays the duration between $start_time and now to STDOUT (or
optionally to log it to $log - See Logger)

Parameters:

=for html <blockquote>

=over

=item $start_time

Time that represents the start time of the time period.

=item $log

Log object to long durtion to.

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Nothing

=back

=for html </blockquote>

=cut

  unless ($start_time) {
    if ($log) {
      $log->msg ('Finished in 0 seconds');
    } else {
      display 'Finished in 0 seconds';
    } # if
  } # unless

  my $end_time = time;
  my $duration = howlong $start_time, $end_time;

  if ($log) {
    $log->msg ("Finished in $duration");
  } else {
    display "Finished in $duration";
  } # if

  return;
} # display_duration

sub format_yyyymmdd ($) {
  my ($time) = @_;

=pod

=head2 format_yyyymmdd ($time)

Quickly returns a YYYYMMDD format date for $time. If $time is not
specified then it returns today.

Parameters:

=for html <blockquote>

=over

=item $time

The $time to get the date from

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Date string in YYYYMMDD format for $time

=back

=for html </blockquote>

=cut

  $time ||= time;

  my ($sec, $min, $hour, $mday, $mon, $year) = localtime ($time);

  $year += 1900;
  $mon++;
  $mon   = $mon  < 10 ? "0$mon"  : $mon;
  $mday  = $mday < 10 ? "0$mday" : $mday;

  return '$year$mon$mday';
} # format_yyyymmdd

1;

=head1 CONFIGURATION AND ENVIRONMENT

DEBUG: If set then $debug is set to this level.

VERBOSE: If set then $verbose is set to this level.

TRACE: If set then $trace is set to this level.

=head1 DEPENDENCIES

=head2 Perl Modules

L<File::Spec|File::Spec>

=head2 ClearSCM Perl Modules

=for html <p><a href='/php/scm_man.php?file=lib/Display.pm'>Display</a></p>

=for html <p><a href='/php/scm_man.php?file=lib/Logger.pm'>Logger</a></p>

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
