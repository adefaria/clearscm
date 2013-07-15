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
use Clearcase::Element;
use Display;

error "Usage: $0 <pname>", 1 if !$ARGV[0];

my $element = new Clearcase::Element (pname => $ARGV[0]);

display MAGENTA	. "Element:\t"	. RESET	. $element->pname;
display MAGENTA	. "Version:\t"	. RESET	. $element->version;
display MAGENTA	. "Pred:\t\t"	. RESET . $element->pred;

display MAGENTA	. "Activities:"	. RESET;

if (my %activities = $element->activities) {
  display "\t\t$_: $activities{$_}" foreach (keys %activities);
} else {
  display CYAN	. "\t\tNone"	. RESET;
} # if

display MAGENTA	. "Attributes:"	. RESET;

if (my %attributes = $element->attributes) {
  display "\t\t$_=$attributes{$_}" foreach (keys %attributes);
} else {
  display CYAN	. "\t\tNone"	. RESET;
} # if

display MAGENTA	. "Hyperlinks:"	. RESET;

if (my @hyperlinks = $element->hyperlinks) {
  display "\t\t$_" foreach (@hyperlinks);
} else {
  display CYAN	. "\t\tNone"	. RESET;
} # if

display MAGENTA	. "Comments:"		. RESET . $element->comments;
display MAGENTA	. "Create_date:\t"	. RESET . $element->create_date;
display MAGENTA	. "User:\t\t"		. RESET . $element->user;
display MAGENTA	. "Group:\t\t"		. RESET	. $element->group;
display MAGENTA	. "User_mode:\t"	. RESET	. $element->user_mode;
display MAGENTA	. "Group_mode:\t"	. RESET	. $element->group_mode;
display MAGENTA	. "Other_mode:\t"	. RESET	. $element->other_mode;
display MAGENTA	. "Mode:\t\t"		. RESET	. $element->mode;	

display MAGENTA	. "Labels:"	. RESET;

if (my @labels = $element->labels) {
  display "\t\t$_" foreach (@labels);
} else {
  display CYAN	. "\t\tNone"	. RESET;
} # if

display MAGENTA	. "Rule:\t\t"		. RESET	. $element->rule;
display MAGENTA	. "Xname:\t\t"		. RESET	. $element->xname;
