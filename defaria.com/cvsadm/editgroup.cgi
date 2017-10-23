#!/usr/bin/perl
################################################################################
#
# File:         cvsadm/editgroup.cgi
# Description:  Provides the edit group screen for cvsadm
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
my $group	= param "group";
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
    -action	=> "modifygroup.cgi",
    -onSubmit	=> "return validate_group (this);"
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
    -name	=> "old_group",
    -value	=> $group
  };
  print textfield {
    -class	=> "inputfield",
    -size	=> 20,
    -name	=> "new_group",
    -value	=> $group
  };
  print end_td;
  print start_td {
    -valign	=> "middle",
    -align	=> "center"
  };
  print submit {
    -name	=> "Update Group"
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
		  "Edit Group"
	  );
my $is_cvsadm	= IsAdmin $cvs_server, $repository, $userid;

if (!$is_cvsadm) {
  DisplayError "You are not authorized to edit groups";
} # if

Body;
Footing;

exit;
