#!/usr/bin/perl
################################################################################
#
# File:         cvsadm/admin.cgi
# Description:  Provides the admin screen for cvsadm
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
my $repository  = param "repository";
my $userid	= param "userid";
my $euid	= cookie "CVSAdmUser";
my $isadmin	= IsAdmin ($cvs_server, $repository, $euid);

sub StartForm {
  my $action = shift;

  print start_form {
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
  if (!$isadmin) {
    print hidden {
      -name	=> "userid",
      -value	=> $userid
    };
  } # if
} # StartForm

sub Body {
  my @users	= Users		$cvs_server, $repository;
  my @groups	= Groups	$cvs_server, $repository;
  my @sysusers	= SystemUsers	$cvs_server, $repository;

  print h3 "<center>Maintenance Menu</center>";

  print start_table {
    -align		=> "center",
    -bgcolor		=> "white",
    -border		=> 0,
    -cellspacing	=> 0,
    -cellpadding	=> 2,
    -width		=> "70%"};

  # Users
  print start_Tr;
    print start_td {
      -valign	=> "middle",
      -class	=> "label"
    };
    print "User:";
    print end_td;

    StartForm "processaction.cgi";
    print start_td {
      -valign	=> "middle",
      -align	=> "right",
    };
    print popup_menu {
      -name	=> "userid",
      -values	=> \@users,
      -class	=> "inputfield"
    };
    print end_td;

    print start_td {
      -valign	=> "middle"
    };
    print submit {
      -name	=> "action",
      -value	=> "Edit User"
    };
    print end_td;

    print start_td {
      -valign	=> "middle"
    };
    print submit {
      -name	=> "action",
      -value	=> "Delete User",
      -onClick	=> "return AreYouSure ('Are you sure you wish to delete the selected user?');"
    };
    print end_td;
    print end_form;

    StartForm "adduser.cgi";
    print start_td {
      -valign	=> "middle"
    };
    print submit {
      -name	=> "action",
      -value	=> "Create User"
    };
    print end_td;
    print end_form;
  print end_Tr;

  if ($euid eq "cvsroot") {
  # Groups
  print start_Tr;
    print start_td {
      -valign	=> "middle",
      -class	=> "label"
    };
    print "Group:";
    print end_td;

    StartForm "processaction.cgi";
    print start_td {
      -valign	=> "middle",
      -align	=> "right",
    };
    print popup_menu {
      -name	=> "group",
      -values	=> \@groups,
      -class	=> "inputfield"
    };
    print end_td;

    print start_td {
      -valign	=> "middle"
    };
    print submit {
      -name	=> "action",
      -value	=> "Edit Group"
    };
    print end_td;

    print start_td {
      -valign	=> "middle"
    };
    print submit {
      -name	=> "action",
      -value	=> "Delete Group",
      -onClick	=> "return AreYouSure ('Are you sure you wish to delete the selected group?');"
    };
    print end_td;
    print end_form;

    StartForm "addgroup.cgi";
    print start_td {
      -valign	=> "middle"
    };
    print submit {
      -name	=> "submit",
      -value	=> "Create Group"
    };
    print end_td;
    print end_form;

  print end_Tr;

  # System Users
  print start_Tr;
    print start_td {
      -valign	=> "middle",
      -class	=> "label"
    };
    print "System User:";
    print end_td;

    StartForm "processaction.cgi";
    print start_td {
      -valign	=> "middle",
      -align	=> "right",
    };
    print popup_menu {
      -name	=> "sysuser",
      -values	=> \@sysusers,
      -class	=> "inputfield"
    };
    print end_td;

    print start_td {
      -valign	=> "middle"
    };
    print submit {
      -name	=> "action",
      -value	=> "Edit SysUser"
    };
    print end_td;

    print start_td {
      -valign	=> "middle"
    };
    print submit {
      -name	=> "action",
      -value	=> "Delete SysUser",
      -onClick	=> "return AreYouSure ('Are you sure you wish to delete the selected system user?');"
    };
    print end_td;
    print end_form;

    StartForm "addsysuser.cgi";
    print start_td {
      -valign	=> "middle"
    };
    print submit {
      -name	=> "submit",
      -value	=> "Create SysUser"
    };
    print end_td;
    print end_form;
  print end_Tr;
} # if
  print start_Tr;
  print start_td {
    -colspan	=> 5,
    -align	=> "center",
    -valign	=> "middle"
  };
  print start_form {
    -action	=> "login.cgi"
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
    -name	=> "logout",
    -value	=> "yes"
  };
  print submit {
    -name	=> "Logout",
  };
  print end_td;
  print end_Tr;
  print end_table;
} # Body

Heading (
	 "getcookie",
	 $userid,
	 "CVSAdm:$Cvs_server:$repository: Administration",
	 "CVS Administration for $Cvs_server:$repository"
);

if (!$isadmin) {
  DisplayError "You are not authorized to add users";
} # if

Body;
Footing;

exit;
