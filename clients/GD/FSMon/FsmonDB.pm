=pod

=head2 NAME $RCSfile: FsmonDB.pm,v $

Object oriented interface to filesystems

=head2 VERSION

=over

=item Author:

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision:

$Revision: $

=item Created:

Thu Dec 11 10:39:12 MST 2008

=item Modified:

$Date:$

=back

=head2 SYNOPSIS

=head1 SYNOPSIS

  use FsmonDB;

  my $username = "fsmonadm";
  my $password = "<password>";

  my $fsmondb = new FsmonDB ($username, $password);

  my ($errno, $errmsg) = $fsmondb->addSystem (
    name		=> hostname,
    owner		=> "root",
    description		=> "Database server",
    ostype		=> "Unix",
    osversion		=> `uname -a`,
    monitorAllFS	=> 1,
  );

  $status = $fsmondb->fsSnapshot (hostname);

=head2 DESCRIPTION

Filesystem creates a filesystem object that encapsulates information
about the file system as a whole.

=head2 ROUTINES

The following routines are exported:

=over

=cut

use strict;
use warnings;

package FsmonDB;

use Carp;
use DBI;

use DateUtils;
use Display;
use Filesystem;

############################################################################
#
# insert:	Construct SQL insert statement based on passed in table
#		name and hash values.
#
# Parms:
#   table	Table name
#   record	Name value hash
#
# Returns:
#   status	($errno, $errmsg)
#
############################################################################
sub insert ($%) {
  my ($self, $table, %values) = @_;

  my $first = 1;
  my $fields;
  my $values;

  foreach (keys %values) {
    if ($first) {
      $first = 0;
    } else {
      $fields .= ",";
      $values .= ",";
    } # if

    if (!defined $_) {
      $values .= "NULL";
    } else {
      $fields .= $_;
      $values .= "\"" . quotemeta ($values{$_}) . "\"";
    } # if
  } # foreach

  my $statement = "insert into $table ($fields) values ($values)";

  $self->{db}->do ($statement)
    or return $self->_dberror ("Unable to add system", $statement);

  return (0, undef);
} # insert

############################################################################
#
# _dberror: Output the DB error message and exit (Internal)
#
# Parms:
#   msg		User defined message to output
#   statement	SQL Statement attempted (optional)
#
# Returns:
#   Nothing
#
############################################################################
sub _dberror ($;$) {
  my ($self, $msg, $statement) = @_;

  my $caller = (caller (1))[3];

  my $returnMsg = "$caller: DBError: "	
                . $msg
		. "\nError #"
		. $self->{db}->err
		. " "
		. $self->{db}->errstr;

  $returnMsg .= "\nSQL Statement: $statement\n" if $statement;

  return ($self->{db}->err, $returnMsg);
} # _dberror

############################################################################
#
# _exists: Return 1 if the value exists in the table otherwise 0
#
# Parms:
#   table	Name of table to search
#   column	Column name to search
#   value	Value to look for
#   column2	Secondary column to search for
#   value2	Secondary value to search for
#
# Returns:
#   1 if found, 0 if not
#
############################################################################
sub _exists ($$$;$$) {
  my ($self, $table, $column, $value, $column2, $value2) = @_;

  my $statement = "select count(*) from $table where $column = \""
                . quotemeta ($value)
                . "\"";

  $statement .= " and $column2 = \""
             .  quotemeta ($value2)
             . "\"" if $column2;

  my $sth;

  unless ($sth = $self->{db}->prepare ($statement)) {
    my ($errNo, $errMsg) = $self->_dberror ("Unable to prepare statement", $statement);
    display $errMsg;
    return 0;
  } # unless

  unless ($sth->execute) {
    my ($errNo, $errMsg) = $self->_dberror ("Unable to execute statement", $statement);
    display $errMsg;
    return 0;
  } # unless

  my @row = $sth->fetchrow_array;

  $sth->finish;

  if ($row[0]) {
    return $row[0]
  } else {
    return 0;
  } # if
} # _exists

