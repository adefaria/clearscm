#!/usr/bin/perl -w
#################################################################################
#
# File:         tagit
# Description:  Script to tag views or vobs into the current region. The main
#		motivation for this script is to be able to tag things quickly
#		and easily. As such we employ heuristics to find these objects.
# Author:       Andrew@DeFaria.com
# Created:      Fri Apr  9 12:19:04 PDT 2004
# Language:     Perl
#
# (c) Copyright 2004, Andrew@DeFaria.com, all rights reserved.
#
################################################################################
use strict;
use File::Spec;

my $me;

BEGIN {
  # Extract relative path and basename from script name.
  $0  =~ /.*[\/\\](.*)/;
  $me = (!defined $1) ? $0  : $1;
} # BEGIN

# Check to see if we are running on Windows
my $windows	= ($^O =~ /MSWin/) ? "yes" : "no";
my $null	= $windows eq "yes" ? "NUL" : "/dev/null";
my $backslashes	= $windows eq "yes" ? "\\"  : "\\\\";

sub Usage {
  print "Usage $me: [[ -view ] <view_tag> ] [ -vob <vob_tag> ]\n";
  print "\nWhere:\n";
  print "\t-view\tView tag to tag in current region\n";
  print "\t-vob\tVob tag to tag in current region\n";
  exit 1;
} # Usage

sub GetCurrentRegion {
  my @lines = `cleartool hostinfo -l`;

  foreach (@lines) {
    chomp; chop $_ if /\r/;

    if (/Registry region: (\S+)/) {
      return $1;
    } # if
  } # foreach

  return undef;
} # GetCurrentRegion

my $current_region = GetCurrentRegion;
my @regions = `cleartool lsregion`;

sub FindView {
  my $view_tag = shift;

  foreach (@regions) {
    chomp; chop if /\r/;

    my $output = `cleartool lsview -region $_ $view_tag 2> $null`;
    chomp $output; chop $output if /\r/;

    if ($output =~ /$view_tag\s*(.*)/) {
      my $view_storage = $1;
      $view_storage =~ tr /\\/\/\//;
      return ($view_storage, $_);
    } # if
  } # foreach

  return;
} # FindView

sub FindVob {
  my $vob_tag = shift;

  foreach (@regions) {
    chomp; chop if /\r/;

    my $output = `cleartool lsvob -region $_ $backslashes$vob_tag 2> $null`;
    chomp $output; chop $output if /\r/;

    if ($output =~ /$vob_tag\s*(\S*)/) {
      my $vob_storage = $1;
      $vob_storage =~ tr /\\/\/\//;
      return ($vob_storage, $_);
    } # if
  } # foreach

  return;
} # FindVob

sub MkViewTag {
  my $view_tag		= shift;
  my $view_storage	= shift;

  # Check to see if view tag already exists
  if (!system "cleartool lsview $view_tag > $null 2>&1") {
    print "$view_tag already exists in $current_region\n";
    return 0;
  } else {
    if (system "cleartool mktag -view -tag $view_tag $view_storage") {
      die "Unable to make view tag: $view_tag in $current_region\n";
    } # if
    return 1;
  } # if
} # MkViewTag

sub MkVobTag {
  my $vob_tag		= shift;
  my $vob_storage	= shift;

  # Check to see if vob tag already exists
  if (!system "cleartool lsvob $backslashes$vob_tag > $null 2>&1") {
    print "$vob_tag already exists in $current_region\n";
    return 1;
  } else {
    print "cleartool mktag -vob -tag $backslashes$vob_tag $vob_storage\n";
    if (system "cleartool mktag -vob -tag $backslashes$vob_tag $vob_storage") {
      die "Unable to make vob tag: $vob_tag in $current_region\n";
    } # if
    return 0;
  } # if
} # MkVobTag

my $view_tag;
my $vob_tag;

# Get parms
while ($#ARGV >= 0) {
  if ($ARGV [0] eq "-u" or $ARGV [0] eq "-usage") {
    Usage;
  } # if

  if ($ARGV [0] eq "-vob") {
    shift;
    $vob_tag = $ARGV [0];
    # Script all backslashes - we'll re-add them when needed...
    $vob_tag =~ s/\\//;
    shift;
    next;
  } # if

  if ($ARGV [0] eq "-view") {
    shift;
    $view_tag = $ARGV [0];
    next;
  } # if
} # while

if (!(defined $view_tag or defined $vob_tag)) {
  Usage "Must specify a view or a vob to tag!";
} # if

if (defined $view_tag) {
  my ($view_storage, $view_region) = FindView $view_tag;

  die "Unable to find view $view_tag in any region!\n"	if !defined $view_region;
  die "Unable to find storage area for $view_tag\n"	if !defined $view_storage;

  if ($view_region eq $current_region) {
    print "$view_tag already exists in $current_region\n";
  } else {
    print "$view_tag, from $view_region region, added to $current_region region\n" if MkViewTag $view_tag, $view_storage;;
  } # if
} # if

if (defined $vob_tag) {
  my ($vob_storage, $vob_region) = FindVob $vob_tag;

  die "Unable to find vob $vob_tag in any region!\n"	if !defined $vob_region;
  die "Unable to find storage area for $vob_tag\n"	if !defined $vob_storage;

  if ($vob_region eq $current_region) {
    print "$vob_tag already exists in $current_region\n";
  } else {
    print "$vob_tag, from $vob_region, added to $current_region region\n" if MkVobTag $vob_tag, $vob_storage;;
  } # if
} # if

exit 0;

