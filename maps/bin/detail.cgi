#!/usr/bin/perl
################################################################################
#
# File:         $RCSfile: detail.cgi,v $
# Revision:     $Revision: 1.1 $
# Description:  Displays list of email addresses based on report type.
# Author:       Andrew@DeFaria.com
# Created:      Fri Nov 29 14:17:21  2002
# Modified:     $Date: 2013/06/12 14:05:47 $
# Language:     perl
#
# (c) Copyright 2000-2006, Andrew@DeFaria.com, all rights reserved.
#
################################################################################
use strict;
use warnings;

use MIME::Words qw(:all);
use FindBin;
$0 = $FindBin::Script;

use lib "$FindBin::Bin/../lib";

use MAPS;
use MAPSLog;
use MAPSUtil;
use MAPSWeb;
use CGI qw(:standard *table start_td end_td start_Tr end_Tr start_div end_div);
use CGI::Carp 'fatalsToBrowser';

my $type   = param('type');
my $next   = param('next');
my $lines  = param('lines');
my $date   = param('date');

$date ||= '';

my $userid;
my $current;
my $last;
my $prev;
my $total;
my $table_name = 'detail';

my %types = (
  'blacklist'   => [
    'Blacklist report',
    'The following blacklisted users attempted to email you'
  ],
  'whitelist'   => [
    'Delivered report',
    'Delivered email from the following users'
  ],
  'nulllist'    => [
    'Discarded report',
    'Discarded messages from the following users'
  ],
  'error'       => [
    'Error report',
    'Errors detected'
  ],
  'mailloop'    => [
    'MailLoop report',
    'Automatically detected mail loops from the following users'
  ],
  'registered'  => [
    'Registered report',
    'The following users have recently registered'
  ],
  'returned'    => [
    'Returned report',
    'Sent Register reply to the following users'
  ]
);

sub MakeButtons {
  my ($type) = @_;

  my $prev_button = $prev >= 0 ?
    a ({-href      => "detail.cgi?type=$type;date=$date;next=$prev",
        -accesskey => 'p',
    }, '<img src=/maps/images/previous.gif border=0 alt=Previous align=middle>') : '';
  my $next_button = ($next + $lines) < $total ?
    a {-href      => "detail.cgi?type=$type;date=$date;next=" . ($next + $lines),
       -accesskey => 'n',
    }, '<img src=/maps/images/next.gif border=0 alt=Next align=middle>' : '';

  my $buttons = $prev_button;

  if ($type eq 'whitelist') {
    $buttons = $buttons .
      submit ({-name    => 'action',
               -value   => 'Blacklist',
               -onClick => 'return CheckAtLeast1Checked (document.detail);'}) .
      submit ({-name    => 'action',
               -value   => 'Nulllist',
               -onClick => 'return CheckAtLeast1Checked (document.detail);'}) .
      submit ({-name    => 'action',
               -value   => 'Reset',
               -onClick => 'return ClearAll (document.detail);'});
  } elsif ($type eq 'blacklist') {
    $buttons = $buttons .
      submit ({-name    => 'action',
               -value   => 'Whitelist',
               -onClick => 'return CheckAtLeast1Checked (document.detail);'}) .
      submit ({-name    => 'action',
               -value   => 'Nulllist',
               -onClick => 'return CheckAtLeast1Checked (document.detail);'}) .
      submit ({-name    => 'action',
               -value   => 'Reset',
               -onClick => 'return ClearAll (document.detail);'});
  } elsif ($type eq 'nulllist') {
    $buttons = $buttons .
      submit ({-name    => 'action',
               -value   => 'Whitelist',
               -onClick => 'return CheckAtLeast1Checked (document.detail);'}) .
      submit ({-name    => 'action',
               -value   => 'Blacklist',
               -onClick => 'return CheckAtLeast1Checked (document.detail);'}) .
      submit ({-name    => 'action',
               -value   => 'Reset',
               -onClick => 'return ClearAll (document.detail);'});
  } else {
    $buttons = $buttons .
      submit ({-name    => 'action',
               -value   => 'Whitelist',
               -onClick => 'return CheckAtLeast1Checked (document.detail);'}) .
      submit ({-name    => 'action',
               -value   => 'Blacklist',
               -onClick => 'return CheckAtLeast1Checked (document.detail);'}) .
      submit ({-name    => 'action',
               -value   => 'Nulllist',
               -onClick => 'return CheckAtLeast1Checked (document.detail);'}) .
      submit ({-name    => 'action',
               -value   => 'Reset',
               -onClick => 'return ClearAll (document.detail);'});
  } # if

  return $buttons . $next_button;
} # MakeButtons

