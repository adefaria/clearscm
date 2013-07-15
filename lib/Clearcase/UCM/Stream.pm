=pod

=head1 NAME $RCSfile: Stream.pm,v $

Object oriented interface to UCM Streams

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.8 $

=item Created

Fri May 14 18:16:16 PDT 2010

=item Modified

$Date: 2011/11/15 02:00:58 $

=back

=head1 SYNOPSIS

Provides access to information about Clearcase Elements.

  my $stream= new Clearcase::UCM::Stream ($name, $pvob);

=head1 DESCRIPTION

This module implements a UCM Stream object

=head1 ROUTINES

The following routines are exported:

=cut

package Clearcase::UCM::Stream;

use strict;
use warnings;

use Clearcase;
use Clearcase::UCM::Baseline;

sub new ($$) {
  my ($class, $stream, $pvob) = @_;

=pod

=head2 new

Construct a new Clearcase Stream object.

Parameters:

=for html <blockquote>

=over

=item stream name

Name of stream

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Clearcase Stream object

=back

=for html </blockquote>

=cut

  my $self = bless {
    name => $stream,
    pvob => Clearcase::vobtag $pvob,
  }, $class; # bless
    
  return $self; 
} # new
  
sub name () {
  my ($self) = @_;
    
=pod

=head2 name

Returns the name of the stream

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item stream's name

=back

=for html </blockquote>

=cut

  return $self->{name};
} # name

sub pvob () {
  my ($self) = @_;
  
=pod

=head2 pvob

Returns the pvob of the stream

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item stream's pvob

=back

=for html </blockquote>

=cut

  return $self->{pvob};
} # pvob
  
sub create ($$;$$) {
  my ($self, $project, $pvob, $baseline, $opts) = @_;

=pod

=head2 create

Creates a new UCM Stream Object

Parameters:

=for html <blockquote>

=over

=item UCM Project (required)

UCM Project this stream belongs to

=item PVOB (Required)

Project Vob

=item baseline

Baseline to set this stream to

=item opts

Options: Additional options to use (e.g. -readonly)

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item $status

Status from cleartool

=item @output

Ouput from cleartool

=back

=for html </blockquote>

=cut

  # Fill in object members
  $self->{project}  = $project;
  $self->{pvob}     = $pvob;
    
  # Fill in opts   
  $opts ||= '';
  $opts .= " -baseline $baseline"
    if $baseline;  
      
  $self->{readonly} = $opts =~ /-readonly/;
  
  # TODO: This should call the exists function
  # Return the stream name if the stream already exists
  my ($status, @output) = 
    $Clearcase::CC->execute ('lsstream -short ' . $self->{name}); 

  return ($status, @output)
    unless $status;
    
  # Need to create the stream
  return $Clearcase::CC->execute 
    ("mkstream $opts -in " . $self->{project} .
     "\@"                  . $self->{pvob}    .
     ' '                   . $self->{name});
} # create

sub remove () {
  my ($self) = @_;

=pod

=head2 remove

Removes UCM Stream

Parameters:

=for html <blockquote>

=over

=item UCM Project (required)

UCM Project this stream belongs to

=item PVOB (Required)

Project Vob

=item baseline

Baseline to set this stream to

=item opts

Options: Additional options to use (e.g. -readonly)

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item $status

Status from cleartool

=item @output

Ouput from cleartool

=back

=for html </blockquote>

=cut

  return $Clearcase::CC->execute 
    ('rmstream -f ' . $self->{name} . "\@" . $self->{pvob});
} # rmStream

sub baselines () {
  my ($self) = @_;

=pod

=head2 baselines

Returns baseline objects associated with the stream

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item @baselines

An array of baseline objects for this stream

=back

=for html </blockquote>

=cut

  my $cmd = "lsbl -short -stream $self->{name}\@$self->{pvob}";
  
  $Clearcase::CC->execute ($cmd); 

  return if $Clearcase::CC->status;

  my @baselines;
  
  foreach ($Clearcase::CC->output) {
    my $baseline = Clearcase::UCM::Baseline->new ($_, $self->{pvob});
    
    push @baselines, $baseline;
  } # foreach
  
  return @baselines;
} # baselines

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
