=pod

=head1 NAME $RCSfile: Machines.pm,v $

Abstraction of machines.

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.4 $

=item Created

Tue Jan  8 17:24:16 MST 2008

=item Modified

$Date: 2011/11/16 19:46:13 $

=back

=head1 SYNOPSIS

This module handles the details of providing information about
machines while obscuring the mechanism for storing such information.

 my $machines = Machines->new;

 foreach ($machine->all) {
   my %machine = %{$_};
   display "Machine: $machine{name}";
   disp.ay "Owner: $machine{owner}"
 } # if

=head1 DESCRIPTION

This module provides information about machines

=head1 ROUTINES

The following routines are exported:

=cut

package Machines;

use strict;
use warnings;

use Carp;
use DBI;
use FindBin;

use DateUtils;
use Display;
use GetConfig;

our %MACHINESOPTS = GetConfig ("$FindBin::Bin/../etc/machines.conf");

my $defaultFilesystemThreshold = 90;
my $defaultFilesystemHist      = '6 months';
my $defaultLoadavgHist         = '6 months';

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
  push @returnValues, $_ eq '' ? 'null' : $self->{db}->quote ($_)  
    foreach (@values);
  
  return @returnValues;
} # _formatValues

sub _formatNameValues (%) {
  my ($self, %rec) = @_;
  
  my @nameValueStrs;
  
  push @nameValueStrs, "$_=" . $self->{db}->quote ($rec{$_})
    foreach (keys %rec);
    
  return @nameValueStrs;
} # _formatNameValues

sub _error () {
  my ($self) = @_;
  
  if ($self->{msg}) {
    if ($self->{errno}) {
      carp $self->{msg};
    } else {
      cluck $self->{msg};
    } # if
  } # if
} # _error

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

sub _connect (;$) {
  my ($self, $dbserver) = @_;
  
  $dbserver ||= $MACHINESOPTS{MACHINES_SERVER};
  
  my $dbname   = 'machines';
  my $dbdriver = 'mysql';

  $self->{db} = DBI->connect (
    "DBI:$dbdriver:$dbname:$dbserver", 
    $MACHINESOPTS{MACHINES_USERNAME},
    $MACHINESOPTS{MACHINES_PASSWORD},
    {PrintError => 0},
  ) or croak (
    "Couldn't connect to $dbname database " 
  . "as $MACHINESOPTS{MACHINESADM_USERNAME}\@$MACHINESOPTS{MACHINESADM_SERVER}"
  );
  
  $self->{dbserver} = $dbserver;
  
  return;
} # _connect

sub _getRecords ($$) {
  my ($self, $table, $condition) = @_;
  
  my ($err, $msg);
    
  my $statement = "select * from $table where $condition";
  
  my $sth = $self->{db}->prepare ($statement);
  
  unless ($sth) {
    ($err, $msg) = $self->_dberror ('Unable to prepare statement', $statement);
    
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
      ($err, $msg) = $self->_dberror ('Unable to execute statement',
                                      $statement);
    } # if
    
    last if $err == 0;
    
    croak $msg unless $err == 2006;

    my $timestamp = YMDHMS;
      
    $self->Error ("$timestamp: Unable to talk to DB server.\n\n$msg\n\n"
                . "Will try again in $sleepTime seconds", -1);
                
    # Try to reconnect
    $self->_connect ($self->{dbserver});

    sleep $sleepTime;
  } # while

  $self->Error ("After $maxAttempts attempts I could not connect to the database", $err)
    if ($err == 2006 and $attempts > $maxAttempts);
  
  my @records;
  
  while (my $row = $sth->fetchrow_hashref) {
    push @records, $row;
  } # while
  
  return @records;
} # _getRecord


sub new {
  my ($class, %parms) = @_;

=pod

=head2 new ($server)

Construct a new Machines object.

=cut

  # Merge %parms with %MACHINEOPTS
  foreach (keys %parms) {
    $MACHINESOPTS{$_} = $parms{$_};
  } # foreach;
  
  my $self = bless {}, $class;
  
  $self->_connect ();
  
  return $self;
} # new

sub add (%) {
  my ($self, %system) = @_;
  
  my @requiredFields = qw(
    name
    admin
    type
  );

  my $result = _checkRequiredFields \@requiredFields, \%system;
  
  return -1, "add: $result" if $result;
  
  $system{loadavgHist} ||= $defaultLoadavgHist;
  
  return $self->_addRecord ('system', %system);
} # add

sub delete ($) {
  my ($self, $name) = @_;

  return $self->_deleteRecord ('system', "name='$name'");  
} # delete

sub update ($%) {
  my ($self, $name, %update) = @_;

  return $self->_updateRecord ('system', "name='$name'", %update);
} # update

sub get ($) {
  my ($self, $system) = @_;
  
  return unless $system;
  
  my @records = $self->_getRecords (
    'system', 
    "name='$system' or alias like '%$system%'"
  );
  
  if ($records[0]) {
    return %{$records[0]};
  } else {
        return;
  } # if
} # get

sub find (;$) {
  my ($self, $condition) = @_;

  return $self->_getRecords ('system', $condition);
} # find

1;

=pod

=head1 CONFIGURATION AND ENVIRONMENT

MACHINES: If set then points to a flat file containing machine
names. Note this is providied as a way to quickly use an alternate
"machine database". As such only minimal information is support.

=head1 DEPENDENCIES

 Display
 Rexec

=head1 INCOMPATABILITIES

None yet...

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head1 LICENSE AND COPYRIGHT

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
