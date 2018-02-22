#!/usr/bin/perl
################################################################################
#
# File:         $RCSfile: register.cgi,v $
# Revision:     $Revision: 1.1 $
# Description:	Register a MAPS user
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

use lib "$FindBin::Bin/../lib";

use MAPS;
use MAPSLog;
use MAPSWeb;

use CGI qw/:standard/;

my $fullname = param("fullname");
my $sender   = lc(param("sender"));
my $userid   = param("userid");

sub MyFooting() {
  print div({-align  => "center"},
    button (-name    => "close",
            -value   => "Close Window",
            -onClick => "window.close ()")
  );
  print end_html;
} # MyFooting

sub MyError($) {
  my ($errmsg) = @_;

  print h3 ({-class => "error",
             -align => "center"}, "ERROR: " . $errmsg);

  MyFooting;

  exit 1;
} # MyError

sub MyHeading() {
  print
    header(-title  => "MAPS Registration"),
    start_html(-title  => "MAPS Registration",
                -author => "Andrew\@DeFaria.com",
                -style  => {-src => "/maps/css/MAPSPlain.css"}
    );
  print
    h2 ({-class     => "header",
         -align     => "center"},
      font ({-class => "standout"}, 
      "MAPS"), "Registration Results"
	  );
} # MyHeading

# Main
MyHeading;

MyError("Sender not specified!") if $sender eq '';

my ($status, $rule) = OnWhitelist($sender, $userid, 0);

if ($status) {
  MyError("The email address $sender is already on ${userid}'s list)");
} # if

my $messages = Add2Whitelist($sender, $userid, $fullname);

print p "$fullname, your email address, $sender, has been added to ${userid}'s white list.";

if ($messages > 0) {
  if ($messages == 1) {
    print p "Your previous message has been delivered\n";
  } else {
    print p "Your previous $messages messages have been delivered\n";
  } # if
} elsif ($messages == -1) {
  MyError "Unable to deliver message";
} else {
  print p "Unable to find any old messages but future messages will now be delivered.";
} # if

MyFooting;
