#!/usr/bin/perl
################################################################################
#
# File:         $RCSfile: checkaddress.cgi,v $
# Revision:	$Revision: 1.1 $
# Description:	Check an email address
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

use CGI qw (:standard);

# Get MAPSUser from cookie
my $userid;

if (param "user") {
  $userid = param "user";
} else {
  $userid = cookie ("MAPSUser");
} # if

my $sender = param ("sender");

sub Heading {
  print
    header     (-title	=> "MAPS: Check Address"),
    start_html (-title  => "MAPS: Check Address",
		-author	=> "Andrew\@DeFaria.com");
    print h3 {-align	=> "center",
	      -class	=> "header"},
    "MAPS: Checking address $sender";
} # Heading

sub Body {
  my ($status, $rule);

  ($status, $rule) = OnNulllist $sender;
  if ($status) {
    print div {-align	=> "center"},
      font {-color	=> "grey"},
      "Messages from", b ($sender), "will be", b ("discarded"), br, hr;
    print $rule;
  } else {
    ($status, $rule) = OnBlacklist $sender;
    if ($status) {
      print div {-align	=> "center"},
	font {-color	=> "black"},
	"Messages from", b ($sender), "will be", b ("blacklisted"), br, hr;
      print $rule;
    } else {
      ($status, $rule) = OnWhitelist $sender;
      if ($status) {
	print div {-align	=> "center"},
	  font {-color	=> "green"},
          "Messages from", b ($sender), "will be", b ("delivered"), br, hr;
	print $rule;
      } else {
	print div {-align	=> "center"},
	  font {-color	=> "red"},
          "Messages from", b ($sender), "will be", b ("returned");
      } # if
    } # if
  } # if

  print br div {-align	=> "center"},
    submit (-name	=> "submit",
	    -value	=> "Close",
	    -onClick	=> "window.close (self)");
} # Body

sub Footing {
  print end_html;
} # Footing

# Main
SetContext $userid;
Heading;
Body;
Footing;

exit;

