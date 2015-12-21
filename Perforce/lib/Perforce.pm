package Perforce;

use strict;
use warnings;

use Carp;
use File::Basename;
use File::Temp;

use P4;
use Authen::Simple::LDAP;

use Display;
use GetConfig;
use Utils;

our $VERSION  = '$Revision: 2.23 $';
   ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);

my $p4config   = $ENV{P4_CONF}   || dirname (__FILE__) . '/../etc/p4.conf';
my $ldapconfig = $ENV{LDAP_CONF} || dirname (__FILE__) . '/../etc/LDAP.conf';

my %P4OPTS   = GetConfig $p4config   if -r $p4config;
my %LDAPOPTS = GetConfig $ldapconfig if -r $ldapconfig;

my $serviceUser = 'shared';
my ($domain, $password);
my $defaultPort = 'perforce:1666';
my $p4tickets   = $^O =~ /win/i ? 'C:/Program Files/Devops/Perforce/p4tickets'
                                : '/opt/audience/perforce/p4tickets';
                                
my $keys;

# If USERDOMAIN is set and equal to audience then set $domain to ''. This will
# use the Audience domain settings in LDAP.conf.
if ($ENV{USERDOMAIN}) {
  if (lc $ENV{USERDOMAIN} eq 'audience') {
    $domain = '';
  } else {
    $domain = $ENV{USERDOMAIN}
  } # if
} # if

sub new (;%) {
  my ($class, %parms) = @_;
  
  my $self = bless {}, $class;
  
  $self->{P4USER}   = $parms{username} || $P4OPTS{P4USER}   || $ENV{P4USER}   || $serviceUser;
  $self->{P4PASSWD} = $parms{password} || $P4OPTS{P4PASSWD} || $ENV{P4PASSWD} || undef;
  $self->{P4CLIENT} = $parms{p4client} || $P4OPTS{P4CLIENT} || $ENV{P4CLIENT} || undef;
  $self->{P4PORT}   = $parms{p4port}   || $ENV{P4PORT}    || $defaultPort;

  $self->{P4}       = $self->connect (%parms);
  
  return $self; 
} # new

sub errors ($;$) {
  my ($self, $cmd, $exit) = @_;

  my $msg    = "Unable to run \"p4 $cmd\"";
  my $errors = $self->{P4}->ErrorCount;

  error "$msg\n" . $self->{P4}->Errors, $exit if $errors; 

  return $errors;
} # errors

sub connect () {
  my ($self) = @_;
  
  $self->{P4} = P4->new;
  
  $self->{P4}->SetUser     ($self->{P4USER});
  $self->{P4}->SetClient   ($self->{P4CLIENT}) if $self->{P4CLIENT};
  $self->{P4}->SetPort     ($self->{P4PORT});
  $self->{P4}->SetPassword ($self->{P4PASSWD}) unless $self->{P4USER} eq $serviceUser;

  verbose_nolf "Connecting to Perforce server $self->{P4PORT}...";
  $self->{P4}->Connect or croak "Unable to connect to Perforce Server\n";
  verbose 'done';
  
  verbose_nolf "Logging in as $self->{P4USER}\@$self->{P4PORT}...";

  unless ($self->{P4USER} eq $serviceUser) {
    $self->{P4}->RunLogin;

    $self->errors ('login', $self->{P4}->ErrorCount);
  } else {
    $ENV{P4TICKETS} = $p4tickets if $self->{P4USER} eq $serviceUser;
  } # unless

  verbose 'done';

  return $self->{P4};
} # connect

