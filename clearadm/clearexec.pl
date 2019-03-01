#!/usr/bin/env perl

=pod

=head1 NAME $RCSfile: clearexec.pl,v $

Execute commands on the remote system

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.11 $

=item Created:

Mon Dec 13 09:13:27 EST 2010

=item Modified:

$Date: 2012/04/27 14:47:22 $

=back

=head1 SYNOPSIS

 Usage clearexec.pl: [-u|sage] [-ve|rbose] [-deb|ug]
                     [-h|ost <host>] [-p|ort <port>] [<cmd>]

 Where:
   -u|sage:       Displays usage
 
   -ve|rbose:     Be verbose
   -deb|ug:       Output debug messages
 
   -h|ost <host>: Host to contact (Default: localhost)
   -p|ort <port>: Port to connect to (Default: 25327) 
   <cmd>          Command to perform
     
=head1 DESCRIPTION

This script exercises the clearserver.pl daemon by executing a command on the
remote host:port that the clearserver.pl daemon is running on

=cut

use strict;
use warnings;

use Getopt::Long;
use FindBin;
use Term::ANSIColor qw (color);

use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Clearexec;
use CmdLine;
use Display;
use Utils;

my $VERSION  = '$Revision: 1.11 $';
  ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);

my $me = $FindBin::Script;
   $me =~ s/\.pl$//;
   
local $0 = $me;

my $host = $Clearexec::CLEAROPTS{CLEAREXEC_HOST};
my $port = $Clearexec::CLEAROPTS{CLEAREXEC_PORT};

my $clearexec;

sub CmdLoop () {
  my ($line, $result);

  my $prompt = color ('BOLD YELLOW') . "$me->$host:" . color ('RESET');
  
  $CmdLine::cmdline->set_prompt ($prompt);
    
  while (($line, $result) = $CmdLine::cmdline->get ()) {
    last unless defined $line;
    last if $line =~ /exit|quit/i;
    
    my ($status, @output) = $clearexec->execute ($line);
    
    last if $line =~ /stopserver/i;
    
    if ($status) {
      error "Non zero status returned from $line ($status)\n" . join "\n", @output;
    } else {
      display join "\n", @output;
      display "Status: $status"
        if $status;
    } # if
  } # while
  
  return; 
} # CmdLoop

# Main
GetOptions (
  'usage'   => sub { Usage },
  'verbose' => sub { set_verbose },
  'debug'   => sub { set_debug },
  'host=s'  => \$host,
  'port=s'  => \$port,
) or Usage "Invalid parameter";

my $cmd = join ' ', @ARGV;

verbose "$FindBin::Script V$VERSION";

$clearexec =Clearexec->new;

my ($status, @output);

$status = $clearexec->connectToServer ($host, $port);

error "Unable to connect to $host:$port", 1
  unless $status;

if ($cmd ne '') {
  ($status, @output) = $clearexec->execute ($cmd);

  if ($status) {
    error "Unable to execute $cmd (Status: $status)\n" . join ("\n", @output), 1;
  } else {
    display join "\n", @output;
    display "Status: $status";
  } # if
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
<a href="http://clearscm.com/php/scm_man.php?file=clearadm/lib/Clearexec.pm">Clearexec</a><br>
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
