#!/usr/bin/env perl

=pod

=head1 NAME $RCSfile: updatela.pl,v $

Update Load Average

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.29 $

=item Created:

Mon Dec 13 09:13:27 EST 2010

=item Modified:

$Date: 2011/06/16 15:14:52 $

=back

=head1 SYNOPSIS

 Usage updatela.pl: [-u|sage] [-ve|rbose] [-deb|ug]
                    [-host [<host>|all]]

 Where:
   -u|sage:     Displays usage
 
   -ve|rbose:   Be verbose
   -deb|ug:     Output debug messages
   
   -host [<host>|all]: Update host or all hosts (Default: all)
   -fs   [<fs>|all]:   Update filesystem or all (Default: all)   

=head1 DESCRIPTION

This script will record the load average of a system

=cut

use strict;
use warnings;

use Net::Domain qw(hostname);
use FindBin;
use Getopt::Long;

use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Clearadm;
use Clearexec;
use DateUtils;
use Display;
use Utils;

my $VERSION  = '$Revision: 1.29 $';
  ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);

my $clearadm  = Clearadm->new;
my $clearexec = Clearexec->new; 

my $host;

# Given a host, formulate a loadavg record
sub snapshotLoad ($) {
  my ($systemRef) = @_;

  my %system = %{$systemRef};
  
  my ($status, @output);

  $status = $clearexec->connectToServer (
    $system{name}, $system{port}
  );
  
  error "Unable to connect to system $system{name}:$system{port}", 1
    unless $status;
  
  verbose "Snapshotting load on $system{name}";
  
  my %load = (
    system => $system{name},
  );

  my $cmd = 'uptime';
  
  ($status, @output) = $clearexec->execute ($cmd);

  return
    if $status;

  # Parsing uptime is odd. Sometimes we get output like
  #
  #  10:11:59 up 17 days, 22:11,  6 users,  load average: 1.08, 1.10, 1.10
  #
  # And sometimes we get output like:
  #
  #  10:11:15 up 23:04,  0 users,  load average: 0.00, 0.00, 0.00
  #
  # Notice that if the machine was up for less than a day you don't get the
  # "x days" portion of output. There is no real controls on uptime to format
  # the output better, so we parse for either format.
  if ($output[0] =~ /up\s+(.+?),\s+(.+?),\s+(\d+) user.*load average:\s+(.+?),/) {
    $load{uptime}  = "$1 $2";
    $load{users}   = $3;
    $load{loadavg} = "$4";
  } elsif ($output[0] =~ /up\s+(.+?),\s+(\d+) user.*load average:\s+(.+?),/) {
    $load{uptime}  = "$1";
    $load{users}   = $2;
    $load{loadavg} = "$3";
  } else {
    warning "Unable to parse output of uptime from $system{name}";
    return;
  } # if

  # On Windows sytems, Cygwin's uptime does not return a loadavg at all - it
  # returns only 0! So we have load.vbs which give us the LoadPercentage
  if ($system{type} =~ /windows/i) {
    my $loadvbs = 'c:/cygwin/opt/clearscm/clearadm/load.vbs';
    $cmd = "cscript /nologo $loadvbs";
  	
    ($status, @output) = $clearexec->execute ($cmd);
  	
    chop @output if $output[0] =~ /\r/;
  	
    return
      if $status;
  	  
    $load{loadavg} = $output[0] / 100;
  } # if
  
  $clearexec->disconnectFromServer;
  
  return %load;  
} # snapshotLoad

# Main
GetOptions (
  'usage'   => sub { Usage },
  'verbose' => sub { set_verbose },
  'debug'   => sub { set_debug },
  'host=s'  => \$host,
) or Usage "Invalid parameter";

Usage 'Extraneous options: ' . join ' ', @ARGV
  if @ARGV;

# Announce ourselves
verbose "$FindBin::Script V$VERSION";

my $exit = 0;

foreach my $system ($clearadm->FindSystem ($host)) {
  next if $$system{active} eq 'false';
  
  my %load = snapshotLoad $system;
  
  if (%load) {
    my ($err, $msg) = $clearadm->AddLoadavg (%load);
  
    error $msg, $err if $err;
  } else {
    error "Unable to get loadavg for system $$system{name}", 1;
  } # if
  
  # Check if over threshold
  my %notification = $clearadm->GetNotification ('Loadavg');

  next
    unless %notification;
  
  if ($load{loadavg} >= $$system{loadavgThreshold}) {
    $exit = 2;
    error YMDHMS . " System: $$system{name} "
        . "Loadavg $load{loadavg} "
        . "Threshold $$system{loadavgThreshold}";
  } else {
    $clearadm->ClearNotifications ($$system{name});
  } # if
} # foreach

exit $exit;

=pod

=head1 CONFIGURATION AND ENVIRONMENT

DEBUG: If set then $debug is set to this level.

VERBOSE: If set then $verbose is set to this level.

TRACE: If set then $trace is set to this level.

=head1 DEPENDENCIES

=head2 Perl Modules

L<FindBin>

L<Getopt::Long|Getopt::Long>

L<Net::Domain|Net::Domain>

=head2 ClearSCM Perl Modules

=begin man 

 Clearadm
 Clearexec
 DateUtils
 Display
 Utils

=end man

=begin html

<blockquote>
<a href="http://clearscm.com/php/scm_man.php?file=clearadm/lib/Clearadm.pm">Clearadm</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=clearadm/lib/Clearexec.pm">Clearexec</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/DateUtils.pm">DateUtils</a><br>
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
