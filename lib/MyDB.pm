
=pod

=head1 NAME $RCSfile: MyDB.pm,v $

Object oriented, quick and easy interface to MySQL/MariaDB databases

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@DeFaria.com>

=item Revision

$Revision: 1.0 $

=item Created

Sat 19 Jun 2021 11:05:00 PDT

=item Modified

$Date: $

=back

=head1 SYNOPSIS

Provides lower level, basic database routines in an Perl object

  # Instanciate MyDB object
  my $db = MyDB->new(<database>, <username>, <password>, %opts);

  # Add record
  my $status = $db->add(<tablename>, <%record>);

  # Delete record
  my $status = $db->delete(<tablename>, <condition>);

  # Modify record
  my $status = $db->modify(<tablename>, <%record>, <condition>)

  # Get records
  my @records = $db->get(<tablename>, <condition>, <fields>, <additional>)

=head1 DESCRIPTION

Low level but convienent database routines

=head1 ROUTINES

The following routines are exported:

=cut

package MyDB;

use strict;
use warnings;

use Carp;
use DBI;
use Exporter;

use Utils;

# Globals
our $VERSION = '$Revision: 1.0 $';
($VERSION) = ($VERSION =~ /\$Revision: (.*) /);

my %opts = (
  MYDB_USERNAME => $ENV{MYDB_USERNAME},
  MYDB_PASSWORD => $ENV{MYDB_PASSWORD},
  MYDB_DATABASE => $ENV{MYDB_DATABASE},
  MYDB_SERVER   => $ENV{MYDB_SERVER} || 'localhost',
);

# Internal methods
sub _dberror($$) {
  my ($self, $msg, $statement) = @_;

  my $dberr    = $self->{db}->err;
  my $dberrmsg = $self->{db}->errstr;

  $dberr    ||= 0;
  $dberrmsg ||= 'Success';

  my $message = '';

  if ($dberr) {
    my $function = (caller (1))[3];

    $message = "$function: $msg\nError #$dberr: $dberrmsg\n"
      . "SQL Statement: $statement";
  }    # if

  return $dberr, $message;
}    # _dberror

sub _encode_decode ($$$) {
  my ($self, $type, $password, $userid) = @_;

  my $statement = 'select ';

  if ($type eq 'encode') {
    $statement .= "hex(aes_encrypt('$password','$userid'))";
  } elsif ($type eq 'decode') {
    $statement .= "aes_decrypt(unhex('$password'),'$userid')";
  }    # if

  my $sth = $self->{db}->prepare ($statement)
    or return $self->_dberror ('MyDB::$type: Unable to prepare statement',
    $statement);

  $sth->execute
    or $self->_dberror ('MyDB::$type: Unable to execute statement', $statement);

  my @row = $sth->fetchrow_array;

  return $row[0];
}    # _encode_decode

sub _formatValues(@) {
  my ($self, @values) = @_;

  my @returnValues;

  # Quote data values
  push @returnValues, ($_ and $_ ne '')
    ? $self->{db}->quote ($_)
    : 'null'
    for (@values);

  return @returnValues;
}    # _formatValues

sub _formatNameValues(%) {
  my ($self, %rec) = @_;

  my @nameValueStrs;

  for (keys %rec) {
    if ($rec{$_}) {
      push @nameValueStrs, "$_=" . $self->{db}->quote ($rec{$_});
    } else {
      push @nameValueStrs, "$_=null";
    }    # if
  }    # for

  return @nameValueStrs;
}    # _formatNameValues

sub add($%) {
  my ($self, $table, %rec) = @_;

  my $statement = "insert into $table (";
  $statement .= join ',', keys %rec;
  $statement .= ') values (';
  $statement .= join ',', $self->_formatValues (values %rec);
  $statement .= ')';

  $self->{db}->do ($statement);

  return $self->_dberror ("Unable to add record to $table", $statement);
}    # add

sub check($) {
  my ($self, $table) = @_;

  my @tables;

  if (ref $table eq 'ARRAY') {
    @tables = @$table;
  } else {
    push @tables, $table;
  }    # if

  my $statement = 'check table ';
  $statement .= join ',', @tables;

  $self->{db}->do ($statement);

  return $self->_dberror ('MyDB::check: Unable to check tables', $statement);
}    # check

sub count($;$) {
  my ($self, $table, $condition) = @_;

  my $statement = "select count(*) from $table";
  $statement .= " where $condition" if $condition;

  my $sth = $self->{db}->prepare ($statement)
    or return $self->_dberror ('MyDB::count: Unable to prepare statement',
    $statement);

  $sth->execute
    or return $self->_dberror ('MyDB::count: Unable to execute statement',
    $statement);

  # Get return value, which should be how many entries there are
  my @row = $sth->fetchrow_array;

  # Done with $sth
  $sth->finish;

  my $count;

  # Retrieve returned value
  unless ($row[0]) {
    wantarray ? return (0, 'No records found') : return 0;
  } else {
    wantarray ? return ($row[0], 'Records found') : return $row[0];
  }    # unless

  return;
}    # count

sub count_distinct($$;$) {
  my ($self, $table, $column, $condition) = @_;

  my $statement = "select count(distinct $column) from $table";
  $statement .= " where $condition" if $condition;

  my $sth = $self->{db}->prepare ($statement)
    or return $self->_dberror ('MyDB::count: Unable to prepare statement',
    $statement);

  $sth->execute
    or return $self->_dberror ('MyDB::count: Unable to execute statement',
    $statement);

  # Get return value, which should be how many entries there are
  my @row = $sth->fetchrow_array;

  # Done with $sth
  $sth->finish;

  my $count;

  # Retrieve returned value
  unless ($row[0]) {
    wantarray ? return (0, 'No records found') : return 0;
  } else {
    wantarray ? return ($row[0], 'Records found') : return $row[0];
  }    # unless

  return;
}    # count_distinct

