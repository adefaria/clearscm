#!/usr/bin/perl

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

## no critic (TestingAndDebugging::RequireUseWarnings, TestingAndDebugging::RequireUseStrict)
use FindBin;
use lib "$FindBin::Bin/../lib";

use StdEnv;
use Getopt::Long;
use Pod::Usage;
use Display;
use Logger;
use Utils;

use POSIX ":sys_wait_h";

my %opts = (
  usage        => sub {pod2usage},
  help         => sub {pod2usage (-verbose => 2)},
  verbose      => sub {set_verbose},
  debug        => sub {set_debug},
  daemon       => 1,
  logpath      => '/var/local/log',
  lock_timeout => 1800,
);

my ($xscreensaver, $log);
my $timer_pid = 0;

sub cancel_timer() {
  if ($timer_pid) {
    $log->dbug ("Cancelling lock timer (pid $timer_pid)");
    kill 'TERM', $timer_pid;
    waitpid ($timer_pid, 0);
    $timer_pid = 0;
  } ## end if ($timer_pid)

  return;
}    # cancel_timer

sub interrupt() {
  $log->msg ("$FindBin::Script shutdown");
  cancel_timer ();

  # For Perl::Critic
  return;
}    # interrupt

## Main
GetOptions (\%opts, 'usage', 'help', 'verbose', 'debug', 'daemon!', 'logpath',
  'lock_timeout=i',)
  or pod2usage;

$SIG{INT} = \&interrupt;

$log = Logger->new (
  path        => $opts{logpath},
  timestamped => 1,
  append      => $opts{append},
);

my $locked = 0;

local $| = 1;

$log->msg ('Started monitoring XScreenSaver');

if ($opts{daemon}) {
  ## no critic (TestingAndDebugging::ProhibitNoWarnings)
  no warnings;
  EnterDaemonMode unless defined $DB::OUT or get_debug;
  use warnings;
}    # if

## no critic (InputOutput::RequireBriefOpen)
open $xscreensaver, '-|', 'xscreensaver-command -watch'
  or $log->err ("Unable to start xscreensaver-command -watch - $!", 1);

sub is_session_locked {
  my $active = `loginctl show-session auto -p Active --value 2>/dev/null`;
  chomp $active;
  return 1 if $active eq 'no';

  my $locked_hint =
    `loginctl show-session auto -p LockedHint --value 2>/dev/null`;
  chomp $locked_hint;
  return 1 if $locked_hint eq 'yes';

  return 0;
}    # is_session_locked

while (<$xscreensaver>) {
  $log->dbug ("Received: $_");

  if ($timer_pid) {
    my $kid = waitpid ($timer_pid, WNOHANG);
    $timer_pid = 0 if ($kid > 0 || $kid == -1);
  }

  if (/^BLANK/) {
    if (is_session_locked ()) {
      $log->dbug ('Session is already locked; ignoring blank event');
      cancel_timer ();
      $locked = 1;
      next;
    }

    cancel_timer ();

    if ($opts{lock_timeout} > 0) {
      $log->msg ("Screen blanked; scheduling lock in $opts{lock_timeout} seconds");
      $timer_pid = fork ();
      if (defined $timer_pid && $timer_pid == 0) {
        $SIG{TERM} = sub { exit 0; };
        sleep $opts{lock_timeout};
        exec '/opt/clearscm/bin/lock_screen';
        exit 0;
      }
    } else {
      unless ($locked) {
        $log->msg ('Locked screen');
        $locked = 1;

        my $cmd = '/opt/clearscm/bin/lock_screen';

        $log->dbug ("Calling $cmd");
        system $cmd;
        my $status = $?;

        $log->dbug ("Returned from $cmd");

        if ($status == 0) {
          $log->dbug ('Success');
        } else {
          $log->err ("Unable to call $cmd- $!");
        } # if
      } # unless
    }
  } elsif (/^LOCK/) {
    if (is_session_locked ()) {
      $log->dbug ('Session is already locked; ignoring lock event');
      cancel_timer ();
      $locked = 1;
      next;
    }

    cancel_timer ();

    unless ($locked) {
      $log->msg ('Locked screen');
      $locked = 1;

      my $cmd = '/opt/clearscm/bin/lock_screen';

      $log->dbug ("Calling $cmd");
      system $cmd;
      my $status = $?;

      $log->dbug ("Returned from $cmd");

      if ($status == 0) {
        $log->dbug ('Success');
      } else {
        $log->err ("Unable to call $cmd- $!");
      } # if
    } # unless
  } elsif (/^UNBLANK/) {
    cancel_timer ();

    if (is_session_locked ()) {
      $log->dbug ('Received UNBLANK while session is still locked; skipping unlock');
      next;
    }

    $log->msg ('Unlocked screen');
    $locked = 0;

    my $cmd = '/opt/clearscm/bin/settheme';
    $log->dbug ("Calling $cmd");
    system $cmd;
  } # if
} # while
