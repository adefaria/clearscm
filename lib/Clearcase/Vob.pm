=pod

=head1 NAME $RCSfile: Vob.pm,v $

Object oriented interface to a Clearcase VOB

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.15 $

=item Created

Thu Dec 29 12:07:59 PST 2005

=item Modified

$Date: 2011/11/16 19:46:13 $

=back

=head1 SYNOPSIS

Provides access to information about a Clearcase VOB. Note that information
about the number of elements, branches, etc. that is provided by countdb are not
initially instantiated with the VOB object, rather those member variables are
expanded if and when accessed. This helps the VOB object to be more efficient.

 # Create VOB object
 my $vob = new Clearcase::Vob (tag => "/vobs/test");

 # Access member variables...
 display "Tag:\t\t"		. $vob->tag;
 display "Global path:\t"	. $vob->gpath;
 display "Sever host:\t"	. $vob->shost;
 display "Access:\t\t"		. $vob->access;
 display "Mount options:\t"	. $vob->mopts;
 display "Region:\t\t"		. $vob->region;
 display "Active:\t\t"		. $vob->active;
 display "Replica UUID:\t"	. $vob->replica_uuid;
 display "Host:\t\t"		. $vob->host;
 display "Access path:\t"	. $vob->access_path;
 display "Family UUID:\t"	. $vob->family_uuid;

 # This members are not initially expanded until accessed
 display "Elements:\t"		. $vob->elements;
 display "Branches:\t"		. $vob->branches;
 display "Versions:\t"		. $vob->versions;
 display "DB Size:\t"		. $vob->dbsize;
 display "Adm Size:\t"		. $vob->admsize;
 display "CT Size:\t"		. $vob->ctsize;
 display "DO Size:\t"		. $vob->dbsize;
 display "Src Size:\t"		. $vob->srcsize;
 display "Size:\t\t"		. $vob->size;

 # VOB manipulation
 display "Umounting " . $vob->tag . "...";

 $vob->umount;

 display "Mounting " . $vob->tag . "...";

 $vob->mount;

=head2 DESCRIPTION

This module, and others below the Clearcase directory, implement an object
oriented approach to Clearcase. In general Clearcase entities are made into
objects that can be manipulated easily in Perl. This module is the main or
global module. Contained herein are members and methods of a general or global
nature. Also contained here is an IPC interface to cleartool such that cleartool
runs in the background andcommands are fed to it via the exec method. When
making repeated calls to cleartool this can result in a substantial savings of
time as most operating systems' fork/exec sequence is time consuming. Factors of
8 fold improvement have been measured.

Additionally a global variable, $cc, is implemented from this module such that
you should not need to instantiate another one, though you could.

=head2 ROUTINES

The following routines are exported:

=cut

package Clearcase::Vob;

use strict;
use warnings;

use Clearcase;
use OSDep;

sub new ($) {
  my ($class, $tag) = @_;

=pod

=head2 new (tag)

Construct a new Clearcase VOB object. Note that not all members are
initially populated because doing so would be time consuming. Such
member variables will be expanded when accessed.

Parameters:

=for html <blockquote>

=over

=item tag

VOB tag to be instantiated. You can use either an object oriented call
(i.e. my $vob = new Clearcase::Vob (tag => "/vobs/test")) or the
normal call (i.e. my $vob = new Clearcase::Vob ("/vobs/test")). You
can also instantiate a new vob by supplying a tag and then later
calling the create method.

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Clearcase VOB object

=back

=for html </blockquote>

=cut

  $class = bless {
    tag => $tag
  }, $class;

  $class->updateVobInfo;

  return $class;
} # new

sub tag () {
  my ($self) = @_;
   
=pod

=head2 tag

Returns the VOB's tag

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item VOB's tag

=back

=for html </blockquote>

=cut

  return $self->{tag};
} # tag

sub gpath () {
  my ($self) = @_;
  
=pod

=head2 gpath

Returns the VOB's global path

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item VOB's gpath

=back

=for html </blockquote>

=cut

  return $self->{gpath};
} # gpath

sub shost () {
  my ($self) = @_;
  
=pod

=head2 shost

Returns the VOB's server host

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item VOB's server host

=back

=for html </blockquote>

=cut

  return $self->{shost};
} # shost

sub access () {
  my ($self) = @_;
  
=pod

=head2 access

Returns the type of VOB access

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item access

Returns either public for public VOBs or private for private VOBs

=back

=for html </blockquote>

=cut

  return $self->{access};
} # access

sub mopts () {
  my ($self) = @_;
  
=pod

=head2 mopts

Returns the mount options

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item VOB's mount options

=back

=for html </blockquote>

=cut

  return $self->{mopts};
} # mopts

sub region () {
  my ($self) = @_;
  
=pod

=head3 region

Returns the region for this VOB tag

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item region

=back

=for html </blockquote>

=cut

  return $self->{region};
} # region

sub active () {
  my ($self) = @_;
  
=pod

=head2 active

Returns that active status (whether or not the vob is currently mounted) of the
VOB

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Returns YES for an active VOB or NO for an inactive one

=back

=for html </blockquote>

=cut

  return $self->{active};
} # active

