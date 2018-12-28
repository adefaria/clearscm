=pod

=head1 NAME $RCSfile: Clearadm.pm,v $

Object oriented interface to Clearadm.

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.54 $

=item Created

Tue Dec 07 09:13:27 EST 2010

=item Modified

$Date: 2012/11/09 06:43:26 $

=back

=head1 SYNOPSIS

Provides the Clearadm object which handles all interaction with the Clearadm
database. Similar add/change/delete/update methods for other record types. In
general you must orient your record hashs to have the appropriately named
keys that correspond to the database. Also see mothod documentation for
specifics about the method you are envoking.

 # Create new Clearadm object
 my $clearadm = new Clearadm;

 # Add a new system
 my %system = (
  name          => 'jupiter',
  alias         => 'defaria.com',
  admin         => 'Andrew DeFaria',
  os            => 'Linux defaria.com 2.6.32-25-generic-pae #45-Ubuntu SMP Sat Oct 16 21:01:33 UTC 2010 i686 GNU/Linux',
  type          => 'Linux',
  description   => 'Home server',
 );

 my ($err, $msg) = $clearadm->AddSystem (%system);

 # Find systems matching 'jup'
 my @systems = $clearadm->FindSystem ('jup');

 # Get a system by name
 my %system = $clearadm->GetSystem ('jupiter');

 # Update system
 my %update = (
  'region' => 'East Coast',
 );

 my ($err, $msg) = $clearadm->UpdateSystem ('jupiter', %update);

 # Delete system (Warning: will delete all related records regarding this
 # system).
 my ($err, $msg) = $clearadm->DeleteSystem ('jupiter');

=head1 DESCRIPTION

This package provides and object oriented interface to the Clearadm database.
Methods are provided to manipulate records by adding, updating and deleting
them. In general you need to specify a hash which contains keys and values
corresponding to the database field names and values.

=head1 ROUTINES

The following methods are available:

=cut

package Clearadm;

use strict;
use warnings;

use Carp;
use DBI;
use File::Basename;
use Net::Domain qw(hostdomain);
use Sys::Hostname;

use FindBin;

use lib "$FindBin::Bin", "$FindBin::Bin/../../lib";

use DateUtils;
use Display;
use GetConfig;
use Mail;

my $conf = dirname(__FILE__) . '/../etc/clearadm.conf';

our %CLEAROPTS = GetConfig($conf);

# Globals
our $VERSION  = '$Revision: 1.54 $';
   ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);

$CLEAROPTS{CLEARADM_USERNAME} = $ENV{CLEARADM_USERNAME}
                              ? $ENV{CLEARADM_USERNAME}
                              : $CLEAROPTS{CLEARADM_USERNAME}
                              ? $CLEAROPTS{CLEARADM_USERNAME}
                              : 'clearwriter';
$CLEAROPTS{CLEARADM_PASSWORD} = $ENV{CLEARADM_PASSWORD}
                              ? $ENV{CLEARADM_PASSWORD}
                              : $CLEAROPTS{CLEARADM_PASSWORD}
                              ? $CLEAROPTS{CLEARADM_PASSWORD}
                              : 'clearwriter';
$CLEAROPTS{CLEARADM_SERVER}   = $ENV{CLEARADM_SERVER}
                              ? $ENV{CLEARADM_SERVER}
                              : $CLEAROPTS{CLEARADM_SERVER}
                              ? $CLEAROPTS{CLEARADM_SERVER}
                              : 'localhost';

my $defaultFilesystemThreshold = 90;
my $defaultFilesystemHist      = '6 months';
my $defaultLoadavgHist         = '6 months';

# Internal methods
sub _dberror($$) {
  my ($self, $msg, $statement) = @_;

  my $dberr    = $self->{db}->err;
  my $dberrmsg = $self->{db}->errstr;

  $dberr    ||= 0;
  $dberrmsg ||= 'Success';

  my $message = '';

  if ($dberr) {
    my $function = (caller(1)) [3];

    $message = "$function: $msg\nError #$dberr: $dberrmsg\n"
             . "SQL Statement: $statement";
  } # if

  return $dberr, $message;
} # _dberror

sub _formatValues(@) {
  my ($self, @values) = @_;

  my @returnValues;

  # Quote data values
  push @returnValues, $_ eq '' ? 'null' : $self->{db}->quote($_)
    for (@values);

  return @returnValues;
} # _formatValues

sub _formatNameValues(%) {
  my ($self, %rec) = @_;

  my @nameValueStrs;

  push @nameValueStrs, "$_=" . $self->{db}->quote($rec{$_})
    for (keys %rec);

  return @nameValueStrs;
} # _formatNameValues

sub _addRecord($%) {
  my ($self, $table, %rec) = @_;

  my $statement  = "insert into $table (";
     $statement .= join ',', keys %rec;
     $statement .= ') values (';
     $statement .= join ',', $self->_formatValues(values %rec);
     $statement .= ')';

  my ($err, $msg);

  $self->{db}->do($statement);

  return $self->_dberror("Unable to add record to $table", $statement);
} # _addRecord

sub _deleteRecord($;$) {
  my ($self, $table, $condition) = @_;

  my $count;

  my $statement  = "select count(*) from $table ";
     $statement .= "where $condition"
      if $condition;

  my $sth = $self->{db}->prepare($statement)
    or return $self->_dberror('Unable to prepare statement', $statement);

  $sth->execute
    or return $self->_dberror('Unable to execute statement', $statement);

  my @row = $sth->fetchrow_array;

  $sth->finish;

  if ($row[0]) {
    $count = $row[0];
  } else {
    $count = 0;
  } # if

  return ($count, 'Records deleted')
    if $count == 0;

  $statement  = "delete from $table ";
  $statement .= "where $condition"
    if $condition;

  $self->{db}->do($statement);

  if ($self->{db}->err) {
    return $self->_dberror("Unable to delete record from $table", $statement);
  } else {
    return $count, 'Records deleted';
  } # if
} # _deleteRecord

sub _updateRecord($$%) {
  my ($self, $table, $condition, %rec) = @_;

  my $statement  = "update $table set ";
     $statement .= join ',', $self->_formatNameValues(%rec);
     $statement .= " where $condition"
       if $condition;

  $self->{db}->do($statement);

  return $self->_dberror("Unable to update record in $table", $statement);
} # _updateRecord

