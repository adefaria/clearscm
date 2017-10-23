#!/usr/bin/perl
################################################################################
#
# File:         cvsadm/addsysuser.cgi
# Description:  Add a new sysuser
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
my $Cvs_server	= ucfirst $cvs_server;
my $repository	= param "repository";
my $sysuser	= param "sysuser";
my $userid	= param "userid";

sub Body {
  print start_table {
    -align		=> "center",
    -bgcolor		=> "white",
    -border		=> 0,
    -cellspacing	=> 0,
    -cellpadding	=> 2,
    -width		=> "35%"
  };

  print start_form {
    -action	=> "processaction.cgi",
    -onSubmit	=> "return validate_sysuser (this);"
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
  print "Sysuser:";
  print end_td;
  print start_td {
    -valign	=> "middle"
  };
  print textfield {
    -class	=> "inputfield",
    -size	=> 20,
    -name	=> "sysuser",
    -value	=> $sysuser
  };
  print start_td {
    -align	=> "center"
  };
  print submit {
    -name	=> "action",
    -value	=> "Add SysUser"
  };
  print end_td;
  print end_form;

  print start_form {
    -action	=> "admin.cgi",
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
    -colspan	=> 3,
    -align	=> "center"
  };
  print submit {
    -name	=> "Admin",
  };
  print end_td;
  print end_Tr;
  print end_table;
} # Body

$userid = Heading (
		   "getcookie",
		   "",
		   "CVSAdm:$Cvs_server:$repository: Add Group",
		   "CVS Administration for $Cvs_server:$repository",
		   "Add New System User"
		   );

if (!IsAdmin ($cvs_server, $repository, $userid)) {
  DisplayError "You are not authorized to add sysusers";
} # if

Body;
Footing;

exit;
