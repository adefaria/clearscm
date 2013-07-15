#!/usr/bin/perl

=pod

=head1 NAME $RCSfile: updatesystem.pl,v $

Update System

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.17 $

=item Created:

Mon Dec 13 09:13:27 EST 2010

=item Modified:

$Date: 2012/11/09 06:44:38 $

=back

=head1 SYNOPSIS

 Usage updatesystem.pl: [-u|sage] [-ve|rbose] [-deb|ug]
                        [-del|ete -h|ost <host>]

 Where:
   -u|sage:       Displays usage
 
   -ve|rbose:     Be verbose
   -deb|ug:       Output debug messages
   
   -del|ete:      Delete host
   -h|ost <host>: Host to operate on (Default: Current host)
   -p|ort <port>: Clearexec port to connect to

=head1 DESCRIPTION

This script will add/update the system to the Clearadm database.  You can also
delete a system from the Clearadm database.

=cut

use strict;
use warnings;

use Sys::Hostname;

use FindBin;
use Getopt::Long;

use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Clearadm;
use Clearexec;
use Display;
use Utils;

my $VERSION  = '$Revision: 1.17 $';
  ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);

my $clearadm  = Clearadm->new;
my $clearexec = Clearexec->new;

my ($delete, $host, $port);

sub GetFilesystems (%) {
  my (%system) = @_;
  
  # TODO: Unix/Linux systems often vary as to what parameters df supports. The
  # -P is to intended to make this POSIX standard. Need to make sure this works
  # on other systems (i.e. Solaris, HP-UX, Redhat, etc.).
  my $cmd = $system{type} eq 'Windows' ? 'df -TP' : 'df -l -TP';
   
  my ($status, @output) = $clearexec->execute ($cmd);
  
  error "Unable to execute uname -a - $!", $status . join ("\n". @output)
    if $status;
  
  # Real file systems start with "/"
  @output = grep { /^\// } @output;
  
  my @filesystems;
    
  foreach (@output) {
  	if (/^(\S+)\s+(\S+).+?(\S+)$/) {
      my %filesystem;
      
      $filesystem{system}     = $system{name};
  	  $filesystem{filesystem} = $1;
  	  $filesystem{fstype}     = $2;
  	  $filesystem{mount}      = $3;

      push @filesystems, \%filesystem;    
  	} # if
  } # foreach
  
  return @filesystems;
} # GetFilesystems

sub GatherSysInfo (;%) {
  my (%system) = @_;

  # Set name if not currently set  
  $system{name} = $host
    unless $system{name};
    
  my ($status, @output);
  
  $system{port} ||= $port;

  # Connect to clearexec server
  $status = $clearexec->connectToServer ($system{name}, $system{port});

  unless ($status) {
    warning "Unable to connect to $system{name}:$port";
    return %system;
  } # if

  # Get OS info
  my $cmd = 'uname -a';

  ($status, @output) = $clearexec->execute ($cmd);
  
  error "Unable to execute '$cmd' - $!", $status . join ("\n". @output)
    if $status;
  
  $system{os} = $output[0];
  
  $system{clearagent} = 1;
  
  $cmd = 'uname -s';
  
  ($status, @output) = $clearexec->execute ($cmd);

  error "Unable to execute '$cmd' - $!", $status . join ("\n". @output)
    if $status;
  
  # TODO: Need to handle this better
  $system{type} = $output[0] =~ /cygwin/i ? 'Windows' : $output[0];
  
  return %system;  
} # GatherSysInfo

sub AddFilesystems (%) {
  my (%system) = @_;

  my ($err, $msg);
    
  foreach (GetFilesystems %system) {
    my %filesystem = %{$_};
    
    my %oldfilesystem = $clearadm->GetFilesystem (
      $filesystem{system},
      $filesystem{filesystem}
    );
    
    if (%oldfilesystem) {
      verbose "Updating filesystem $filesystem{system}:$filesystem{filesystem}";
      
      ($err, $msg) = $clearadm->UpdateFilesystem (
        $filesystem{system},
        $filesystem{filesystem},
        %filesystem,
      );
      
      error 'Unable to update filesystem '
          . "$filesystem{system}:$filesystem{filesystem}"
        if $err;
    } else {
      verbose 'Adding filesystem '
            . "$filesystem{system}:$filesystem{filesystem}";
    
      ($err, $msg) = $clearadm->AddFilesystem (%filesystem);

      error 'Unable to add filesystem '
          . "$filesystem{system}:$filesystem{filesystem}"
        if $err;
    } # if      
  } # foreach
  
  return ($err, $msg);  
} # AddFilesystems

sub AddSystem ($) {
  my ($system) = @_;
  
  verbose "Adding newhost $system";

  my %system = GatherSysInfo;
  
  # If GatherSysInfo was able to connect to clearagent it will set this field
  my $clearagent = delete $system{clearagent};
  
  my ($err, $msg) = $clearadm->AddSystem (%system);
  
  return ($err, $msg)
    if $err;
    
  if ($clearagent) {
    return AddFilesystems %system;
  } else {
    return ($err, $msg);
  } # if
} # AddSystem

sub UpdateSystem (%) {
  my (%system) = @_;
  
  my ($err, $msg);
  
  %system = GatherSysInfo (%system);
  
  # If GatherSysInfo was able to connect to clearagent it will set this field
  my $clearagent = delete $system{clearagent};
  
  return ($err, $msg) unless $clearagent;
  
  verbose "Updating existing host $system{name}";
  
  ($err, $msg) = $clearadm->UpdateSystem ($system{name}, %system);
    
  return ($err, $msg) if $err;

  ($err, $msg) = AddFilesystems %system;
  
  $clearexec->disconnectFromServer;
  
  return ($err, $msg);
} # UpdateSystem

# Main
$host = hostname;
$port = $Clearexec::CLEAROPTS{CLEAREXEC_PORT};

GetOptions (
  'usage'   => sub { Usage },
  'verbose' => sub { set_verbose },
  'debug'   => sub { set_debug },
  'delete'  => \$delete,
  'host=s'  => \$host,
  'port=s'  => \$port,
) or Usage "Invalid parameter";

Usage 'Extraneous options: ' . join ' ', @ARGV
  if @ARGV;

if ($delete) {
  error "Must specify -host if you specify -delete", 1
    unless $host;
} # if

# Announce ourselves
verbose "$FindBin::Script V$VERSION";

my ($err, $msg);

if ($delete) {
  display_nolf "Delete host $host (y/N):";
  
  my $answer = <STDIN>;
  
  if ($answer =~ /(y|yes)/i) {
    ($err, $msg) = $clearadm->DeleteSystem ($host);
  
    if ($err == 0) {
       error "No host named $host in database";
    } elsif ($err < 0) {
      error "Unable to delete $host" . $msg, $err;
    } else {
      verbose "Deleted host $host";
    } # if
  } else {
  	display "Host $host not deleted";
  } # if
} else {
  if ($host eq 'all') {
    foreach ($clearadm->FindSystem) {
      my %system = %$_;
      
      ($err, $msg) = UpdateSystem (%system);
  
      error "Unable to update host $system{name}\n$msg", $err
        if $err;
    } # foreach
  } else {
    my %system = $clearadm->GetSystem ($host);
    
    if (%system) {
      ($err, $msg) = UpdateSystem (%system);
    } else {
      ($err, $msg) = AddSystem ($host);
    } # if

    if ($err) {
      my $errmsg  = 'Unable to ';
         $errmsg .= %system ? 'update' : 'add';
         $errmsg .= " host $host\$msg"; 

      error "Unable to add host $host\n$msg", $err;
    } # if
  } # if
} # if

=pod

=head1 CONFIGURATION AND ENVIRONMENT

DEBUG: If set then $debug is set to this level.

VERBOSE: If set then $verbose is set to this level.

TRACE: If set then $trace is set to this level.

=head1 DEPENDENCIES

=head2 Perl Modules

L<FindBin>

L<Getop::Long|Getopt::Long>

L<Sys::Hostname|Sys::Hostname>

=head2 ClearSCM Perl Modules

=begin man 

 Clearadm
 Clearexec
 Display
 Utils

=end man

=begin html

<blockquote>
<a href="http://clearscm.com/php/cvs_man.php?file=clearadm/lib/Clearadm.pm">Clearadm</a><br>
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
