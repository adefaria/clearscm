=pod

=head2 NAME $RCSfile: FileSystem.pm,v $

Object oriented interface to filesystems

=head2 VERSION

=over

=item Author:

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision:

$Revision: $

=item Created:

Thu Dec 11 10:39:12 MST 2008

=item Modified:

$Date:$

=back

=head2 SYNOPSIS

This module implements a FileSystem object.

  $fs = new FileSystem ("hosta");

  while ($fs->filesystem) {
    display "Filesystem: $_";
    display "\tSize:\t$fs{$_}->size";
    display "\tUsed:$fs{$_}->used";
    display "\tFree:$fs{$_}->free";
    display "\tUsed %:$fs{$_}->usedPct";
    display "\tMounted on:$fs{$_}->mount";
  } # while

=head2 DESCRIPTION

Filesystem creates a filesystem object that encapsulates information
about the file system as a whole.

=head2 ROUTINES

The following routines are exported:

=over

=cut

use strict;
use warnings;

package Filesystem;

use base "Exporter";

use OSDep;
use Display;
use Utils;
use Rexec;

=pod

=head3 new (<parms>)

Construct a new Filesystem object. The following OO style arguments are
supported:

Parameters:

=for html <blockquote>

=over

=item none

Returns:

=for html <blockquote>

=over

=item Filesystem object

=back

=for html </blockquote>

=cut

sub new ($;$$$$) {
  my ($class, $system, $ostype, $username, $password, $prompt, $shellstyle) = @_;

  # Set prompt if not passed in
  $prompt ||= $Rexec::default_prompt;

  # Connect to remote machine
  my $remote = new Rexec (
    host	=> $system,
    username	=> $username,
    password	=> $password,
    prompt	=> $prompt,
    shellstyle	=> $shellstyle,
  );

  unless ($remote) {
    error "Unable to connect to $system";

    return undef;
  } # if

  my (@fs, %fs);

  # Sun is so braindead!
  if ($ostype eq "Unix") {
    foreach ("ufs", "vxfs") {
      my $cmd = "/usr/bin/df -k -F $_";

      my @unixfs = $remote->exec ($cmd);

      if ($remote->status != 0) {
	error ("Unable to determine fsinfo on $system ($cmd)\n" . join ("\n", @fs));;
	return undef;
      } # if

      # Skip heading
      shift @unixfs;

      for (my $i = 0; $i < scalar @unixfs; $i++) {
	my (%fsinfo, $firstField);
	
	# Trim leading and trailing spaces
	$unixfs[$i] =~ s/^\s+//;
	$unixfs[$i] =~ s/\s+$//;

	my @fields = split /\s+/, $unixfs[$i];

	if (scalar @fields == 1) {
	  $fsinfo{fs}	= $fields[0];
	  $firstField	= 0;
	  $i++;

	  # Trim leading and trailing spaces
	  $unixfs[$i] =~ s/^\s+//;
	  $unixfs[$i] =~ s/\s+$//;

	  @fields	= split /\s+/, $unixfs[$i];;
	} else {
	  $fsinfo{fs}	= $fields[0];
	  $firstField	= 1;
	} #if

	$fsinfo{size}		= $fields[$firstField]     * 1024;
	$fsinfo{used}		= $fields[$firstField + 1] * 1024;
	$fsinfo{free}		= $fields[$firstField + 2] * 1024;
	$fsinfo{reserve}	= $fsinfo{size} - $fsinfo{used} - $fsinfo{free};

	$fs{$fields[$firstField + 4]} = \%fsinfo;
      } # for
    } # foreach
  } elsif ($ostype eq "Linux") {
    foreach ("ext3") {
      my $cmd = "/bin/df --block-size=1 -t $_";

      my @linuxfs = $remote->exec ($cmd);

      if ($remote->status != 0) {
	error ("Unable to determine fsinfo on $system ($cmd)\n" . join ("\n", @fs));;
	return undef;
      } # if

      # Skip heading
      shift @linuxfs;

      foreach (@linuxfs) {
	my %fsinfo;
	my @fields = split;
	
	$fsinfo{fs}		= $fields[0];
	$fsinfo{size}		= $fields[1];
	$fsinfo{used}		= $fields[2];
	$fsinfo{free}		= $fields[3];
	$fsinfo{reserve}	= $fsinfo{size} - $fsinfo{used} - $fsinfo{free};

	$fs{$fields[5]}	= \%fsinfo;
      } # foreach
    } # foreach
  } else {
    error "Can't handle $ostype", 1;
  } # if

  bless \%fs, $class;
} # new

=pod

=head3 mounts ()

Returns an array of mount points

Parameters:

=for html <blockquote>

=over

=item none

None

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Array of mount points

=back

=for html </blockquote>

=cut

sub mounts () {
  my ($self) = shift;

  return keys %{$self}
} # mounts

=pod

=head3 getFSInfo ($mount)

Returns a hash of filesystem info for a mount point

Parameters:

=for html <blockquote>

=over

=item $mount: Mount point

None

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Hash of filesystem info

=back

=for html </blockquote>

=cut

sub getFSInfo ($) {
  my ($self, $mount) = @_;

  return %{$self->{$mount}};
} # getFSInfo

1;

=back

=head2 CONFIGURATION AND ENVIRONMENT

None

=head2 DEPENDENCIES

  Display
  OSDep
  Utils

=head2 INCOMPATABILITIES

None yet...

=head2 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Andrew DeFaria (Andrew@ClearSCM.com).

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
