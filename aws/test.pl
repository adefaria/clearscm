#!/usr/bin/perl
use strict;
use warnings;

use Paws;

my $bucket         = 'defaria-aws.com';

sub get_remote_objects ($) {
  my ($s3) = @_;

  my (%remote_objects, $token, $truncated);

  do {
    my $response = $s3->ListObjectsV2(
      Bucket => $bucket,
      ($token ? (ContinuationToken => $token) : ()),
    );

    for (@{$response->{Contents}}) {
      $remote_objects{$_->{Key}} = Time::Piece->strptime($_->{LastModified}, '%Y-%m-%dT%T.000Z')->epoch;
    } # for

    if ($response->{isTruncated}) {
      $token = $response->{NextContinuationToken};
      $truncated = 1;
    }  # if
  } while ($truncated);

  return \%remote_objects;
} # get_remote_objects

# Let's get the files in the S3 bucket
my $s3             = Paws->service('S3', region => 'us-west-1');
my $remote_objects = get_remote_objects($s3);

for (keys %$remote_objects) {
  print "$_\n";
} # for

print "done\n";
