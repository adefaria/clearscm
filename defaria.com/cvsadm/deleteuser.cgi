#!/usr/bin/perl
################################################################################
#
# File:         cvsadm/login.cgi
# Description:  Provides login screen for cvsadm
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
my $Cvs_server  = ucfirst $cvs_server;
my $repository  = param "repository";
my $userid	= cookie "CVSAdmUser";
my $errormsg	= param ("errormsg");
my $logout	= param ("logout");

sub Body {
  print start_form {
    -method	=> "post",
    -action	=> "edituser.cgi",
    -onSubmit	=> "return validate_login (this);"
  };

  print start_table {
    -align              => "center",
    -bgcolor            => "white",
    -border             => 0,
    -cellspacing        => 0,
    -cellpadding        => 2,
    -width              => "40%"};
  print Tr ([
    td {-valign => "middle",
        -class  => "label"},
      "Username:",
    td {-valign => "middle"},
      textfield {-class => "inputfield",
                 -size  => 20,
                 -name  => "userid",
                 -value => $userid}
  ]);
  print Tr ([
    td {-valign => "middle",
        -class  => "label"},
      "Password:",
    td {-valign => "middle"},
      password_field {-class    => "inputfield",
                      -size     => 20,
                      -name     => "password"}
  ]);
  print Tr [
    td ({-colspan       => 2,
         -align         => "center"},
      submit (-name     => "submit",
              -value    => "Login"))
  ];

  if (defined $errormsg) {
    print Tr [
      td {-align        => "center",
          -colspan      => 2,
          -class        => "error"},
            $errormsg
    ];
  } # if

  print end_table;
  print end_form;
} # Body

if (defined $userid && !defined $logout) {
  print redirect "edituser.cgi";
  exit;
} # if

$userid = Heading (
		   "getcookie",
		   "",
		   "CVSAdm:$Cvs_server:$repository: Delete User",
		   "CVS Administration for $Cvs_server:$repository",
		   "Delete User"
		  );

my $errmsg = Sanity;

if (defined $errmsg) {
  DisplayError $errmsg;
} # if

Body;
Footing;

exit;
