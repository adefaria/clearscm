#!/usr/bin/perl -w
################################################################################
#
# File:         EvilTwin.pl,v
# Revision:     1.1.1.1
# Description:  This trigger checks for evil twins. And evil twin can occur when
#               a user checks in an element which matches an element name on
#               some other branch of the directory that is invisible in the
#               current view.
# Trigger Type: All element
# Operation:    Preop lnname
# Author:       Andrew@DeFaria.com
# Created:      May 24, 2004
# Modified:     2007/05/17 07:45:48
# Language:     Perl
#
# (c) Copyright 2004, Andrew@DeFaria.com, all rights reserved
#
################################################################################
use strict;
use File::Basename;

# Ensure that the view-private file will get named back on rejection.
BEGIN {
  END {
    rename "$ENV{CLEARCASE_PN}.mkelem", "$ENV{CLEARCASE_PN}"
      if $? && ! -e "ENV{CLEARCASE_PN}" && -e "$ENV{CLEARCASE_PN}.mkelem";
  } # END
} # BEGIN

# Check to see if we are running on Windows
my $windows     = ($^O =~ /MSWin/) ? "yes" : "no";

# Delimeters and null are different on the different OSes
my $dir_delim   = $windows eq "yes" ? "\\"   : "/";
my $dir_delim_e = $windows eq "yes" ? "\\\\" : "\/";
my $null        = $windows eq "yes" ? "NUL"  : "/dev/null";

# This is called only if an evil twin is detected. It simply writes
# out information about the evil twin to a log file. Eventually we
# will turn this off.
sub Log {
  my $msg = shift;

  my $time = localtime;
  my $user = $ENV {CLEARCASE_USER};
  my $logpath = $windows eq "yes" ? "\\\\p01ccvob.usa.hp.com\\vobstore\\triggers\\" :
                                    "/net/p01ccvob.usa.hp.com/vobstore/triggers/";
  my $logfile = $logpath . "EvilTwin.log";
  open LOG, ">>$logfile" or die "Unable to open $logfile";

  print LOG "$time: $user: $msg\n";

  close LOG;
} # Log

# Get Clearcase Environment variables needed
my $pname = $ENV {CLEARCASE_PN};

#Log "pname = $pname";

# Get element and parent directory name
my ($element_name, $parent) = fileparse ($pname);
#Log "element_name = $element_name";
#Log "parent = $parent";

# At this point parent will either end with "\.\" on Windows ("/./" on
# Unix) or a single "\" Windows ("/" on Unix).  Windows has a strange
# situation when the trailing part of parent is = "\". It ends up
# quoting the double quote and causes the execution of the lsvtree to
# fail. We must detect this and add on an additional "\".
if ($parent =~ m/$dir_delim_e\.$dir_delim_e$/) {
  $parent =~ s/$dir_delim_e\.$dir_delim_e$/$dir_delim_e/;
} elsif ($parent =~ m/\\$/) {
  $parent .= $dir_delim;
} # if

#Log "parent = $parent";

# Look for evil twins
my $status;
my $possible_dup;

# Get list of all branches for the parent directory. We will search
# these for possible evil twins.
my @parent_dir_branches = `cleartool lsvtree -all -s "$parent"`;

# Fixup parent by removing trailing delimiters
$parent =~ s/\\\\$/\\/;

foreach (@parent_dir_branches) {
  chomp;
  chop if /\r/;
#  Log $_;
} # foreach

my $evil_twin = 1;

#Log "Checking parent directories";
foreach (@parent_dir_branches) {
  chomp;

  $possible_dup = $_ . $dir_delim . $element_name;
#  Log "possible_dup = $possible_dup";

  # View extended pathnames don't work from snapshot views. While
  # using cleartool ls is slower it also has the benefit of respecting
  # the case sensitivity of MVFS.
#  Log "Doing ct ls";
  $status = (system "cleartool ls -s $possible_dup > $null 2>&1") >> 8;

  if ($status eq 0) {
    # We found something related to $element_name. Now check to see if
    # this something is a branch name
#    Log "Found something";
    my $type = `cleartool desc -fmt %m $possible_dup 2>&1`;
    chomp ($type);

    if ("$type" ne "branch") {
      # If it's not a branch then we've found an evil twin - set $status
      # to 1 indicating this and break out.
#      Log "Evil twin found!";
      $evil_twin = 0;
      last;
    } # if
#  } else {
#    Log "status = $status";
  } # if
} # foreach

# Exit 0 if the evil twin is not found
exit 0 if $evil_twin;

# Possible duplicate element is found on invisible branch(es).
my $prompt;
my $nl = $windows eq "yes" ? "\\n" : "\n";
$parent = "." if $parent eq "";
$prompt  = "The element $element_name already exists for the directory \'$parent\'$nl";
$prompt .= "in another branch as ($possible_dup).$nl$nl";
$prompt .= "You could either merge the parent directories or create a Clearcase hardline to$nl";
$prompt .= "that element.$nl$nl";
$prompt .= "For more information about this condition see:$nl$nl";
$prompt .= "http://ilmwiki.usa.hp.com/wiki/ClearCase_Evil_Twins$nl$nl";
$prompt .= "If you feel you really need to perform this action please submit a request$nl";
$prompt .= "through SourceForge at:$nl$nl";
$prompt .= "http://plesf01srv.usa.hp.com/sf/tracker/do/listArtifacts/projects.eng_tools_support/tracker.clearcase";

Log "Evil twin detected in $parent. Twin: $possible_dup";
system ("clearprompt yes_no -mask abort -default abort -newline -prompt \"$prompt\"");

exit 1;
