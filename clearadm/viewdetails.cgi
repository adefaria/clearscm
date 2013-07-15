#!/usr/bin/perl

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
use CGI qw (:standard :cgi-lib *table start_Tr end_Tr);
use CGI::Carp 'fatalsToBrowser';

use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use ClearadmWeb;
use Clearcase;
use Clearcase::View;
use Clearcase::Views;
use Display;
use Utils;

my %opts = Vars;

my $subtitle = 'View Details';

if ($Clearcase::CC->region) {
  $opts{region} ||= $Clearcase::CC->region;
} else {
  $opts{region} ||= 'Clearcase not installed';
} # if

my $VERSION  = '$Revision: 1.11 $';
  ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);

sub DisplayTable ($) {
  my ($view) = @_;

  # Data fields
  my $tag             = setField $view->tag;
  my $server          = setField $view->shost;
  my $region          = setField $view->region;
  my $properties      = setField $view->properties;
  my $text_mode       = setField $view->text_mode;
  my $permissions     = setField $view->owner_mode
                      . setField $view->group_mode
                      . setField $view->other_mode;
  my $owner           = setField $view->owner;
  my $active          = ($view->active) ? 'YES' : 'NO';
  my $created_by      = setField $view->created_by;
  my $created_date    = setField $view->created_date;
  my $cs_updated_by   = setField $view->cs_updated_by;
  my $cs_updated_date = setField $view->cs_updated_date;
  my $gpath           = setField $view->gpath;
  my $access_path     = setField $view->access_path;
  my $uuid            = setField $view->uuid;

  $gpath = font {-class => 'unknown'}, '&lt;no-gpath&gt;'
    if $gpath eq '<no-gpath>';

  display start_table {
    -cellspacing    => 1,
    -class          => 'main',
  };

  display start_Tr;
    display th {class => 'label'},              'Tag:';
    display td {class => 'data', colspan => 3}, $tag;
    display th {class => 'label'},              'Server:';
    display td {class => 'data'}, a {
      href => "serverdetails.cgi?server=$server"
    }, $server;
    display th {class => 'label'},               'Region:';
    display td {class => 'data'},                 $region;
  display end_Tr;

  display start_Tr;
    display th {class => 'label'},              'Properties:';
    display td {class => 'data', colspan => 3}, $properties;
    display th {class => 'label'},              'Text Mode:';
    display td {class => 'data'},               $text_mode;
    display th {class => 'label'},              'Permission:';
    display td {class => 'data'},               $permissions;
  display end_Tr;

  display start_Tr;
    display th {class => 'label'},              'Owner:';
    display td {class => 'data', colspan => 3}, $owner;
    display th {class => 'label'},              'Active:';
    display td {class => 'data', colspan => 3}, $active;
  display end_Tr;

  display start_Tr;
    display th {class => 'label'},              'Created by:';
    display td {class => 'data', colspan => 3}, $created_by;
    display th {class => 'label'},              'on:';
    display td {class => 'data', colspan => 3}, $created_date;
  display end_Tr;

  display start_Tr;
    display th {class => 'label'},              'CS Updated by:';
    display td {class => 'data', colspan => 3}, $cs_updated_by;
    display th {class => 'label'},              'on:';
    display td {class => 'data', colspan => 3}, $cs_updated_date;
  display end_Tr;

  display start_Tr;
    display th {class => 'label'},              'Global Path:';
    display td {class => 'data', colspan => 7}, $gpath;
  display end_Tr;

  display start_Tr;
    display th {class => 'label'},              'Access Path:';
    display td {class => 'data', colspan => 7}, $access_path;
  display end_Tr;

  display start_Tr;
    display th {class => 'label'},              'UUID:';
    display td {class => 'data', colspan => 7}, $uuid;
  display end_Tr;

  display end_table;
  
  return
} # DisplayTable

sub DisplayRegion {
  display start_form (action => 'viewdetails.cgi');

  display 'Region ';

  my ($defaultRegion, @regions) = ('', ('Clearcase not installed'));

  display popup_menu (
    -name     => 'region',
    -values   => [@regions],
    -default  => $defaultRegion,
    -onchange => 'submit();',
  );

  display submit (
    -value => 'Go',
  );

  display end_form;
  
  return
} # DisplayRegion

sub DisplayViews ($) {
  my ($region) = @_;

  my $views = Clearcase::Views->new ($region);
  my @views = $views->views;

  unless (@views) {
    push @views, 'No Views';
  } # unless

  display start_form (action => 'viewdetails.cgi');

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

  display submit (
    -value     => 'Go',
  );

  display end_form;
  
  return;
} # DisplayViews

# Main
GetOptions (
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

my $view = Clearcase::View->new ($opts{tag}, $opts{region});

DisplayTable $view;

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
<a href="http://clearscm.com/php/cvs_man.php?file=clearadm/lib/ClearadmWeb.pm">ClearadmWeb</a><br>
<a href="http://clearscm.com/php/cvs_man.php?file=lib/Clearcase.pm">Clearcase</a><br>
<a href="http://clearscm.com/php/cvs_man.php?file=lib/Clearcase/View.pm">Clearcase::View</a><br>
<a href="http://clearscm.com/php/cvs_man.php?file=lib/Clearcase/Views.pm">Clearcase::Views</a><br>
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