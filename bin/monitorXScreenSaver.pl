#!/usr/bin/perl
use strict;
use warnings;

=pod

=head1 NAME $RCSfile: monitorXScreenSaver.pl,v $

Monitor xscreensaver and forcefully turn off screens when blanked. Note I had a
problem before where the screens wouled unblank and not go into powersave mode.
I think my new system doesn't have this problem anymore but I still run this.

I'd like to augment this so that after blanking of the screen and some time
thereafter the system would suspend. Suspending the system doesn't always work
well. It doesn't work well on my MacBook running Ubuntu but it does seem to work
OK on my Thelio Desktop from System76. But I have not implemented this yet.

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@DeFaria.com>

=item Revision

$Revision: 1.0 $

=item Created:

Fri 09 Apr 2021 10:50:28 AM PDT

=item Modified:

$Date: $

=back

=head1 SYNOPSIS

 Usage: monitorXscreenSaver.pl [-u|sage] [-h|elp] [-v|erbose] [-de|bug]
                               [-[no]da|emon] [-l|ogpath]

 Where:
   -u|sage           Print this usage
   -h|elp            Detailed help
   -v|erbose:        Verbose mode
   -d|ebug:          Print debug messages
   -l|ogpath <path>: Path to logfile (Default: /var/local/log)
   -da|emon          Run in daemon mode (Default: -daemon)

=head1 DESCRIPTION

This script will monitor the xscreensaver process and forcefully powersave the
monitors when blanked.

=cut

use FindBin;
use Getopt::Long;
use Pod::Usage;

use lib "$FindBin::Bin/lib";

use Display;
use Logger;
use Utils;

my %opts = (
  usage   => sub { pod2usage },
  help    => sub { pod2usage(-verbose => 2)},
  verbose => sub { set_verbose },
  debug   => sub { set_debug },
  daemon  => 1,
  logpath => '/var/local/log',
);

my ($xscreensaver, $log);

sub interrupt() {
  $log->msg("$FindBin::Script shutdown");

  # For Perl::Critic
  return;
} # interrupt

## Main
GetOptions(
  \%opts,
  'usage',
  'help',
  'verbose',
  'debug',
  'daemon!',
  'logpath',
) or pod2usage;

$SIG{INT} = \&interrupt;

$log = Logger->new(
  path        => $opts{logpath},
  timestamped => 1,
  append      => $opts{append},
);

my $locked = 0;

$| = 1;

$log->msg('Started monitoring XScreenSaver');

if ($opts{daemon}) {
  # Perl complains if we reference $DB::OUT only once
  display "EnterDaemonMode" unless $DB::OUT or get_debug;
  no warnings;
  EnterDaemonMode unless defined $DB::OUT or get_debug;
  display "Back from EnterDaemonMode";
  use warnings;
} # if

open $xscreensaver, '-|', 'xscreensaver-command -watch'
  or $log->err("Unable to start xscreensaver-command -watch - $!", 1);

while (<$xscreensaver>) {
  $log->dbug("Received: $_");

  if (/^LOCK/) {
    $log->msg('Locked screen');
    $locked = 1;

    my $cmd = 'xset dpms force off';

    $log->dbug("Calling $cmd");
    system $cmd;
    my $status = $?;

    $log->dbug("Returned from $cmd");

    if ($status == 0) {
      $log->dbug('Success');
    } else {
      $log->err("Unable to call $cmd- $!");
    } # if
  } elsif ($locked and /^UNBLANK/) {
    $log->msg('Unlocked screen');
    $locked = 0;
  } # if
} # while
