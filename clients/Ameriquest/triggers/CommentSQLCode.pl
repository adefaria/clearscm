#!/usr/bin/perl
################################################################################
#
# File:         CommentSQLCode.pl
# Description:  This trigger script will gather certain information and write
#		that information into the element being checked in in the form
#		of a comment.
#
#		Here are the requirements as I understand them for the
#		trigger that Steve Lipson wants for the SQL
#		checkins. Basically he desires a trigger that will
#		capture the checkin comment and other information and
#		insert that information in the form of a comment at
#		the top of the checked in element. This trigger will:
#
#			* Be a postop trigger for the checkin action
#			* Not be an all element trigger rather it will
#			be attached to certain file elements in the
#			vob
#			* Be made for the <fill in vob name here> vob
#			* Only work on file elements - directory
#			elements are to be skipped
# 			* Only work on file elements that have an
# 			extension of .sql - other elements will be
# 			skipped
#
# Author:       Andrew@DeFaria.com
# Created:      Mon Jul 19 10:54:01 PDT 2004
# Language:     Perl
# Modifications:Wed Aug  4 12:41:47 PDT 2004
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
  $lib_path,
  $log_path,
  $me,
  $triggers_path
);

BEGIN {
  # Extract relative path and basename from script name.
  $0 =~ /(.*)[\/\\](.*)/;

  $abs_path	= (!defined $1) ? "." : File::Spec->rel2abs ($1);
  $me		= (!defined $2) ? $0  : $2;

  # Setup paths
  $lib_path		= "$abs_path/../lib";
  $log_path		= "$abs_path/../log";
  $triggers_path	= "$abs_path/../triggers";

  # Add the appropriate path to our modules to @INC array.
  unshift (@INC, "$lib_path");
} # BEGIN

use TriggerUtils;

sub getCurrentTime {
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime (time);
  $mon++;
  $year += 1900;
  $hour = "0" . $hour if $hour < 10;
  $min  = "0" . $min  if $min  < 10;
  return "$mon/$mday/$year\@$hour:$min";
} # getCurrentTime

sub parseLSActivity {
  my ($activity_id, $activity_title, $activity_owner);

  my @output = `cleartool lsactivity -cact -long`;

  if ($? ne 0 || $#output eq -1) {
    clearmsg "You are not set to an activity!";
    exit 1;
  } # if

  foreach (@output) {
    if (/^activity \"(\S*)\"/) {
      $activity_id = $1;
      next;
    } elsif (/owner: AMERIQUEST\\(\S*)/) {
      $activity_owner = $1;
      next;
    } elsif (/title: (.*)/) {
      $_ = $1;
      chomp; chop if /\r/;
      $activity_title = $_;
      next;
    } # if
  } # foreach

  return ($activity_id, $activity_owner, $activity_title);
} # parseLSActivity

# Get name of element and its type
my $pname        = $ENV{CLEARCASE_PN};
my $element_type = $ENV{CLEARCASE_ELTYPE};

# Skip directories and elements that aren't .sql
exit if $element_type =~ /directory/i || $pname !~ /\.sql$/i;

# Get comment and user
my $comment   = $ENV{CLEARCASE_COMMENT};
my $userid    = $ENV{CLEARCASE_USER};

# Format timestamp
my $timestamp = getCurrentTime;

# Parse output of lsactivity -cact -long
my ($activity_id, $activity_owner, $activity_title) = parseLSActivity;

# Open up $pname for reading and $pname.trig for writting
open PNAME_IN, $pname
  or clearlogmsg "Unable to open $pname for reading - $!\n", exit 1;

open PNAME_OUT, ">$pname.trig"
  or clearlogmsg "Unable to open $pname.trig for writing - $!\n", exit 1;

# Add comment to top of file
my $activity_str	= "$activity_id: $activity_title";
my $owner_str		= $activity_owner =~ /\$userid/i ? "$activity_owner ($userid)" : "$activity_owner";

print PNAME_OUT <<END;
-- Date:\t$timestamp
-- Activity:\t$activity_str
-- Owner:\t$owner_str
-- Comment:\t$comment
--------------------------------------------------------------------------------\n
END

# Append $pname
while (<PNAME_IN>) {
  print PNAME_OUT $_;
} # while

close PNAME_IN;
close PNAME_OUT;

# Switch $pname.trig -> $pname
rename "$pname.trig", $pname
  or clearlogmsg "Internal error - Unable to rename $pname.trig to $pname", exit 1;

# Allow checkin to proceed
exit 0;
