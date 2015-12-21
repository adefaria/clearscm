#!/usr/bin/env perl
use strict;
use warnings;

=pod

=head1 NAME $File: //AudEngr/Import/VSS/ReleaseEng/Dev/Perforce/getPicture.pl $

Retrieve thumbnailPhoto for the userid from Active Directory

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: #1 $

=item Created

Fri Oct  3 18:16:26 PDT 2014

=item Modified

$Date: 2015/03/03 $

=back

=head1 DESCRIPTION

This script will take a userid and search the Active Directory for the user and
return an image file if the user has an image associated with his 
thumbnailPhoto attribute.

This can be configured into Perforce Swarn as documented:

http://www.perforce.com/perforce/doc.current/manuals/swarm/admin.avatars.html

One would use something like

  // this block shoudl be a peer of 'p4'
  'avatars' => array(
    'http_url'  => 'http://<server>/cgi-bin/getPicture.pl?userid={user}'
    'https_url' => 'http://<server>/cgi-bin/getPicture.pl?userid={user}',
  ),

=cut

use FindBin;
use Getopt::Long;
use Pod::Usage;
use Net::LDAP;
use CGI qw (:standard);

# Interpolate variable in str (if any) from %opts
sub interpolate ($%) {
  my ($str, %opts) = @_;

  # Since we wish to leave undefined $var references in tact the following while
  # loop would loop indefinitely if we don't change the variable. So we work
  # with a copy of $str changing it always, but only changing the original $str
  # for proper interpolations.
  my $copyStr = $str;

  while ($copyStr =~ /\$(\w+)/) {
    my $var = $1;

    if (exists $opts{$var}) {
      $str     =~ s/\$$var/$opts{$var}/;
      $copyStr =~ s/\$$var/$opts{$var}/;
    } elsif (exists $ENV{$var}) {
      $str     =~ s/\$$var/$ENV{$var}/;
      $copyStr =~ s/\$$var/$ENV{$var}/;
    } else {
     $copyStr =~ s/\$$var//;
  } # if
 } # while

 return $str;
} # interpolate

sub _processFile ($%) {
  my ($configFile, %opts) = @_;
  
  while (<$configFile>) {
    chomp;

    next if /^\s*[\#|\!]/;    # Skip comments

    if (/\s*(.*?)\s*[:=]\s*(.*)\s*/) {
      my $key   = $1;
      my $value = $2;

      # Strip trailing spaces
      $value =~ s/\s+$//;

      # Interpolate
      $value = interpolate $value, %opts;

      if ($opts{$key}) {
        # If the key exists already then we have a case of multiple values for 
        # the same key. Since we support this we need to replace the scalar
        # value with an array of values...
        if (ref $opts{$key} eq "ARRAY") {
          # It's already an array, just add to it!
          push @{$opts{$key}}, $value;
        } else {
          # It's not an array so make it one
          my @a;

          push @a, $opts{$key};
          push @a, $value;
          $opts{$key} = \@a;
        } # if
      } else {
        # It's a simple value
        $opts{$key} = $value;
      }  # if
    } # if
  } # while
  
  return %opts;
} # _processFile

sub GetConfig ($) {
  my ($filename) = @_;

  my %opts;

  open my $configFile, '<', $filename
    or die "Unable to open config file $filename";

  %opts = _processFile $configFile;

  close $configFile;

  return %opts;
} # GetConfig

sub checkLDAPError ($$) {
  my ($msg, $result) = @_;
  
  my $code = $result->code;
  
  die "$msg (Error $code)\n" . $result->error if $code;
} # checkLDAPError

my ($confFile) = ($FindBin::Script =~ /(.*)\.pl$/);
    $confFile = "$FindBin::Bin/$confFile.conf";

my %opts = GetConfig ($confFile);

## Main
$| = 1;

GetOptions (
  \%opts,
  'AD_HOST=s',
  'AD_PORT=s',
  'AD_BINDDN=s',
  'AD_BINDPW=s',
  'AD_BASEDN=s',
  'userid=s', 
) or pod2usage;

$opts{userid} = param 'userid' unless $opts{userid};

pod2usage "Usage getPicture.pl [userid=]<userid>\n" unless $opts{userid};

my $ldap = Net::LDAP->new (
  $opts{AD_HOST}, (
    host   => $opts{AD_HOST},
    port   => $opts{AD_PORT},
    basedn => $opts{AD_BASEDN},
    binddn => $opts{AD_BINDDN},
    bindpw => $opts{AD_BINDPW},
  ),
) or die $@;

my $result = $ldap->bind (
  dn       => $opts{AD_BINDDN},
  password => $opts{AD_BINDPW},
) or die "Unable to bind\n$@";

checkLDAPError ('Unable to bind', $result);

$result = $ldap->search (
  base   => $opts{AD_BASEDN},
  filter => "sAMAccountName=$opts{userid}",
);

checkLDAPError ('Unable to search', $result);

my @entries = ($result->entries);

if ($entries[0]) {
  print header 'image/jpeg';
  print $entries[0]->get_value ('thumbnailPhoto');  
} # if
