=pod

=head1 NAME $RCSfile: Client.pm,v $

Clearquest client - Provide access to a running Clearquest server

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 2.8 $

=item Created

Monday, October 10, 2011  5:02:07 PM PDT

=item Modified

$Date: 2013/05/30 15:43:28 $

=back

=head1 SYNOPSIS

Provides an interface to a running Clearquest Server over the network. This 
means that you can use any Perl you like, not just cqperl, and you don't need
to have Clearquest installed locally. In fact you can run from say Linux and
talk to the Clearquest Server running on Windows.

=head1 DESCRIPTION

The server allows both read and write access to a Clearquest database as defined
in cqdservice.conf file. Note the username/password must be of a user who can
write to the Clearquest database for write access to succeed.

A hash is passed into to the execute method, which the client should use to talk
to the server, that describes relatively simple protocol to tell the server what
action to perform. In both the read case and the read/write case a field named
id should be defined that has a value of "<record>=<id>" (e.g. 
"defect=BUGDB00034429").

For the read case the rest of the keys are the names of the fields to retrieve
with values that are undef'ed. For read/write, the rest of hash contains name
value pairs of fields to set and their values.

Execute returns a status and a hash of name value pairs for the read case and an
array of lines for any error messages for the read/write case. 

=head1 ROUTINES

The following methods are available:

=cut

package Clearquest::Client;

use strict;
use warnings;

use Carp;
use File::Basename;
use FindBin;
use IO::Socket;
use Net::hostent;
use POSIX ":sys_wait_h";
use Data::Dumper;

use Clearquest;

use parent 'Clearquest';

$Data::Dumper::Indent = 0;

our $VERSION  = '$Revision: 2.8 $';
   ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);
   
=pod

=head1 Options

Options are keep in the cq.conf file in the etc directory. They specify the
default options listed below. Or you can export the option name to the env(1) to 
override the defaults in cq.conf. Finally you can programmatically set the
options when you call new by passing in a %parms hash. The items below are the
key values for the hash.

=for html <blockquote>

=over

=item CQ_SERVER

The CQ Server host to connect to

=item CQ_PORT

Port number to contact the server at (Default: From cq.conf)

=item CQ_USERNAME

User name to connect as (Default: From cq.conf)

=item CQ_PASSWORD

Password for CQ_USERNAME

=item CQ_DATABASE

Name of database to connect to (Default: From cq.conf)

=item CQ_DBSET

Database Set name (Default: From cq.conf)

=back

=cut   

sub _parseCmd ($) {
  my ($self, $cmd) = @_;
} # _parseCmd

sub _request ($;@) {
  my ($self, $call, @parms) = @_;
  
  my $server = $self->{socket};

  my $request = $call;
  
  $request .= ' ';
  $request .= Dumper \@parms;
  $request .= "\n";

  # Send request
  print $server $request;

  # Get response
  my ($response, $status, @output);
  
  while (defined ($response = <$server>)) {
    if ($response =~ /Clearquest::Server Status: (-*\d+)/) {
      $status = $1;
      last;
    } # if
    
    chomp $response; chop $response if $response =~ /\r$/;
    
    push @output, $response;
  } # while
  
  unless (@output) {
    push @output, 'Unknown or unhandled error';
    
    $status = -1;
  } # unless
  
  $self->_setError (join ("\n", @output), $status) if $status;
  
  return ($status, @output);
} # _request

sub add ($$;@) {
  my ($self, $table, $values, @ordering) = @_;

  my @parms;
  
  push @parms, $table, Dumper ($values), @ordering;
  
  $self->_request ('add', @parms);
  
  return $self->errmsg;
} # add

sub connect (;$$$$) {
  my ($self, $username, $password, $database, $dbset) = @_;
  
  return $self->connectToServer;
} # connect

sub connectToServer (;$$) {
  my ($self, $server, $port) = @_;

  $self->{socket} = IO::Socket::INET->new (
    Proto    => 'tcp',
    PeerAddr => $self->{server},
    PeerPort => $self->{port},
  );
  
  unless ($self->{socket}) {
    $self->_setError ($!, 1);
    
    return;
  } # unless
  
  $self->{socket}->autoflush;

  # Now tell the server what database we wish to use
  my ($status, @output) = $self->_request (
    'open',
    $self->{database},
    $self->{username},
    $self->{password},
    $self->{dbset},
  );

  $self->{loggedin} = $status == 0;
  
  $self->_setError (@output, $status);
  
  return $self->connected;
} # connectToServer

sub dbsets () {
  my ($self) = @_;
  
  my ($status, @output) = $self->_request ('dbsets');

  return @output;
} # dbsets

sub delete ($$) {
  my ($self, $table, $key) = @_;

  my @parms;
  
  push @parms, $table;
  push @parms, $key;
  
  my ($status, @output) = $self->_request ('delete', @parms);
  
  return $self->errmsg;
} # delete

sub DESTROY () {
  my ($self) = @_;
  
  $self->disconnectFromServer;
} # DESTROY

sub disconnect () {
  my ($self) = @_;
  
  $self->disconnectFromServer;
  
  $self->{loggedin} = 0;
  
  return;
} # disconnect

