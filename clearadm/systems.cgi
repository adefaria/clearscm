#!/usr/local/bin/perl

=pod

=head1 NAME $RCSfile: systems.cgi,v $

Systems

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.15 $

=item Created:

Mon Oct 25 11:10:47 PDT 2008

=item Modified:

$Date: 2011/02/14 14:54:59 $

=back

=head1 SYNOPSIS

 Usage systems.cgi: [-u|sage] [-ve|rbose] [-d|ebug]

 Where:
   -u|sage:               Displays usage
   -v|erbose:             Be verbose
   -d|ebug:               Output debug messages

=head2 DESCRIPTION

This script displays all known systems

=cut

use strict;
use warnings;

use FindBin;
use Getopt::Long;
use CGI qw (:standard :cgi-lib *table start_Tr end_Tr start_td end_td);
use CGI::Carp 'fatalsToBrowser';

use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Clearadm;
use ClearadmWeb;
use Display;
use Utils;

my $VERSION  = '$Revision: 1.15 $';
  ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);
  
my $subtitle = 'Systems Status: All Systems';

my $clearadm;

sub DisplaySystems () {
  display start_table {cellspacing => 1, class => 'main'};
  
  display start_Tr;
    display th {class => 'labelCentered'}, 'Action';
    display th {class => 'labelCentered'}, 'Name';
    display th {class => 'labelCentered'}, 'Alias';
    display th {class => 'labelCentered'}, 'Admin';
    display th {class => 'labelCentered'}, 'Type';
    display th {class => 'labelCentered'}, 'Last Contacted';
    display th {class => 'labelCentered'}, 'Current load';
    display th {class => 'labelCentered'}, 'Threshold';
    display th {class => 'labelCentered'}, 'Load Avg';
  display end_Tr;
  
  foreach ($clearadm->FindSystem) {
    my %system = %{$_};
  
    $system{alias}  = setField $system{alias},  'N/A';
    $system{region} = setField $system{region}, 'N/A';

    my $admin = ($system{email})
              ? a {href => "mailto:$system{email}"}, $system{admin}
              : $system{admin};
  
    my $alias = ($system{alias} !~ 'N/A')
              ? a {
                  href => "systemdetails.cgi?system=$system{name}"
                }, $system{alias}
              : $system{alias};
      
    my %load = $clearadm->GetLatestLoadavg ($system{name});

    $load{loadavg}   ||= 0;
    $load{timestamp} ||= 'unknown';
    
    my $class         = $load{loadavg} < $system{loadavgThreshold} 
                      ? 'data'
                      : 'dataAlert';
    my $classRight    = $load{loadavg} < $system{loadavgThreshold} 
                      ? 'dataRight'
                      : 'dataRightAlert';
    my $classRightTop = $load{loadavg} < $system{loadavgThreshold}
                      ? 'dataRightTop'
                      : 'dataRightAlertTop';                      

    display start_Tr;
      display start_td {class => 'data'};

      my $areYouSure = 'Are you sure you want to delete this system?\n'
                     . 'Doing so will remove all records related to '
                     . $system{name}
                     . '\nincluding filesystem records and history as well as '
                     . 'loadavg history.';
  
      display start_form {
        method => 'post',
        action => "processsystem.cgi",
      };
        
      display input {
        name  => 'name',
        type  => 'hidden',
        value => $system{name},
      };
        
      display input {
        name    => 'delete',
        type    => 'image',
        src     => 'delete.png',
        alt     => 'Delete',
        title   => 'Delete',
        value   => 'Delete',
        onclick => "return AreYouSure ('$areYouSure');"
      };
      display input {
        name    => 'edit',
        type    => 'image',
        src     => 'edit.png',
        alt     => 'Edit',
        title   => 'Edit',
        value   => 'Edit',
      };
      display checkbox {
        disabled => 'disabled',
        checked  => $system{active} eq 'true' ? 1 : 0,
      };    
          
      if ($system{notification}) {
        display a {href => "alertlog.cgi?system=$system{name}"}, img {
          src    => 'alert.png',
          border => 0,
          alt    => 'Alert!',
          title  => 'This system has alerts', 
        };
      } # if
                      
      display end_form;
       
      display end_td;    
      display td {class => $class},
        a {href => "systemdetails.cgi?system=$system{name}"}, $system{name};
      display td {class => $class}, $alias;
      display td {class => $class}, $admin;
      display td {class => $class}, $system{type};
      
      my $lastheardfromClass = 'dataCentered';
      my $lastheardfromData  = $system{lastheardfrom};
  
      unless ($clearadm->SystemAlive (%system)) {
        $lastheardfromClass = 'dataCenteredAlert';
        $lastheardfromData  = a {
          href  => "alertlog.cgi?system=$system{name}",
          class => 'alert',
          title => "Have not heard from $system{name} for a while"
        }, $system{lastheardfrom};
        $system{notification} = 'Heartbeat';
      } # unless
      
      display td {class => $lastheardfromClass}, "$lastheardfromData ",
        font {class => 'dim' }, "<br>Up: $load{uptime}";
      display td {class => $classRightTop}, "$load{loadavg} ",
        font {class => 'dim' }, "<br>$load{timestamp}";
      display td {class => $classRightTop}, $system{loadavgThreshold};
      display td {class => $class}, 
        a {
          href => 
            "plot.cgi?type=loadavg&system=$system{name}&scaling=Hour&points=24"
        }, img {
          src    => "plotloadavg.cgi?system=$system{name}&tiny=1",
          border => 0,
        };
    display end_Tr;
  } # foreach

  display end_table;
  
  display p {class => 'center'}, a {
    href => 'processsystem.cgi?action=Add',
  }, 'New system', img {
    src    => 'add.png',
    border => 0,
  };
  
  return;
} # DisplaySystems

# Main
GetOptions (
  usage   => sub { Usage },
  verbose => sub { set_verbose },
  debug   => sub { set_debug },
) or Usage 'Invalid parameter';

# Announce ourselves
verbose "$FindBin::Script v$VERSION";

$clearadm = Clearadm->new;

heading $subtitle;

display h1 {class => 'center'}, $subtitle;

DisplaySystems;

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
