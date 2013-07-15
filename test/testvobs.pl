#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
use Term::ANSIColor qw(:constants);

my $libs;

BEGIN {
  $libs = $ENV{SITE_PERLLIB} ? $ENV{SITE_PERLLIB} : "$FindBin::Bin/../lib";

  die "Unable to find libraries\n" if !$libs and !-d $libs;
} # BEGIN

use lib $libs;

use Clearcase;
use Clearcase::Vobs;
use Display;

my $vobs = new Clearcase::Vobs;

my $nbr_vobs	= $vobs->vobs;
my @vob_list	= $vobs->vobs;

display YELLOW . "Clearcase VOBs\n" . RESET;

display MAGENTA . "Number of vobs:\t\t"		. RESET . $nbr_vobs;
display MAGENTA . "VOB list:\n"			. RESET;

display "\t$_" foreach (@vob_list);

if ($vobs->umount) {
  display "Unmounted all vobs";
} # if

if ($vobs->mount) {
  display "Mounted all vobs";
} # if