############################################################################
#
# _count:	Returns the number of entries in a table that qualify for
#		the given condition.
#
# Parms:
#   table	Name of table to search
#   id		condition (Default: All entries in the table)
#
# Returns:
#   Count of qualifying entries
#
############################################################################
sub _count ($;$) {
  my ($self, $table, $condition) = @_;

  $condition = $condition ? "where $condition" : "";

  my $statement = "select count(*) from $table $condition";

  my $sth;

  unless ($sth = $self->{db}->prepare ($statement)) {
    my ($errNo, $errMsg) = $self->_dberror ("Unable to prepare statement", $statement);
    display $errMsg;
    return -1;
  } # unless

  unless ($sth->execute) {
    my ($errNo, $errMsg) = $self->_dberror ("Unable to execute statement", $statement);
    display $errMsg;
    return -1;
  } # unless

  my @row = $sth->fetchrow_array;

  $sth->finish;

  if ($row[0]) {
    return $row[0]
  } else {
    return 0;
  } # if
} # _count

=pod

=head3 new ()

Construct a new FsmonDB object. The following OO style arguments are
supported:

Parameters:

=for html <blockquote>

=over

=item none

Returns:

=for html <blockquote>

=over

=item FsmonDB object

=back

=for html </blockquote>

=cut

sub new (;$$) {
  my ($class, $username, $password) = @_;

  $username = $username ? $username : "fsmon";
  $password = $password ? $password : "fsmon";

  my $dbname	= $ENV{FSMON_DBNAME}
    		? $ENV{FSMON_DBNAME}		
                : "fsmon";
  my $dbserver	= $ENV{FSMON_DBSERVER}
    		? $ENV{FSMON_DBSERVER}
		: "seast1";
  my $dbdriver	= "mysql";

  my $db = DBI->connect ("DBI:$dbdriver:$dbname:$dbserver", $username,
			 $password, {PrintError => 0})
    or croak "Unable to connect to $dbname database as $username";

  return bless {
    db		=> $db,
    username	=> $username,
    password	=> $password,
  }, $class;
} # new

=pod

=head3 addSystem (%system)

Add a system record

Parameters:

=for html <blockquote>

=over

%system is a hash containing the following keys:

=item $name (required)

Name of the system

=item $owner (optional)

Person or persons responsible for this system

=item $description (optional)

Description of this system

=item $ostype (required)

An enumeration of "Linux", "Unix" or "Windows" (default Linux)

=item $osversion (optional)

String representing an OS version

Returns:

=for html <blockquote>

=over

=item FsmonDB object

=back

=for html </blockquote>

=cut

sub addSystem (%) {
  my ($self, %record) = @_;

  return $self->insert ("system", %record);
} # addSystem

=pod

=head3 getSystem ($system)

Get a system record

Parameters:

=for html <blockquote>

=over

=item $system (option)

Name of the system to return information about. If not specified then
getSystem returns all systems

Returns:

=for html <blockquote>

=over

=item If $system was specified, a hash of that system's
information. If $system is not specified then an array of hashes
containing information on all systems.

=back

=for html </blockquote>

=cut

sub getSystem (;$) {
  my ($self, $system) = @_;

  my ($statement, $sth);

  if ($system) {
    $statement = "select * from system where name = \"$system\"";
  } else {
    $statement = "select name from system";
  } # unless

  unless ($sth = $self->{db}->prepare ($statement)) {
    my ($errno, $errmsg) = $self->_dberror ("Unable to prepare statement", $statement);
    error $errmsg, $errno;
  } # unless

  unless ($sth->execute) {
    my ($errno, $errmsg) = $self->_dberror ("Unable to execute statement", $statement);
    error $errmsg, $errno;
  } # unless

  if ($system) {
    return %{my $row = $sth->fetchrow_hashref};
  } else {
    my @records;

    while (my @record = $sth->fetchrow_array) {
      push @records, pop @record;
    } # while

    return @records;
  } # if
} # addSystem

=pod

=head3 addFilesystem ($system, $mount)

Add monitoring of a filesytem identified by $mount from a $system

Parameters:

=for html <blockquote>

=over

=item $system (required)

Name of the system that this filesystem is local to

=item mount (optional)

Mount point for this file system. If undef then add all local file systems.

Returns:

=for html <blockquote>

=over

=item ($errno, $errmsg)

=back

=for html </blockquote>

=cut

