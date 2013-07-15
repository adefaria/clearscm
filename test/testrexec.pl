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

my $remote = Rexec->new (
  host     => $hostname,
  username => $username,
  password => $password,
  timeout  => 30,
);

if ($remote) {
  print "Connected to $username\@$hostname using "
      . $remote->{protocol} . " protocol\n";
    
  $cmd = "/bin/ls /nonexistent";

  @output = $remote->execute ($cmd);
  $status = $remote->status;

  print "$cmd status: $status\n";

  $remote->print_lines;

  print "$_\n" foreach ($remote->execute ('cat /etc/passwd'));
} else {
  print "Unable to connect to $username@$hostname\n";
} # if


