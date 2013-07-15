#!/usr/bin/perl
################################################################################
#
# File:         $RCSfile: main.cgi,v $
# Revision:	$Revision: 1.1 $
# Description:	This is the main or home page for maps. It is presented when the
#		user logs in.
# Author:       Andrew@DeFaria.com
# Created:	Fri Nov 29 14:17:21  2002
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

use CGI qw (:standard *table start_Tr end_Tr start_div end_div);
use CGI::Carp "fatalsToBrowser";

my $new_userid = param ("userid");
my $password   = param ("password");

sub Body {
  print
    h3 ("Welcome to MAPS!"),
    p  "This is the main or home page of MAPS. To the left
       you see a menu of choices that you can use to explore MAPS
       functionality.",
    a ({-href	=> "/maps/bin/stats.cgi"},
      "Statistics"),
      "gives you a view of the spam that MAPS has been trapping for you
       in tabular format. You can use",
    a ({-href => "/maps/bin/editprofile.cgi"},
      "Edit Profile"),
      "to change your profile information or to change your password.";
  print
    p "MAPS also offers a series of web based",
    a ({-href => "/maps/Reports.html"},
      "Reports"),
      "to analyze your mail flow. You can manage your",
    a ({-href => "/maps/bin/list.cgi?type=white"},
       "White") . ",",
    a ({-href => "/maps/bin/list.cgi?type=black"},
       "Black"), "and",
    a ({-href => "/maps/bin/list.cgi?type=null"},
       "Null"),
       "lists although MAPS seeks to put that responsibility on those
	who wish to email you. You can use this to pre-register somebody
 	or to black or null list somebody. You can also import/export
	your lists through these pages.";
  print
    p a ({-href => "/maps/Admin.html"},
      "MAPS Administration"),
      "is to administer MAPS itself and is only available to MAPS
       Administrators.";
  print
    p "Also on the left you will see ", i ("Today's Activity"),
      "which quickly shows you what mail MAPS processed today for you.";
} # Body

# Main
my $action;

if (defined $new_userid) {
  my $result = Login $new_userid, $password;

  if ($result == -1) {
    if ($new_userid eq "") {
      print redirect ("/maps/?errormsg=Please specify a username");
      exit $result;
    } else {
      print redirect ("/maps/?errormsg=User \"$new_userid\" does not exist");
      exit $result;
    } # if
  } elsif ($result == -2) {
    print redirect ("/maps/?errormsg=Invalid password");
    exit $result;
  } else {
    $action = "setcookie";
  } # if
} else {
  $action = "getcookie"
} # if

my $userid = Heading (
  $action,
  $new_userid,
  "Home",
  "Spam Elimination System"
);

SetContext $userid;
NavigationBar $userid;
Body;
Footing;

exit;
