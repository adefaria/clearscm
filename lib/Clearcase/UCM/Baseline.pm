=pod

=head1 NAME $RCSfile: Baseline.pm,v $

Object oriented interface to UCM Streams

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.4 $

=item Created

Fri May 14 18:16:16 PDT 2010

=item Modified

$Date: 2011/11/15 01:59:07 $

=back

=head1 SYNOPSIS

Provides access to information about Clearcase Elements.

  my $stream= new Clearcase::UCM::Stream ($name, $pvob);

=head1 DESCRIPTION

This module implements a UCM Stream object

=head1 ROUTINES

The following routines are exported:

=cut

package Clearcase::UCM::Baseline;

use strict;
use warnings;

use Carp;

use lib '../..';

use Clearcase;
use Clearcase::Element;
use Clearcase::UCM::Activity;

sub _processOpts (%) {
  my ($self, %opts) = @_;

  my $opts;
  
  foreach (keys %opts) {
    if ($_ eq 'cq' or $_ eq 'cqe' or $_ eq 'force' or $_ eq 'nc') {
      $opts .= "-$_ ";
    } elsif ($_ eq 'c' or $_ eq 'cfile') {
      $opts .= "-$_ $opts{$_}";
    } # if
  } # foreach
  
  
  return $opts;
} # _processOpts

sub new ($$) {
  my ($class, $baseline, $pvob) = @_;

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
    name => $baseline,
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

sub remove (\%) {
  my ($self, %opts) = @_;

=pod

=head2 remove

Removes UCM Baseline

Parameters:

=for html <blockquote>

=over

=item none

=item %opts

Options: Additional options to use (e.g. -c, -force, etc.)

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item nothing

Remember to check status method for error, and/or output method for output.

=back

=for html </blockquote>

=cut

  my $opts = $self->_processOpts (%opts);
  
  my $pvob = Clearcase::vobtag ($self->{pvob});
  
  my ($status, @output) = $Clearcase::CC->execute 
    ("rmbl $opts " . $self->{name} . '@' . $pvob);
  
  return;
} # remove

sub attributes () {
  my ($self) = @_;

=pod

=head2 attributes

Returns a hash of the attributes associated with a baseline

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item %attributes

Hash of attributes for this baseline

=back

=for html </blockquote>

=cut

  return $self->Clearcase::attributes (
    'baseline',
    "$self->{name}\@" . Clearcase::vobtag ($self->{pvob})
  );
} # attributes

sub diff ($;$$) {
  my ($self, $type, $baseline, %opts) = @_;
  
=pod

=head2 diff

Returns a hash of information regarding the difference between two baselines or
a baseline and the stream (AKA "top of stream").

Parameters:

=for html <blockquote>

=over

=item [activities|versions|baselines]

Must specify one of [activities|versions|baselines]. Information will be 
returned based on this parameter.

=item $baseline or $stream

Specify the baseline or stream to compare to. If not specified a -predeccsor 
diffbl will be done. If a stream use "stream:<stream>" otherwise use 
"baseline:<baseline>" or simply "<baseline>".

=item %opts

Additional options.

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item %info

Depending on whether activites, versions or baselines were specified, the 
returned hash will be constructed with the key being the activity, version 
string or baseline name as the key with additional information specified as the
value.

=back

=for html </blockquote>

=cut

  unless ($type =~ /^activities$/i or
          $type =~ /^versions$/i   or
          $type =~ /^baselines$/i) {
    croak "Type must be one of activities, versions or baselines in "
        . "Clearcase::UCM::Baseline::diff - not $type";
  } # unless
  
  my $myBaseline = "$self->{name}\@$self->{pvob}";
  
  my $cmd = "diffbl -$type";
  
  if ($baseline) {
    if ($baseline =~ /(\S+):/) {
      unless ($1 eq 'baseline' or $1 eq 'stream') {
        croak "Baseline should be baseline:<baseline> or stream:<stream> or "
            . "just <baseline>";
      } # unless
    } # if
    
    $baseline .= "\@$self->{pvob}" unless $baseline =~ /\@/;
    
    $cmd .= " $myBaseline $baseline";
  } else {
    $cmd .= " -predeccsor";
  } # if
  
  $Clearcase::CC->execute ($cmd);
  
  return if $Clearcase::CC->status;
  
  my @output = $Clearcase::CC->output;

  my %info;
    
  foreach (@output) {
    next unless /^(\>\>|\<\<)/;
    
    if (/(\>\>|\<\<)\s+(\S+)\@/) {
      $info{$2} = Clearcase::UCM::Activity->new ($2, $self->{pvob});
    } # if
  } # foreach
  
  return %info;
} # diff

1;

=head1 DEPENDENCIES

=head2 ClearSCM Perl Modules

=for html <p><a href="/php/cvs_man.php?file=lib/Clearcase.pm">Clearcase</a></p>

=head1 INCOMPATABILITIES

None

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007, ClearSCM, Inc. All rights reserved.

=cut
