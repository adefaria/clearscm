################################################################################
#
# File:         Protect.pl,v
# Revision:	1.1.1.1
# Description:	When new elements are created in the VOB change the elements
#		ownership to the owner of the VOB and change element permissions
#		to appropiate for element_type.
#
#		NOTE: If a particular file_type is not implemented in
#		your VOB then comment it out.  Unspecified file_types
#		will have origional permissions, but will have
#		ownership changed.
# Assumptions:	Clearprompt is in the users PATH
# Author:       Andrew@DeFaria.com
# Created:      April 20, 2003
# Modified:	2007/05/17 07:45:48
# Language:     Perl
#
################################################################################
use strict;
use warnings;

# What do we set the owner and group to?
my $owner  = "vobadm";
my $group  = "ccadmin";

# Get CLEARCASE_PN
my $pname = $ENV {CLEARCASE_PN};

# Let's get the real owner from the real output of describe
my @output = `cleartool describe vob:$pname`;

foreach (@output) {
  if (/owner\s*\w*\\(.*)/) {
    $owner = $1;
    chop $owner if $owner =~ /\r/; # any carriage return
    last;
  } # if
} # foreach

# Let's get the real group from the real output of describe
foreach (@output) {
  if (/group\s*\w*\\(.*)/) {
    $group = $1;
    chop $group if $group =~ /\r/; # any carriage return
    last;
  } # if
} # foreach

# Get what element type we are dealing with
my $eltype = $ENV {CLEARCASE_ELTYPE};

if (($eltype eq "directory") ||
    ($eltype =~ /.*script/)  ||
    ($eltype =~ /.*program/)) {
  # All element types that are known to be 775 should be placed here.
  `cleartool protect -chmod 775 -chown $owner -chgrp $group $pname`;
} elsif (($eltype eq "makefile")  ||
         ($eltype =~ /.*include/) ||
         ($eltype =~ /.*source/)) {
  # All element types that are known to be 664 should be placed here.
  `cleartool protect -chmod 664 -chown $owner -chgrp $group $pname`;
} elsif ($eltype eq "report") {
  # All element types that are known to be 644 should be placed here.
  `cleartool protect -chmod 644 -chown $owner -chgrp $group $pname`;
} else {
  # All other element types should just have the ownership changed.
  `cleartool protect -chown $owner -chgrp $group $pname`;
} # if

exit 0
