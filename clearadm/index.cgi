#!/usr/local/bin/perl

=pod

=head1 NAME $RCSfile: index.cgi,v $

Clearadm: Portal to your Clearcase Infrastructure

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.22 $

=item Created:

Mon Oct 25 11:10:47 PDT 2008

=item Modified:

$Date: 2011/02/14 14:50:48 $

=back

=head1 DESCRIPTION

Clearadm is a web based portal into your Clearcase infrastucture. It seeks to
provide your CM staff with an easy to use, yet informative interface to locate,
report on and monitor various aspects of the Clearcase infrastructure.

=cut

use strict;
use warnings;

use FindBin;
use Getopt::Long;

use CGI qw(:standard *table start_Tr end_Tr);
use CGI::Carp 'fatalsToBrowser';
use Convert::Base64;

use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use ClearadmWeb;
use Clearadm;
use Clearcase;
use Clearcase::Views;
use Display;
use Utils;

my $clearadm = Clearadm->new;

# Main
GetOptions(
  'usage'        => sub { Usage },
  'verbose'      => sub { set_verbose },
  'debug'        => sub { set_debug },
) or Usage "Invalid parameter";

# Announce ourselves
verbose "$ClearadmWeb::APPNAME V$ClearadmWeb::VERSION";

heading;

display p '&nbsp;';
display p <<"END";
Clearadm is a web based portal into your infrastructure. It seeks to provide
your system administrative staff with an easy to use, yet informative interface
to locate, report on and monitor various aspects of your infrastructure. 
END
  display p <<"END";
Additionally, Clearacdm is aware of Clearcase servers as well as Clearcase
objects such as views, vobs, etc. When systems are added to Clearadm that house
or server Clearcase objects, additional information is collected about those
objects.
END

display h1 {class => 'center'}, 'Systems Snapshot';

display start_table {cellspacing => 1};

my $i = 0;
my $perRow = 5;

display start_Tr;

my @systems = $clearadm->FindSystem;

$perRow = @systems if @systems < $perRow;

for (@systems) {
  my %system = %{$_};
  
  if ($i++ % $perRow == 0) {
    display end_Tr;
    display start_Tr; 
  } # if

  my %load = $clearadm->GetLatestLoadavg ($system{name});

  my $data;
  
  $data = '<strike>' if $system{active} eq 'false';
    
  $data .= a {
    href => "systemdetails.cgi?system=$system{name}"
  }, ucfirst $system{name};
  
  if ($system{notification}) {
    $data .= '&nbsp;' . a {
      href   => "alertlog.cgi?system=$system{name}"}, img {
      src    => 'alert.png',
      border => 0,
      alt    => 'Alert!',
      title  => 'This system has alerts', 
    };
  } # if
  
  my $image = $system{loadavgsmall}
    ? "data:image/png;base64,$system{loadavgsmall}"
    : "plotloadavg.cgi?system=$system{name}&tiny=1";

  $data .=  '<br>' .  
    a {href => 
      "plot.cgi?type=loadavg&system=$system{name}&scaling=Hour&points=24"
     }, img {
       src    => $image,
       border => 0,
     };
   
  $data .= '</strike>' if $system{active} eq 'false';
    
  $load{uptime} ||= 'Unknown';

  display td {class => 'dataCentered'}, "$data ",
    font {class => 'dim' }, "<br>Up: $load{uptime}";
} # for

while ($i % $perRow != 0) {
   $i++;
   display td {class => 'data'}, '&nbsp;';
} # while

display end_Tr;

display end_table;

footing;

=pod

=head1 CONFIGURATION AND ENVIRONMENT

DEBUG: If set then $debug is set to this level.

VERBOSE: If set then $verbose is set to this level.

TRACE: If set then $trace is set to this level.

=head1 DEPENDENCIES

=head2 Perl Modules

L<CGI|CGI.html>

L<CGI::Carp|CGI::Carp>

L<FindBin>

L<Getopt::Long|Getopt::Long>

=head2 ClearSCM Perl Modules

=begin man 

 Clearadm
 ClearadmWeb
 Display
 Utils

=end man

=begin html

<blockquote>
<a href="http://clearscm.com/php/scm_man.php?file=clearadm/lib/Clearadm.pm">Clearadm</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=clearadm/lib/ClearadmWeb.pm">ClearadmWeb</a><br>
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
