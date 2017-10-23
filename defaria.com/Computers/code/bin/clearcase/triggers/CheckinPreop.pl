#!/usr/bin/perl
################################################################################
#
# File:         CheckinPreop.pl
# Description:  This trigger script is run when the user is attempting to
#		checkin. Several checks are performed on the check in comment.
#		The comment should contain the bug ID, which we will later used
#		to label this element checkin (See CheckinPostop.pl). We will
#		also check to insure the bug ID is valid in Clearquest and that
#		the bug is in the proper state.
#
#		If the check in is on the "main" or "trial" branch then we will
#		consult a file to insure that the bug ID is listed. This is an
#		additional method for limiting checkins.
# Assumptions:	Clearprompt is in the users PATH
# Author:       Andrew@DeFaria.com
# Created:      Fri Oct 26 15:32:12  2001
# Language:     Perl
# Modifications:6/25/2002: Added check to see if a bug ID label exists and it
#		is locked. If so then that's an indication that we should not
#		allow the checkin.
#		6/20/2002: Added interface to cqd to verify that the bug exists
#		in Clearquest, is of a certain state and has an owner
#		5/15/2002: Added tests so that bug IDs must exist in
#		mainbugs.txt or	trialbugs.txt for the main and trial branches.
#		5/17/2002: Exempted EMS code.
#		5/31/2002: Exempted hardware code.
#		10/22/2002: Changed to allow checkins to main branch with no
#		bug IDs. Removed $mainbugs.
#		11/20/2002: It was determined to relax restrictions of checkins
#		for non 1.0 branches such that bug ID's are not required, in fact
#		they are not allowed.
#		04/11/2003: Added support for multiple bug IDs in the comment
#		05/18/2003: Changed code to only check for bug IDs in comments
#		for check ins on certain branches.
#
# (c) Copyright 2003, Andrew@DeFaria.com, all rights reserved
#
################################################################################
use strict;

my $site;

BEGIN {
  # Add the appropriate path to our modules to @INC array. We use ipconfig to
  # get the current host's IP address then determine whether we are in the US
  # or China.
  my @ipconfig = grep (/IP Address/, `ipconfig`);
  my ($ipaddr) = ($ipconfig[0] =~ /(\d{1,3}\.\d{1,3}.\d{1,3}\.\d{1,3})/);

  # US is in the subnets of 192 and 172 while China is in the subnet of 10
  if ($ipaddr =~ /^192|^172/) {
    $site = "US";
    unshift (@INC, "//sons-clearcase/Views/official/Tools/lib");
  } elsif ($ipaddr =~ /^10/) {
    $site = "CN";
    unshift (@INC, "//sons-cc/Views/official/Tools/lib");
  } else {
    die "Internal Error: Unable to find our modules!\n"
  } # if
} # BEGIN

use TriggerUtils;
use cqc;

%cqc::fields;

# The following environment variables are set by Clearcase when this
# trigger is called
my $comment = $ENV{CLEARCASE_COMMENT};
my $branch  = $ENV{CLEARCASE_BRTYPE};
my $pname   = $ENV{CLEARCASE_PN};

# Which vob we will look up labels in
my $vob = "salira";

my $bugid;

sub ExtractBugID {
  my $comment = shift;

  my @fields  = split (/\W/,$comment);
  my $bugid   = "unknown";

  foreach (@fields) {
    if (/BUGS2[0-9]{8}/) {
      $bugid = $_;
      last;
    } # if
  } # foreach

  return $bugid;
} # ExtractBugID

sub ExtractBugIDs {
  my $comment = shift;

  my @fields  = split (/\W/,$comment);

  # Use associative array to insure uniqueness
  my %bugids;
  # Return unique array
  my @bugids;

  foreach (@fields) {
    if (/BUGS2[0-9]{8}/) {
      $bugids{$_} = $_;
    } # if
  } # foreach

  foreach (keys %bugids) {
    push @bugids, $_;
  }

  return @bugids;
} # ExtractBugIDs

