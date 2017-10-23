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

use CGI qw (:standard *table start_Tr end_Tr start_td end_td start_div end_div);
use CGI::Carp "fatalsToBrowser";
use CVSAdm;

my $cvs_server	= param "cvs_server";
my $repository	= param "repository";
my $Cvs_server	= ucfirst $cvs_server;
my $userid	= cookie "CVSAdmUser";
my $errormsg	= param "errormsg";
my $logout	= param "logout";
my $action	= defined $logout ? "unsetcookie" : "getcookie";

sub Body {
  print "<center>";
  print start_form {
    -action	=> "select_repository.cgi"
  };
  print hidden {
    -name	=> "cvs_server",
    -value	=> $cvs_server
  };
  print submit {
    -name	=> "submit",
    -value	=> "<- Select Repository"
  };
  print end_form;
  print "</center>";

  print start_table {
    -align              => "center",
    -bgcolor            => "white",
    -border             => 0,
    -cellspacing        => 0,
    -cellpadding        => 2,
    -width              => "40%"};
  print start_form {
    -action	=> "edituser.cgi",
    -onSubmit	=> "return validate_login (this);"
  };
  print hidden {
    -name	=> "cvs_server",
    -value	=> $cvs_server
  };
  print hidden {
    -name	=> "repository",
    -value	=> $repository
  };
  print start_Tr;
  print start_td {
    -valign	=> "middle",
    -class	=> "label"
  };
  print "Username:";
  print end_td;
  print start_td {
    -valign	=> "middle"
  };
  print textfield {
    -class	=> "inputfield",
    -size	=> 20,
    -name	=> "userid",
    -value	=> $userid
  };
  print end_td;
  print end_Tr;

  print start_Tr;
  print start_td {
    -valign	=> "middle",
    -class	=> "label"
  };
  print "Password:";
  print end_td;
  print start_td {
    -valign	=> "middle"
  };
  print password_field {
    -class	=> "inputfield",
    -size	=> 20,
    -name	=> "password"
  };
  print end_td;
  print end_Tr;

  print start_Tr;
  print start_td {
    -colspan	=> 2,
    -align	=> "center"
  };
  print submit {
    -name	=> "submit",
    -value	=> "Login"
  };
  print end_td;
  print end_form;
  print end_Tr;

  if (defined $errormsg) {
    print Tr [
      td {-align        => "center",
          -colspan      => 2,
          -class        => "error"},
            $errormsg
    ];
  } # if

  print end_table;
} # Body

$userid = Heading (
		   $action,
		   $userid,
		   "CVSAdm:$Cvs_server:$repository: Login",
		   "CVS Administration for $Cvs_server:$repository",
		   "Please login"
		  );
Body;
Footing;

exit;
