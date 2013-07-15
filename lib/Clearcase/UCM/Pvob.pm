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

use Clearcase;
use Clearcase::UCM::Stream;

sub new ($) {
  my ($class, $name) = @_;
  
=pod

=head2 new

Construct a new Clearcase Pvob object.

Parameters:

=for html <blockquote>

=over

=item pvob name

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

  my $self = bless {
    name => $name,
  }, $class; # bless
    
  return $self; 
} # new
  
sub name () {
  my ($self) = @_;

=pod

=head2 name

Returns the name of the pvob

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item pvob's name

=back

=for html </blockquote>

=cut
    
  return $self->{name};
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
    foreach ($Clearcase::CC->output);

  return @streams;  
} # streams
  
1;

=head1 DEPENDENCIES

=head2 ClearSCM Perl Modules

=for html <p><a href="/php/cvs_man.php?file=lib/Clearcase.pm">Clearcase</a></p>

=for html <p><a href="/php/cvs_man.php?file=lib/Clearcase/UCM/Baseline.pm">Clearcase::UCM::Baseline</a></p>

=head1 INCOMPATABILITIES

None

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007, ClearSCM, Inc. All rights reserved.

=cut
