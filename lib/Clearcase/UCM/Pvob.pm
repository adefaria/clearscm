=pod

=head1 NAME $RCSfile: Pvob.pm,v $

Object oriented interface to a UCM Pvob

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.1 $

=item Created

Fri May 14 18:16:16 PDT 2010

=item Modified

$Date: 2011/11/09 01:52:39 $

=back

=head1 SYNOPSIS

Provides access to information about a Clearcase Pvob.

  my $pvob = new Clearcase::UCM::Pvob ($name);

=head1 DESCRIPTION

This module implements a UCM Pvob object

=head1 ROUTINES

The following routines are exported:

=cut

package Clearcase::UCM::Pvob;

use strict;
use warnings;

use parent 'Clearcase::Vob';

use Carp;

sub new ($) {
  my ($class, $tag) = @_;
  
=pod

=head2 new

Construct a new Clearcase Pvob object.

Parameters:

=for html <blockquote>

=over

=item name

Name of pvob

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Clearcase Pvob object

=back

=for html </blockquote>

=cut  

  croak 'Clearcase::UCM::Pvob: Must specify pvob tag' unless $tag;

  $class = bless {
    tag        => $tag,
    ucmproject => 1,
  }, $class; # bless
    
  $class->updateVobInfo;

  return $class; 
} # new
  
sub tag() {
  my ($self) = @_;

=pod

=head2 tag

Returns the tag of the pvob

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item tag

=back

=for html </blockquote>

=cut
    
  return $self->{tag};
} # tag

# Alias name to tag
sub name() {
  goto &tag;
} # name

sub streams () {
  my ($self) = @_;
  
=pod

=head2 streams

Returns an array of stream objects in the pvob

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item array of stream objects in the pvob

=back

=for html </blockquote>

=cut  

  my $cmd = "lsstream -short -invob $self->{name}";
  
  $Clearcase::CC->execute ($cmd);
  
  return if $Clearcase::CC->status;
  
  my @streams;

  push @streams, Clearcase::UCM::Stream->new ($_, $self->{name})
    for ($Clearcase::CC->output);

  return @streams;  
} # streams
  
1;

=head1 DEPENDENCIES

=head2 ClearSCM Perl Modules

=for html <p><a href="/php/scm_man.php?file=lib/Clearcase.pm">Clearcase</a></p>

=for html <p><a href="/php/scm_man.php?file=lib/Clearcase/UCM/Baseline.pm">Clearcase::UCM::Baseline</a></p>

=head1 INCOMPATABILITIES

None

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007, ClearSCM, Inc. All rights reserved.

=cut
