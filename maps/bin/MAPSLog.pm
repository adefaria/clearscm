#!/usr/bin/perl
#################################################################################
#
# File:         $RCSfile: MAPSLog.pm,v $
# Revision:	$Revision: 1.1 $
# Description:  MAPS routines for logging.
# Author:       Andrew@DeFaria.com
# Created:      Fri Nov 29 14:17:21  2002
# Modified:     $Date: 2013/06/12 14:05:47 $
# Language:     perl
#
# (c) Copyright 2000-2006, Andrew@DeFaria.com, all rights reserved.
#
################################################################################
package MAPSLog;

use strict;

use FindBin;

use lib $FindBin::Bin;

use MAPSDB;
use MAPSUtil;
use vars qw (@ISA @EXPORT);
use Exporter;

@ISA = qw (Exporter);

@EXPORT = qw (
  Debug
  Error
  GetStats
  Info
  Logmsg
  countlog
  getstats
  @Types
);

our @Types = (
  'returned',
  'whitelist',
  'blacklist',
  'registered',
  'mailloop',
  'nulllist'
);

sub countlog (;$$) {
  my ($condition, $type) = @_;

  return MAPSDB::countlog $condition, $type;
} # countlog

sub nbr_msgs ($) {
  my ($sender) = @_;

  return MAPSDB::FindEmail $sender;
} # nbr_msgs

sub GetStats (;$$) {
  my ($nbr_days, $date) = @_;

  $nbr_days	||= 1;
  $date		||= Today2SQLDatetime

  my %dates;

  while ($nbr_days > 0) {
    my $ymd = substr $date, 0, 10;
    my $sod = $ymd . ' 00:00:00';
    my $eod = $ymd . ' 23:59:59';

    my %stats;

    foreach (@Types) {
      my $condition = "log.type=\'$_\' and (log.timestamp > \'$sod\' and log.timestamp < \'$eod\')";
      $stats{$_} = countlog $condition, $_;
    } # foreach

    $dates{$ymd} = \%stats;

    $date = SubtractDays $date, 1;
    $nbr_days--;
  } # while

  return %dates
} # GetStats

sub Logmsg ($$$) {
  my ($type, $sender, $msg) = @_;

  AddLog $type, $sender, $msg;
} # logmsg

sub Debug ($) {
  my ($msg) = @_;

  Logmsg 'debug', '', $msg;
} # Debug

sub Error ($) {
  my ($msg) = @_;

  Logmsg 'error', '', $msg;
} # Error

sub Info ($) {
  my ($msg) = @_;

  Logmsg 'info', '', $msg;
} # info

1;
