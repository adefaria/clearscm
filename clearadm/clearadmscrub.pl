#!/usr/local/bin/perl

=pod

=head1 NAME $RCSfile: clearadmscrub.pl,v $

Scrub Clearadm records

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.9 $

=item Created:

Sun Jan  2 19:40:28 EST 2011

=item Modified:

$Date: 2012/11/09 06:45:36 $

=back

=head1 SYNOPSIS

 Usage clearadmscrub.pl: [-u|sage] [-ve|rbose] [-deb|ug]

 Where:
   -u|sage:     Displays usage
 
   -ve|rbose:   Be verbose
   -deb|ug:     Output debug messages
   
=head1 DESCRIPTION

This script will scrub all old records in the Clearadm database

=cut

use strict;
use warnings;

use FindBin;
use Getopt::Long;
use Sys::Hostname;

use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Clearadm;
use DateUtils;
use Display;
use TimeUtils;
use Utils;

my $VERSION  = '$Revision: 1.9 $';
  ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);

my $clearadm  = Clearadm->new;

my ($host, $fs);

my %opts = (
  scrubdays => $Clearadm::CLEAROPTS{CLEARADM_SCRUBDAYS}
);

# Main
GetOptions(
  \%opts,
  'usage'    => sub { Usage },
  'verbose'  => sub { set_verbose },
  'debug'    => sub { set_debug },
  "scrubdays=i",
) or Usage "Invalid parameter";

Usage 'Extraneous options: ' . join ' ', @ARGV if @ARGV;

# Announce ourselves
verbose "$FindBin::Script V$VERSION";

my ($err, $msg);

for my $system ($clearadm->FindSystem($host)) {
  ($err, $msg) = $clearadm->TrimLoadavg($system->{name});
  
  if ($msg eq 'Records deleted' or $msg eq '') {
    verbose "Scrub loadavg $system->{name}: $err $msg:";
  } else {
    error "#$err: $msg";
  } # if
  
  for my $filesystem ($clearadm->FindFilesystem($system->{name}, $fs)) {
    ($err, $msg) = $clearadm->TrimFS($system->{name}, $filesystem->{filesystem});
    
    if ($msg eq 'Records deleted' or $msg eq '') {
      verbose "Scrub filesystem $system->{name}:$filesystem->{filesystem}: $err $msg";
    } else {
      error "#$err: $msg";
    } # if
  } # for
} # for

my $scrubdate = SubtractDays(Today2SQLDatetime, $opts{scrubdays});

my %runlog = (
  task    => 'Scrub',
  started => Today2SQLDatetime,
  system  => hostname(),
);

# Scrub view and vob storage records
for ($clearadm->FindVob) {
  ($err, $msg) = $clearadm->TrimStorage('vob', $_->{tag}, $_->{region});

  if ($msg eq 'Records deleted' or $msg eq '') {
    verbose "Scub VOB $_->{tag} $err $msg";
  } else {
    error "#$err: $msg";
  } # if
} # for

for ($clearadm->FindView) {
  ($err, $msg) = $clearadm->TrimStorage('view', $_->{tag}, $_->{region});

  if ($msg eq 'Records deleted' or $msg eq '') {
    verbose "Scub View $_->{tag} $err $msg";
  } else {
    error "#$err: $msg";
  } # if
} # for

# Make sure the Clearcase objects we have in Clearadm are still valid
my ($views, $vobs) = $clearadm->ValidateCCObjects;

if ($vobs !~ /^\d+/) {
  error "Unable to validate Clearcase objects: $vobs", $views;
} else {
  $runlog{status} = 0;

  $runlog{message}  = "Deleted $views views\n" if $views;
  $runlog{message} .= "Deleted $vobs vobs"     if $vobs;

  $clearadm->AddRunlog(%runlog);
} # if

# Scrub old alertlogs
($runlog{status}, $runlog{message}) = 
  $clearadm->DeleteAlertlog ("timestamp<='$scrubdate'");

verbose "$runlog{task} alertlog: $runlog{status} $runlog{message}";

$clearadm->AddRunlog (%runlog);

$runlog{started} = Today2SQLDatetime;

# Scrub old runlogs
($runlog{status}, $runlog{message}) = 
  $clearadm->DeleteRunlog ("started<='$scrubdate'");
  
verbose "$runlog{task} runlog: $runlog{status} $runlog{message}";

$clearadm->AddRunlog(%runlog);

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

 Clearadm
 DateUtils
 Display
 TimeUtils
 Utils

=end man

=begin html

<blockquote>
<a href="http://clearscm.com/php/scm_man.php?file=clearadm/lib/Clearadm.pm">Clearadm</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/DateUtils.pm">DateUtils</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Display.pm">Display</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/TimeUtils.pm">TimeUtils</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Utils.pm">Utils</a><br>
</blockquote>

=end html

=head1 BUGS AND LIMITATIONS

There are no known bugs in this script

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, ClearSCM, Inc. All rights reserved.

=cut
