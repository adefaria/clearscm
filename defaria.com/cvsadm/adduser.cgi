#!/usr/bin/perl
################################################################################
#
# File:         cvsadm/adduser.cgi
# Description:  Provides the add user screen
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
my $euid	= cookie "CVSAdmUser";
my $password	= param "password";

sub StartForm {
  my $action	= shift;
  my $onSubmit	= shift;

  if (defined $onSubmit) {
    print start_form {
      -action	=> $action,
      -onSubmit	=> $onSubmit
    };
  } else {
    print start_form {
      -action	=> $action
    };
  } # if

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

} # StartForm

sub Body {
  print "<center>";
  StartForm "admin.cgi";
  print submit {
    -name	=> "Admin"
  };
  print end_form;
  print "</center>";

  print start_table {
    -align		=> "center",
    -bgcolor		=> "white",
    -border		=> 0,
    -cellspacing	=> 0,
    -cellpadding	=> 2,
    -width		=> "50%"};

  StartForm  "add.cgi", "return validate_user (this);";

  my @sysusers		= SystemUsers $cvs_server, $repository;
  my $system_users	= popup_menu {-name	=> "sysusers",
				      -values	=> \@sysusers,
				      -class	=> "inputfield"};
  print Tr [
    td {-valign		=> "middle",
        -class		=> "label"},
      "Username:",
    td {-colspan	=> 2,
  	-valign		=> "middle"},
      textfield {-class	=> "inputfield",
		 -size	=> 15,
                 -name	=> "username"}
  ];
  print Tr [
    td {-valign		=> "middle",
        -class		=> "label"},
      "System User:",
    td {-colspan	=> 2,
	-valign		=> "middle"},
      $system_users
  ];
  print Tr [
    td {-valign		=> "middle",
        -class		=> "label"},
      "Password:",
    td {-colspan	=> 2,
  	-valign		=> "middle"},
      password_field {-class	=> "inputfield",
		      -size	=> 15,
		      -name	=> "password"}
  ];

  print Tr [
    td {-valign		=> "middle",
        -class		=> "label"},
      "Fullname:",
    td {-colspan	=> 2,
	-valign		=> "middle"},
      textfield {-class	=> "inputfield",
		 -size	=> 40,
                 -name	=> "fullname"}
  ];
  print Tr [
    td {-valign		=> "middle",
        -class		=> "label"},
      "Email:",
    td {-colspan	=> 2,
	-valign		=> "middle"},
      textfield {-class	=> "inputfield",
		 -size	=> 40,
                 -name	=> "email"}
  ];

  my @groups = Groups $cvs_server, $repository;
  my $groups;

  foreach (@groups) {
    my $checkbox_str;
    $checkbox_str = checkbox {
      -name	=> $_
    };
    $groups .= $checkbox_str . "<br>";
  } # foreach

  print Tr [
    td {-valign		=> "middle",
	-class		=> "label"},
      "Groups:",
    td {-colspan	=> 2,
	-valign		=> "middle"},
      $groups
  ];

  my $reader = checkbox {-name	=> "${repository}_reader",
		         -label	=> "Read access"};
  my $writer = checkbox {-name	=> "${repository}_writer",
		         -label	=> "Write access"};

  print Tr [
    td {-valign	=> "middle",
	-class	=> "label"},
      $repository,
    td {-align	=> "left",
        -width	=> 200,
	-valign	=> "middle"},
      $reader,
    td {-align	=> "left",
	-width	=> 200,
	-valign	=> "middle"},
      $writer
  ];

  print start_Tr;
  print start_td {
    -colspan	=> 2,
    -align	=> "center"
  };
  print submit {
    -name	=> "action",
    -value	=> "Add User"
  };
  print end_form;
  print end_td;

  StartForm "login.cgi";
  print start_td;
  print hidden {
    -name	=> "logout",
    -value	=> "yes"
  };
  print submit {
    -name	=> "Logout"
  };
  print end_form;
  print end_td;
  print end_table;
} # Body

$userid = Heading (
		   "getcookie",
		   $userid,
		   "CVSAdm:$Cvs_server:$repository: Add User",
		   "CVS Administration for $Cvs_server:$repository",
		   "Add New User"
		  );

if (!IsAdmin ($cvs_server, $repository, $userid)) {
  DisplayError "You are not authorized to add users";
} # if

Body;
Footing;

exit;
