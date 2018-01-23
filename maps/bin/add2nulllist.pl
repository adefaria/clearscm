#!/usr/bin/perl
use strict;
use warnings;

use FindBin;

use lib $FindBin::Bin, '/opt/clearscm/lib';

use MAPS;
use MAPSLog;
use MAPSWeb;
use Display;

# Highly specialized!
my $userid = $ENV{USER};
my $Userid;
my $type = "null";

sub GetItems {
  my $filename = shift;

  my @items;

  open my $file, '<', $filename
    or error "Unable to open $filename - $!", 1;

  while (<$file>) {
    my @fields = split;
    my %item;

    my @address = split /\@/, $fields [0];

    $item{pattern}   = $address[0];
    $item{domain}    = $address[1];
    $item{comment}   = $fields[1] ? $fields[1] : '';
    $item{hit_count} = $fields[2] ? $fields[2] : 0;

    push @items, \%item;
  } # while

  close $file;

  return @items;
} # GetItems

sub Add2List {
  my @items = @_;

  my $sender  = "";
  my $nextseq = MAPSDB::GetNextSequenceNo $userid, $type;

  foreach (@items) {
    my %item = %{$_};

    my $pattern   = $item{pattern};
    my $domain    = $item{domain};
    my $comment   = $item{comment};
    my $hit_count = $item{hit_count};

    display_nolf "Adding $pattern\@$domain ($comment) to null list ($nextseq)...";

    last if ((!defined $pattern || $pattern eq '') &&
             (!defined $domain  || $domain  eq ''));

    $sender = lc ("$pattern\@$domain");

    if (OnNulllist $sender) {
      display " Already on list";
    } else {
      Add2Nulllist $sender, $userid, $comment, $hit_count;
      display " done";

      # Now remove this entry from the other lists (if present)
      foreach my $otherlist ("white", "black") {
        my $sth = FindList $otherlist, $sender;
        my ($sequence, $count);

        ($_, $_, $_, $_, $_, $sequence) = GetList $sth;

        if ($sequence) {
          $count = DeleteList $otherlist, $sequence;
        } # if
      } # foreach
    } # if
    $nextseq++;
  } # while

  return;
} # Add2List

# Main
my $filename;

if ($ARGV [0]) {
  $filename = $ARGV[0];
} else {
  error "Must specify a filename of addresses to null list", 1;
} # if

SetContext $userid;

$Userid = ucfirst $userid;

Add2List (GetItems $filename);

exit;
