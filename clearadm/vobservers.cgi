#!/usr/local/bin/perl

=pod

=head1 NAME $RCSfile: vobservers.cgi,v $

View Details

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.9 $

=item Created:

Mon Oct 25 11:10:47 PDT 2008

=item Modified:

$Date: 2011/01/02 15:25:42 $

=back

=head1 SYNOPSIS

 Usage vobservers.cgi: [-u|sage] [-r|egion <region>]
                       [-ve|rbose] [-d|ebug]

 Where:
   -u|sage:           Displays usage
   -r|egion <region>: Region to use when looking for the view

   -ve|rbose:         Be verbose
   -d|ebug:           Output debug messages

=head1 DESCRIPTION

This script display the details for all vob servers in the region

=cut

use strict;
use warnings;

use FindBin;
use Getopt::Long;
use CGI qw(:standard :cgi-lib *table start_Tr end_Tr start_ol end_ol);
use CGI::Carp 'fatalsToBrowser';

use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use ClearadmWeb;
use Clearcase;
use Clearcase::Server;
use Clearcase::Vobs;
use Clearcase::Vob;
use Display;
use Utils;

my %opts = Vars;

$opts{region} ||= $Clearcase::CC->region if $Clearcase::CC;

my $subtitle = 'Vob Servers';

my $VERSION  = '$Revision: 1.9 $';
  ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);

sub DisplayVobs($) {
  my ($server) = @_;

  display h3 {
    -class => 'center',
  }, "Vobs on " . $server->name;

  display start_table;

  display start_Tr;
    display th {
      -class => 'labelCentered',
      }, '#';
    display th {
    -class => 'labelCentered',
      }, 'Tag';
    display th {
      -class => 'labelCentered',
      }, 'Type';
    display th {
      -class => 'labelCentered',
      }, 'Active';
    display th {
      -class => 'labelCentered',
      }, 'Access Path';
    display th {
      -class => 'labelCentered',
      }, 'Attributes';
  display end_Tr;

  my $i = 0;

  my $vobs = Clearcase::Vobs->new($server->name);

  for (sort $vobs->vobs) {
    my $vob = Clearcase::Vob->new($_);

    display start_Tr;
      display td {
        -class => 'dataCentered',
      }, ++$i;
      display td {
        -class => 'data',
      }, a {-href => "vobdetails.cgi?tag=" . $vob->tag}, $vob->tag;
      display td {
        -class => 'dataCentered',
      }, $vob->access;
      display td {
        -class => 'dataCentered',
      }, $vob->active;
      display td {
        -class => 'data',
      }, $vob->access_path;
      display td {
        -class => 'data',
      }, $vob->vob_registry_attributes;
    display end_Tr;
  } # for

  display end_table;
} # DisplayVob

