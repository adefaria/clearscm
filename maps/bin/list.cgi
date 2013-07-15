#!/usr/bin/perl
################################################################################
#
# File:         $RCSfile: list.cgi,v $
# Revision:	$Revision: 1.1 $
# Description:	Manage lists
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
use MAPSLog;
use MAPSUtil;
use MAPSWeb;
use CGI qw (:standard *table start_div end_div);
use CGI::Carp "fatalsToBrowser";

my $next	= param ("next");
my $lines	= param ("lines");
my $type	= param ("type");
my $message	= param ("message");
my $Type	= ucfirst $type;
my $userid;
my $prev;
my $total;
my $last;
my $table_name = "list";

sub Body {
  my $type = shift;

  if (defined $message) {
    print div {-align	=> "center"},
      font {-class	=> "error"}, $message;
  } # if

  print start_form {
    -method	=> "post",
    -action	=> "processaction.cgi",
    -name	=> "list"
  };

  # Print some hidden fields to pass along
  print
    hidden (-name	=> "type",
	    -default	=> $type),
    hidden (-name	=> "next",
	    -default	=> $next);

  my $current = $next + 1;

  print div {-align => "center"}, b (
    "(" . $current . "-" . $last . " of " . $total . ")");
  print start_div {-class	=> "toolbar",
		   -align	=> "center"};
  my $prev_button = $prev >= 0 ?
    a ({-href => "list.cgi?type=$type;next=$prev"},
      "<img src=/maps/images/previous.gif border=0 alt=Previous align=middle>") : "";
  my $next_button = ($next + $lines) < $total ?
    a {-href => "list.cgi?type=$type;next=" . ($next + $lines)},
      "<img src=/maps/images/next.gif border=0 alt=Next align=middle>" : "";
  print $prev_button,
    submit ({-name	=> "action",
	     -value	=> "Add New Entry",
	     -onClick	=> "return NoneChecked (document.list);"}),
    submit ({-name	=> "action",
	     -value	=> "Delete Marked",
	     -onClick	=> "return CheckAtLeast1Checked (document.list) && AreYouSure ('Are you sure you want to delete these entries?');"}),
    submit ({-name	=> "action",
	     -value	=> "Modify Marked",
	     -onClick	=> "return CheckAtLeast1Checked (document.list);"}),
    submit ({-name	=> "action",
	     -value	=> "Reset Marks",
	     -onClick	=> "return ClearAll (document.list);"}),
    $next_button;
  print end_div;
  print start_table {-align		=> "center",
		     -id		=> $table_name,
		     -border		=> 0,
		     -cellspacing	=> 0,
		     -cellpadding	=> 4,
		     -width		=> "100%"};
  print Tr [
    th {-class	=> "tableleftend"},	"Seq",
    th {-class	=> "tableheader"},	"Mark",
    th {-class	=> "tableheader"},	"Username",
    th {-class	=> "tableheader"},	"@",
    th {-class	=> "tableheader"},	"Domain",
    th {-class	=> "tablerightend"},	"Comments"
  ];

  my @list = ReturnList $type, $next, $lines;
  my %record;
  my $i = 1;

  foreach (@list) {
    %record = %{$_};
    $record{pattern}	= "&nbsp;" if !defined $record{pattern};
    $record{domain}	= "&nbsp;" if !defined $record{domain};
    $record{comment}	= "&nbsp;" if !defined $record{comment};

    my $leftclass  = ($i eq $lines || $record{sequence} eq $total) ?
      "tablebottomleft"  : "tableleftdata";
    my $dataclass  = ($i eq $lines || $record{sequence} eq $total) ?
      "tablebottomdata"  : "tabledata";
    my $rightclass = ($i eq $lines || $record{sequence} eq $total) ?
      "tablebottomright" : "tablerightdata";
    $i++;

    print Tr [
      td {-class	=> $leftclass,
	  -align	=> "center"}, $record{sequence},
      td {-class	=> $dataclass,
	  -align	=> "center"},
  	checkbox ({-name	=> "action$record{sequence}",
		   -label	=> ""}),
      td {-class	=> $dataclass,
	  -align	=> "right"}, $record{pattern},
      td {-class	=> $dataclass,
	  -align	=> "center"}, "\@",
      td {-class	=> $dataclass,
	  -align	=> "left"}, $record{domain},
      td {-class	=> $rightclass,
	  -align	=> "left"}, $record{comment}
    ];
  } # foreach
  print end_table;
  print end_form;

  print div ({-align	=> "center"},
    a ({-href => "/maps/bin/exportlist.cgi?type=$type"},
      submit ({-name	=> "export",
	       -value	=> "Export list"})),
    a ({-href => "/maps/bin/importlist.cgi?type=$type"},
      submit ({-name	=> "import",
	       -value	=> "Import List"})));
} # Body

# Main
my @scripts = ("ListActions.js");

$userid = Heading (
  "getcookie",
  "",
  "Manage $Type List",
  "Manage $Type List",
  "",
  $table_name,
  @scripts
);

SetContext $userid;
NavigationBar $userid;

if (!defined $lines) {
  my %options = GetUserOptions $userid;
  $lines = $options{"Page"};
} # if

$total = MAPSDB::count "list", "userid = \"$userid\" and type = \"$type\"";;

$next = !defined $next ? 0 : $next;
$last = $next + $lines < $total ? $next + $lines : $total;

if (($next - $lines) > 0) {
  $prev = $next - $lines;
} else {
  $prev = $next eq 0 ? -1 : 0;
} # if

Body $type;
Footing $table_name;

exit;