sub replica_uuid () {
  my ($self) = @_;
  
=pod

=head2 replica_uuid

Returns the VOBS replica_uuid

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item VOB replica_uuid

=back

=for html </blockquote>

=cut

  return $self->{replica_uuid};
} # replica_uuid

sub host () {
  my ($self) = @_;
  
=pod

=head2 host

Returns the VOB's host

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item VOB's host

=back

=for html </blockquote>

=cut

  return $self->{host};
} # host

sub access_path () {
  my ($self) = @_;
  
=pod

=head2 access_path

Returns the VOB's access path

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item VOB access path

This is the path relative to the VOB's host

=back

=for html </blockquote>

=cut

  return $self->{access_path};
} # access_path

sub family_uuid () {
  my ($self) = @_;
  
=pod

=head2 family_uuid

Returns the VOB family UUID

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item VOB family UUID

=back

=for html </blockquote>

=cut

  return $self->{family_uuid};
} # family_uuid

sub vob_registry_attributes () {
  my ($self) = @_;
  
=pod

=head2 vob_registry_attributes

Returns the VOB Registry Attributes

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item VOB Registry Attributes

=back

=for html </blockquote>

=cut

  return $self->{vob_registry_attributes};
} # vob_registry_attributes

sub expand_space () {
  my ($self) = @_;

  my ($status, @output) = $Clearcase::CC->execute ("space -vob $self->{tag}");

  # Initialize fields in case of command failure
  $self->{dbsize}  = 0;
  $self->{admsize} = 0;
  $self->{ctsize}  = 0;
  $self->{dosize}  = 0;
  $self->{srcsize} = 0;
  $self->{size}    = 0;

  foreach (@output) {
    if (/(\d*\.\d).*VOB database(.*)/) {
      $self->{dbsize} = $1;
    } elsif (/(\d*\.\d).*administration data(.*)/) {
      $self->{admsize} = $1;
    } elsif (/(\d*\.\d).*cleartext pool(.*)/) {
      $self->{ctsize} = $1;
    } elsif (/(\d*\.\d).*derived object pool(.*)/) {
      $self->{dosize} = $1;
    } elsif (/(\d*\.\d).*source pool(.*)/) {
      $self->{srcsize} = $1;
    } elsif (/(\d*\.\d).*Subtotal(.*)/) {
      $self->{size} = $1;
    } # if
  } # foreach
  
  return;
} # expand_space

sub countdb () {
  my ($self) = @_;

  # Set values to zero in case we cannot get the right values from countdb
  $self->{elements} = 0;
  $self->{branches} = 0;
  $self->{versions} = 0;

  # Countdb needs to be done in the vob's db directory
  my $cwd = `pwd`;
  
  chomp $cwd;
  chdir "$self->{gpath}/db";

   my $cmd    = "$Clearcase::COUNTDB vob_db 2>&1";
   my @output = `$cmd`;

   if ($? != 0) {
     chdir $cwd;
     return;
    }    # if

  chomp @output;

  # Parse output
  foreach (@output) {
    if (/^ELEMENT\s*:\s*(\d*)/) {
      $self->{elements} = $1;
    } elsif (/^BRANCH\s*:\s*(\d*)/) {
      $self->{branches} = $1;
    } elsif (/^VERSION\s*:\s*(\d*)/) {
      $self->{versions} = $1;
    } # if
  } # foreach

  chdir $cwd;
  
  return;
} # countdb

sub elements () {
  my ($self) = @_;

=pod

=head2 elements

Returns the number of elements in the VOB (obtained via countdb)

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item number of elements

=back

=for html </blockquote>

=cut

  $self->countdb if !$self->{elements};
  
  return $self->{elements};
} # elements

sub branches () {
  my ($self) = @_;

=pod

=head3 branches

Returns the number of branch types in the vob

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item number of branch types

=back

=for html </blockquote>

=cut

  $self->countdb if !$self->{branches};
  
  return $self->{branches};
} # branches

sub versions () {
  my ($self) = @_;

=pod

=head2 versions

Returns the number of element versions in the VOB

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item number of element versions

=back

=for html </blockquote>

=cut

  $self->countdb if !$self->{versions};
  
  return $self->{versions};
} # versions

sub dbsize () {
  my ($self) = @_;

=pod

=head3 dbsize

Returns the size of the VOB's database

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item database size

=back

=for html </blockquote>

=cut

  $self->expand_space if !$self->{dbsize};
  
  return $self->{dbsize};
} # dbsize

sub admsize () {
  my ($self) = @_;

=pod

=head2 admsize

Returns the size of administrative data in the VOB

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item adminstrative size

=back

=for html </blockquote>

=cut

  $self->expand_space if !$self->{admsize};
  
  return $self->{admsize};
} # admsize

sub ctsize () {
  my ($self) = @_;

=pod

=head3 ctsize

Returns the size of the cleartext pool

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item cleartext pool size

=back

=for html </blockquote>

=cut

  $self->expand_space if !$self->{ctsize};
  
  return $self->{ctsize};
} # ctsize

