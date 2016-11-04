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
and finally telnet. Username and password can be suppliec (or set up ssh 
pre-shared key) to log in. This is especially important when ssh'ing into
Windows machines using Cygwin and wanting to use network resources. If you ssh
into a Windows box using pre-shared key then Windows will not have your 
password and it needs it to authenticate your user to determine access to remote
file systems. Therefore on Windows machines, do not set up preshared key if you
wish to access remotely mounted file systems. Instead supply the username and 
password (hopefully in a secure manner).

=cut

use FindBin;
use Getopt::Long;
use Pod::Usage;
use Term::ANSIColor qw(:constants);
use POSIX ":sys_wait_h";

use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../clearadm/lib";

use Display;
use Logger;
use Rexec;

my ($currentHost, $skip, $log);

my %opts = (
  usage    => sub { pod2usage },
  help     => sub { pod2usage (-verbose => 2)},
  verbose  => sub { set_verbose },
  debug    => sub { set_debug },
  username => $ENV{REXEC_USER} ? $ENV{REXEC_USER} : $ENV{USER},
  password => $ENV{REXEC_PASSWD},
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
  'machines=s@',
) or pod2usage;

$opts{debug}   = get_debug   if ref $opts{debug}   eq 'CODE';
$opts{verbose} = get_verbose if ref $opts{verbose} eq 'CODE';

my $cmd = join ' ', @ARGV;

unless ($opts{machines}) {
  $opts{machines} = [$ENV{REXEC_HOST}] if $ENV{REXEC_HOST};
} # unless

pod2usage 'Must specify -machines to run on' unless $opts{machines};

my @machines;

push @machines, (split /,/, join (',', $_)) for (@{$opts{machines}}); 

$opts{machines} = [@machines];

my ($status, @lines);

for my $machine (@{$opts{machines}}) {
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
      while () {
        display_nolf BOLD . YELLOW . "$machine:" . RESET . WHITE;

        $cmd = <STDIN>; 

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