#!/usr/bin/perl

=pod

=head1 NAME $RCSfile: tunnel.pl,v $

Set up a tunnel for emailing

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision:

$Revision: 1.0 $

=item Created:

Wed 19 Aug 2020 09:09:09 AM MST

=item Modified:

$Date: $

=back

=head1 SYNOPSIS

 Usage: tunnel.pl [-u|sage] [-h|elp] [-ve|rbose] [-d|ebug]
 
 Where:

 -u|sage:      Displays this usage
 -h|elp:       Display full help
 -ve|rbose:    Be verbose
 -d|ebug:      Output debug messages
 -host1:       First host for tunnel (Default: localhost)
 -port1:       Port for host1
 -host2:       Second host for tunnel (Default: defaria.com)
 -port2:       Port for host2
 -a|nnounce:   Whether to announce startup (Default false)
 -maxtretries: Maximum number of retry attempt to reestablish tunnel
               (Default 3)
 -nodaemon:    Whether to go into daemon mode (Default: Daemon mode)

=head1 DESCRIPTION

This script sets up an SSH tunnel for the purposes of emailing.

=cut

use strict;
use warnings;

use File::Temp qw(tempfile);
use FindBin;
use Getopt::Long;
use Net::OpenSSH;
use POSIX ':sys_wait_h';

use lib "$FindBin::Bin/../lib";

use Pod::Usage;

use Display;
use Logger;
use Utils;

my $VERSION  = '$Revision: 1.0 $';
  ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);

my %opts = (
  usage      => sub { pod2usage },
  help       => sub { pod2usage (-verbose => 2)},
  verbose    => sub { set_verbose },
  debug      => sub { set_debug },
  host1      => 'localhost',
  port1      => 1025,
  host2      => 'defaria.com',
  port2      => 25,
  remotehost => 'defaria.com',
  maxretries => 3,
  daemon     => 1,
);

my ($log, $ssh);

sub Say($) {
  my ($msg) = @_;

  if (-f "$FindBin::Bin/shh") {
    $log->msg("Not speaking because we were asked to be quiet - $msg");

    return;
  } # if

  my ($status, @output) = Execute "/usr/local/bin/gt \"$msg\"";

  $log->err("Unable to speak (Status: $status) - "
          . join ("\n", @output), $status) if $status;

  return;
} # Say

sub Report ($;$) {
  my ($msg, $err) = @_;

  Say $msg;

  if ($err) {
    $log->err($msg, $err);
  } else {
    $log->err($msg);
  } # if

  return;
} # Report

sub interrupt {
   Report "Tunnel killed unexpectedly", 1;

   kill 'INT', $ssh->get_master_pid;
} # interrupt

sub tunnel() {
  my $tunnelStr = "-NL$opts{host1}:$opts{port1}:$opts{host2}:$opts{port2}";

  my $retryattempts = 0;

RETRY:
  my ($fh, $filename) = tempfile;

  my $ssh = Net::OpenSSH->new(
    $opts{remotehost},
    master_opts         => $tunnelStr,
    default_stderr_file => $filename
  );

  Report("Unable to establish ssh tunnel " . $ssh->error, 1) if $ssh->error;

  my @lines = <$fh>;

  close $fh;

  unlink $filename;

  if (grep /address already in use/i, @lines) {
    Report 'Unable to start tunnel - Address already in use', 1;
  } else {
    my $msg  = 'Ssh tunnel ';
       $msg .= $retryattempts ? 'reestablished' : 'established';

    Say $msg if $opts{announce};

    $log->msg($msg);

    # Wait for master to exit
    waitpid($ssh->get_master_pid, WUNTRACED);

    Report("Ssh tunnel terminated unexpectedly - Maximum retry count hit ($opts{maxretries}) - giving up", 1)
      if $retryattempts++ >= $opts{maxretries};

    $opts{announce} = $retryattempts;

    Report 'Ssh tunnel terminated unexpectedly - Attempting restart';

    goto RETRY;
  } # if

  return;
} # tunnel

## Main
GetOptions (
  \%opts,
  'usage',
  'help',
  'verbose',
  'debug',
  'host1',
  'host2',
  'port1',
  'port2',
  'announce!',
  'maxretries=i',
  'daemon!',
) || Usage;

# Turn off daemon mode if we are in the Perl debugger;
no warnings; # Ignore warning about used only once $DB::OUT when not in debugger
$opts{daemon} = 0 if defined $DB::OUT;
use warnings;

$log = Logger->new(
  path        => '/var/log',
  name        => "$Logger::me",
  timestamped => 'yes',
  append      => 'yes',
);

$log->msg("$FindBin::Script v$VERSION");

$SIG{INT} = $SIG{TERM} = \&interrupt;

EnterDaemonMode if $opts{daemon};

tunnel;
