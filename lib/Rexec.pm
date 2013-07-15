=pod                                                                                    
                                                                                        
=head1 NAME $RCSfile: Rexec.pm,v $                                                      
                                                                                        
Execute commands remotely and returning the output and status of the                    
remotely executed command.                                                              
                                                                                        
=head1 VERSION                                                                          
                                                                                        
=over                                                                                   
                                                                                        
=item Author:                                                                           
                                                                                        
Andrew DeFaria <Andrew@ClearSCM.com>                                                    
                                                                                        
=item Revision:                                                                         
                                                                                        
$Revision: 1.21 $                                                                       
                                                                                        
=item Created:                                                                          
                                                                                        
Mon Oct  9 18:28:28 CDT 2006                                                            
                                                                                        
=item Modified:                                                                         
                                                                                        
$Date: 2012/04/07 00:39:48 $                                                            
                                                                                        
=back                                                                                   
                                                                                        
=head1 SYNOPSIS                                                                         
                                                                                        
  use Rexec;                                                                            
                                                                                        
  my $status;                                                                           
  my $cmd;                                                                              
  my @lines;                                                                            
                                                                                        
  my $remote = new Rexec (host => $host);                                               
                                                                                        
  if ($remote) {                                                                        
    print "Connected using " . $remote->{protocol} . " protocol\n";                     
                                                                                        
    $cmd = "ls /tmp";                                                                   
    @lines = $remote->execute ($cmd);                                                   
    $status = $remote->status;                                                          
    print "$cmd status: $status\n";                                                     
    $remote->print_lines;                                                               
                                                                                        
    print "$_\n" foreach ($remote->execute ("cat /etc/passwd"));                        
  } else {                                                                              
    print "Unable to connect to $username\@$host\n";                                    
  } # if                                                                                
                                                                                        
=head1 DESCRIPTION                                                                      
                                                                                        
This module provides an object oriented interface to executing remote                   
commands on Linux/Unix system (or potentially well configured Windows                   
machines with Cygwin installed). Upon object creation a connection is                   
attempted to the specified host in a cascaded fashion. First ssh is                     
attempted, then rsh/rlogin and finally telnet. This clearly favors                      
secure methods over those less secure ones. If username or password is                  
prompted for, and if they are supplied, then they are used, otherwise                   
the attempted connection is considered failed.                                          
                                                                                        
Once connected the caller can use the exec method to execute commands                   
on the remote host. Upon object destruction the connection is                           
shutdown. Output from the remotely executed command is returned                         
through the exec method and also avaiable view the lines                                
method. Remote status is available via the status method. This means                    
you can now more reliably obtain the status of the command executed                     
remotely instead of just the status of the ssh/rsh command itself.                      
                                                                                        
Note: Currently no attempt has been made to differentiate output                        
written to stdout and stderr.                                                           
                                                                                        
As Expect is used to drive the remote session particular attention                      
should be defining a regex to locate the prompt. The standard prompt                    
regex (if not specified by the caller at object creation) is qr'[#>:$]                  
$'. This covers most default and common prompts.                                        
                                                                                        
=head1 Handling Timeouts                                                                
                                                                                        
The tricky thing when dealing with remote execution is attempting to                    
determine if the remote machine has finished, stopped responding or                     
otherwise crashed. It's more of an art than a science! The best one                     
can do it send the command along and wait for a response. But how long                  
to wait is the question. If your wait is too short then you run the                     
risk of timing out before the remote command is finished. If you wait                   
too long then you can be possibly waiting for something that will not                   
be happening because the remote machine is either down or did not                       
behave in a manner that you expected it to.                                             
                                                                                        
To a large extent this module attempts to mitigate these issues on the                  
principal that remote command execution is pretty well known. You log                   
in and get a prompt. Issue a command and get another prompt. If the                     
prompts are well known and easily determinable things go                                
smoothly. However what happens if you execute a command remotely that                   
will take 30 minutes to finish?                                                         
                                                                                        
This module has two timeout values. The first is login timeout. It's                    
assumed that logins should happen fairly quickly. The default timeout                   
for logins is 5 seconds.                                                                
                                                                                        
Command timeouts are set by default to 30 seconds. Most commands will                   
finish before then. If you expect a command to take much longer then                    
you can set an alternate timeout period.                                                
                                                                                        
You can achieve longer timeouts in several ways. To give a longer                       
login timeout specify your timeout to the new call. To give a longer                    
exec timeout either pass a longer timeout to exec or set it view                        
setTimeout. The current exec timeout is returned by getTimeout.                         
                                                                                        
=head1 METHODS                                                                          
                                                                                        
The following routines are exported:                                                    
                                                                                        
=cut                                                                                    
                                                                                        
package Rexec;                                                                          
                                                                                        
