=pod

=head1 NAME $RCSfile: Admin.pm,v $

Clearquest Admin - Provide access Clearquest AdminSession objects

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.3 $

=item Created

Wed Apr 18 09:59:47 PDT 2012

=item Modified

$Date: 2012/11/09 06:53:11 $

=back

=head1 SYNOPSIS

Provides an interface to the Clearquest AdminSession objects. These are for
dealing with objects in the schema, not the user database.

=head1 DESCRIPTION

The Admin object allows you to create a session object associated with a schema
repository. This allows you to retrieve and modify information in a schema
repository. You must log into the Admin object as an admin user. 

Functions are available to deal with users, groups, databases and schemas.

Note: Admin object needs to be filled out with more functions over time...

=head1 ROUTINES

The following methods are available:

=cut

package Clearquest::Admin;

use strict;
use warnings;

use Carp;
use File::Basename;
use FindBin;

use DateUtils;
use Display;
use GetConfig;

use Clearquest;

# Seed options from config file
my $config = $ENV{CQD_CONF} || dirname (__FILE__) . '/../../etc/cqdservice.conf';

croak "Unable to find config file $config" unless -r $config;

our %OPTS = GetConfig $config;

our $VERSION  = '$Revision: 1.3 $';
   ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);
   
# Override options if in the environment
$OPTS{CQD_HOST}          = $ENV{CQD_HOST}
  if $ENV{CQD_HOST};
$OPTS{CQD_PORT}          = $ENV{CQD_PORT}
  if $ENV{CQD_PORT};
$OPTS{CQD_MULTITHREADED} = $ENV{CQD_MULTITHREADED}
  if defined $ENV{CQD_MULTITHREADED};
$OPTS{CQD_DATABASE}      = $ENV{CQD_DATABASE}
  if $ENV{CQD_DATABASE};
$OPTS{CQD_USERNAME}      = $ENV{CQD_USERNAME}
  if $ENV{CQD_USERNAME};
$OPTS{CQD_PASSWORD}      = $ENV{CQD_PASSWORD}
  if $ENV{CQD_PASSWORD};
$OPTS{CQD_DBSET}         = $ENV{CQD_DBSET}
  if $ENV{CQD_DBSET};

sub getUser ($) {
  my ($self, $loginname) = @_;
  
=pod

=head2 getUser ($)

Returns a user object for the specified user or undef.

Parameters:

=for html <blockquote>

=over

=item $username

The $loginname to retrieve the user object for

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item User object

A user object

=back

=for html </blockquote>

=cut

  return $self->{session}->GetUser ($loginname);
} # getNext

sub userActive ($) {
  my ($self, $loginname) = @_;
  
=pod

=head2 userActive ($)

Returns a true if user is active

Parameters:

=for html <blockquote>

=over

=item $username

The $loginname to see if active

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item 1 if true, 0 if false

=back

=for html </blockquote>

=cut

  my $user = $self->getUser ($loginname);
  
  if ($user) {
    return $user->GetActive;
  } else {
    return 0;
  } # if
} # userActive

sub userActivate ($) {
  my ($self, $loginname) = @_;
  
=pod

=head2 userActivate ($)

Activates a user if they were inactive

Parameters:

=for html <blockquote>

=over

=item $username

The $loginname to activate

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item nothing

=back

=for html </blockquote>

=cut

  unless ($self->activeUser ($logname)) {
    my $user = $self->getUser ($loginname);
    
    if ($user) {
      $user->SetUser (1);
    } # if
  } # unless
} # userActive

sub userActivate ($) {
  my ($self, $loginname) = @_;
  
=pod

=head2 userInactivate ($)

Inactivates a user if they were active

Parameters:

=for html <blockquote>

=over

=item $username

The $loginname to inactivate

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item nothing

=back

=for html </blockquote>

=cut

  if ($self->activeUser ($logname)) {
    my $user = $self->getUser ($loginname);
    
    if ($user) {
      $user->SetUser (0);
    } # if
  } # unless
} # userInactive

sub new () {
  my ($class, $username, $password, $dbset) = @_;

  my $self = bless {}, $class;
  
  if (ref $username eq 'HASH') {
    my %parms = %$username;
    
    $self->{username} = $parms{username};
    $self->{password} = $parms{password};
    $self->{dbset}    = $parms{dbset};
  } else {
    $self->{username} = $username;
    $self->{password} = $password;
    $self->{dbset}    = $dbset;
  } # if

  return $self;
} # new

sub connect (;$$$) {

=pod

=head2 connect (;$$$)

Connect to the Clearquest schema database. You can supply parameters such as
username, password, etc and they will override any passed to 
Clearquest::Admin::new (or those coming from ../etc/cq.conf)

Parameters:

=for html <blockquote>

=over

=item $username

Username to use to connect to the schema database

=item $password

Password to use to connect to the schema database

=item $dbset

Database set to connect to (Default: Connect to the default dbset)

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item 1

=back

=for html </blockquote>

=cut
    
  my ($self, $username, $password, $dbset) = @_;
  
  $self->{username} = $username if $username;
  $self->{password} = $password if $password;
  $self->{database} = $database if $database;
  $self->{dbset}    = $dbset    if $dbset;
  
  $self->{session}  = CQAdminSession::Build;
  
  # TODO: Should handle failures better
  $self->{session}->($self->{username},
                     $self->{password},
                     $self->{dbset});
  $self->{loggedin} = 1;
  
  return $self->{loggedin};
} # connect

sub connected () {
  my ($self) = @_;
  
=pod

=head2 connected ()

Returns 1 if we are currently connected to a Clearquest Admin Schema Database

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item 1 if logged in - 0 if not

=back

=for html </blockquote>

=cut
  
  return $self->{loggedin};  
} # connected

sub disconnect () {
  my ($self) = @_;

=pod

=head2 disconnect ()

Disconnect from Clearquest Admin Schema Database

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item nothing

=back

=for html </blockquote>

=cut

  CQAdminSession::Unbuild ($self->{session});
  
  undef $self->{session};
  
  $self->{loggedin} = 0;
  
  return;
} # disconnect



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
<a href="http://clearscm.com/php/scm_man.php?file=lib/DateUtils.pm">DateUtils</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Display.pm">Display</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/GetConfig.pm">GetConf</a><br>
</blockquote>

=end html

=head1 SEE ALSO

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011, ClearSCM, Inc. All rights reserved.

=cut
