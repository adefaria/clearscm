#!/usr/bin/perl
################################################################################
#
# File:         cvsadm/edituser.cgi
# Description:  Provides the edit user screen for cvsadm
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
my $password	= param "password";
my $action;
my $euid	= cookie "CVSAdmUser";
my $is_cvsadm;
my $needs_login;

if (defined $euid) {
  $is_cvsadm	= IsAdmin $cvs_server, $repository, $euid;
  $needs_login = "no";
} else {
  $is_cvsadm	= IsAdmin $cvs_server, $repository, $userid;
  $needs_login = "yes";
} # if

sub Body {
  my %passwd_entry = PasswdEntry $cvs_server, $repository, $userid;

  if ($is_cvsadm) {
    print "<center>";
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
    print end_form;
    print "</center>";
  } # if

  print start_table {
    -align		=> "center",
    -bgcolor		=> "white",
    -border		=> 0,
    -cellspacing	=> 0,
    -cellpadding	=> 2,
    -width		=> "50%"};

  print start_form {
    -action	=> "modifyuser.cgi",
    -onSubmit	=> "return validate_user (this);"
  };
  print hidden {
    -name	=> "cvs_server",
    -value	=> $cvs_server
  };
  print hidden {
    -name	=> "repository",
    -value	=> $repository
  };

  if ($is_cvsadm) {
    my @sysusers	= SystemUsers $cvs_server, $repository;
    my $system_user 	= SystemUser  $cvs_server, $repository, $userid;
    my $system_users	= popup_menu {-name	=> "sysusers",
				      -values	=> \@sysusers,
				      -class	=> "inputfield",
				      -default	=> $system_user};
    print Tr [
      td {-valign		=> "middle",
          -class		=> "label"},
        "Username:",
      td {-colspan		=> 2,
  	  -valign		=> "middle"},
          $userid,
  	hidden {-name		=> "userid",
		-value		=> $userid}
    ];
    print Tr [
      td {-valign		=> "middle",
          -class		=> "label"},
        "System User:",
      td {-colspan		=> 2,
  	-valign			=> "middle"},
          $system_users
    ];
  } else {
    print Tr [
      td {-valign		=> "middle",
          -class		=> "label"},
        "Username:",
      td {-colspan		=> 2,
  	-valign			=> "middle"},
          $userid . " (" . $passwd_entry {system_user} . ")",
  	hidden {-name		=> "userid",
		-value		=> $userid}
    ];
  } # if

  if (!$is_cvsadm) {
    print Tr [
      td {-valign		=> "middle",
          -class		=> "label"},
        "Password:",
      td {-colspan		=> 2,
  	  -valign		=> "middle"},
        password_field {-class	=> "inputfield",
		        -size	=> 15,
		        -name	=> "old_password"}
    ];
  } # if

  print Tr ([
    td {-valign		=> "middle",
        -class		=> "label"},
      "New Password:",
    td {-colspan	=> 2,
	-valign		=> "middle"},
      password_field {-class	=> "inputfield",
		      -size	=> 15,
		      -name	=> "new_password"}
  ]);
  if (!$is_cvsadm) {
    print Tr [
      td {-valign		=> "middle",
          -class		=> "label"},
        "Confirm Password:",
      td {-colspan	=> 2,
  	  -valign		=> "middle"},
        password_field {-class	=> "inputfield",
		      -size	=> 15,
		      -name	=> "repeated_password"}
    ];
  } # if
  print Tr [
    td {-valign		=> "middle",
        -class		=> "label"},
      "Fullname:",
    td {-colspan	=> 2,
	-valign		=> "middle"},
      textfield {-class	=> "inputfield",
		 -size	=> 40,
                 -name	=> "fullname",
	         -value	=> $passwd_entry {fullname}}
  ];
  print Tr [
    td {-valign		=> "middle",
        -class		=> "label"},
      "Email:",
    td {-colspan	=> 2,
	-valign		=> "middle"},
      textfield {-class	=> "inputfield",
		 -size	=> 40,
                 -name	=> "email",
	         -value	=> $passwd_entry {email}}
  ];

  my @groups = Groups $cvs_server, $repository;
  my $groups;

  foreach (@groups) {
    my $in_group = UserInGroup $cvs_server, $repository, $userid, $_;
    my $checkbox_str;
    if ($is_cvsadm) {
      $checkbox_str = checkbox {-name		=> $_,
				-checked	=> $in_group};
    } else {
      $checkbox_str = checkbox {-name		=> $_ . "_readonly",
				-checked	=> $in_group,
				-label		=> $_,
				-disabled	=> 1};
      print hidden {-name			=> $_,
		    -value			=> "on"} if $in_group;
    } # if
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

  my $reader = "";
  my $writer = "";

  if (IsReader $cvs_server, $repository, $userid) {
    if ($is_cvsadm) {
      $reader = checkbox {-name		=> "${repository}_reader",
			  -label	=> "Read access",
			  -checked	=> 1};
    } else {
      $reader = checkbox {-name		=> "${repository}_reader_readonly",
			  -label	=> "Read access",
			  -checked	=> 1,
			  -disabled	=> 1};
      print hidden {-name		=> "${repository}_reader",
		    -value		=> "on"};
    } # if
  } else {
    if ($is_cvsadm) {
      $reader = checkbox {-name		=> "${repository}_reader",
			  -label	=> "Read access"};
    } else {
      $reader = checkbox {-name		=> "${repository}_reader_readonly",
			  -label	=> "Read access",
			  -disabled	=> 1};
      print hidden {-name		=> "${repository}_reader",
		    -value		=> "off"};
    } # if
  } # if

  if (IsWriter $cvs_server, $repository, $userid) {
    if ($is_cvsadm) {
      $writer = checkbox {-name		=> "${repository}_writer",
			  -label	=> "Write access",
			  -checked	=> 1};
    } else {
      $writer = checkbox {-name		=> "${repository}_writer_readonly",
			  -label	=> "Write access",
			  -checked	=> 1,
			  -disabled	=> 1};
      print hidden {-name		=> "${repository}_writer",
		    -value		=> "on"};
    } # if
  } else {
    if ($is_cvsadm) {
      $writer = checkbox {-name		=> "${repository}_writer",
			  -label	=> "Write access"};
    } else {
      $writer = checkbox {-name		=> "${repository}_writer_readonly",
			  -label	=> "Write access",
			  -disabled	=> 1};
      print hidden {-name		=> "${repository}_writer",
		    -value		=> "off"};
    } # if
  } # if

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
    -name	=> "Submit"
  };
  print end_form;
  print end_td;
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
  print start_td;
  print submit {
    -name	=> "Logout"
  };
  print end_form;
  print end_td;
  print end_table;
} # Body

my $result;

if ($is_cvsadm and $needs_login eq "no") {
  # Editing other user as cvsadm
  Heading (
	   "setcookie",
	   defined $euid ? $euid : $userid,
	   "CVSAdm:$Cvs_server:$repository: Edit User",
	   "CVS Administration for $Cvs_server:$repository",
	   "Edit User"
	  );
} else {
  # Need to login
  $result = CVSAdm::Login $cvs_server, $repository, $userid, $password;

  if ($result == 1) {
    if ($userid eq "") {
      print redirect "login.cgi?cvs_server=$cvs_server&repository=$repository&errormsg=Please specify a username";
      exit $result;
    } else {
      print redirect "login.cgi?cvs_server=$cvs_server&repository=$repository&errormsg=No such user $userid";
      exit $result;
    } # if
  } elsif ($result == 2) {
    print redirect "login.cgi?cvs_server=$cvs_server&repository=$repository&errormsg=Invalid password";
    exit $result;
  } else {
    $action = "setcookie";
  } # if
  $userid = Heading (
		     $action,
		     $userid,
		     "CVSAdm:$Cvs_server:$repository: Edit User",
		     "CVS Administration for $Cvs_server:$repository",
		     "Edit User"
		    );
} # if

Body;
Footing;

exit;
