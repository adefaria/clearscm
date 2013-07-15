#!/usr/bin/perl

=pod

=head1 NAME $RCSfile: ccdb.pl,v $

Request Clearcase metadata from CCDB

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.4 $

=item Created:

Fri Mar 11 19:09:52 PST 2011

=item Modified:

$Date: 2011/05/05 18:33:33 $

=back

=head1 SYNOPSIS

 Usage ccdb.pl: [-u|sage] [-ve|rbose] [-deb|ug]
                [-h|ost <host>] [-p|ort <port>] [<cmd>]

 Where:
   -u|sage:       Displays usage
 
   -ve|rbose:     Be verbose
   -deb|ug:       Output debug messages
 
   -h|ost <host>: Host to contact (Default: localhost)
   -p|ort <port>: Port to connect to (Default: 25327) 
   <requests>     Request to perform
     
=head1 DESCRIPTION

This script exercises the ccdbserver.pl daemon by requesting Clearcase metadata
from the remote host:port that the ccdbserver.pl daemon is running on.

Requests are of the variety:

 <method> <parms>

=cut

use strict;
use warnings;

use Getopt::Long;
use FindBin;

use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use CCDBService;
use Display;
use Utils;

my $VERSION  = '$Revision: 1.4 $';
  ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);

my $me = $FindBin::Script;
   $me =~ s/\.pl$//;
   
local $0 = $me;

my $CCDBService;

sub DisplayOutput ($$) {
  my ($status, $output) = @_;
  
  if ($status) {
    error "Unable to service request (Status: $status)";
    display join "\n", @$output;
  } else {
    if (ref $output eq 'HASH') {
      foreach (keys %$output) {
        display "$_:$$output{$_}";
      } # foreach
    } elsif (ref $output eq 'ARRAY') {
      foreach (@$output) {
        my %rec = %$_;
        
        display '-' x 80;
        
        foreach (keys %rec) {
          my $data  = "$_:";
             $data .= $rec{$_} ? $rec{$_} : '';

          display $data;
        } # foreach
      } # foreach
      
      display      '=' x 80;
      display_nolf scalar @$output;
      display_nolf ' record';
      display_nolf 's' if @$output > 1;
      display      ' qualified';
    } # if
  } # if
  
  return;
} # DisplayOutput

sub CmdLoop () {
  while () {
    display_nolf "CCDB:";
  
    my $request = <STDIN>;
    
    chomp $request;
    
    last if $request =~ /^exit|^quit/i;
    
    my ($status, $output) = $CCDBService->execute ($request);
    
    DisplayOutput ($status, $output);
    
    last if $request =~ /stopserver/i;
  } # while
  
  return; 
} # CmdLoop

# Main
GetOptions (
  'usage'   => sub { Usage },
  'verbose' => sub { set_verbose },
  'debug'   => sub { set_debug },
  'host=s'  => \$CCDBService::OPTS{CCDB_HOST},
  'port=s'  => \$CCDBService::OPTS{CCDB_PORT},
) or Usage "Invalid parameter";

my $request = join ' ', @ARGV;

display "$FindBin::Script V$VERSION";

$CCDBService = CCDBService->new;

my ($status, $output);

$status = $CCDBService->connectToServer (
  $CCDBService::OPTS{CCDB_HOST},
  $CCDBService::OPTS{CCDB_PORT}
);

error 'Unable to connect to '
    . "$CCDBService::OPTS{CCDB_HOST}:$CCDBService::OPTS{CCDB_PORT}", 1
  unless $status;

if ($request ne '') {
  ($status, $output) = $CCDBService->execute ($request);
  
  DisplayOutput $status, $output;
} else {
  CmdLoop;
} # if

=pod

=head1 CONFIGURATION AND ENVIRONMENT

DEBUG: If set then $debug is set to this level.

VERBOSE: If set then $verbose is set to this level.

TRACE: If set then $trace is set to this level.

=head1 DEPENDENCIES

=head2 Perl Modules

L<FindBin>

L<Getopt::Long|Getopt::Long>

=head2 ClearSCM Perl Modules

=begin man 

 Clearexec
 Display
 Utils

=end man

=begin html

<blockquote>
<a href="http://clearscm.com/php/cvs_man.php?file=clearadm/lib/Clearexec.pm">Clearexec</a><br>
<a href="http://clearscm.com/php/cvs_man.php?file=lib/Display.pm">Display</a><br>
<a href="http://clearscm.com/php/cvs_man.php?file=lib/Utils.pm">Utils</a><br>
</blockquote>

=end html

=head1 BUGS AND LIMITATIONS

There are no known bugs in this script

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, Tellabs, Inc. All rights reserved.

=cut
