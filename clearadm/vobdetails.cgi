#!/usr/local/bin/perl

=pod

=head1 NAME $RCSfile: vobdetails.cgi,v $

View Details

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.11 $

=item Created:

Mon Oct 25 11:10:47 PDT 2008

=item Modified:

$Date: 2011/01/14 16:51:58 $

=back

=head1 SYNOPSIS

 Usage vobdetails.cgi: [-u|sage] [-r|egion <region>] -vo|b <vobtag>
                       [-ve|rbose] [-d|ebug]

 Where:
   -u|sage:           Displays usage
   -r|egion <region>: Region to use when looking for the vob
   -vo|b <vobtag>:    Tag of vob to display details for

   -ve|rbose:         Be verbose
   -d|ebug:           Output debug messages

=head2 DESCRIPTION

This script display the details for the given vob

=cut

use strict;
use warnings;

use FindBin;
use Getopt::Long;
use CGI qw(:standard :cgi-lib *table start_Tr end_Tr);
use CGI::Carp 'fatalsToBrowser';

use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Clearadm;
use ClearadmWeb;
use Clearcase;
use Clearcase::Vob;
use Clearcase::Vobs;
use Display;
use Utils;

my %opts = Vars;

my $subtitle = 'VOB Details';

if ($Clearcase::CC->region) {
  $opts{region} ||= $Clearcase::CC->region;
} else {
  $opts{region} ||= 'Clearcase not installed';
} # if

my $VERSION  = '$Revision: 1.11 $';
  ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);

