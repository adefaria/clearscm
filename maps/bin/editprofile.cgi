#!/usr/bin/perl
################################################################################
#
# File:         $RCSfile: editprofile.cgi,v $
# Revision:	$Revision: 1.1 $
# Description:	Edit the user's profile
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

use CGI qw (:standard *table);

my $userid;
my $table_name = "profile";

sub Body {
  my $handle = FindUser $userid;

  my ($fullname, $email, $password);
  ($_, $fullname, $email, $password) = GetUser ($handle);

  $handle->finish;

  my %options = GetUserOptions $userid;

  print start_form {
    -method	=> "post",
    -action	=> "updateprofile.cgi",
    -onSubmit	=> "return validate (this);"
  };
  print start_table {
    -align		=> "center",
    -id			=> $table_name,
    -border		=> 1,
    -cellspacing	=> 0,
    -cellpadding	=> 2,
    -width		=> "100%"};
  print Tr ([
    td {-class	=> "label",
	-width	=> 134},
      "Username:",
    td {-width	=> 290},
      $userid,
    td {-class	=> "notetext"},
      "Specify a username to log into MAPS"
  ]) . "\n";
  print Tr ([
    td {-class	=> "label"},
      "Full name:",
    td (
      textfield {-class	=> "inputfield",
	         -size	=> 50,
		 -name	=> "fullname",
	         -value	=> "$fullname"}),
    td {-class	=> "notetext"},
      "Specify your full name"
  ]) . "\n";
  print Tr [
    td {-class	=> "label"},
      "Email:",
    td (
      textfield {-class	=> "inputfield",
	         -size	=> 50,
		 -name	=> "email",
	         -value	=> $email}),
    td {-class	=> "notetext"},
      "Your email address is used if you are a " .
    i ("Tag &amp; Forward") .
      " user. This is the email address that MAPS will forward your email to after it tags it. This email address is also used in case you forget your password so that we can email you your password."
  ];
  print Tr [
    td {-class	=> "label"},
      "Old Password:",
    td (
      password_field {-class	=> "inputfield",
		      -size	=> 20,
		      -name	=> "old_password"}),
    td {-class	=> "notetext"},
      "Enter your old password"
  ];
  print Tr [
    td {-class	=> "label"},
      "New Password:",
    td (
      password_field {-class	=> "inputfield",
		      -size	=> 20,
		      -name	=> "new_password",
		      -value	=> ""}),
    td {-class	=> "notetext"},
      "Choose a new password greater than 6 characters."
  ];
  print Tr [
    td {-class	=> "label"},
      "Repeat Password:",
    td (
      password_field {-class	=> "inputfield",
		      -size	=> 20,
		      -name	=> "repeated_password",
		      -value	=> ""}),
    td {-class	=> "notetext"},
      "Re-enter your password so we can be sure you typed it correctly."
  ];
  print Tr [
    td {-class	=> "label"},
      "MAPSPOP user:",
    td (
      font ({-class => "label"},
      radio_group {-name	=> "MAPSPOP",
		   -values	=> ["yes", "no"],
		   -default	=> "no",
		   -labels	=> {"yes"	=> "Yes",
				    "no"	=> "No"}})),
    td {-class	=> "notetext"},
      "MAPSPOP users need to download " .
    a ({-href => "/maps/bin/MAPSPOP.exe"}, "MAPSPOP") .
      ". See " .
    a ({-href => "/maps/doc/UsingMAPSPOP.html"}, "Using MAPSPOP") .
      " for more information."
  ];
  print Tr [
    td {-class	=> "label"},
      "Keep history for:",
    td (
      font ({-class => "label"},
      popup_menu {-class	=> "inputfield",
		  -name		=> "history",
		  -values	=> ["7", "14", "30", "60", "90"],
		  -default	=> $options{"History"}}),
      font ({-class => "label"}, " days")),
    td {-class	=> "notetext"},
      "This specifies how many days of history that MAPS will keep before discarding returned messages."
  ];
  print Tr [
    td {-class	=> "label"},
      "Dates in Stats Page:",
    td (
      font ({-class => "label"},
      popup_menu {-class	=> "inputfield",
		  -name		=> "dates",
		  -values	=> ["7", "14", "21", "30"],
		  -default	=> $options{"Dates"}})),
    td {-class	=> "notetext"},
      "This specifies how many days are displayed in the MAPS Stats Page."
  ];
  print Tr [
    td {-class	=> "label"},
      "Entries per page:",
    td (
      font ({-class => "label"},
      popup_menu {-class	=> "inputfield",
		  -name		=> "days",
		  -values	=> ["10", "20", "30", "40", "50"],
		  -default	=> $options{"Page"}})),
    td {-class	=> "notetext"},
      "This specifies how many entries are displayed per page in the online MAPS Reports."
  ];
  print Tr [
    td {-class	=> "label"},
      i ("Tag & Forward:"),
    td (
      font ({-class => "label"},
      radio_group {-name	=> "tag_and_forward",
		   -values	=> ["yes", "no"],
		   -default	=> "no",
		   -labels	=> {"yes"	=> "Yes",
				    "no"	=> "No"}})),
    td {-class	=> "notetext"},
    i ("Tag and Forward") .
      " means that MAPS will not filter or save any email for you. Instead it will simply add an X-MAPS header to your email indicating what MAPS would have done with the email. This allows you to filter your email in your local email client."
  ];
  print end_table;
  print br (div {-align => "center"},
    submit (-name	=> "submit",
	    -value	=> "Update Profile"));
  print end_form;
} # Body

# Main
my @scripts = ("MAPSUtils.js", "CheckEditProfile.js");

$userid = Heading (
  "getcookie",
  "",
  "Edit Profile",
  "Spam Elimination System",
  "",
  $table_name,
  @scripts
);

SetContext $userid;
NavigationBar $userid;

Body;

Footing $table_name;

exit;
