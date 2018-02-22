#!/usr/bin/perl
################################################################################
#
# File:         $RCSfile: exportlist.cgi,v $
# Revision:  $Revision: 1.1 $
# Description:  Export an address list
# Author:       Andrew@DeFaria.com
# Created:      Mon Jan 16 20:25:32 PST 2006
# Modified:     $Date: 2013/06/12 14:05:47 $
# Language:     perl
#
# (c) Copyright 2000-2006, Andrew@DeFaria.com, all rights reserved.
#
################################################################################
use strict;

use FindBin;
local $0 = $FindBin::Script;

use lib "$FindBin::Bin/../lib";

use MAPS;
use MAPSWeb;

use CGI qw/:standard *table/;
use CGI::Carp "fatalsToBrowser";

my $type     = param('type');
my $userid   = cookie("MAPSUser");
   $userid //= $ENV{USER};
my $Userid   = ucfirst $userid;

sub PrintList($) {
  my ($type) = @_;

  my $year = substr((scalar(localtime)), 20, 4);

  my ($pattern, $domain, $comment, $hit_count, $last_hit);
  my $sth = FindList($type);

  print "\################################################################################\n";
  print "\#\n";
  print "\# MAPS:\t\tMail Authorization and Permission System (MAPS)\n";
  print "\# $type.list:\t${Userid}'s $type.list file\n";
  print "\# Exported:\t" . localtime . "\n";
  print "\#\n";
  print "\# Copyright 2001-" . $year . ", Andrew\@DeFaria.com, all rights reserved.\n";
  print "\#\n";
  print "\################################################################################\n";

  while (($_, $_, $pattern, $domain, $comment, $_, $hit_count, $last_hit) = GetList($sth)) {
    last if !(defined $pattern or defined $domain);

    $pattern //= '';
    $domain  //= '';

    if ($domain eq '') {
      print "$pattern,$comment,$hit_count,$last_hit\n";
    } else {
      print "$pattern\@$domain,$comment,$hit_count,$last_hit\n";
    } # if
  } # while

  return;
} # PrintList

# Main
SetContext($userid);

print header(
  -type        => "application/octet-stream",
  -attachment  => "$type.list",
);

PrintList($type);

exit;
