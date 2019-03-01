#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use Getopt::Long;

use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

use Clearadm;
use Display;
use Utils;

my $clearadm = new Clearadm;

my %system = (
  name		=> 'jupiter',
  alias		=> 'defaria.com',
  admin		=> 'Andrew DeFaria',
  os		=> 'Linux defaria.com 2.6.32-25-generic-pae #45-Ubuntu SMP Sat Oct 16 21:01:33 UTC 2010 i686 GNU/Linux',
  type		=> 'Linux',
  description	=> 'Home server',
);

my %package = (
  'system'	=> 'jupiter',
  'name'	=> 'MySQL',
  'version'	=> '5.1',
);

my %update;

my %filesystem = (
  'system'	=> 'jupiter',
  'filesystem'	=> '/dev/mapper/jupiter-root',
  'fstype'	=> 'ext3',
  'mount'	=> '/',
  'threshold'	=> 90,
);

my %vob = (
  'system'	=> 'jupiter',
  'tag'		=> '/vobs/clearscm',
);

my %view = (
  'system'	=> 'jupiter',
  'tag'		=> 'andrew_view',
);
  
GetOptions (
  'verbose'	=> sub { set_verbose },
  'usage'	=> sub { Usage },
);

sub DisplayRecord (%) {
  my (%record) = @_;
  
  for (keys %record) {
    if ($record{$_}) {
      display "$_: $record{$_}";
    } else {
      display "$_: <undef>";
    } # if
  } # for
} # DisplayRecord

sub DisplayRecords(@) {
  my (@records) = @_;
  
  DisplayRecord %{$_} for (@records);
} # DisplayRecords

sub TestSystem() {
  verbose "Adding system $system{name}";

  my ($err, $msg) = $clearadm->AddSystem(%system);

  if ($err == 1062) {
    warning 'You already have that record!';
  } elsif ($err) {
    error $msg, $err;
  } # if

  verbose "Finding systems that match \'jup\'";
  DisplayRecords $clearadm->FindSystem('jup');

  verbose "Getting record for \'jupiter\'";
  DisplayRecord  $clearadm->GetSystem('jupiter');

  verbose "Finding systems that match \'def\'";
  DisplayRecords $clearadm->FindSystem('def');
  
  verbose "Getting record for \'defaria.com\'";
  DisplayRecord $clearadm->GetSystem('defaria.com');
  
  %update = (
    'region' => 'East Coast',
  );

  verbose "Updating system $system{name}";

  ($err, $msg) = $clearadm->UpdateSystem($system{name}, %update);

  error $msg, $err if $err;
} # TestaSystem

sub TestPackage() {
  verbose "Adding package $package{name}";
  
  my ($err, $msg) = $clearadm->AddPackage(%package);

  if ($err == 1062) {
    warning 'You already have that record!';
  } elsif ($err) {
    error $msg, $err;
  } # if

  %update = (
    'vendor'	  => 'ClearSCM',
    'description' => 'This is not ClearSCM\'s version of MySQL', 
  );

  verbose "Updating package $package{name}";
  
  ($err, $msg) = $clearadm->UpdatePackage($package{system}, $package{name}, %update);

  error $msg, $err if $err;

  verbose "Finding packages for $system{name} that match \'My\'";
  DisplayRecords $clearadm->FindPackage($system{name}, 'My');

  verbose ("Getting package for $system{name} record for \'MySQL\'");
  DisplayRecord  $clearadm->GetPackage($system{name}, 'MySQL');
} # TestPackage

sub TestFilesystem() {
  verbose "Adding filesystem $filesystem{filesystem}";
  
  my ($err, $msg) = $clearadm->AddFilesystem(%filesystem);

  error $msg, $err if $err;
  
  $filesystem{filesystem} = '/dev/sda5';
  $filesystem{path}	  = '/disk2';

  verbose "Adding filesystem $filesystem{filesystem}";
  
  ($err, $msg) = $clearadm->AddFilesystem(%filesystem);

  error $msg, $err if $err;

  %update = (
    'filesystem' => '/dev/sdb5',
  );

  verbose "Updating filesystem $filesystem{filesystem}";
  
  ($err, $msg) = $clearadm->UpdateFilesystem(
    $filesystem{system}, $filesystem{filesystem}, %update
  );

  error $msg, $err if $err;

  verbose "Finding filesystems for $system{name} that match \'My\'";
  DisplayRecords $clearadm->FindFilesystem($system{name}, 'root');

  verbose ("Getting filesystem for $system{name} record for \'/dev/sdb5\'");
  DisplayRecord  $clearadm->GetFilesystem($system{name}, '/dev/sdb5');
} # TestFilesystem

sub TestVob() {
  verbose "Adding vob $vob{tag}";

  my ($err, $msg) = $clearadm->AddVob(%vob);

  error $msg, $err if $err;
  
  $vob{tag} = '/vobs/clearscm_old';

  verbose "Adding vob $vob{tag}";

  ($err, $msg) = $clearadm->AddVob(%vob);

  error $msg, $err if $err;

  verbose "Finding vobs that match \'clearscm\'";
  DisplayRecords $clearadm->FindVob('clearscm');

  verbose ("Getting vob for \'clearscm\'");
  DisplayRecord  $clearadm->GetVob('clearscm');
} # TestVob

sub TestView() {
  verbose "Adding view $view{tag}";

  my ($err, $msg) = $clearadm->AddView(%view);

  error $msg, $err if $err;

  $view{tag} = 'andrew2_view';

  verbose "Adding view $view{tag}";

  ($err, $msg) = $clearadm->AddView(%view);

  error $msg, $err if $err;

  verbose "Finding views that match \'andrew\'";
  DisplayRecords $clearadm->FindView('andrew');

  verbose ("Getting view for \'view\'");
  DisplayRecord  $clearadm->GetView('andrew');
} # TestView

TestSystem;
TestPackage;
TestFilesystem;
TestVob;
TestView;

########################
verbose "Deleting system $system{name}";
  
my ($err, $msg) = $clearadm->DeleteSystem($system{name});

error $msg, $err if $err;