use strict;                                                                             
use warnings;                                                                           
                                                                                        
use base 'Exporter';                                                                    
                                                                                        
use Carp;                                                                               
use Expect;                                                                             
                                                                                        
our $VERSION = '1.0';                                                                   
                                                                                        
# This is the "normal" definition of a prompt. However what's normal?                   
# For example, my prompt it typically the machine name followed by a                    
# colon. But even that appears in error messages such as <host>: not                    
# found and will be mistaken for a prompt. No real good way to handle                   
# this so we define a standard prompt here and allow the caller to                      
# override that. But overriding it is tricky and left as an exercise                    
# to the caller.                                                                        
                                                                                        
# Here we have a number of the common prompt characters [#>:%$]                         
# followed by a space and end of line.                                                  
our $DEFAULT_PROMPT = qr'[#>:%$] $';                                                    
                                                                                        
my $default_login_timeout = 5;                                                          
my $default_exec_timeout  = 30;                                                         
                                                                                        
my $debug = $ENV{DEBUG} || 0;                                                           
                                                                                        
our @EXPORT = qw (                                                                      
  exec                                                                                  
  host                                                                                  
  lines                                                                                 
  login                                                                                 
  logout                                                                                
  new                                                                                   
  print_lines                                                                           
  status                                                                                
);                                                                                      
                                                                                        
my @lines;                                                                              
                                                                                        
sub ssh {                                                                               
  my ($self) = @_;                                                                      
                                                                                        
  my ($logged_in, $timedout, $password_attempts) = 0;                                   
                                                                                        
  $self->{protocol} = 'ssh';                                                            
                                                                                        
  my $user = $self->{username} ? "$self->{username}\@" : '';                            
                                                                                        
  my $remote = Expect->new ("ssh $self->{opts} $user$self->{host}");                    
                                                                                        
  return if !$remote;                                                                   
                                                                                        
  $remote->log_user ($debug);                                                           
                                                                                        
  $remote->expect (                                                                     
    $self->{timeout},                                                                   
                                                                                        
    # If password is prompted for, and if one has been specified, then                  
    # use it                                                                            
    [ qr "[P|p]assword: $",                                                             
      sub {                                                                             
        # If we already supplied the password then it must not have                     
        # worked so this protocol is no good.                                           
        return if $password_attempts;                                                   
                                                                                        
        my $exp = shift;                                                                
                                                                                        
        # If we're being prompted for password and there is no                          
        # password to supply then there is nothing much we can do but                   
        # return undef since we can't get in with this protocol                         
        return if !$self->{password};                                                   
                                                                                        
        $exp->send ("$self->{password}\n") if $self->{password};                        
        $password_attempts++;                                                           
                                                                                        
        exp_continue;                                                                   
      }                                                                                 
    ],                                                                                  
                                                                                        
    # Discard lines that begin with "ssh:" (like "ssh: <host>: not                      
    # found")                                                                           
    [ qr'\nssh: ',                                                                      
      sub {                                                                             
        return;                                                                         
      }                                                                                 
    ],                                                                                  
                                                                                        
    # If we find a prompt then everything's good                                        
    [ $self->{prompt},                                                                  
      sub {                                                                             
        $logged_in = 1;                                                                 
      }                                                                                 
    ],                                                                                  
                                                                                        
    # Of course we may time out...                                                      
    [ timeout =>                                                                        
      sub {                                                                             
        $timedout = 1;                                                                  
      }                                                                                 
    ],                                                                                  
  );                                                                                    
                                                                                        
  if ($logged_in) {                                                                     
    return $remote;                                                                     
  } elsif ($timedout) {                                                                 
    carp "WARNING: $self->{host} is not responding to $self->{protocol} protocol";      
    undef $remote;                                                                      
    return;                                                                             
  } else {                                                                              
    carp "WARNING: Unable to connect to $self->{host} using $self->{protocol} protocol";
    return;                                                                             
  } # if                                                                                
} # ssh                                                                                 
                                                                                        
