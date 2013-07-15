=pod

=head1 NAME $RCSfile: Machines.pm,v $

Abstraction of machines.

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.4 $

=item Created

Tue Jan  8 17:24:16 MST 2008

=item Modified

$Date: 2011/11/16 19:46:13 $

=back

=head1 SYNOPSIS

This module handles the details of providing information about
machines while obscuring the mechanism for storing such information.

 my $machines = Machines->new;

 foreach ($machine->all) {
   my %machine = %{$_};
   display "Machine: $machine{name}";
   disp.ay "Owner: $machine{owner}"
 } # if

=head1 DESCRIPTION

This module provides information about machines

=head1 ROUTINES

The following routines are exported:

=cut

package Machines;

use strict;
use warnings;

use Display;
use Utils;

use base 'Exporter';

our @EXPORT = qw (
  all
  new
);

sub new {
  my ($class, %parms) = @_;

=pod

=head2 new (<parms>)

Construct a new Machines object. The following OO style arguments are
supported:

Parameters:

=for html <blockquote>

=over

=item file:

Name of an alternate file from which to read machine information. This
is intended as a quick alternative.

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Machines object

=back

=for html </blockquote>

=cut

  my $file = $parms{file} ? $parms{file} : "$FindBin::Bin/../etc/machines";

  error "Unable to find $file", 1 if ! -f $file;

  my %machines;

  foreach (ReadFile $file) {
    my @parts = split;

    # Skip commented out or blank lines
    next if $parts[0] =~ /^#/ or $parts[0] =~ /^$/;

    $machines{$parts[0]} = $parts[1];
  } # foreach

  bless {
    file     => $parms {file},
    machines => \%machines,
  }, $class; # bless

  return $class;
} # new

sub all () {
  my ($self) = @_;

=pod

=head3 all ()

Returns all known machines as an array of hashes

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=begin html

<blockquote>

=end html

=over

=item Array of machine hash records

=back

=for html </blockquote>

=cut

  return %{$self->{machines}};
} # display

1;

=pod

=head1 CONFIGURATION AND ENVIRONMENT

MACHINES: If set then points to a flat file containing machine
names. Note this is providied as a way to quickly use an alternate
"machine database". As such only minimal information is support.

=head1 DEPENDENCIES

 Display
 Rexec

=head1 INCOMPATABILITIES

None yet...

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head1 LICENSE AND COPYRIGHT

This Perl Module is freely available; you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation; either version 2 of the
License, or (at your option) any later version.

This Perl Module is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License (L<http://www.gnu.org/copyleft/gpl.html>) for more
details.

You should have received a copy of the GNU General Public License
along with this Perl Module; if not, write to the Free Software Foundation,
Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
reserved.

=cut
