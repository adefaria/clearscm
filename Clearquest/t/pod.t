#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

unless ($ENV{RELEASE_TESTING}) {
  plan (skip_all => "Author tests not required for installation");
}

# Ensure a recent version of Test::Pod
my $min_t_pod = '1.22';
eval "use Test::Pod $min_t_pod";
plan skip_all => "Test::Pod $min_t_pod required for testing POD" if $@;

all_pod_files_ok ();
