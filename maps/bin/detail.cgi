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
# (c) Copyright 2000-2021, Andrew@DeFaria.com, all rights reserved.
#
################################################################################
use strict;
use warnings;

use MIME::Words qw(:all);

use CGI qw(:standard *table start_td end_td start_Tr end_Tr start_div end_div);
use CGI::Carp 'fatalsToBrowser';

use FindBin;

local $0 = $FindBin::Script;

use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../lib";

use MAPS;
use MAPSLog;
use MAPSWeb;
use DateUtils;

my $type   = param 'type';
my $next   = param 'next';
my $lines  = param 'lines';
my $date   = param 'date';

$date ||= '';

my ($userid, $current, $last, $prev, $total);

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

sub MakeButtons($) {
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
               -onClick => 'return CheckAtLeast1Checked (document.detail);'}) . '&nbsp;' .
      submit ({-name    => 'action',
               -value   => 'Nulllist',
               -onClick => 'return CheckAtLeast1Checked (document.detail);'}) . '&nbsp;' .
      submit ({-name    => 'action',
               -value   => 'Reset',
               -onClick => 'return ClearAll (document.detail);'});
  } elsif ($type eq 'blacklist') {
    $buttons = $buttons .
      submit ({-name    => 'action',
               -value   => 'Whitelist',
               -onClick => 'return CheckAtLeast1Checked (document.detail);'}) . '&nbsp;' .
      submit ({-name    => 'action',
               -value   => 'Nulllist',
               -onClick => 'return CheckAtLeast1Checked (document.detail);'}) . '&nbsp;' .
      submit ({-name    => 'action',
               -value   => 'Reset',
               -onClick => 'return ClearAll (document.detail);'});
  } elsif ($type eq 'nulllist') {
    $buttons = $buttons .
      submit ({-name    => 'action',
               -value   => 'Whitelist',
               -onClick => 'return CheckAtLeast1Checked (document.detail);'}) . '&nbsp;' .
      submit ({-name    => 'action',
               -value   => 'Blacklist',
               -onClick => 'return CheckAtLeast1Checked (document.detail);'}) . '&nbsp;' .
      submit ({-name    => 'action',
               -value   => 'Reset',
               -onClick => 'return ClearAll (document.detail);'});
  } else {
    $buttons = $buttons .
      submit ({-name    => 'action',
               -value   => 'Whitelist',
               -onClick => 'return CheckAtLeast1Checked (document.detail);'}) . '&nbsp;' .
      submit ({-name    => 'action',
               -value   => 'Blacklist',
               -onClick => 'return CheckAtLeast1Checked (document.detail);'}) . '&nbsp;' .
      submit ({-name    => 'action',
               -value   => 'Nulllist',
               -onClick => 'return CheckAtLeast1Checked (document.detail);'}) . '&nbsp;' .
      submit ({-name    => 'action',
               -value   => 'Reset',
               -onClick => 'return ClearAll (document.detail);'});
  } # if

  print div {
    -align => 'center',
    -class => 'toolbar',
  }, $buttons . $next_button;

  return;
} # MakeButtons