sub DisplayTable(@) {
  my (@vobServers) = @_;

  my $unknown = font {-class => 'unknown'}, 'Unknown';

  display start_table {
    -cellspacing    => 1,
    -class          => 'main',
  };

  display start_Tr;
    display th {
      -class => 'labelCentered',
      }, '#';
    display th {
      -class => 'labelCentered',
      }, 'Server';
    display th {
      -class => 'labelCentered',
      }, 'CC Version';
    display th {
      -class => 'labelCentered',
      }, 'OS Version';
    display th {
      -class => 'labelCentered',
      }, 'Hardware';
    display th {
      -class => 'labelCentered',
      }, 'Registry Host';
    display th {
      -class => 'labelCentered',
      }, 'Region';
    display th {
      -class => 'labelCentered',
      }, 'License Host';
  display end_Tr;

  my $i = 0;

  my $server;

  for (@vobServers) {
    $server = Clearcase::Server->new($_, $opts{region});

    display start_Tr;
      display td {
        -class => 'dataCentered',
      }, ++$i;
      display td {
        -class   => 'dataCentered',
      }, a {-href => "systemdetails.cgi?system=" . $server->name}, $server->name;
      display td {
        -class => 'dataCentered',
      }, $server->ccVer;
      display td {
        -class => 'dataCentered',
      }, $server->osVer;
      display td {
        -class => 'dataCentered',
      }, $server->hardware;
      display td {
        -class => 'dataCentered',
      }, a {-href => "systemdetails.cgi?system=" . $server->registryHost}, $server->registryHost;
      display td {
        -class => 'dataCentered',
      }, $server->registryRegion;
      display td {
        -class => 'dataCentered',
      }, $server->licenseHost;
    display end_Tr;

    display start_Tr;
      display th {
        -class => 'labelCentered',
        }, 'MVFS';
      display th {
        -class => 'labelCentered',
        }, 'Scaling';
      display th {
        -class => 'labelCentered',
        }, 'Free Mnodes';
      display th {
        -class => 'labelCentered',
        }, 'Free Mnodes Cleartext';
      display th {
        -class => 'labelCentered',
        }, 'File names';
      display th {
        -class => 'labelCentered',
        }, 'Directory names';
      display th {
        -class => 'labelCentered',
        }, 'Blocks Per Directory';
      display th {
        -class => 'labelCentered',
        }, 'Names not found';
    display end_Tr;

    display start_Tr;
      display td {
        -class => 'dataCentered',
      }, '&nbsp;';
      display td {
        -class   => 'dataCentered',
      }, $server->scalingFactor;
      display td {
        -class   => 'dataRight',
      }, $server->mvfsFreeMnodes;
      display td {
        -class => 'dataRight',
      }, $server->mvfsFreeMnodesCleartext;
      display td {
        -class => 'dataRight',
      }, $server->mvfsFileNames;
      display td {
        -class => 'dataRight',
      }, $server->mvfsDirectoryNames;
      display td {
        -class => 'dataRight',
      }, $server->mvfsBlocksPerDirectory;
      display td {
        -class => 'dataRight',
      }, $server->mvfsNamesNotFound;
    display end_Tr;

    display start_Tr;
      display th {
        -class => 'labelCentered',
        }, 'RPC Handles';
      display th {
        -class => 'labelCentered',
        }, 'Cleartext Idle Lifetime';
      display th {
        -class => 'labelCentered',
        }, 'VOB HTS';
      display th {
        -class => 'labelCentered',
        }, 'Cleartext HTS';
      display th {
        -class => 'labelCentered',
        }, 'Thread HTS';
      display th {
        -class => 'labelCentered',
        }, 'DNC HTS';
      display th {
        -class => 'labelCentered',
        }, 'Process HTS';
      display th {
        -class => 'labelCentered',
        }, 'Initial Mnode Table Size';
    display end_Tr;

    display start_Tr;
      display td {
        -class => 'dataRight',
      }, $server->mvfsRPCHandles;
      display td {
        -class => 'dataRight',
      }, $server->cleartextIdleLifetime;
      display td {
        -class   => 'dataRight',
      }, $server->vobHashTableSize;
      display td {
        -class   => 'dataRight',
      }, $server->cleartextHashTableSize;
      display td {
        -class => 'dataRight',
      }, $server->threadHashTableSize;
      display td {
        -class => 'dataRight',
      }, $server->dncHashTableSize;
      display td {
        -class => 'dataRight',
      }, $server->processHashTableSize;
      display td {
        -class => 'dataRight',
      }, $server->mvfsInitialMnodeTableSize;
    display end_Tr;
    display end_table;
  } # for
  
  display p;
  DisplayVobs $server;

  return;
} # DisplayTable

# Main
GetOptions(
  \%opts,
  'usage'        => sub { Usage },
  'verbose'      => sub { set_verbose },
  'debug'        => sub { set_debug },
  'region=s',
) or Usage "Invalid parameter";

# Announce ourselves
verbose "$FindBin::Script v$VERSION";

heading $subtitle;

display h1 {
  -class => 'center',
}, $subtitle;

my ($status, @output) = $Clearcase::CC->execute (
  "lsvob -region $opts{region} -long"
);

error "Unable to list all vobs in the region $opts{region}"
    . join("\n", @output), 1 if $status;

my %vobServers;

for (@output) {
  if (/Server host: (.*)/) {
    $vobServers{$1} = undef;
  } # if
} # for

DisplayTable sort(keys(%vobServers));

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
 Clearcase::Server
 Display
 Utils

=end man

=begin html

<blockquote>
<a href="http://clearscm.com/php/scm_man.php?file=clearadm/lib/ClearadmWeb.pm">ClearadmWeb</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Clearcase.pm">Clearcase</a><br>
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
