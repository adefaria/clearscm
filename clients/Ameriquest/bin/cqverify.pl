#!/usr/bin/perl -w
#################################################################################
#
# File:         cqverify.pl
# Description:  Verify that Rational Clearquest was installed correctly
# Author:       Andrew@DeFaria.com
# Created:      Mon Mar 15 08:48:24 PST 2004
# Language:     Perl
#
################################################################################
use strict;
use CQPerlExt;

my $cqverify	= "1.0";
my $logpath	= "\\\\rtnlprod02\\viewstore\\PMO\\CM_TOOLS\\log";
my $hostname	= `hostname`; chomp $hostname;
my $logfile	= "$logpath\\$hostname.log";
my $status	= 0;

open LOGFILE, ">>$logfile"
  or die "Unable to open logfile: $logfile - $!\n";

sub logmsg {
  my $message = shift;

  print "$message\n";
  print LOGFILE "$message\n";
} # logmsg

# Log in to CQ as guest
logmsg "CQVerify Version $cqverify";
logmsg "Verifying Clearquest/TUP installation on $hostname (" . scalar (localtime) . ")";

my $CQsession = CQPerlExt::CQSession_Build ()
  or logmsg "Unable to establish CQSession", die;

my ($queryDef, $resultSet, $result);
eval {
  $CQsession->UserLogon ("guest", "guest", "AMQST", "AMQST");
  # Construct a CQ query that will return the ID of the first CQ record
  $queryDef = $CQsession->BuildQuery ("defect");
  $queryDef->BuildField ("id");
  $resultSet = $CQsession->BuildResultSet ($queryDef);
  $resultSet->Execute;
  $resultSet->GetNumberOfColumns;
  $status = $resultSet->MoveNext;
  $result = $resultSet->GetColumnValue ("1");
  CQSession::Unbuild ($CQsession);
};

if ($@) {
  logmsg $@;
  logmsg
"-----------------------------------------------------
Clearquest/TUP NOT installed and functioning properly
-----------------------------------------------------";
  exit 1;
} else {
  if ($result =~ m/^AMQST/) {
    logmsg "Clearquest query succeeded";
    logmsg
"-------------------------------------------------
Clearquest/TUP installed and functioning properly
-------------------------------------------------";
    exit 0;
  } else {
    logmsg "Value returned not was not expected: $result";
    logmsg
"-----------------------------------------------------
Clearquest/TUP NOT installed and functioning properly
-----------------------------------------------------";
    exit 1;
  } # if
} # if
