=pod

=head1 NAME $RCSfile: CCDB.pm,v $

Object oriented interface to CCDB.

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.4 $

=item Created

Wed Mar  9 17:03:48 PST 2011

=item Modified

$Date: 2011/04/15 22:27:45 $

=back

=head1 SYNOPSIS

Provides the CCDB object which handles all interaction with the CCDB
database. Similar add/change/delete/update methods for other record types. In
general you must orient your record hashs to have the appropriately named
keys that correspond to the database. Also see method documentation for
specifics about the method you are envoking.

 # Create new CCDB object
 my $ccdb= new CCDB;
 
 # Add a new system
 my %project= (
  name        => 'The Next Thing',
  pvob        => '8800_projects',
  description => 'This is the greatest thing since sliced bread',
 );
 
 my ($err, $msg) = $CCDB->AddProject (%project);
 
 # Find projects matching '8800'
 my @projects = $ccdb->FindProject ('8800');
 
 # Get a project by name
 my %project = $ccdb->GetProject ('8800_projects');
 
 # Update project
 my %update = (
  'description' => 'Greatest thing since the net!',
 );

 my ($err, $msg) = $ccdb->UpdateProject ('8800_projects', %update);
 
 # Delete project (Warning: will delete all related records regarding this
 # project).
 my ($err, $msg) = $ccdb->DeleteProject ('8800_projects');

=head1 DESCRIPTION

This package provides and object oriented interface to the CCDB database.
Methods are provided to manipulate records by adding, updating and deleting 
them. In general you need to specify a hash which contains keys and values 
corresponding to the database field names and values.

=head1 ROUTINES

The following methods are available:

=cut

package CCDB;

use strict;
use warnings;

use Carp;
use DBI;

use FindBin;

use lib "$FindBin::Bin/../../lib";

use Clearcase;
use DateUtils;
use Display;
use GetConfig;

our %CCDBOPTS = GetConfig ("$FindBin::Bin/../etc/ccdb.conf");

$CCDBOPTS{CCDB_MY_CNF} = "$FindBin::Bin/etc/$CCDBOPTS{CCDB_MY_CNF}"; 

# Globals
our $VERSION  = '$Revision: 1.4 $';
   ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);
  
$CCDBOPTS{CCDB_USERNAME} = $ENV{CCDB_USERNAME} 
                         ? $ENV{CCDB_USERNAME}
                         : $CCDBOPTS{CCDB_USERNAME}
                         ? $CCDBOPTS{CCDB_USERNAME}
                         : '<specify username>';
$CCDBOPTS{CCDB_PASSWORD} = $ENV{CCDB_PASSWORD} 
                         ? $ENV{CCDB_PASSWORD}
                         : $CCDBOPTS{CCDB_PASSWORD}
                         ? $CCDBOPTS{CCDB_PASSWORD}
                         : '<specify password>';
$CCDBOPTS{CCDB_SERVER}   = $ENV{CCDB_SERVER} 
                         ? $ENV{CCDB_SERVER} 
                         : $CCDBOPTS{CCDB_SERVER}
                         ? $CCDBOPTS{CCDB_SERVER}
                         : '<specify server>';

# Internal methods
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
  foreach (@values) {
    if ($_) {
      unless ($_ eq '') {
        push @returnValues, $self->{db}->quote ($_);
        next;
      } # unless
    } # if

    push @returnValues, 'null';
  } # foreach
    
  return @returnValues;
} # _formatValues

sub _formatNameValues (%) {
  my ($self, %rec) = @_;
  
  my @nameValueStrs;
  
  push @nameValueStrs, "$_=" . $self->{db}->quote ($rec{$_})
    foreach (keys %rec);
    
  return @nameValueStrs;
} # _formatNameValues

sub _addRecord ($%) {
  my ($self, $table, %rec) = @_;
  
  my $statement  = "insert into $table (";
     $statement .= join ',', keys %rec;
     $statement .= ') values (';
     $statement .= join ',', $self->_formatValues (values %rec);
     $statement .= ')';
  
  $self->{db}->do ($statement);
  
  return $self->_dberror ("Unable to add record to $table", $statement);
} # _addRecord

