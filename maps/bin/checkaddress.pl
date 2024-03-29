#!/usr/bin/perl
################################################################################
#
# File:         $RCSfile: checkaddress,v $
# Revision:     $Revision: 1.1 $
# Description:	Check an email address
# Author:       Andrew@DeFaria.com
# Created:      Mon Jan 16 20:25:32 PST 2006
# Modified:     $Date: 2013/06/12 14:05:47 $
# Language:     perl
#
# (c) Copyright 2000-2006, Andrew@DeFaria.com, all rights reserved.
#
################################################################################
use strict;
use warnings;

use FindBin;

use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../lib";

use MAPS;
use Display;

error("Must specify an email address to check", 1) 
  if !$ARGV[0] or $ARGV[0] eq "";

for (@ARGV) {
  my $sender = lc $_;

  my ($status, $rule);

  my $username = lc $ENV{USER};

  my ($user, $domain) = $sender =~ /(.+)\@(.+)/;

  unless ($user and $domain) {
    error "Illegal email address $sender";

    next;
  } # unless

  if ($domain eq "defaria.com" and $user ne $username) {
    display"Nulllist - $sender is from this domain but is not from $username";
    next;
  } # if

  # Algorithm change: We now first check to see if the sender is not found
  # in the message and skip it if so. Then we handle if we are the sender
  # and that the from address is formatted properly. Spammers often use 
  # the senders email address (i.e. andrew@defaria.com) as their from address
  # so we check "Andrew DeFaria <Andrew@DeFaria.com>", which they have never
  # forged. This catches a lot of spam actually.
  #
  # Next we check to see if the sender is on our whitelist. If so then we let
  # them in. This allows us to say whitelist josephrosenberg@hotmail.com while
  # still nulllisting all of the other hotmail.com spammers.
  #
  # Next we process blacklisted people as they are also of high priority.
  #
  # Then we process nulllist people.
  #
  # Finally, we handle return processing

  # Check which list the sender is on. Note that these function calls return a
  # list of scalars. But if we want to check to see that the first returned
  # item is in the list we need to use a syntax of () = func(). If instead we
  # just use if (func()) and func returns a list, then we will not see the first
  # scalar returned as a boolen. Using () = func() does this for us.
  if (() = OnWhitelist($sender, $username, 0)) {
    display "Sender $sender would be whitelisted";
  } elsif (() = OnBlacklist($sender, 0)) {
    display "Sender $sender would be be blacklisted";
  } elsif (() = OnNulllist($sender, 0)) {
    display "Sender $sender would be nulllisted"
  } else {
    display "Sender $sender would be returned"
  } # if 
} # for
