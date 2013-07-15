#!/usr/bin/perl
################################################################################
#
# File:         $RCSfile: TriggerUtils.pm,v $
# Revision:	$Revision: 1.3 $
# Description:  Perl module for Trigger Utilities.
# Author:       Andrew@ClearSCM.com
# Created:      Fri Mar 12 10:17:44 PST 2004
# Modified:	$Date: 2011/01/09 01:04:33 $
# Language:     perl
#
# (c) Copyright 2005, ClearSCM, Inc. all rights reserved
#
################################################################################
use warnings;

package TriggerUtils;
  use base "Exporter";
  use File::Spec;
  use OSDep;

  our @EXPORT = qw (
    clearmsg
    clearlog
    clearlogmsg);

  my ($abs_path, $me, $log_path, $logfile, $user);

  BEGIN {
    # Extract relative path and basename from script name.
    $0 =~ /(.*)[\/\\](.*)/;

    $abs_path	= (!defined $1) ? "." : File::Spec->rel2abs ($1);
    $me		= (!defined $2) ? $0  : $2;

    # Setup paths
    $log_path	= "$abs_path$SEPARATOR..${SEPARATOR}triggers";

    # Where to log things
    $logfile	= "$log_path${SEPARATOR}trigger.log";

    # Get username to use to tag messages
    $user	= $ENV {CLEARCASE_USER};
  } # BEGIN

  sub clearmsg {
    # Display a message to the user using clearprompt
    my $message = shift;

    `clearprompt proceed -newline -type error -prompt "$message" -mask abort -default abort`;
  } # clearmsg

  sub clearlog {
    # Log a message to the log file
    my $message = shift;

    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime (time);
    $mon++;
    $year += 1900;
    $hour = "0" . $hour if $hour < 10;
    $min  = "0" . $min  if $min  < 10;
    my $date = "$mon/$mday/$year\@$hour:$min";

    my $status = open (LOGFILE, ">>$logfile");

    if (!defined $status) {
      clearmsg "Catostrophic error:\n\n
Unable to open logfile ($logfile) to log the following message:\n\n
$message";
      exit 1;
    } # if

    print LOGFILE "$me: $date: $user: $message\n";

    close LOGFILE;
  } # clearlog

  sub clearlogmsg {
    # Log message to log file then display it to user
    my $message = shift;

    clearlog $message;
    clearmsg $message;
  } # clearlogmsg

1;
