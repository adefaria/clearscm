#!/usr/bin/perl
################################################################################
#
# File:         $RCSfile: bigfiles.pl,v $
# Revision:     $Revision: 1.3 $
# Description:  Reports large files
# Author:       Andrew@DeFaria.com
# Created:      Mon May 24 09:09:24 PDT 1999
# Modified:     $Date: 2011/04/18 05:15:29 $
# Language:     Perl
#
# (c) Copyright 2001, ClearSCM, Inc., all rights reserved
#
################################################################################
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Getopt::Long;

use OSDep;
use Display;

sub Usage {
  display "Usage: bigfiles: [ -verbose | -v ] [ -size | -s n ] [ <directory> ]";
  display "\t\t[ -top n | -t n ] [ -notop | -not ]\n";
  display "Where:";
  display "  -size | -s n\tShow only files bigger then n Meg (default 1 Meg)";
  display "  -verbose | -v\tTurn on verbose mode (default verbose off)";
  display "  -top | -t n\tPrint out only the top n largest files (default LINES - 1)";
  display "  -notop|not\tPrint out all files (default top LINES - 1)";
  display "  <directory>\tDirectory paths to check";
  exit 1;
} # usage

sub Bigfiles {
  my $size = shift;
  my @dirs = @_;

  my @files;

  foreach (@dirs) {
    next if !-d "$_";

    my $lsOpts  = $ARCHITECTURE eq 'solaris' ? '-loL' : '-lLG';
    my $cmd	= "find \"$_\" -xdev -type f -size +$size -exec ls $lsOpts {} \\;";
    my @lines	= `$cmd`;

    foreach (@lines) {
      chomp;

      my %info;

      #if (/\S+\s+\d+\s+(\S+)\s+(\d+).*\"\.\/(.*)\"/) {
      if (/\S+\s+\d+\s+(\S+)\s+(\d+)\s+\S+\s+\S+\s+\d+\s+(.*)/) {
        $info {user}     = $1;
        $info {filesize} = $2;
        $info {filename} = $3;

        push @files, \%info;
      } # if
    } # foreach
  } # foreach

  return @files;
} # Bigfiles

my $lines        = $ENV{LINES} || 24;
my $top          = $lines - 2;
my $bytes_in_meg = 1048576;
my $block_size   = 512;
my $size_in_meg  = 1;
my %opts = (
  size => 1
);

my $result = GetOptions (
  \%opts,
  usage     => sub { Usage },
  verbose   => sub { set_verbose },
  debug     => sub { set_debug },
  'top=i',
  'size=i',
);

my @dirs = @ARGV > 0 ? @ARGV : '.';
my $size = $opts{size} ? $opts{size} * $bytes_in_meg / $block_size : 4096;
my @files;

# Now do the find
verbose "Directory:\t@dirs";

for (@dirs) {
  verbose "Size:\t\t$opts{size} Meg ($size blocks)";
  verbose "Top:\t\t$top";

  my $head = $top ? "cat" : "head -$top";

  @files = Bigfiles $size, @dirs;
} # for

for (sort {$b->{filesize} <=> $a->{filesize}} @files) {
  my %info = %{$_};

  last if $top-- == 0;

  print "${info {filesize}}\t${info {user}}\t${info {filename}}\n";
} # for
