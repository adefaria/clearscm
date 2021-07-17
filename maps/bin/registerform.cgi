#!/usr/bin/perl
################################################################################
#
# File:         $RCSfile: registerform.cgi,v $
# Revision:     $Revision: 1.1 $
# Description:  Register a MAPS user
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

use CGI qw/:standard *table start_div end_div/;

use lib "$FindBin::Bin/../lib";

use MAPS;
use MAPSWeb;

my $userid   = param ('userid');
my $Userid   = ucfirst $userid;
my $sender   = param ('sender');
my $errormsg = param ('errormsg');

sub MyHeading {
  print
    header     (-title  => "MAPS Registration"),
    start_html (-title  => "MAPS Registration",
                -author => "Andrew\@DeFaria.com",
                -style  => {-src => "/maps/css/MAPSPlain.css"},
                -script => [{ -language => "JavaScript1.2",
                -src    => "/maps/JavaScript/MAPSUtils.js"},
                  { -language => "JavaScript1.2",
                -src    => "/maps/JavaScript/CheckRegistration.js"}
                ]);
  print
    h2 ({-class => "header", -align => "center"},
      "Mail Authorization and Permission System");

  if ($errormsg) {
    DisplayError $errormsg;
    exit;
  } # if
} # MyHeading

sub Body {
  print start_div {-class => "content"};
  print p ("${Userid}'s email is protected by MAPS, a spam elimination
            system. In order to email $Userid you must register. You need
            only register once to be added to ${Userid}'s <i>white list</i>,
            thereafter you should have no problems emailing them. This is not
            unlike the acceptance procedure for many instant messaging clients.");
  print p ("Please enter your full name and click on Register to complete the
            registration.");
  print start_form {
    -method   => "post",
    -action   => "register.cgi",
    -onSubmit => "return validate (this);"
  };
  print start_table {
    -cellpadding => 2,
    -cellspacing => 0,
    -border      => 0,
    -align       => "center",
    -width       => "360"
  };
  print hidden (-name  => "userid",
                -value => "$userid");
  print Tr [
    td ({-class => "header"}, "Full name:") .
    td (textfield {-class => "inputfield",
                   -size  => 50,
                   -name  => "fullname"})
  ];
  print hidden (-name  => "sender",
                -value => "$userid");
  print end_table;
  print p {-align  => "center"},
    submit (-name  => "submit",
            -value => "Register");
  print end_form;
  print p ("Tired of dealing with unsolicited email (AKA SPAM)? Want to know
            more about MAPS, the Mail Authorization and Permission System for
            eliminating SPAM? Click",
            a ({-href   => "/maps/",
                -target => "_blank"},
                "here"),
            "to find out more.");
  print start_table {
    -cellpadding => 2,
    -cellspacing => 0,
    -border      => 1,
    -align       => "center",
    -width       => "50%"
  };
  print Tr [
    td ({-class => "note",
         -align => "center"}, "Note")
  ];
  print Tr [
    td ({-class => "notetext"}, 
    "This registration process is instantaneous however we reserve the
     right to remove you from the ${Userid}'s white list should you abuse
     this privilege.")
  ];
  print end_table;
  print end_div;

  return;
} # Body

if (!$userid) {
  $errormsg = "Internal error: Userid not specified";
} else {
  if (!UserExists ($userid)) {
    $errormsg = "Sorry but $userid is no longer a MAPS user";
  } # if
}

MyHeading;
Body;
Footing;
