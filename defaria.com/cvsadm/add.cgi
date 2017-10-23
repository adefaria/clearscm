#!/usr/bin/perl
################################################################################
#
# File:         cvsadm/add.cgi
# Description:  Add user to the passwd and repository reader/writer files
# Author:       Andrew@DeFaria.com
# Created:      Thu Jul  7 16:54:07 PDT 2005
# Modified:
# Language:     Perl
#
# (c) Copyright 2005, Andrew@DeFaria.com, all rights reserved.
#
################################################################################
use strict;
use warnings;

use CGI qw (:standard *table start_Tr end_Tr start_div end_div);
use CGI::Carp "fatalsToBrowser";
use CVSAdm;

my $cvs_server	= param "cvs_server";
my $Cvs_server	= ucfirst $cvs_server;
my $repository	= param "repository";
my $userid	= param "username";

sub Body {
  my %user_record;

  $user_record {userid}		= $userid;
  $user_record {fullname}	= param ("fullname");
  $user_record {email}		= param ("email");
  $user_record {password}	= param ("password");

  my $system_user = param ("sysusers");

  if (defined $system_user) {
    $user_record {system_user} = $system_user;
  } # if

  my @groups = Groups $cvs_server, $repository;

  my $first_time = 1;

  foreach (@groups) {
    my $toggle = param $_;
    if (defined $toggle and $toggle eq "on") {
      if ($first_time) {
	$user_record {groups} = $_;
	$first_time = 0;
      } else {
      	$user_record {groups} .= ",$_";
      } # if
    } # if
  } # foreach

  if (param ($repository . "_reader")) {
    $user_record {$repository} = "r";
  } # if

  if (param ($repository . "_writer")) {
    $user_record {$repository} = "rw";
  } # if

  my ($status, $msg) = AddUser $cvs_server, $repository, %user_record;

  if ($status) {
    DisplayError $msg, $status;
  } else {
    DisplayMsg $msg;
  } # if

  print start_form {
    -method	=> "post",
    -action	=> "adduser.cgi"};
  print hidden {
    -name	=> "userid",
    -value	=> $user_record {userid}
  };
  print hidden {
    -name	=> "cvs_server",
    -value	=> $cvs_server
  };
  print hidden {
    -name	=> "repository",
    -value	=> $repository
  };
  print "<center>", submit {-name => "submit", -value => "OK"}, "</center>";
  print end_form;
} # Body

Heading (
	 "getcookie",
	 "",
	 "CVSAdm:$Cvs_server:$repository: Add User",
	 "CVS Administration for $Cvs_server:$repository",
);
Body;
Footing;

exit;