sub PrintTable {
  my ($type) = @_;

  my $current = $next + 1;

  print div {-align => 'center'}, b (
    '(' . $current . '-' . $last . ' of ' . $total . ')');
  print start_form {
    -method => 'post',
    -action => 'processaction.cgi',
    -name   => 'detail'
  };
  print start_table({-align        => 'center',
                     -id           => $table_name,
                     -border       => 0,
                     -cellspacing  => 0,
                     -cellpadding  => 0,
                     -width        => '100%'}) . "\n";

  my $buttons = MakeButtons $type;

  print start_div {-class => 'toolbar'};
  print
    Tr [
      td {-class  => 'tablebordertopleft',
          -valign => 'middle'},
      td {-class  => 'tablebordertopright',
          -valign => 'middle',
          -align  => 'center'}, $buttons,
    ];
  print end_div;

  for my $sender (ReturnSenders($userid, $type, $next, $lines, $date)) {
    my @msgs  = ReturnMessages($userid, $sender);
    my @msgs2 = @msgs;

    my ($onlist, $seq);

    my $rule      = 'none';
    my $hit_count = 0;

    ($onlist, $rule, $seq, $hit_count) = OnWhitelist($sender, $userid, 0);

    unless ($onlist) {
      ($onlist, $rule, $seq, $hit_count) = OnBlacklist($sender, 0);

      unless ($onlist) {
        ($onlist, $rule, $seq, $hit_count) = OnNulllist($sender, 0);
      } # unless
    } # unless

    if ($rule) {
      $rule =~ s/Matching rule: \(//;
      $rule =~ s/\)//;

      if ($rule =~ /(\w+):(\d+)/) {
        my $list     = $1;
        my $sequence = $2 - 1;
        my $link     = "<a href=\"/maps/php/list.php?type=$list&next=$sequence\">$list:$2</a>/$hit_count";

        $rule =~ s/\w+:\d+/$link/;
      } # if
    } # if

    $next++;
    print
      start_Tr {-valign => 'middle'};
    print
      td {-class => 'tableborder'}, small ($next,
        checkbox {-name  => "action$next",
                  -label => ''}),
          hidden ({-name    => "email$next",
                   -default => $sender});
    print
      start_td {-align => 'left'};
    print
      start_table {-class       => 'tablerightdata',
                   -cellpadding => 2,
                   -callspacing => 0,
                   -border      => 0,
                   -width       => '100%',
                   -bgcolor     => '#d4d0c8'};

    # Get subject line
    my $heading = $msgs2[0][0] || '';
    $heading = "?subject=$heading" if $heading;
    print
      td {-class   => 'tablelabel',
          -valign  => 'middle',
          -width   => '40'}, 'Sender:',
      td {-class   => 'sender',
          -valign  => 'middle',
          -width   => '40%'},
        a {-href   => "mailto:$sender$heading"}, $sender,
      td {
          -valign  => 'middle'},
          $rule;
    print
      end_table;

    my $messages = 1;

    for (@msgs) {
      my $msg_date = pop @{$_};
      my $subject  = pop @{$_};

      if ($date eq substr ($msg_date, 0, 10)) {
        $msg_date = b font {-color => 'green'}, SQLDatetime2UnixDatetime $msg_date;
      } else {
        $msg_date = SQLDatetime2UnixDatetime $msg_date;
      } # if

      $subject = $subject eq '' ? '&lt;Unspecified&gt;' : $subject;
      $subject = decode_mimewords ($subject);
      $subject =~ s/\>/&gt;/g;
      $subject =~ s/\</&lt;/g;

      print
        start_table {-class       => 'tablerightdata',
                     -cellpadding => 2,
                     -cellspacing => 2,
                     -border      => 0,
                     -width       => '100%'};
      my $msg_nbr = $messages;
      print
        Tr [
          td {-class   => 'msgnbr',
              -valign  => 'middle',
              -rowspan => 2,
              -width   => '2%'}, $messages++,
          td {-class   => 'tablelabel',
              -valign  => 'middle',
              -width   => '45'}, 'Subject:',
          td {-class   => 'subject',
              -valign  => 'middle',
              -bgcolor => '#ffffff'},
           a {-href    => "display.cgi?sender=$sender;msg_nbr=$msg_nbr"}, $subject,
          td {-class   => 'date',
              -width   => '150',
              -valign  => 'middle'}, $msg_date
        ];
      print end_table;
    } # for
    print end_td;
    print end_Tr;
  } # for

  print start_div {-class => 'toolbar'};
  print
    Tr [
      td {-class  => 'tableborderbottomleft',
          -valign => 'middle'},
      td {-class  => 'tableborderbottomright',
          -valign => 'middle'},
      $buttons
    ];
  print end_div;
  print end_table;
  print end_form;

  return;
} # PrintTable

# Main
my $condition;
my @scripts = ('ListActions.js');

my $heading_date =$date ne '' ? ' on ' . FormatDate ($date) : '';

$userid = Heading(
  'getcookie',
  '',
  (ucfirst ($type) . ' Report'),
  $types {$type} [0],
  $types {$type} [1] . $heading_date,
  $table_name,
  @scripts
);

$userid ||= $ENV{USER};

SetContext($userid);
NavigationBar($userid);

unless ($lines) {
  my %options = GetUserOptions($userid);
  $lines = $options{'Page'};
} # unless

if ($date eq '') {
  $condition .= "userid = '$userid' and type = '$type'";
} else {
  my $sod = $date . ' 00:00:00';
  my $eod = $date . ' 23:59:59';

  $condition .= "userid = '$userid' and type = '$type' "
              . "and timestamp > '$sod' and timestamp < '$eod' ";
} # if

$total = count_distinct('log', 'sender', $condition);

$next ||= 0;

$last = $next + $lines < $total ? $next + $lines : $total;

if (($next - $lines) > 0) {
  $prev = $next - $lines;
} else {
  $prev = $next == 0 ? -1 : 0;
} # if

PrintTable($type);

Footing($table_name);

exit;
