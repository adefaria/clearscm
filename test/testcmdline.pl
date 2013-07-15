#!/usr/bin/perl
use strict;
use warnings;

use FindBin;

use lib "$FindBin::Bin/../lib";

use CmdLine;
use Display;
use Term::ANSIColor qw (color);

my $me = $FindBin::Script;
   $me =~ s/\.pl$//;

my $prompt = color ('BOLD CYAN') . "$me:" . color ('RESET');
  
$CmdLine::cmdline->set_prompt ($prompt);

my ($line, $result);

while (($line, $result) = $CmdLine::cmdline->get) {
  last unless defined $line;
  last if $line =~ /exit|quit/i;
  
  display "Would have executed $line"
    if $line !~ /^\s*$/;
} # while

display 'done';