sub _checkRequiredFields($$) {
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

sub _getRecords($$;$) {
  my ($self, $table, $condition, $additional) = @_;

  my ($err, $msg);

  $additional ||= '';

  my $statement  = "select * from $table";
     $statement .= " where $condition" if $condition;
     $statement .= $additional;

  my $sth = $self->{db}->prepare($statement);

  unless ($sth) {
    ($err, $msg) = $self->_dberror('Unable to prepare statement', $statement);

    croak $msg;
  } # if

  my $attempts    = 0;
  my $maxAttempts = 3;
  my $sleepTime   = 30;
  my $status;

  # We've been having the server going away. Supposedly it should reconnect so
  # here we simply retry up to $maxAttempts times to re-execute the statement.
  # (Are there other places where we need to do this?)
  $err = 2006;

  while ($err == 2006 and $attempts++ < $maxAttempts) {
    $status = $sth->execute;

    if ($status) {
      $err = 0;
      last;
    } else {
      ($err, $msg) = $self->_dberror('Unable to execute statement',
                                      $statement);
    } # if

    last if $err == 0;

    croak $msg unless $err == 2006;

    my $timestamp = YMDHMS;

    $self->Error("$timestamp: Unable to talk to DB server.\n\n$msg\n\n"
                . "Will try again in $sleepTime seconds", -1);

    # Try to reconnect
    $self->_connect($self->{dbserver});

    sleep $sleepTime;
  } # while

  $self->Error("After $maxAttempts attempts I could not connect to the database", $err)
    if ($err == 2006 and $attempts > $maxAttempts);

  my @records;

  while (my $row = $sth->fetchrow_hashref) {
    push @records, $row;
  } # while

  return @records;
} # _getRecords

sub _aliasSystem($) {
  my ($self, $system) = @_;

  my %system = $self->GetSystem($system);

  if ($system{name}) {
    return $system{name};
  } else {
  	return;
  } # if
} # _aliasSystem

sub _getLastID() {
  my ($self) = @_;

  my $statement = 'select last_insert_id()';

  my $sth = $self->{db}->prepare($statement);

  my ($err, $msg);

  unless ($sth) {
    ($err, $msg) = $self->_dberror('Unable to prepare statement', $statement);

    croak $msg;
  } # if

  my $status = $sth->execute;

  unless ($status) {
    ($err, $msg) = $self->_dberror('Unable to execute statement', $statement);

    croak $msg;
  } # if

  my @records;

  my @row = $sth->fetchrow_array;

  return $row[0];
} # _getLastID

sub _connect(;$) {
  my ($self, $dbserver) = @_;

  $dbserver ||= $CLEAROPTS{CLEARADM_SERVER};

  my $dbname   = 'clearadm';
  my $dbdriver = 'mysql';

  $self->{db} = DBI->connect(
    "DBI:$dbdriver:$dbname:$dbserver",
    $CLEAROPTS{CLEARADM_USERNAME},
    $CLEAROPTS{CLEARADM_PASSWORD},
    {PrintError => 0},
  ) or croak(
    "Couldn't connect to $dbname database "
  . "as $CLEAROPTS{CLEARADM_USERNAME}\@$CLEAROPTS{CLEARADM_SERVER}"
  );

  $self->{dbserver} = $dbserver;

  return;
} # _connect

sub new(;$) {
  my ($class, $dbserver) = @_;

  my $self = bless {}, $class;

  $self->_connect($dbserver);

  return $self;
} # new

sub SetNotify() {
  my ($self) = @_;

  $self->{NOTIFY} = $CLEAROPTS{CLEARADM_NOTIFY};

  return;
} # SetNotify

sub Error($;$) {
  my ($self, $msg, $errno) = @_;

  # If $errno is specified we need to stop. However we need to notify somebody
  # that cleartasks is no longer running.
  error $msg;

  if ($errno) {
    if ($self->{NOTIFY}) {
      mail(
        to      => $self->{NOTIFY},
        subject => 'Internal error occurred in Clearadm',
        data    => "<p>An unexpected, internal error occurred in Clearadm:</p><p>$msg</p>",
        mode    => 'html',
      );

      exit $errno  if $errno > 0;
    } # if
  } # if

  return;
} # Error

sub AddSystem(%) {
  my ($self, %system) = @_;

  my @requiredFields = (
    'name',
  );

  my $result = _checkRequiredFields \@requiredFields, \%system;

  return -1, "AddSystem: $result"
    if $result;

  $system{loadavgHist} ||= $defaultLoadavgHist;

  return $self->_addRecord('system', %system);
} # AddSystem

sub DeleteSystem($) {
  my ($self, $name) = @_;

  return $self->_deleteRecord('system', "name='$name'");
} # DeleteSystem

sub UpdateSystem ($%) {
  my ($self, $name, %update) = @_;

  return $self->_updateRecord('system', "name='$name'", %update);
} # UpdateSystem

sub GetSystem($) {
  my ($self, $system) = @_;

  return
    unless $system;

  my @records = $self->_getRecords(
    'system',
    "name='$system' or alias like '%$system%'"
  );

  if ($records[0]) {
    return %{$records[0]};
  } else {
  	return;
  } # if
} # GetSystem

sub FindSystem(;$) {
  my ($self, $system) = @_;

  $system ||= '';

  my $condition = "name like '%$system%' or alias like '%$system%'";

  return $self->_getRecords('system', $condition);
} # FindSystem

sub SearchSystem(;$) {
  my ($self, $condition) = @_;

  $condition = "name like '%'" unless $condition;

  return $self->_getRecords('system', $condition);
} # SearchSystem

sub AddPackage(%) {
  my ($self, %package) = @_;

  my @requiredFields = (
    'system',
    'name',
    'version'
  );

  my $result = _checkRequiredFields \@requiredFields, \%package;

  return -1, "AddPackage: $result"
    if $result;

  return $self->_addRecord('package', %package);
} # AddPackage

sub DeletePackage($$) {
  my ($self, $system, $name) = @_;

  return $self->_deleteRecord(
    'package',
    "(system='$system' or alias='$system') and name='$name'");
} # DeletePackage

sub UpdatePackage($$%) {
  my ($self, $system, $name, %update) = @_;

  $system = $self->_aliasSystem($system);

  return
    unless $system;

  return $self->_updateRecord('package', "system='$system'", %update);
} # UpdatePackage

sub GetPackage($$) {
  my ($self, $system, $name) = @_;

  $system = $self->_aliasSystem($system);

  return
    unless $system;

  return
    unless $name;

  my @records = $self->_getRecords(
    'package',
    "system='$system' and name='$name'"
  );

  if ($records[0]) {
    return %{$records[0]};
  } else {
  	return;
  } # if
} # GetPackage

sub FindPackage($;$) {
  my ($self, $system, $name) = @_;

  $name ||= '';

  $system = $self->_aliasSystem($system);

  return
    unless $system;

  my $condition = "system='$system' and name like '%$name%'";

  return $self->_getRecords('package', $condition);
} # FindPackage

sub AddFilesystem(%) {
  my ($self, %filesystem) = @_;

  my @requiredFields = (
    'system',
    'filesystem',
    'fstype'
  );

  my $result = _checkRequiredFields \@requiredFields, \%filesystem;

  return -1, "AddFilesystem: $result"
    if $result;

  # Default filesystem threshold
  $filesystem{threshold} ||= $defaultFilesystemThreshold;

  return $self->_addRecord('filesystem', %filesystem);
} # AddFilesystem

sub DeleteFilesystem($$) {
  my ($self, $system, $filesystem) = @_;

  $system = $self->_aliasSystem($system);

  return
    unless $system;

  return $self->_deleteRecord(
    'filesystem',
    "system='$system' and filesystem='$filesystem'"
  );
} # DeleteFilesystem

sub UpdateFilesystem($$%) {
  my ($self, $system, $filesystem, %update) = @_;

  $system = $self->_aliasSystem($system);

  return
    unless $system;

  return $self->_updateRecord(
    'filesystem',
    "system='$system' and filesystem='$filesystem'",
    %update
  );
} # UpdateFilesystem

sub GetFilesystem($$) {
  my ($self, $system, $filesystem) = @_;

  $system = $self->_aliasSystem($system);

  return
    unless $system;

  return
    unless $filesystem;

  my @records = $self->_getRecords(
    'filesystem',
    "system='$system' and filesystem='$filesystem'"
  );

  if ($records[0]) {
    return %{$records[0]};
  } else {
    return;
  } # if
} # GetFilesystem

sub FindFilesystem($;$) {
  my ($self, $system, $filesystem) = @_;

  $filesystem ||= '';

  $system = $self->_aliasSystem($system);

  return
    unless $system;

  my $condition = "system='$system' and filesystem like '%$filesystem%'";

  return $self->_getRecords('filesystem', $condition);
} # FindFilesystem

sub AddVob(%) {
  my ($self, %vob) = @_;

  my @requiredFields = (
    'tag',
    'region',
  );

  my $result = _checkRequiredFields \@requiredFields, \%vob;

  return -1, "AddVob: $result" if $result;

  return $self->_addRecord('vob', %vob);
} # AddVob

sub DeleteVob($$) {
  my ($self, $tag, $region) = @_;

  return $self->_deleteRecord('vob', "tag='$tag' and region='$region'");
} # DeleteVob

sub GetVob($$) {
  my ($self, $tag, $region) = @_;

  return unless $tag;

  # Windows vob tags begin with "\", which is problematic. The solution is to
  # escape the "\"
  $tag =~ s/^\\/\\\\/;

  my @records = $self->_getRecords('vob', "tag='$tag' and region='$region'");

  if ($records[0]) {
    return %{$records[0]};
  } else {
    return;
  } # if
} # GetVob

sub FindVob($;$) {
  my ($self, $tag, $region) = @_;

  # Windows vob tags begin with "\", which is problematic. The solution is to
  # escape the "\"
  $tag =~ s/^\\/\\\\/;

  my $condition = "tag like '%$tag%'";
  
  $condition .= " and region='$region'" if $region;

  return $self->_getRecords('vob', $condition);
} # FindVob

sub UpdateVob(%) {
  my ($self, %vob) = @_;

  # Windows vob tags begin with "\", which is problematic. The solution is to
  # escape the "\"
  my $vobtag = $vob{tag};

  $vobtag =~ s/^\\/\\\\/;

  return $self->_updateRecord('vob', "tag='$vobtag' and region='$vob{region}'", %vob);
} # UpdateVob

sub AddView(%) {
  my ($self, %view) = @_;

  my @requiredFields = (
    'tag',
    'region'
  );

  my $result = _checkRequiredFields \@requiredFields, \%view;

  return -1, "AddView: $result"
    if $result;

  return $self->_addRecord('view', %view);
} # AddView

sub DeleteView($$) {
  my ($self, $tag, $region) = @_;

  return $self->_deleteRecord('vob', "tag='$tag' and region='$region'");
} # DeleteView

sub UpdateView(%) {
  my ($self, %view) = @_;

  return $self->_updateRecord('view', "tag='$view{tag}' and region='$view{region}'", %view);
} # UpdateView

sub GetView($$) {
  my ($self, $tag, $region) = @_;

  return unless $tag;

  my @records = $self->_getRecords('view', "tag='$tag' and region='$region'");

  if ($records[0]) {
    return %{$records[0]};
  } else {
    return;
  } # if
} # GetView

sub FindView(;$$$$) {
  my ($self, $system, $region, $tag, $ownerName) = @_;

  $system    ||= '';
  $region    ||= '';
  $tag       ||= '';
  $ownerName ||= '';

  my $condition;

  $condition  = "system like '%$system%'";
  $condition .= ' and ';
  $condition  = "region like '%$region%'";
  $condition .= ' and ';
  $condition .= "tag like '%$tag'";
  $condition .= ' and ';
  $condition .= "ownerName like '%$ownerName'";

  return $self->_getRecords('view', $condition);
} # FindView

sub AddFS(%) {
  my ($self, %fs) = @_;

  my @requiredFields = (
    'system',
    'filesystem',
  );

  my $result = _checkRequiredFields \@requiredFields, \%fs;

  return -1, "AddFS: $result"
    if $result;

  # Timestamp record
  $fs{timestamp} = Today2SQLDatetime;

  return $self->_addRecord('fs', %fs);
} # AddFS

sub TrimFS($$) {
  my ($self, $system, $filesystem) = @_;

  my %filesystem = $self->GetFilesystem($system, $filesystem);

  return
    unless %filesystem;

  my %task = $self->GetTask('scrub');

  $self->Error("Unable to find scrub task!", 1) unless %task;

  my $days;
  my $today = Today2SQLDatetime;

  # TODO: SubtractDays uses just an approximation (i.e. subtracting 30 days when
  # in February is not right.
  if ($filesystem{filesystemHist} =~ /(\d+) month/i) {
    $days = $1 * 30;
  } elsif ($filesystem{filesystemHist} =~ /(\d+) year/i) {
    $days = $1 * 365;
  } # if

  my $oldage = SubtractDays $today, $days;

  my ($dberr, $dbmsg) = $self->_deleteRecord(
    'fs',
    "system='$system' and filesystem='$filesystem' and timestamp<='$oldage'"
  );

  if ($dbmsg eq 'Records deleted') {
    return (0, $dbmsg)
      if $dberr == 0;

    my %runlog;

    $runlog{task}    = $task{name};
    $runlog{started} = $today;
    $runlog{status}  = 0;
    $runlog{message} =
      "Scrubbed $dberr fs records for filesystem $system:$filesystem";

    my ($err, $msg) = $self->AddRunlog(%runlog);

    $self->Error("Unable to add runlog - (Error: $err)\n$msg") if $err;
  } # if

  return ($dberr, $dbmsg);
} # TrimFS

sub TrimLoadavg($) {
  my ($self, $system) = @_;

  my %system = $self->GetSystem($system);

  return
    unless %system;

  my %task = $self->GetTask('loadavg');

  $self->Error("Unable to find loadavg task!", 1) unless %task;

  my $days;
  my $today = Today2SQLDatetime;

  # TODO: SubtractDays uses just an approximation (i.e. subtracting 30 days when
  # in February is not right.
  if ($system{loadavgHist} =~ /(\d+) month/i) {
    $days = $1 * 30;
  } elsif ($system{loadavgHist} =~ /(\d+) year/i) {
    $days = $1 * 365;
  } # if

  my $oldage = SubtractDays $today, $days;

  my ($dberr, $dbmsg) = $self->_deleteRecord(
    'loadavg',
    "system='$system' and timestamp<='$oldage'"
  );

  if ($dbmsg eq 'Records deleted') {
    return (0, $dbmsg)
      if $dberr == 0;

    my %runlog;

    $runlog{task}    = $task{name};
    $runlog{started} = $today;
    $runlog{status}  = 0;
    $runlog{message} =
      "Scrubbed $dberr loadavg records for system $system";

    my ($err, $msg) = $self->AddRunlog(%runlog);

    $self->Error("Unable to add runload (Error: $err)\n$msg") if $err;
  } # if

  return ($dberr, $dbmsg);
} # TrimLoadavg

sub GetFS($$;$$$$) {
  my ($self, $system, $filesystem, $start, $end, $count, $interval) = @_;

  $system = $self->_aliasSystem($system);

  return
    unless $system;

  return
    unless $filesystem;

  $interval ||= 'Minute';

  my $size = $interval =~ /month/i
           ? 7
           : $interval =~ /day/i
           ? 10
           : $interval =~ /hour/i
           ? 13
           : 16;

  undef $start if $start and $start =~ /earliest/i;
  undef $end   if $end   and $end   =~ /latest/i;

  my $condition  = "system='$system' and filesystem='$filesystem'";
     $condition .= " and timestamp>='$start'" if $start;
     $condition .= " and timestamp<='$end'"   if $end;

     $condition .= " group by left(timestamp,$size)";

  if ($count) {
    # We can't simply do a "limit 0, $count" as that just gets the front end of
    # the records return (i.e. if $count = say 10 and the timestamp range
    # returns 40 rows we'll see only rows 1-10, not rows 31-40). We need limit
    # $offset, $count where $offset = the number of qualifying records minus
    # $count
    my $nbrRecs = $self->Count('fs', $condition);
    my $offset  = $nbrRecs - $count;

    # Offsets of < 0 are not allowed.
    $offset = 0
      if $offset < 0;

    $condition .= " limit $offset, $count";
  } # if

  my $statement = <<"END";
select
  system,
  filesystem,
  mount,
  left(timestamp,$size) as timestamp,
  avg(size) as size,
  avg(used) as used,
  avg(free) as free,
  reserve
from
  fs
  where $condition
END

  my ($err, $msg);

  my $sth = $self->{db}->prepare($statement);

  unless ($sth) {
    ($err, $msg) = $self->_dberror('Unable to prepare statement', $statement);

    croak $msg;
  } # if

  my $status = $sth->execute;

  unless ($status) {
    ($err, $msg) = $self->_dberror('Unable to execute statement', $statement);

    croak $msg;
  } # if

  my @records;

  while (my $row = $sth->fetchrow_hashref) {
    push @records, $row;
  } # while

  return @records;
} # GetFS

sub GetLatestFS($$) {
  my ($self, $system, $filesystem) = @_;

  $system = $self->_aliasSystem($system);

  return
    unless $system;

  return
    unless $filesystem;

  my @records = $self->_getRecords(
    'fs',
    "system='$system' and filesystem='$filesystem'"
  . " order by timestamp desc limit 0, 1",
  );

  if ($records[0]) {
  	return %{$records[0]};
  } else {
  	return;
  } # if
} # GetLatestFS

sub AddLoadavg() {
  my ($self, %loadavg) = @_;

  my @requiredFields = (
    'system',
  );

  my $result = _checkRequiredFields \@requiredFields, \%loadavg;

  return -1, "AddLoadavg: $result"
    if $result;

  # Timestamp record
  $loadavg{timestamp} = Today2SQLDatetime;

  return $self->_addRecord('loadavg', %loadavg);
} # AddLoadavg

sub GetLoadavg($;$$$$) {
  my ($self, $system, $start, $end, $count, $interval) = @_;

  $system = $self->_aliasSystem($system);

  return
    unless $system;

  $interval ||= 'Minute';

  my $size = $interval =~ /month/i
           ? 7
           : $interval =~ /day/i
           ? 10
           : $interval =~ /hour/i
           ? 13
           : 16;

  my $condition;

  undef $start if $start and $start =~ /earliest/i;
  undef $end   if $end   and $end   =~ /latest/i;

  $condition .= " system='$system'"        if $system;
  $condition .= " and timestamp>='$start'" if $start;
  $condition .= " and timestamp<='$end'"   if $end;

  $condition .= " group by left(timestamp,$size)";

  if ($count) {
    # We can't simply do a "limit 0, $count" as that just gets the front end of
    # the records return (i.e. if $count = say 10 and the timestamp range
    # returns 40 rows we'll see only rows 1-10, not rows 31-40). We need limit
    # $offset, $count where $offset = the number of qualifying records minus
    # $count
    my $nbrRecs = $self->Count('loadavg', $condition);
    my $offset  = $nbrRecs - $count;

    # Offsets of < 0 are not allowed.
    $offset = 0
      if $offset < 0;

    $condition .= " limit $offset, $count";
  } # if

  my $statement = <<"END";
select
  system,
  left(timestamp,$size) as timestamp,
  uptime,
  users,
  avg(loadavg) as loadavg
from
  loadavg
  where $condition
END

  my ($err, $msg);

  my $sth = $self->{db}->prepare($statement);

  unless ($sth) {
    ($err, $msg) = $self->_dberror('Unable to prepare statement', $statement);

    croak $msg;
  } # if

  my $status = $sth->execute;

  unless ($status) {
    ($err, $msg) = $self->_dberror('Unable to execute statement', $statement);

    croak $msg;
  } # if

  my @records;

  while (my $row = $sth->fetchrow_hashref) {
    push @records, $row;
  } # while

  return @records;
} # GetLoadvg

sub GetLatestLoadavg($) {
  my ($self, $system) = @_;

  $system = $self->_aliasSystem($system);

  return
    unless $system;

  my @records = $self->_getRecords(
    'loadavg',
    "system='$system'"
  . " order by timestamp desc limit 0, 1",
  );

  if ($records[0]) {
    return %{$records[0]};
  } else {
    return;
  } # if
} # GetLatestLoadavg

sub GetStorage($$$;$$$$$) {
  my ($self, $type, $tag, $storage, $region, $start, $end, $count, $interval) = @_;

  $interval ||= 'Day';
  $region   ||= $Clearcase::CC->region;

  return unless $type =~ /vob/i or $type =~ /view/;

  my $size = $interval =~ /month/i
           ? 7
           : $interval =~ /day/i
           ? 10
           : $interval =~ /hour/i
           ? 13
           : 16;

  undef $start if $start and $start =~ /earliest/i;
  undef $end   if $end   and $end   =~ /latest/i;

  # Windows vob tags begin with "\", which is problematic. The solution is to
  # escape the "\"
  $tag =~ s/^\\/\\\\/;

  my $condition;
  my $table = $type eq 'vob' ? 'vobstorage' : 'viewstorage';

  $condition  = "tag='$tag' and region='$region'";
  $condition .= " and timestamp>='$start'" if $start;
  $condition .= " and timestamp<='$end'"   if $end;

  $condition .= " group by left(timestamp,$size)";

  if ($count) {
    # We can't simply do a "limit 0, $count" as that just gets the front end of
    # the records return (i.e. if $count = say 10 and the timestamp range
    # returns 40 rows we'll see only rows 1-10, not rows 31-40). We need limit
    # $offset, $count where $offset = the number of qualifying records minus
    # $count
    my $nbrRecs = $self->Count($table, $condition);
    my $offset  = $nbrRecs - $count;

    # Offsets of < 0 are not allowed.
    $offset = 0 if $offset < 0;

    $condition .= " limit $offset, $count";
  } # if

  my $statement = <<"END";
select
  tag,
  region,
  left(timestamp,$size) as timestamp,
  avg($storage) as size
from
  $table
  where $condition
END

  my ($err, $msg);

  my $sth = $self->{db}->prepare($statement);

  unless ($sth) {
    ($err, $msg) = $self->_dberror('Unable to prepare statement', $statement);

    croak $msg;
  } # if

  my $status = $sth->execute;

  unless ($status) {
    ($err, $msg) = $self->_dberror('Unable to execute statement', $statement);

    croak $msg;
  } # if

  my @records;

  while (my $row = $sth->fetchrow_hashref) {
    push @records, $row;
  } # while

  return @records;
} # GetStorage

sub AddTask(%) {
  my ($self, %task) = @_;

  my @requiredFields = (
    'name',
    'command'
  );

  my $result = _checkRequiredFields \@requiredFields, \%task;

  return -1, "AddTask: $result"
    if $result;

  return $self->_addRecord('task', %task);
} # AddTask

sub DeleteTask($) {
  my ($self, $name) = @_;

  return $self->_deleteRecord('task', "name='$name'");
} # DeleteTask

sub FindTask($) {
  my ($self, $name) = @_;

  $name ||= '';

  my $condition = "name like '%$name%'";

  return $self->_getRecords('task', $condition);
} # FindTask

sub GetTask($) {
  my ($self, $name) = @_;

  return
    unless $name;

  my @records = $self->_getRecords('task', "name='$name'");

  if ($records[0]) {
    return %{$records[0]};
  } else {
    return;
  } # if
} # GetTask

sub UpdateTask($%) {
  my ($self, $name, %update) = @_;

  return $self->_updateRecord('task', "name='$name'", %update);
} # Update

sub AddSchedule(%) {
  my ($self, %schedule) = @_;

  my @requiredFields = (
    'task',
  );

  my $result = _checkRequiredFields \@requiredFields, \%schedule;

  return -1, "AddSchedule: $result"
    if $result;

  return $self->_addRecord('schedule', %schedule);
} # AddSchedule

sub DeleteSchedule($) {
  my ($self, $name) = @_;

  return $self->_deleteRecord('schedule', "name='$name'");
} # DeleteSchedule

sub FindSchedule(;$$) {
  my ($self, $name, $task) = @_;

  $name ||= '';
  $task||= '';

  my $condition  = "name like '%$name%'";
     $condition .= ' and ';
     $condition .= "task like '%$task%'";

  return $self->_getRecords('schedule', $condition);
} # FindSchedule

sub GetSchedule($) {
  my ($self, $name) = @_;

  my @records = $self->_getRecords('schedule', "name='$name'");

  if ($records[0]) {
    return %{$records[0]};
  } else {
    return;
  } # if
} # GetSchedule

sub UpdateSchedule($%) {
  my ($self, $name, %update) = @_;

  return $self->_updateRecord('schedule', "name='$name'", %update);
} # UpdateSchedule

sub AddRunlog(%) {
  my ($self, %runlog) = @_;

  my @requiredFields = (
    'task',
  );

  my $result = _checkRequiredFields \@requiredFields, \%runlog;

  return -1, "AddRunlog: $result"
    if $result;

  $runlog{ended} = Today2SQLDatetime;

  $runlog{system} = hostname if $runlog{system} =~ /localhost/i;

  my ($err, $msg) = $self->_addRecord('runlog', %runlog);

  return ($err, $msg, $self->_getLastID);
} # AddRunlog

sub DeleteRunlog($) {
  my ($self, $condition) = @_;

  return $self->_deleteRecord('runlog', $condition);
} # DeleteRunlog

sub FindRunlog(;$$$$$$) {
  my ($self, $task, $system, $status, $id, $start, $page) = @_;

  # If ID is specified then that's all that really matters as it uniquely
  # identifies a runlog entry;
  my ($condition, $conditions);
  my $limit = '';

  unless ($id) {
    if ($task !~ /all/i) {
      $conditions++;
      $condition = "task like '%$task%'";
    } # if

    if ($system !~ /all/i) {
      $condition .= ' and ' if $conditions;
      $condition .= "system like '%$system%'";
      $conditions++;
    } # if

    if ($status) {
      $condition .= ' and ' if $conditions;

      if ($status =~ /!(-*\d+)/) {
        $condition .= "status<>$1";
      } else {
        $condition .= "status=$status"
      } # if
    } # if

    # Need defined here as $start may be 0!
    if (defined $start) {
      $page ||= 10;
      $limit = "limit $start, $page";
    } # unless
  } else {
    $condition = "id=$id";
  } # unless

  return $self->_getRecords('runlog', $condition, " order by started desc $limit");
} # FindRunlog

sub GetRunlog($) {
  my ($self, $id) = @_;

  return
    unless $id;

  my @records = $self->_getRecords('runlog', "id=$id");

  if ($records[0]) {
    return %{$records[0]};
  } else {
    return;
  } # if
} # GetRunlog

sub UpdateRunlog($%) {
  my ($self, $id, %update) = @_;

  return $self->_updateRecord('runlog', "id=$id", %update);
} # UpdateRunlog

sub Count($;$) {
  my ($self, $table, $condition) = @_;

  $condition = $condition ? 'where ' . $condition : '';

  my ($err, $msg);

  my $statement = "select count(*) from $table $condition";

  my $sth = $self->{db}->prepare($statement);

  unless ($sth) {
    ($err, $msg) = $self->_dberror('Unable to prepare statement', $statement);

    croak $msg;
  } # if

  my $status = $sth->execute;

  unless ($status) {
    ($err, $msg) = $self->_dberror('Unable to execute statement', $statement);

    croak $msg;
  } # if

  # Hack! Statements such as the following:
  #
  # select count(*) from fs where system='jupiter' and filesystem='/dev/sdb5'
  # > group by left(timestamp,10);
  # +----------+
  # | count(*) |
  # +----------+
  # |       49 |
  # |       98 |
  # |      140 |
  # |        7 |
  # |       74 |
  # |      124 |
  # |      190 |
  # +----------+
  # 7 rows in set (0.00 sec)
  #
  # Here we want 7 but what we see in $records[0] is 49. So the hack is that if
  # statement contains "group by" then we assume we have the above and return
  # scalar @records, otherwise we return $records[0];
  if ($statement =~ /group by/i) {
    my $allrows = $sth->fetchall_arrayref;

    return scalar @{$allrows};
  } else {
    my @records = $sth->fetchrow_array;

    return $records[0];
  } # if
} # Count

# GetWork returns two items, the number of seconds to wait before the next task
# and array of hash records of work to be done immediately. The caller should
# execute the work to be done, timing it, and subtracting it from the $sleep
# time returned. If the caller exhausts the $sleep time then they should call
# us again.
sub GetWork() {
  my ($self) = @_;

  my ($err, $msg);

  my $statement = <<"END";
select
  schedule.name as schedulename,
  task.name,
  task.system as system,
  task.command,
  schedule.notification,
  frequency,
  runlog.started as lastrun
from
  task,
  schedule left join runlog on schedule.lastrunid=runlog.id
where
      schedule.task=task.name
  and schedule.active='true'
order by lastrun
END

  my $sth = $self->{db}->prepare($statement);

  unless ($sth) {
    ($err, $msg) = $self->_dberror('Unable to prepare statement', $statement);

    croak $msg;
  } # if

  my $status = $sth->execute;

  unless ($status) {
    ($err, $msg) = $self->_dberror('Unable to execute statement', $statement);

    croak $msg;
  } # if

  my $sleep;
  my @records;

  while (my $row = $sth->fetchrow_hashref) {
   if ($$row{system} !~ /localhost/i) {
     my %system = $self->GetSystem($$row{system});

     # Skip inactive systems
     next if $system{active} eq 'false';
   } # if

    # If started is not defined then this task was never run so run it now.
    unless ($$row{lastrun}) {
      push @records, $row;
      next;
    } # unless

    # TODO: Handle frequencies better.
    my $seconds;

    if ($$row{frequency} =~ /(\d+) seconds/i) {
      $seconds = $1;
    } elsif ($$row{frequency} =~ /(\d+) minute/i) {
      $seconds = $1 * 60;
    } elsif ($$row{frequency} =~ /(\d+) hour/i) {
      $seconds = $1 * 60 * 60;
    } elsif ($$row{frequency} =~ /(\d+) day/i) {
      $seconds= $1 * 60 * 60 * 24;
    } else {
      warning "Don't know how to handle frequencies like $$row{frequency}";
      next;
    } # if

    my $today    = Today2SQLDatetime;
    my $lastrun  = Add($$row{lastrun}, (seconds => $seconds));
    my $waitTime = DateToEpoch($lastrun) - DateToEpoch($today);

    if ($waitTime < 0) {
      # We're late - push this onto records and move on
      push @records, $row;
    } # if

    $sleep ||= $waitTime;

    if ($sleep > $waitTime) {
      $sleep = $waitTime;
    } # if
  } # while

  # Even if there is nothing to do the caller should sleep a bit and come back
  # to us. So if it ends up there's nothing past due, and nothing upcoming, then
  # sleep for a minute and return here. Somebody may have added a new task next
  # time we're called.
  if (@records == 0 and not $sleep) {
    $sleep = 60;
  } # if

  return ($sleep, @records);
} # GetWork

sub GetUniqueList($$) {
  my ($self, $table, $field) = @_;

  my ($err, $msg);

  my $statement = "select $field from $table group by $field";

  my $sth = $self->{db}->prepare($statement);

  unless ($sth) {
    ($err, $msg) = $self->_dberror('Unable to prepare statement', $statement);

    croak $msg;
  } # if

  my $status = $sth->execute;

  unless ($status) {
    ($err, $msg) = $self->_dberror('Unable to execute statement', $statement);

    croak $msg;
  } # if

  my @values;

  while (my @row = $sth->fetchrow_array) {
    if ($row[0]) {
      push @values, $row[0];
    } else {
      push @values, '<NULL>';
    } # if
  } # for

  return @values;
} # GetUniqueList

sub AddAlert(%) {
  my ($self, %alert) = @_;

  my @requiredFields = (
    'name',
    'type',
  );

  my $result = _checkRequiredFields \@requiredFields, \%alert;

  return -1, "AddAlert: $result"
    if $result;

  return $self->_addRecord('alert', %alert);
} # AddAlert

sub DeleteAlert($) {
  my ($self, $name) = @_;

  return $self->_deleteRecord('alert', "name='$name'");
} # DeleteAlert

sub FindAlert(;$) {
  my ($self, $alert) = @_;

  $alert ||= '';

  my $condition = "name like '%$alert%'";

  return $self->_getRecords('alert', $condition);
} # FindAlert

sub GetAlert($) {
  my ($self, $name) = @_;

  return
    unless $name;

  my @records = $self->_getRecords('alert', "name='$name'");

  if ($records[0]) {
    return %{$records[0]};
  } else {
    return;
  } # if
} # GetAlert

sub SendAlert($$$$$$$) {
  my (
    $self,
    $alert,
    $system,
    $notification,
    $subject,
    $message,
    $to,
    $runlogID,
  ) = @_;

  my $footing  = '<hr><p style="text-align: center;">';
     $footing .= '<font color="#bbbbbb">';
  my $year     = (localtime)[5] + 1900;
     $footing .= "<a href='$CLEAROPTS{CLEARADM_WEBBASE}'>Clearadm</a><br>";
     $footing .= "Copyright &copy; $year, ClearSCM, Inc. - All rights reserved";

  my %alert = $self->GetAlert($alert);

  if ($alert{type} eq 'email') {
    my $from = 'Clearadm@' . hostdomain;

    mail(
      from    => $from,
      to      => $to,
      subject => "Clearadm Alert: $system: $subject",
      mode    => 'html',
      data    => $message,
      footing => $footing,
    );
  } else {
    $self->Error("Don't know how to send $alert{type} alerts\n"
                . "Subject: $subject\n"
                . "Message: $message", 1);
  } # if

  # Log alert
  my %alertlog = (
    alert        => $alert,
    system       => $system,
    notification => $notification,
    runlog       => $runlogID,
    timestamp    => Today2SQLDatetime,
    message      => $subject,
  );

  return $self->AddAlertlog(%alertlog);
} # SendAlert

sub GetLastAlert($$) {
  my ($self, $notification, $system) = @_;

  my $statement = <<"END";
select
  runlog,
  timestamp
from
  alertlog
where
      notification='$notification'
  and system='$system'
order by
  timestamp desc
limit
  0, 1
END

  my $sth = $self->{db}->prepare($statement)
    or return $self->_dberror('Unable to prepare statement', $statement);

  $sth->execute
    or return $self->_dberror('Unable to execute statement', $statement);

  my $alertlog= $sth->fetchrow_hashref;

  $sth->finish;

  if ($alertlog) {
    return %$alertlog;
  } else {
    return;
  } # if
} # GetLastAlert

sub GetLastTaskFailure($$) {
  my ($self, $task, $system) = @_;

  my $statement = <<"END";
select
  id,
  ended
from
  runlog
where
      status <> 0
  and task='$task'
  and system='$system'
  and alerted='true'
order by
  ended desc
limit
  0, 1
END

  my $sth = $self->{db}->prepare($statement)
    or return $self->_dberror('Unable to prepare statement', $statement);

  $sth->execute
    or return $self->_dberror('Unable to execute statement', $statement);

  my $runlog= $sth->fetchrow_hashref;

  $sth->finish;

  if ($$runlog{ended}) {
    return %$runlog;
  } # if

  # If we didn't get any ended in the last call then there's nothing that
  # qualified. Still let's return a record (%runlog) that has a valid id so
  # that the caller can update that runlog with alerted = 'true'.
  $statement = <<"END";
select
  id
from
  runlog
where
      status <> 0
  and task='$task'
  and system='$system'
order by
  ended desc
limit
  0, 1
END

  $sth = $self->{db}->prepare($statement)
    or return $self->_dberror('Unable to prepare statement', $statement);

  $sth->execute
    or return $self->_dberror('Unable to execute statement', $statement);

  $runlog = $sth->fetchrow_hashref;

  $sth->finish;

  if ($runlog) {
    return %$runlog;
  } else {
    return
  } # if
} # GetLastTaskFailure

sub Notify($$$$$$) {
  my (
    $self,
    $notification,
    $subject,
    $message,
    $task,
    $system,
    $filesystem,
    $runlogID,
  ) = @_;

  $runlogID = $self->_getLastID
    unless $runlogID;

  my ($err, $msg);

  # Update filesystem, if $filesystem was specified
  if ($filesystem) {
    ($err, $msg) = $self->UpdateFilesystem(
      $system,
      $filesystem, (
        notification => $notification,
      ),
    );

    $self->Error("Unable to set notification for filesystem $system:$filesystem "
               . "(Status: $err)\n$msg", $err) if $err;
  } # if

  # Update system
  ($err, $msg) = $self->UpdateSystem(
    $system, (
      notification => $notification,
    ),
  );

  my %notification = $self->GetNotification($notification);

  my %lastnotified = $self->GetLastAlert($notification, $system);

  if (%lastnotified and $lastnotified{timestamp}) {
    my $today        = Today2SQLDatetime;
    my $lastnotified = $lastnotified{timestamp};

    if ($notification{nomorethan} =~ /hour/i) {
      $lastnotified = Add($lastnotified, (hours => 1));
    } elsif ($notification{nomorethan} =~ /day/i) {
      $lastnotified = Add($lastnotified, (days => 1));
    } elsif ($notification{nomorethan} =~ /week/i) {
      $lastnotified = Add($lastnotified, (days => 7));
    } elsif ($notification{nomorethan} =~ /month/i) {
      $lastnotified = Add($lastnotified, (month => 1));
    } # if

    # If you want to fake an alert in the debugger just change $diff accordingly
    my $diff = Compare($today, $lastnotified);

    return
      if $diff <= 0;
  } # if

  my $when       = Today2SQLDatetime;
  my $nomorethan = lc $notification{nomorethan};
  my %alert      = $self->GetAlert($notification{alert});
  my $to         = $alert{who};

  # If $to is null then this means to send the alert to the admin for the
  # machine.
  unless ($to) {
    if ($system) {
      my %system = $self->GetSystem($system);

      $to = $system{email};
    } else {
      # If we don't know what system this error occurred on we'll have to notify
      # the "super user" defined as $self->{NOTIFY} (The receiver of last
      # resort)
      $to = $self->{NOTIFY};
    } # if
  } # unless

  unless ($to) {
    Error "To undefined";
  } # unless

  $message .= "<p>You will receive this alert no more than $nomorethan.</p>";

  ($err, $msg) = $self->SendAlert(
    $notification{alert},
    $system,
    $notification{name},
    $subject,
    $message,
    $to,
    $runlogID,
  );

  $self->Error("Unable to send alert (Status: $err)\n$msg", $err) if $err;

  verbose "Sent alert to $to";

  # Update runlog to indicate we notified the user for this execution
  ($err, $msg) = $self->UpdateRunlog(
    $runlogID, (
      alerted => 'true',
    ),
  );

  $self->Error("Unable to update runlog (Status: $err)\n$msg", $err) if $err;

  return;
} # Notify

sub ClearNotifications($$;$) {
  my ($self, $system, $filesystem) = @_;

  my ($err, $msg);

  if ($filesystem) {
    ($err, $msg) = $self->UpdateFilesystem(
      $system,
      $filesystem, (notification => undef),
    );

    error "Unable to clear notification for filesystem $system:$filesystem "
        . "(Status: $err)\n$msg", $err
      if $err;

    # Check to see any of this system's filesystems have notifications. If none
    # then it's save to say we've turned off the last notification for a
    # filesystem involved with this system and if $system{notification} was
    # 'Filesystem' then we can toggle off the notification on the system too
    my $filesystemsAlerted = 0;

    for ($self->FindFilesystem($system)) {
      $filesystemsAlerted++
        if $$_{notification};
    } # for

    my %system = $self->GetSystem($system);

    return
      unless $system;

    if ($system{notification}                 and
        $system{notification} eq 'Filesystem' and
        $filesystemsAlerted == 0) {
      ($err, $msg) = $self->UpdateSystem($system, (notification => undef));

      $self->Error("Unable to clear notification for system $system "
                  . "(Status: $err)\n$msg", $err) if $err;
    } # if
  } else {
    ($err, $msg) = $self->UpdateSystem($system, (notification => undef));

    $self->Error("Unable to clear notification for system $system "
                . "(Status: $err)\n$msg", $err) if $err;
  } # if

  return;
} # ClearNotifications

sub SystemAlive(%) {
  my ($self, %system) = @_;

  # If we've never heard from this system then we will assume that the system
  # has not been set up to run clearagent and has never checked in. In any event
  # we cannot say the system died because we've never known it to be alive!
  return 1
    unless $system{lastheardfrom};

  # If a system is not active (may have been temporarily been deactivated) then
  # we don't want to turn on the bells and whistles alerting people it's down.
  return 1
    if $system{active} eq 'false';

  my $today         = Today2SQLDatetime;
  my $lastheardfrom = $system{lastheardfrom};

  my $tenMinutes = 10 * 60;

  $lastheardfrom = Add($lastheardfrom, (seconds => $tenMinutes));

  if (DateToEpoch($lastheardfrom) < DateToEpoch($today)) {
    $self->UpdateSystem(
      $system{name}, (
        notification => 'Heartbeat'
      ),
    );

    return;
  } else {
    if ($system{notification}) {
      $self->UpdateSystem(
        $system{name}, (
          notification => undef
        ),
      );
    }
    return 1;
  } # if
} # SystemAlive

sub UpdateAlert($%) {
  my ($self, $name, %update) = @_;

  return $self->_updateRecord(
    'alert',
    "name='$name'",
    %update
  );
} # UpdateAlert

sub AddAlertlog(%) {
  my ($self, %alertlog) = @_;

  my @requiredFields = (
    'alert',
    'notification',
  );

  my $result = _checkRequiredFields \@requiredFields, \%alertlog;

  return -1, "AddAlertlog: $result"
    if $result;

  # Timestamp record
  $alertlog{timestamp} = Today2SQLDatetime;

  return $self->_addRecord('alertlog', %alertlog);
} # AddAlertlog

sub DeleteAlertlog($) {
  my ($self, $condition) = @_;

  return
    unless $condition;

  if ($condition =~ /all/i) {
    return $self->_deleteRecord('alertlog');
  } else {
    return $self->_deleteRecord('alertlog', $condition);
  } # if
} # DeleteAlertlog

sub FindAlertlog(;$$$$$) {
  my ($self, $alert, $system, $notification, $start, $page) = @_;

  $alert        ||= '';
  $system       ||= '';
  $notification ||= '';

  my $condition  = "alert like '%$alert%'";
     $condition .= ' and ';
     $condition .= "system like '%$system%'";
     $condition .= ' and ';
     $condition .= "notification like '%$notification%'";
     $condition .= " order by timestamp desc";

     if (defined $start) {
       $page ||= 10;
       $condition .= " limit $start, $page";
     } # unless

  return $self->_getRecords('alertlog', $condition);
} # FindAlertLog

sub GetAlertlog($) {
  my ($self, $alert) = @_;

  return
    unless $alert;

  my @records = $self->_getRecords('alertlog', "alert='$alert'");

  if ($records[0]) {
    return %{$records[0]};
  } else {
    return;
  } # if
} # GetAlertlog

sub UpdateAlertlog($%) {
  my ($self, $alert, %update) = @_;

  return $self->_updateRecord(
    'alertlog',
    "alert='$alert'",
    %update
  );
} # UpdateAlertlog

sub AddNotification(%) {
  my ($self, %notification) = @_;

  my @requiredFields = (
    'name',
    'alert',
    'cond'
  );

  my $result = _checkRequiredFields \@requiredFields, \%notification;

  return -1, "AddNotification: $result"
    if $result;

  return $self->_addRecord('notification', %notification);
} # AddNotification

sub DeleteNotification($) {
  my ($self, $name) = @_;

  return $self->_deleteRecord('notification', "name='$name'");
} # DeletePackage

sub FindNotification(;$$) {
  my ($self, $name, $cond, $ordering) = @_;

  $name ||= '';

  my $condition  = "name like '%$name%'";
     $condition .= " and $cond"
       if $cond;

  return $self->_getRecords('notification', $condition);
} # FindNotification

sub GetNotification($) {
  my ($self, $name) = @_;

  return
    unless $name;

  my @records = $self->_getRecords('notification', "name='$name'");

  if ($records[0]) {
    return %{$records[0]};
  } else {
    return;
  } # if
} # GetNotification

sub UpdateNotification($%) {
  my ($self, $name, %update) = @_;

  return $self->_updateRecord(
    'notification',
    "name='$name'",
    %update
  );
} # UpdateNotification

sub AddVobStorage(%) {
  my ($self, %vobstorage) = @_;

  my @requiredFields = (
    'tag',
  );

  my $result = _checkRequiredFields \@requiredFields, \%vobstorage;

  return -1, "AddVobStorage: $result" if $result;

  # Timestamp record
  $vobstorage{timestamp} = Today2SQLDatetime;

  return $self->_addRecord('vobstorage', %vobstorage);
} # AddVobStorage

sub AddViewStorage(%) {
  my ($self, %viewstorage) = @_;

  my @requiredFields = (
    'tag',
  );

  my $result = _checkRequiredFields \@requiredFields, \%viewstorage;

  return -1, "AddViewStorage: $result" if $result;

  # Timestamp record
  $viewstorage{timestamp} = Today2SQLDatetime;

  return $self->_addRecord('viewstorage', %viewstorage);
} # AddViewStorage

1;

=pod

=head1 CONFIGURATION AND ENVIRONMENT

DEBUG: If set then $debug is set to this level.

VERBOSE: If set then $verbose is set to this level.

TRACE: If set then $trace is set to this level.

=head1 DEPENDENCIES

=head2 Perl Modules

L<Carp>

L<DBI>

L<FindBin>

L<Net::Domain|Net::Domain>

=head2 ClearSCM Perl Modules

=begin man

 DateUtils
 Display
 GetConfig
 Mail

=end man

=begin html

<blockquote>
<a href="http://clearscm.com/php/scm_man.php?file=lib/DateUtils.pm">DateUtils</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Display.pm">Display</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/GetConfig.pm">GetConfig</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Mail.pm">Mail</a><br>
</blockquote>

=end html

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, ClearSCM, Inc. All rights reserved.

=cut
