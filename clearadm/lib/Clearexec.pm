=pod

=head1 NAME $RCSfile: Clearexec.pm,v $

Clearexec - Execute remote commands locally

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.18 $

=item Created

Tue Dec 07 09:13:27 EST 2010

=item Modified

$Date: 2012/12/16 18:00:16 $

=back

=head1 SYNOPSIS

Provides an interface to the Clearexec object. Clearexec is a daemon that runs
on a host and accepts requests to execute commands locally and send the results
back to the caller.

=head1 DESCRIPTION

The results are sent back as follows:

 Status: <status>
 <command output>
 
This allows the caller to determine if the command execution was successful as
well as capture the commands output.

=head1 ROUTINES

The following methods are available:

=cut

package Clearexec;

use strict;
use warnings;

use Carp;
use FindBin;
use IO::Socket;
use Net::hostent;
use POSIX qw(:sys_wait_h);
use Errno;

use lib "$FindBin::Bin/../../lib";

use DateUtils;
use Display;
use GetConfig;
use Utils;

# Seed options from config file
our %CLEAROPTS = GetConfig ("$FindBin::Bin/etc/clearexec.conf");

our $VERSION = '$Revision: 1.18 $';
($VERSION) = ($VERSION =~ /\$Revision: (.*) /);

# Override options if in the environment
$CLEAROPTS{CLEAREXEC_HOST} = $ENV{CLEAREXEC_HOST}
  if $ENV{CLEAREXEC_HOST};
$CLEAROPTS{CLEAREXEC_PORT} = $ENV{CLEAREXEC_PORT}
  if $ENV{CLEAREXEC_PORT};
$CLEAROPTS{CLEAREXEC_MULTITHREADED} = $ENV{CLEAREXEC_MULTITHREADED}
  if $ENV{CLEAREXEC_MULTITHREADED};

sub new () {
  my ($class) = @_;

  my $clearadm = bless {}, $class;

  $clearadm->{multithreaded} = $CLEAROPTS{CLEAREXEC_MULTITHREADED};

  return $clearadm;
} # new

sub _tag ($) {
  my ($self, $msg) = @_;

  my $tag = YMDHMS;
  $tag .= ' ';
  $tag .= $self->{pid} ? "[$self->{pid}] " : '';

  return "$tag$msg";
} # _tag

sub _verbose ($) {
  my ($self, $msg) = @_;

  verbose $self->_tag ($msg);

  return;
} # _verbose

sub _debug ($) {
  my ($self, $msg) = @_;

  debug $self->_tag ($msg);

  return;
} # _debug

sub _log ($) {
  my ($self, $msg) = @_;

  display $self->_tag ($msg);

  return;
} # log

sub _endServer () {
  display "Clearexec V$VERSION shutdown at " . localtime;

  # Kill process group
  kill 'TERM', -$$;

  # Wait for all children to die
  while (wait != -1) {

    # do nothing
  } # while

  # Now that we are alone, we can simply exit
  exit;
} # _endServer

sub _restartServer () {

  # Not sure what to do on a restart server
  display 'Entered _restartServer';

  return;
} # _restartServer

sub setMultithreaded ($) {
  my ($self, $value) = @_;

  my $oldValue = $self->{multithreaded};

  $self->{multithreaded} = $value;

  return $oldValue;
} # setMultithreaded

sub getMultithreaded () {
  my ($self) = @_;

  return $self->{multithreaded};
} # getMultithreaded

sub connectToServer (;$$) {
  my ($self, $host, $port) = @_;

  $host ||= $CLEAROPTS{CLEAREXEC_HOST};
  $port ||= $CLEAROPTS{CLEAREXEC_PORT};

  $self->{socket} = IO::Socket::INET->new (
    Proto    => 'tcp',
    PeerAddr => $host,
    PeerPort => $port,
  );

  return unless $self->{socket};

  $self->{socket}->autoflush
    if $self->{socket};

  $self->{host} = $host;
  $self->{port} = $port;

  if ($self->{socket}) {
    return 1;
  } else {
    return;
  } # if

  return;
} # connectToServer

sub disconnectFromServer () {
  my ($self) = @_;

  undef $self->{socket};

  return;
} # disconnectFromServer

