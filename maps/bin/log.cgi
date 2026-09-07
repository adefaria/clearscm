#!/usr/bin/perl
################################################################################
#
# File:         log.cgi
# Description:  Displays MAPS log (/var/local/log/maps.log) and mapsscrub.log table.
# Author:       Andrew@DeFaria.com
# Language:     perl
#
# (c) Copyright 2000-2026, Andrew@DeFaria.com, all rights reserved.
#
################################################################################
use strict;
use warnings;

use FindBin;

local $0 = $FindBin::Script;

use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../lib";

use MAPS;
use MAPSLog;
use MAPSWeb;
use DateUtils;

use CGI qw (:standard *table start_Tr end_Tr start_div end_div);
use CGI::Carp 'fatalsToBrowser';

my $table_name = 'logs';
my $maps_log_path     = '/var/local/log/maps.log';
my $scrub_log_path    = '/var/local/log/mapsscrub.log';

sub FormatTimestamp($) {
  my ($ts) = @_;
  if ($ts =~ /^(\d{4})(\d{2})(\d{2})\@(\d{2}):(\d{2})/) {
    return "$1-$2-$3 $4:$5";
  }
  return $ts;
}

sub GetEventBadge($) {
  my ($msg) = @_;

  if ($msg =~ /auth\s*fail/i) {
    return '<span style="background-color:#ffe6e6; color:#cc0000; padding:3px 8px; border-radius:4px; font-weight:bold; font-size:11px;">Auth Failure</span>';
  } elsif ($msg =~ /nulllist/i) {
    return '<span style="background-color:#fce8e6; color:#c5221f; padding:3px 8px; border-radius:4px; font-weight:bold; font-size:11px;">Nulllist</span>';
  } elsif ($msg =~ /whitelist/i) {
    return '<span style="background-color:#e6f4ea; color:#137333; padding:3px 8px; border-radius:4px; font-weight:bold; font-size:11px;">Whitelist</span>';
  } elsif ($msg =~ /blacklist/i) {
    return '<span style="background-color:#e8eaed; color:#3c4043; padding:3px 8px; border-radius:4px; font-weight:bold; font-size:11px;">Blacklist</span>';
  } elsif ($msg =~ /return/i) {
    return '<span style="background-color:#fef7e0; color:#b06000; padding:3px 8px; border-radius:4px; font-weight:bold; font-size:11px;">Returned</span>';
  } else {
    return '<span style="background-color:#e8f0fe; color:#1a73e8; padding:3px 8px; border-radius:4px; font-weight:bold; font-size:11px;">Info</span>';
  }
}

sub RenderMapsLog() {
  print '<div style="background-color:#ffffff; border:1px solid #dcdfe6; border-radius:8px; padding:18px; margin-bottom:24px; box-shadow:0 2px 4px rgba(0,0,0,0.05);">';
  print '<h3 style="margin-top:0; color:#1a73e8; font-family:sans-serif; border-bottom:2px solid #e8f0fe; padding-bottom:8px;">MAPS Activity Log (<code style="font-size:13px;">/var/local/log/maps.log</code>)</h3>';

  unless (-f $maps_log_path && -r $maps_log_path) {
    print '<p style="color:#666; font-style:italic;">No log entries available at /var/local/log/maps.log</p>';
    print '</div>';
    return;
  }

  open my $fh, '<', $maps_log_path or do {
    print "<p style=\"color:#c5221f;\">Unable to open $maps_log_path: $!</p></div>";
    return;
  };

  my @lines = <$fh>;
  close $fh;

  @lines = reverse @lines; # Newest first

  if (@lines == 0) {
    print '<p style="color:#666; font-style:italic;">maps.log is currently empty.</p>';
    print '</div>';
    return;
  }

  print start_table({
    -align       => 'center',
    -border      => 0,
    -cellspacing => 0,
    -cellpadding => 6,
    -width       => '100%',
    -style       => 'border-collapse:collapse; font-family:sans-serif; font-size:13px;'
  });

  print start_Tr({-style => 'background-color:#f8f9fa; border-bottom:2px solid #dee2e6; text-align:left;'});
  print th({-style => 'padding:8px; color:#495057;'}, 'Timestamp');
  print th({-style => 'padding:8px; color:#495057;'}, 'Event');
  print th({-style => 'padding:8px; color:#495057;'}, 'Message Details');
  print end_Tr;

  my $row_count = 0;
  for my $line (@lines) {
    chomp $line;
    next unless $line =~ /\S/;

    my ($ts, $msg);
    if ($line =~ /^maps:\s*(\S+):\s*(.*)/) {
      $ts  = FormatTimestamp($1);
      $msg = $2;
    } else {
      $ts  = '-';
      $msg = $line;
    }

    my $bg = ($row_count % 2 == 0) ? '#ffffff' : '#f8f9fa';
    my $badge = GetEventBadge($msg);

    print start_Tr({-style => "background-color:$bg; border-bottom:1px solid #e9ecef;"});
    print td({-style => 'padding:8px; white-space:nowrap; color:#6c757d; font-family:monospace;'}, $ts);
    print td({-style => 'padding:8px; white-space:nowrap;'}, $badge);
    print td({-style => 'padding:8px; color:#212529; word-break:break-word;'}, $msg);
    print end_Tr;

    $row_count++;
    last if $row_count >= 200; # Cap display to last 200 log entries
  }

  print end_table;
  print '</div>';

  return;
}