sub addFilesystem ($;$) {
  my ($self, $system, $mount) = @_;

  my $fs = new Filesystem;

  foreach ($fs->mounts ()) {
    my %fsinfo = $fs->getFSInfo ($_);
    my %filesystem = (
      "sysname"		=> $system,
      "mount"		=> $_,
      "fs"		=> $fsinfo{fs},
    );
    my ($errno, $errmsg);

    if ($mount) {
      if ($mount eq $_) {
	($errno, $errmsg) = $self->insert ("filesystems", %filesystem);

	return ($errno, $errmsg) if $errno != 0;
      } # if
    } else {
	($errno, $errmsg) = $self->insert ("filesystems", %filesystem);

	return ($errno, $errmsg) if $errno != 0;
      } # if
  } # foreach

  return (0, undef);
} # addFilesystem

=pod

=head3 addSnapshot (%snapshot)

Add a snapshot record of a filesystem

Parameters:

=for html <blockquote>

=over

%snapshot is a hash containing the following keys:

=item sysname (required)

Name of the system that this filesystem is local to

=item mount (required)

Mount point for this file system

=item timestamp (required)

Timestamp representing the time that the snapshot of the filesystem
was taken.

=item size (optional)

Total size of the filesystem in bytes

=item used (optional)

Number of bytes of used space

=item free (optional)

Number of bytes free or available for use

=item reserve (optional)

Number of bytes held in reserve

Returns:

=for html <blockquote>

=over

=item ($errno, $errmsg)

=back

=for html </blockquote>

=cut

sub addSnapshot (%) {
  my ($self, %snapshot) = @_;

  return $self->insert ("fs", %snapshot);
} # addSnapshot

=pod

=head3 snapshot ($system)

Take a snapshot of all configured file systems for a given system

Parameters:

=for html <blockquote>

=over

=item $system

Name of the system to snapshot

Returns:

=for html <blockquote>

=over

=item ($errno, $errmsg)

=back

=for html </blockquote>

=cut

sub snapshot ($;$) {
  my ($self, $system) = @_;

  my %system	= $self->getSystem ($system);
  my $fs	= new Filesystem (
    $system,
    $system{ostype},
    $system{username},
    $system{password},
    qr "$system{prompt}",
    $system{shellstyle},
  );

  if ($fs) {
    foreach ($fs->mounts ()) {
      my %fsinfo = $fs->getFSInfo ($_);
      my %fs;

      # Format record
      $fs{sysname}	= $system;
      $fs{mount}	= $_;
      $fs{timestamp}	= Today2SQLDatetime;
      $fs{size}		= $fsinfo{size};
      $fs{used}		= $fsinfo{used};
      $fs{free}		= $fsinfo{free};
      $fs{reserve}	= $fsinfo{reserve};

      my ($errno, $errmsg) = $self->addSnapshot (%fs);

      return ($errno, $errmsg) if $errno != 0;
    } # foreach
  } # if

  return (0, "");
} # snapshot

1;

=head1 NAME

FsmonDB - Access routines to the fsmon SQL database

=head1 VERSION

Version 1.0

=head1 DESCRIPTION

This module provides for access routines to the fsmon SQL database.

=head1 METHODS

=head2 new ($username, $password)

Opens the fsmon SQL database for the specified $username and
$password and returns a FsmonDB object

Parameters:

=over

=item username:

Username to connect to the database. At this time "fsmonadm" is the R/W
user and "fsmon" (password "reader") has R/O access (Default:
fsmon).

=item password:

Password to use. (Default: "fsmon").

=item Returns FsmonDB object

=back

=head2 addSystem (%testrun)

Adds the system record. Pass in a hash of field name/value pairs.

=over

=item ($errno, $errmsg)

=back

=back

=head2 CONFIGURATION AND ENVIRONMENT

None

=head2 DEPENDENCIES

  ...

=head2 INCOMPATABILITIES

None yet...

=head2 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Andrew DeFaria (Andrew@ClearSCM.com).

=head2 LICENSE AND COPYRIGHT

This Perl Module is freely available; you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation; either version 2 of the
License, or (at your option) any later version.

This Perl Module is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License (L<http://www.gnu.org/copyleft/gpl.html>) for more
details.

You should have received a copy of the GNU General Public License
along with this Perl Module; if not, write to the Free Software Foundation,
Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
reserved.

=cut
