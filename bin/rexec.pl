#!/usr/bin/perl
use strict;
use warnings;

=pod

=head1 NAME $RCSfile: rexec.pl,v $

Run arbitrary command on another machine

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.0 $

=item Created:

Tue Jan  8 15:57:27 MST 2008

=item Modified:

$Date: 2008/02/29 15:09:15 $

=back

=head1 SYNOPSIS

 Usage: rexec.pl [-usa|ge] [-h|elp] [-v|erbose] [-d|ebug]
                 [-use|rname <username>] [-p|assword <password>]
                 [-log]
                 -m|achines <host1>,<host2>,...

              <command>

 Where:
   -usa|ge:    Print this usage
   -h|elp:     Print detailed usage
   -v|erbose:  Verbose mode
   -d|ebug:    Print debug messages
   -use|rname: User name to login as (Default: $USER - Env: REXEC_USER)
   -p|assword: Password to use (Default: None - Env: REXEC_PASSWD)
   -m|achines: Machine(s) to run the command on
   -l|og:      Log output (<machine>.log)

   <command>:  Commands to execute (Enclose multiple commands in quotes)

=head1 DESCRIPTION

This script will perform and arbitrary command on a set of machines. It uses the
Rexec module which utilizes Perl::Expect to attempt a connection using ssh, rsh
and finally telnet. Username and password can be supplied (or set up ssh 
pre-shared key) to log in. This is especially important when ssh'ing into
Windows machines using Cygwin and wanting to use network resources. If you ssh
into a Windows box using pre-shared key then Windows will not have your 
password and it needs it to authenticate your user to determine access to remote
file systems. Therefore on Windows machines, do not set up preshared key if you
wish to access remotely mounted file systems. Instead supply the username and 
password (hopefully in a secure manner).

Machines:

The list of machines that will be operated on can be specified in the machines
option but is more often obtained using a Machines module. The default Machines
module will parse a flat file that lists machine names and the characteristics
of those machines (OS version, CPU count, owner - See Machines.pm). If a
different mechanism is used to store and retrieve machine information then the
use can write a replacement for the Machines module. This replacement must
present an object oriented approach at supplying the qualifying machines by
supporting the following methods:

new: Create new Machines object

find: Find machines based on a specified condition (e.g. OS = "Ubuntu 18.04")

next: Return the next qualifying machine

Logging and reruning:

If -log is specified then a directory will be created based on the machine's
name in -logdir (default current directory) where all output will be written to 
a log file named $machine/$machine.log. The command attempted will be written to
$machine/command and the status will be written to $machine/status. If instead
the we were not able to connect to the remote machine, often because the machine
was down, then the $machine directory will only have the command file indicating
that the command was not run on the remote machine. This allows the -restart
parameter to work. When run with -restart, rexec will exam all log directories
to see which ones only contain a command file and attempt to execute them on
$machine again.

=cut

use FindBin;
use Getopt::Long;
use Pod::Usage;
use Term::ANSIColor qw(:constants);
use POSIX ":sys_wait_h";

use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../clearadm/lib";

use CmdLine;
use Display;
use Logger;
use Rexec;
use Machines;

my ($currentHost, $log);

my %opts = (
  usage    => sub { pod2usage },
  help     => sub { pod2usage (-verbose => 2)},
  verbose  => sub { set_verbose },
  debug    => sub { set_debug },
  username => $ENV{REXEC_USER} || $ENV{USER},
  password => $ENV{REXEC_PASSWD},
  filename => $ENV{REXEC_MACHINES_FILE} || '/opt/clearscm/data/machines',
);

