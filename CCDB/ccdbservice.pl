#!/usr/bin/perl

=pod

=head1 NAME $RCSfile: ccdbservice.pl,v $

ClearCase DataBase Service: Respond to requests for Clearcase metadata from
CCDB.

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.1 $

=item Created:

Fri Mar 11 17:45:57 PST 2011

=item Modified:

$Date: 2011/03/22 19:18:04 $

=back

=head1 SYNOPSIS

 Usage ccdbservice.pl: [-u|sage] [-ve|rbose] [-de|bug] 
                       [-da|emon] [-m|ultithreaded] [-p|idfile]
                       [-l|ogfile <logfile>]

 Where:
   -u|sage:         Displays usage
 
   -ve|rbose:       Be verbose
   -de|bug:         Output debug messages
   
   -da|emon:        Run in daemon mode. Use -nod|aemon to run in foreground
                    (Default: -daemon)
   -m|ultithreaded: Multithread requests. Use -nom|ultithreaded to single
                    thread request handline (Default: -multithreaded)
   -p|idfile:       File to be created with the pid written to it (Default: 
                    ccddservice.pid). Note: pidfile is only written if -daemon
                    is specified.
   -l|ogfile:       Specify alternative logfile name. Note that .log will be 
                    appended. (Default: ccdbservice.log).
                    
Note: Certain options can be set in ../etc/ccdbserver.conf. See ccdbserver.conf
for more info.
   
=head1 DESCRIPTION

This script normally runs as a daemon and accepts requests from other hosts to
retrieve Clearcase metadata from CCDB.

=cut

use strict;
use warnings;

use Getopt::Long;
use FindBin;

use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use CCDB;
use CCDBService;
use Display;
use Utils;

my $VERSION  = '$Revision: 1.1 $';
  ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);

# Extract relative path and basename from script name.
my $me = $FindBin::Script;
  
# Remove .pl for Perl scripts that have that extension
$me =~ s/\.pl$//;
  
my $pidfile = 
  "$CCDBService::OPTS{CCDB_RUNDIR}/$me.pid";
my $logfile = 
  "$CCDBService::OPTS{CCDB_LOGDIR}/$me.log";
  
# Main
my $multithreaded = $CCDBService::OPTS{CCDB_MULTITHREADED};
my $daemon        = 1;

GetOptions (
  'usage'           => sub { Usage },
  'verbose'         => sub { set_verbose },
  'debug'           => sub { set_debug },
  'daemon!'         => \$daemon,
  'multithreaded!'  => \$multithreaded,
  'pidfile=s'       => \$pidfile,
  'logfile=s'       => \$logfile,
) or Usage "Invalid parameter";

Usage 'Extraneous options: ' . join ' ', @ARGV
  if @ARGV;

my $CCDBService = CCDBService->new;

$CCDBService->setMultithreaded ($multithreaded);

EnterDaemonMode $logfile, $logfile, $pidfile
  if $daemon;
  
display "$FindBin::Script V$VERSION started at " . localtime;

$CCDBService->startServer;

verbose "Server running";

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

