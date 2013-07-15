#!/usr/bin/perl

=pod

=head1 NAME $RCSfile: setup.pl,v $

Setup Clearadm

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.1 $

=item Created:

Mon Dec 13 09:13:27 EST 2010

=item Modified:

$Date: 2011/01/09 18:12:05 $

=back

=head1 SYNOPSIS

 Usage setup.pl: [-u|sage] [-ve|rbose] [-deb|ug]
                 [-package [all|agent|database|tasks|web]]

 Where:
   -u|sage:       Displays usage
 
   -ve|rbose:     Be verbose
   -deb|ug:       Output debug messages
   
   -package:      Which subpackage to set up (Default: all). 

=head1 DESCRIPTION

This script will setup Clearadm packages on machines. You must be root
(or administrator on Windows) to setup packages. Setting up web package
configures the web server. Setting up the tasks portion sets up cleartasks
poriton. Cleartasks periodically runs the predefined and user defined
tasks and should only be set up on one machine. The agent package sets up 
clearagent.pl. This should be run on all machines that you intend to monitor. 
The database package sets up the Clearadm database.
 
Default, sets up all packages on the current machine.

=cut

use strict;
use warnings;

use Socket;

use FindBin;
use Getopt::Long;

use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Clearadm;
use Display;
use OSDep;
use Utils;

my $VERSION  = '$Revision: 1.1 $';
  ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);
  
sub SetupAgent () {
  verbose 'Setting up Agent...';
  
  my ($status, @output, $cmd);
  
  if ($ARCH eq 'cygwin') {
     verbose '[Cygwin] Creating up Clearagent Service';
     
     $cmd  = 'cygrunsrv -I clearagent -p C:/Cygwin/bin/perl ';
     $cmd .= '> -a "/opt/clearscm/clearadm/clearagent.pl -nodaemon"';
     
    ($status, @output) = Execute "$cmd 2>&1";
  
    error "Unable to execute $cmd (Status: $status)\n" . join ("\n", @output), 1
      if $status;
      
    verbose '[Cygwin] Starting Clearagent Service';
    
    $cmd .= 'net start clearagent';
    ($status, @output) = Execute "$cmd 2>&1";
  
    error "Unable to execute $cmd (Status: $status)\n" . join ("\n", @output), 1
      if $status;
  } else {
    my $Arch = ucfirst $ARCH;
  
    verbose 'Creating clearagent user';
    
    $cmd = 'useradd -Mr clearagent';
    
    ($status, @output) = Execute "$cmd 2>&1";
  
    if ($status == 9) {
       warning "The user clearagent already exists";
    } elsif ($status != 0) {
      error "Unable to execute $cmd (Status: $status)\n" . join ("\n", @output), 1;
    } # if

    verbose 'Setting permissions on log and var directories';
    
    $cmd  = "chmod 777 $Clearadm::CLEAROPTS{CLEARADM_BASE}/var;";
    $cmd .= "chmod 777 $Clearadm::CLEAROPTS{CLEARADM_BASE}/var/run;";
    $cmd .= "chmod 777 $Clearadm::CLEAROPTS{CLEARADM_BASE}/log";
  
    ($status, @output) = Execute "$cmd 2>&1";
  
    error "Unable to execute $cmd (Status: $status)\n" . join ("\n", @output), 1
      if $status;

    verbose "[$Arch] Setting up clearagent daemon";
       
    # Symlink $CLEARADM/etc/conf.d/clearadm -> /etc/init.d
    my $confdir = '/etc/init.d';

    error "Cannot find conf.d directory ($confdir)", 1
      unless -d $confdir;

    unless (-e "$confdir/clearadm") {
      $cmd = "ln -s $FindBin::Bin/etc/init.d/clearadm $confdir";
  
      ($status, @output) = Execute "$cmd 2>&1";
  
      error "Unable to execute $cmd (Status: $status)\n" . join ("\n", @output), 1
        if $status;
    } # unless

    # Setup runlevel links
    $cmd = 'update-rc.d clearagent defaults';
    
    ($status, @output) = Execute "$cmd 2>&1";
  
    error "Unable to execute $cmd (Status: $status)\n" . join ("\n", @output), 1
      if $status;
      
    verbose 'Starting clearagent';
    
    $cmd = 'service clearagent start';
  
    error "Unable to execute $cmd (Status: $status)\n" . join ("\n", @output), 1
      if $status;
  } # if

  verbose "Done";
        
  return;
} # SetupAgent