sub _authenticateUser ($$$$) {
  my ($self, $domain, $username, $p4client) = @_;
  
  $domain .= '_' unless $domain eq '';
  
  # Connect to LDAP
  my $ad = Authen::Simple::LDAP->new (
    host   => $LDAPOPTS{"${domain}AD_HOST"},
    basedn => $LDAPOPTS{"${domain}AD_BASEDN"},
    port   => $LDAPOPTS{"${domain}AD_PORT"},
    filter => $LDAPOPTS{"${domain}AD_FILTER"},
  ) or croak $@;
  
  # Read the password from <stdin> and truncate the newline - unless we already
  # read in the password
  unless ($password) {
    if (-t STDIN) {
      $password = GetPassword;
    } else {
      $password = <STDIN>;
      
      chomp $password;
    } # if
  } # unless
  
  # Special handling of "shared" user
  if ($username eq 'shared') {
    my $sharedAcl = "$FindBin::Bin/sharedAcl.txt";
    
    croak "Unable to find file $sharedAcl" unless -f $sharedAcl;
    
    open my $sharedAcls, '<', $sharedAcl
      or croak "Unable to open $sharedAcl - $!";
      
    chomp (my @acls = <$sharedAcls>);
    
    close $sharedAcls;
    
    for (@acls) {
      if (/\*$/) {
        chop;
        
        exit if $p4client =~ /$_/;
      } else {
        exit if $_ eq $p4client;
      } # if
    } # for
  } # if

  # Connect to Perforce
  $self->connect unless $self->{P4};
  
  # Must be a valid Perforce user  
  return unless $self->getUser ($username);
  
  # And supply a valid username/password
  return $ad->authenticate ($username, $password);
} # _authenticateUser

sub authenticateUser ($;$) {
  my ($self, $username, $p4client) = @_;
  
=pod
  # If $domain is set to '' then we'll check Audience's LDAP. 
  # If $domain is not set (undef) then we'll try Knowles first, then Audience
  # otherwise we will take $DOMAIN and look for those settings...
  unless ($domain) {
    unless ($self->_authenticateUser ('KNOWLES', $username, $p4client)) {
      unless ($self->_authenticateUser ('', $username, $p4client)) {
        return;
      } # unless
    } # unless
  } else {
    if ($domain eq '') {
      unless ($self->_authenticateUser ('', $username, $p4client)) {
        return;
      } # unless
    } else {
      unless ($self->_authenticateUser ($domain, $username, $p4client)) {
        return;
      } # unless
    } # if
  } # unless
=cut

  return $self->_authenticateUser ('KNOWLES',  $username, $p4client);  
  
#  return 1;
} # authenticateUser

sub changes (;$%) {
  my ($self, $args, %opts) = @_;

  my $cmd = 'changes';

  for (keys %opts) {
    if (/from/i and $opts{to}) {
        $args .= " $opts{$_},$opts{to}";
        
        delete $opts{to};
    } else {
      $args .= " $opts{$_}";
    } # if
  } # for
  
  my $changes = $self->{P4}->Run ($cmd, $args);
  
  return $self->errors ("$cmd $args") || $changes;
} # changes

sub job ($) {
  my ($self, $job) = @_;
  
  my $jobs = $self->{P4}->IterateJobs ("-e $job");
  
  return $self->errors ("jobs -e $job") || $job;
} # job

sub comments ($) {
  my ($self, $changelist) = @_;
  
  my $change = $self->{P4}->FetchChange ($changelist);
  
  return $self->errors ("change $changelist") || $change;
} # comments

sub files ($) {
  my ($self, $changelist) = @_;
  
  my $files = $self->{P4}->Run ('files', "\@=$changelist");
  
  return $self->errors ("files \@=$changelist") || $files;
} # files

sub filelog ($;%) {
  my ($self, $fileSpec, %opts) = @_;
  
  return $self->{P4}->RunFilelog ($fileSpec, %opts);
} # filelog

sub getRevision ($;$) {
  my ($self, $filename, $revision) = @_;
  
  unless ($revision) {
    if ($filename =~ /#/) {
      ($filename, $revision) = split $filename, '#';
    } else {
      error "No revision specified in $filename";
    
      return;
    } # if
  } # unlessf

  my @contents = $self->{P4}->RunPrint ("$filename#$revision");
  
  if ($self->{P4}->ErrorCount) {
    $self->errors ("Print $filename#$revision");
    
    return;
  } else {
    return @contents;
  } # if
} # getRevision