sub Interrupted {
  use Term::ReadKey;

  display BLUE . "\nInterrupted execution on $currentHost->{host}" . RESET;

  display_nolf "Executing on " . YELLOW . $currentHost->{host}  . RESET . " - "
    . CYAN      . BOLD . "C" . RESET . CYAN     . "ontinue"     . RESET . " or "
    . MAGENTA   . BOLD . "A" . RESET . MAGENTA  . "bort run"    . RESET . " ("
    . CYAN      . BOLD . "C" . RESET . "/"
    . MAGENTA   . BOLD . "a" . RESET . ")?";

  ReadMode ("cbreak");
  my $answer = ReadKey (0);
  ReadMode ("normal");

  if ($answer eq "\n") {
    display "c";
  } else {
    display $answer;
  } # if

  $answer = lc $answer;

  if ($answer eq "s") {
    *STDOUT->flush;
    display "Skipping $currentHost->{host}";
  } elsif ($answer eq "a") {
    display RED . "Aborting run". RESET;
    exit;
  } else {
    display "Continuing...";
  } # if

  return;
} # Interrupted

sub connectHost ($) {
  my ($host) = @_;

  # Start a log...
  $log = Logger->new (name => $host) if $opts{log};

  eval {
    $currentHost = Rexec->new (
      host     => $host,
      username => $opts{username},
      password => $opts{password},
    );
  };

  # Problem with creating Rexec object. Log error if logging and return.
  if ($@ || !$currentHost) {
    if ($opts{log}) {
      $log->err ("Unable to connect to $host") if $opts{log};
    } else {
      display RED . 'ERROR:' . RESET . " Unable to connect";
    } # if
  } # if

  return;
} # connectHost

sub execute ($$;$) {
  my ($host, $cmd, $prompt) = @_;

  my @lines;

  verbose_nolf "Connecting to machine $host...";

  display_nolf BOLD . YELLOW . "$host:" . RESET if $opts{verbose};

  connectHost $host unless $currentHost and $currentHost->{host} eq $host;

  return (1, ()) unless $currentHost;

  verbose " connected";

  display WHITE . UNDERLINE . "$cmd" . RESET if $opts{verbose};

  @lines = $currentHost->execute ($cmd);

  verbose "Disconnected from $host";

  my $status = $currentHost->status;

  return ($status, @lines);
} # execute

$SIG{INT} = \&Interrupted;

# Get our options
GetOptions (
  \%opts,
  'usage',
  'help',
  'verbose',
  'debug',
  'username=s',
  'password=s',
  'log',
  'logdir',
  'filename=s',
  'database',
  'machines=s@',
) or pod2usage;

$opts{debug}   = get_debug   if ref $opts{debug}   eq 'CODE';
$opts{verbose} = get_verbose if ref $opts{verbose} eq 'CODE';

my $cmd = join ' ', @ARGV;

unless ($opts{machines}) {
  $opts{machines} = [$ENV{REXEC_HOST}] if $ENV{REXEC_HOST};
} # unless

# Connect to Machines module
my $machines;

unless ($opts{database}) {
  require Machines; Machines->import;

  $machines = Machines->new(filename => $opts{filename});
} else {
  require Machines::MySQL; Machines::MySQL->import;

  $machines = Machines::MySQL->new;
} # if

my %machines = $machines->select;

my ($status, @lines);

for my $machine (sort keys %machines) {
  if ($cmd) {
    ($status, @lines) = execute $machine, $cmd;

    display BOLD . YELLOW . "$machine:" . RESET . WHITE . $cmd;

    error "Execution of $cmd on $machine yielded error $status" if $status;

    display $_ for @lines;

    undef $currentHost;
  } else {
    verbose_nolf "Connecting to machine $machine...";

    connectHost $machine;

    if ($currentHost) {
      my $cmdline = CmdLine->new ();

      $cmdline->set_prompt (BOLD . YELLOW . "$machine:" . RESET . WHITE);

      while () {
        #$cmd = <STDIN>;
        $cmd = $cmdline->get(); 

        unless ($cmd) {
          display '';
          last;
        } # unless

        last if $cmd =~ /^\s*(exit|quit)\s*$/i;
        next if $cmd =~ /^\s*$/;

        chomp $cmd;

        ($status, @lines) = execute $machine, $cmd;

        error "Execution of $cmd on $machine yielded error $status" if $status;

        display $_ for @lines;
      } # while
    } # if
  } # if
} # for