sub _deleteRecord ($;$) {
  my ($self, $table, $condition) = @_;
  
  my $count;
  
  my $statement  = "select count(*) from $table ";
     $statement .= "where $condition"
      if $condition;
  
  my $sth = $self->{db}->prepare ($statement)
    or return $self->_dberror ('Unable to prepare statement', $statement);
    
  $sth->execute
    or return $self->_dberror ('Unable to execute statement', $statement);
    
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
  
  $self->{db}->do ($statement);
  
  if ($self->{db}->err) {
    return $self->_dberror ("Unable to delete record from $table", $statement);
  } else {
    return $count, 'Records deleted';
  } # if
} # _deleteRecord

sub _updateRecord ($$%) {
  my ($self, $table, $condition, %rec) = @_;
  
  my $statement  = "update $table set ";
     $statement .= join ',', $self->_formatNameValues (%rec);
     $statement .= " where $condition"
       if $condition;
  
  $self->{db}->do ($statement);
  
  return $self->_dberror ("Unable to update record in $table", $statement);
} # _updateRecord

sub _checkRequiredFields ($$) {
  my ($fields, $rec) = @_;
  
  foreach my $fieldname (@$fields) {
    my $found = 0;
    
    foreach (keys %$rec) {
      if ($fieldname eq $_) {
      	 $found = 1;
      	 last;
      } # if
    } # foreach
    
    return "$fieldname is required"
      unless $found;
  } # foreach
  
  return;
} # _checkRequiredFields

sub _getRecords ($$) {
  my ($self, $table, $condition) = @_;
  
  my ($err, $msg);
    
  my $statement = "select * from $table where $condition";
  
  my $sth = $self->{db}->prepare ($statement);
  
  unless ($sth) {
    ($err, $msg) = $self->_dberror ('Unable to prepare statement', $statement);
    
    croak $msg;
  } # if
    
  my $status = $sth->execute;
  
  unless ($status) {
    ($err, $msg) = $self->_dberror ('Unable to execute statement', $statement);
    
    croak $msg;
  } # if
    
  my @records;
  
  while (my $row = $sth->fetchrow_hashref) {
    push @records, $row;
  } # while
  
  return @records;
} # _getRecord

sub _getLastID () {
  my ($self) = @_;
  
  my $statement = 'select last_insert_id()';
  
  my $sth = $self->{db}->prepare ($statement);
  
  my ($err, $msg);
  
  unless ($sth) {
    ($err, $msg) = $self->_dberror ('Unable to prepare statement', $statement);
    
    croak $msg;
  } # if
    
  my $status = $sth->execute;
  
  unless ($status) {
    ($err, $msg) = $self->_dberror ('Unable to execute statement', $statement);
    
    croak $msg;
  } # if
    
  my @records;

  my @row = $sth->fetchrow_array;
  
  return $row[0];
} # _getLastID

sub new (;$) {
  my ($class, $dbserver) = @_;

  $dbserver ||= $CCDBOPTS{CCDB_SERVER};
  
  my $self = bless {}, $class;

  my $dbname   = 'ccdb';
  my $dbdriver = 'mysql';

  $self->{db} = DBI->connect (
    "DBI:$dbdriver:$dbname:$dbserver;"
  . "mysql_read_default_file=$CCDBOPTS{CCDB_MY_CNF}",
    $CCDBOPTS{CCDB_USERNAME},
    $CCDBOPTS{CCDB_PASSWORD},
    {PrintError => 0},
  ) or croak (
    "Couldn't connect to $dbname database " 
  . "as $CCDBOPTS{CCDB_USERNAME}\@$dbserver\nDBERR: $DBI::errstr"
  );

  return $self;
} # new

