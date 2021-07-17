#!/usr/bin/perl
################################################################################
#
# File:         $RCSfile: modifyentries.cgi,v $
# Revision:     $Revision: 1.1 $
# Description:  Modify list entries
# Author:       Andrew@DeFaria.com
# Created:      Mon Jan 16 20:25:32 PST 2006
# Modified:     $Date: 2013/06/12 14:05:47 $
# Language:     perl
#
# (c) Copyright 2000-2021, Andrew@DeFaria.com, all rights reserved.
#
################################################################################
use strict;
use warnings;

use FindBin;
local $0 = $FindBin::Script;

use lib "$FindBin::Bin/../lib";

use MAPS;
use MAPSLog;
use MAPSWeb;

use CGI qw/:standard/;
use CGI::Carp 'fatalsToBrowser';

my $userid = cookie('MAPSUser');
my $type   = param('type');
my $next   = param('next');

$userid ||= $ENV{USER};

sub ReturnSequenceNbrs {
  my @names = param;
  my @sequence_nbrs;

  for (@names) {
    if (/pattern(\d+)/) {
      push @sequence_nbrs, $1;
    } # if
  } # for

  return @sequence_nbrs;
} # ReturnSequenceNbrs

# Main
my $i = 0;

for (ReturnSequenceNbrs) {
  my %rec = (
    userid    => $userid,
    type      => $type,
    sequence  => $_,
  );

  $rec{pattern}   = param "pattern$_";
  $rec{domain}    = param "domain$_";
  $rec{comment}   = param "comment$_";
  $rec{hit_count} = param "hit_count$_";
  $rec{retention} = param "retention$_";

  $rec{hit_count} = 0 unless $rec{hit_count};

  my ($err, $msg) = UpdateList(%rec);

  croak $msg if $err;

  $i++;
} # for

if ($i == 0) {
  print redirect ("/maps/php/list.php?type=$type&next=$next&message=Unable to update entries");
} elsif ($i == 1) {
  print redirect ("/maps/php/list.php?type=$type&next=$next&message=Modified entry");
} else {
  print redirect ("/maps/php/list.php?type=$type&next=$next&message=Modified entries");
} # if

exit;