sub Body($) {
  my ($type) = @_;

  my $current = $next + 1;

  print div {-align => 'center'}, b (
    '(' . $current . '-' . $last . ' of ' . $total . ')');
  print start_form {
    -method => 'post',
    -action => 'processaction.cgi',
    -name   => 'detail'
  };

  MakeButtons $type;

  print start_table({-align        => 'center',
                     -id           => $table_name,
                     -border       => 0,
                     -cellspacing  => 0,
                     -cellpadding  => 0,
                     -width        => '100%'}) . "\n";

  print
    Tr [
      td {-class  => 'tablebordertopleft'},  '&nbsp;',
      th {-class  => 'tableborder'},         'Sender',
      th {-class  => 'tableborder'},         'List',
      th {-class  => 'tableborder'},         'Hit Count',
      th {-class  => 'tableborder'},         'Rule',
      th {-class  => 'tablebordertopright'}, 'Comment',
    ];

  my @senders = ReturnSenders(
    userid   => $userid,
    type     => $type,
    start_at => $next,
    lines    => $lines,
    date     => $date
  );

  for my $sender (@senders) {
    my $msgs = ReturnMessages(
      userid => $userid,
      sender => $sender,
    );

    my $leftclass    = 'tableleftdata';
    my $dataclass    = 'tabledata';
    my $rightclass   = 'tablerightdata';
    my $senderclass  = 'sender';
    my $subjectclass = 'subject';

    # Check to see if this is the last line
    if ((($next + 1) % $lines) == (@senders % $lines)) {
      # We always "bottom" the first column
      $leftclass = 'tablebottomleft';

      # Check to see if there any message lines to display
      unless (@$msgs) {
        $dataclass   = 'tablebottomdata';
        $rightclass  = 'tablebottomright';
        $senderclass = 'senderbottom';
      } # unless
    } # if

    # This is for the purposes of supplying a subject line if the mailto address
    # is clicked on. It's kludgy because we are simply grabbing the subject line
    # of the first email sent where there may be many emails from this sender
    # Still it is often the right subject (or a good enough one)
    #
    # A little tricky here because of transliteration. If I test for
    # $msg->[0]{subject} when $msg->[0] is essentially empty I create the hash
    # making it non empty. Therefore I need to first test if $msgs->[0] exists
    # first.
    my $heading = '';

    if ($msgs->[0]) {
      $heading = $msgs->[0]{subject} if $msgs->[0]{subject};
    } # if

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

    $hit_count //= '';

    my $list     = '';
    my $sequence = 0;
    my $comment  = '';

    # Parse rule
    if ($rule) {
      if ($rule =~ /\((\w+):(\d+)\)\s+"(\S*)"/) {
        $list     = $1;
        $sequence = $2;
        $rule     = $3;
        $comment  = '';
      } elsif ($rule =~ /\((\w+):(\d+)\)\s+"(\S*) - (.*)"/) {
        $list     = $1;
        $sequence = $2;
        $rule     = $3;
        $comment  = $4;
      } # if

      $rule =~ s/\\@/\@/;
    } # if

    $sequence //= 0;
    $next++;

    # Start Sender line
    my $rowspan = @$msgs + 1;

    print start_Tr {-valign => 'middle'};
    print td {
      -class   => $leftclass,
      -align   => 'right',
      -valign  => 'middle',
      -rowspan => $rowspan,
    }, $next,
      checkbox {
        -name   => "action$next",
        -label  => '',
        -valign => 'middle',
      };

      print hidden({
        -name    => "email$next",
        -default => $sender,
      });

    # Get subject line
    $heading = "?subject=$heading" if $heading;

    print td {
      -class => $senderclass,
    }, a {
      -href  => "mailto:$sender$heading",
    }, "&nbsp;$sender";

    my $listlink = ($list and $sequence) ? "$list:$sequence" : '&nbsp;';

    print td {
      -class => $dataclass,
      -align => 'right',
    }, a {
      href  => "/maps/php/list.php?type=$list&next=" . ($sequence - 1),
    }, $listlink,
    td {
      -class => $dataclass,
      -align => 'right',
    }, "$hit_count&nbsp;",
    td {
      -class => $dataclass,
    }, $rule,
    td {
      -class => $rightclass,
    }, $comment;
    print end_Tr;

    my $msgnbr = 0;

    for my $rec (@$msgs) {
      $msgnbr++;

      # We increased $next earlier so do not add 1 here
      if (($next % $lines) == (@senders % $lines)) {
        $dataclass    = 'tablebottomdata';
        $rightclass   = 'tablebottomright' if $msgnbr == @$msgs;

        # Only subjectbottom the last message
        $subjectclass = 'subjectbottom' if $msgnbr == @$msgs;
      } # if

      if ($date eq substr ($rec->{timestamp}, 0, 10)) {
        $rec->{date} = b font {-color => 'green'}, SQLDatetime2UnixDatetime $rec->{timestamp};
      } else {
        $rec->{date} = SQLDatetime2UnixDatetime $rec->{timestamp};
      } # if

      $rec->{subject} //= '&lt;Unspecified&gt;';
      $rec->{subject} = decode_mimewords ($rec->{subject});
      $rec->{subject} =~ s/\>/&gt;/g;
      $rec->{subject} =~ s/\</&lt;/g;

      print
        Tr [
          td {
            -class   => $subjectclass,
            -colspan => 4,
          }, a {
            -href    => "display.cgi?sender=$sender;msg_date=$rec->{timestamp}",
           }, '&nbsp;&nbsp;&nbsp;&nbsp;' . $rec->{subject},
          td {-class => $rightclass,
              -width => '150',
              -align => 'right'}, span {-class => 'date'}, $rec->{date} . '&nbsp',
        ];
    } # for
  } # for

  print end_table;
  print end_form;

  MakeButtons $type;

  return;
} # Body

# Main
my $condition;
my @scripts = ('ListActions.js');

my $heading_date =$date ne '' ? ' on ' . FormatDate ($date, 1) : '';

$userid = Heading(
  'getcookie',
  '',
  (ucfirst ($type) . ' Report'),
  $types{$type} [0],
  $types{$type} [1] . $heading_date,
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
  $condition .= "type = '$type'";
} else {
  my $sod = $date . ' 00:00:00';
  my $eod = $date . ' 23:59:59';

  $condition .= "type = '$type' and timestamp > '$sod' and timestamp < '$eod'";
} # if

# Need to count distinct on sender
$total = CountLogDistinct(
  userid     => $userid,
  column     => 'sender',
  additional => $condition,
);

$next ||= 0;

$last = $next + $lines < $total ? $next + $lines : $total;

if (($next - $lines) > 0) {
  $prev = $next - $lines;
} else {
  $prev = $next == 0 ? -1 : 0;
} # if

Body($type);

Footing($table_name);

exit;