sub RenderScrubLog() {
  print '<div style="background-color:#ffffff; border:1px solid #dcdfe6; border-radius:8px; padding:18px; margin-bottom:24px; box-shadow:0 2px 4px rgba(0,0,0,0.05);">';
  print '<h3 style="margin-top:0; color:#1a73e8; font-family:sans-serif; border-bottom:2px solid #e8f0fe; padding-bottom:8px;">MAPS Scrub Log (<code style="font-size:13px;">/var/local/log/mapsscrub.log</code>)</h3>';

  unless (-f $scrub_log_path && -r $scrub_log_path) {
    print '<p style="color:#666; font-style:italic;">No mapsscrub log entries found at /var/local/log/mapsscrub.log</p>';
    print '</div>';
    return;
  }

  open my $fh, '<', $scrub_log_path or do {
    print "<p style=\"color:#c5221f;\">Unable to open $scrub_log_path: $!</p></div>";
    return;
  };

  my %runs;
  my $current_ts = '';

  while (my $line = <$fh>) {
    chomp $line;
    next unless $line =~ /\S/;

    if ($line =~ /^mapsscrub:\s*(\S+):\s*(.*)/) {
      my $ts   = FormatTimestamp($1);
      my $text = $2;

      $current_ts = $ts;
      push @{$runs{$ts}}, $text;
    }
  }
  close $fh;

  my @timestamps = sort { $b cmp $a } keys %runs;

  if (@timestamps == 0) {
    print '<p style="color:#666; font-style:italic;">mapsscrub.log is empty.</p>';
    print '</div>';
    return;
  }

  print start_table({
    -align       => 'center',
    -border      => 0,
    -cellspacing => 0,
    -cellpadding => 6,
    -width       => '100%',
    -style       => 'border-collapse:collapse; font-family:sans-serif; font-size:13px;'
  });

  print start_Tr({-style => 'background-color:#f8f9fa; border-bottom:2px solid #dee2e6; text-align:left;'});
  print th({-style => 'padding:8px; color:#495057;'}, 'Run Timestamp');
  print th({-style => 'padding:8px; color:#495057;'}, 'Metric / Action');
  print th({-style => 'padding:8px; color:#495057; text-align:right;'}, 'Count / Status');
  print end_Tr;

  my $row_count = 0;
  for my $ts (@timestamps) {
    my $entries = $runs{$ts};
    for my $entry (@$entries) {
      next if $entry =~ /Run Statistics:/i;

      my ($metric, $value);
      if ($entry =~ /^\s*(\d+)\s+(.*)/) {
        $value  = $1;
        $metric = $2;
      } else {
        $metric = $entry;
        $value  = 'OK';
      }

      my $bg = ($row_count % 2 == 0) ? '#ffffff' : '#f8f9fa';

      print start_Tr({-style => "background-color:$bg; border-bottom:1px solid #e9ecef;"});
      print td({-style => 'padding:8px; white-space:nowrap; color:#6c757d; font-family:monospace;'}, $ts);
      print td({-style => 'padding:8px; color:#212529; font-weight:500;'}, $metric);
      print td({-style => 'padding:8px; text-align:right; font-weight:bold; color:#1a73e8;'}, $value);
      print end_Tr;

      $row_count++;
    }
  }

  print end_table;
  print '</div>';

  return;
}

sub Body($) {
  my ($userid) = @_;

  print start_div({-id => 'highlightrow'});
  print '<div style="padding:10px 0;">';
  RenderMapsLog();
  RenderScrubLog();
  print '</div>';
  print end_div;

  return;
}

# Main
my $userid = Heading(
  'getcookie',
  '',
  'Logs',
  'MAPS Logs',
  '',
  $table_name
);

$userid //= $ENV{USER};

SetContext($userid);
NavigationBar($userid);
Body($userid);
Footing($table_name);

exit;
