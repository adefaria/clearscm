#!/usr/bin/perl
use strict;
use warnings;

use FindBin;

use lib "$FindBin::Bin/../lib";

use Rexec;

my ($status, $cmd, @output);

my $hostname = $ENV{HOST}     || 'localhost';
my $username = $ENV{USERNAME};
my $password = $ENV{PASSWORD};

my $command  = $ENV{COMMAND};

if (@ARGV) {
  $command = join ' ', @ARGV;
} else {
  $command = 'ls /tmp' unless $command;  
} # if

print "Attempting to connect to $username\@$hostname to execute \"$command\"\n";

my $remote = Rexec->new (
  host     => $hostname,
  username => $username,
  password => $password,
  timeout  => 30,
);

if ($remote) {
  print "Connected to $username\@$hostname using "
      . $remote->{protocol} . " protocol\n";

  print "Executing command \"$command\" on $hostname as $username\n";    
  @output = $remote->execute ($command);
  $status = $remote->status;

  print "\"$command\" status: $status\n";

  if (@output == 0) {
    print "No lines of output received!\n";
  } else {
    print "$_\n" foreach (@output);
  } # if
} else {
  print "Unable to connect to $username@$hostname\n";
} # if