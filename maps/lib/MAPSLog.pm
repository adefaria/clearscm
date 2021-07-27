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

use base qw(Exporter);

use MAPS;

use DateUtils;
use Utils;

our @ISA = qw(Exporter);
our @EXPORT = qw (
  Debug
  Error
  GetStats
  Info
  Logmsg
  @Types
);

our @Types = (
  'nulllist',
  'returned',
  'whitelist',
  'blacklist',
  'registered',
  'mailloop',
);

sub nbr_msgs($) {
  my ($sender) = @_;

  return FindEmail($sender);
} # nbr_msgs

sub GetStats(%) {
  my (%params) = @_;

  CheckParms(['userid'], \%params);

  $params{days} ||= 1;
  $params{date} ||= Today2SQLDatetime;

  my %dates;

  while ($params{days} > 0) {
    my $ymd = substr $params{date}, 0, 10;
    my $sod = $ymd . ' 00:00:00';
    my $eod = $ymd . ' 23:59:59';

    my %stats;

    for (@Types) {
      my $condition = "type=\'$_\' and (timestamp > \'$sod\' and timestamp < \'$eod\')";

      $stats{$_} = MAPS::CountLogDistinct(
        userid     => $params{userid},
        column     => 'sender',
        additional => $condition,
      );
    } # for

    $dates{$ymd} = \%stats;

    $params{date} = SubtractDays $params{date}, 1;
    $params{days}--;
  } # while

  return %dates
} # GetStats

sub Logmsg(%) {
  my(%params) = @_;

  CheckParms(['userid', 'type', 'message'], \%params);

  # TODO Why do I need to qualify this?
  return MAPS::AddLog(%params);
} # logmsg

sub Debug(%) {
  my (%params) = @_;

  return Logmsg(
    userid  => $params{userid},
    type    => 'debug',
    message => $params{message});
} # Debug

sub Error(%) {
  my (%params) = @_;

CheckParms(['userid', 'message'], \%params);

  return Logmsg(
    userid  => $params{userid},
    type    => 'error',
    message => $params{message});
  } # Error

sub Info(%) {
  my (%params) = @_;

  return Logmsg(
    userid  => $params{userid},
    type    => 'info',
    message => $params{message});
} # info

1;
