#!/usr/bin/perl
use strict;
use warnings;

use CVSAdm;

sub Read {
  my $filename	= shift;

  open FILE, $filename
    or DisplayError "Unable to open file $filename - $!";

  my @lines = <FILE>;

  close FILE;

  return @lines;
} # Read

my $groups = "penguin/andrew-cvs/CVSROOT/groups";
my $group = "foobar";

  my @groups = Read $groups;

  open FILE, ">/tmp/groups.before";
  foreach (@groups) {
    print FILE $_;
  } # foreach
  close FILE;
  foreach (@groups) {
    my $line = $_;
    chomp $line;
    return 1, "Group $group already exists" if $group eq $line;
  } # foreach
  push @groups, $group . "\n";

  open FILE, ">/tmp/groups.after";
  foreach (@groups) {
    print FILE $_;
  } # foreach
  close FILE;