sub getUser (;$) {
  my ($self, $user) = @_;
  
  $user //= $ENV{P4USER} || $ENV{USER};
  
  my $cmd  = 'user';
  my @args = ('-o', $user);
  
  my $userRecs = $self->{P4}->Run ($cmd, @args);
  
  # Perforce returns an array of qualifying users. We only care about the first
  # one. However if the username is invalid, Perforce still returns something 
  # that looks like a user. We look to see if there is a Type field here which
  # indicates that it's a valid user
  if ($userRecs->[0]{Type}) {
    return %{$userRecs->[0]};
  } else {
    return;
  } # if
} # getUser

sub renameSwarmUser ($$) {
  my ($self, $oldusername, $newusername) = @_;
  
  # We are turning this off because Perforce support says that just modifying
  # the keys we do not update the indexing done in the Perforce Server/Database.
  # So instead we have a PHP script (renameUser.php) which goes through the
  # official, but still unsupported, "Swarm Record API" to change the usernames
  # and call the object's method "save" which should perform the necessary
  # reindexing... Stay tuned! :-)
  #
  # BTW One needs to run renameUser.php by hand as we do not do that here. 
  return;
  
  $keys = $self->getKeys ('swarm-*') unless $keys;
  
  for (@$keys) {
    my %key = %$_;
    
    if ($key{value} =~ /$oldusername/) {
      $key{value} =~ s/\"$oldusername\"/\"$newusername\"/g;
      $key{value} =~ s/\@$oldusername /\@$newusername /g;
      $key{value} =~ s/\@$oldusername\./\@$newusername\./g;
      $key{value} =~ s/\@$oldusername,/\@$newusername,/g;
      $key{value} =~ s/ $oldusername / $newusername /g;
      $key{value} =~ s/ $oldusername,/ $newusername,/g;
      $key{value} =~ s/ $oldusername\./ $newusername\./g;
      $key{value} =~ s/-$oldusername\"/-$newusername\"/g;
      
      my $cmd = 'key';
      
      display "Correcting key $key{key}";

      my @result = $self->{P4}->Run ($cmd, $key{key}, $key{value});
      
      $self->errors ($cmd, $result[0]->{key} || 1);
    } # if
  } # for
  
  return;
} # renameSwarmUser

sub renameUser ($$) {
  my ($self, $old, $new) = @_;
  
  my $cmd  = 'renameuser';
  my @args = ("--from=$old", "--to=$new");
  
  $self->{P4}->Run ($cmd, @args);
  
  my $status = $self->errors (join ' ', $cmd, @args);
  
  return $status if $status;
  
#  return $self->renameSwarmUser ($old, $new);
} # renameUser

sub updateUser (%) {
  my ($self, %user) = @_;
  
  # Trying to do this with P4Perl is difficult. First off the structure needs
  # to be AOH and secondly you need to call SetUser to be the other user. That
  # said you need to also specify -f to force the update (which means you must
  # a admin (or superuser?) and I found no way to specify -f so I've reverted
  # back to using p4 from the command line. I also don't like having to use
  # a file here...
  my $tmpfile     = File::Temp->new;
  my $tmpfilename = $tmpfile->filename;
  
  print $tmpfile "User: $user{User}\n";
  print $tmpfile "Email: $user{Email}\n";
  print $tmpfile "Update: $user{Update}\n";
  print $tmpfile "FullName: $user{FullName}\n";
  
  close $tmpfile;
  
  my @lines  = `p4 -p $self->{P4PORT} user -f -i < $tmpfilename`;
  my $status = $?;

  return wantarray ? @lines : join '', @lines;  
} # updateUser

sub getKeys (;$) {
  my ($self, $filter) = @_;
  
  my $cmd = 'keys';
  my @args;
  
  if ($filter) {
    push @args, '-e';
    push @args, $filter;
  } # if
  
  my $keys = $self->{P4}->Run ($cmd, @args);
  
  $self->errors ($cmd . join (' ', @args), 1);
  
  return $keys; 
} # getKeys

sub key ($$) {
  my ($self, $name, $value) = @_;
  
  my $cmd = 'key';
  my @args = ($name, $value);
  
  $self->{P4}->Run ($cmd, @args);
  
  return $self->errors (join ' ', $cmd, @args);
} # key

1;