sub decode($$) {
  my ($self, $password, $userid) = @_;

  return $self->_encode_decode ('decode', $password, $userid);
}    # decode

sub delete($;$) {
  my ($self, $table, $condition) = @_;

  my $count = $self->count ($table, $condition);

  return ($count, 'Records deleted') if $count == 0;

  my $statement = "delete from $table ";
  $statement .= "where $condition" if $condition;

  $self->{db}->do ($statement);

  if ($self->{db}->err) {
    my ($err, $msg) =
      $self->_dberror ("MyDB::delete: Unable to delete record(s) from $table",
      $statement);

    wantarray ? return (-$err, $msg) : return -$err;
  } else {
    wantarray ? return ($count, 'Records deleted') : return $count;
  }    # if

  return;
}    # delete

sub DESTROY {
  my ($self) = @_;

  $self->{db}->disconnect if $self->{db};

  return;
}    # DESTROY

sub encode($$) {
  my ($self, $password, $userid) = @_;

  return $self->_encode_decode ('encode', $password, $userid);
}    # encode

sub find($;$@) {
  my ($self, $table, $condition, $fields, $additional) = @_;

  $fields //= '*';

  $fields = join ',', @$fields if ref $fields eq 'ARRAY';

  my $statement = "select $fields from $table";
  $statement .= " where $condition" if $condition;
  $statement .= " $additional"      if $additional;

  $self->{sth} = $self->{db}->prepare ($statement)
    or return $self->_dberror ('MyDB::find: Unable to prepare statement',
    $statement);

  $self->{sth}->execute
    or return $self->_dberror ('MyDB::find: Unable to execute statement',
    $statement);

  return $self->_dberror (
    "MyDB::find: Unable to find record ($table, $condition)", $statement);
}    # find

sub get($;$$$) {
  my ($self, $table, $condition, $fields, $additional) = @_;

  $fields //= '*';

  $fields = join ',', @$fields if ref $fields eq 'ARRAY';

  my $statement = "select $fields from $table";
  $statement .= " where $condition" if $condition;
  $statement .= " $additional"      if $additional;

  my $rows = $self->{db}->selectall_arrayref ($statement, {Slice => {}});

  return $rows if $rows;
  return $self->_dberror ('MyDB::get: Unable to prepare/execute statement',
    $statement);
}    # get

sub getone($;$$$) {
  my ($self, $table, $condition, $fields, $additional) = @_;

  my $rows = $self->get ($table, $condition, $fields, $additional);

  return $rows->[0];
}    # getone

sub getnext() {
  my ($self) = @_;

  return unless $self->{sth};

  return $self->{sth}->fetchrow_hashref;
}    # getnext

sub lastid() {
  my ($self) = @_;

  my $statement = 'select last_insert_id()';

  my $sth = $self->{db}->prepare ($statement)
    or
    $self->_dberror ('MyDB::lastid: Unable to prepare statement', $statement);

  $sth->execute
    or
    $self->_dberror ('MyDB::lastid: Unable to execute statement', $statement);

  my @row = $sth->fetchrow_array;

  return $row[0];
}    # lastid

sub lock(;$$) {
  my ($self, $type, $table) = @_;

  $type //= 'read';

  croak "Type must be read or write" unless $type =~ /(read|write)/;

  my $tables;

  if (ref $table eq 'ARRAY') {
    $tables = join " $type,", @$table;
  } else {
    $tables = $table;
  }    # if

  my $statement = "lock tables $tables";
  $statement .= " $type";

  $self->{db}->do ($statement);

  return $self->_dberror ("MyDB::lock Unable to lock $tables", $statement);
}    # lock

sub modify($$%) {
  my ($self, $table, $condition, %rec) = @_;

  my $statement = "update $table set ";
  $statement .= join ',', $self->_formatNameValues (%rec);
  $statement .= " where $condition" if $condition;

  $self->{db}->do ($statement);

  return $self->_dberror ("MyDB::modify: Unable to update record in $table",
    $statement);
}    # modify

sub new(;$$$$) {
  my ($class, $username, $password, $database, $dbserver) = @_;

  my $self = {
    username => $username || $opts{MYDB_USERNAME},
    password => $password || $opts{MYDB_PASSWORD},
    database => $database || $opts{MYDB_DATABASE},
    dbserver => $dbserver || $opts{MYDB_SERVER},
  };

  bless $self, $class;

  $self->{dbdriver} = 'mysql';

  $self->{db} = DBI->connect (
    "DBI:$self->{dbdriver}:$database:$self->{dbserver}",
    $self->{username},
    $self->{password},
    {PrintError => 0, mysql_enable_utf8mb4 => 1},

    )
    or croak
"MyDB::new: Couldn't connect to $database database as $self->{username}\@$self->{dbserver}";

  return $self;
}    # new

sub optimize($) {
  my ($self, $table) = @_;

  my @tables;

  if (ref $table eq 'ARRAY') {
    @tables = @$table;
  } else {
    push @tables, $table;
  }    # if

  my $statement = 'optimize table ';
  $statement .= join ',', @tables;

  $self->{db}->do ($statement);

  return $self->_dberror ('MyDB::optimize: Unable to optimize tables',
    $statement);
}    # optimize

sub unlock() {
  my ($self) = @_;

  my $statement = 'unlock tables';

  $self->{db}->do ($statement);

  return $self->_dberror ('MyDB::unlock: Unable to unlock tables', $statement);
}    # unlock

sub update($$%) {

  # Using a Perl goto statement in this fashion really just creates an alias
  # such that the user can call either modify or update.
  goto &modify;
}    # update

1;
