#!/usr/bin/perl
################################################################################
#
# File:         $RCSfile: search.cgi,v $
# Revision:     $Revision: 1.1 $
# Description:  Search by sender and subject
# Author:       Andrew@DeFaria.com
# Created:      Mon Jan 16 20:25:32 PST 2006
# Modified:     $Date: 2013/06/12 14:05:47 $
# Language:     perl
#
# (c) Copyright 2000-2006, Andrew@DeFaria.com, all rights reserved.
#
################################################################################
use strict;
use warnings;

use FindBin;
local $0 = $FindBin::Script;

use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../lib";

use DateUtils;
use MAPS;
use MAPSWeb;

use CGI qw (:standard *table start_Tr start_td start_div end_Tr end_td end_div);
use CGI::Carp "fatalsToBrowser";

my $str   = param('str');
my $next  = param('next');
my $lines = param('lines');

my ($userid, $prev, $total, $last);

my $table_name = 'searchresults';

sub MakeButtons {
  my $prev_button = $prev >= 0 ?
    a ({-href => "search.cgi?str=$str;next=$prev"},
      "<img src=/maps/images/previous.gif border=0 alt=Previous align=middle>") : "";
  my $next_button = ($next + $lines) < $total ?
    a {-href => "search.cgi?str=$str;next=" . ($next + $lines)},
      "<img src=/maps/images/next.gif border=0 alt=Next align=middle>" : "";

  my $buttons = $prev_button;

  $buttons = $buttons .
    submit ({-name    => "action",
             -value   => "Whitelist",
             -onClick => "return CheckAtLeast1Checked (document.detail);"}) .
    submit ({-name    => "action",
             -value   => "Blacklist",
             -onClick => "return CheckAtLeast1Checked (document.detail);"}) .
    submit ({-name    => "action",
             -value   => "Nulllist",
             -onClick => "return CheckAtLeast1Checked (document.detail);"}) .
    submit ({-name    => "action",
             -value   => "Reset",
             -onClick => "return ClearAll (document.detail);"});

  return $buttons . $next_button;
} # MakeButtons

sub HighlightSearchStr {
  $_ = shift;

  my $highlighted_str = font {-class => "found"}, $str;

  s/$str/<font class=\"found\">$&<\/font>/gi;

  return $_;
} # HighlightSearchStr

sub Body {
  my @emails = SearchEmails(
    userid => $userid,
    search => $str,
  );

  my $current = $next + 1;

  print div {-align => "center"}, b (
    "(" . $current . "-" . $last . " of " . $total . ")");
  print start_form {
    -method => "post",
    -action => "processaction.cgi",
    -name   => "detail"
  };
  my $buttons = MakeButtons;
  print div {-align => "center",
             -class => "toolbar"}, $buttons;
  print start_table ({-align       => "center",
                      -id          => $table_name,
                      -border      => 0,
                      -cellspacing => 0,
                      -cellpadding => 0,
                      -width       => "100%"}) . "\n";
  print
    Tr [
      th {-class => "tableleftend"},
      th {-class => "tableheader"},   "Sender",
      th {-class => "tableheader"},   "Subject",
      th {-class => "tablerightend"}, "Date"
    ];

  for my $rec (@emails) {
    my $display_sender = HighlightSearchStr $rec->{sender};

    $rec->{subject} //= '&lt;Unspecified&gt;';
    $rec->{subject} = HighlightSearchStr $rec->{subject};

    $next++;

    print Tr [
      td {-class => "tableleftdata",
          -align => "center"},
         (checkbox {-name  => "action$next",
                    -label => ""}),
          hidden ({-name   => "email$next",
         -default  => $rec->{sender}}),
      td {-class   => "sender"}, 
          a {-href => "mailto:$rec->{sender}"}, $display_sender,
      td {-class   => "subject"},
          a {-href => "display.cgi?sender=$rec->{sender}"}, $rec->{subject},
      td {-class   => "dateright",
          -width   => "115"}, SQLDatetime2UnixDatetime $rec->{timestamp},
    ];
  } # for

  print
    Tr [
      td {-class  => 'tableborderbottomleft'},  '&nbsp;',
      td {-class  => 'tableborder'},            '&nbsp;',
      td {-class  => 'tableborder'},            '&nbsp;',
      td {-class  => 'tableborderbottomright'}, '&nbsp;'
    ];
  print end_table;

  return;
} # Body

# Main
my @scripts = ("ListActions.js");

$userid = Heading (
  "getcookie",
  "",
  "Search Results",
  "Search Results for \"$str\"",
  "",
  $table_name,
  @scripts
);

$userid //= $ENV{USER};

SetContext $userid;
NavigationBar $userid;

DisplayError "No search string specified" if !defined $str;

if (!$lines) {
  my %options = GetUserOptions $userid;
  $lines = $options{"Page"};
} # if

$total = CountEmail(
  userid     => $userid,
  additional => "(subject like '%$str%' or sender like '%$str%')",
);

DisplayError "Nothing matching!" if $total eq 0;

$next //= 0;
$last = $next + $lines < $total ? $next + $lines : $total;

if (($next - $lines) > 0) {
  $prev = $next - $lines;
} else {
  $prev = $next eq 0 ? -1 : 0;
} # if

Body;

Footing $table_name;

exit;
