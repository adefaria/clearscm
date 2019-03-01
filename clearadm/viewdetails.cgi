#!/usr/local/bin/perl

=pod

=head1 NAME $RCSfile: viewdetails.cgi,v $

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

 Usage viewdetails.cgi: [-u|sage] [-r|egion <region>] -vi|ew <viewname>
                        [-ve|rbose] [-d|ebug]

 Where:
   -u|sage:           Displays usage
   -r|egion <region>: Region to use when looking for the view
   -vi|ew<viewname>:  Name of view to display details for

   -ve|rbose:         Be verbose
   -d|ebug:           Output debug messages

=head2 DESCRIPTION

This script display the details for the given view

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
use Clearcase::View;
use Clearcase::Views;
use Display;
use Utils;

my %opts = Vars;

my $subtitle = 'View Details';

$opts{region} ||= $Clearcase::CC->region;

my $VERSION  = '$Revision: 1.12 $';
  ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);

sub DisplayTable ($) {
  my ($view) = @_;

  my $permissions     = setField $view->owner_mode
                      . setField $view->group_mode
                      . setField $view->other_mode;
  my $active          = ($view->active) ? 'YES' : 'NO';
  my $gpath           = $view->gpath;

  $gpath = font {-class => 'unknown'}, '&lt;no-gpath&gt;'
    if $gpath eq '<no-gpath>';

  display start_table {
    -cellspacing    => 1,
    -class          => 'main',
  };

  my $clearadm = Clearadm->new;

  my %clearadmview = $clearadm->GetView($view->tag, $view->region);

  display start_Tr;
    display th {class => 'label'},              'Tag:';
    display td {class => 'data', colspan => 3}, setField $view->tag;
    display th {class => 'label'},              'Server:';
    display td {class => 'data'}, a {
      href => 'systemdetails.cgi?system=' . $view->shost
    }, $view->shost;
    display th {class => 'label'},               'Region:';
    display td {class => 'data'},                 $view->region;
  display end_Tr;

  display start_Tr;
    display th {class => 'label'},              'Properties:';
    display td {class => 'data', colspan => 3}, $view->properties;
    display th {class => 'label'},              'Text Mode:';
    display td {class => 'data'},               $view->text_mode;
    display th {class => 'label'},              'Permission:';
    display td {class => 'data'},               $permissions;
  display end_Tr;

  display start_Tr;
    display th {class => 'label'},              'Owner:';
    display td {class => 'data', colspan => 3}, $view->owner;
    display th {class => 'label'},              'Active:';
    display td {class => 'data', colspan => 3}, $active;
  display end_Tr;

  display start_Tr;
    display th {class => 'label'},              'Created by:';
    display td {class => 'data', colspan => 3}, $view->created_by;
    display th {class => 'label'},              'on:';
    display td {class => 'data', colspan => 3}, $view->created_date;
  display end_Tr;

  display start_Tr;
    display th {class => 'label'},              'CS Updated by:';
    display td {class => 'data', colspan => 3}, $view->cs_updated_by;
    display th {class => 'label'},              'on:';
    display td {class => 'data', colspan => 3}, $view->cs_updated_date;
  display end_Tr;

  display start_Tr;
    display th {class => 'label'},              'Global Path:';
    display td {class => 'data', colspan => 7}, $gpath;
  display end_Tr;

  display start_Tr;
    display th {class => 'label'},              'Access Path:';
    display td {class => 'data', colspan => 7}, $view->access_path;
  display end_Tr;

  display start_Tr;
    display th {class => 'label'},              'UUID:';
    display td {class => 'data', colspan => 7}, $view->uuid;
  display end_Tr;

  display start_Tr;
    display th {class => 'labelCentered', colspan => 10}, 'View Storage Pools';
  display end_Tr;

  my $image = $clearadmview{dbsmall}
    ? "data:image/png;base64,$clearadmview{dbsmall}"
    : "plotstorage.cgi?type=view&storage=db&tiny=1&tag=" . $view->tag;

  display start_Tr;
    display th {class => 'label'},                                'Database:';
    display td {class => 'data', colspan => 3, align => 'center'}, a {href =>
       "plot.cgi?type=view&storage=db&scaling=Day&points=7&region=" . $view->region . '&tag=' . $view->tag
    }, img {
      src    => $image,
      border => 0,
    };

    $image = $clearadmview{privatesmall}
      ? "data:image/png;base64,$clearadmview{privatesmall}"
      : "plotstorage.cgi?type=view&storage=private&tiny=1&tag=" . $view->tag;

    display th {class => 'label'},                                'Private:';
    display td {class => 'data', colspan => 5, align => 'center'}, a {href =>
       "plot.cgi?type=view&storage=private&scaling=Day&points=7&region=" . $view->region . '&tag=' . $view->tag
    }, img {
      src    => $image,
      border => 0,
    };
  display end_Tr;

  $image = $clearadmview{adminsmall}
    ? "data:image/png;base64,$clearadmview{adminsmall}"
    : "plotstorage.cgi?type=view&storage=admin&tiny=1&tag=" . $view->tag;

  display start_Tr;
    display th {class => 'label'},                                'Admin:';
    display td {class => 'data', colspan => 3, align => 'center'}, a {href =>
       "plot.cgi?type=view&storage=admin&scaling=Day&points=7&region=" . $view->region . '&tag=' . $view->tag
    }, img {
      src    => $image,
      border => 0,
    };

    $image = $clearadmview{totalsmall}
      ? "data:image/png;base64,$clearadmview{totalsmall}"
      : "plotstorage.cgi?type=view&storage=total&tiny=1&tag=" . $view->tag;

    display th {class => 'label'},                                'Total Space:';
    display td {class => 'data', colspan => 5, align => 'center'}, a {href =>
       "plot.cgi?type=view&storage=total&scaling=Day&points=7&region=" . $view->region . '&tag=' . $view->tag
    }, img {
      src    => $image,
      border => 0,
    };
  display end_Tr;

  display end_table;
  
  return
} # DisplayTable

sub DisplayRegion() {
  display start_form (action => 'viewdetails.cgi');

  display 'Region ';

  display popup_menu (
    -name     => 'region',
    -values   => [$Clearcase::CC->regions],
    -default  => $Clearcase::CC->region,
    -onchange => 'submit();',
  );

  display submit (
    -value => 'Go',
  );

  display end_form;
  
  return
} # DisplayRegion

sub DisplayViews($) {
  my ($region) = @_;

  my $views = Clearcase::Views->new ($region);
  my @views = $views->views;

  unless (@views) {
    push @views, 'No Views';
  } # unless

  display start_form(action => 'viewdetails.cgi');

  display 'Region ';

  display popup_menu (
    -name     => 'region',
    -values   => [$Clearcase::CC->regions],
    -default  => $region,
    -onchange => 'submit();',
  );

  display b ' View: ';

  display popup_menu (
     -name     => 'view',
     -values   => \@views,
     -onchange => 'submit();',
  );

  display submit(
    -value     => 'Go',
  );

  display end_form;
  
  return;
} # DisplayViews

# Main
GetOptions(
  \%opts,
  'usage'        => sub { Usage },
  'verbose'      => sub { set_verbose },
  'debug'        => sub { set_debug },
  'view=s',
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
    DisplayViews $opts{region};
  } # unless

  exit;
} # unless

DisplayTable(Clearcase::View->new($opts{tag}, $opts{region}));

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

 Clearadm
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
