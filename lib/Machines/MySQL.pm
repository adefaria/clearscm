=pod

=head1 NAME $RCSfile: MySQL.pm,v $

MySQL Backend for Machines module

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@DeFaria.com>

=item Revision

$Revision: $

=item Created

Mon, Jul 16, 2018 10:13:12 AM

=item Modified

$Date: $

=back

=head1 SYNOPSIS

Interfaces to a MySQL backend for machine information

=head1 DESCRIPTION

The rexec.pl script allows you to execute an arbitrary command on a set of
machines, however what set of machines? Primative exeuction involves just a
flat file with machine information listed in it. This module instead provides
a MySQL backend for this machine data.

=head1 ROUTINES

The following methods are available:

=cut

package Machines::MySQL;

use strict;
use warnings;

use Carp;
use DBI;

use parent qw(Machines);

our $VERSION  = '$Revision: 1.0 $';
   ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);

my %MACHINEOPTS = (
  SERVER   => $ENV{REXEC_DBHOST} || 'localhost',
  USERNAME => 'rexec',
  PASSWORD => 'rexec',
);

# Internal methods
sub _connect (;$) {
  my ($self, $dbserver) = @_;

  $dbserver ||= $MACHINEOPTS{SERVER};

  my $dbname   = 'machines';
  my $dbdriver = 'mysql';

  $self->{db} = DBI->connect (
    "DBI:$dbdriver:$dbname:$dbserver",
    $MACHINEOPTS{USERNAME},
    $MACHINEOPTS{PASSWORD},
    {PrintError => 0},
  ) or croak (
    "Couldn't connect to $dbname database "
  . "as $MACHINEOPTS{USERNAME}\@$MACHINEOPTS{SERVER}"
  );

  $self->{dbserver} = $dbserver;

  return;
} # _connect

sub _checkRequiredFields ($$) {
  my ($fields, $rec) = @_;

  for my $fieldname (@$fields) {
    my $found = 0;

    for (keys %$rec) {
      if ($fieldname eq $_) {
      	 $found = 1;
      	 last;
      } # if
    } # for

    return "$fieldname is required"
      unless $found;
  } # for

  return;
} # _checkRequiredFields

sub _dberror ($$) {
  my ($self, $msg, $statement) = @_;

  my $dberr    = $self->{db}->err;
  my $dberrmsg = $self->{db}->errstr;

  $dberr    ||= 0;
  $dberrmsg ||= 'Success';

  my $message = '';

  if ($dberr) {
    my $function = (caller (1)) [3];

    $message = "$function: $msg\nError #$dberr: $dberrmsg\n"
             . "SQL Statement: $statement";
  } # if

  return $dberr, $message;
} # _dberror

sub _formatValues (@) {
  my ($self, @values) = @_;

  my @returnValues;

  # Quote data values
  push @returnValues, $_ eq '' ? 'null' : $self->{db}->quote ($_)
    for (@values);

  return @returnValues;
} # _formatValues

sub _formatNameValues (%) {
  my ($self, %rec) = @_;

  my @nameValueStrs;

  push @nameValueStrs, "$_=" . $self->{db}->quote ($rec{$_})
    for (keys %rec);

  return @nameValueStrs;
} # _formatNameValues

sub _addRecord ($%) {
  my ($self, $table, %rec) = @_;

  my $statement  = "insert into $table (";
     $statement .= join ',', keys %rec;
     $statement .= ') values (';
     $statement .= join ',', $self->_formatValues (values %rec);
     $statement .= ')';

  my ($err, $msg);

  $self->{db}->do ($statement);

  return $self->_dberror ("Unable to add record to $table", $statement);
} # _addRecord

sub _getRecords ($;$) {
  my ($self, $table, $condition) = @_;

  my ($err, $msg);

  my $statement  = "select * from $table";

  if ($condition) {
    $condition .= ' and ';
  } # if

  $condition .= 'active = "true"';
  $statement .= " where $condition";

  my $sth = $self->{db}->prepare($statement);

  unless ($sth) {
    ($err, $msg) = $self->_dberror('Unable to prepare statement', $statement);

    croak $msg;
  } # if

  my $status = $sth->execute;

  ($err, $msg) = $self->_dberror ('Unable to execute statement', $statement);

  return ($err, $msg) if $err;

  my %records;

  while (my $row = $sth->fetchrow_hashref) {
    # Change undef to ''
    $row->{$_} ||= '' for keys %$row;

    my $name = delete $row->{name};

    $records{$name} = $row;
  } # while

  return %records;
} # _getRecord

sub new (;$) {
  my ($class, $db) = @_;

  my $self = bless {}, $class;

  $self->_connect ($db);

  return $self;
} # new

sub select(;$) {
  my ($self, $condition) = @_;

  return $self->_getRecords('system', $condition);
} # select

sub AddSystem (%) {
  my ($self, %system) = @_;

  my @requiredFields = (
    'name',
    'type',
  );

  my $result = _checkRequiredFields \@requiredFields, \%system;

  return -1, "AddSystem: $result" if $result;

  return $self->_addRecord ('system', %system);
} # AddSystem

1;
