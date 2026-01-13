
=pod

=head1 NAME Server.pm

Object oriented interface to a Clearcase Server

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@DeFaria.com>

=item Revision

$Revision: 1.2 $

=item Created

Sat Dec 18 09:51:15 EST 2010

=item Modified

$Date: 2011/01/02 04:59:36 $

=back

=head2 SYNOPSIS

Provides access to information about a Clearcase Server.

=head2 DESCRIPTION

This module implements an object oriented interface to a Clearcase
Server.

=head2 ROUTINES

The following routines are exported:

=cut

package Clearcase::Server;

use strict;
use warnings;

use Clearcase;

=pod

=head2 new (tag)

Construct a new Clearcase View object. Note that not all members are
initially populated because doing so would be time consuming. Such
member variables will be expanded when accessed.

Parameters:

=for html <blockquote>

=over

=item tag

View tag to be instantiated. You can use either an object oriented call
(i.e. my $view = new Clearcase::View (tag => 'my_new_view')) or the
normal call (i.e. my $vob = new Clearcase::View ('my_new_view')). You
can also instantiate a new view by supplying a tag and then later
calling the create method.

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Clearcase View object

=back

=for html </blockquote>

=cut

sub new ($;$) {
  my ($class, $name) = @_;

  my $self = bless {name => $name}, $class;

  $self->updateServerInfo ($name);

  return $self;
}    # new

sub name () {
  my ($self) = @_;

  return $self->{name};
}    # name

sub ccVer () {
  my ($self) = @_;

  return $self->{ccVer};
}    # ccVer

sub osVer () {
  my ($self) = @_;

  return $self->{osVer};
}    # osVer

sub hardware () {
  my ($self) = @_;

  return $self->{hardware};
}    # hardware

sub licenseHost () {
  my ($self) = @_;

  return $self->{licenseHost};
}    # licenseHost

sub registryHost () {
  my ($self) = @_;

  return $self->{registryHost};
}    # registryHost

sub registryRegion () {
  my ($self) = @_;

  return $self->{registryRegion};
}    # registryRegion

sub mvfsBlocksPerDirectory () {
  my ($self) = @_;

  return $self->{mvfsBlocksPerDirectory};
}    # mvfsBlocksPerDirectory

sub mvfsFreeMnodesCleartext() {
  my ($self) = @_;

  return $self->{mvfsFreeMnodesCleartext};
}    # mvfsFreeMnodesCleartext

sub mvfsDirectoryNames () {
  my ($self) = @_;

  return $self->{mvfsDirectoryNames};
}    # mvfsDirectoryNames

sub mvfsFileNames () {
  my ($self) = @_;

  return $self->{mvfsFileNames};
}    # mvfsFileNames

sub mvfsFreeMnodes () {
  my ($self) = @_;

  return $self->{mvfsFreeMnodes};
}    # mvfsFreeMnodes

sub mvfsInitialMnodeTableSize () {
  my ($self) = @_;

  return $self->{mvfsInitialMnodeTableSize};
}    # mvfsInitialMnodeTableSize

sub mvfsMinCleartextMnodes () {
  my ($self) = @_;

  return $self->{mvfsMinCleartextMnodes};
}    # mvfsMinCleartextMnodes

sub mvfsMinFreeMnodes () {
  my ($self) = @_;

  return $self->{mvfsMinFreeMnodes};
}    # mvfsMinFreeMnodes

sub mvfsNamesNotFound () {
  my ($self) = @_;

  return $self->{mvfsNamesNotFound};
}    # mvfsNamesNotFound

sub mvfsRPCHandles () {
  my ($self) = @_;

  return $self->{mvfsRPCHandles};
}    # mvfsRPCHandles

sub interopRegion () {
  my ($self) = @_;

  return $self->{interopRegion};
}    # interopRegion

sub scalingFactor () {
  my ($self) = @_;

  return $self->{scalingFactor};
}    # scalingFactor

