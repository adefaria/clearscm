#!/usr/bin/perl

=pod

=head1 NAME $RCSfile: updatefs.pl,v $

Update Filesystem

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.29 $

=item Created:

Mon Dec 13 09:13:27 EST 2010

=item Modified:

$Date: 2011/06/16 15:12:50 $

=back

=head1 SYNOPSIS

 Usage updatefs.pl: [-u|sage] [-ve|rbose] [-deb|ug]
                    [-host [<host>|all]] [-fs [<fs>|all]]

 Where:
   -u|sage:     Displays usage
 
   -ve|rbose:   Be verbose
   -deb|ug:     Output debug messages
   
   -host [<host>|all]: Update host or all hosts (Default: all)
   -fs   [<fs>|all]:   Update filesystem or all (Default: all)   

=head1 DESCRIPTION

This script will record the state of a filesystem.

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

my ($host, $fs);

# Given a host and a filesystem, formulate a fs record
sub snapshotFS ($$) {
  my ($systemRef, $filesystem) = @_;

  my %system = %{$systemRef};

  my %filesystem = $clearadm->GetFilesystem ($system{name}, $filesystem);
  
  unless (%filesystem) {
  	error "Filesystem $host:$filesystem not in clearadm database - try adding it";
  	
  	return;
  } # unless
  
  my %fs = (
    system     => $system{name},
    filesystem => $filesystem,
    timestamp  => Today2SQLDatetime,
  );

  # Sun is so braindead!
  # TODO: Verify this works under Solaris
  if ($system{type} eq 'Unix') {
    foreach ('ufs', 'vxfs') {
      my $cmd = "/usr/bin/df -k -F $filesystem{mount}";

      my ($status, @unixfs) = $clearexec->execute ($cmd);

      if ($status != 0) {
        error ('Unable to determine fsinfo for '
             . "$system{name}:$filesystem{mount} ($cmd)\n" .
               join "\n", @unixfs
        );
    
        return;
      } # if

      # Skip heading
      shift @unixfs;

      for (my $i = 0; $i < scalar @unixfs; $i++) {
        my $firstField;
    
        # Trim leading and trailing spaces
        $unixfs[$i] =~ s/^\s+//;
        $unixfs[$i] =~ s/\s+$//;

        my @fields = split /\s+/, $unixfs[$i];

        if (@fields == 1) {
          $firstField   = 0;
          $i++;

          @fields   = split /\s+/, $unixfs[$i];;
        } else {
          $firstField   = 1;
        } #if

        $fs{size}    = $fields[$firstField]     * 1024;
        $fs{used}    = $fields[$firstField + 1] * 1024;
        $fs{free}    = $fields[$firstField + 2] * 1024;
        $fs{reserve} = $fs{size} - $fs{used} - $fs{free};
      } # for
    } # foreach
  } elsif ($system{type} eq 'Linux' or $system{type} eq 'Windows') {
    my $cmd = "/bin/df --block-size=1 -P $filesystem{mount}";

    my ($status, @linuxfs) = $clearexec->execute ($cmd);

    if ($status != 0) {
      error ("Unable to determine fsinfo for $system{name}:$filesystem{mount}\n"
          . join "\n", @linuxfs
      );
               
      return;
    } # if

    # Skip heading
    shift @linuxfs;
    
    $_ = shift @linuxfs;
    my @fields = split;
    
    $fs{size}    = $fields[1];
    $fs{used}    = $fields[2];
    $fs{free}    = $fields[3];
    $fs{mount}   = $fields[5];
    $fs{reserve} = $fs{size} - $fs{used} - $fs{free};
  } # if

  return %fs;  
} # snapshotFS

# Main
GetOptions (
  'usage'   => sub { Usage },
  'verbose' => sub { set_verbose },
  'debug'   => sub { set_debug },
  'host=s'  => \$host,
  'fs=s'    => \$fs,
) or Usage "Invalid parameter";

Usage 'Extraneous options: ' . join ' ', @ARGV
  if @ARGV;

# Announce ourselves
verbose "$FindBin::Script V$VERSION";

my $exit = 0;

foreach my $system ($clearadm->FindSystem ($host)) {
  next if $$system{active} eq 'false';
  
  my $status = $clearexec->connectToServer (
    $$system{name}, 
    $$system{port}
  );
  
  unless ($status) {
    verbose "Unable to connect to system $$system{name}:$$system{port}";
    next;
  } # unless

  foreach my $filesystem ($clearadm->FindFilesystem ($$system{name}, $fs)) {
    verbose "Snapshotting $$system{name}:$$filesystem{filesystem}";
  
    my %fs = snapshotFS ($system, $$filesystem{filesystem});
    
    if (%fs) {
      my ($err, $msg) = $clearadm->AddFS (%fs);
  
      error $msg, $err if $err;
    } # if
    
    # Check if over threshold
    my %notification = $clearadm->GetNotification ('Filesystem');

    next
      unless %notification;
  
    my $usedPct = sprintf (
      '%.2f',
      (($fs{used} + $fs{reserve}) / $fs{size}) * 100
    );
    
    if ($usedPct >= $$filesystem{threshold}) {
      $exit = 2;
      display YMDHMS . " System: $$filesystem{system} "
            . "Filesystem: $$filesystem{filesystem} Used: $usedPct% " 
            . "Threshold: $$filesystem{threshold}";    
    } else {
      $clearadm->ClearNotifications ($$system{name}, $$filesystem{filesystem});    
    } # if
  } # foreach
  
  $clearexec->disconnectFromServer;
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
