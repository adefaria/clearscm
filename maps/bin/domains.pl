#!/usr/bin/perl
################################################################################
#
# File:         $RCSfile: domains,v $
# Revision:     $Revision: 1.1 $
# Description:  Display entries from the list table where there is at least one
#               entry with a null pattern (nuke the domain) and yet still other
#               entries with the same domain name but having a pattern. We may
#               want to eliminate the other entries since we're nuking the
#               whole domain anyway.
# Author:       Andrew@DeFaria.com
# Created:      Sat Oct 20 23:28:19 MST 2007
# Modified:     $Date: 2013/06/12 14:05:47 $
# Language:     Perl
#
# (c) Copyright 2007, Andrew@DeFaria.com, all rights reserved.
#
################################################################################
use strict;
use warnings;

use FindBin;
use Getopt::Long;

use lib "$FindBin::Bin/../lib", '/opt/clearscm/lib';

use MAPS;
use Display;

sub Usage () {
  display <<END;
$FindBin::Script { -verbose } { -debug } { -usage }
END

  exit 1;
} # Usage

GetOptions (
  "verbose" => sub { set_verbose },
  "debug"   => sub { set_debug },
  "usage"   => sub { Usage },
) || Usage;

my $userid = $ENV{MAPS_USERNAME} ? $ENV{MAPS_USERNAME} : $ENV{USER};

# Main
SetContext $userid;

my $statement = "select domain from list where userid=\"$userid\" and type=\"null\" and pattern is null";

my $need_resequence = 0;

for my $domain (sort (GetRows($statement))) {
  verbose "Processing domain $domain";
  $statement = "select sequence from list where userid = \"$userid\" and domain = \"$domain\" and type = \"null\" and pattern is not null";

  for my $sequence (GetRows $statement) {
    display "Deleting $domain ($sequence)";
    $need_resequence = 1;
    DeleteList "null", $sequence;
  } # for
} # for

if ($need_resequence) {
  verbose "Resequencing null list...";
  ResequenceList $userid, "null";
  verbose "done";
} # if

exit;