sub rlogin {                                                                            
  my ($self) = @_;                                                                      
                                                                                        
  my ($logged_in, $timedout, $password_attempts) = 0;                                   
                                                                                        
  $self->{protocol} = "rlogin";                                                         
                                                                                        
  my $user = $self->{username} ? "-l $self->{username}" : "";                           
                                                                                        
  my $remote = Expect->new ("rsh $user $self->{host}");                                 
                                                                                        
  return if !$remote;                                                                   
                                                                                        
  $remote->log_user ($debug);                                                           
                                                                                        
  $remote->expect (                                                                     
    $self->{timeout},                                                                   
                                                                                        
    # If password is prompted for, and if one has been specified, then                  
    # use it                                                                            
    [ qr "[P|p]assword: $",                                                             
      sub {                                                                             
        # If we already supplied the password then it must not have                     
        # worked so this protocol is no good.                                           
        return if $password_attempts;                                                   
                                                                                        
        my $exp = shift;                                                                
                                                                                        
        # If we're being prompted for password and there is no                          
        # password to supply then there is nothing much we can do but                   
        # return undef since we can't get in with this protocol                         
        return if !$self->{password};                                                   
                                                                                        
        $exp->send ("$self->{password}\n");                                             
        $password_attempts++;                                                           
                                                                                        
        exp_continue;                                                                   
      }                                                                                 
    ],                                                                                  
                                                                                        
    # HACK! rlogin may return "<host>: unknown host" which clashes                      
    # with some prompts (OK it clashes with my prompt...)                               
    [ ": unknown host",                                                                 
      sub {                                                                             
        return;                                                                         
      }                                                                                 
    ],                                                                                  
                                                                                        
    # If we find a prompt then everything's good                                        
    [ $self->{prompt},                                                                  
      sub {                                                                             
        $logged_in = 1;                                                                 
      }                                                                                 
    ],                                                                                  
                                                                                        
    # Of course we may time out...                                                      
    [ timeout =>                                                                        
      sub {                                                                             
        $timedout = 1;                                                                  
      }                                                                                 
    ],                                                                                  
  );                                                                                    
                                                                                        
  if ($logged_in) {                                                                     
    return $remote;                                                                     
  } elsif ($timedout) {                                                                 
    carp "WARNING: $self->{host} is not responding to $self->{protocol} protocol";      
    undef $remote;                                                                      
    return;                                                                             
  } else {                                                                              
    carp "WARNING: Unable to connect to $self->{host} using $self->{protocol} protocol";
    return;                                                                             
  } # if                                                                                
} # rlogin                                                                              
                                                                                        
sub telnet {                                                                            
  my ($self) = @_;                                                                      
                                                                                        
  my ($logged_in, $timedout, $password_attempts) = 0;                                   
                                                                                        
  $self->{protocol} = "telnet";                                                         
                                                                                        
  my $remote = Expect->new ("telnet $self->{host}");                                    
                                                                                        
  return if !$remote;                                                                   
                                                                                        
  $remote->log_user ($debug);                                                           
                                                                                        
  $remote->expect (                                                                     
    $self->{timeout},                                                                   
                                                                                        
    # If login is prompted for, and if what has been specified, then                    
    # use it                                                                            
    [ qr "login: $",                                                                    
      sub {                                                                             
        my $exp = shift;                                                                
                                                                                        
        # If we're being prompted for username and there is no                          
        # username to supply then there is nothing much we can do but                   
        # return undef since we can't get in with this protocol                         
        return if !$self->{username};                                                   
                                                                                        
        $exp->send ("$self->{username}\n");                                             
        exp_continue;                                                                   
      }                                                                                 
    ],                                                                                  
                                                                                        
    # If password is prompted for, and if one has been specified, then                  
    # use it                                                                            
    [ qr "[P|p]assword: $",                                                             
      sub {                                                                             
        # If we already supplied the password then it must not have                     
        # worked so this protocol is no good.                                           
        return if $password_attempts;                                                   
                                                                                        
        my $exp = shift;                                                                
                                                                                        
        # If we're being prompted for password and there is no                          
        # password to supply then there is nothing much we can do but                   
        # return undef since we can't get in with this protocol                         
        return if !$self->{password};                                                   
                                                                                        
        $exp->send ("$self->{password}\n");                                             
        $password_attempts++;                                                           
                                                                                        
        exp_continue;                                                                   
      }                                                                                 
    ],                                                                                  
                                                                                        
    # HACK! rlogin may return "<host>: Unknown host" which clashes                      
    # with some prompts (OK it clashes with my prompt...)                               
    [ ": Unknown host",                                                                 
      sub {                                                                             
        return;                                                                         
      }                                                                                 
    ],                                                                                  
                                                                                        
    # If we find a prompt then everything's good                                        
    [ $self->{prompt},                                                                  
      sub {                                                                             
        $logged_in = 1;                                                                 
      }                                                                                 
    ],                                                                                  
                                                                                        
    # Of course we may time out...                                                      
    [ timeout =>                                                                        
      sub {                                                                             
        $timedout = 1;                                                                  
      }                                                                                 
    ],                                                                                  
  );                                                                                    
                                                                                        
  if ($logged_in) {                                                                     
    return $remote;                                                                     
  } elsif ($timedout) {                                                                 
    carp "WARNING: $self->{host} is not responding to $self->{protocol} protocol";      
    undef $remote;                                                                      
    return;                                                                             
  } else {                                                                              
    carp "WARNING: Unable to connect to $self->{host} using $self->{protocol} protocol";
    return;                                                                             
  } # if                                                                                
} # telnet                                                                              
                                                                                        
