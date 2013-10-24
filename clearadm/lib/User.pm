=pod

=head2 NAME $RCSfile: User.pm,v $

Return information about a user

=head2 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.4 $

=item Created

Tue Jan  3 11:36:10 PST 2006

=item Modified

$Date: 2011/01/09 01:03:10 $

=back

=head2 SYNOPSIS

This module implements a User object which returns information about a user.

 my $user = new User ('adefaria');
 
 print "Fullname: $user->{fullname}\n";
 print "EMail: $user->{email}\n";
 
=head2 DESCRIPTION

This module instanciates a user object for the given user identifier and 
then collects information about the user such as fullname, email, etc. It does
so by contacting Active Directory in a Windows domain or other directory servers
depending on the site. As such exactly what data members are available may 
change or be different from site to site.

=cut

package User;

use strict;
use warnings;

use Carp;
use Net::LDAP;

use GetConfig;

# Seed options from config file
our %CLEAROPTS= GetConfig ("$FindBin::Bin/etc/clearuser.conf");

our $VERSION  = '$Revision: 1.4 $';
   ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);
   
# Override options if in the environment
$CLEAROPTS{CLEARUSER_LDAPHOST} = $ENV{CLEARUSER_LDAPHOST}
  if $ENV{CLEARUSER_LDAPHOST};
$CLEAROPTS{CLEARUSER_BIND}     = $ENV{CLEARUSER_BIND}
  if $ENV{CLEARUSER_BIND};
$CLEAROPTS{CLEARUSER_USERNAME} = $ENV{CLEARUSER_USERNAME}
  if $ENV{CLEARUSER_USERNAME};
$CLEAROPTS{CLEARUSER_PASSWORD} = $ENV{CLEARUSER_PASSWORD}
  if $ENV{CLEARUSER_PASSWORD};
$CLEAROPTS{CLEARUSER_BASEDN}   = $ENV{CLEARUSER_BASEDN}
  if $ENV{CLEARUSER_BASEDN};

my ($ldap, $ad);

sub unix2sso ($) {
  my ($unix) = @_;

  my $firstchar  = substr $unix, 0, 1;
  my $secondchar = substr $unix, 1, 1;

  # Crazy mod 36 math!
  my $num = (ord ($firstchar) - 97) * 36 + (ord ($secondchar) - 97) + 100;

  my $return = $num . substr $unix, 2, 6;

  return $return;
} # unix2sso

sub GetOwnerInfo ($) {
  my ($userid) = @_;
  
  my @parts = split /(\/|\\)/, $userid;

  if (@parts == 3) {
    $userid = $parts[2];
  } # if

  my $sso = unix2sso ($userid);
  
  unless ($ldap) {
    $ldap = Net::LDAP->new ($CLEAROPTS{CLEARUSER_LDAPHOST})
      or croak 'Unable to create LDAP object';
      
    $ad = $ldap->bind (
      "$CLEAROPTS{CLEARUSER_USERNAME}\@$CLEAROPTS{CLEARUSER_BIND}",
      password => $CLEAROPTS{CLEARUSER_PASSWORD});
  } # unless
  
  $ad = $ldap->search (
    base   => $CLEAROPTS{CLEARUSER_BASEDN},
    filter => "(&(objectclass=user)(sAMAccountName=$sso))",
  );
  
  $ad->code 
    && croak $ad->error;
    
  my @entries = $ad->entries;

  my %ownerInfo;
    
  if (@entries == 1) {
    for (my $i = 0; $i < $ad->count; $i++) {
      my $entry = $ad->entry ($i);

      foreach my $attribute ($entry->attributes) {
        $ownerInfo{$attribute} = $entry->get_value ($attribute)
      } # foreach
    } # for
    
    return %ownerInfo;
  } else {
    return;
  } # if 
} # GetOwnerInfo

=pod

=item new ($id)

Returns a new user object based on $id

Parameters:

=begin html

<blockquote>

=end html

=over

=item $id

User identifier

=back

=begin html

</blockquote>

=end html

Returns:

=begin html

<blockquote>

=end html

=over

=item User object

=back

=begin html

</blockquote>

=end html

=cut

sub new ($) {
  my ($class, $userid) = @_;

  croak "Must specify userid to User constructor"
    if @_ == 1;
    
  my %members;
  
  $members{id} = $userid;
  
  my %ownerInfo = GetOwnerInfo ($userid);
  
  $members{$_} = $ownerInfo{$_}
    foreach (keys %ownerInfo);
  
  return bless \%members, $class;
} # new

1;

=pod

=head1 CONFIGURATION AND ENVIRONMENT

DEBUG: If set then $debug is set to this level.

VERBOSE: If set then $verbose is set to this level.

TRACE: If set then $trace is set to this level.

=head1 DEPENDENCIES

=head2 Perl Modules

L<Carp>

L<Net::LDAP|Net::LDAP>

=head2 ClearSCM Perl Modules

=begin man 

 GetConfig

=end man

=begin html

<blockquote>
<a href="http://clearscm.com/php/scm_man.php?file=lib/GetConfig.pm">GetConfig</a><br>
</blockquote>

=end html

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, ClearSCM, Inc. All rights reserved.

=cut
