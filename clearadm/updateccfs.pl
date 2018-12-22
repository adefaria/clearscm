#!/usr/local/bin/perl

=pod

=head1 NAME $RCSfile: updateccstorage.pl,v $

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

 Usage updateccstorage.pl: [-u|sage] [-ve|rbose] [-deb|ug]
                           [-view [<tag>|all]| -vob [<tag>|all]]

 Where:
   -u|sage:     Displays usage
 
   -ve|rbose:   Be verbose
   -deb|ug:     Output debug messages
   
   -view [<tag>|all]      Update view storage (Default: all)
   -vob	 [<tag>|all]      Update vob storage (Default: all)
   -region [<region>|all] Update region (Default: all)

=head1 DESCRIPTION

This script will record the state of Clearcase storage

=cut

use strict;
use warnings;

use FindBin;
use Getopt::Long;

use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Clearadm;
use Clearexec;
use Clearcase::Views;
use Clearcase::View;
use Clearcase::Vobs;
use Clearcase::Vob;
use DateUtils;
use Display;
use Utils;

my $VERSION  = '$Revision: 1.29 $';
  ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);

my $clearadm = Clearadm->new;

# Given a view tag, snapshot the storage sizes
sub snapshotViewStorage($$) {
  my ($tag, $region) = @_;

  my %viewstorage = (
    tag    => $tag,
    region => $region,
  );

  my $view = Clearcase::View->new($tag, $region);
  
  $viewstorage{private} = $view->viewPrivateStorage;
  $viewstorage{db}      = $view->viewDatabase;
  $viewstorage{admin}   = $view->viewAdmin;
  $viewstorage{total}   = $view->viewSpace;

  my ($err, $msg) = $clearadm->AddViewStorage(%viewstorage);

  error $msg, $err if $err;
} # snapshotVobStorage

# Given a vob tag, snapshot the storage sizes
sub snapshotVobStorage($$) {
  my ($tag, $region) = @_;

  my %vobstorage = (
    tag    => $tag,
    region => $region,
  );

  my $vob = Clearcase::Vob->new($tag, $region);

  $vobstorage{admin}	  = $vob->admsize;
  $vobstorage{db}	  = $vob->dbsize;
  $vobstorage{cleartext}  = $vob->ctsize;
  $vobstorage{derivedobj} = $vob->dosize;
  $vobstorage{source} 	  = $vob->srcsize;
  $vobstorage{total}	  = $vob->size;

  my ($err, $msg) = $clearadm->AddVobStorage(%vobstorage);

  error $msg, $err, if $err;
} # snapshotVobStorage

my %opts;

# Main
GetOptions (
  \%opts,
  'usage'   => sub { Usage },
  'verbose' => sub { set_verbose },
  'debug'   => sub { set_debug },
  'view=s',
  'vob=s',
  'region=s',
) or Usage "Invalid parameter";

Usage 'Extraneous options: ' . join ' ', @ARGV if @ARGV;

unless ($opts{view} or $opts{vob}) {
  $opts{view} = 'all';
  $opts{vob}  = 'all';
} # unless

$opts{region} ||= 'all';

# Announce ourselves
verbose "$FindBin::Script V$VERSION";

if ($opts{view} and $opts{view} =~ /all/i) {
  if ($opts{region} =~ /all/i) {
    for my $region ($Clearcase::CC->regions) {
      my $views = Clearcase::Views->new($region);

      for my $view ($views->views) {
        verbose "Snapshotting view $view in region $region";

        snapshotViewStorage $view, $region;
      } # for
    } # for
  } else {
    my $views = Clearcase::Views->new($opts{region});

    for my $view ($views->views) {
      verbose "Snapshotting view $view in region $opts{region}";

      snapshotViewStorage $view, $opts{region};
    } # for
  } # if
} elsif ($opts{view}) {
  if ($opts{region} =~ /all/i) {
    for my $region ($Clearcase::CC->regions) {
      verbose "Snapshotting view $opts{view} in region $region";

      snapshotViewStorage $opts{view}, $region;
    } # for
  } else {
    verbose "Snapshotting view $opts{view} in region $opts{region}";

    snapshotViewStorage $opts{view}, $opts{region};
  } # if
} # if

if ($opts{vob} and $opts{vob} =~ /all/i) {
  if ($opts{region} =~ /all/i) {
    for my $region ($Clearcase::CC->regions) {
      my $vobs = Clearcase::Vobs->new(undef, $region);

      for my $vob ($vobs->vobs) {
        verbose "Snapshotting vob $vob in region $region";

        snapshotVobStorage $vob, $region;
      } # for
    } # for
  } else {
    my $vobs = Clearcase::Vobs->new(undef, $opts{region});

    for my $vob ($vobs->vobs) {
      verbose "Snapshotting vob $vob in region $opts{region}";
      
      snapshotVobStorage $vob, $opts{region};
    } # for
  } # if
} elsif ($opts{vob}) {
  if ($opts{region} =~ /all/i) {
    for my $region ($Clearcase::CC->regions) {
      verbose "Snapshotting view $opts{vob} in region $region";

      snapshotVobStorage $opts{vob}, $region;
    } # for
  } else {
    verbose "Snapshotting vob $opts{vob} in region $opts{region}";

    snapshotVobStorage $opts{vob}, $opts{region};
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
<a href="http://clearscm.com/php/scm_man.php?file=clearadm/lib/Clearcase/Vobs.pm">Clearcase::Vobs</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=clearadm/lib/Clearcase/Vobs.pm">Clearcase::Vob</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=clearadm/lib/Clearcase/Views.pm">Clearcase::Views</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=clearadm/lib/Clearcase/View.pm">Clearcase::View</a><br>
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