sub DisplayTable($) {
  my ($vob) = @_;

  my $active = ($vob->active) ? 'YES' : 'NO';
  my $gpath  = $vob->gpath;

  $gpath = font {-class => 'unknown'}, '&lt;no-gpath&gt;'
    if $gpath eq '<no-gpath>';

  display start_table {
    -cellspacing    => 1,
    -class          => 'main',
  };

  my $clearadm = Clearadm->new;

  my %clearadmvob = $clearadm->GetVob($vob->tag, $vob->region);

  display start_Tr;
    display th {class => 'label'},              'Tag:';
    display td {class => 'data', colspan => 3}, setField $vob->tag;
    display th {class => 'label'},              'Server:';
    display td {class => 'data'}, a {
      href => 'systemdetails.cgi?system=' . $vob->shost
    }, $vob->shost;
    display th {class => 'label'},               'Region:';
    display td {class => 'data', colspan => 3},  $vob->region;
  display end_Tr;

  display start_Tr;
    display th {class => 'label'},              'Type:';
    display td {class => 'data', colspan => 3}, $vob->access;
    display th {class => 'label'},              'Attributes:';
    display td {class => 'data'},               $vob->vob_registry_attributes;
    display th {class => 'label'},              'Mount Opts:';
    display td {class => 'data', colspan => 3}, $vob->mopts;
  display end_Tr;

  display start_Tr;
    display th {class => 'label'},              'Owner:';
    display td {class => 'data', colspan => 3}, $vob->owner;
    display th {class => 'label'},              'Active:';
    display td {class => 'data'},               $active;
    display th {class => 'label'},              'ACLs Enabled:';
    display td {class => 'data', colspan => 3}, $vob->aclsEnabled;
  display end_Tr;

  display start_Tr;
    display th {class => 'label'},              'Created by:';
    display td {class => 'data', colspan => 3}, $vob->ownername;
    display th {class => 'label'},              'on:';
    display td {class => 'data'},               $vob->created;
    display th {class => 'label'},              'Atomic Checkin:';
    display td {class => 'data', colspan => 3}, $vob->atomicCheckin;
  display end_Tr;

  display start_Tr;
    display th {class => 'label'},              'Comment:';
    display td {class => 'data', colspan => 5}, $vob->comment;
    display th {class => 'label'},              'Schema Version:';
    display td {class => 'data', colspan => 3}, $vob->schemaVersion;
  display end_Tr;
  
  display start_Tr;
    display th {class => 'label'},              'Global Path:';
    display td {class => 'data', colspan => 5}, $gpath;
    display th {class => 'label'},              'Registry Attributes:';
    display td {class => 'data', colspan => 3}, $vob->vob_registry_attributes;
  display end_Tr;

  display start_Tr;
    display th {class => 'label'},              'Access Path:';
    display td {class => 'data', colspan => 5}, $vob->access_path;
    display th {class => 'label'},              'Group:';
    display td {class => 'data', colspan => 3}, $vob->group;
  display end_Tr;

  display start_Tr;
    display th {class => 'label'},              'Family UUID:';
    display td {class => 'data', colspan => 5}, $vob->family_uuid;
    display th {class => 'label'},              'Remote Privilage:';
    display td {class => 'data', colspan => 3}, $vob->remotePrivilege;
  display end_Tr;

  display start_Tr;
    display th {class => 'label'},              'Replica UUID:';
    display td {class => 'data', colspan => 5}, $vob->replica_uuid;
    display th {class => 'label'},              'Master Replica:';
    display td {class => 'data', colspan => 3}, $vob->masterReplica;
  display end_Tr;

  my $groups = join "<br>", $vob->groups;

  display start_Tr;
    display th {class => 'label'},               'Groups:';
    display td {class => 'data', colspan => 10}, $groups;
  display end_Tr;

  my %attributes = $vob->attributes;
  my $attributes = '';

  for (keys %attributes) {
    $attributes .= "$_ = $attributes{$_}<br>";
  } # for
  
  display start_Tr;
    display th {class => 'label'},               'Attributes:';
    display td {class => 'data', colspan => 10}, $attributes;
  display end_Tr;

  my %hyperlinks = $vob->hyperlinks;
  my $hyperlinks = '';

  for (keys %hyperlinks) {
    $hyperlinks .= "$_ = $hyperlinks{$_}<br>";
  } # for
  
  display start_Tr;
    display th {class => 'label'},               'Hyperlinks:';
    display td {class => 'data', colspan => 10}, $hyperlinks;
  display end_Tr;

  display start_Tr;
    display th {class => 'labelCentered', colspan => 10}, 'VOB Storage Pools';
  display end_Tr;

  my $image = $clearadmvob{adminsmall}
    ? "data:image/png;base64,$clearadmvob{adminsmall}"
    : "plotstorage.cgi?type=vob&storage=admin&tiny=1&tag=" . $vob->tag;

  display start_Tr;
    display th {class => 'label'},                                'Admin:';
    display td {class => 'data', colspan => 4, align => 'center'}, a {href =>
      'plot.cgi?type=vob&storage=admin&scaling=Day&points=7&region=' . $vob->region . '&tag=' . $vob->tag
    }, img {
      src    => $image,
      border => 0,
    };

    $image = $clearadmvob{sourcesmall}
      ? "data:image/png;base64,$clearadmvob{sourcesmall}"
      : 'plotstorage.cgi?type=vob&storage=source&tiny=1&region=' . $vob->region . '&tag=' . $vob->tag;

    display th {class => 'label'},                                'Source Size:';
    display td {class => 'data', colspan => 4, align => 'center'}, a {href =>
      'plot.cgi?type=vob&storage=source&scaling=Day&points=7&region=' . $vob->region . '&tag=' . $vob->tag
    }, img {
      src    => $image,
      border => 0,
    };
  display end_Tr;

  display start_Tr;
    $image = $clearadmvob{dbsmall}
      ? "data:image/png;base64,$clearadmvob{dbsmall}"
      : 'plotstorage.cgi?type=vob&storage=db&tiny=1&region=' . $vob->region . '&tag=' . $vob->tag;

    display th {class => 'label'},                                'Database:';
    display td {class => 'data', colspan => 4, align => 'center'}, a {href =>
      'plot.cgi?type=vob&storage=db&scaling=Day&points=7&region=' . $vob->region . '&tag=' . $vob->tag
    }, img {
      src    => $image,
      border => 0,
    };

    $image = $clearadmvob{derivedobjsmall}
      ? "data:image/png;base64,$clearadmvob{derivedobjsmall}"
      : 'plotstorage.cgi?type=vob&storage=derivedobj&tiny=1&region=' . $vob->region . '&tag=' . $vob->tag;

    display th {class => 'label'},                                'Derived Obj:';
    display td {class => 'data', colspan => 4, align => 'center'}, a {href =>
      'plot.cgi?type=vob&storage=derivedobj&scaling=Day&points=7&region=' . $vob->region . '&tag=' . $vob->tag
    }, img {
      src    => $image,
      border => 0,
    };
  display end_Tr;

  display start_Tr;
    $image = $clearadmvob{cleartextsmall}
      ? "data:image/png;base64,$clearadmvob{cleartextsmall}"
      : 'plotstorage.cgi?type=vob&storage=cleartext&tiny=1&region=' . $vob->retion . '&tag=' . $vob->tag;

    display th {class => 'label'},                                'Cleartext:';
    display td {class => 'data', colspan => 4, align => 'center'}, a {href =>
      'plot.cgi?type=vob&storage=cleartext&scaling=Day&points=7&region=' . $vob->region . '&tag=' . $vob->tag
    }, img {
      src    => $image,
      border => 0,
    };

    $image = $clearadmvob{totalsmall}
      ? "data:image/png;base64,$clearadmvob{totalsmall}"
      : 'plotstorage.cgi?type=vob&storage=total&tiny=1&region=' . $vob->region . '&tag=' . $vob->tag;

    display th {class => 'label'},                                'Total Size:';
    display td {class => 'data', colspan => 4, align => 'center'}, a {href =>
      'plot.cgi?type=vob&storage=total&scaling=Day&points=7&region=' . $vob->region . '&tag=' . $vob->tag
    }, img {
      src    => $image,
      border => 0,
    };
  display end_Tr;

  display end_table;

  return;
} # DisplayTable

