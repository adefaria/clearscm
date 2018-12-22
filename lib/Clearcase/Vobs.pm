=pod

=head1 NAME $RCSfile: Vobs.pm,v $

Object oriented interface to Clearcase VOBs

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.17 $

=item Created

Thu Dec 29 12:07:59 PST 2005

=item Modified

$Date: 2011/11/16 19:46:13 $

=back

=head1 SYNOPSIS

Provides access to information about all Clearcase VOBs.

 # Create VOBs object
 my $vobs = new Clearcase::Vobs;

 display "There are " . $vobs->vobs . " vobs to process";

 # Iterrate through the list of vobs
 foreach ($vobs->vobs) {
   my $vob = new Clearcase::Vob $_;
   ...
 } # foreach

 # VOBs manipulation
 display "Umounting all vobs";

 $vobs->umount;

 display "Mounting all vobs";

 $vobs->mount;

=head1 DESCRIPTION

This module implements a Clearcase vobs object to  deal with the lists
of vobs in the current region.

=head1 ROUTINES

The following routines are exported:

=cut

package Clearcase::Vobs;

use strict;
use warnings;

use lib '..';

use Clearcase;
use Display;
use OSDep;

sub new (;$) {
  my ($class, $host, $region) = @_;

=pod

=head2 new (host)

Construct a new Clearcase Vobs object.

Parameters:

=for html <blockquote>

=over

=item host

If host is specified then limit the vob list to only those vobs on that host. If
host is not specified then all vobs are considered

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Clearcase VOBs object

=back

=for html </blockquote>

=cut

  my $cmd  = 'lsvob -short';
     $cmd .= " -host $host"     if $host;
     $cmd .= " -region $region" if $region;

  my ($status, @output) = $Clearcase::CC->execute ($cmd);

  return if $status;

  return bless {
    vobs => \@output
  }, $class; # bless
} # new

sub vobs () {
  my ($self) = @_;

=pod

=head3 vobs

Return a list of VOB tags in an array context or the number of vobs in
a scalar context.

Parameters:

=for html <blockquote>

=over

=over

=item none

=back

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=over

=item List of VOBs or number of VOBs

Array of VOB tags in an array context or the number of vobs in a scalar context.

=back

=back

=for html </blockquote>

=cut

  if (wantarray) {
    my @returnVobs = sort @{$self->{vobs}};
    
    return @returnVobs;
  } else {
    return scalar @{$self->{vobs}};
  } #if
} # vobs

sub mount () {
  my ($self) = @_;

=pod

=head3 mount

Mount all VOBs

Parameters:

=for html <blockquote>

=over

=over

=item none

=back

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=over

=item $status

Status from cleartool

=item @output

Ouput from cleartool

=back

=back

=for html </blockquote>

=cut

  my ($status, @output) = $Clearcase::CC->execute ("mount -all");

  return $status;
} # mount

sub umount () {
  my ($self) = @_;

=pod

=head3 umount

Unmounts all VOBs

Parameters:

=for html <blockquote>

=over

=over

=item none

=back

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=over

=item $status

Status from cleartool

=item @output

Ouput from cleartool

=back

=back

=for html </blockquote>

=cut

  my ($status, @output) = $Clearcase::CC->execute ("umount -all");

  return $status;
} # umount

1;

=pod

=head2 DEPENDENCIES

=head3 ClearSCM Perl Modules

=for html <p><a href="/php/scm_man.php?file=lib/Clearcase.pm">Clearcase</a></p>

=for html <p><a href="/php/scm_man.php?file=lib/Display.pm">Display</a></p>

=for html <p><a href="/php/scm_man.php?file=lib/OSDep.pm">OSdep</a></p>

=head2 BUGS AND LIMITATIONS

There are no known bugs in this module

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head2 LICENSE AND COPYRIGHT

Copyright (c) 2007, ClearSCM, Inc. All rights reserved.

=cut
