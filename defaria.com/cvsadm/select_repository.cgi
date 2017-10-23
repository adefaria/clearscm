#!/usr/bin/perl
################################################################################
#
# File:         cvsadm/select_repository.cgi
# Description:  Provides repository selection
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

my $cvs_server = param "cvs_server";
my $Cvs_server = ucfirst $cvs_server;

sub Body {
  print "<center>";
  print start_form {
    -action	=> "select_server.cgi"
  };
  print submit {
    -name	=> "submit",
    -value	=> "<- Select Server"
  };
  print end_form;
  print "</center>";

  my @repositories = CVSRepositories $cvs_server;

  print start_table {
    -align              => "center",
    -bgcolor            => "white",
    -border             => 0,
    -cellspacing        => 0,
    -cellpadding        => 2,
    -width              => "30%"};
  print start_Tr;
  print start_td {
    -valign => "middle",
    -class  => "label"};
  print "Repository:";
  print end_td;
  print start_form {
    -action	=> "login.cgi"
  };
  print hidden {
    -name	=> "cvs_server"
  };
  print start_td {
    -valign	=> "middle"
  };
  print popup_menu {
    -name	=> "repository",
    -values	=> \@repositories,
    -class	=> "inputfield"
  };
  print "&nbsp;";
  print submit {
    -name	=> "Select"
  };
  print end_td;
  print end_form;
  print end_table;
} # Body

Heading (
	 "",
	 "",
	 "CVSAdm: Select Repository",
	 "CVS Administration Select $Cvs_server Repository",
	 "Please select a repository to manage"
);

Body;
Footing;

exit;
