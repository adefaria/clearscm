=pod

=head1 NAME $RCSfile: CCDBService.pm,v $

CCDBService - ClearCase DataBase Service

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.6 $

=item Created

Fri Mar 11 15:37:34 PST 2011

=item Modified

$Date: 2011/05/05 18:41:44 $

=back

=head1 SYNOPSIS

Provides an interface to the CCDB object over the netwok. This is useful as 
neither ccperl nor cqperl have DBI installed so if clients want to talk to an
SQL database such as MySQL they generally can't.

This library implements both the daemon portion of the server and the client 
API.

=head1 DESCRIPTION

This client/server process (ccdbc and ccdbd) serves only an informational 
purpose. By that I mean the client can request information as described below
but it cannot request to add/delete or update information. In other words the
client has read only access.

The caller makes requests in the form of:

 <method> <parms>

Different methods will return different values. See CCDB.pm. 

=head1 ROUTINES

The following methods are available:

=cut

package CCDBService;

use strict;
use warnings;

use Carp;
use FindBin;
use IO::Socket;
use Net::hostent;
use POSIX ":sys_wait_h";

use lib "$FindBin::Bin/../../lib";

use DateUtils;
use Display;
use GetConfig;

# Seed options from config file
our %OPTS = GetConfig ("$FindBin::Bin/../etc/ccdbservice.conf");

our $VERSION  = '$Revision: 1.6 $';
   ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);
   
# Override options if in the environment
$OPTS{CCDB_HOST}          = $ENV{CCDB_HOST}
  if $ENV{CCDB_HOST};
$OPTS{CCDB_PORT}          = $ENV{CCDB_PORT}
  if $ENV{CCDB_PORT};
$OPTS{CCDB_MULTITHREADED} = $ENV{CCDB_MULTITHREADED}
  if $ENV{CCDB_MULTITHREADED};

sub new () {
  my ($class) = @_;

  my $ccdbservice = bless {}, $class;

  $ccdbservice->{multithreaded} = $OPTS{CCDB_MULTITHREADED};

  return $ccdbservice;
} # new