sub DisplayRegion() {
  display start_form (action => 'vobdetails.cgi');

  display 'Region ';

  my ($defaultRegion, @regions) = ('', ('Clearcase not installed'));

  display popup_menu(
    -name     => 'region',
    -values   => [@regions],
    -default  => $defaultRegion,
    -onchange => 'submit();',
  );

  display submit(
    -value => 'Go',
  );

  display end_form;
  
  return
} # DisplayRegion

sub DisplayVobs($) {
  my ($region) = @_;

  my @vobs = Clearcase::Vobs->new ($region);

  unless (@vobs) {
    push @vobs, 'No VOBs';
  } # unless

  display start_form(action => 'vobdetails.cgi');

  display 'Region ';

  display popup_menu(
    -name     => 'region',
    -values   => [$Clearcase::CC->regions],
    -default  => $region,
    -onchange => 'submit();',
  );

  display b ' VOB: ';

  display popup_menu(
     -name     => 'vob',
     -values   => \@vobs,
     -onchange => 'submit();',
  );

  display submit(
    -value     => 'Go',
  );

  display end_form;
  
  return;
} # DisplayVobs

# Main
GetOptions(
  \%opts,
  'usage'        => sub { Usage },
  'verbose'      => sub { set_verbose },
  'debug'        => sub { set_debug },
  'vob=s',
  'region=s',
) or Usage "Invalid parameter";

# Announce ourselves
verbose "$FindBin::Script v$VERSION";

heading $subtitle;

display h1 {
  -class => 'center',
}, $subtitle;

unless ($opts{tag}) {
  unless ($opts{region}) {
    DisplayRegion;
  } else {
    DisplayVobs $opts{region};
  } # unless

  exit;
} # unless

my $vob = Clearcase::Vob->new($opts{tag}, $opts{region});

DisplayTable $vob;

footing;

=pod

=head1 CONFIGURATION AND ENVIRONMENT

DEBUG: If set then $debug is set to this level.

VERBOSE: If set then $verbose is set to this level.

TRACE: If set then $trace is set to this level.

=head1 DEPENDENCIES

=head2 Perl Modules

L<CGI>

L<CGI::Carp|CGI::Carp>

L<FindBin>

L<Getopt::Long|Getopt::Long>

=head2 ClearSCM Perl Modules

=begin man 

 ClearadmWeb
 Clearcase
 Clearcase::View
 Clearcase::Views
 Display
 Utils

=end man

=begin html

<blockquote>
<a href="http://clearscm.com/php/scm_man.php?file=clearadm/lib/Clearadm.pm">Clearadm</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=clearadm/lib/ClearadmWeb.pm">ClearadmWeb</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Clearcase.pm">Clearcase</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Clearcase/View.pm">Clearcase::View</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Clearcase/Views.pm">Clearcase::Views</a><br>
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
