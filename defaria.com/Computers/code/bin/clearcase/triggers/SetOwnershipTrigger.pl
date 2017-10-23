################################################################################
#
# File:         SetOwnershipTrigger.pl
# Description:  This script will set the ownership of Clearcase elements to 
#		ccadmin when a mkelem is performed. This way all Clearcase
#		elements will be owned by ccadmin and therefore nobody but
#		ccadmin will be able to do the destructive rmelem.
# Author:       Andrew@DeFaria.com
# Created:      Wed Nov 14 16:41:48  2001
# Language:     Perl
# Modifications:
#
# (c) Copyright 2001, Andrew@DeFaria.com, all rights reserved
#
################################################################################
$pname = "$ENV{CLEARCASE_PN}";
$adm   = "ccadmin";

# Get current owner
$_ = `cleartool describe $pname`;
if (/User :\s+(\S*)\s*:/) {
  $owner = $1;
} else {
  $owner = "";
}

if ($owner ne "$adm") {
 `cleartool protect -chown $adm $ENV{CLEARCASE_PN}`;
}
