#!/usr/bin/perl
################################################################################
#
# File:         Permissions.pl
# Description:  This trigger script implements additional permissions checking.
#		The general idea is to open up permissions at the group level
#		and to control who gets to checkout elements at the folder
#		level. You do this by making an element named
#		$permissions_element which contains group names of which
#		groups have "checkout" permissions in that folder downward.
# Author:       Andrew@DeFaria.com
# Created:      Mon Jul 19 10:54:01 PDT 2004
# Language:     Perl
# Modifications:
#
# (c) Copyright 2004, Andrew@DeFaria.com, all rights reserved
#
################################################################################
use strict;
use warnings;
use File::Spec;

# This will be set in the BEGIN block but by putting them here the become
# available for the whole script.
my (
  $abs_path,
  $lib_path,
  $log_path,
  $me,
  $triggers_path
);

BEGIN {
  # Extract relative path and basename from script name.
  $0 =~ /(.*)[\/\\](.*)/;

  $abs_path	= (!defined $1) ? "." : File::Spec->rel2abs ($1);
  $me		= (!defined $2) ? $0  : $2;

  # Setup paths
  $lib_path		= "$abs_path/../lib";
  $log_path		= "$abs_path/../log";
  $triggers_path	= "$abs_path/../triggers";

  # Add the appropriate path to our modules to @INC array.
  unshift (@INC, "$lib_path");
} # BEGIN

use TriggerUtils;

# Name of permissions element to search for
my $permissions_element = ".perms";

# Trigger environment variables used
my $pname = $ENV{CLEARCASE_PN};
my $user  = $ENV{CLEARCASE_USER};
my $vob   = $ENV{CLEARCASE_VOB_PN};

sub ParentDir {
  my $path = shift;

  $path =~ m/(.*)[\/\\].*/;

  return $1;
} # ParentDir

# Returns the current group owner of the vob. This is the first group listed, not the'
# "Additional groups".
sub GetGroupOwner {
  my $vob = shift;

  my @output = `cleartool describe vob:$vob 2>&1`;

  foreach (@output) {
    chomp; chop if /\r/;
    if (/group AMERIQUEST\\(.*)/) {
      return $1;
    } # if
  } # foreach

  return "Unknown";
} # GetGroupOwner

# Returns the primary group using creds
sub GetPrimaryGroup {
  my @output = `"C:\\Program Files\\Rational\\Clearcase\\etc\\utils\\creds.exe" 2>&1`;

  foreach (@output) {
    chomp; chop if /\r/;
    if (/Primary group: AMERIQUEST\\(\S*).*/) {
      return $1;
    } # if
  } # foreach

  return "Domain Users";
} # GetPrimaryGroup

# Parsed the $permissions_element returning a list of permitted groups.
sub Parse {
  my $permissions_element = shift;

  open PERMISSIONS_ELEMENT, $permissions_element
    or clearlogmsg "Unable to open $permissions_element - $!\n", exit 1;

  my @lines = <PERMISSIONS_ELEMENT>;
  my @tidy_lines;

  foreach (@lines) {
    chomp; chop if /\r/;
    next if $_ eq "";
    push @tidy_lines, $_;
  } # foreach

  return @tidy_lines;
} # Parse

# Compare the two string arrays and return 1 if there are any matches.
sub IsAMember {
  my $set1	= shift;
  my $set2	= shift;

  # Convert two array references to actual arrays
  my @set1	= @{$set1};
  my @set2	= @{$set2};

  foreach my $item1 (@set1) {
    foreach my $item2 (@set2) {
      return 1 if $item1 eq $item2;
    } # foreach
  } # foreach

  return 0;
} # IsAMember

# Returns an array of (AMERIQUEST) group names for the user using creds.
sub GetUserGroups {
  my @output = `"C:\\Program Files\\Rational\\Clearcase\\etc\\utils\\creds.exe" 2>&1`;
  my @groups;
  my $found = 0;

  foreach (@output) {
    chomp; chop if /\r/;

    # We should first see the Primary Grou
    if (/Primary group: AMERIQUEST\\(.*) \(/) {
      push @groups, $1;
    } # if

    # When we hit the "Groups:" line then what follows is a list of groups
    if (/^Groups:/) {
      $found = 1;
      next
    } # if

    # Select only those that are specifically in the AMERIQUEST domain
    if ($found eq 1 and /\s*AMERIQUEST\\(.*) \(/) {
      push @groups, $1;
    } # if
  } # foreach

  return @groups
} # GetUserGroups

# This routine will check to see if any of the user's groups are in the
# $permissions_element(s) by recursing up the directory looking for 
# $permissions_element(s) then comparing those groups to the user's groups.
sub Permitted {
  my $vob		= shift;
  my $pname		= shift;
  my @user_groups	= @_;

  # User may be attemptign to Add to Source Control in the current
  # directory and have permissions to do so. When Add to Source
  # Control runs it checks out the parent directory. The user
  # typically will NOT have permissions to check out the parent
  # directory! So for directory elements first check if the user is
  # permitted as per $pname/$permissions_element BEFORE traversing up
  # to the parent directory.
  my @permitted_groups;
  my $element_type = $ENV{CLEARCASE_ELTYPE};

  if ($element_type =~ /directory/i) {
    if (-e "$pname/$permissions_element") {
      @permitted_groups = Parse ("$pname/$permissions_element");
      return 1 if (IsAMember (\@user_groups, \@permitted_groups));
    } # if
  } # if
	
  # Get parent directory
  $pname = ParentDir $pname;

  # Exhausted $pname
  return 0 if !defined $pname;

  if (-e "$pname/$permissions_element") {
    @permitted_groups = Parse ("$pname/$permissions_element");
    return 1 if (IsAMember (\@user_groups, \@permitted_groups));
  } # if

  # Recurse up to parent directory
  return Permitted ($vob, $pname, @user_groups);
} # Permitted

# Main
my $vob_group_owner	= GetGroupOwner $vob;
my $group		= GetPrimaryGroup;
my @user_groups		= GetUserGroups;
my $msg;

if ($vob_group_owner eq $group) {
  # Vob group openers are always permitted
  exit 0;
} elsif ($pname =~ m/$permissions_element$/) {
  # User trying to check out the $permissions_element!
  $msg .= "Only members of the vob's initial group owners,\\n";
  $msg .= "$vob_group_owner, may checkout the $permissions_element element!";
  clearmsg $msg;
  exit 1;
} elsif (Permitted ($vob, $pname, @user_groups)) {
  exit 0;
} else {
  $msg .= "The userid of $user is not a member of a group who is\\n";
  $msg .= "permitted to check out elements from the folder\\n";
  $msg .= ParentDir $pname;
  $msg .= " of the $vob vob.";
  clearmsg $msg;
  exit 1;
} # if
