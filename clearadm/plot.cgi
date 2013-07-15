#!/usr/bin/perl

=pod

=head1 NAME $RCSfile: plot.cgi,v $

Plot statistics

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.14 $

=item Created:

Mon Oct 25 11:10:47 PDT 2008

=item Modified:

$Date: 2011/01/28 21:30:45 $

=back

=head1 DESCRIPTION

Display a graph of either Loadavg or Filesystem data and provide controls for
the user to manipulate the chart.

=cut

use strict;
use warnings;

use FindBin;
use CGI qw (:standard :cgi-lib start_table end_table start_Tr end_Tr);
use GD::Graph::area;

use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Clearadm;
use ClearadmWeb;
use Display;

my $VERSION  = '$Revision: 1.14 $';
  ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);
  
my %opts = Vars;

my $clearadm;

sub displayGraph () {
  my $parms;

  foreach (keys %opts) {
    $parms .= '&'
      if $parms;
    $parms .= "$_=$opts{$_}"
  } # foreach

  display '<center>';
  
  if ($opts{type} eq 'loadavg') {
  	unless ($opts{tiny}) {
      display img {src => "plotloadavg.cgi?$parms", class => 'chart'};
  	} else {
      display img {src => "plotloadavg.cgi?$parms", border => 0};
  	} # unless
  } elsif ($opts{type} eq 'filesystem') {
  	unless ($opts{tiny}) {
      display img {src => "plotfs.cgi?$parms", class => 'chart'};
  	} else {
      display img {src => "plotfs.cgi?$parms", border => 0};
  	} # unless
  } # if

  display '</center>';
  
  return
} # displayGraph

sub displayFSInfo () {
  if ($opts{filesystem}) {
    display h3 {-align => 'center'}, 'Latest Filesystem Reading';
  } else {
  	display p;
  	return;
  } # if
  
  display start_table {width => '800px', cellspacing => 1};
  
  display start_Tr;
    display th {class => 'labelCentered'}, 'Filesystem';
    display th {class => 'labelCentered'}, 'Type';
    display th {class => 'labelCentered'}, 'Mount';
    display th {class => 'labelCentered'}, 'Size';
    display th {class => 'labelCentered'}, 'Used';
    display th {class => 'labelCentered'}, 'Free';
    display th {class => 'labelCentered'}, 'Used %';
    display th {class => 'labelCentered'}, 'History';
    display th {class => 'labelCentered'}, 'Threshold';
  display end_Tr;  
  
  my %filesystem = $clearadm->GetFilesystem (
    $opts{system}, 
    $opts{filesystem}
  );
  my %fs = $clearadm->GetLatestFS   (
    $opts{system},
    $opts{filesystem}
  );
  
  my $size = autoScale $fs{size};
  my $used = autoScale $fs{used};
  my $free = autoScale $fs{free};    

  display start_Tr;
    display td {class => 'data'},         $filesystem{filesystem};
    display td {class => 'dataCentered'}, $filesystem{fstype};
    display td {class => 'data'},         $filesystem{mount};
    display td {class => 'dataRight'},    $size;
    display td {class => 'dataRight'},    $used;
    display td {class => 'dataRight'},    $free;
    # TODO: Note that this percentages does not agree with df output. I'm not 
    # sure why.
    display td {class => 'dataCentered'},
      sprintf ('%.0f%%', (($fs{reserve} + $fs{used}) / $fs{size} * 100));
    display td {class => 'dataCentered'}, $filesystem{filesystemHist};
    display td {class => 'dataCentered'}, "$filesystem{threshold}%";
  display end_Tr;
  
  display end_table;
  
  return;  
} # displayInfo

sub displayControls () {
  my $class = $opts{type} =~ /loadavg/i 
            ? 'controls'
            : 'filesystemControls';
  
  display start_table {
    align       => 'center',
    class       => $class,
    cellspacing => 0,
    width       => '800px',
  };
  
  my $systemLink = span {id => 'systemLink'}, a {
    href => "systemdetails.cgi?system=$opts{system}",
  }, 'System';

  my $systemButtons = makeSystemDropdown (
    $systemLink, 
    $opts{system}, 
    'updateFilesystems(this.value);updateSystemLink(this.value)'
  );

  my $startButtons = makeTimeDropdown (
    $opts{type},
    'startTimestamp',
    $opts{system},
    $opts{filesystem},
    'Start',
    $opts{start},
    $opts{scaling},
  );

  my $endButtons = makeTimeDropdown (
    $opts{type},
    'endTimestamp',
    $opts{system},
    $opts{filesystem},
    'End',
    $opts{end},
    $opts{scaling},
  );

  my $update = $opts{type} eq 'loadavg' 
             ? "updateSystem('$opts{system}')"
             : "updateFilesystem('$opts{system}','$opts{filesystem}')";
             
  my $intervalButtons = makeIntervalDropdown (
    'Interval',
    $opts{scaling},
    $update
  );
  
  display start_Tr;
    display td $startButtons;
    display td $intervalButtons;
    display td $systemButtons;
  display end_Tr;

  display start_Tr;
    display td $endButtons;
    display td 'Points', 
      input {
        name      => 'points',
        value     => $opts{points},
        class     => 'inputfield',
        size      => 7,
        style     => 'text-align: right',
        maxlength => 7,
      };  

  if ($opts{type} eq 'loadavg') {
    display td input {
      type  => 'submit',
      value => 'Draw Graph',
    };
  } else {
    my $filesystemButtons = makeFilesystemDropdown (
      $opts{system}, 
      'Filesystem',
      undef,
      "updateFilesystem('$opts{system}',this.value)",
    );
  	
    display td $filesystemButtons;
    
    display end_Tr;
    display start_Tr;
    display td {align => 'center', colspan => 3}, 
      input {type => 'submit', value => 'Draw Graph'};
  } # if
  
  display end_Tr;

  display end_table;
  
  return;
} # displayControls

$clearadm = Clearadm->new;

my $title  = ucfirst ($opts{type}) . ': ' . ucfirst $opts{system};

$title .= ":$opts{filesystem}"
  if $opts{filesystem};

heading $title;

display h1 {class => 'center'}, $title;

display start_form {
  method => 'get', 
  action => 'plot.cgi',
};

# Some hidden fields to pass along
display input {type => 'hidden', name => 'type', value => $opts{type}};

displayGraph;
displayFSInfo;
displayControls;

display end_form;   

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

=end man

=begin html

<blockquote>
<a href="http://clearscm.com/php/cvs_man.php?file=clearadm/lib/Clearadm.pm">Clearadm</a><br>
<a href="http://clearscm.com/php/cvs_man.php?file=clearadm/lib/ClearadmWeb.pm">ClearadmWeb</a><br>
<a href="http://clearscm.com/php/cvs_man.php?file=lib/Display.pm">Display</a><br>
</blockquote>

=end html

=head1 BUGS AND LIMITATIONS

There are no known bugs in this script

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, ClearSCM, Inc. All rights reserved.

=cut