sub BugOnList {
  my $bugid       = shift;
  my $branch	  = shift;

  my $found_bugid = 0;
  my $bug         = "unknown";

  # Excempt EMS code
  return 1 if $pname =~ /salira\\ems/i;

  # Excempt Hardware code
  return 1 if $pname =~ /salira\\hardware/i;

  # Exempt bug ID 2912
  return 1 if $bugid eq "BUGS200002912";

  # Exempt bug ID 3035
  return 1 if $bugid eq "BUGS200003035";

  my $filename;

  if ($site eq "US") {
    $filename = "//sons-clearcase/Views/official/Tools/bin/clearcase/triggers/data/$branch.lst";
  } elsif ($site eq "CN") {
   $filename = "//sons-cc/Views/official/Tools/bin/clearcase/triggers/data/$branch.lst";
 } else {
   die "Internal Error: Site not set properly! ($site)\n";
 } # if

  if (-f $filename) {
    open (FILE, $filename) || die "Can't open $filename!\n";

    while (<FILE>) {
      $bug = ExtractBugID $_;
      next if ($bug eq "unknown");
      if ($bug eq $bugid) {
	$found_bugid = 1;
	last;
      } # if
    } # while

    close (FILE);
  } else {
    clearlog "Skipping check because $filename does not exist!";
    # Since there is no file list to check return that the bug id was found
    $found_bugid = 1;
  } # if

  return $found_bugid;
} # BugOnList

sub LabelLocked {
  # 04/28/2003: Oddity! All of a sudden this subroutine broke! I don't know
  # why but even though we used to cd to the official view and issue our
  # cleartool lslock command we started getting "Unable to determine VOB
  # from pname" errors. Weird! Anyways we have changed to use the @<vob
  # selector> syntax instead. This means we must now specify the vob
  # specifically. Fortunately we only have one vob to worry about at this
  # time. On the plus side we no longer need to rely on the "official" view.
  my $bugid = shift;

  my $output = `cleartool lslock -short lbtype:$bugid@\\$vob 2>&1`;

  if ($? == 0) {
    return $output;
  } else {
    return 0;
  } # if
} # LabelLocked

sub CheckComment {
  my $comment = shift;
  my $branch  = shift;

  my @valid_branches = (
    "main",
    "rel_1.0",
    "rel_2.0",
    "rel_2.1",
    "rel_2.2",
    "rel_2.3",
    "china_1.0",
    "china_2.0",
    "china_2.1",
    "china_2.2",
    "china_2.3",
    "2.0_ga"
  );

  if ($comment eq "") {
    clearlogmsg "You need to specify checkin comments";
    return 1;
  } # if

  if (length $comment <= 4) {
    clearlogmsg "The comment, '$comment' is too short!";
    return 1;
  } # if

  if ($comment !~ m/.*BUGS2[0-9]{8}.*/) {
    # Bug ID's are only required on certain branches
    my $found = 0;

    foreach (@valid_branches) {
      if ($branch eq $_) {
	$found = 1;
	last;
      } # if
    } # foreach

    if ($found == 1) {
      clearlogmsg "Could not find bug ID in comment! This is required for the $branch branch";
      return 1;
    } # if
  } # if

  return 0;
} # CheckComment

sub CheckBugIDs {
  my @bugs = @_;

  my $result;

  foreach my $bugid (@bugs) {
    # Check if label is locked
    if (LabelLocked ($bugid)) {
      clearlog "Bug id $bugid is locked!";
      clearmsg "Bug id $bugid is locked!\nSee your Clearcase Admin to unlock it";
      return 1;
    } # if

    # Get Clearquest information
    $result = cqc::GetBugRecord ($bugid, %fields);

    if ($result == 0) {
      # Make sure bug is owned
      if ($fields {owner} eq "<Unspecified>") {
	clearlogmsg "No owner specified in Clearquest for bug ID $bugid.";
	return 1;
      } # if

      # Make sure bug is in the correct state
      if ($fields {state} ne "Assigned" and $fields {state} ne "Resolved") {
	clearlogmsg "Bug ID $bugid is in the wrong state. It is in the " . $fields {state}. " state but should be in Assigned or Resolved state.";
	return 1;
      } # if
    } elsif ($result > 0) {
      clearlogmsg "Bug ID $bugid is not in Clearquest.";
      return 1;
    } else {
      clearlogmsg "Clearquest Daemon (cqd) is not running!
Please contact the Clearquest Administrator.";
      return 1;
    } # if

    # Check if bug is on a branch list file
    if (! BugOnList ($bugid, $branch)) {
      clearlog "Bug ID $bugid is not on the list of acceptable bugs for the $branch branch!";
      clearmsg "Bug ID $bugid is not on the list\nof acceptable bugs for the $branch branch!";
      return 1;
    } # if
  } # foreach
} # CheckBugIDs

clearlog "Checkin checks started for $pname on $branch branch";

if (CheckComment ($comment, $branch)) {
  exit 1;
} elsif (CheckBugIDs (ExtractBugIDs $comment)) {
  exit 1;
} # if

clearlog "Successful precheckin of $pname on $branch branch with bug ID $bugid";

exit 0;
