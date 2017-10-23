#!/usr/bin/perl
################################################################################
#
# File:         NotifyTrigger.pl
# Description:  This script is a generalized notify trigger. It takes one 
#		parameter, a message file. The format of this file is similar
#		to an email message. Environment variables will be substituted.
# Assumptions:	Clearprompt is in the users PATH
# Author:       Andrew@DeFaria.com
# Created:      Tue Mar 12 15:42:55  2002
# Language:     Perl
# Modifications:
#
# (c) Copyright 2002, Andrew@DeFaria.com, all rights reserved
#
################################################################################
use strict;

use Net::SMTP;

my $mailhost;

BEGIN {
  # Add the appropriate path to our modules to @INC array. We use ipconfig to
  # get the current host's IP address then determine whether we are in the US
  # or China. Also set our mail server.
  my @ipconfig = grep (/IP Address/, `ipconfig`);
  my ($ipaddr) = ($ipconfig[0] =~ /(\d{1,3}\.\d{1,3}.\d{1,3}\.\d{1,3})/);

  # US is in the subnets of 192 and 172 while China is in the subnet of 10
  if ($ipaddr =~ /^192|^172/) {
    $mailhost="sons-exch02.salira.com";
    unshift (@INC, "//sons-clearcase/Views/official/Tools/lib");
  } elsif ($ipaddr =~ /^10/) {
    $mailhost="sons-exch03.salira.com";
    unshift (@INC, "//sons-cc/Views/official/Tools/lib");
  } else {
    die "Internal Error: Unable to find our modules!\n"
  } # if
} # BEGIN

use TriggerUtils;

# This routine will replace references to environment variables. If an
# environment variable is not defined then the string <Unknown> is
# substituted.
sub ReplaceText {
  my $line = shift (@_);

  my ($var, $value);

  while ($line =~ /\$(\w+)/) {
    $line =~ /\$(\w+)/;
    $var = $1;
    if ($ENV{$var} eq "") {
      $line =~ s/\$$var/\<Unknown\>/;
    } else {
      $value = $ENV{$var};
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
open (MSG, $ARGV[0]) || error "Unable to open message file:\n\n$ARGV[0]\n\n($!)";

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
