#!/usr/bin/perl -w
#################################################################################
#
# File:         ccverify.pl
# Description:  Verify that Rational Clearcase was installed correctly
# Author:       Andrew@DeFaria.com
# Created:      Mon Mar 15 08:48:24 PST 2004
# Language:     None
#
# (c) Copyright 2004, Andrew@DeFaria.com, all rights reserved.
#
################################################################################
use strict;

my $ccverify	= "1.0";
my $logpath	= "\\\\rtnlprod02\\viewstore\\PMO\\CM_TOOLS\\log";
my $hostname	= `hostname`; chomp $hostname;
my $logfile	= "$logpath\\$hostname.log";
my $status	= 0;
my $tag		= "ccverify";

open LOGFILE, ">>$logfile"
  or die "Unable to open logfile: $logfile - $!\n";

sub logmsg {
  my $message = shift;

  print "$message\n";
  print LOGFILE "$message\n";
} # logmsg

sub mktag {
  my $tag	= shift;

  my $status	= system "cleartool lsvob \\$tag > NUL 2>&1";

  if ($status ne 0) {
    return system "cleartool mktag -vob -tag \\$tag \\\\rtnlprod01\\vobstore\\$tag.vbs > NUL 2>&1";
  } # if
} # mktag

sub rmtag {
  my $tag = shift;

  return system "cleartool rmtag -vob \\$tag > NUL 2>&1";
} # rmtag

sub rmview {
  my $tag = shift;

  return system "cleartool rmview -force -tag $tag > NUL 2>&1";
} # rmview

sub mkview {
  my $tag = shift;

  my $status = system "cleartool lsview -short $tag > NUL 2>&1";

  if ($status ne 0) {
    return system "cleartool mkview -tag $tag -stgloc -auto > NUL 2>&1";
  } else {
    rmview $tag;
    return system "cleartool mkview -tag $tag -stgloc -auto > NUL 2>&1";
  } # if
} # mkview

sub mount_vob {
  my $tag = shift;

  mktag $tag;

  return system "cleartool mount \\$tag > NUL 2>&1";
} # mount_vob

sub umount_vob {
  my $tag = shift;

  my $status =  system "cleartool umount \\$tag > NUL 2>&1";

  rmtag $tag;

  return $status;
} # umount_vob

my $version		= `cleartool -ver`;
my $primary_group	= $ENV {CLEARCASE_PRIMARY_GROUP};

my @hostinfo = `cleartool hostinfo -long`;
my $region = "Not Set";

foreach (@hostinfo) {
  chomp;
  if (/\s*Registry region:\s*(\S*)/) {
    $region = $1;
    last;
  } # if
} # foreach

logmsg "CCVerify Version $ccverify";
logmsg "Verifying Clearcase installation on $hostname (" . scalar (localtime) . ")\n";
logmsg "Clearcase Version Information\n";
logmsg "$version\n";

if (!defined $primary_group) {
  $primary_group = "<not set>";
  $status++;
} # if

logmsg "Clearcase Primary Group:\t$primary_group";
logmsg "Clearcase Region:\t\t$region\n";

if (mkview ($tag) eq 0) {
  logmsg "Created a dynamic view named $tag";
} else {
  $status++;
  logmsg "Unable to create the $tag dynamic view!";
} # if

if (mount_vob ($tag) eq 0) {
  logmsg "Mounted the vob \\$tag";
} else {
  $status++;
  logmsg "Unable to mount the vob \\$tag";
} # if

if (umount_vob ($tag) eq 0) {
  logmsg "Unmounted the vob \\$tag";
} else {
  $status++;
  logmsg "Unable to unmount vob \\$tag";
} # if

if (rmview ($tag) eq 0) {
  logmsg "Removed view $tag";
} else {
  $status++;
  logmsg "Unable to remove view $tag";
} # if

if ($status eq 0) {
  logmsg
"\n--------------------------------------------
Clearcase installed and functioning properly
--------------------------------------------\n";
} else {
  logmsg
"\n------------------------------------------------
Clearcase NOT installed and functioning properly
------------------------------------------------\n";
} # if

exit $status;
