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

use utf8;
use Encode;
use Encode::CN;
use Encode::TW;
use Encode::JP;
use Encode::KR;

use MIME::Words qw(:all);

use CGI qw(:standard *table start_td end_td start_Tr end_Tr start_div end_div);
use CGI::Carp 'fatalsToBrowser';

use FindBin;

binmode STDOUT, ':encoding(UTF-8)';

local $0 = $FindBin::Script;

use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../lib";

use MAPS;
use MAPSLog;
use MAPSWeb;
use DateUtils;

my $type  = param 'type';
my $list  = substr $type, 0, -4 if $type =~ /list$/;
my $next  = param 'next';
my $lines = param 'lines';
my $date  = param 'date';

$date ||= '';

my ($userid, $current, $last, $prev, $total);

my $table_name = 'detail';

my %types = (
  'blacklist' => [
    'Blacklist report',
    'The following blacklisted users attempted to email you'
  ],
  'whitelist' =>
    ['Delivered report', 'Delivered email from the following users'],
  'nulllist' =>
    ['Discarded report', 'Discarded messages from the following users'],
  'error'    => ['Error report', 'Errors detected'],
  'mailloop' => [
    'MailLoop report',
    'Automatically detected mail loops from the following users'
  ],
  'registered' =>
    ['Registered report', 'The following users have recently registered'],
  'returned' =>
    ['Returned report', 'Sent Register reply to the following users']
);

sub formatRule($) {
  my ($rec) = @_;

  return '' unless $rec->{pattern} or $rec->{domain};

  $rec->{pattern} //= '';
  $rec->{domain}  //= '';

  return "$rec->{pattern}\@$rec->{domain}";
}    # formatRule

