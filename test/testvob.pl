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
use Clearcase::Vob;
use Display;

my $vobs = new Clearcase::Vobs;

my @vob_list	= $vobs->vobs;

my $vob;
my $i		= 0;

$vob = new Clearcase::Vob (tag => $vob_list[$i++]);

display YELLOW . "Clearcase VOB\n" . RESET;

display MAGENTA . "Tag:\t\t"		. RESET . $vob->tag;
display MAGENTA . "Global path:\t"	. RESET . $vob->gpath;
display MAGENTA . "Sever host:\t"	. RESET . $vob->shost;
display MAGENTA . "Access:\t\t"		. RESET . $vob->access;
display MAGENTA . "Mount options:\t"	. RESET . $vob->mopts;
display MAGENTA . "Region:\t\t"		. RESET . $vob->region;
display MAGENTA . "Active:\t\t"		. RESET . $vob->active;
display MAGENTA . "Replica UUID:\t"	. RESET . $vob->replica_uuid;
display MAGENTA . "Host:\t\t"		. RESET . $vob->host;
display MAGENTA . "Access path:\t"	. RESET . $vob->access_path;
display MAGENTA . "Family UUID:\t"	. RESET . $vob->family_uuid;

display YELLOW	. "\nVOB Statistics\n"	. RESET;
display MAGENTA . "Elements:\t"		. RESET . $vob->elements;
display MAGENTA . "Branches:\t"		. RESET . $vob->branches;
display MAGENTA . "Versions:\t"		. RESET . $vob->versions;
display MAGENTA . "DB Size:\t"		. RESET . $vob->dbsize;
display MAGENTA . "Adm Size:\t"		. RESET . $vob->admsize;
display MAGENTA . "CT Size:\t"		. RESET . $vob->ctsize;
display MAGENTA . "DO Size:\t"		. RESET . $vob->dbsize;
display MAGENTA . "Src Size:\t"		. RESET . $vob->srcsize;
display MAGENTA . "Size:\t\t"		. RESET . $vob->size;

display YELLOW	. "\nVOB manipulation\n" . RESET;

display "Umounting " . $vob->tag . "...";

$vob->umount;

display "Mounting " . $vob->tag . "...";

$vob->mount;
