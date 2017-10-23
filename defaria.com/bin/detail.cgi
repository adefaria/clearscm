#!/usr/bin/perl
#################################################################################
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
################################################################################use strict;
use warnings;

use MIME::Words qw(:all);
use FindBin;
$0 = $FindBin::Script;

use lib $FindBin::Bin;

use MAPS;
use MAPSLog;
use MAPSUtil;
use MAPSWeb;
use CGI qw (:standard *table start_td end_td start_Tr end_Tr start_div end_div);
use CGI::Carp 'fatalsToBrowser';

my $type   = param ('type');
my $next   = param ('next');
my $lines  = param ('lines');
my $date   = param ('date');

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
  my $type = shift;

  my $prev_button = $prev >= 0 ?
    a ({-href => "detail.cgi?type=$type;date=$date;next=$prev"},
      '<img src=/maps/images/previous.gif border=0 alt=Previous align=middle>') : '';
  my $next_button = ($next + $lines) < $total ?
    a {-href => "detail.cgi?type=$type;date=$date;next=" . ($next + $lines)},
      '<img src=/maps/images/next.gif border=0 alt=Next align=middle>' : '';

  my $buttons = $prev_button;

  if ($type eq 'whitelist') {
    $buttons = $buttons .
      submit ({-name    => 'action',
               -value   => 'Blacklist Marked',
               -onClick => 'return CheckAtLeast1Checked (document.detail);'}) .
      submit ({-name    => 'action',
               -value   => 'Nulllist Marked',
               -onClick => 'return CheckAtLeast1Checked (document.detail);'}) .
      submit ({-name    => 'action',
               -value   => 'Reset Marks',
               -onClick => 'return ClearAll (document.detail);'});
  } elsif ($type eq 'blacklist') {
    $buttons = $buttons .
      submit ({-name    => 'action',
               -value   => 'Whitelist Marked',
               -onClick => 'return CheckAtLeast1Checked (document.detail);'}) .
      submit ({-name    => 'action',
               -value   => 'Nulllist Marked',
               -onClick => 'return CheckAtLeast1Checked (document.detail);'}) .
      submit ({-name    => 'action',
               -value   => 'Reset Marks',
               -onClick => 'return ClearAll (document.detail);'});
  } elsif ($type eq 'nulllist') {
    $buttons = $buttons .
      submit ({-name    => 'action',
               -value   => 'Whitelist Marked',
               -onClick => 'return CheckAtLeast1Checked (document.detail);'}) .
      submit ({-name    => 'action',
               -value   => 'Blacklist Marked',
               -onClick => 'return CheckAtLeast1Checked (document.detail);'}) .
      submit ({-name    => 'action',
               -value   => 'Reset Marks',
               -onClick => 'return ClearAll (document.detail);'});
  } else {
    $buttons = $buttons .
      submit ({-name    => 'action',
               -value   => 'Whitelist Marked',
               -onClick => 'return CheckAtLeast1Checked (document.detail);'}) .
      submit ({-name    => 'action',
               -value   => 'Blacklist Marked',
               -onClick => 'return CheckAtLeast1Checked (document.detail);'}) .
      submit ({-name    => 'action',
               -value   => 'Nulllist Marked',
               -onClick => 'return CheckAtLeast1Checked (document.detail);'}) .
      submit ({-name    => 'action',
               -value   => 'Reset Marks',
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
  print start_table ({-align        => 'center',
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

  foreach my $sender (ReturnSenders $userid, $type, $next, $lines, $date) {
    my @msgs = ReturnMessages $userid, $sender;

    $next++;
    print
      start_Tr {-valign => 'middle'};
    print
      td {-class => 'tableborder'}, small ($next,
        checkbox {-name  => "action$next",
                  -label => ''}),
          hidden ({-name     => "email$next",
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
    print
      td {-class => 'tablelabel',
          -valign => 'middle',
          -width  => '40'}, 'Sender:',
      td {-class  => 'sender',
          -valign => 'middle'},
      a {-href    => "mailto:$sender"}, $sender;
    print
      end_table;

    my $messages = 1;

    foreach (@msgs) {
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
              -width   => '130',
              -valign  => 'middle'}, $msg_date
        ];
      print end_table;
    } # foreach
    print end_td;
    print end_Tr;
  } # foreach

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
} # PrintTable

# Main
my @scripts = ('ListActions.js');

my $heading_date =$date ne '' ? ' on ' . FormatDate ($date) : '';

$userid = Heading (
  'getcookie',
  '',
  (ucfirst ($type) . ' Report'),
  $types {$type} [0],
  $types {$type} [1] . $heading_date,
  $table_name,
  @scripts
);

$userid ||= $ENV{USER};

SetContext $userid;
NavigationBar $userid;

unless ($lines) {
  my %options = GetUserOptions $userid;
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

$total = MAPSDB::count_distinct ('log', 'sender', $condition);

$next ||= 0;

$last = $next + $lines < $total ? $next + $lines : $total;

if (($next - $lines) > 0) {
  $prev = $next - $lines;
} else {
  $prev = $next eq 0 ? -1 : 0;
} # if

PrintTable $type;

Footing $table_name;

exit;