sub login () {                                                                          
  my ($self) = @_;                                                                      
                                                                                        
=pod                                                                                    
                                                                                        
=head2 login                                                                            
                                                                                        
Performs a login on the remote host. Normally this is done during                       
construction but this method allows you to login, say again, as maybe                   
another user...                                                                         
                                                                                        
Parameters:                                                                             
                                                                                        
=for html <blockquote>                                                                  
                                                                                        
=over                                                                                   
                                                                                        
=item None                                                                              
                                                                                        
=back                                                                                   
                                                                                        
=for html </blockquote>                                                                 
                                                                                        
Returns:                                                                                
                                                                                        
=for html <blockquote>                                                                  
                                                                                        
=over                                                                                   
                                                                                        
=item Nothing                                                                           
                                                                                        
=back                                                                                   
                                                                                        
=for html </blockquote>                                                                 
                                                                                        
=cut                                                                                    
                                                                                        
  # Close any prior opened sessions                                                     
  $self->logoff if ($self->{handle});                                                   
                                                                                        
  my $remote;                                                                           
                                                                                        
  if ($self->{protocol}) {                                                              
    if ($self->{protocol} eq "ssh") {                                                   
      return $self->ssh;                                                                
    } elsif ($self->{protocol} eq "rsh" or $self->{protocol} eq "rlogin") {             
      return $self->rlogin;                                                             
    } elsif ($self->{protocol} eq "telnet") {                                           
      return $self->telnet;                                                             
    } else {                                                                            
      croak "ERROR: Invalid protocol $self->{protocol} specified", 1;                   
    } # if                                                                              
  } else {                                                                              
    return $remote if $remote = $self->ssh;                                             
    return $remote if $remote = $self->rlogin;                                          
    return $self->telnet;                                                               
  } # if                                                                                
                                                                                        
  return;                                                                               
} # login                                                                               
                                                                                        
sub logoff {                                                                            
  my ($self) = @_;                                                                      
                                                                                        
=pod                                                                                    
                                                                                        
=head3 logoff                                                                           
                                                                                        
Performs a logout on the remote host. Normally handled in the                           
destructor but you could call logout to logout if you wish.                             
                                                                                        
Parameters:                                                                             
                                                                                        
=for html <blockquote>                                                                  
                                                                                        
=over                                                                                   
                                                                                        
=item None                                                                              
                                                                                        
=back                                                                                   
                                                                                        
=for html </blockquote>                                                                 
                                                                                        
Returns:                                                                                
                                                                                        
=for html <blockquote>                                                                  
                                                                                        
=over                                                                                   
                                                                                        
=item Nothing                                                                           
                                                                                        
=back                                                                                   
                                                                                        
=for html </blockquote>                                                                 
                                                                                        
=cut                                                                                    
                                                                                        
  $self->{handle}->soft_close;                                                          
                                                                                        
  undef $self->{handle};                                                                
  undef $self->{status};                                                                
  undef $self->{lines};                                                                 
                                                                                        
  return;                                                                               
} # logoff                                                                              
                                                                                        
