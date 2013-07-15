#!cqperl
################################################################################
#
# File:         CheckCodePage.pl
# Description:  With Clearquest 2003.06.15 there is more support for
#               internationalization. This means that Clearquest now
#               implements a Code Page which essentially defines the
#               valid character set for data. If it encounters invalid
#               characters the user must correct them.
#
#               This script will check a Clearquest database to see if
#               there are any invalid ASCII characters in string oriented
#               fields.
# Author:       Andrew@DeFaria.com
# Created:      Fri Sep 23 17:27:58 PDT 2005
# Language:     Perl
#
# (c) Copyright 2005, Andrew@DeFaria.com, all rights reserved
#
################################################################################
use strict;
use warnings;
use CQPerlExt;
use File::Spec;

our ($me, $SEPARATOR);

my ($abs_path, $lib_path);

BEGIN {
  # Extract relative path and basename from script name.
  $0 =~ /(.*)[\/\\](.*)/;

  $abs_path   = (!defined $1) ? "." : File::Spec->rel2abs ($1);
  $me         = (!defined $2) ? $0  : $2;
  $me         =~ s/\.pl$//;

  # Remove .pl for Perl scripts that have that extension
  $me         =~ s/\.pl$//;

  # Define the path separator
  $SEPARATOR  = ($^O =~ /MSWin/) ? "\\" : "/";

  # Setup paths
  $lib_path   = "$abs_path" . $SEPARATOR . ".." . $SEPARATOR . "lib";

  # Add the appropriate path to our modules to @INC array.
  unshift (@INC, "$abs_path");
  unshift (@INC, "$lib_path");
} # BEGIN

use PQA;
use Display;
use Logger;
use TimeUtils;

my $from_db_connection_name = "Controller";

sub Usage {
  my $msg = shift;

  display "ERROR: $msg\n" if defined $msg;

  display "Usage: $me\t[-u] [-v] [-d] [-from <connection name>]

Where:

  -u:                       Display usage
  -v:                       Turn on verbose mode
  -d:                       Turn on debug mode
  -from  <connection name>: Specify the from connection name
                            (Default: $from_db_connection_name)";
  exit 1;
} # Usage

while ($ARGV [0]) {
  if ($ARGV [0] eq "-v") {
    Display::set_verbose;
    Logger::set_verbose;
  } elsif ($ARGV [0] eq "-d") {
    set_debug;
  } elsif ($ARGV [0] eq "-from") {
    shift;
    if (!$ARGV [0]) {
      Usage "Must specify <connection name> after -from";
    } else {
      $from_db_connection_name = $ARGV [0];
    } # if
  } elsif ($ARGV [0] eq "-u") {
    Usage;
  } else {
    Usage "Unknown argument found: " . $ARGV [0];
  } # if

  shift (@ARGV);
} # while

my $log = Logger->new (path => ".");

my $process_start_time  = time;
my $start_time;

$log->msg ("Starting Cont session");
my $session = StartSession ("Cont", $from_db_connection_name);

$start_time = time;

#$log->msg ("Checking customer record...");
#CheckRecord $log, $session, "dbid", "customer", undef, @customer_fields;

#$log->msg ("Checking project record...");
#CheckRecord $log, $session, "dbid", "project", undef, @project_fields;

$log->msg ("Checking defect record...");
#CheckRecord $log, $session, "id", "defect", undef, @new_Cont_defect_fields;
CheckRecord $log, $session, "id", "defect", "Cont00022003", @new_Cont_defect_fields;

$log->msg ("Ending Cont session...");
EndSession $session;

display_duration $start_time, $log;


$log->msg ("\nInvalid character analysis\n");

my $i = 0;

foreach (sort (keys (%bad_chars))) {
  $log->msg (++$i . "\t$_\t$bad_chars{$_}\n");
} # foreach

display_duration $process_start_time, $log;
