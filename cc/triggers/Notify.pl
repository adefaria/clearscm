#!/usr/bin/perl
################################################################################
#
# File:         Notify.pl
# Description:  This script is a generalized notify trigger. It takes one
#		parameter, a message file. The format of this file is similar
#		to an email message. Environment variables will be substituted.
#
#		This trigger is typically added, perhaps multiple times with
#		different message files, then attached to elements in the vob
#		as needed. Make the trigger with:
#
#			cleartool mktrtype -element -postop checkin \
#			  -c "<comment>" \
#			  -exec "<perl> <path_to_trigger>/Notify.pl \
#				<msg file>" <TRIGGER_NAME>
#
# Assumptions:	Clearprompt is in the users PATH
# Author:       Andrew@DeFaria.com
# Created:      Tue Mar 12 15:42:55  2002
# Language:     Perl
# Modifications:
#
# (c) Copyright 2004, Andrew@DeFaria.com, all rights reserved
#
################################################################################
use strict;

use File::Spec;
use Net::SMTP;

my $mailhost = "smtphost";

# This will be set in the BEGIN block but by putting them here the become
# available for the whole script.
my (
  $abs_path,
  $lib_path,
  $me,
  $msgfiles_path,
  $triggers_path
);

BEGIN {
  # Extract relative path and basename from script name.
  $0 =~ /(.*)[\/\\](.*)/;

  $abs_path	= (!defined $1) ? "." : File::Spec->rel2abs ($1);
  $me		= (!defined $2) ? $0  : $2;

  # Setup paths
  $lib_path		= "$abs_path/../lib";
  $triggers_path	= "$abs_path/../triggers";
  $msgfiles_path	= "$abs_path/../msgs";

  # Add the appropriate path to our modules to @INC array.
  unshift (@INC, "$lib_path");
} # BEGIN

use TriggerUtils;

# This routine will replace references to environment variables. If an
# environment variable is not defined then the string <Unknown> is
# substituted.
sub ReplaceText {
  my $line = shift;

  while ($line =~ /\$(\w+)/) {
    my $var = $1;
    if ($ENV{$var} eq "") {
      $line =~ s/\$$var/\<Unknown\>/;
    } else {
      my $value = $ENV{$var};
      $value =~ s/\\/\//g;
      $line =~ s/\$$var/$value/;
    } # if
  } # while

  return $line;
} # ReplaceText

sub error {
  my $message = shift;

  clearlogmsg $message;

  exit 1;
} # error

# First open the message file. If we can't then there's a problem, die!
my $msgfile = "$msgfiles_path/$ARGV[0]";
open MSG, $msgfile
  or error "Unable to open message file:\n\n$msgfile\n\n($!)";

# Suck in file
my @lines = <MSG>;

# Connect to mail server
my $smtp = Net::SMTP->new ($mailhost);

error "Unable to open connection to mail host: $mailhost" if $smtp == undef;

# Compose message
my $data_sent = "F";
my $from_seen = "F";
my $to_seen   = "F";
my ($line, $from, $to, @addresses);

foreach $line (@lines) {
  next if $line =~ /^\#/;
  next if $line =~ /--/;

  $line = ReplaceText $line;

  if ($line =~ /^From:\s+/) {
    $_ = $line;
    $from = $line;
    s/^From:\s+//;
    $smtp->mail ($_);
    $from_seen = "T";
    next;
  } # if

  if ($line =~ /^To:\s+/) {
    $_ = $line;
    $to = $line;
    s/^To:\s+//;
    @addresses = split (/,|;| /);
    $to_seen = "T";
    foreach (@addresses) {
      next if ($_ eq "");
      $smtp->to ($_);
    } # foreach
    next;
  } # if

  if ($data_sent eq "F") {
    $smtp->data ();
    $smtp->datasend ($from);
    $smtp->datasend ($to);
    $data_sent = "T";
  } # if

  if ($from_seen eq "T" && $to_seen eq "T" && $data_sent eq "T") {
    $smtp->datasend ($line);
  } else {
    clearlogmsg "Message file ($ARGV[0]) missing From and/or To!";
    exit 1;
  } # if
} # foreach

$smtp->dataend ();
$smtp->quit;

exit 0;