sub new {                                                                               
  my ($class) = shift;                                                                  
                                                                                        
=pod                                                                                    
                                                                                        
=head3 new (<parms>)                                                                    
                                                                                        
This method instantiates a new Rexec object. Currently only hash style                  
parameter passing is supported.                                                         
                                                                                        
Parameters:                                                                             
                                                                                        
=for html <blockquote>                                                                  
                                                                                        
=over                                                                                   
                                                                                        
=item host => <host>:                                                                   
                                                                                        
Specifies the host to connect to. Default: localhost                                    
                                                                                        
=item username => <username>                                                            
                                                                                        
Specifies the username to use if prompted. Default: No username specified.              
                                                                                        
=item password => <password>                                                            
                                                                                        
Specifies the password to use if prompted. Default: No password                         
specified. Note passwords must be in cleartext at this                                  
time. Specifying them makes you insecure!                                               
                                                                                        
=item prompt => <prompt regex>                                                          
                                                                                        
Specifies a regex describing how to identify a prompt. Default: qr'[#>:$] $'            
                                                                                        
=item protocol => <ssh|rsh|rlogin|telnet>                                               
                                                                                        
Specifies the protocol to use when connecting. Default: Try them all                    
starting with ssh.                                                                      
                                                                                        
=item opts => <options>                                                                 
                                                                                        
Additional options for protocol (e.g. -X for ssh and X forwarding)                      
                                                                                        
=item verbose => <0|1>                                                                  
                                                                                        
If true then status messages are echoed to stdout. Default: 0.                          
                                                                                        
=back                                                                                   
                                                                                        
=for html </blockquote>                                                                 
                                                                                        
Returns:                                                                                
                                                                                        
=for html <blockquote>                                                                  
                                                                                        
=over                                                                                   
                                                                                        
=item Rexec object                                                                      
                                                                                        
=back                                                                                   
                                                                                        
=for html </blockquote>                                                                 
                                                                                        
=cut                                                                                    
                                                                                        
  my %parms = @_;                                                                       
                                                                                        
  my $self = {};                                                                        
                                                                                        
  $self->{host}       = $parms{host}       ? $parms{host}       : 'localhost';          
  $self->{username}   = $parms{username};                                               
  $self->{password}   = $parms{password};                                               
  $self->{prompt}     = $parms{prompt}     ? $parms{prompt}     : $DEFAULT_PROMPT;      
  $self->{protocol}   = $parms{protocol};                                               
  $self->{verbose}    = $parms{verbose};                                                
  $self->{shellstyle} = $parms{shellstyle} ? $parms{shellstyle} : 'sh';                 
  $self->{opts}       = $parms{opts}       ? $parms{opts}       : '';                   
  $self->{timeout}    = $parms{timeout}    ? $parms{timeout}    : $default_login_timeout;
                                                                                        
  if ($self->{shellstyle} ne 'sh' and $self->{shellstyle} ne 'csh') {                   
    croak 'ERROR: Unknown shell style specified. Must be one of "sh" or "csh"', 1;      
  } # if                                                                                
                                                                                        
  bless ($self, $class);                                                                
                                                                                        
  # now login...                                                                        
  $self->{handle} = $self->login;                                                       
                                                                                        
  # Set timeout to $default_exec_timeout                                                
  $self->{timeout} = $default_exec_timeout;                                             
                                                                                        
  return $self->{handle} ? $self : undef;                                               
} # new                                                                                 
                                                                                        
sub execute ($$) {                                                                      
  my ($self, $cmd, $timeout) = @_;                                                      
                                                                                        
=pod                                                                                    
                                                                                        
=head3 exec ($cmd, $timeout)                                                            
                                                                                        
This method executes a command on the remote host returning an array                    
of lines that the command produced, if any. Status of the command is                    
stored in the object and accessible via the status method.                              
                                                                                        
Parameters:                                                                             
                                                                                        
=for html <blockquote>                                                                  
                                                                                        
=over                                                                                   
                                                                                        
=item $cmd:                                                                             
                                                                                        
Command to execute remotely                                                             
                                                                                        
=item $timeout                                                                          
                                                                                        
Set timeout for this execution. If timeout is 0 then wait forever. If                   
you wish to interrupt this then set up a signal handler.                                
                                                                                        
=back                                                                                   
                                                                                        
=for html </blockquote>                                                                 
                                                                                        
Returns:                                                                                
                                                                                        
=for html <blockquote>                                                                  
                                                                                        
=over                                                                                   
                                                                                        
=item @lines                                                                            
                                                                                        
An array of lines from STDOUT of the command. If STDERR is also wanted                  
then add STDERR redirection to $cmd. Exit status is not returned by                     
retained in the object. Use status method to retrieve it.                               
                                                                                        
=back                                                                                   
                                                                                        
=for html </blockquote>                                                                 
                                                                                        
=cut                                                                                    
                                                                                        
  # If timeout is specified for this exec then use it - otherwise                       
  # use the object's defined timeout.                                                   
  $timeout = $timeout ? $timeout : $self->{timeout};                                    
                                                                                        
  # If timeout is set to 0 then the user wants an indefinite                            
  # timeout. But Expect wants it to be undefined. So undef it if                        
  # it's 0. Note this means we do not support Expect's "check it                        
  # only one time" option.                                                              
  undef $timeout if $timeout == 0;                                                      
                                                                                        
  # If timeout is < 0 then the user wants to run the command in the                     
  # background and return. We still need to wait as we still may                        
  # timeout so change $timeout to the $default_exec_timeout in this                     
  # case and add a "&" to the command if it's not already there.                        
  # because the user has added a & to the command to run it in the                      
  if ($timeout && $timeout < 0) {                                                       
    $timeout = $default_exec_timeout;                                                   
    $cmd .= "&" if $cmd !~ /&$/;                                                        
  } # if                                                                                
                                                                                        
  # Set status to -2 indicating nothing happened! We should never                       
  # return -2 (unless a command manages to set $? to -2!)                               
  $self->{status} = -2;                                                                 
                                                                                        
  # Empty lines of any previous command output                                          
  @lines = ();                                                                          
                                                                                        
  # Hopefully we will not see the following in the output string                        
  my $errno_str = "ReXeCerRoNO=";                                                       
  my $start_str = "StaRT";                                                              
                                                                                        
  my $compound_cmd;                                                                     
                                                                                        
  # If cmd ends in a & then it makes no sense to compose a compound                     
  # command. The original command will be in the background and thus                    
  # we should not attempt to get a status - there will be none.                         
  if ($cmd !~ /&$/) {                                                                   
    $compound_cmd = "echo $start_str; $cmd; echo $errno_str";                           
    $compound_cmd .= $self->{shellstyle} eq "sh" ? "\$?" : "\$status";                  
  } else {                                                                              
    $compound_cmd = $cmd;                                                               
  } # if                                                                                
                                                                                        
  $self->{handle}->send ("$compound_cmd\n");                                            
                                                                                        
  $self->{handle}->expect (                                                             
    $timeout,                                                                           
                                                                                        
    [ timeout =>                                                                        
      sub {                                                                             
        $self->{status} = -1;                                                           
      }                                                                                 
    ],                                                                                  
                                                                                        
    [ qr "\n$start_str",                                                                
      sub {                                                                             
        exp_continue;                                                                   
      }                                                                                 
    ],                                                                                  
                                                                                        
    [ qr "\n$errno_str",                                                                
      sub {                                                                             
        my ($exp) = @_;                                                                 
                                                                                        
        my $before = $exp->before;                                                      
        my $after  = $exp->after;                                                       
                                                                                        
        if ($after =~ /(\d+)/) {                                                        
          $self->{status} = $1;                                                         
        } # if                                                                          
                                                                                        
        my @output = split /\n/, $before;                                               
                                                                                        
        chomp @output;                                                                  
        chop @output if $output[0] =~ /\r$/;                                            
                                                                                        
        foreach (@output) {                                                             
          next if /^$/;                                                                 
          last if /$errno_str=/;                                                        
                                                                                        
          push @lines, $_;                                                              
        } # foreach                                                                     
                                                                                        
        exp_continue;                                                                   
      }                                                                                 
    ],                                                                                  
                                                                                        
    [ $self->{prompt},                                                                  
      sub {                                                                             
        print 'Hit prompt!' if $debug;                                                  
      }                                                                                 
    ],                                                                                  
  );                                                                                    
                                                                                        
  $self->{lines} = \@lines;                                                             
                                                                                        
  return @lines;                                                                        
} # exec                                                                                
                                                                                        