sub disconnectFromServer () {
  my ($self) = @_;

  if ($self->{socket}) {
    $self->_request ('end');
    
    close $self->{socket};
   
    undef $self->{socket};
  } # if
  
  return;
} # disconnectFromServer

sub find ($;$@) {
  my ($self, $table, $condition, @fields) = @_;
  
  $condition ||= '';
  
  # TODO: Need to return nbrrecs
  my ($status, @output) = $self->_request ('find', $table, $condition, @fields);

  if ($self->error) {
    return (undef, $self->errmsg);
  } else {
    return ($status, $output[1]);
  } # if
} # find

sub get ($$@) {
  my ($self, $table, $key, @fields) = @_;

  my %record;
  
  $self->_setError ('', 0);
  
  my ($status, @output) = $self->_request ('get', $table, $key, @fields);  

  return if $status;

  foreach (@output) {
    my ($field, $value) = split /\@\@/;
    
    $value =~ s/&#10;/\n/g;
      
    if ($record{$field}) {
      if (ref $record{$field} ne 'ARRAY') {
        my $valueOne = $record{$field};
        
        $record{$field} = ();
        
        push @{$record{$field}}, $valueOne, $value;
      } else {
        push @{$record{$field}}, $value;
      } # if
    } else {
      $record{$field} = $value;
    } # if
  } # foreach

  return %record;
} # get

sub getDBID ($$@) {
  my ($self, $table, $dbid, @fields) = @_;

  my %record = ();
  
  my ($status, @output) = $self->_request ('getDBID', $table, $dbid, @fields);  

  return ($status, %record) if $status;

  foreach (@output) {
    my ($field, $value) = split /\@\@/;
    
    $value =~ s/&#10;/\n/g;
      
    if ($record{$field}) {
      if (ref $record{$field} ne 'ARRAY') {
        my $valueOne = $record{$field};
        
        $record{$field} = ();
        
        push @{$record{$field}}, $valueOne, $value;
      } else {
        push @{$record{$field}}, $value;
      } # if
    } else {
      $record{$field} = $value;
    } # if
  } # foreach

  return %record;
} # getDBID

sub getDynamicList ($) {
  my ($self, $list) = @_;
  
  my ($status, @output) = $self->_request ('getDynamicList', $list);
  
  return @output;
} # getDynamicList

sub getNext ($) {
  my ($self, $result) = @_;
  
  my ($status, @output) = $self->_request ('getNext', ());
  
  return if $status;
  
  my %record;
  
  foreach (@output) {
    my ($field, $value) = split /\@\@/;
    
    $value =~ s/&#10;/\n/g;
      
    if ($record{$field}) {
      if (ref $record{$field} ne 'ARRAY') {
        push @{$record{$field}}, $record{$field}, $value;
      } else {
        push @{$record{$field}}, $value;
      } # if
    } else {
      $record{$field} = $value;
    } # if
  } # foreach

  return %record;
} # getNext

sub key ($$) {
  my $self = shift;
  
  my ($status, @output) = $self->_request ('key', @_);

  return $output[0];
} # key

sub modify ($$$$;@) {
  my ($self, $table, $key, $action, $values, @ordering) = @_;
  
  $action ||= 'Modify';
  
  my @parms;
  
  push @parms, $table, $key, $action, Dumper ($values), @ordering;
    
  $self->_request ('modify', @parms);
  
  return $self->errmsg;
} # modify

sub modifyDBID ($$$$;@) {
  my ($self, $table, $dbid, $action, $values, @ordering) = @_;
  
  my @parms;
  
  push @parms, $table, $dbid, $action, Dumper ($values), @ordering;
    
  $self->_request ('modifyDBID', @parms);
  
  return $self->errmsg;
} # modifyDBID

sub port () {
  my ($self) = @_;
  
  return $self->{port};
} # port

sub new () {
  my ($class, $self) = @_;

  $$self{server} ||= $Clearquest::OPTS{CQ_SERVER};
  $$self{port}   ||= $Clearquest::OPTS{CQ_PORT};
  
  bless $self, $class;
} # new

sub shutdown () {
  my ($self) = @_;
  
  if ($self->{socket}) {
    $self->_request ('shutdown');
  } # if
} # shutdown

1;

=pod

=head1 CONFIGURATION AND ENVIRONMENT

DEBUG: If set then $debug is set to this level.

VERBOSE: If set then $verbose is set to this level.

TRACE: If set then $trace is set to this level.

=head1 DEPENDENCIES

=head2 Perl Modules

L<Carp>

L<File::Basename|File::Basename>

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
<a href="http://clearscm.com/php/cvs_man.php?file=lib/DateUtils.pm">DateUtils</a><br>
<a href="http://clearscm.com/php/cvs_man.php?file=lib/Display.pm">Display</a><br>
<a href="http://clearscm.com/php/cvs_man.php?file=lib/GetConfig.pm">GetConf</a><br>
</blockquote>

=end html

=head1 SEE ALSO

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011, ClearSCM, Inc. All rights reserved.

=cut