sub cleartextIdleLifetime () {
  my ($self) = @_;

  return $self->{cleartextIdleLifetime};
}    # cleartextIdleLifetime

sub vobHashTableSize () {
  my ($self) = @_;

  return $self->{vobHashTableSize};
}    # vobHashTableSize

sub cleartextHashTableSize () {
  my ($self) = @_;

  return $self->{cleartextHashTableSize};
}    # cleartextHashTableSize

sub dncHashTableSize () {
  my ($self) = @_;

  return $self->{dncHashTableSize};
}    # dncHashTableSize

sub threadHashTableSize () {
  my ($self) = @_;

  return $self->{threadHashTableSize};
}    # threadHashTableSize

sub processHashTableSize () {
  my ($self) = @_;

  return $self->{processHashTableSize};
}    # processHashTableSize

sub updateServerInfo($) {
  my ($self, $host) = @_;

  my ($status, @output) =
    $Clearcase::CC->execute ("hostinfo -long -properties -full $host");

  for (@output) {
    if (/Product: ClearCase (.*)/) {
      $self->{ccVer} = $1;
    } elsif (/Operating system: (.*)/) {
      $self->{osVer} = $1;
    } elsif (/Hardware type: (.*)/) {
      $self->{hardware} = $1;
    } elsif (/License host: (.*)/) {
      $self->{licenseHost} = $1;
    } elsif (/Registry host: (.*)/) {
      $self->{registryHost} = $1;
    } elsif (/Registry region: (.*)/) {
      $self->{registryRegion} = $1;
    } elsif (/Blocks per directory: (.*)/) {
      $self->{mvfsBlocksPerDirectory} = $1;
    } elsif (/Free mnodes for cleartext: (.*)/) {
      $self->{mvfsFreeMnodesCleartext} = $1;
    } elsif (/Directory names: (.*)/) {
      $self->{mvfsDirectoryNames} = $1;
    } elsif (/File names: (.*)/) {
      $self->{mvfsFileNames} = $1;
    } elsif (/Free mnodes: (.*)/) {
      $self->{mvfsFreeMnodes} = $1;
    } elsif (/Initial mnode table size: (.*)/) {
      $self->{mvfsInitialMnodeTableSize} = $1;
    } elsif (/Minimum free mnodes for cleartext: (.*)/) {
      $self->{mvfsMinCleartextMnodes} = $1;
    } elsif (/Mimimum free mnodes: (.*)/) {
      $self->{mvfsMinFreeMnodes} = $1;
    } elsif (/Names not found: (.*)/) {
      $self->{mvfsNamesNotFound} = $1;
    } elsif (/RPC handles: (.*)/) {
      $self->{mvfsRPCHandles} = $1;
    } elsif (/Scaling\ factor\ to\ initialize\ MVFS\ cache\ sizes:\ (.*)/x) {
      $self->{scalingFactor} = $1;
    } elsif (/Cleartext idle lifetime: (.*)/) {
      $self->{cleartextIdleLifetime} = $1;
    } elsif (/VOB hash table size: (.*)/) {
      $self->{vobHashTableSize} = $1;
    } elsif (/Cleartext hash table size: (.*)/) {
      $self->{cleartextHashTableSize} = $1;
    } elsif (/Thread hash table size: (.*)/) {
      $self->{threadHashTableSize} = $1;
    } elsif (/DNC hash table size: (.*)/) {
      $self->{dncHashTableSize} = $1;
    } elsif (/Process hash table size: (.*)/) {
      $self->{processHashTableSize} = $1;
    }    # if
  }    # for

  return;
}    # updateServerInfo

1;

=pod

=head2 Modules

=over

=item L<Clearcase|Clearcase>

=back

=head2 INCOMPATABILITIES

None

=head2 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Andrew DeFaria <Andrew@DeFaria.com>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Andrew@DeFaria.com

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.38.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
