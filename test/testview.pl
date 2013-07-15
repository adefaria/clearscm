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
use Clearcase::View;
use Display;

sub DisplayViewInfo ($) {
  my ($view) = @_;

  display YELLOW	. "View:\t\t \t"	. RESET . $view->tag;
  display MAGENTA	. "Accessed by:\t\t"	. RESET . $view->accessed_by;
  display MAGENTA	. "Accessed date:\t\t"	. RESET . $view->accessed_date;
  display MAGENTA	. "Access path:\t\t"	. RESET . $view->access_path;
  display MAGENTA	. "Active:\t\t\t"	. RESET . $view->active;

  display_nolf MAGENTA	. "Additional groups:\t";

  foreach ($view->additional_groups) {
    display_nolf "$_ ";
  } # foreach

  display "";

  display MAGENTA	. "Created by:\t\t"	. RESET . $view->created_by;
  display MAGENTA	. "Created date:\t\t"	. RESET . $view->created_date;
  display MAGENTA	. "CS updated by:\t\t"	. RESET . $view->cs_updated_by;
  display MAGENTA	. "CS updated date:\t"	. RESET . $view->cs_updated_date;
  display MAGENTA	. "Global path:\t\t"	. RESET . $view->gpath;
  display MAGENTA	. "Group:\t\t\t"	. RESET . $view->group;
  display MAGENTA	. "Group mode:\t\t"	. RESET . $view->group_mode;
  display MAGENTA	. "Host:\t\t\t"		. RESET . $view->host;
  display MAGENTA	. "Mode:\t\t\t"		. RESET . $view->mode;
  display MAGENTA	. "Modified by:\t\t"	. RESET . $view->modified_by;
  display MAGENTA	. "Modified date:\t\t"	. RESET . $view->modified_date;
  display MAGENTA	. "Other mode:\t\t"	. RESET . $view->other_mode;
  display MAGENTA	. "Owner:\t\t\t"	. RESET . $view->owner;
  display MAGENTA	. "Owner mode:\t\t"	. RESET . $view->owner_mode;
  display MAGENTA	. "Properties:\t\t"	. RESET . $view->properties;
  display MAGENTA	. "Region:\t\t\t"	. RESET . $view->region;
  display MAGENTA	. "Server host:\t\t"	. RESET . $view->shost;
  display MAGENTA	. "Text mode:\t\t"	. RESET . $view->text_mode;

  display_nolf MAGENTA	. "Type:\t\t\t"		. RESET;

  if ($view->snapshot) {
    display_nolf "snapshot";
  } else {
    display_nolf "dynamic";
  } # if

  if ($view->ucm) {
    display_nolf ",ucm";
  } # if

  display "";

  display MAGENTA	. "UUID:\t\t\t"		. RESET . $view->uuid;
} # DisplayViewInfo

error "Usage $0 <view tag>", 1 if !$ARGV[0];

foreach (@ARGV) {
  my $view = new Clearcase::View (tag => $_);

  DisplayViewInfo $view;
} # foreach

