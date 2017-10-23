#!/usr/bin/perl
################################################################################
#
# File:         cvsadm/modifysysuser.cgi
# Description:  Modify the sysusers file
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
my $old_sysuser	= param "old_sysuser";
my $new_sysuser	= param "new_sysuser";

sub Body {
  if (UpdateSysUser $cvs_server, $repository, $old_sysuser, $new_sysuser) {
    DisplayError "Unable to update " . $old_sysuser
  } else {
    DisplayMsg "Sysuser " . $new_sysuser . " updated";
    print start_form {
      -method	=> "post",
      -action	=> "editsysuser.cgi"};
    print hidden {
      -name	=> "cvs_server",
      -value	=> $cvs_server
    };
    print hidden {
      -name	=> "repository",
      -value	=> $repository
    };
    print "<center>", submit {-name => "submit", -value => "OK"}, "</center>";
    print end_form;
  } # if
} # Body

Heading (
	 "",
	 "",
	 "CVSAdm:$Cvs_server:$repository: Modify Sysuser",
	 "CVS Administration for $Cvs_server:$repository"
);
Body;
Footing;

exit;