sub abortCmd (;$) {                                                                     
  my ($self, $timeout) = @_;                                                            
                                                                                        
=pod                                                                                    
                                                                                        
=head3 abortCmd                                                                         
                                                                                        
Aborts the current command by sending a Control-C (assumed to be the                    
interrupt character).                                                                   
                                                                                        
Parameters:                                                                             
                                                                                        
=for html <blockquote>                                                                  
                                                                                        
=over                                                                                   
                                                                                        
=item None                                                                              
                                                                                        
=back                                                                                   
                                                                                        
=for html </blockquote>                                                                 
                                                                                        
Returns:                                                                                
                                                                                        
=for html <blockquote>                                                                  
                                                                                        
=over                                                                                   
                                                                                        
=item $status                                                                           
                                                                                        
1 if abort was successful (we got a command prompt back) or 0 if it                     
was not.                                                                                
                                                                                        
=back                                                                                   
                                                                                        
=for html </blockquote>                                                                 
                                                                                        
=cut                                                                                    
                                                                                        
  # If timeout is specified for this exec then use it - otherwise                       
  # use the object's defined timeout.                                                   
  $timeout = $timeout ? $timeout : $self->{timeout};                                    
                                                                                        
  # If timeout is set to 0 then the user wants an indefinite                            
  # timeout. But Expect wants it to be undefined. So undef it if                        
  # it's 0. Note this means we do not support Expect's "check it                        
  # only one time" option.                                                              
  undef $timeout if $timeout == 0;                                                      
                                                                                        
  # Set status to -2 indicating nothing happened! We should never                       
  # return -2 (unless a command manages to set $? to -2!)                               
  $self->{status} = -2;                                                                 
                                                                                        
  $self->{handle}->send ("\cC");                                                        
                                                                                        
  $self->{handle}->expect (                                                             
    $timeout,                                                                           
                                                                                        
    [ timeout =>                                                                        
      sub {                                                                             
        $self->{status} = -1;                                                           
      }                                                                                 
    ],                                                                                  
                                                                                        
    [ $self->{prompt},                                                                  
      sub {                                                                             
        print "Hit prompt!" if $debug;                                                  
      }                                                                                 
    ],                                                                                  
  );                                                                                    
                                                                                        
  return $self->{status};                                                               
} # abortCmd                                                                            
                                                                                        