sub AddRecord ($$$) {
  my ($self, $record, $required, $data) = @_;
  
  my $Record         = ucfirst $record;
  my @requiredFields = @$required;

  unless (ref $data eq 'HASH') {
    my $VAR1;
    
    eval $data;
    
    $data = $VAR1;
  } # unless
  
  my %data = %$data;

  # Determine oid if necessary
  unless ($data{oid}) {
    if ($record eq 'activity' 
     or $record eq 'baseline'
     or $record eq 'folder',
     or $record eq 'project'
     or $record eq 'stream'
     or $record eq 'replica'
     or $record eq 'vob') {
       
      if ($record eq 'vob') {
        $data{oid} = $Clearcase::CC->name2oid (
          'vob:' . Clearcase::vobtag ($data{name})
        );
      } elsif ($record eq 'replica') {
        $data{oid} = $Clearcase::CC->name2oid (
          "replica:$data{replica}", $data{vob}
        );
      } else {
        $data{oid} = $Clearcase::CC->name2oid (
          "$record:$data{name}", $data{pvob}
        );
      } # if
    } # if
  } # unless
  
  my $result = _checkRequiredFields \@requiredFields, \%data;
  
  return -1, "Add$Record: $result"
    if $result;
  
  return $self->_addRecord ($record, %data);
} # AddRecord

sub DeleteRecord ($$$) {
  my ($self, $table, $keyname, $keyvalue) = @_;

  # If $keyname is an array then we have multiple keys in the database. When
  # this is the case we assume that both $keyname and $keyvalue are references
  # to equal sized name/value pairs and we construct the condition in the form
  # of "<keyname1>=<keyvalue1> and <keyname2>=<keyvalue2>..."
  my $condition;
  
  if (ref $keyname eq 'ARRAY') {
    for (my $i = 0; $i < @$keyname; $i++) {
      unless ($condition) {
        $condition = "$$keyname[$i]='$$keyvalue[$i]'"
      } else {
        $condition .= " and $$keyname[$i]='$$keyvalue[$i]'"
      } # if
    } # for
  } else {
    $condition = "$keyname='$keyvalue'";
  } # if

  return $self->_deleteRecord ($table, $condition);  
} # DeleteRecord

sub UpdateRecord ($$$$) {
  my ($self, $table, $keyname, $keyvalue, $update) = @_;

  # If $keyname is an array then we have multiple keys in the database. When
  # this is the case we assume that both $keyname and $keyvalue are references
  # to equal sized name/value pairs and we construct the condition in the form
  # of "<keyname1>=<keyvalue1> and <keyname2>=<keyvalue2>..."
  my $condition;
  
  if (ref $keyname eq 'ARRAY') {
    for (my $i = 0; $i < @$keyname; $i++) {
      unless ($condition) {
        $condition = "$$keyname[$i] like '$$keyvalue[$i]'"
      } else {
        $condition .= " and $$keyname[$i] like '$$keyvalue[$i]'"
      } # if
    } # for
  } else {
    $condition = "$keyname like '$keyvalue'";
  } # if
  
  unless (ref $update eq 'HASH') {
    my $VAR1;
    
    eval $update;
    
    $update = $VAR1;
  } # unless
  
  my %update = %$update;
    
  return $self->_updateRecord ($table, $condition, %update);
} # UpdateRecord

sub GetRecord ($$$) {
  my ($self, $table, $keyname, $keyvalue) = @_;
  
  # If $keyname is an array then we have multiple keys in the database. When
  # this is the case we assume that both $keyname and $keyvalue are references
  # to equal sized name/value pairs and we construct the condition in the form
  # of "<keyname1>=<keyvalue1> and <keyname2>=<keyvalue2>..."
  my $condition;
  
  if (ref $keyname eq 'ARRAY') {
    for (my $i = 0; $i < @$keyname; $i++) {
      $$keyvalue[$i] ||= '';
      
      unless ($condition) {
        $condition = "$$keyname[$i]='$$keyvalue[$i]'"
      } else {
        $condition .= " and $$keyname[$i]='$$keyvalue[$i]'"
      } # if
    } # for
  } else {
    $condition = "$keyname='$keyvalue'";
  } # if
  
  my @records = $self->_getRecords ($table, $condition);
  
  if ($records[0]) {
    return %{$records[0]};
  } else {
    return;
  } # if
} # GetRecord

