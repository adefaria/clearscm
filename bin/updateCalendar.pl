#!/usr/bin/perl
# filepath: /opt/clearscm/combine_calendars.pl

## no critic (TestingAndDebugging::RequireUseWarnings, TestingAndDebugging::RequireUseStrict)
use FindBin;
use lib "$FindBin::Bin/../lib";

use StdEnv;
use LWP::Simple;
use Getopt::Long;
use POSIX qw(strftime);

# Parse command-line options
my $verbose   = 0;
my $days_past = 90;
GetOptions (
  'verbose'     => \$verbose,
  'days-past=i' => \$days_past,
);

my $cutoff_date = strftime ('%Y%m%d', localtime (time - ($days_past * 86400)));

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
  'Rock Ready' =>
'https://defaria.com/RockReady/?post_type=tribe_events&ical=1&eventDisplay=list',
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
        \A(.*?)                 # Header (non-greedy)
        (BEGIN:VEVENT.*)        # All events (starting with the first one)
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
  my @raw_events = $event_block =~ /(BEGIN:VEVENT.*?END:VEVENT\r?\n)/sg;
  my @events;

  foreach my $event (@raw_events) {
    # Always preserve recurring events
    if ($event =~ /^RRULE:/m) {
      push @events, $event;
      next;
    }

    # For non-recurring events, keep if end date (or start date) >= cutoff date
    my ($event_date) = $event =~ m{^DTEND(?:;[^:]*)?:(\d{8})}m;
    $event_date //= ($event =~ m{^DTSTART(?:;[^:]*)?:(\d{8})}m)[0];

    if (!$event_date || $event_date >= $cutoff_date) {
      push @events, $event;
    }
  }

  $total_events += scalar @events;
  push @all_events, @events;
} ## end foreach my $name (sort keys...)

# Fetch Google Tasks if configured
my @all_todos;
my $total_tasks        = 0;
my $fetch_tasks_script = "$FindBin::Bin/fetchGoogleTasks.py";
my $tasks_token        = "$ENV{HOME}/.config/google_tasks_token.json";

if (-x $fetch_tasks_script && (-f $tasks_token || $ENV{BW_SESSION})) {
  my $tasks_output = `$fetch_tasks_script 2>&1`;
  if ($? == 0 && $tasks_output) {
    @all_todos   = $tasks_output =~ /(BEGIN:VTODO.*?END:VTODO\r?\n)/sg;
    $total_tasks = scalar @all_todos;
    print "Google Tasks: $total_tasks tasks\n" if $verbose;
  } elsif ($verbose) {
    warn "Warning: Failed to fetch Google Tasks: $tasks_output\n";
  }
}

# Print master calendar
open (my $fh, '>:encoding(UTF-8)', $result_calendar)
  or die "Cannot open $result_calendar: $!";
print $fh $calendar_header;
print $fh join ('', @all_events);
print $fh join ('', @all_todos) if @all_todos;
print $fh $calendar_footer, "\n";
close $fh;
print "Calendar: $total_events events, $total_tasks tasks\n" if $verbose;

# Refresh Rainlendar if available
system ('rainlendar2 -e "Rainlendar_Refresh()" >/dev/null 2>&1')
  if -x '/bin/rainlendar2' || -x '/usr/bin/rainlendar2';