sub status {                                                                            
  my ($self) = @_;                                                                      
                                                                                        
=pod                                                                                    
                                                                                        
=head3 status                                                                           
                                                                                        
Returns the status of the last command executed remotely.                               
                                                                                        
Parameters:                                                                             
                                                                                        
=for html <blockquote>                                                                  
                                                                                        
=over                                                                                   
                                                                                        
=item None                                                                              
                                                                                        
=back                                                                                   
                                                                                        
=for html </blockquote>                                                                 
                                                                                        
Returns:                                                                                
                                                                                        
=for html <blockquote>                                                                  
                                                                                        
=over                                                                                   
                                                                                        
=item $status                                                                           
                                                                                        
Last status from exec.                                                                  
                                                                                        
=back                                                                                   
                                                                                        
=for html </blockquote>                                                                 
                                                                                        
=cut                                                                                    
                                                                                        
  return $self->{status};                                                               
} # status                                                                              
                                                                                        
sub shellstyle {                                                                        
  my ($self) = @_;                                                                      
                                                                                        
=pod                                                                                    
                                                                                        
=head3 shellstyle                                                                       
                                                                                        
Returns the shellstyle                                                                  
                                                                                        
Parameters:                                                                             
                                                                                        
=for html <blockquote>                                                                  
                                                                                        
=over                                                                                   
                                                                                        
=item None                                                                              
                                                                                        
=back                                                                                   
                                                                                        
=for html </blockquote>                                                                 
                                                                                        
Returns:                                                                                
                                                                                        
=for html <blockquote>                                                                  
                                                                                        
=over                                                                                   
                                                                                        
=item "sh"|"csh"                                                                        
                                                                                        
sh: Bourne or csh: for csh style shells                                                 
                                                                                        
=back                                                                                   
                                                                                        
=for html </blockquote>                                                                 
                                                                                        
=cut                                                                                    
                                                                                        
  return $self->{shellstyle};                                                           
} # shellstyle                                                                          
                                                                                        
sub lines () {                                                                          
  my ($self) = @_;                                                                      
                                                                                        
=pod                                                                                    
                                                                                        
=head3 lines                                                                            
                                                                                        
Returns the lines array from the last command called by exec.                           
                                                                                        
Parameters:                                                                             
                                                                                        
=for html <blockquote>                                                                  
                                                                                        
=over                                                                                   
                                                                                        
=item None                                                                              
                                                                                        
=back                                                                                   
                                                                                        
=for html </blockquote>                                                                 
                                                                                        
Returns:                                                                                
                                                                                        
=for html <blockquote>                                                                  
                                                                                        
=over                                                                                   
                                                                                        
=item @lines                                                                            
                                                                                        
An array of lines from the last call to exec.                                           
                                                                                        
=back                                                                                   
                                                                                        
=for html </blockquote>                                                                 
                                                                                        
=cut                                                                                    
                                                                                        
  return @{$self->{lines}};                                                             
} # lines                                                                               
                                                                                        
sub print_lines () {                                                                    
  my ($self) = @_;                                                                      
                                                                                        
=pod                                                                                    
                                                                                        
=head3 print_lines                                                                      
                                                                                        
Essentially prints the lines array to stdout                                            
                                                                                        
Parameters:                                                                             
                                                                                        
=for html <blockquote>                                                                  
                                                                                        
=over                                                                                   
                                                                                        
=item None                                                                              
                                                                                        
=back                                                                                   
                                                                                        
=for html </blockquote>                                                                 
                                                                                        
Returns:                                                                                
                                                                                        
=for html <blockquote>                                                                  
                                                                                        
=over                                                                                   
                                                                                        
=item Nothing                                                                           
                                                                                        
=back                                                                                   
                                                                                        
=for html </blockquote>                                                                 
                                                                                        
=cut                                                                                    
                                                                                        
  print "$_\n" foreach ($self->lines);                                                  
                                                                                        
  return;                                                                               
} # print_lines                                                                         
                                                                                        
sub getHost () {                                                                        
  my ($self) = @_;                                                                      
                                                                                        
=pod                                                                                    
                                                                                        
=head3 host                                                                             
                                                                                        
Returns the host from the object.                                                       
                                                                                        
Parameters:                                                                             
                                                                                        
=for html <blockquote>                                                                  
                                                                                        
=over                                                                                   
                                                                                        
=item None                                                                              
                                                                                        
=back                                                                                   
                                                                                        
=for html </blockquote>                                                                 
                                                                                        
Returns:                                                                                
                                                                                        
=for html <blockquote>                                                                  
                                                                                        
=over                                                                                   
                                                                                        
=item $hostname                                                                         
                                                                                        
=back                                                                                   
                                                                                        
=for html </blockquote>                                                                 
                                                                                        
=cut                                                                                    
                                                                                        
  return $self->{host};                                                                 
} # getHost                                                                             
                                                                                        
