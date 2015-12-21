#!/usr/bin/env perl
use strict;
use warnings;

use Net::LDAP;
use Carp;

sub getUserEmail ($) {
  my ($userid) = @_;
  
  my (@entries, $result);

  my %opts = (
    KNOWLES_AD_HOST   => '10.252.2.28',
    KNOWLES_AD_PORT   => 389,
    KNOWLES_AD_BASEDN => 'DC=knowles,DC=com',
    KNOWLES_AD_BINDDN => 'CN=AD Reader,OU=Users,OU=KMV,OU=Knowles,DC=knowles,DC=com',
    KNOWLES_AD_BINDPW => '@Dre@D2015',
  );
  
  my $mailAttribute = 'mail';

  print "Creating new LDAP object for Knowles\n";  
  my $knowlesLDAP = Net::LDAP->new (
    $opts{KNOWLES_AD_HOST}, (
      host   => $opts{KNOWLES_AD_HOST},
      port   => $opts{KNOWLES_AD_PORT},
      basedn => $opts{KNOWLES_AD_BASEDN},
      #binddn => $opts{KNOWLES_AD_BINDDN},
      #bindpw => $opts{KNOWLES_AD_BINDPW},
    )
  ) or croak $@;
  
  print "Binding anonymously\n";  
#  if ($opts{KNOWLES_AD_BINDDN}) {
     $result = $knowlesLDAP->bind (
#      dn       => $opts{KNOWLES_AD_BINDDN},
#      password => $opts{KNOWLES_AD_BINDPW},
    ) or croak "Unable to bind\n$@";

  croak "Unable to bind (Error " . $result->code . "\n" . $result->error
    if $result->code;
  
  print "Searching for $userid\n";  
  $result = $knowlesLDAP->search (
    base   => $opts{KNOWLES_AD_BASEDN},
    filter => "sAMAccountName=$userid",
  );
  
  print "Getting entries\n";
  @entries = ($result->entries);
    
  if ($entries[0]) {
    return $entries[0]->get_value ($mailAttribute);
  } else {
    return 'Unknown';
  } # if
} # getUserEmail

print getUserEmail ('adefari');
print "\n";