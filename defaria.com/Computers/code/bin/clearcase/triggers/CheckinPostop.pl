#!/usr/bin/perl -w
################################################################################
#
# File:         CheckinPostop.pl
# Description:  This script is run on check in post op. It will pick up the
#		bug IDs from the comment and label the elements that have just
#		been checked in.
# Author:       Andrew@DeFaria.com
# Created:      Fri Oct 26 15:32:12  2001
# Language:     Perl
# Modifications:10/22/2002: Changed to not complain about missing bug IDs if
#		the branch was main.
#		04/11/2003: Changed to support multiple bug IDs in the comment.
# (c) Copyright 2003, Andrew@DeFaria.com, all rights reserved
#
################################################################################
use strict;

BEGIN {
  # Add the appropriate path to our modules to @INC array. We use ipconfig to
  # get the current host's IP address then determine whether we are in the US
  # or China. If neither then we fallback to using T:/Triggers.
  my @ipconfig = grep (/IP Address/, `ipconfig`);
  my ($ipaddr) = ($ipconfig[0] =~ /(\d{1,3}\.\d{1,3}.\d{1,3}\.\d{1,3})/);

  # US is in the subnets of 192 and 172 while China is in the subnet of 10
  if ($ipaddr =~ /^192|^172/) {
    unshift (@INC, "//sons-clearcase/Views/official/Tools/lib");
  } elsif ($ipaddr =~ /^10/) {
    unshift (@INC, "//sons-cc/Views/official/Tools/lib");
  } else {
    die "Internal Error: Unable to find our modules!\n"
  } # if
} # BEGIN

use TriggerUtils;

# The following environment variables are set by Clearcase when this
# trigger is called
my $comment = $ENV{CLEARCASE_COMMENT};
my $branch  = $ENV{CLEARCASE_BRTYPE};
my $pname   = $ENV{CLEARCASE_PN};
my $user    = $ENV{CLEARCASE_USER};

sub ExtractBugIDs {
  my $comment = shift;

  my @fields  = split /\W/,$comment;

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

sub mklabel {
  my $label = shift;

  my $result = system "cleartool lstype lbtype:$label@\\salira > /dev/null 2>&1";

  return $result if ($result eq 0);

  $result = system "cleartool mklbtype -nc -shared -pbranch $label@\\salira";
   
  if ($result eq 0) {
    clearlog "Created label for $label";
  } else {
    clearlogmsg "Unable to mklbtype for $label (Error #: $result)";
  } # if

  return $result;
} # mklabel

foreach my $bugid (ExtractBugIDs ($comment)) {
  if (mklabel ($bugid) eq 0) {
    my $result = system "cleartool mklabel -replace $bugid \"$pname\"";

    if ($result ne 0) {
      clearlogmsg "Unable to apply label $bugid to $pname (Error #: $result)";
      exit 1;
    } else {
      clearlog "Attached label $bugid to $pname";
    } # if

    clearlog "Successful postcheckin of $pname on $branch branch with bug ID $bugid";
  } # if

} # foreach

exit 0;
