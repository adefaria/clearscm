#!/usr/bin/perl
################################################################################
#
# File:         cvsadm/select_server.cgi
# Description:  Provides server selection
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

sub Body {
  my %cvs_servers = CVSServers;
  my @cvs_servers = sort keys (%cvs_servers);

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
  print "CVS Server:";
  print end_td;
  print start_form {
    -action => "select_repository.cgi"
  };
  print start_td {
    -valign	=> "middle"
  };
  print popup_menu {
    -name	=> "cvs_server",
    -values	=> \@cvs_servers,
    -class	=> "inputfield"
  };
  print "&nbsp;";
  print submit {
    -name => "Select"
  };
  print end_td;
  print end_form;
  print end_table;
} # Body

Heading (
	 "",
	 "",
	 "CVSAdm: Select Server",
	 "CVS Administration Select Server",
	 "Please select a server to manage"
);

Body;
Footing;

exit;
