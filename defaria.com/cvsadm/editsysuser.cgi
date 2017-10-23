#!/usr/bin/perl
################################################################################
#
# File:         cvsadm/editsysuser.cgi
# Description:  Provides the edit sysuser screen for cvsadm
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
my $userid	= param "userid";
my $sysuser	= param "sysuser";
my $euid	= cookie "CVSAdmUser";

sub Body {
  print start_table {
    -align		=> "center",
    -bgcolor		=> "white",
    -border		=> 0,
    -cellspacing	=> 0,
    -cellpadding	=> 2,
    -width		=> "35%"};

  print start_form {
    -action	=> "modifysysuser.cgi",
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
  print "Group:";
  print end_td;
  print start_td {
    -valign	=> "middle"
  };
  print hidden {
    -name	=> "old_sysuser",
    -value	=> $sysuser
  };
  print textfield {
    -class	=> "inputfield",
    -size	=> 20,
    -name	=> "new_sysuser",
    -value	=> $sysuser
  };
  print end_td;
  print start_td {
    -valign	=> "middle",
    -align	=> "center"
  };
  print submit {
    -name	=> "Update SysUser"
  };
  print end_td;
  print end_Tr;
  print end_form;

  print start_Tr;
  print start_td {
    -colspan	=> 3,
    -valign	=> "middle",
    -align	=> "center"
  };
  print start_form {
    -action	=> "admin.cgi"
  };
  print hidden {
    -name	=> "cvs_server",
    -value	=> $cvs_server
  };
  print hidden {
    -name	=> "repository",
    -value	=> $repository
  };
  print hidden {
    -name	=> "userid",
    -value	=> $userid
  };
  print submit {
    -name	=> "Admin"
  };
  print end_td;
  print end_Tr;
  print end_form;
  print end_table;
} # Body

$userid= Heading (
		  "setcookie",
		  defined $euid ? $euid : $userid,
		  "CVSAdm:$Cvs_server:$repository: Edit Group",
		  "CVS Administration for $Cvs_server:$repository",
		  "Edit SysUser"
	  );
my $is_cvsadm	= IsAdmin $cvs_server, $repository, $userid;

if (!$is_cvsadm) {
  DisplayError "You are not authorized to edit sysusers";
} # if

Body;
Footing;

exit;