sub FindRecord ($$$;$) {
  my ($self, $table, $keyname, $keyvalue, $additional) = @_;

  # If $keyname is an array then we have multiple keys in the database. When
  # this is the case we assume that both $keyname and $keyvalue are references
  # to equal sized name/value pairs and we construct the condition in the form
  # of "<keyname1> like <keyvalue1> and <keyname2> like <keyvalue2>..."
  my $condition;
  
  if (ref $keyname eq 'ARRAY') {
    for (my $i = 0; $i < @$keyname; $i++) {
      $$keyvalue[$i] ||= '';
      $$keyvalue[$i] = '' if $$keyvalue[$i] eq '*';
      
      unless ($condition) {
        $condition = "$$keyname[$i] like '%$$keyvalue[$i]%'"
      } else {
        $condition .= " and $$keyname[$i] like '%$$keyvalue[$i]%'"
      } # if
    } # for
  } else {
    $keyvalue ||= '';
    $keyvalue = '' if $keyvalue eq '*';
    $condition = "$keyname like '%$keyvalue%'";
  } # if
  
  return $self->_getRecords ($table, $condition);
} # FindRecord

sub AddProject ($) {
  my ($self, $data) = @_;
  
  return $self->AddRecord (
    'project',
    ['name', 'folder', 'pvob'],
    $data
  );
} # AddProject

sub DeleteProject ($$$) {
  my ($self, $name, $folder, $pvob) = @_;

  return $self->DeleteRecord (
    'project', 
    ['name', 'folder', 'pvob'],
    [$name, $folder, $pvob]
  );  
} # DeleteProject

sub UpdateProject ($$$$) {
  my ($self, $name, $folder, $pvob, $update) = @_;

  return $self->UpdateRecord (
    'project',
    ['name', 'folder', 'pvob'],
    [$name, $folder, $pvob], 
    $update
  );
} # UpdateRegistry

sub GetProject ($) {
  my ($self, $name, $folder, $pvob) = @_;
  
  return $self->GetRecord (
    'project', 
    ['name', 'folder', 'pvob'],
    [$name, $folder, $pvob]
  );
} # GetProject

sub FindProject (;$$$) {
  my ($self, $name, $folder, $project, $pvob) = @_;
  
  return $self->FindRecord (
    'project',
    ['name', 'folder', 'pvob'],
    [$name, $folder, $pvob]
  );
} # FindProject

sub AddRegistry ($) {
  my ($self, $data) = @_;
  
  return $self->AddRecord (
    'registry',
    ['name'],
    $data
  );
} # AddRegistry

sub DeleteRegistry ($) {
  my ($self, $name) = @_;

  return $self->DeleteRecord ('registry', 'name', $name);  
} # DeleteRegistry

sub UpdateRegistry ($$) {
  my ($self, $name, $update) = @_;

  return $self->UpdateRecord ('registry', 'name', $name, $update);
} # UpdateRegistry

sub GetRegistry ($) {
  my ($self, $name) = @_;
  
  return $self->GetRecord ('registry', 'name', $name);
} # GetRegistry

sub FindRegistry (;$) {
  my ($self, $name) = @_;
  
  return $self->FindRecord ('registry', 'name', $name);
} # FindRegistry

sub AddStream ($) {
  my ($self, $data) = @_;
  
  # TODO: We should probably make sure that things like $$data{pvob} and
  # $$data{name} exist in $data first. Maybe add the record (which checks for
  # required fields) then perform an update to update the type to intergration
  # IFF this is an intergration stream.
  
  # Determine the integration stream for this stream's project. First get
  # project for the stream.
  my $pvobTag = Clearcase::vobtag ($$data{pvob});
  my $cmd     = "lsstream -fmt \"%[project]p\" $$data{name}\@$pvobTag";
  
  my ($status, @output) = $Clearcase::CC->execute ($cmd);

  if ($status == 0) {
    my $project = $output[0];
  
    # Now get the intergration stream for this project
    $cmd = "lsproject -fmt \"%[istream]p\" $project\@$pvobTag";
  
    ($status, @output) = $Clearcase::CC->execute ($cmd);
    
    if ($status == 0) {
      $$data{type} = 'integration'
        if $$data{name} eq $output[0];
    } # if
  } # if
      
  return $self->AddRecord (
    'stream',
    ['name', 'pvob'],
    $data
  );
} # AddStream

