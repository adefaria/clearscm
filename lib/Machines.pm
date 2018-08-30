=pod

=head1 NAME $RCSfile: Machines.pm,v $

Object oriented interface to list of managed machines

=head1 VERSION

=over

=item Author:

Andrew DeFaria <Andrew@DeFaria.com>

=item Revision:

$Revision: 1.0 $

=item Created:

Thu, Jul 12, 2018  5:11:44 PM

=item Modified:

$Date: $

=back

=head1 SYNOPSIS

Perl module to specify a list of managed machines for rexec.pl

  $machines = Machines->new (filename => "/opt/clearscm/data/machines");

  my @machines = $machines->all;

  my @linux_machines = $machines->select(condition => 'OS = "linux"');

=head1 DESCRIPTION

Machines is an OO interface to a list of managed machines. By default it parses
a file that contains machine names and other identifying information.

=head1 ROUTINES

The following routines are exported:

=cut

package Machines;

use strict;
use warnings;

use base 'Exporter';

use Carp;

sub _parseFile() {
  my ($self) = @_;

  my %machines;

  # Simple parse for now
  open my $machineFile, '<', $self->{filename}
    or croak "Unable to open $self->{filename} - $!";

  while (<$machineFile>) {
    chomp;

    next if /^#/; # Skip comments

    my ($name, $model, $os, $ccver, $owner, $usage) = split /:/;

    my %machineInfo = (
      model => $model,
      os    => $os,
      ccver => $ccver,
      owner => $owner,
      usage => $usage,
    );

    $machines{$name} = \%machineInfo;
  } # while

  close $machineFile;

  return \%machines;
} # _parseFile

sub new(;%){
  my ($class, %parms) = @_;

=pod

=head2 new (<parms>)

Construct a new Machines object. The following OO style arguments are
supported:

Parameters:

=for html <blockquote>

=over

=item filename:

Filename to parse

=item path:

Path where file resides

=back

=for html </blockquote>

Returns::

=for html <blockquote>

=over

=item Machines object

=back

=for html </blockquote>

=cut

  $parms{filename} ||= 'machines';

  if (! -r $parms{filename}) {
    croak "Unable to read $parms{filename}";
  } # if

  my $self = bless {
    filename => $parms{filename},
  }, $class; # bless

  # Parse file
  $self->{machines} = $self->_parseFile;

  return $self;
} # new

sub select(;$) {
  my ($self, $condition) = @_;

=pod

=head3 select

Return machines that qualify based on $condition

Parameters:

=for html <blockquote>

=over

=item $condition

Condition to apply to machine list

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Array of qualifying machines

=back

=for html </blockquote>

=cut

  $condition //= '';

  if ($condition) {
  	croak "Not supporting conditions yet";
  } else {
    return %{$self->{machines}};
  } # if
} # select

sub GetSystem($) {
  my ($self, $systemName) = @_;

  return;
} # getSystem

sub AddSystem(%) {
  my ($self, %system) = @_;

  return;
} # addSystem

sub ChangeSystem(%){
  my ($self, %system) = @_;

  return;
} # changeSystem

sub DeleteSystem($) {
  my ($self, $systemName) = @_;

  return;
} # deleteSystem

sub DumpSystems(;$) {
  my ($self, $filename) = @_;

  $filename ||= 'machines';

  open my $file, '>', $filename
    or croak "Unable to open $filename for writing - $!";

  # Write header
  print $file <<"END";
################################################################################
#
# File:         $filename
# Description:  Dump of machines for use with rexec.pl
# Author:       Andrew\@DeFaria.com
#
################################################################################
# Column 1 Machine name
# Column 2 Alias
# Column 3 Active
# Column 4 Admin name
# Column 5 Admin email
# Column 6 OS version
# Column 7 OS Type
# Column 8 Last heard from
# Column 9 Description
END

  # Write out machine info
  my @fields = qw(name alias active admin email os type lastheardfrom description);

  for my $record ($self->select) {
    my %machine = %$record;

    for (@fields) {
      print $file "$machine{$_}|"
    } # for

    print $file "\n";
  } # for

  close $file;

  return;
} # DumpSystems

sub ReadSystemsFile(;$) {
  my ($self, $filename) = @_;

  $filename ||= 'machines';

  open my $file, '<', $filename
    or croak "Unable to open $filename - $!";

  my @systems;

  while (<$file>) {
    chomp;

    next if /^#/;

    my ($name, $model, $osver, $ccver, $owner, $usage) = split ':';
    my %system = (
      name        => $name,
      model       => $model,
      ccver       => $ccver,
      admin       => $owner,
      os          => $osver,
      type        => 'Unix',
      description => $usage,
    );

    push @systems, \%system;
  } # while

  close $file;

  return @systems;
} # ReadSystemsFile

1;

=pod

=head2 CONFIGURATION AND ENVIRONMENT

DEBUG: If set then $debug in this module is set.

VERBOSE: If set then $verbose in this module is set.

=head2 DEPENDENCIES

=head3 Perl Modules

L<File::Spec>

L<IO::Handle>

=head3 ClearSCM Perl Modules

=for html <p><a href="/php/scm_man.php?file=lib/DateUtils.pm">DateUtils</a></p>

=for html <p><a href="/php/scm_man.php?file=lib/Display.pm">Display</a></p>

=for html <p><a href="/php/scm_man.php?file=lib/Mail.pm">Mail</a></p>

=for html <p><a href="/php/scm_man.php?file=lib/OSDep.pm">OSDep</a></p>

=for html <p><a href="/php/scm_man.php?file=lib/Utils.pm">Utils</a></p>

=head2 INCOMPATABILITIES

None yet...

=head2 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head2 LICENSE AND COPYRIGHT

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