sub DESTROY {                                                                           
  my ($self) = @_;                                                                      
                                                                                        
  $self->{handle}->hard_close                                                           
    if $self->{handle};                                                                 
                                                                                        
  return;                                                                               
} # destroy                                                                             
                                                                                        
sub getTimeout {                                                                        
  my ($self) = @_;                                                                      
                                                                                        
=head3 getTimeout                                                                       
                                                                                        
Returns the timeout from the object.                                                    
                                                                                        
Parameters:                                                                             
                                                                                        
=for html <blockquote>                                                                  
                                                                                        
=over                                                                                   
                                                                                        
=item None                                                                              
                                                                                        
=back                                                                                   
                                                                                        
=for html </blockquote>                                                                 
                                                                                        
Returns:                                                                                
                                                                                        
=for html <blockquote>                                                                  
                                                                                        
=over                                                                                   
                                                                                        
=item $timeout                                                                          
                                                                                        
=back                                                                                   
                                                                                        
=for html </blockquote>                                                                 
                                                                                        
=cut                                                                                    
                                                                                        
  return $self->{timeout} ? $self->{timeout} : $default_login_timeout;                  
} # getTimeout                                                                          
                                                                                        
sub setTimeout ($) {                                                                    
  my ($self, $timeout) = @_;                                                            
                                                                                        
=pod                                                                                    
                                                                                        
=head3 setTimeout ($timeout)                                                            
                                                                                        
Sets the timeout value for subsequent execution.                                        
                                                                                        
Parameters:                                                                             
                                                                                        
=for html <blockquote>                                                                  
                                                                                        
=over                                                                                   
                                                                                        
=item $timeout                                                                          
                                                                                        
New timeout value to set                                                                
                                                                                        
=back                                                                                   
                                                                                        
=for html </blockquote>                                                                 
                                                                                        
Returns:                                                                                
                                                                                        
=for html <blockquote>                                                                  
                                                                                        
=over                                                                                   
                                                                                        
=item $timeout                                                                          
                                                                                        
Old timeout value                                                                       
                                                                                        
=back                                                                                   
                                                                                        
=for html </blockquote>                                                                 
                                                                                        
=cut                                                                                    
                                                                                        
  my $oldTimeout = $self->getTimeout;                                                   
  $self->{timeout} = $timeout;                                                          
                                                                                        
  return $oldTimeout;                                                                   
} # setTimeout                                                                          
                                                                                        
1;                                                                                      
                                                                                        
=head1 DIAGNOSTICS                                                                      
                                                                                        
=head2 Errors                                                                           
                                                                                        
If verbose is turned on then connections or failure to connect will be                  
echoed to stdout.                                                                       
                                                                                        
=head3 Error text                                                                       
                                                                                        
  <host> is not responding to <protocol>                                                
  Connected to <host> using <protocol> protocol                                         
  Unable to connect to <host> using <protocol> protocol                                 
                                                                                        
=head2 Warnings                                                                         
                                                                                        
Specifying cleartext passwords is not recommended for obvious security concerns.        
                                                                                        
=head1 CONFIGURATION AND ENVIRONMENT                                                    
                                                                                        
Configuration files and environment variables.                                          
                                                                                        
=over                                                                                   
                                                                                        
=item None                                                                              
                                                                                        
=back                                                                                   
                                                                                        
=head1 DEPENDENCIES                                                                     
                                                                                        
=head2 Perl Modules                                                                     
                                                                                        
=for html <a href="http://search.cpan.org/~rgiersig/Expect-1.21/Expect.pod">Expect</a><b
                                                                                        
=head3 ClearSCM Perl Modules                                                            
                                                                                        
=for html <p><a href="/php/cvs_man.php?file=lib/Display.pm">Display</a></p>             
                                                                                        
=head1 INCOMPATABILITIES                                                                
                                                                                        
None yet...                                                                             
                                                                                        
=head1 BUGS AND LIMITATIONS                                                             
                                                                                        
There are no known bugs in this module.                                                 
                                                                                        
Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.                         
                                                                                        
=head1 LICENSE AND COPYRIGHT                                                            
                                                                                        
This Perl Module is freely available; you can redistribute it and/or                    
modify it under the terms of the GNU General Public License as                          
published by the Free Software Foundation; either version 2 of the                      
License, or (at your option) any later version.                                         
                                                                                        
This Perl Module is distributed in the hope that it will be useful,                     
but WITHOUT ANY WARRANTY; without even the implied warranty of                          
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU                        
General Public License (L<http://www.gnu.org/copyleft/gpl.html>) for more               
details.                                                                                
                                                                                        
You should have received a copy of the GNU General Public License                       
along with this Perl Module; if not, write to the Free Software Foundation,             
Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.                          
reserved.                                                                               
                                                                                        
=cut                                                                                    