sub DeleteStream ($$) {
  my ($self, $name, $pvob) = @_;

  return $self->DeleteRecord (
    'stream', 
    ['name', 'pvob'],
    [$name, $pvob],
  );  
} # DeleteStream

sub DeleteStreamOID ($) {
  my ($self, $oid) = @_;
  
  return $self->DeleteRecord (
    'stream',
    'oid',
    $oid
  );
} # DeleteStreamOID

sub UpdateStream ($$$) {
  my ($self, $name, $pvob, $update) = @_;

  return $self->UpdateRecord (
    'stream', 
    ['name', 'pvob'], 
    [$name, $pvob],
    $update
  );
} # UpdateStream

sub GetStream ($$) {
  my ($self, $name, $pvob) = @_;
  
  return $self->GetRecord (
    'stream', 
    ['name', 'pvob'],
    [$name, $pvob],
  );
} # GetRegistry

sub FindStream (;$$) {
  my ($self, $name, $pvob) = @_;
  
  return $self->FindRecord (
    'stream', 
    ['name', 'pvob'], 
    [$name, $pvob]
  );
} # FindRegistry

sub AddSubfolder ($) {
  my ($self, $data) = @_;
  
  return $self->AddRecord (
    'subfolder',
    ['parent', 'subfolder', 'pvob'],
    $data
  );
} # AddSubfolder

sub DeleteSubfolder ($$$) {
  my ($self, $parent, $subfolder, $pvob) = @_;

  return $self->DeleteRecord (
    'subfolder', 
    ['parent', 'subfolder', 'pvob'],
    [$parent, $subfolder, $pvob],
  );  
} # DeleteSubfolder

sub UpdateSubfolder ($$$$) {
  my ($self, $parent, $subfolder, $pvob, $update) = @_;

  return $self->UpdateRecord (
    'subfolder', 
    ['parent', 'subfolder', 'pvob'], 
    [$parent, $subfolder, $pvob],
    $update
  );
} # UpdateSubfolder

sub GetSubfolder ($$$) {
  my ($self, $parent, $subfolder, $pvob) = @_;
  
  return $self->GetRecord (
    'subfolder', 
    ['parent', 'subfolder', 'pvob'],
    [$parent, $subfolder, $pvob],
  );
} # GetSubfolder

sub FindSubfolder (;$$$) {
  my ($self, $parent, $subfolder, $pvob) = @_;
  
  return $self->FindRecord (
    'subfolder', 
    ['parent', 'subfolder', 'pvob'], 
    [$parent, $subfolder, $pvob]
  );
} # FindFolder

sub AddActivity ($) {
  my ($self, $data) = @_;
  
  if ($$data{name}) {
    $$data{type} = 'integration'
      if $$data{name} =~ /^(deliver|rebase|integrate|revert|tlmerge)/i;
  } # if
  
  return $self->AddRecord (
    'activity',
    ['name', 'pvob'],
    $data
  );
} # AddActivity

sub DeleteActivity ($$) {
  my ($self, $name, $pvob) = @_;

  return $self->DeleteRecord (
    'activity', 
    ['name', 'pvob'],
    [$name, $pvob],
  );  
} # DeleteActivity

sub DeleteActivityOID ($) {
  my ($self, $oid) = @_;
  
  return $self->DeleteRecord (
    'activity',
    'name',
    $oid
  );
} # DeleteActivityOID

sub UpdateActivity ($$$) {
  my ($self, $name, $pvob, $update) = @_;

  return $self->UpdateRecord (
    'activity', 
    ['name', 'pvob'], 
    [$name, $pvob],
    $update
  );
} # UpdateActivity

