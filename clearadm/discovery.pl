#!/usr/bin/perl

=pod

=head1 NAME $RCSfile: discovery.pl,v $

Update System

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.1 $

=item Created:

Mon Dec 13 09:13:27 EST 2010

=item Modified:

$Date: 2011/01/07 20:48:22 $

=back

=head1 SYNOPSIS

 Usage updatesystem.pl: [-u|sage] [-ve|rbose] [-deb|ug]
                        [-b|roadcastTime <seconds>]

 Where:
   -u|sage:       Displays usage
 
   -ve|rbose:     Be verbose
   -deb|ug:       Output debug messages
   
   -broadcastA|ddr <ip>:      Broadcast IP (Default: Current subnet)
   -broadcastT|ime <seconds>: Number of sends to wait for responses to broadcast
                              (Default: 30 seconds)

=head1 DESCRIPTION

This script will discover systems on the local subnet and then add or update
them in the Clearadm database.

=cut

use strict;
use warnings;

use Socket;

use FindBin;
use Getopt::Long;

use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Clearadm;
use Display;
use Utils;

my $VERSION  = '$Revision: 1.1 $';
  ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);

my $clearadm = Clearadm->new;

my $broadcastTime = 10;

sub discover ($) {
  my ($broadcast) = @_;
  
  my $startTime = time;

  my %hosts;

  verbose "Performing discovery (for $broadcastTime seconds)...";

  while (<$broadcast>) {
    if (/from (.*):/) {
      my $ip       = $1;
      my $hostname = gethostbyaddr (inet_aton ($ip), AF_INET);
     
       unless ($hosts{$ip}) {
         verbose "Received response from ($ip): $hostname";
         $hosts{$ip} = $hostname;
       } # unless
    } # if
  
    last
      if (time () - $startTime) > $broadcastTime;
  } # while

  verbose "$broadcastTime seconds has elapsed - discovery complete";

  return %hosts
} # discover

# Main
my $broadcastAddress = inet_ntoa (INADDR_BROADCAST);

GetOptions (
  usage             => sub { Usage },
  verbose           => sub { set_verbose },
  debug             => sub { set_debug },
  'broadcastTime=s' => \$broadcastTime,
  'broadcastAddr=s' => \$broadcastAddress,  
) or Usage "Invalid parameter";

Usage 'Extraneous options: ' . join ' ', @ARGV
  if @ARGV;

# Announce ourselves
verbose "$FindBin::Script V$VERSION";

my $broadcastCmd = "ping -b $broadcastAddress 2>&1";

my $pid = open my $broadcast, '-|', $broadcastCmd
  or error "Unable to do $broadcastCmd", 1;

my %hosts = discover $broadcast;

kill TERM => $pid;

close $broadcast;

my $nbrHosts = scalar keys %hosts;  

verbose_nolf "Found $nbrHosts host";
verbose_nolf 's' if $nbrHosts != 1;
verbose      " on subnet $broadcastAddress";

foreach (sort values %hosts) {
  my $verbose = get_verbose () ? '-verbose' : '';
  
  my ($status, @output) = Execute "updatesystem.pl -host $_ $verbose";

  error "Unable to update host $_ (Status: $status)\n"
      . join ("\n", @output), 1
    if $status;
    
  verbose join "\n", @output;
} # foreach

=pod

=head1 CONFIGURATION AND ENVIRONMENT

DEBUG: If set then $debug is set to this level.

VERBOSE: If set then $verbose is set to this level.

TRACE: If set then $trace is set to this level.

=head1 DEPENDENCIES

=head2 Perl Modules

L<FindBin>

L<Getop::Long|Getopt::Long>

L<Socket>

=head2 ClearSCM Perl Modules

=begin man 

 Clearadm
 Display
 Utils

=end man

=begin html

<blockquote>
<a href="http://clearscm.com/php/scm_man.php?file=clearadm/lib/Clearadm.pm">Clearadm</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Display.pm">Display</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Utils.pm">Utils</a><br>
</blockquote>

=end html

=head1 BUGS AND LIMITATIONS

There are no known bugs in this script

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, ClearSCM, Inc. All rights reserved.

=cut