sub SetupTasks () {
  my ($status, @output, $cmd);
   
  verbose 'Setting up Tasks...';

  # Symlink $CLEARADM/etc/conf.d/cleartasks -> /etc/init.d
  my $confdir = '/etc/init.d';

  error "Cannot find conf.d directory ($confdir)", 1
    unless -d $confdir;

  unless (-e "$confdir/clearadm") {
    $cmd = "ln -s $FindBin::Bin/etc/init.d/cleartasks $confdir";
  
    ($status, @output) = Execute "$cmd 2>&1";
 
    error "Unable to execute $cmd (Status: $status)\n" . join ("\n", @output), 1
      if $status;
  } # unless

  # Setup runlevel links
  $cmd = 'update-rc.d cleartasks defaults';
    
  ($status, @output) = Execute "$cmd 2>&1";
  
  error "Unable to execute $cmd (Status: $status)\n" . join ("\n", @output), 1
    if $status;
 
  verbose 'Starting cleartasks';
    
  $cmd = 'service cleartasks start';
  
  ($status, @output) = Execute "$cmd 2>&1";
  
  error "Unable to execute $cmd (Status: $status)\n" . join ("\n", @output), 1
    if $status;

  verbose 'Done';
        
  return;
} # SetupTasks
 
sub SetupWeb () {
  verbose 'Setting up Web...';
  
  my ($status, @output, $cmd);
  
  # Symlink $CLEARADM/etc/conf.d/clearadm -> /etc/apache2/conf.d
  my $confdir = '/etc/apache2/conf.d';

  error "Cannot find Apache 2 conf.d directory ($confdir)", 1
    unless -d $confdir;

  unless (-e "$confdir/clearadm") {
    $cmd = "ln -s $FindBin::Bin/etc/conf.d/clearadm $confdir";
  
    ($status, @output) = Execute "$cmd 2>&1";
  
    error "Unable to execute $cmd (Status: $status)\n" . join ("\n", @output), 1
      if $status;
  } # unless
    
  if ($ARCH eq 'cygwin') {
    $cmd = 'net stop apache2; net start apache2';
  } else {
    $cmd = '/etc/init.d/apache2 restart';
  } # if
  
  ($status, @output) = Execute "$cmd 2>&1";
  
  error "Unable to execute $cmd (Status: $status)\n" . join ("\n", @output), 1
    if $status;

  verbose 'Done';
  
  return;
} # SetupWeb

sub SetupDatabase () {
  verbose 'Setting up Database';
  
  my ($status, @output, $cmd);
  
  # TODO: Probably need to use -u root -p and prompt for MySQL root user's
  # password.
  $cmd = "mysql < $Clearadm::CLEAROPTS{CLEARADM_BASE}/etc/clearadm.sql";
  
  ($status, @output) = Execute "$cmd 2>&1";
  
  error "Unable to execute $cmd (Status: $status)\n" . join ("\n", @output), 1
    if $status;

  verbose 'Setting up database users';
        
  $cmd = "mysql clearadm < $Clearadm::CLEAROPTS{CLEARADM_BASE}/etc/users.sql";
  
  ($status, @output) = Execute "$cmd 2>&1";
  
  error "Unable to execute $cmd (Status: $status)\n" . join ("\n", @output), 1
    if $status;

  verbose 'Setting up predefined tasks';
        
  $cmd = "mysql clearadm < $Clearadm::CLEAROPTS{CLEARADM_BASE}/etc/load.sql";
  
  ($status, @output) = Execute "$cmd 2>&1";
  
  error "Unable to execute $cmd (Status: $status)\n" . join ("\n", @output), 1
    if $status;

  verbose 'Done';
  
  return;
} # SetupDatbase

# Main
error "Cannot setup Clearadm when using Windows - hint try using Cgywin", 1 
  if $ARCH eq 'windows';

Usage 'You must be root'
  unless $> == 0 or $ARCH eq 'cygwin'; 
  
my $package = 'all';

GetOptions (
  usage       => sub { Usage },
  verbose     => sub { set_verbose },
  debug       => sub { set_debug },
  'package=s' => \$package,
) or Usage "Invalid parameter";

Usage 'Extraneous options: ' . join ' ', @ARGV
  if @ARGV;

# Announce ourselves
verbose "$FindBin::Script V$VERSION";

my @validPackages = (
  'all',
  'agent',
  'database',
  'tasks',
  'web',
);

my $lcpackage = lc $package;

unless (InArray $lcpackage, @validPackages) {
  Usage "Invalid -package $package";
} # unless

if ($lcpackage eq 'all') {
  SetupAgent;
  SetupDatabase;
  SetupTasks;
  SetupWeb;
} elsif ($lcpackage eq 'agent') {
  SetupAgent;
} elsif ($lcpackage eq 'database') {
  SetupDatabase;
} elsif ($lcpackage eq 'tasks') {
  SetupTasks;
} elsif ($lcpackage eq 'agent') {
  SetupWeb;
} # if
 
=pod