sub execute ($) {
  my ($self, $cmd) = @_;

  return (-1, 'Unable to talk to server')
    unless $self->{socket};

  my ($status, $statusLine, @output) = (-1, '', ());

  my $server = $self->{socket};

  print $server "$cmd\n";

  my $response;

  while (defined ($response = <$server>)) {
    if ($response =~ /Clearexec Status: (-*\d+)/) {
      $status = $1;
      last;
    } # if

    push @output, $response;
  } # while

  chomp @output;

  return ($status, @output);
} # execute

sub _serviceClient ($$) {
  my ($self, $host, $client) = @_;

  $self->_verbose ("Serving requests from $host");

  # Set autoflush for client
  $client->autoflush
    if $client;

  while () {
    # Read command from client
    my $cmd = <$client>;

    last unless $cmd;

    chomp $cmd;

    next if $cmd eq '';

    last if $cmd =~ /quit|exit/i;

    $self->_debug ("$host wants us to do $cmd");

    my ($status, @output);

    $status = 0;

    if ($cmd =~ /stopserver/i) {
      if ($self->{server}) {
        $self->_verbose ("$host requested to stop server [$self->{server}]");

        # Send server hangup signal
        kill 'HUP', $self->{server};
      } else {
        $self->_verbose ('Shutting down server');

        print $client "Clearexec Status: 0\n";

        exit;
      } # if

      $self->_debug ("Returning 0, undef");
    } else {
      # Combines STDERR -> STDOUT if not already specified
      $cmd .= ' 2>&1'
        unless $cmd =~ /2>&1/;

      $self->_debug ("Executing $cmd");
      ($status, @output) = Execute $cmd;
      $self->_debug ("Status: $status");
    } # if

    print $client "$_\n" foreach (@output);
    print $client "Clearexec Status: $status\n";

    $self->_debug ("Looping around for next command");
  } # while

  close $client;

  $self->_verbose ("Serviced requests from $host");

  return;
} # _serviceClient

sub startServer (;$) {
  my ($self, $port) = @_;

  $port ||= $CLEAROPTS{CLEAREXEC_PORT};

  # Create new socket to communicate to clients with
  $self->{socket} = IO::Socket::INET->new (
    Proto     => 'tcp',
    LocalPort => $port,
    Listen    => SOMAXCONN,
    Reuse     => 1
  );

  error "Could not create socket - $!", 1
    unless $self->{socket};

  # Announce ourselves
  $self->_log ("Clearexec V$VERSION accepting clients at " . localtime);

  # Now wait for an incoming request
  my $client;

  while () {
    $client = $self->{socket}->accept;
    
    if ($? == -1) {
      if ($!{EINTR}) {
        next;
      } else {
        error "Accept called failed (Error: $?) - $!", 1;
      } # if
    } # if

    my $hostinfo = gethostbyaddr $client->peeraddr;
    my $host = $hostinfo->name || $client->peerhost;

    $self->_verbose ("$host is requesting service");

    if ($self->getMultithreaded) {
      $self->{server} = $$;

      my $childpid;

      $self->_debug ("Spawning child to handle request");

      error "Can't fork: $!"
        unless defined ($childpid = fork);

      if ($childpid) {
        $self->{pid} = $$;

        # On Unix/Linux, setting SIGCHLD to ignore auto reaps dead children.
        $SIG{CHLD} = "IGNORE";
        $SIG{HUP}  = \&_endServer;
        $SIG{USR2} = \&_restartServer;

        $self->_debug ("Parent produced child [$childpid]");
      } else {
        # In child process - ServiceClient
        $self->{pid} = $$;

        $self->_debug         ("Calling _serviceClient");
        $self->_serviceClient ($host, $client);
        $self->_debug         ("Returned from _serviceClient - exiting...");

        exit;
      } # if
    } else {
      $self->_serviceClient ($host, $client);
    } # if
  } # while
} # startServer

1;

=pod

=head1 CONFIGURATION AND ENVIRONMENT

DEBUG: If set then $debug is set to this level.

VERBOSE: If set then $verbose is set to this level.

TRACE: If set then $trace is set to this level.

=head1 DEPENDENCIES

=head2 Perl Modules

L<Carp>

L<FindBin>

L<IO::Socket|IO::Socket>

L<Net::hostent|Net::hostent>

=head2 ClearSCM Perl Modules

=begin man 

 DateUtils
 Display
 GetConfig

=end man

=begin html

<blockquote>
<a href="http://clearscm.com/php/scm_man.php?file=lib/DateUtils.pm">Display</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Display.pm">Display</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/GetConfig.pm">GetConf</a><br>
</blockquote>

=end html

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, ClearSCM, Inc. All rights reserved.

=cut