sub GetActivity ($$) {
  my ($self, $name, $pvob) = @_;
  
  return $self->GetRecord (
    'activity', 
    ['name', 'pvob'],
    [$name, $pvob],
  );
} # GetActivity

sub FindActivity (;$$) {
  my ($self, $name, $pvob) = @_;
  
  return $self->FindRecord (
    'activity', 
    ['name', 'pvob'], 
    [$name, $pvob]
  );
} # FindActivity

sub AddBaseline ($) {
  my ($self, $data) = @_;
  
  return $self->AddRecord (
    'baseline',
    ['name', 'pvob'],
    $data
  );
} # AddBaseline

sub DeleteBaseline ($$) {
  my ($self, $name, $pvob) = @_;

  return $self->DeleteRecord (
    'baseline', 
    ['name', 'pvob'],
    [$name, $pvob],
  );  
} # DeleteBaseline

sub DeleteBaselineOID ($) {
  my ($self, $oid) = @_;
  
  return $self->DeleteRecord (
    'baseline',
    'oid',
    $oid,
  );
} # DeleteBaselineOID

sub UpdateBaseline ($$$) {
  my ($self, $name, $pvob, $update) = @_;

  return $self->UpdateRecord (
    'baseline', 
    ['name', 'pvob'], 
    [$name, $pvob],
    $update
  );
} # UpdateBaseline

sub GetBaseline ($$) {
  my ($self, $name, $pvob) = @_;
  
  return $self->GetRecord (
    'baseline', 
    ['name', 'pvob'],
    [$name, $pvob],
  );
} # GetBaseline

sub FindBaseline (;$$) {
  my ($self, $name, $pvob) = @_;
  
  return $self->FindRecord (
    'baseline', 
    ['name', 'pvob'], 
    [$name, $pvob]
  );
} # FindBaseline

sub DeleteElementAll ($) {
  my ($self, $name) = @_;
  
  my ($total, $err, $msg);
  
  foreach ($self->FindChangeset (undef, $name)) {
    my %changeset = %$_;
    
    ($err, $msg) = $self->DeleteChangeset (
      $changeset{activity},
      $changeset{name},
      $changeset{version},
      $changeset{pvob},
    );
    
    return ($err, $msg)
      if $msg ne 'Records deleted';
      
    $total += $err;
  } # foreach
  
  return ($total, $msg);
} # DeleteElementAll

sub AddChangeset ($) {
  my ($self, $data) = @_;
  
  return $self->AddRecord (
    'changeset',
    ['activity', 'element', 'version', 'pvob'],
    $data
  );
} # AddChangeset

sub DeleteChangeset ($$$$) {
  my ($self, $activity, $element, $version, $pvob) = @_;

  return $self->DeleteRecord (
    'changeset', 
    ['activity', 'element', 'version', 'pvob'],
    [$activity, $element, $version, $pvob],
  );  
} # DeleteChangeset

sub UpdateChangeset ($$$$$) {
  my ($self, $activity, $element, $version, $pvob, $update) = @_;

  return $self->UpdateRecord (
    'changeset', 
    ['activity', 'element', 'version', 'pvob'], 
    [$activity, $element, $version, $pvob],
    $update
  );
} # UpdateChangeset

sub GetChangeset ($$$$) {
  my ($self, $activity, $element, $version, $pvob) = @_;
  
  return $self->GetRecord (
    'changeset', 
    ['activity', 'element', 'version', 'pvob'],
    [$activity, $element, $version, $pvob],
  );
} # GetChangeset

sub FindChangeset (;$$$$) {
  my ($self, $activity, $element, $version, $pvob) = @_;
  
  return $self->FindRecord (
    'changeset', 
    ['activity', 'element', 'version', 'pvob'], 
    [$activity, $element, $version, $pvob]
  );
} # FindChangeset

sub AddFolder ($) {
  my ($self, $data) = @_;
  
  return $self->AddRecord (
    'folder',
    ['name', 'pvob'],
    $data
  );
} # AddFolder

