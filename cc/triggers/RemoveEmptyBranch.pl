#!/usr/bin/perl
################################################################################
#
# File:         RemoveEmptyBranch.pl,v
# Revision:     1.1.1.1
# Description:  This trigger script is remove empty branches. If a branch has
#               no elements (except the 0 element of course) after an uncheckout
#               remove it and the branch.
# Trigger Type: All element
# Operation:    Postop rmbranch, uncheckout
# Author:       Andrew@DeFaria.com
# Created:      Fri Mar 12 10:17:44 PST 2004
# Modified:     2007/05/17 07:45:48
# Language:     Perl
#
# (c) Copyright 2004, ClearSCM, Inc., all rights reserved
#
################################################################################
use strict;
use warnings;

use Carp;

my $debug        = $ENV{TRIGGER_DEBUG};
my $windows      = ($^O || $ENV{OS}) =~ /MSWin32|Windows_NT/i ? "yes" : "no";
my $SEPARATOR    = $windows eq "yes" ? "\\" : "/";
my $null         = $windows eq "yes" ? "NUL" : "/dev/null";
my $trigger_file;

sub InitDebug {
  my $tmpdir            = $ENV{TMP};
  my $trigger_debug_log = "$tmpdir/trigger_debug.log";

  open my $debugLog, '>>', $trigger_debug_log
    or croak "Unable to open $trigger_debug_log";

  return $debugLog
} # InitDebug

sub debug {
  my ($msg) = @_;

  return if !defined $debug;

  $trigger_file = InitDebug if !defined $trigger_file;

  print $trigger_file "$msg\n";
  
  return;
} # debug

# The following environment variables are set by Clearcase when this
# trigger is called
my $xname       = $ENV{CLEARCASE_XPN};
my $xn_sfx      = $ENV{CLEARCASE_XN_SFX};
my $opkind      = $ENV{CLEARCASE_OP_KIND};
my $brtype      = $ENV{CLEARCASE_BRTYPE};
my $view_type   = $ENV{CLEARCASE_VIEW_KIND};

debug "RM_EMPTY_BRANCH Trigger:";
debug "CLEARCASE_XPN            = $xname";
debug "CLEARCASE_XN_SFX         = $xn_sfx";
debug "CLEARCASE_OP_KIND        = $opkind";
debug "CLEARCASE_BRTYPE         = $brtype";
debug "CLEARCASE_VIEW_KIND      = $view_type";

$xname =~ s/\\/\//g if $windows eq "yes";

# For uncheckout, if the remaining version is not 0 then we are done -
# the most common case...
exit 0 if ($opkind eq "uncheckout" && $xname !~ m/\/0$/);

my $branch = $xname;

if ($opkind eq "uncheckout") {
  # Remove the last component
  $branch =~ s/\/[^\/]*$//;
} # if

# Don't try to remove the /main branch
exit 0 if $branch =~ m/$xn_sfx\/main$/;

# Check if there are other versions, branches, labels or checked out versions
# on this branch. If so don't do anything.
if ($view_type eq "dynamic") {
  opendir (DIR, $branch);
  my @entries = readdir (DIR);
  closedir (DIR);

  # In an empty branch there are four things: ".", "..", "0" an d"LATEST".
  # If there are more then it isn't an empty branch
  exit 0 if (scalar (@entries) != 4);
} else {
  # Snapshot views.
  my ($pname, $brpath) = split ($xn_sfx, $branch);

  # The rmbranch will not reload the element. This shows as "special
  # selection, deleted version" in snapshot views This cleans that up.
  if ($opkind eq "rmbranch") {
    system "cleartool update -log $null \"$pname\"" if ($opkind eq "rmbranch");
    exit 0; # Nothing else to do here...
  } # if

  my @vtree = `cleartool lsvtree -branch $brpath \"$pname\"`;
  my $latest;
  chomp ($latest = pop (@vtree));
  $latest =~ tr/\\/\// if $windows eq "yes";

  exit 0 unless $latest =~ m/$brpath\/0$/;
} # if

# Remove the branch!
debug "Removing empty branch $branch";
system "cleartool rmbranch -force -nc \"$branch\"";

exit 0;
