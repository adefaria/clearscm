#!/usr/bin/perl
################################################################################
#
# File:         $RCSfile: updateprofile.cgi,v $
# Revision:     $Revision: 1.1 $
# Description:  Update the users profile
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

use MAPS;
use MAPSWeb;

use CGI qw (:standard);

my ($userid, $Userid);
my $name              = param 'fullname';
my $email             = param 'email';
my $old_password      = param 'old_password';
my $new_password      = param 'new_password';
my $repeated_password = param 'repeated_password';
my $mapspop           = param 'MAPSPOP';
my $history           = param 'history';
my $days              = param 'days';
my $dates             = param 'dates';
my $tag_and_forward   = param 'tag_and_forward';

sub Body {
  my %options = (
    MAPSPOP       => $mapspop,
    History       => $history,
    Page          => $days,
    Dates         => $dates,
    'Tag&Forward' => $tag_and_forward,
  );

  if ($old_password) {
    my $dbpassword             = UserExists($userid);
    my $encrypted_old_password = Encrypt($old_password, $userid);

    if ($dbpassword ne $encrypted_old_password) {
      DisplayError 'Your old password was not correct!';
    } # if
  } # if

  if ($new_password) {
    unless ($old_password) {
      DisplayError "You must provide your old password in order to change it";
    } else {
      if ($repeated_password ne $new_password) {
        DisplayError "Your new password does not match your repeat password";
      } else {
        $new_password = Encrypt($new_password, $userid);
      } # if
    } # unless
  } # if

  if (UpdateUser(
    userid   => $userid,
    name     => $name,
    email    => $email,
    password => $new_password,
  ) != 0) {
    DisplayError "Unable to update user record for user $userid";
  } # if

  if (UpdateUserOptions($userid, %options) != 0) {
    DisplayError "Unable to update user options for user $userid";
  } # if

  print h2 {-class => 'header',
            -align => 'center'},
    "${Userid}'s profile has been updated";

  return;
} # Body

$userid = Heading (
  'getcookie',
  '',
  'Update Profile',
  "Update user's profile",
);

$userid //= $ENV{USER};

$Userid = ucfirst $userid;

SetContext($userid);
NavigationBar($userid);

Body;

Footing;

exit;