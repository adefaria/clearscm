#!/usr/bin/perl
################################################################################
#
# File:         $RCSfile: nuke.cgi,v $
# Revision:     $Revision: 1.0 $
# Description:  Nuke (nulllist domain) a sender
# Author:       Andrew@DeFaria.com
# Created:      Sat Jan 17 12:45:00 PST 2026
# Modified:     $Date: 2026/01/17 20:45:00 $
# Language:     Perl
#
# (c) Copyright 2026, Andrew@DeFaria.com, all rights reserved.
#
################################################################################
use strict;
use warnings;

use FindBin;

use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../lib";

use MAPS;
use MAPSWeb;

use CGI qw(:standard);
use CGI::Carp 'fatalsToBrowser';

my $sender = param 'sender';
my $next   = param 'next' || 0;
my $userid = cookie 'MAPSUser';

# Default to environment user if cookie not set (for testing/cli)
$userid ||= $ENV{USER};

unless ($sender) {
  DisplayError ("Sender parameter is missing");
  exit;
}

# Extract domain
my ($user, $domain) = split /\@/, $sender;

unless ($domain) {
  DisplayError ("Invalid sender address: $sender");
  exit;
}

# Add domain to nulllist
my ($ret, $msg) = Add2Nulllist (
  userid  => $userid,
  sender  => '@' . $domain,
  comment => "Nuked from web interface"
);

my $message = "Nuked domain $domain";
if ($ret < 0) {
  if ($msg =~ /already matches/i) {
    $message = "Domain $domain was already nuked ($msg)";
  } else {
    DisplayError ("Error nuking domain $domain: $msg");
    exit;
  }
} ## end if ($ret < 0)

# Redirect back to detail page
print redirect(
  "/maps/bin/detail.cgi?type=returned&next=$next&message=$message");

exit;
