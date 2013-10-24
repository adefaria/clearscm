=pod

=head1 NAME $RCSfile: Server.pm,v $

Object oriented interface to a Clearcase Server

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

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

  my $self = bless { name => $name }, $class;

  return $self;
} # new
  
sub name () {
  my ($self) = @_;

  return $self->{name};
} # name

sub ccVer () {
  my ($self) = @_;

  return $self->{ccVer};
} # ccVer

sub osVer () {
  my ($self) = @_;

  return $self->{osVer};
} # osVer

sub hardware () {
  my ($self) = @_;

  return $self->{hardware};
} # hardware

sub licenseHost () {
  my ($self) = @_;

  return $self->{licenseHost};
} # licenseHost

sub registryHost () {
  my ($self) = @_;

  return $self->{registryHost};
} # registryHost

sub registryRegion () {
  my ($self) = @_;

  return $self->{registryRegion};
} # registryRegion

sub mvfsBlocksPerDirectory () {
  my ($self) = @_;

  return $self->{mvfsBlocksPerDirectory};
} # mvfsBlocksPerDirectory

sub mvfsCleartextMnodes () {
  my ($self) = @_;
 
  return $self->{mvfsCleartextMnodes};
} # mvfsCleartextMnodes

sub mvfsDirectoryNames () {
  my ($self) = @_;

  return $self->{mvfsDirectoryNames};
} # mvfsDirectoryNames

sub mvfsFileNames () {
  my ($self) = @_;

  return $self->{mvfsFileNames};
} # mvfsFileNames

sub mvfsFreeMnodes () {
  my ($self) = @_;

  return $self->{mvfsFreeMnodes};
} # mvfsFreeMnodes

sub mvfsInitialMnodeTableSize () {
  my ($self) = @_;

  return $self->{mvfsInitialMnodeTableSize};
} # mvfsInitialMnodeTableSize

sub mvfsMinCleartextMnodes () {
  my ($self) = @_;

  return $self->{mvfsMinCleartextMnodes};
} # mvfsMinCleartextMnodes

sub mvfsMinFreeMnodes () {
  my ($self) = @_;

  return $self->{mvfsMinFreeMnodes};
} # mvfsMinFreeMnodes

sub mvfsNamesNotFound () {
  my ($self) = @_;

  return $self->{mvfsNamesNotFound};
} # mvfsNamesNotFound

sub mvfsRPCHandles () {
  my ($self) = @_;

  return $self->{mvfsRPCHandles};
} # mvfsRPCHandles

sub interopRegion () {
  my ($self) = @_;

  return $self->{interopRegion};
} # interopRegion

sub scalingFactor () {
  my ($self) = @_;

  return $self->{scalingFactor};
} # scalingFactor

sub cleartextIdleLifetime () {
  my ($self) = @_;

  return $self->{cleartextIdleLifetime};
} # cleartextIdleLifetime

sub vobHashTableSize () {
  my ($self) = @_;

  return $self->{vobHashTableSize};
} # vobHashTableSize

sub cleartextHashTableSize () {
  my ($self) = @_;

  return $self->{cleartextHashTableSize};
} # cleartextHashTableSize

sub dncHashTableSize () {
  my ($self) = @_;

  return $self->{dncHashTableSize};
} # dncHashTableSize

sub threadHashTableSize () {
  my ($self) = @_;

  return $self->{threadHashTableSize};
} # threadHashTableSize

sub processHashTableSize () {
  my ($self) = @_;

  return $self->{processHashTableSize};
} # processHashTableSize

1;

=pod

=head2 DEPENDENCIES

=for html <p><a href="/php/scm_man.php?file=lib/Clearcase.pm">Clearcase</a></p>

=head2 INCOMPATABILITIES

None

=head2 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head2 LICENSE AND COPYRIGHT

Copyright (c) 2007, ClearSCM, Inc. All rights reserved.

=cut
