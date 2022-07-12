#!/usr/bin/perl
################################################################################
#
# File:		NoPBLs.pl
# Description:	This trigger stops all users except for vobadm and Steve Lipson
#		(userid to be specified) from checking in PBLs which are
#		PowerBuilder libraries and should never be checked into a vob.
#		Why Steve Lipson would want this capability is unknown.
#		
# Author:	Andrew@DeFaria.com
# Created:	May 18, 2004
# Language:	Perl
# Modifications:
#
# (c) Copyright 2004, Andrew@DeFaria.com, all rights reserved
#
################################################################################
use strict;
use warnings;
use File::Spec;

# This will be set in the BEGIN block but by putting them here the become
# available for the whole script.
my (
  $abs_path,
  $me,
  $bin_path,
  $triggers_path,
  $lib_path,
  $log_path,
  $windows
);

BEGIN {
  # Extract relative path and basename from script name.
  $0 =~ /(.*)[\/\\](.*)/;

  $abs_path	= (!defined $1) ? "." : File::Spec->rel2abs ($1);
  $me		= (!defined $2) ? $0  : $2;

  # Check to see if we are running on Windows
  $windows	= ($^O =~ /MSWin/) ? "yes" : "no";

  # Setup paths
  $bin_path		= "$abs_path";
  $triggers_path	= "$abs_path/../triggers";
  $lib_path		= "$abs_path/../lib";
  $log_path		= "$abs_path/../log";

  # Add the appropriate path to our modules to @INC array.
  unshift (@INC, "$lib_path");
} # BEGIN

use TriggerUtils;

my $steve_lipson	= "sl020353";
my $user		= $ENV {CLEARCASE_USER};
my $pname		= $ENV {CLEARCASE_PN};

if ($pname =~ /\.pbl$/i and lc ($user) !~ $steve_lipson) {
  clearmsg "Check in's of pbl's are not allowed except for administrators";
  exit 1;
} # if

exit 0;
