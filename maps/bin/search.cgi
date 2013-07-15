#!/usr/bin/perl
################################################################################
#
# File:         $RCSfile: search.cgi,v $
# Revision:	$Revision: 1.1 $
# Description:	Search by sender and subject
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
$0 = $FindBin::Script;

use lib $FindBin::Bin;

use MAPS;
use MAPSWeb;
use MAPSUtil;
use CGI qw (:standard *table start_Tr start_td start_div end_Tr end_td end_div);
use CGI::Carp "fatalsToBrowser";

my $str		= param ("str");
my $next        = param ("next");
my $lines	= param ("lines");
my $userid;
my $prev;
my $total;
my $last;
my $table_name = "searchresults";

sub MakeButtons {
  my $prev_button = $prev >= 0 ?
    a ({-href => "search.cgi?str=$str;next=$prev"},
      "<img src=/maps/images/previous.gif border=0 alt=Previous align=middle>") : "";
  my $next_button = ($next + $lines) < $total ?
    a {-href => "search.cgi?str=$str;next=" . ($next + $lines)},
      "<img src=/maps/images/next.gif border=0 alt=Next align=middle>" : "";

  my $buttons = $prev_button;

  $buttons = $buttons .
    submit ({-name	=> "action",
	     -value	=> "Whitelist Marked",
       	     -onClick	=> "return CheckAtLeast1Checked (document.detail);"}) .
    submit ({-name	=> "action",
	     -value	=> "Blacklist Marked",
       	     -onClick	=> "return CheckAtLeast1Checked (document.detail);"}) .
    submit ({-name	=> "action",
	     -value	=> "Nulllist Marked",
       	     -onClick	=> "return CheckAtLeast1Checked (document.detail);"}) .
    submit ({-name	=> "action",
	     -value	=> "Reset Marks",
	     -onClick	=> "return ClearAll (document.detail);"});

  return $buttons . $next_button;
} # MakeButtons

sub HighlightSearchStr {
  $_ = shift;

  my $highlighted_str = font {-class => "found"}, $str;

  s/$str/<font class=\"found\">$&<\/font>/gi;

  return $_;
} # HighlightSearchStr

sub Body {
  my @emails;

  @emails = SearchEmails $userid, $str;

  my $current = $next + 1;

  print div {-align => "center"}, b (
    "(" . $current . "-" . $last . " of " . $total . ")");
  print start_form {
    -method	=> "post",
    -action	=> "processaction.cgi",
    -name	=> "detail"
  };
  my $buttons = MakeButtons;
  print div {-align	=> "center",
	     -class	=> "toolbar"}, $buttons;
  print start_table ({-align		=> "center",
		      -id		=> $table_name,
		      -border		=> 0,
		      -cellspacing	=> 0,
		      -cellpadding	=> 0,
		      -width		=> "100%"}) . "\n";
  print
    Tr [
      th {-class => "tableleftend"},
      th {-class => "tableheader"},	"Sender",
      th {-class => "tableheader"},	"Subject",
      th {-class => "tablerightend"},	"Date"
    ];

  foreach (@emails) {
    my $sender  = shift @{$_};
    my $subject = shift @{$_};
    my $date    = shift @{$_};

    my $display_sender  = HighlightSearchStr $sender;
    $subject = HighlightSearchStr $subject;
    $subject = $subject eq "" ? "&lt;Unspecified&gt;" : $subject;

    $next++;

    print Tr [
      td {-class => "tableleftdata",
	  -align => "center"},
	(checkbox {-name	=> "action$next",
		   -label	=> ""}),
        hidden ({-name		=> "email$next",
		 -default	=> $sender}),
      td {-class => "sender"}, 
	a {-href => "mailto:$sender"}, $display_sender,
      td {-class => "subject"},
	a {-href => "display.cgi?sender=$sender"}, $subject,
      td {-class => "dateright",
	  -width => "115"},		SQLDatetime2UnixDatetime $date
    ];
  } # foreach
  print end_table;
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

SetContext $userid;
NavigationBar $userid;

DisplayError "No search string specified" if !defined $str;

if (!defined $lines) {
  my %options = GetUserOptions $userid;
  $lines = $options{"Page"};
} # if

$total = MAPSDB::count "email",
  "userid = \"$userid\" and (subject like \"%$str%\" or sender like \"%$str%\")";

DisplayError "Nothing matching!" if $total eq 0;

$next = !defined $next ? 0 : $next;
$last = $next + $lines < $total ? $next + $lines : $total;

if (($next - $lines) > 0) {
  $prev = $next - $lines;
} else {
  $prev = $next eq 0 ? -1 : 0;
} # if

Body;

Footing $table_name;

exit;
