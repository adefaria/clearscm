#!/usr/bin/perl
################################################################################
#
# File:         $RCSfile: importlist.cgi,v $
# Revision:     $Revision: 1.1 $
# Description:  Export an address list
# Author:       Andrew@DeFaria.com
# Created:      Mon Jan 16 20:25:32 PST 2006
# Modified:     $Date: 2013/06/12 14:05:47 $
# Language:     perl
#
# (c) Copyright 2000-2006, Andrew@DeFaria.com, all rights reserved.
#
################################################################################
use strict;

use FindBin;
local $0 = $FindBin::Script;

use lib "$FindBin::Bin/../lib";

use Getopt::Long;
use Pod::Usage;

use MAPS;
use MAPSWeb;

use CGI qw/:standard *table/;
use CGI::Carp "fatalsToBrowser";

my $userid =   cookie('MAPSUser');
   $userid //= $ENV{USER};
my $Userid =   ucfirst $userid;

my %opts = (
  usage => sub { pod2usage },
  help  => sub { pod2usage (-verbose => 2)},
  type  => param('type'),
  file  => param('file'),
);

sub importList ($) {
  my ($type) = @_;

  my $count = 0;

  open my $file, '<', $opts{file}
    or die "Unable to open $opts{file} - $!\n";

  while (<$file>) {
    next if /^\s*#/;

    chomp;

    my ($pattern, $comment, $hit_count, $last_hit) = split /,/;

    my $alreadyExists;

    if ($type eq 'white') {
      ($alreadyExists) = OnWhitelist($pattern, $userid);
    } elsif ($type eq 'black') {
      ($alreadyExists) = OnBlacklist($pattern, $userid);
    } elsif ($type eq 'null') {
      ($alreadyExists) = OnNulllist($pattern, $userid);
    } # if

    unless ($alreadyExists) {
      AddList($type, $pattern, 0, $comment, $hit_count, $last_hit);

      $count++;
    } else {
      print br "$pattern is already on your " . ucfirst($type) . 'list';
    } # unless
  } # while

  close $file;

  return $count;
} # importList

# Main
GetOptions(
  \%opts,
  'usage',
  'help',
  'verbose',
  'debug',
  'file=s',
  'type=s',
);

pod2usage "Type not specified" unless $opts{type};
pod2usage '-file should be specified' unless $opts{file};
pod2usage "Unable to read $opts{file}" unless -r $opts{file};

$userid = Heading(
  'getcookie',
  '',
  'Import List',
  'Import List',
);

SetContext($userid);

NavigationBar($userid);

my $count = importList($opts{type});

if ($count == 1) {
  print br "$count list entry imported";
} elsif ($count == 0) {
  print br 'No entries imported';
} else {
  print br "$count list entries imported";
} # if

exit;
