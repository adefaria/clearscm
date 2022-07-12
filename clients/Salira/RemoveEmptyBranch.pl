#!/usr/bin/perl
################################################################################
#
# File:         RemoveEmptyBranch.pl
# Description:  This trigger script is remove empty branches. If a branch has
#               no elements (except the 0 element of course) after an uncheckout
#               or rmver, or the parent of a just-rmbranched branch is now empty,
#               remove it.
#
#		Install like this:
#
#		ct mktrtype -element -global -postop uncheckout,rmver,rmbranch \
#		-c "Remove empty branches after uncheckout, rmver, or rmbranch" \
#		-exec T:/Triggers/RemoveEmptyBranch RM_EMPTY_BRANCH
# Assumptions:	Clearprompt is in the users PATH
# Author:       Andrew@DeFaria.com
# Created:      Fri May 23 13:23:47 PDT 2003
# Language:     Perl
# Modifications:
#
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
my $xname  = $ENV{CLEARCASE_XPN};
my $opkind = $ENV{CLEARCASE_OP_KIND};
my $xn_sfx = $ENV{CLEARCASE_XN_SFX};
my $os     = $ENV{OS};
my $brtype = $ENV{CLEARCASE_BRTYPE};
#clearlog "Checking to see if the branch is empty and needs to be removed";
#clearlog "xname  = $xname";
#clearlog "opkind = $opkind";
#clearlog "xn_sfx = $xn_sfx";
#clearlog "os     = $os";

$xname =~ s/\\/\//g if $ENV{OS} eq "Windows_NT";

# For uncheckout, if the remaining version is not 0 then we are done;
exit 0 if ($opkind eq "uncheckout" && $xname !~ m/\/0$/);

#clearlog "Continuing...";
my $branch;

($branch = $xname) =~ s/\/[^\/]*$//;

#clearlog "branch = $branch; xname = $xname";

# Don't try to remove the /main branch
exit 0 if $branch =~ m/\@\@\/main$/;

# Check if there are other versions, branches, labels or checked out versions
# on this branch. If so don't do anything.
if (opendir (D, $branch)) {
  # This opendir succeeds only in a dynamic view
  #clearlog "In dynamic view!";
  my @other_stuff = readdir (D);
  closedir (D);

  # In an empty branch there are four things: ".", "..", "0" an d"LATEST".
  # If there are more then it isn't an empty branch
  exit if (scalar (@other_stuff) != 4);
} else {
  # Snapshot views.
  #clearlog "In snapshot view!";
  my ($pname, $brpath) = split ($xn_sfx, $branch);
  #clearlog "pname = $pname; brpath = $brpath";
  # rmbranch will not reload the element...
  system "cleartool update -log /dev/null \"$pname\"" if ($opkind eq "rmbranch");
  my @vtree = `cleartool lsvtree -branch $brpath \"$pname\"`;
  my $latest;
  chomp ($latest = pop (@vtree));
  $latest =~ tr/\\/\// if $os eq "Windows_NT";
  #clearlog "latest = $latest";
  exit 0 unless $latest =~ m/$brpath\/0$/;
} # if

# Remove the branch!
clearlog "After $opkind branch is empty - removing empty branch $brtype";
#clearlog "About to cleartool rmbranch -force -nc \"$branch\"";
system "cleartool rmbranch -force -nc \"$branch\"";

exit 0;