sub _tag ($) {
  my ($self, $msg) = @_;

  my $tag  = YMDHMS;
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

sub _funeral () {
  debug 'Entered _funeral';

  while (my $childpid = waitpid (-1, WNOHANG) > 0) {
    my $status = $?;
  
    debug "childpid: $childpid - status: $status";
  
    if ($childpid != -1) {
      local $SIG{CHLD} = \&_funeral;

      my $msg  = 'Child has died';
         $msg .= $status ? " with status $status" : '';

      verbose "[$childpid] $msg"
        if $status;
    } else {
      debug "All children reaped";
    } # if
  } # while
  
  return;
} # _funeral

sub _endServer () {
  display "CCDBService V$VERSION shutdown at " . localtime;
  
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

  $host ||= $OPTS{CCDB_HOST};
  $port ||= $OPTS{CCDB_PORT};
  
  $self->{socket} = IO::Socket::INET->new (
    Proto       => 'tcp',
    PeerAddr    => $host,
    PeerPort    => $port,
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

sub _serviceClient ($$) {
  my ($self, $host, $client) = @_;

  $self->_verbose ("Serving requests from $host");

  # Set autoflush for client
  $client->autoflush
    if $client;
    
  my $ccdb = CCDB->new;

  while () {
    # Read command from client
    my $cmd = <$client>;
	
    last unless $cmd;
	
    chomp $cmd;
	
    next if $cmd eq '';

    last if $cmd =~ /^quit|^exit/i;

    $self->_debug ("$host wants us to do $cmd");
	
    my $status = 0;
    my ($method, $rec, @keys, @values);

    if ($cmd =~ /stopserver/i) {
      if ($self->{server}) {
        $self->_verbose ("$host requested to stop server [$self->{server}]");
	  	
        # Send server hangup signal
        kill 'HUP', $self->{server};
      } else {
        $self->_verbose ('Shutting down server');
        
        print $client "CCDBService Status: 0\n";
        
        exit;
      } # if
	  
      $self->_debug ("Returning 0, undef");
    } else {
      # Parse command
      @values = split /[^\S]+/, $cmd;
      
      if (@values < 2) {
        print $client "ERROR: I don't understand the command: $cmd\n";
        print $client "Request must be of the form: <method> <parms>\n";
        print $client "CCDB Status: 1\n";
        next;
      } # if
      
      $method = shift @values;
      
      my $values = join ' ', @values;
      
      unless (
         $method =~ /^get/i
      or $method =~ /^find/i
      or $method =~ /^add/i
      or $method =~ /^delete/i
      or $method =~ /^update/i) {
        print $client "I only understand get, find, add, delete and ";
        print $client "update operations ";
        print $client "- not '$method'\n";
        print $client "CCDB Status: 1\n";
        next;
      } # unless
      
      $self->_debug ("Executing CCDB::$method");

      my (%rec, @recs);
     
      if ($method =~ /^get/i) {
        eval {
          %rec = $ccdb->$method (@values);
        }; # eval
    
        if ($@) {
          print $client "$@\n";
          print $client "CCDB Status: 1\n";
          next;
        } else {
          $rec = \%rec;
        } # if
      } elsif ($method =~ /^find/i) {
        eval {
          @recs = $ccdb->$method (@values);
        }; # eval
    
        if ($@) {
          print $client "$@\n";
          print $client "CCDB Status: 1\n";
          next;
        } else {
          $rec = \@recs;
        } # if
      } elsif ($method =~ /^add/i) {
        my ($err, $msg);
        
        eval {
          ($err, $msg) = $ccdb->$method ($values);
        }; # eval
        
        if ($@) {
          print $client "$@\n";
          print $client "CCDB Status: 1\n";
          next;
        } else {
          $msg = "Success"
            if $msg eq '';
          $rec = "Err:$err;Msg:$msg";
        } # if
      } elsif ($method =~ /^update/i) {
        # Updates are tricky because there is an unknown number of parms then
        # a hash. We will look for $VAR1 in the @values array and if we find
        # that then that is the start of the hash.
        my @parms;
        
        # Since we're gonna shift off of @values we don't want to use $#values
        # in the for loop because it's value is dynamic and will change.
        my $valuesSize = $#values;
        
        # Shift off each parm into @parms until we find $VAR1
        for (my $i = 0; $i < $valuesSize; $i++) {
          last if $values[0] =~ /^\$VAR1/;
          
          push @parms, shift @values;
        } # for
        
        # Now just join the rest of the @values together
        push @parms, join ' ', @values;
        
        my ($err, $msg);
        
        eval {
          ($err, $msg) = $ccdb->$method (@parms);
        }; # eval
        
        if ($@) {
          print $client "$@\n";
          print $client "CCDB Status: 1\n";
          next;
        } else {
          $msg = "Success"
            if $msg eq '';
          $rec = "Err:$err;Msg:$msg";
        } # if
      } elsif ($method =~ /^delete/i) {
        my ($err, $msg);
        
        eval {
          ($err, $msg) = $ccdb->$method (@values);
        }; # eval
    
        if ($@) {
          print $client "$@\n";
          print $client "CCDB Status: 1\n";
          next;
        } else {
          # A little messy here. Normally a delete method returns the number of
          # records deleted as its status. But the caller will sense non-zero as
          # an error. So if the $msg simply says 'Records deleted' then we flip
          # the $err to 0.
          $err = 0
            if $msg eq 'Records deleted';
          
          $rec = "Err:$err;Msg:$msg";
        } # if
      } # if
    } # if
    
    if (ref $rec eq 'HASH') {
      if (%$rec) {
        foreach (keys %$rec) {
          $self->_debug ("Get: Found record");
        
          my $data  = "$_~";
             $data .= $$rec{$_} ? $$rec{$_} : '';
           
          print $client "$data\n";
        } # foreach
        
        print $client "CCDB Status: 0\n";
      } else {        
        $self->_debug ("Get: No record found");
        
        print $client "CCDB::$method: No record found\n";
        print $client "CCDB Status: 1\n";
      } # if
    } elsif (ref $rec eq 'ARRAY') {
      if (@$rec > 0) {
        $self->_debug ("Find: Records found: " . scalar @$rec);
        
        foreach my $entry (@$rec) {
          my %rec = %$entry;
          
          print $client '-' x 80 . "\n";
          
          foreach (keys %rec) {
            my $data  = "$_~";
               $data .= $rec{$_} ? $rec{$_} : '';

            print $client "$data\n";
          } # foreach
        } # foreach

        print $client '=' x 80 . "\n";
        print $client "CCDB Status: 0\n";
      } else {
        $self->_debug ("Find: Records not found");
        
        print $client "CCDB::$method: No records found\n";
        print $client "CCDB Status: 1\n";
      } # if
    } elsif (ref \$rec eq 'SCALAR') {
      my ($err, $msg);
      
      if ($rec =~ /Err:(-*\d+);Msg:(.*)/ms) {
        $err = $1;
        $msg = $2;
      } # if
        
      print $client "$msg\n"
        if $msg;
      print $client "CCDB Status: $err\n";
    } # if
    
    $self->_debug ("Looping around for next command");
  } # while
  
  close $client;
  
  $self->_verbose ("Serviced requests from $host");
  
  return;
}  # _serviceClient

sub execute ($) {
  my ($self, $request) = @_;
  
  return (-1, 'Unable to talk to server')
    unless $self->{socket};
  
  my ($status, @output) = (-1, ());
  
  my $server = $self->{socket};
  
  print $server "$request\n";

  my $response;
  
  while (defined ($response = <$server>)) {
    if ($response =~ /CCDB Status: (-*\d+)/) {
      $status = $1;
      last;
    } # if
    
    push @output, $response;
  } # while
  
  chomp @output;
  
  my (@recs, $output);

  return ($status, \@output)
    if $status;

  if ($output[0] eq '-' x 80) {
    shift @output;
    
    while ($_ = shift @output) {
      last if $_ eq '=' x 80;

      my %rec;
      
      while ($_) {
        last if $_ eq '-' x 80;

        if (/^(\S+)~(.*)$/) {
          $rec{$1} = $2;
        } # if

        $_ = shift @output;
      } # while
      
      push @recs, \%rec;
    } # while

    $output = \@recs;
  } else {
    my %rec;
    
    foreach (@output) {
      if (/^(\S+):(.*)$/) {
        $rec{$1} = $2;
      } # if
    } # foreach
    
    $output = \%rec;
  } # if
  
  return ($status, $output);
} # execute

sub startServer (;$) {
  my ($self, $port) = @_;

  $port ||= $OPTS{CCDB_PORT};

  # Create new socket to communicate to clients with
  $self->{socket} = IO::Socket::INET->new(
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
  LOOP:
  my $client;

  while ($client = $self->{socket}->accept) {
    my $hostinfo = gethostbyaddr $client->peeraddr;
    my $host     = $hostinfo ? $hostinfo->name : $client->peerhost;

    $self->_verbose ("$host is requesting service");

    if ($self->getMultithreaded) {
      $self->{server} = $$;

      my $childpid;

      $self->_debug ("Spawning child to handle request");

      error "Can't fork: $!"
        unless defined ($childpid = fork);
        
      if ($childpid) {
        $self->{pid} = $$;

        $SIG{CHLD} = \&_funeral;
        $SIG{HUP}  = \&_endServer;
        $SIG{USR2} = \&_restartServer;

        $self->_debug ("Parent produced child [$childpid]");
      } else {
        # In child process - ServiceClient
        $self->{pid} = $$;

        $self->_debug ("Calling _serviceClient");
        $self->_serviceClient ($host, $client);
        $self->_debug ("Returned from _serviceClient - exiting...");

        exit;
      } # if
    } else {
      $self->_serviceClient ($host, $client);
    } # if
  } # while

  # This works but I really don't like it. The parent should have looped back to
  # the while statement thus waiting for the next client. But it doesn't seem to
  # do that. Instead, when multithreaded, the child exits above and then the
  # parent breaks out of the while loop. I'm not sure why this is happening.
  # This goto fixes this up but it's sooooo ugly!
  goto LOOP;
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

L<POSIX>

=head2 ClearSCM Perl Modules

=begin man 

 DateUtils
 Display
 GetConfig

=end man

=begin html

<blockquote>
<a href="http://clearscm.com/php/scm_man.php?file=lib/DateUtils.pm">DateUtils</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Display.pm">Display</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/GetConfig.pm">GetConf</a><br>
</blockquote>

=end html

=head1 SEE ALSO

=begin man

See also: CCDB

=end man

=begin html

<blockquote>
<a href="http://clearscm.com/php/scm_man.php?file=CCDB/lib/CCDB.pm">CCDB</a><br>
</blockquote>

=end html

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011, ClearSCM, Inc. All rights reserved.

=cut