sub DeleteFolder ($$) {
  my ($self, $folder, $pvob) = @_;

  return $self->DeleteRecord (
    'folder', 
    ['name', 'pvob'],
    [$folder, $pvob],
  );  
} # DeleteFolder

sub UpdateFolder ($$$) {
  my ($self, $name, $pvob, $update) = @_;

  return $self->UpdateRecord (
    'folder', 
    ['name', 'pvob'], 
    [$name, $pvob],
    $update
  );
} # UpdateFolder

sub GetFolder ($$) {
  my ($self, $name, $pvob) = @_;
  
  return $self->GetRecord (
    'folder', 
    ['name', 'pvob'],
    [$name, $pvob],
  );
} # GetFolder

sub FindFolder (;$$) {
  my ($self, $name, $pvob) = @_;
  
  return $self->FindRecord (
    'folder', 
    ['name', 'pvob'], 
    [$name, $pvob]
  );
} # FindFolder

sub AddVob ($) {
  my ($self, $data) = @_;
  
  return $self->AddRecord (
    'vob',
    ['name'],
    $data
  );
} # AddVob

sub DeleteVob ($) {
  my ($self, $name) = @_;

  return $self->DeleteRecord (
    'vob', 
    ['name'],
    $name,
  );  
} # DeleteVob

sub UpdateVob ($$) {
  my ($self, $name, $update) = @_;

  return $self->UpdateRecord ('vob', 'name', $name, $update);
} # UpdateVob

sub GetVob ($) {
  my ($self, $name) = @_;
  
  return $self->GetRecord (
    'vob', 
    'name',
    $name,
  );
} # GetVob

sub FindVob (;$$) {
  my ($self, $name, $type) = @_;
  
  $type ||= '';
  
  return $self->FindRecord (
    'vob', 
    ['name', 'type'],
    [$name, $type],
  );
} # FindVob

sub AddStreamActivityXref ($) {
  my ($self, $data) = @_;
  
  return $self->AddRecord (
    'stream_activity_xref',
    ['stream', 'activity', 'pvob'],
    $data
  );
} # AddStreamActivityXref

sub DeleteStreamActivityXref ($$$) {
  my ($self, $stream, $activity, $pvob) = @_;

  return $self->DeleteRecord (
    'stream_activity_xref', 
    ['stream', 'activity', 'pvob'],
    [$stream, $activity, $pvob],
  );  
} # DeleteStreamActivityXref

sub UpdateStreamActivityXref ($$$$) {
  my ($self, $stream, $activity, $pvob, $update) = @_;

  return $self->UpdateRecord (
    'stream_activity_xref', 
    ['stream', 'activity', 'pvob'], 
    [$stream, $activity, $pvob],
    $update
  );
} # UpdateStreamActivityXref

sub GetStreamActivityXref ($$$) {
  my ($self, $stream, $activity, $pvob) = @_;
  
  return $self->GetRecord (
    'stream_activity_xref', 
    ['stream', 'activity', 'pvob'],
    [$stream, $activity, $pvob],
  );
} # GetStreamActivityXref

sub FindStreamActivityXref (;$$$) {
  my ($self, $stream, $activity, $pvob) = @_;
  
  return $self->FindRecord (
    'stream_activity_xref', 
    ['stream', 'activity', 'pvob'], 
    [$stream, $activity, $pvob]
  );
} # FindStreamActivityXref

sub AddStreamBaselineXref ($) {
  my ($self, $data) = @_;
  
  return $self->AddRecord (
    'stream_baseline_xref',
    ['stream', 'baseline', 'pvob'],
    $data
  );
} # AddStreamBaselineXref

sub DeleteStreamBaselineXref ($$$) {
  my ($self, $stream, $baseline, $pvob) = @_;

  return $self->DeleteRecord (
    'stream_baseline_xref', 
    ['stream', 'baseline', 'pvob'],
    [$stream, $baseline, $pvob],
  );  
} # DeleteStreamBaselineXref

sub UpdateStreamBaselineXref ($$$$) {
  my ($self, $stream, $baseline, $pvob, $update) = @_;

  return $self->UpdateRecord (
    'stream_baseline_xref', 
    ['stream', 'baseline', 'pvob'], 
    [$stream, $baseline, $pvob],
    $update
  );
} # UpdateStreamBaselineXref

