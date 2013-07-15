=pod

=head1 NAME $RCSfile: Views.pm,v $

Object oriented interface to Clearcase Views

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.12 $

=item Created

Dec 29 12:07:59 PST 2005

=item Modified

$Date: 2011/11/16 19:46:13 $

=back

=head1 SYNOPSIS

Provides access to information about Clearcase Views.

 my $views = new Clearcase::Views;

 my $nbr_views	= $views->views;
 my @view_list	= $views->views;

 display "Clearcase Views\n";

 display "Number of views:\t\t"	. $nbr_views;
 display "View list:\n";

 display "\t$_" foreach (@view_list);

=head1 DESCRIPTION

This module implements an object oriented interface to Clearcase
views.

=head1 ROUTINES

The following routines are exported:

=cut

package Clearcase::Views;

use strict;
use warnings;

use Clearcase;

sub new (;$) {
  my ($class, $region) = @_;
    
=pod

=head2 new

Construct a new Clearcase Views object. 

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Clearcase Views object

=back

=for html </blockquote>

=cut

  $region ||= $Clearcase::CC->region;

  my ($status, @output) = 
    $Clearcase::CC->execute ("lsview -short -region $region");

  $class = bless {
    views => \@output,
  }, $class; # bless
   
  return $class;
} # new

sub views () {
  my ($self) = @_;

=pod

=head2 views

Return a list of view tags in an array context or the number of views in
a scalar context.

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item List of views or number of views

Array of view tags in an array context or the number of views in a scalar context.

=back

=for html </blockquote>

=cut

  if (wantarray) {
    return $self->{views} ? sort @{$self->{views}} : ();
  } else {
    return $self->{views} ? scalar @{$self->{views}} : 0;
  } #if
} # views

sub dynamic () {
  my ($self) = @_;

=pod

=head2 dynamic

Return the number of dynamic views

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item number of dynamic views

Returns the number of dynamic views in the region

=back

=for html </blockquote>

=cut

  $self->updateViewInfo if !defined $self->{dynamic};
  return $self->{dynamic};
} # dynamic

sub ucm () {
  my ($self) = @_;

=pod

=head2 ucm

Return the number of ucm views

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item number of ucm views

Returns the number of ucm views in the region

=back

=for html </blockquote>

=cut

  $self->updateViewInfo if !defined $self->{ucm};
  return $self->{ucm};
} # ucm

sub snapshot () {
  my ($self) = @_;

=pod

=head2 snapshot

Return the number of snapshot views

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item number of snapshot views

Returns the number of snapshot views in the region

=back

=for html </blockquote>

=cut

  $self->updateViewInfo if !defined $self->{snapshot};
  return $self->{snapshot};
} # snapshot

sub web () {
  my ($self) = @_;

=pod

=head2 web

Return the number of web views

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item number of web views

Returns the number of web views in the region

=back

=for html </blockquote>

=cut

  $self->updateViewInfo if !defined $self->{web};
  return $self->{web};
} # web

sub updateViewInfo ($) {
  my ($self) = @_;

  my ($dynamic, $web, $ucm, $snapshot) = (0, 0, 0, 0);

  foreach ($self->views) {
    my ($status, @lsview_out) = $Clearcase::CC->execute ("lsview -properties -full $_");

    next
      if $status;

    foreach (@lsview_out) {
      if (/Properties/) {
        $dynamic++
          if /dynamic/;
	    $snapshot++
  	      if /snapshot/ and not /webview/;
	    $ucm++
	      if /ucmview/;
	    $web++
          if /webview/;
	    last;
      } # if
    } # foreach

    $self->{dynamic}  = $dynamic;
    $self->{web}      = $web;
    $self->{ucm}      = $ucm;
    $self->{snapshot} = $snapshot;
  } # foreach
  
  return
} # updateViewInfo

1;

=head1 DEPENDENCIES

=for html <p><a href="/php/cvs_man.php?file=lib/Clearcase.pm">Clearcase</a></p>

=head1 INCOMPATABILITIES

None

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007, ClearSCM, Inc. All rights reserved.

=cut
