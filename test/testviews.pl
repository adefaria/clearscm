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
use Clearcase::Views;
use Display;

my $views = new Clearcase::Views;

my $nbr_views	= $views->views;
my @view_list	= $views->views;

display YELLOW . "Clearcase Views\n" . RESET;

display MAGENTA . "Number of views:\t\t"	. RESET . $nbr_views;
display MAGENTA . "View list:\n"		. RESET;

display "\t$_" foreach (@view_list);