sub GetStreamBaselineXref ($$$) {
  my ($self, $stream, $baseline, $pvob) = @_;
  
  return $self->GetRecord (
    'stream_baseline_xref', 
    ['stream', 'baseline', 'pvob'],
    [$stream, $baseline, $pvob],
  );
} # GetStreamBaselineXref

sub FindStreamBaselineXref (;$$$) {
  my ($self, $stream, $baseline, $pvob) = @_;
  
  return $self->FindRecord (
    'stream_baseline_xref', 
    ['stream', 'baseline', 'pvob'], 
    [$stream, $baseline, $pvob]
  );
} # FindStreamBaselineXref

sub AddBaselineActivityXref ($) {
  my ($self, $data) = @_;
  
  return $self->AddRecord (
    'baseline_activity_xref',
    ['baseline', 'activity', 'pvob'],
    $data
  );
} # AddBaselineActivityXref

sub DeleteBaselineActivityXref ($$$) {
  my ($self, $baseline, $activity, $pvob) = @_;

  return $self->DeleteRecord (
    'baseline_activity_xref', 
    ['baseline', 'activity', 'pvob'],
    [$baseline, $activity, $pvob],
  );  
} # DeleteBaselineActivityXref

sub UpdateBaselineActivityXref ($$$$) {
  my ($self, $baseline, $activity, $pvob, $update) = @_;

  return $self->UpdateRecord (
    'baseline_activity_xref', 
    ['baseline', 'activity', 'pvob'], 
    [$baseline, $activity, $pvob],
    $update
  );
} # UpdateBaselineActivityXref

sub GetBaselineActivityXref ($$$$) {
  my ($self, $baseline, $activity, $pvob) = @_;
  
  return $self->GetRecord (
    'baseline_activity_xref', 
    ['baseline', 'activity', 'pvob'],
    [$baseline, $activity, $pvob],
  );
} # GetBaselineActivityXref

sub FindBaselineActivityXref (;$$$$) {
  my ($self, $baseline, $activity, $pvob) = @_;
  
  return $self->FindRecord (
    'baseline_activity_xref', 
    ['baseline', 'activity', 'pvob'], 
    [$baseline, $activity, $pvob]
  );
} # FindBaselineActivityXref

sub FindActivities ($$$) {
  my ($self, $pvob, $stream, $element) = @_;
  
  my $statement = <<"END";
select 
  aex.activity
from
  changeset             as cs,
  stream_activity_xref  as sax
where
  cs.pvob     =    sax.pvob     and
  cs.activity =    sax.activity and
  cs.pvob     =    '$pvob'      and
  sax.stream  =    '$stream'    and
  cs.element  like '$element%'
group by
  cs.activity
END

  my $sth = $self->{db}->prepare ($statement);
  
  my ($err, $msg);
  
  unless ($sth) {
    ($err, $msg) = $self->_dberror ('Unable to prepare statement', $statement);
    
    croak $msg;
  } # if
    
  my $status = $sth->execute;
  
  unless ($status) {
    ($err, $msg) = $self->_dberror ('Unable to execute statement', $statement);
    
    croak $msg;
  } # if
    
  my @records;
  
  while (my $row = $sth->fetchrow_hashref) {
    push @records, $row;
  } # while
  
  return @records;  
} # FindActivities

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

L<DBI>

=head2 ClearSCM Perl Modules

=begin man 

 DateUtils
 Display
 GetConfig

=end man

=begin html

<blockquote>
<a href="http://clearscm.com/php/cvs_man.php?file=lib/DateUtils.pm">DateUtils</a><br>
<a href="http://clearscm.com/php/cvs_man.php?file=lib/Display.pm">Display</a><br>
<a href="http://clearscm.com/php/cvs_man.php?file=lib/GetConfig.pm">GetConfig</a><br>
</blockquote>

=end html

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011, ClearSCM, Inc. All rights reserved.

=cut
