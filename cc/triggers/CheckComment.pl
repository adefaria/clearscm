#!/usr/bin/perl
#################################################################################
# File:         CheckComment.pl,v
# Revision:     1.1.1.1
# Description:  This trigger checks to insure that the user enters a comment
#		during checkin time.
# Trigger Type: All element
# Operation:    Preop checkin
# Author:       Andrew@DeFaria.com
# Created:      May 24, 2004
# Modified:     2007/05/17 07:45:48
# Language:     Perl
#
# (c) Copyright 2006, Andrew@DeFaria.com, all rights reserved
#
################################################################################
use strict;
use warnings;

# Get comment
my $comment = $ENV {"CLEARCASE_COMMENT"};

# Check if it's empty
if ($comment eq "") {
  # Alert user
  `clearprompt proceed -type error -prompt "You must specify a comment" -mask proceed`;
  # Exit with non-zero status so checkin aborts
  exit 1
} # if
