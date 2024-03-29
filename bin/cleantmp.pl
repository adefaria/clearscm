#!/usr/bin/env perl
use strict;
use warnings;
use v5.22;

=pod

=head1 NAME $RCSfile: cleantmp.pl,v $

Keep /tmp clean based on filesets

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@DeFaria.com>

=item Revision

$Revision: 1.0 $

=item Created:

Wed Feb 21 20:43:58 PST 2018

=item Modified:

$Date: $

=back

=head1 SYNOPSIS

 Usage: cleantmp.pl [-u|sage] [-h|elp] [-v|erbose] [-d|ebug]
                    [-t|mp <dir>] [-c|onf <file>] [-l|ogpath <path>]
                    [-s|leep <secs>]

 Where:
   -u|sage           Print this usage
   -h|elp            Detailed help
   -v|erbose:        Verbose mode
   -d|ebug:          Print debug messages
   -t|mp <dir>:      Tmp directory to monitor (Default: /tmp)
   -c|onf <file>:    Config file holding patterns to match (Default: 
                     .../etc/cleantmp.conf)
   -l|ogpath <path>: Path to logfile (Default: /var/log)
   -a|ppend:         Append to logfile (Default: Noappend)
   -da|emon          Run in daemon mode (Default: -daemon)
   -s|leep <secs>:   How many seconds to sleep between polls (Default: 60)

=head1 DESCRIPTION

This script will run in the background and keep /tmp clean. It will read in a 
list of Perl regexs from the config file. When new files are created in tmp they
will be compared against the list of regexs and if there's a match the file or
directory will be removed. 

The sleep parameter tells us how long to wait before polling for changes again

=cut

use FindBin;
use Getopt::Long;
use Pod::Usage;
use File::Monitor;
use File::Spec;
use File::Path qw/remove_tree/;

use lib "$FindBin::Bin/../lib";

use Display;
use Logger;
use Utils;

my ($script) = ($FindBin::Script =~ /^(.*)\.pl/);
my $log;

local $0 = $script;

my %opts = (
  usage   => sub { pod2usage },
  help    => sub { pod2usage(-verbose => 2)},
  verbose => sub { set_verbose },
  debug   => sub { set_debug },
  daemon  => 1,
  tmp     => File::Spec->tmpdir(),
  conf    => "$FindBin::Bin/../etc/$script.conf",
  logpath => '/var/local/log',
  sleep   => 60,
);

sub loadConfig() {
  my @patterns;

  open my $patterns, '<', $opts{conf}
    or $log->err("Unable to open $opts{conf} - $!", 1);

  while (<$patterns>) {
    next if /^\s*#/; # Skip comments

    chomp;

    push @patterns, $_;
  } # while

  close $patterns;

  return @patterns;
} # loadConfig

sub FileCreated {
  my ($name, $event, $change) = @_;

  opendir my $dir, $opts{tmp}
    or $log->err("Unable to open $opts{tmp} - $!", 1);

  while (my $createdFile = readdir $dir) {
    next if $createdFile =~ /^\./; # Skip all hidden files

    for my $pattern (loadConfig) {
      debug "Processing pattern $pattern";

      if ($createdFile =~ /$pattern/) {
        debug "Matched $createdFile to $pattern";

        if (-d "$opts{tmp}/$createdFile") {
          remove_tree ("$opts{tmp}/$createdFile", {error => \my $err});

          if (@$err) {
            for my $diag (@$err) {
              my ($file, $message) = %$diag;

              if ($file eq '') {
                $log->err("General error: $message");
              } else {
                $log->err("Unable to delete $file: $message");
              } # if
            } # for
          } else {
            $log->msg("$opts{tmp}/$createdFile removed");
          } # if
        } else {
          unless (unlink "$opts{tmp}/$createdFile") {
            $log->err("Unable to remove $opts{tmp}/$createdFile - $!");
          } else {
            $log->msg("$opts{tmp}/$createdFile removed");
          } # if
        } # if

        last;
      } # if
    } # for
  } # while

  return;
} # FileCreated

$SIG{USR1} = \&FileCreated;

## Main
GetOptions (
  \%opts,
  'usage',
  'help',
  'verbose',
  'debug',
  'daemon!',
  'tmp=s',
  'logpath=s',
  'conf=s',
  'sleep=i',
  'append',
) or pod2usage;

$log = Logger->new(
  path        => $opts{logpath},
  timestamped => 1,
  append      => $opts{append},
);

$log->msg("Starting $FindBin::Script");

# First run through whatever junk is in /tmp
for (glob "$opts{tmp}/*") {
  FileCreated($_);
} # for

my $monitor = File::Monitor->new;

$monitor->watch({
  name     => $opts{tmp},
  files    => 1,
  callback => {files_created => \&FileCreated}
});

set_debug if $DB::OUT;

if ($opts{daemon}) {
  # Perl complains if we reference $DB::OUT only once
  no warnings;
  EnterDaemonMode unless defined $DB::OUT or get_debug;
  use warnings;
} # if

while () {
  $monitor->scan;

  sleep $opts{sleep};
} # while

