#!/usr/local/bin/perl

=pod

=head1 NAME $RCSfile: systemdetails.cgi,v $

System Details

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.22 $

=item Created:

Mon Oct 25 11:10:47 PDT 2008

=item Modified:

$Date: 2011/01/28 21:31:25 $

=back

=head1 SYNOPSIS

 Usage systemdetails.cgi: [-u|sage] [-ve|rbose] [-d|ebug]
                          -s|ystem <systemname>
                          

 Where:
   -u|sage:               Displays usage
   -ve|rbose:             Be verbose
   -d|ebug:               Output debug messages
   
   -s|ystem <systemname>: Name of system to display details for

=head2 DESCRIPTION

This script displays the details for the given system

=cut

use strict;
use warnings;

use FindBin;
use Getopt::Long;
use CGI qw (:standard :cgi-lib *table start_Tr end_Tr);
use CGI::Carp 'fatalsToBrowser';

use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Clearadm;
use ClearadmWeb;
use Clearcase::Server;
use Display;
use Utils;

my $VERSION  = '$Revision: 1.22 $';
  ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);
  
my $name = param ('system');

my $subtitle = 'System Details';

my $clearadm;

sub DisplayTable ($) {
  my ($server) = @_;

  my $unknown = font {-class => 'unknown'}, 'Unknown';

  # Data fields
  my $systemName                = setField ($server->name);
  my $ccVer                     = setField ($server->ccVer);
  my $osVer                     = setField ($server->osVer);
  my $hardware                  = setField ($server->hardware);
  my $licenseHost               = setField ($server->licenseHost);
  my $registryHost              = setField ($server->registryHost);
  my $registryRegion            = setField ($server->registryRegion);
  my $mvfsBlocksPerDirectory    = setField ($server->mvfsBlocksPerDirectory);
  my $mvfsCleartextMnodes       = setField ($server->mvfsCleartextMnodes);
  my $mvfsDirectoryNames        = setField ($server->mvfsDirectoryNames);
  my $mvfsFileNames             = setField ($server->mvfsFileNames);
  my $mvfsFreeMnodes            = setField ($server->mvfsFreeMnodes);
  my $mvfsInitialMnodeTableSize = setField ($server->mvfsInitialMnodeTableSize);
  my $mvfsMinCleartextMnodes    = setField ($server->mvgsMinCleartextMnodes);
  my $mvfsMinFreeMnodes         = setField ($server->mvfsMinFreeMnodes);
  my $mvfsNamesNotFound         = setField ($server->mvfsNamesNotFound);
  my $mvfsRPCHandles            = setField ($server->mvfsRPCHandles);
  my $interopRegion             = setField ($server->interopRegion);
  my $scalingFactor             = setField ($server->scalingFactor);
  my $cleartextIdleLifetime     = setField ($server->cleartextIdleLifetime);
  my $vobHashTableSize          = setField ($server->vobHashTableSize);
  my $cleartextHashTableSize    = setField ($server->cleartextHashTableSize);
  my $dncHashTableSize          = setField ($server->dncHashTableSize);
  my $threadHashTableSize       = setField ($server->threadHashTableSize);
  my $processHashTableSize      = setField ($server->processHashTableSize);

  display h2 {class => 'center'}, 'Clearcase Information';
    
  display start_table {cellspacing => 1, class => 'main'};
    
  display start_Tr;
    display th {class => 'label'},              'Name:';
    display td {class => 'data', colspan => 4}, $systemName;
    display th {class => 'label'},              'Registry Host:';
    display td {class => 'data', colspan => 4},
      a {href => "systemdetails.cgi?server=$registryHost"}, $registryHost;
  display end_Tr;

  display start_Tr;
    display th {class => 'label'},               'Registry Region:';
    display td {class => 'data', -colspan => 4}, $registryRegion;
    display th {class => 'label'},               'License Host:';
    display td {class => 'data', colspan => 4},
      a {-href => "systemdetails.cgi?server=$licenseHost"}, $licenseHost;
  display end_Tr;

  display start_Tr;
    display th {class => 'label'},              'Clearcase Version:';
    display td {class => 'data', colspan => 4}, $ccVer;
    display th {class => 'label'},              'OS Version:';
    display td {class => 'data', colspan => 4}, $osVer;
  display end_Tr;

  display start_Tr;
    display th {class => 'label'},                    'Interop Region:';
    display td {class => 'dataRight'},                $interopRegion;
    display th {class => 'label'},                    'Scaling Factor:';
    display td {class => 'dataRight'},                $scalingFactor;
    display th {class => 'label'},                    'Clrtxt Idle Lifetime:';
    display td {class => 'dataRight'},                $cleartextIdleLifetime;
    display th {class => 'label'},                    'VOB Hash:';
    display td {class => 'dataRight', -colspan => 3}, $vobHashTableSize;
  display end_Tr;

  display start_Tr;
    display th {class => 'label'},                   'Clrtxt Hash:';
    display td {class => 'dataRight'},               $cleartextHashTableSize;
    display th {class => 'label'},                   'DNC Hash:';
    display td {class => 'dataRight'},               $dncHashTableSize;
    display th {class => 'label'},                   'Thread Hash:';
    display td {class => 'dataRight'},               $threadHashTableSize;
    display th {class => 'label'},                   'Process Hash:';
    display td {class => 'dataRight', colspan => 3}, $processHashTableSize;
  display end_Tr;

  display start_Tr;
    display th {class => 'labelCentered', -colspan => 10}, 'MVFS Parameters';
  display end_Tr;

  display start_Tr;
    display th {class => 'label'},     'Blocks/Dir:';
    display td {class => 'dataRight'}, $mvfsBlocksPerDirectory;
    display th {class => 'label'},     'Clrtxt Mnodes:';
    display td {class => 'dataRight'}, $mvfsCleartextMnodes;
    display th {class => 'label'},     'DirNames:';
    display td {class => 'dataRight'}, $mvfsDirectoryNames;
    display th {class => 'label'},     'FileNames:';
    display td {class => 'dataRight'}, $mvfsFileNames;
    display th {class => 'label'},     'Free Mnodes:';
    display td {class => 'dataRight'}, $mvfsFreeMnodes;
  display end_Tr;

  display start_Tr;
    display th {class => 'label'},     'Init Mnodes:';
    display td {class => 'dataRight'}, $mvfsInitialMnodeTableSize;
    display th {class => 'label'},     'Min Clrtxt Mnodes:';
    display td {class => 'dataRight'}, $mvfsMinCleartextMnodes;
    display th {class => 'label'},     'Min Free Mnodes:';
    display td {class => 'dataRight'}, $mvfsMinFreeMnodes;
    display th {class => 'label'},     'Names Not Found:';
    display td {class => 'dataRight'}, $mvfsNamesNotFound;
    display th {class => 'label'},     'RPC Handles:';
    display td {class => 'dataRight'}, $mvfsRPCHandles;
  display end_Tr;

  display end_table;
  
  return;
} # DisplayTable

# Main
GetOptions (
  usage      => sub { Usage },
  verbose    => sub { set_verbose },
  debug      => sub { set_debug },
  'server=s' => \$name,
) or Usage 'Invalid parameter';

# Announce ourselves
verbose "$FindBin::Script v$VERSION";

my $title  = $subtitle;
   $title .= $name ? ": $name" : '';

$clearadm = Clearadm->new;

$subtitle  = h1 {class => 'center'}, 'System Details: ' . ucfirst $name;

heading $title;

unless ($name) {
 display 'System is required';
 exit;
}

display h1 {class => 'center'}, $subtitle;

displaySystem $name;

#my $server = new Clearcase::Server ($name);

#DisplayTable $server;

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
 Clearcase::Server
 Display
 Utils

=end man

=begin html

<blockquote>
<a href="http://clearscm.com/php/scm_man.php?file=clearadm/lib/Clearadm.pm">Clearadm</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=clearadm/lib/ClearadmWeb.pm">ClearadmWeb</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Clearcase/Server.pm">Clearcase::Server</a><br>
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
