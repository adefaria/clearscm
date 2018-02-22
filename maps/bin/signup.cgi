#!/usr/bin/perl
################################################################################
#
# File:         $RCSfile: signup.cgi,v $
# Revision:	$Revision: 1.1 $
# Description:	Sign up a MAPS user
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
use MAPSWeb;

use CGI qw (:standard);

my $userid            = param('userid');
my $fullname          = param('fullname');
my $email             = param('email');
my $password          = param('password');
my $repeated_password = param('repeated_password');
my $mapspop           = param('MAPSPOP');
my $history           = param('history');
my $days              = param('days');
my $dates             = param('dates');
my $tag_and_forward   = param('tag_and_forward');
my $message;

sub MyError {
  my $errmsg = shift;

  $userid = Heading (
    'getcookie',
    '',
    'Signup',
    'Signup'
  );

  NavigationBar $userid;

  print h2 {-align => 'center',
            -class => 'error'}, 'Error: ' . $errmsg;

  Footing;

  exit 1;
} # MyError

sub Body {
  # Check required fields
  if ($userid eq '' ) {
    MyError 'You must specify a userid!';
  } # if
  if ($email eq '' ) {
    MyError 'You must specify an email address!';
  } # if
  if ($password eq '') {
    MyError 'You must specify a password!';
  } # if
  if ($fullname eq '') {
    MyError 'You must specify your full name!';
  } # if

  # Password field checks
  if (length $password < 6) {
    MyError 'Password must be longer than 6 characters!';
  } # if
  if ($password ne $repeated_password) {
    MyError 'Passwords do not match';
  } # if

  my $status = AddUser($userid, $fullname, $email, $password);

  if ($status ne 0) {
    MyError 'Username already exists';
  } # if

  my %options = (
    MAPSPOP       => $mapspop,
    History       => $history,
    Page          => $days,
    Dates         => $dates,
    'Tag&Forward' => $tag_and_forward,
  );

  my $status = AddUserOptions($userid, %options);

  if ($status == 0) {
    print redirect ("/maps/?errormsg=User account \"$userid\" created.<br>You may now login");
  } elsif ($status == 1) {
    MyError "Username \"$userid\" already exists";
  } else {
    MyError "Unable to add useropts for \"$userid\"";
  } # if
} # Body

Body;
