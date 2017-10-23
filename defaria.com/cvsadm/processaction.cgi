#!/usr/bin/perl
################################################################################
#
# File:         cvsadm/processaction.cgi
# Description:  Processes and action, could be deleteuser, deletegroup, etc.
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
my $userid	= param "userid";
my $group	= param "group";
my $sysuser	= param "sysuser";
my $action	= param "action";

sub Body {
  my $error	= shift;
  my $msg	= shift;
  my $action	= shift;

  print "<center>";
  if ($error ne 0) {
    DisplayError $msg, $error
  } else {
    DisplayMsg $msg;
  } # if

  print start_form {
    -method	=> "post",
    -action	=> $action
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
    -name	=> "submit",
    -value	=> "OK"
  };
  print end_form;
  print "</center>";
} # body
my $msg = "Performing action: $action";
my $error;

if ($action eq "Edit User") {
  print redirect "edituser.cgi?cvs_server=$cvs_server&repository=$repository&userid=$userid";
} # if

if ($action eq "Edit Group") {
  print redirect "editgroup.cgi?cvs_server=$cvs_server&repository=$repository&group=$group";
} # if

if ($action eq "Edit SysUser") {
  print redirect "editsysuser.cgi?cvs_server=$cvs_server&repository=$repository&sysuser=$sysuser";
} # if

Heading (
	 "getcookie",
	 "",
	 "CVSAdm:$Cvs_server:$repository: Process Action",
	 "CVS Administration for $Cvs_server:$repository",
	 $msg
);

if ($action eq "Delete User") {
  $action = "admin.cgi";
  ($error, $msg) = DeleteUser $cvs_server, $repository, $userid;
} elsif ($action eq "Delete Group") {
  $action = "admin.cgi";
  ($error, $msg) = DeleteGroup $cvs_server, $repository, $group;
} elsif ($action eq "Delete SysUser") {
  $action = "admin.cgi";
  ($error, $msg) = DeleteSysUser $cvs_server, $repository, $sysuser;
} elsif ($action eq "Add Group") {
  $action = "addgroup.cgi";
  ($error, $msg) = AddGroup $cvs_server, $repository, $group;
} elsif ($action eq "Add SysUser") {
  $action = "addsysuser.cgi";
  ($error, $msg) = AddSysUser $cvs_server, $repository, $sysuser;
} else {
  $error	= 1;
  $msg		= "Unknown action \"$action\"";
} # if

Body $error, $msg, $action;
Footing;

exit;
