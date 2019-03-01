#!/usr/local/bin/perl

=pod

=head1 NAME $RCSfile: viewservers.cgi,v $

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

$Date: 2011/01/02 15:25:23 $

=back

=head1 SYNOPSIS

 Usage viewservers.cgi: [-u|sage] [-r|egion <region>]
                       [-ve|rbose] [-d|ebug]

 Where:
   -u|sage:           Displays usage
   -r|egion <region>: Region to use when looking for the view

   -ve|rbose:         Be verbose
   -d|ebug:           Output debug messages

=head1 DESCRIPTION

This script display the details for all view servers in the region

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
use Clearcase::Server;
use Display;
use Utils;

my %opts = Vars;

$opts{region} ||= $Clearcase::CC->region;

my $subtitle = 'View Servers';

my $VERSION  = '$Revision: 1.9 $';
  ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);

sub DisplayTable (@) {
  my (@viewServers) = @_;

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
  display end_Tr;

  my $i = 0;

  foreach (@viewServers) {
    my $server = Clearcase::Server->new ($_, $opts{region});

    # Data fields
    my $name  = $server->name;
    my $ccVer = $server->ccVer;
    my $osVer = $server->osVer;

    $ccVer ||= $unknown;
    $osVer ||= $unknown;

    display start_Tr;
      display td {
        -class => 'dataCentered',
      }, ++$i;
      display td {
        -class   => 'data',
      }, a {-href => "serverdetails.cgi?server=$name"}, $name;
      display td {
        -class => 'data',
      }, $ccVer;
      display td {
        -class => 'data',
      }, $osVer;
    display end_Tr;
  } # foreach

  display end_table;
  
  return;
} # DisplayTable

# Main
GetOptions (
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

my ($status, @output) = $Clearcase::CC->execute ("lsview -region $opts{region} -long");

error "Unable to list all views in the region $opts{region}" . join ("\n", @output), 1
  if $status;

my %viewServers;

foreach (@output) {
  if (/Server host: (.*)/) {
    $viewServers{$1} = undef;
  } # if
} # foreach

DisplayTable sort (keys (%viewServers));

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
