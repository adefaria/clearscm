=pod

=head1 NAME $RCSfile: JIRAUtils.pm,v $

Some shared functions dealing with JIRA

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.0 $

=item Created

Fri Mar 12 10:17:44 PST 2004

=item Modified

$Date: 2013/05/30 15:48:06 $

=back

=head1 ROUTINES

The following routines are exported:

=cut

package Confluence;

use strict;
use warnings;

use File::Basename;
use MIME::Base64;

use Display;
use GetConfig;
use Carp;

use REST::Client;

our $VERSION  = '$Revision: 1.0 $';
   ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);
   
my $confluenceConf = $ENV{CONFLUENCE_CONF} || dirname (__FILE__) . '../etc/confluence.conf';

my %OPTS = GetConfig $confluenceConf if -r $confluenceConf;   

sub _get () {
  my ($self, $url) = @_;
  
  unless ($self->{headers}) {
    $self->{headers} = { 
      Accept        => 'application/json',
      Authorization => 'Basic ' 
                     . encode_base64 ($self->{username} . ':' . $self->{password}),
    };
  } # unless
  
  return $self->{REST}->GET ($url, $self->{headers});
} # _get

sub new (;%) {
  my ($class, %parms) = @_;
  
  my $self = bless {}, $class;
  
  $self->{username} = $parms{username} || $OPTS{username} || $ENV{CONFLUENCE_USERNAME};
  $self->{password} = $parms{password} || $OPTS{password} || $ENV{CONFLUENCE_PASSWORD};
  $self->{server}   = $parms{server}   || $OPTS{server}   || $ENV{CONFLUENCE_SERVER};
  $self->{port}     = $parms{port}     || $OPTS{port}     || $ENV{CONFLUENCE_PORT};
  $self->{URL}      = "http://$self->{server}:$self->{port}/rest/api";
  
  return $self->connect;
} # new

sub connect () {
  my ($self) = @_;
  
  $self->{REST} = REST::Client->new (
    host => "http://$self->{server}:$self->{port}",
  );
  
  $self->{REST}->getUseragent()->ssl_opts (verify_hostname => 0);
  $self->{REST}->setFollow (1);
   
  return $self; 
} # connect

sub getContent (%) {
  my ($self, %parms) = @_;
  
  my $url  = 'content?';
  
  my @parms;
  
  push @parms, "type=$parms{type}"             if $parms{type};
  push @parms, "spacekey=$parms{spaceKey}"     if $parms{spaceKey};
  push @parms, "title=$parms{title}"           if $parms{title};
  push @parms, "status=$parms{status}"         if $parms{status};
  push @parms, "postingDay=$parms{postingDay}" if $parms{postingDay};
  push @parms, "expand=$parms{expand}"         if $parms{expand};
  push @parms, "start=$parms{start}"           if $parms{start};
  push @parms, "limit==$parms{limit}"          if $parms{limit};
  
  my $content = $self->_get ('/content/', join ',', @parms);
  
  return $content;
} # getContent

1;