sub dosize () {
  my ($self) = @_;

=pod

=head2 dosize

Returns the size of the derived object pool

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item derived object pool size

=back

=for html </blockquote>

=cut

  $self->expand_space if !$self->{dosize};
  
  return $self->{dosize};
} # dosize

sub srcsize () {
  my ($self) = @_;

=pod

=head2 srcsize

Returns the size of the source pool

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item source pool size

=back

=for html </blockquote>

=cut

  $self->expand_space if !$self->{srcsize};
   
  return $self->{srcsize};
} # srcsize

sub size () {
  my ($self) = @_;

=pod

=head2 size

Returns the size of the VOB

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item size

=back

=for html </blockquote>

=cut

  $self->expand_space if !$self->{size};
  
  return $self->{size};
} # size

sub mount () {
  my ($self) = @_;

=pod

=head2 mount

Mount the current VOB

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item $status

Status of the mount command

=item @output

An array of lines output from the cleartool mount command

=back

=for html </blockquote>

=cut

  return 0 if $self->{active} && $self->{active} eq "YES";

  my ($status, @output) = $Clearcase::CC->execute ("mount $self->{tag}");

  return ($status, @output);
} # mount

sub umount () {
  my ($self) = @_;

=pod

=head3 umount

Unmounts the current VOB

Parameters:

=for html <blockquote>

=over

=item none

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

  my ($status, @output) = $Clearcase::CC->execute ("umount $self->{tag}");

  return ($status, @output);
} # umount

sub exists () {
  my ($self) = @_;

=pod

=head2 exists

Returns true or false if the VOB exists

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

  my ($status, @output) = $Clearcase::CC->execute ("lsvob $self->{tag}");

  return !$status;
} # exists

sub create (;$$$) {
  my ($self, $host, $vbs, $comment) = @_;

=pod

=head2 create

Creates a VOB. First instantiate a VOB object with a tag. Then call create. A 
small subset of parameters is supported for create.

Parameters:

=for html <blockquote>

=over

=item $host (optional)

Host to create the vob on. Default is the current host.

=item $vbs (optional)

VOB storage area. This is a global pathname to the VOB storage
area. Default will attempt to use -stgloc -auto.

=item $comment (optional)

Comment for this VOB's creation. Default is -nc

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

  $comment = Clearcase::setComment $comment;

  my ($status, @output);

  if ($host && $vbs) {
    ($status, @output) = $Clearcase::CC->execute (
      "mkvob -tag $self->{tag} $comment -host $host -hpath $vbs "
    . "-gpath $vbs $vbs");
  } else {
    # Note this requires that -stgloc's work and that using -auto is not a 
    # problem.
    ($status, @output) =
      $Clearcase::CC->execute ("mkvob -tag $self->{tag} $comment "
    . "-stgloc -auto");
  } # if

  $self->updateVobInfo;

  return ($status, @output);
} # create

sub remove () {
  my ($self) = @_;

=pod

=head2 remove

Removed this VOB

Parameters:

=for html <blockquote>

=over

=item none

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

  return $Clearcase::CC->execute ("rmvob -force $self->{gpath}");
} # remove

sub updateVobInfo ($$) {
  my ($self) = @_;

  my ($status, @output) = $Clearcase::CC->execute ("lsvob -long $self->{tag}");

  # Assuming this vob is an empty shell of an object that the user may possibly
  # use the create method on, return our blessings...
  return if $status != 0;

  foreach (@output) {
    if (/Global path: (.*)/) {
      $self->{gpath} = $1;
    } elsif (/Server host: (.*)/) {
      $self->{shost} = $1;
    } elsif (/Access: (.*)/) {
      $self->{access} = $1;
    } elsif (/Mount options: (.*)/) {
      $self->{mopts} = $1;
    } elsif (/Region: (.*)/) {
      $self->{region} = $1;
    } elsif (/Active: (.*)/) {
      $self->{active} = $1;
    } elsif (/Vob tag replica uuid: (.*)/) {
      $self->{replica_uuid} = $1;
    } elsif (/Vob on host: (.*)/) {
      $self->{host} = $1;
    } elsif (/Vob server access path: (.*)/) {
      $self->{access_path} = $1;
    } elsif (/Vob family uuid:  (.*)/) {
      $self->{family_uuid} = $1;
    } elsif (/Vob registry attributes: (.*)/) {
      $self->{vob_registry_attributes} = $1;
    } # if
 } # foreach
 
 return;
} # getVobInfo

1;

=pod

=head2 DEPENDENCIES

=head3 ClearSCM Perl Modules

=for html <p><a href="/php/scm_man.php?file=lib/Clearcase.pm">Clearcase</a></p>

=for html <p><a href="/php/scm_man.php?file=lib/OSDep.pm">OSdep</a></p>

=head2 BUGS AND LIMITATIONS

There are no known bugs in this module

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head2 LICENSE AND COPYRIGHT

Copyright (c) 2007, ClearSCM, Inc. All rights reserved.

=cut
