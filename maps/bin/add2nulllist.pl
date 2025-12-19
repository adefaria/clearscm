#!/usr/bin/perl
use strict;
use warnings;

use FindBin;

use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../lib";

use MAPS;
use MAPSLog;
use MAPSWeb;
use Display;

# Highly specialized!
my $userid = $ENV{USER};
my $Userid;
my $type = 'null';

sub GetItems($) {
  my ($filename) = @_;

  my @items;

  open my $file, '<', $filename
    or error "Unable to open $filename - $!", 1;

  while (<$file>) {
    my @fields = split;
    my %item;

    my @address = split /\@/, $fields[0];

    $item{pattern}   = $address[0];
    $item{domain}    = $address[1];
    $item{comment}   = $fields[1] ? $fields[1] : '';
    $item{hit_count} = $fields[2] ? $fields[2] : 0;
    $item{retention} = $fields[3];

    push @items, \%item;
  }    # while

  close $file;

  return @items;
}    # GetItems

sub Add2List(@) {
  my (@items) = @_;

  my $item;

  my $sequence = GetNextSequenceNo (
    userid => $userid,
    type   => $type,
  );

  for $item (@items) {
    $item->{sequence} = $sequence++;
    $item->{userid}   = $userid;
    $item->{type}     = $type;

    display_nolf
"Adding $item->{pattern}\@$item->{domain} ($item->{comment}) to null list ($item->{sequence})...";

    last unless $item->{pattern} or $item->{domain};

    $item->{sender} = CheckEmail $item->{pattern}, $item->{domain};

    my ($status, $rule) = OnNulllist ($item->{sender}, $userid);

    if (!$status && $item->{sender} =~ /\@$/) {
      my $sender = $item->{sender};
      chop $sender;
      ($status, $rule) = OnNulllist ($sender, $userid);
      print " (Retry '$sender' -> " . ($status ? "Found" : "Not Found") . ") ";
    }    # if

    if ($status) {
      my $match = ($rule->{pattern} // '') . '@' . ($rule->{domain} // '');
      $match .= " ($rule->{comment})" if $rule->{comment};
      display " Already on list - Matches $match";
    } else {
      my ($message, $msg) = Add2Nulllist (%$item);

      display ' done';

      # Now remove this entry from the other lists (if present)
      for my $otherlist ('white', 'black') {
        FindList (
          userid => $item->{userid},
          type   => $otherlist,
          sender => $item->{sender}
        );

        my $seq = GetList ();

        if ($seq->{sequence}) {
          my $count = DeleteList (
            userid   => $item->{userid},
            type     => $otherlist,
            sequence => $seq->{sequence},
          );

          display "Removed $item->{sender} from ${Userid}'s "
            . ucfirst $otherlist . ' list'
            if $count > 0;

          ResequenceList (
            userid => $item->{userid},
            type   => $otherlist,
          );
        }    # if
      }    # for
    }    # if
  }    # while

  return;
}    # Add2List

# Main
my $filename;

if ($ARGV[0]) {
  $filename = $ARGV[0];
} else {
  error "Must specify a filename of addresses to null list", 1;
}    # if

SetContext ($userid);

$Userid = ucfirst $userid;

Add2List (GetItems ($filename));

exit;
