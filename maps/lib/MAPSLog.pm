#!/usr/bin/perl
#################################################################################
#
# File:         $RCSfile: MAPSLog.pm,v $
# Revision:     $Revision: 1.1 $
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
use warnings;

use FindBin;

use MAPS;
use MAPSUtil;

use vars qw(@ISA @EXPORT);
use Exporter;

@ISA = qw (Exporter);

@EXPORT = qw (
  Debug
  Error
  GetStats
  Info
  Logmsg
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

sub nbr_msgs($) {
  my ($sender) = @_;

  return FindEmail($sender);
} # nbr_msgs

sub GetStats(;$$) {
  my ($nbr_days, $date) = @_;

  $nbr_days ||= 1;
  $date     ||= Today2SQLDatetime();

  my %dates;

  while ($nbr_days > 0) {
    my $ymd = substr $date, 0, 10;
    my $sod = $ymd . ' 00:00:00';
    my $eod = $ymd . ' 23:59:59';

    my %stats;

    for (@Types) {
      my $condition = "type=\'$_\' and (timestamp > \'$sod\' and timestamp < \'$eod\')";

      # Not sure why I need to qualify countlog
      $stats{$_} = MAPS::countlog($condition);
    } # for

    $dates{$ymd} = \%stats;

    $date = SubtractDays $date, 1;
    $nbr_days--;
  } # while

  return %dates
} # GetStats

sub Logmsg($$$) {
  my ($type, $sender, $msg) = @_;

  # Todo: Why do I need to specify MAPS:: here?
  MAPS::AddLog($type, $sender, $msg);

  return;
} # logmsg

sub Debug($) {
  my ($msg) = @_;

  Logmsg('debug', '', $msg);

  return;
} # Debug

sub Error($) {
  my ($msg) = @_;

  Logmsg('error', '', $msg);

  return;
} # Error

sub Info($) {
  my ($msg) = @_;

  Logmsg('info', '', $msg);

  return;
} # info

1;
