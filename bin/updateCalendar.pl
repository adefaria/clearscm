#!/usr/bin/perl
# filepath: /opt/clearscm/combine_calendars.pl

use strict;
use warnings;
use LWP::Simple;
use Getopt::Long;

# Parse command-line options
my $verbose = 0;
GetOptions ('verbose' => \$verbose);

# Hash of calendar names and URLs
my %calendar_urls = (
  'Google' =>
'https://calendar.google.com/calendar/ical/adefaria%40gmail.com/public/basic.ics',
  'Silvia' =>
'https://calendar.google.com/calendar/ical/3c6d91c6be7b913c02a0db0bfd9b44d6716448a875d0a9d2b781d5c2c35ad430%40group.calendar.google.com/private-83c4b00e96888e124ef43b3bc71e3138/basic.ics',
  'Meetup' =>
'http://www.meetup.com/events/ical/10426135/8dfdd0ffaaedecf720c5faf0cf3871b7ee5f5c1e/going',
  'Tripit' =>
'https://www.tripit.com/feed/ical/private/06C4F90D-00539C805E8CF5F1C8BC32BF70CB1843/tripit.ics',
);

my $result_calendar = "$ENV{HOME}/Documents/calendar.ics";
my @all_events;
my $calendar_header;
my $calendar_footer;
my $total_events = 0;

foreach my $name (sort keys %calendar_urls) {
  my $url     = $calendar_urls{$name};
  my $content = get ($url);
  unless ($content) {
    warn "Failed to fetch $url\n";
    next;
  }

  # Count number of VEVENTs in this calendar
  my $event_count = () = $content =~ /BEGIN:VEVENT/g;

  # Print calendar name and event count if verbose
  print "$name: $event_count events\n" if $verbose;

  # Extract header, events, and footer
  my ($header, $events, $footer) = $content =~ m{
        \A(.*?BEGIN:VEVENT\s)   # Header up to first event
        (.*)                    # All events and footer
    }xs;

  unless ($header && $events) {
    next;
  }

  # Split events and footer
  my @parts       = split (/END:VCALENDAR/, $events, 2);
  my $event_block = $parts[0];
  my $this_footer = "END:VCALENDAR";

  # Save header/footer from the first calendar
  $calendar_header //= $header;
  $calendar_footer //= $this_footer;

  # Collect all events (split by BEGIN:VEVENT, keep delimiter)
  my @events = $event_block =~ /(BEGIN:VEVENT.*?END:VEVENT\r?\n)/sg;
  $total_events += scalar @events;
  push @all_events, @events;
} ## end foreach my $name (sort keys...)

# Print master calendar
open (my $fh, '>:encoding(UTF-8)', $result_calendar)
  or die "Cannot open $result_calendar: $!";
print $fh $calendar_header;
print $fh join ('', @all_events);
print $fh $calendar_footer, "\n";
close $fh;
print "Calendar: $total_events events\n" if $verbose;
