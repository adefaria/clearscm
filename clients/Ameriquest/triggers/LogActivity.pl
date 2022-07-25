#!/usr/bin/perl
################################################################################
#
# File:		LogActivity.pl
# Description:	This trigger will log all activity into a "log" file of HTML
#		format. Logfiles are kept per day thus the date appears as
#		part of their names.
#
#		This script requires one parameter, which is a path to a
#		folder where to store the log files. Generally this is a UNC
#		path to an area under some web server's DocumentRoot.
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

use Time::localtime;

if (!defined $ARGV [0]) {
  clearlogmsg "Must specify a logpath!";
  exit 1;
} # if

my $logpath = $ARGV [0];

sub Log {
  my $logfile	= shift;
  my $vob	= shift;
  my $title	= shift;
  my $time	= shift;
  my $user	= shift;
  my $type	= shift;
  my $action	= shift;
  my $path	= shift;
  my $element	= shift;
  my $version	= shift;
  my $comments	= shift;

  $logfile = $logpath . "\\" . $logfile;

  if (-e "$logfile") {
     my $status = open LOG, ">>$logfile";

     if (!defined $status) {
       clearlogmsg "Unable to open log file $logfile - $!";
       return 1;
     } # if

     print LOG <<END;
<tr>
  <td><font size=-1>$time</font></td>
  <td><font size=-1>$user</font></td>
  <td><font size=-1>$type</font></td>
  <td><font size=-1>$action</font></td>
  <td><font size=-1>$path</font></td>
  <td><font size=-1>$element</font></td>
  <td><font size=-1>$version</font></td>
  <td><font size=-1>$comments</font></td>
</tr>
END
  } else {
     my $status = open LOG, ">>$logfile";

     if (!defined $status) {
       clearlogmsg "Unable to open log file $logfile - $!";
       return 1;
     } # if

     print LOG <<END;
<html>
  <head>
    <title>$title</title>
  </head>
  <body>
    <h2 align=center>$title</h2>
    <table align=center border=1 cellspacing=0 cellpadding=2>
      <tr bgcolor="teal" align="center">
        <th><font color="white" size=-1>Time</font></th>
        <th><font color="white" size=-1>User</font></th>
        <th><font color="white" size=-1>Type</font></th>
        <th><font color="white" size=-1>Action</font></th>
        <th><font color="white" size=-1>Path</font></th>
        <th><font color="white" size=-1>Name</font></th>
        <th><font color="white" size=-1>Version</font></td>
        <th><font color="white" size=-1>Comment</font></th>
      </tr>
      <tr>
        <td><font size=-1>$time</font></td>
        <td><font size=-1>$user</font></td>
        <td><font size=-1>$type</font></td>
        <td><font size=-1>$action</font></td>
        <td><font size=-1>$path</font></td>
        <td><font size=-1>$element</font></td>
        <td><font size=-1>$version</font></td>
        <td><font size=-1>$comments</font></td>
      </tr>
END
  } # if

  close LOG;

  return 0;
} # Log

# Format $curdate as yyyy-mm-dd and $curtime as hh:mm [AP]m
my $time	= localtime;
my $year	= $time->year + 1900; 
my $month	= ($time->mon < 9)   ? "0" . ($time->mon + 1) : $time->mon + 1;
my $day		= ($time->mday < 10) ? "0" . $time->mday      : $time->mday;
my $hours	= $time->hour;
my $minutes	= ($time->min < 10)  ? "0" . $time->min	    : $time->min;
my $ampm	= "Am";

if ($hours > 12) {
  $ampm = "Pm";
  $hours -= 12;
} elsif ($hours eq 12) {
  $ampm = "Pm";
} # if

my $curtime = $hours . ":" . $minutes . " $ampm";
my $curdate = $year  . "-" . $month   . "-" . $day;

# Get Clearcase environment variables that we'll need
my $type	= $ENV {CLEARCASE_ELTYPE};
my $user	= $ENV {CLEARCASE_USER};
my $vob		= $ENV {CLEARCASE_VOB_PN};

# Remove leading "\" from vob, just cause it looks ugly! :-)
$vob =~ s/^\\//;

my $version	= $ENV {CLEARCASE_ID_STR};

# $version is N/A for mkelem and rmname
$version = "<font color=#666666>N/A</font>" if (!defined $version);

my $comments	= $ENV {CLEARCASE_COMMENT};

# $comments is N/A for rmname
$comments = "<font color=#666666>N/A</font>" if (!defined $comments);

my $pname	= $ENV {CLEARCASE_PN};
my $action	= $ENV {CLEARCASE_OP_KIND};

my $title = "Activity in vob $vob on $month/$day/$year";

# Extract element
my $element	= substr ($pname, rindex ($pname, "\\") + 1);
my $path	= substr ($pname, rindex ($pname, $vob) + length ($vob) + 1);

$path = ($path eq $element) ? ".\\" : substr ($path,  0, rindex ($path, $element) - 1);

my $logfile = "${vob}_$curdate.html";

# Create/Add to HTML logfile.
exit (Log $logfile, $vob, $title, $curtime, $user, $type, $action, $path, $element, $version, $comments);
