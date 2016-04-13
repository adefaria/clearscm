#!/usr/bin/env perl
use strict;
use warnings;

use MP3::Info;
use Data::Dumper;

my $file = $ARGV[0];

die "Cannot open $file - $!" unless -r $file;

my $tag = get_mp3tag ($file);

for (keys %$tag) {
  print "$_: $tag->{$_}\n";
} # for