sub Body($) {
  my ($type) = @_;

  # Preserve original next for links
  my $orig_next = $next;

  my $current = $next + 1;

  my ($onlist, $rec);

  print div {-align => 'center'},
    b ('(' . $current . '-' . $last . ' of ' . $total . ')');
  print start_form {
    -method => 'post',
    -action => 'processaction.cgi',
    -name   => 'detail'
  };

  print MakeButtons (
    script => 'detail.cgi',
    type   => $type,
    extra  => "type=$type;date=$date",
    next   => $next,
    prev   => $prev,
    lines  => $lines,
    total  => $total
  );

  print start_div {-id => 'highlightrow'};

  print start_table({
      -align       => 'center',
      -id          => $table_name,
      -border      => 0,
      -cellspacing => 0,
      -cellpadding => 0,
      -width       => '100%'
    }
  ) . "\n";

  print Tr [
    th {-class => 'tablebordertopleft'},
    '',
    th {-class => 'tableborder'},
    'Sender',
    th {-class => 'tableborder'},
    'List',
    th {-class => 'tableborder'},
    'Hit Count',
    th {-class => 'tableborder'},
    'Rule',
    th {-class => 'tableborder'},
    'Retention',
    th {-class => 'tablebordertopright'},
    'Comment/Date',
  ];

  my @senders = ReturnSenders (
    userid   => $userid,
    type     => $type,
    start_at => $next,
    lines    => $lines,
    date     => $date
  );

  for my $sender (@senders) {
    my $msgs = ReturnMessages (
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
      }    # unless
    }    # if

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
    }    # if

    ($onlist, $rec) = OnWhitelist ($sender, $userid, 0);

    unless ($onlist) {
      ($onlist, $rec) = OnBlacklist ($sender, 0);

      unless ($onlist) {
        ($onlist, $rec) = OnNulllist ($sender, 0);
      }    # unless
    }    # unless

    $next++;

    # Start Sender line
    my $rowspan = @$msgs + 1;

    print start_Tr {-valign => 'middle'};
    print td {
      -class   => $leftclass,
      -align   => 'right',
      -valign  => 'middle',
      -rowspan => $rowspan,
      -rowspan => $rowspan,
      }, (
      ($type eq 'returned' && @$msgs)
      ? a ({-href => "nuke.cgi?sender=$sender;next=$orig_next"}, $next)
      : $next
      ),
      checkbox {
      -name   => "action$next",
      -label  => '',
      -valign => 'middle',
      };

    print hidden({
        -name    => "email$next",
        -default => $sender,
      }
    );

    # Get subject line
    $heading = "?subject=$heading" if $heading;

    print td {-class => $senderclass,}, a {-href => "mailto:$sender$heading",},
      "&nbsp;$sender";

    if ($rec) {
      my $listlink =
        ($rec->{type} and $rec->{sequence})
        ? "$rec->{type}:$rec->{sequence}"
        : '';

      $rec->{comment}   //= '';
      $rec->{retention} //= '';

      if ($rec->{comment} =~ /email rejected/i) {
        $rec->{comment} = font ({-color => 'red'}, $rec->{comment});
      }

      print td {
        -class => $dataclass,
        -align => 'right',
        },
        a {href => "/maps/php/list.php?type=$rec->{type}&next="
          . ($rec->{sequence} - 1),
        }, $listlink,
        td {
        -class => $dataclass,
        -align => 'right',
        },
        "$rec->{hit_count}&nbsp;",
        td {-class => $dataclass,}, formatRule ($rec),
        td {
        -class => $dataclass,
        -align => 'right',
        },
        "$rec->{retention}&nbsp;",
        td {-class => $rightclass,}, $rec->{comment};
    } else {

      # $rec will be undefined if this message will be returned
      print td {-class => $dataclass},
        td     {-class => $dataclass},
        td     {-class => $dataclass},
        td     {-class => $dataclass},
        td     {-class => $rightclass};
    }    # if

    print end_Tr;

    my $msgnbr = 0;

    for my $rec (@$msgs) {
      $msgnbr++;

      # We increased $next earlier so do not add 1 here
      if (($next % $lines) == (@senders % $lines)) {
        $dataclass  = 'tablebottomdata';
        $rightclass = 'tablebottomright' if $msgnbr == @$msgs;

        # Only subjectbottom the last message
        $subjectclass = 'subjectbottom' if $msgnbr == @$msgs;
      }    # if

      if ($date eq substr ($rec->{timestamp}, 0, 10)) {
        $rec->{date} = b font {-color => 'green'},
          SQLDatetime2UnixDatetime $rec->{timestamp};
      } else {
        $rec->{date} = SQLDatetime2UnixDatetime $rec->{timestamp};
      }    # if

      $rec->{subject} //= '<Unspecified>';

      my $subject = '';
      for my $part (decode_mimewords ($rec->{subject})) {
        my ($text, $charset) = @$part;
        if ($charset) {
          eval {$text = decode ($charset, $text)};
        }

     # If no charset, it's either ASCII or already UTF-8 content from the DB.
     # Since we migrated to utf8mb4 and use correct connections, we trust $text.
        $subject .= $text;
      } ## end for my $part (decode_mimewords...)

      $rec->{subject} = $subject;

      $rec->{subject} = escapeHTML ($rec->{subject});
      print Tr [
        td {
          -class   => $subjectclass,
          -colspan => 5,
        },
        a {
          -href => "display.cgi?sender=$sender;msg_date=$rec->{timestamp}",
        },
        '&nbsp;&nbsp;&nbsp;&nbsp;' . $rec->{subject},
        td {
          -class => $rightclass,
          -width => '150',
          -align => 'right'
        },
        span {-class => 'date'},
        $rec->{date} . '&nbsp',
      ];
    }    # for
  }    # for

  print end_table;
  print end_div;

  print MakeButtons (
    script => 'detail.cgi',
    type   => $type,
    extra  => "type=$type;date=$date",
    next   => $next,
    prev   => $prev,
    lines  => $lines,
    total  => $total
  );

  print end_form;

  return;
}    # Body

# Main
my $condition;
my @scripts = ('ListActions.js');

my $heading_date = $date ne '' ? ' on ' . FormatDate ($date, 1) : '';

$userid = Heading (
  'getcookie',      '', (ucfirst ($type) . ' Report'),
  $types{$type}[0], $types{$type}[1] . $heading_date,
  $table_name,      @scripts
);

$userid ||= $ENV{USER};

SetContext    ($userid);
NavigationBar ($userid);

unless ($lines) {
  my %options = GetUserOptions ($userid);
  $lines = $options{'Page'};
}    # unless

if ($date eq '') {
  $condition .= "type = '$type'";
} else {
  my $sod = $date . ' 00:00:00';
  my $eod = $date . ' 23:59:59';

  $condition .= "type = '$type' and timestamp > '$sod' and timestamp < '$eod'";
}    # if

# Need to count distinct on sender
$total = CountLogDistinct (
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
}    # if

Body ($type);

Footing ($table_name);

exit;
