#!/usr/bin/perl

=pod

=head1 NAME $RCSfile: clearagent.pl,v $

Daemon process to run commands on current host in response to requests from 
other hosts.

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.11 $

=item Created:

Mon Dec 13 09:13:27 EST 2010

=item Modified:

$Date: 2011/02/02 18:43:53 $

=back

=head1 SYNOPSIS

 Usage clearagent.pl: [-u|sage] [-ve|rbose] [-deb|ug]

 Where:
   -u|sage:         Displays usage
 
   -ve|rbose:       Be verbose
   -de|bug:         Output debug messages
   
   -da|emon:        Run in daemon mode (Default)
   -m|ultithreaded: Multithread requests (Default)
   -p|idfile:       File to be created with the pid written to it (Default: 
                    clearagent.pid). Note: pidfile is only written if -daemon
                    is specified.
   
=head1 DESCRIPTION

This script normally runs as a daemon and accepts requests from other hosts to
execute commands locally and send back the results.

=cut

use strict;
use warnings;

use Getopt::Long;
use FindBin;

use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Clearadm;
use Clearexec;
use Display;
use Utils;

my $VERSION  = '$Revision: 1.11 $';
  ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);
  
my $pidfile = "$Clearexec::CLEAROPTS{CLEAREXEC_RUNDIR}/$FindBin::Script.pid";

# Augment PATH with $Clearadm::CLEAROPTS{CLEARADM_BASE}
$ENV{PATH} .= ":$Clearadm::CLEAROPTS{CLEARADM_BASE}";

my $clearexec;

# Main
my $multithreaded = $Clearexec::CLEAROPTS{CLEAREXEC_MULTITHREADED};
my $daemon        = 1;

GetOptions (
  'usage'           => sub { Usage },
  'verbose'         => sub { set_verbose },
  'debug'           => sub { set_debug },
  'daemon!'         => \$daemon,
  'multithreaded!'  => \$multithreaded,
  'pidfile=s'       => \$pidfile,
) or Usage "Invalid parameter";

Usage 'Extraneous options: ' . join ' ', @ARGV
  if @ARGV;

$clearexec = Clearexec->new;

$clearexec->setMultithreaded ($multithreaded);

my $logfile = "$Clearexec::CLEAROPTS{CLEAREXEC_LOGDIR}/$FindBin::Script.log";

EnterDaemonMode $logfile, $logfile, $pidfile
  if $daemon;
  
display "$FindBin::Script V$VERSION started at " . localtime;

$clearexec->startServer;

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

Copyright (c) 2010, ClearSCM, Inc. All rights reserved.

=cut
