#!/usr/bin/perl

=pod

=head1 NAME $RCSfile: plotloadavg.cgi,v $

Plot loadavg for a system

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.15 $

=item Created:

Mon Dec 13 09:13:27 EST 2010

=item Modified:

$Date: 2011/01/20 14:34:24 $

=back

=head1 SYNOPSIS

 Usage plotfs.cgi: system=<system> 
                   [height=<height>] [width=<width>] [color=<color>]
                   [scaling=<scaling>] [points=<points>] [tiny=<0|1>] 

 Where:
   <system>:     Name of the system defined in the Clearadm database to
                 retrieve loadavgs snapshots for.
   <height>:     Height of chart (Default: 480px - tiny: 40)
   <width>:      Width of chart (Default: 800px - tiny: 150)
   <color>:      A GD::Color color value (Default: lblue)
   <scaling>:    Currently one of Minute, Hour, Day or Month. Specifies how
                 Clearadm::GetFS will scale the data returned (Default: Minute 
                 - tiny: Day)
   <points>:     Number of points to plot (Default: all points - tiny: 7)
   
=head1 DESCRIPTION

Draws a chart of loadavg for the system passed in. Parameters such as height, 
width, color, scaling and points can be set individually though more often the
user will just use the web controls to set them. Defaults produce a nice chart.
Tiny mode is used by systemdetails.cgi to draw tiny charts in the table. Setting
tiny sets a number of the other chart options to produce a standard, tiny chart.

=cut

use strict;
use warnings;

use FindBin;

use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Clearadm;
use ClearadmWeb;
use Display;

use CGI qw (:standard :cgi-lib);
use GD::Graph::area;

my %opts = Vars;

my $VERSION  = '$Revision: 1.15 $';
  ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);
  
$opts{color}  ||= 'lyellow';
$opts{height} ||= 400;
$opts{width}  ||= 800;

if ($opts{tiny}) {
  $opts{height}  = 40;
  $opts{width}   = 150;
  $opts{points}  = 24;
  $opts{scaling} = 'Hour';
} # if

my $clearadm = Clearadm->new;

my $graph = GD::Graph::area->new ($opts{width}, $opts{height});

graphError "System is required"
  unless $opts{system};
  
graphError "Points not numeric (points: $opts{points})"
  if $opts{points} and $opts{points} !~ /^\d+$/;

my @loads = $clearadm->GetLoadavg (
  $opts{system},
  $opts{start},
  $opts{end},
  $opts{points},
  $opts{scaling}
);

graphError "No loadavg data found for system $opts{system}"
  unless @loads;

my (@x, @y);

foreach (@loads) {
  my %load = %{$_};
  
  if ($opts{tiny}) {
  	push @x, '';
  } else {
    push @x, $load{timestamp};
  } # if

  push @y, $load{loadavg};
} # foreach

my @data = ([@x], [@y]);

my $x_label_skip = @x > 1000 ? 200
                 : @x > 100  ?  20
                 : @x > 50   ?   2
                 : @x > 10   ?   1
                 : 0;

my $x_label = $opts{tiny} ? '' : 'Time';
my $y_label = $opts{tiny} ? '' : 'Load';
my $title   = $opts{tiny} ? '' : "Load Average for $opts{system}";
my $labelY  = $opts{tiny} ? '' : '%.2f';

$graph->set (
  x_label           => $x_label,
  x_labels_vertical => 1,
  x_label_skip      => $x_label_skip,
  x_label_position  => .5,
  y_label           => $y_label,
  y_number_format   => $labelY,
  title             => $title,
  dclrs             => [$opts{color}],
  bgclr             => 'white',
  transparent       => 0,
  long_ticks        => 1,
  t_margin          => 5,
  b_margin          => 5,
  l_margin          => 5,
  r_margin          => 5,
) or graphError $graph->error;

my $image = $graph->plot(\@data)
  or croak $graph->error;

print "Content-type: image/png\n\n";
print $image->png;

=pod

=head1 CONFIGURATION AND ENVIRONMENT

DEBUG: If set then $debug is set to this level.

VERBOSE: If set then $verbose is set to this level.

TRACE: If set then $trace is set to this level.

=head1 DEPENDENCIES

=head2 Perl Modules

L<CGI>

L<FindBin>

L<GD::Graph::area|GD::Graph::area>

=head2 ClearSCM Perl Modules

=begin man 

 Clearadm
 ClearadmWeb
 Display

=end man

=begin html

<blockquote>
<a href="http://clearscm.com/php/scm_man.php?file=clearadm/lib/Clearadm.pm">Clearadm</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=clearadm/lib/ClearadmWeb.pm">ClearadmWeb</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Display.pm">Display</a><br>
</blockquote>

=end html

=head1 BUGS AND LIMITATIONS

There are no known bugs in this script

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, ClearSCM, Inc. All rights reserved.

=cut