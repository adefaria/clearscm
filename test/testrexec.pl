#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Long;
use Pod::Usage; 

use FindBin;

use lib "$FindBin::Bin/../lib";

use Rexec;

my ($status, $cmd, @output);

my %opts = (
  usage    => sub { podusage() } ,
  hostname => $ENV{HOST}     || 'localhost',
  username => $ENV{USERNAME} ? $ENV{USERNAME} : $ENV{USER},
  password => $ENV{PASSWORD},
  command  => 'ls /tmp',
);

GetOptions (
  \%opts,
  'usage',
  'host=s',
  'host=s',
  'username=s',
  'password=s',
  'command=s'
);

if (@ARGV) {
  $opts{command} = join ' ', @ARGV;
} # if

print "Attempting to connect to $opts{username}\@$opts{hostname} to execute \"$opts{command}\"\n";

my $remote = Rexec->new (
  host     => $opts{hostname},
  username => $opts{username},
  password => $opts{password},
);

if ($remote) {
  print "Connected to $opts{username}\@$opts{hostname} using "
      . $remote->{protocol} . " protocol\n";

  print "Executing command \"$opts{command}\" on $opts{hostname} as $opts{username}\n";    
  @output = $remote->execute ($opts{command});
  $status = $remote->status;

  print "\"$opts{command}\" status: $status\n";

  if (@output == 0) {
    print "No lines of output received!\n";
  } else {
    print "$_\n" foreach (@output);
  } # if
} else {
  print "Unable to connect to $opts{username}\@$opts{hostname}\n";
} # if