#!/usr/bin/perl
################################################################################
#
# File:         AddExecute.pl
# Description:  This trigger script simply adds execute permission to an element
#		when it is created in Clearcase
# Trigger Type:	All element
# Operation:	Postop mkelem
# Author:       Andrew@DeFaria.com
# Created:      Fri Mar 12 10:17:44 PST 2004
# Language:     Perl
# Modifications:
#
# (c) Copyright 2004, Andrew@DeFaria.com, all rights reserved
#
################################################################################
use strict;
use warnings;

my $element  = $ENV{CLEARCASE_PN};

system "cleartool protect -chmod +x \"$element\"";

exit 0;
