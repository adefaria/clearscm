=pod

=head1 NAME $RCSfile: Project.pm,v $

Object oriented interface to UCM Projects

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

Provides access to information about Clearcase UCM Projects.

  my $project = new Clearcase::UCM::Project ($name, $folder, $pvob);

=head1 DESCRIPTION

This module implements a UCM Project object

=head1 ROUTINES

The following routines are exported:

=cut

package Clearcase::UCM::Project;

use strict;
use warnings;

sub new ($$) {
  my ($class, $name, $folder, $pvob) = @_;

=pod

=head2 new

Construct a new Clearcase Project object.

Parameters:

=for html <blockquote>

=over

=item project

Name of project

=item folder

Folder object

=item pvob

Associated Pvob

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Clearcase Project object

=back

=for html </blockquote>

=cut

  $folder = Clearcase::UCM::Folder->new('RootFolder', $pvob) unless $folder;

  $class = bless {
    name   => $name,
    folder => $folder,
    pvob   => $pvob,
  }, $class; # bless
    
  return $class; 
} # new
  
sub name () {
  my ($self) = @_;
    
=pod

=head2 name

Returns the name of the project

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item project's name

=back

=for html </blockquote>

=cut

  return $self->{name};
} # name

sub pvob () {
  my ($self) = @_;
  
=pod

=head2 pvob

Returns the pvob of the project

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item project's pvob

=back

=for html </blockquote>

=cut

  return $self->{pvob};
} # pvob
  
sub create (;$) {
  my ($self, $opts) = @_;

=pod

=head2 create

Creates a new UCM Project Object

Parameters:

=for html <blockquote>

=over

=item opts

Optional parameters for cleartool mkproject command

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

  return (0, ()) if $self->exists;

  $opts ||= '';

  return $Clearcase::CC->execute(
    "mkproject $opts -in " . $self->{folder}->name . '@' . $self->{pvob}->tag .
    ' '                    . $self->{name}         . '@' . $self->{pvob}->tag
  );
} # create

sub remove () {
  my ($self) = @_;

=pod

=head2 remove

Removes UCM Project

Parameters:

=for html <blockquote>

=over

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
    ('rmproject -f ' . $self->{name} . "\@" . $self->{pvob}->name);
} # rmProject

sub exists() {
  my ($self) = @_;

=pod

=head3 exists

Returns true if the project exists - false otherwise

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item boolean

=back 

=for html </blockquote>

=cut

  my ($status, @output) = $Clearcase::CC->execute(
    'lsproject ' . $self->{name} . '@' . $self->{pvob}->name
  );

  return !$status;
} # exists

1;

=head1 DEPENDENCIES

=head2 ClearSCM Perl Modules

=for html <p><a href="/php/scm_man.php?file=lib/Clearcase.pm">Clearcase</a></p>

=for html <p><a href="/php/scm_man.php?file=lib/Clearcase/UCM/Folder.pm">Clearcase::UCM::Folder</a></p>

=head1 INCOMPATABILITIES

None

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007, ClearSCM, Inc. All rights reserved.

=cut
