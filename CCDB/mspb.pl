#!/usr/bin/perl

=pod

=head1 NAME $RCSfile: mspb.pl,v $

MultiSite PlayBack: This script updates the CCDB database by playing back
multisite transcations.

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.2 $

=item Created:

Fri Mar 11 19:09:52 PST 2011

=item Modified:

$Date: 2011/05/05 18:39:56 $

=back

=head1 SYNOPSIS

 Usage mspb.pl: [-u|sage] [-ve|rbose] [-deb|ug] [-vo|b <vob>]
 
 Where:
   -u|sage:       Displays usage
 
   -ve|rbose:     Be verbose
   -deb|ug:       Output debug messages
   
   -vo|b <vob>:   Vob to process (Default: All vobs)
     
=head1 DESCRIPTION

This script updates the CCDB database with Clearcase UCM meta data by playing
back multisite transactions.

If no parameters are specified then mspb attempts to replay all transactions
from all vobs listed in CCDB. To add a new vob use -vob. Epoch numbers are kept
in CCDB to keep track of the last oplog operation that had been played back for
the vob.

Note that only certain transactions are played back, those that correspond to
actions important to the metadata kept in CCDB. Also, if a transaction fails,
i.e. the add or deletion of a record fails, then the error is silently ignored.
This allows you to playback transactions without worry that replaying an 
already played transcation will cause the data to become out of sync. This is 
much like multisite's syncreplica itself.

=cut

use strict;
use warnings;

use FindBin;
use Getopt::Long;

use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use CCDB;
use Clearcase;
use Clearcase::Element;
use Clearcase::UCM::Activity;
use Clearcase::Vob;
use DateUtils;
use Display;
use Logger;
use TimeUtils;
use Utils;

my $VERSION  = '$Revision: 1.2 $';
  ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);

my (%opts, %totals, $log);

my $ccdb = CCDB->new;

sub ParseOplog ($) {
  my ($oplog) = @_;

  my %record;
    
  while (<$oplog>) {
    last if /^$/;
    
    if (/(\S+)= (.*)/) {
      my $key   = $1;
      my $value = $2;
      
      # Special casing op_time. For some odd reason we have more than one value
      # on a single line. One case of this is where the keyword is "op_time". 
      # We've seen lines like this:
      #
      #   op_time= 2008-10-15T18:48:39Z  create_time= 2008-10-15T18:48:39Z
      #
      # So by now $value = '2008-10-15T18:48:39Z  create_time= 2008-10-15T18:48:39Z'
      # so we'll split it based on '  '.
      if ($key eq 'op_time') {
        # Note: 2 spaces!
        ($value, $_) = split /  /, $value;
        
        # Set op_time
        $record{$key} = $value;
        
        # Now parse $create time
        if (/(\S+)= (.*)/) {
          $key   = $1;
          $value = $2;
        } # if
      } # if
      
      # Some values are wrapped in quotes
      if ($value =~ /(\'|\")(.*)(\'|\")/) {
        $value = $2;
      } # if
      
      # If a key occurs multiple times then make its value an array
      if ($record{$key}) {
        if (ref $record{$key} eq 'ARRAY') {
          push @{$record{$key}}, $value;
        } else {
          $record{$key} = [ $record{$key}, $value];
        } # if
      } else {
        $record{$key} = $value;
      } # if
    } # if
  } # while
  
  return %record;  
} # ParseOplog

sub GetSubmittedDate ($$) {
  my ($activity, $pvob) = @_;
  
  $pvob = Clearcase::vobtag $pvob;
  
  my $cmd = "describe -fmt \"%Na\" activity:$activity\@$pvob";
  
  my ($status, @output) = $Clearcase::CC->execute ($cmd);
  
  unless ($status) {
    if ($output[0]) {
      foreach (split / /, $output[0]) {
        if (/(\w+)=(.+)/) {
          if ($1 =~ /submit_time/i) {
            my ($year, $mon, $mday, $hour, $min, $sec) = ymdhms $2;
            return "$year-$mon-$mday $hour:$min:$sec";
          } # if
        } # if
      } # foreach
    } # if
  } # unless
  
  return;
} # GetSubmittedDate

sub AddActivity ($%) {
  my ($pvob, %oplog) = @_;
  
  my ($cmd, $err, $status, $msg, @output, %existingRec);
  
  $totals{'Activities processed'}++;

  undef %existingRec;
  
  # Add an activity (if not already existing)      
  %existingRec = $ccdb->GetActivity ($oplog{name_p}, $pvob);
  
  unless (%existingRec) {
    my $submitted = GetSubmittedDate $oplog{name_p}, $pvob;
    
    my $cmd = "describe -fmt \"%[owner]p\" activity:$oplog{name_p}\@"
            . Clearcase::vobtag $pvob;
            
    my ($status, @output) = $Clearcase::CC->execute ($cmd);

    ($err, $msg) = $ccdb->AddActivity ({
      oid       => $oplog{activity_oid},
      name      => $oplog{name_p},
      pvob      => $pvob,
      owner     => $output[0],
      submitted => $submitted,
    });

    return ($err, $msg)
      if $err;
      
    $totals{'Activities added'}++;
  } # unless
    
  # Add a stream (if not already existing)
  $cmd = "lsactivity -fmt \"%[stream]p\" $oplog{name_p}\@"
       . Clearcase::vobtag $pvob;
          
  ($status, @output) = $Clearcase::CC->execute ($cmd);
  
  if ($status) {
    # There are times when an activity is subsequently deleted. Since we are
    # playing back Multisite transactions we will see the mkactivity first, then
    # later see a corresponding rmactivity. Since Multisite has already played
    # all of these transactions to Clearcase itself the activity is gone - and
    # therefore the lsactivity will fail to find the stream. If that's the case
    # then just return. If not then issue a warning.
    unless ($output[0] =~ /activity not found/) {
      $log->warn ("Can't find stream for activity:$oplog{name_p}\@"
         . Clearcase::vobtag $pvob
      );
    } # unless
    
    return (1, "Unable to execute command: $cmd (Status: $status)\n" 
          . join ("\n", @output))
  } # if

  undef %existingRec;
  
  %existingRec = $ccdb->GetStream ($output[0], $pvob);
  
  unless (%existingRec) {
    ($err, $msg) = $ccdb->AddStream ({
      name => $output[0], 
      pvob => $pvob
    });

    if ($err) {
      $log->warn ("Unable to add stream:$output[0]\@"
               . Clearcase::vobtag $pvob
               . " (Error: $err)\n$msg");
      
      return ($err, $msg);
    } # if
      
    $totals{'Streams added'}++;
  } # unless

  undef %existingRec;
  
  # Link them (if not already linked)
  %existingRec = $ccdb->GetStreamActivityXref (
    $output[0], 
    $oplog{name_p},
    $pvob
  );
  
  unless (%existingRec) {
    ($err, $msg) = $ccdb->AddStreamActivityXref ({
      stream   => $output[0],
      activity => $oplog{name_p},
      pvob     => $pvob,
    });

    if ($err) {
      $log->warn ("Unable to add stream_activity_xref:$output[0]\@"
               . Clearcase::vobtag $pvob
               . " activity:$oplog{name_p} (Error: $err)\n$msg");
      
      return ($err, $msg);
    } # if
      
    $totals{'Stream/Activity Xrefs added'}++;
  } # unless
  
  return;
} # AddActivity

sub AddStream ($%) {
  my ($pvob, %oplog) = @_;
  
  my ($err, $msg);
  
  $totals{'Streams processed'}++;

  # Add a stream (if not already existing)      
  my %existingRec = $ccdb->GetStream ($oplog{name_p}, $pvob);
  
  unless (%existingRec) {
    my $pvobTag = Clearcase::vobtag $pvob;
    my $cmd     = "lsstream -fmt \"%[project]p\" $oplog{name_p}\@$pvobTag";
    
    my ($status, @output) = $Clearcase::CC->execute ($cmd);
    
    if ($status) {
      $log->err ("Unable to execute command: $cmd (Status: $status)"
              . join ("\n", @output));
      return ($status, join ("\n", @output));            
    } # if
    
    ($err, $msg) = $ccdb->AddStream ({
      oid     => $oplog{activity_oid},
      name    => $oplog{name_p},
      project => $output[0],
      pvob    => $pvob,
    });

    unless ($err) {
      $totals{'Streams added'}++;
    } # unless
  } # unless
    
  return ($err, $msg); 
} # AddStream

sub ProcessActivity ($$%) {
  my ($operation, $pvob, %oplog) = @_;
  
  # Many operations in Multisite's oplog have an op of mkactivity but are 
  # actually operations on other objects based on actype_oid. The following are 
  # actype_oid values:
  my @validActypes = (
    'activity',
    'folder',
    'project',
    'stream',
    'timeline',
    'internal',
  );
  
  # We only handle activity and stream here
  my $actype;
  
  if ($oplog{actype_oid}) {
    $actype = $Clearcase::CC->oid2name ($oplog{actype_oid}, $pvob);
  } else {
    if ($operation eq 'rmactivity' and $oplog{comment}) {
      $actype = 'activity';
    } else {
      return;
    } # if
  } # if
  
  my ($err, $msg);
  
  if ($operation eq 'mkactivity') {
    if ($actype eq 'activity') {
      AddActivity $pvob, %oplog;
    } elsif ($actype eq 'stream') {
      AddStream $pvob, %oplog;
    } # if
  } elsif ($operation eq 'rmactivity') {
    if ($actype eq 'activity') {
      # For rmactivity there's nothing but the comment to go on to get the
      # activity's name. The comment must be of a format of "Destroyed activity
      # "<activity_name>@<pvob>"." complete with nested double quotes. 
      my ($activity, $pvob);
      
      # Note: There are rmactivity's that lack the comment! Nothing we can do
      # with these except to ignore them!
      return
        unless $oplog{comment};
      
      # Note: <pvob> is a vob tag of the variety of the client. So, for example,
      # it can be a Windows style pvob (e.g. \\pvob) even though we are running
      # on a Linux machine where the pvob needs to be /vob/pvob!
      if ($oplog{comment} =~ /Destroyed activity \"activity:(\S+)\@(\S+)\"/) {
        $activity = $1;
        $pvob     = Clearcase::vobname ($2);
      } # if
      
      return
        unless ($activity or $pvob);
        
      $totals{'Activities processed'}++;
      $totals{'Activities deleted'}++;

      return $ccdb->DeleteActivity ($activity, $pvob);
    } elsif ($actype eq 'stream') {
      # Note: I have yet to see an rmactivity stream with even an actype_oid!
      $totals{'Streams processed'}++;
      $totals{'Streams deleted'}++;

      return $ccdb->DeleteStreamOID ($oplog{activity_oid});
    } # if
  } # if
  
  return;
} # ProcessActivity

sub ProcessBaseline ($$%) {
  my ($operation, $pvob, %oplog) = @_;
  
  my ($cmd, $err, $status, $msg, @output, %existingRec);

  my $pvobTag = Clearcase::vobtag $pvob;
  
  $totals{'Baselines processed'}++;

  if ($operation eq 'mkcheckpoint') {
    undef %existingRec;
    
    # Add an activity (if not already existing)      
    %existingRec = $ccdb->GetBaseline ($oplog{name_p}, $pvob);
    
    unless (%existingRec) {
      ($err, $msg) = $ccdb->AddBaseline ({
        oid  => $oplog{checkpoint_oid},
        name => $oplog{name_p},
        pvob => $pvob,
      });
  
      return ($err, $msg)
        if $err;
        
      $totals{'Baselines added'}++;
    } # unless
    
    # Add a stream_baseline_xref entry
    $cmd = "lsbl -fmt \"%[bl_stream]p\" $oplog{name_p}\@$pvobTag";
    
    ($status, @output) = $Clearcase::CC->execute ($cmd);
    
    if ($status) {
      $log->err ("Unable to execute command: $cmd (Status: $status)"
              . join ("\n", @output));
      return;            
    } # if
    
    ($err, $msg) = $ccdb->AddStreamBaselineXref ({
      stream   => $output[0],
      baseline => $oplog{name_p},
      pvob     => $pvob,
    });

    return ($err, $msg)
      if $err;

    $totals{'Stream/Baseline Xrefs added'}++;
        
    return
      unless $oplog{activity_oid};
      
    # Loop through activities
    my @activities = ref $oplog{activity_oid} eq 'ARRAY'
                   ? @{$oplog{activity_oid}}
                   : ($oplog{activity_oid});
                  
    foreach (@activities) {
      my $activity = $Clearcase::CC->oid2name ($_, $pvob);

      # I think $activity will be blank if after this mkcheckpoint somebody
      # did an rmactivity...      
      next
        unless $activity;
        
      # Check to see if the activity exists
      undef %existingRec;
    
      %existingRec = $ccdb->GetActivity ($activity, $pvob);
      
      unless (%existingRec) {
        ($err, $msg) = $ccdb->AddActivity ({
          name => $activity,
          pvob => $pvob,
        });
        
        return ($err, $msg)
          if $err;
      } # unless
      
      # Link them (if not already linked)
      %existingRec = $ccdb->GetBaselineActivityXref (
        $oplog{name_p}, $activity, $pvob
      );
    
      unless (%existingRec) {
        ($err, $msg) = $ccdb->AddBaselineActivityXref ({
          baseline => $oplog{name_p},
          activity => $activity,
          pvob     => $pvob,
        });
  
        if ($err) {
          $log->warn ("Unable to add baseline_activity_xref:$output[0]\@"
                    . "$pvobTag baseline:$oplog{name_p} activity:$_ (Error:"
                    . "$err)\n$msg");
        
          return ($err, $msg);
        } # if
        
        $totals{'Baseline/Activity Xrefs added'}++;
      } # unless
    } # foreach
  } elsif ($operation eq 'rmcheckpoint') {
    $totals{'Baselines deleted'}++;
    
    return $ccdb->DeleteBaselineOID ($oplog{checkpoint_oid});
  } # if
  
  return;  
} # ProcessBaseline

sub ProcessElement ($$%) {
  my ($operation, $vob, %oplog) = @_;
  
  return
    unless $oplog{version_oid};
  
  my $elementVersion = $Clearcase::CC->oid2name ($oplog{version_oid}, $vob);
  my ($element, $version) = split /$Clearcase::SFX/, $elementVersion;
  
  # Remove VOBTAG_PREFIX from $element
  $element = '/' . Clearcase::vobname $element;
  
  my $cmd = "describe -fmt \"%[activity]Xp\" oid:$oplog{version_oid}\@"
          . Clearcase::vobtag $vob;
  
  my ($status, @output) = $Clearcase::CC->execute ($cmd);
  
  if ($status) {
    $log->err ("Unable to execute command: $cmd (Status: $status)"
            . join ("\n", @output));
    return;            
  } # if
  
  # If this operation is not attached to an activity then we're not interested.
  return
    unless $output[0];
  
  my ($activity, $pvob) = split /\@/, $output[0];
  
  # Remove leading "activity:"
  $activity = substr $activity, 9;
  
  # Fix $pvob
  $pvob = Clearcase::vobname $pvob;
    
  my ($err, $msg, %existingRec);
  
  if ($operation eq 'checkin'
   or $operation eq 'checkout') {
    %existingRec = $ccdb->GetChangeset ($activity, $element, $version, $pvob);
    
    unless (%existingRec) {
      my $create_time = $oplog{create_time};

      # Create time from Multisite are of the format: 2008-10-15T18:48:39Z
      $create_time =~ s/T/ /;
      $create_time =~ s/Z//;
    
      ($err, $msg) = $ccdb->AddChangeset ({
        activity => $activity,
        element  => $element,
        version  => $version,
        pvob     => $pvob,
        created  => $create_time,  
      });
    
      if ($err) {
        $log->err ("Unable to AddChangeset ($activity, $element, $version, " 
                 . "$pvob)\n$msg");
              
         return ($err, $msg);
      } # if
      
      # Update Activity's submitted field (if this create time gt submitted)
      my %activity = $ccdb->GetActivity ($activity, $pvob);
      
      if (%activity) {
        $activity{submitted} ||= $create_time;
        
        if ($create_time ge $activity{submitted}) {
          $activity{submitted} = $create_time;
          
          my ($err, $msg) = $ccdb->UpdateActivity (
            $activity,
            $pvob,
            \%activity,
          );
          
          $log->err ("Unable to update activity: $activity pvob: $pvob - "
                  . " submitted: $create_time")
            if $err;
        } # if
      } # if

      $totals{'Changesets added'}++;
    } # unless
  } elsif ($operation eq 'uncheckout'
        or $operation eq 'rmver') {
    %existingRec = $ccdb->GetChangeset ($activity, $element, $version, $pvob);
    
    if (%existingRec) {
      ($err, $msg) = $ccdb->DeleteChangeset (
        $activity,
        $element,
        $version,
        $pvob,
      );
      
      if ($err) {
        $log->err ("Unable to DeleteChangeset ($activity, $element, $version, " 
                 . "$pvob)\n$msg");
                
        return ($err, $msg);
      } # if

      $totals{'Changesets deleted'}++;
    } # if
  } elsif ($operation eq 'rmelem') {
    %existingRec = $ccdb->GetChangeset ($activity, $element, $version, $pvob);
    
    if (%existingRec) {
      ($err, $msg) = $ccdb->DeleteElementAll ($element);

      if ($err) {
        $log->err ("Unable to DeleteElementAll ($element)\n$msg");
                
        return ($err, $msg);
      } # if

      $totals{'Elements removed'}++;
    } # if
  } # if
  
  return;
} # ProcessElement

sub ProcessRename ($%) {
  my ($vob, %oplog) = @_;
  
  return 
    unless $oplog{comment};
    
  my $object;
    
  # Parse comment to find what got renamed and the from and to names
  if ($oplog{comment} =~ /Changed name of (.+?) from \"(\S+)\" to \"(\S+)\"/) {
       $object = $1;
    my $from   = $2;
    my $to     = $3;
    
    # Only interested in these objects
    return
      unless $object =~ /activity/i or
             $object =~ /baseline/i or
             $object =~ /stream/i;
             
    my %update = (
      name => $to,
    );
    
    my $method = 'Update' . ucfirst $object;
    
    my ($err, $str) = $ccdb->$method ($from, $vob, \%update);
    
    if ($err) {
      $log->err ("Unable to rename $object from $from -> $to (pvob:$vob");
             
      return;
    } # if;
  } # if

  if ($object eq 'activity') {
    $totals{'Activities renamed'}++;
  } elsif ($object eq 'baseline') {
    $totals{'Baselines renamed'}++;
  } elsif ($object eq 'stream') {
    $totals{'Streams renamed'}++;
  } # if  

  return;
} # ProcessRename

sub ProcessOperation ($$%) {
  my ($operation, $vob, %oplog) = @_;
  
  # For now let's only process the activity opcodes... We'll add more later.
  my @interestingOpcodes = (
    'checkin',
    'checkout',
    'mkactivity',
    'mkcheckpoint',
    'rename',
    'rmactivity',
    'rmcheckpoint',
    'rmelem',
    'rmver',
    'uncheckout',
#    'mkattr',
#    'mkhlink',
#    'setpvar',
  );  

  return 
    unless InArray $operation, @interestingOpcodes;
    
  if ($operation eq 'mkactivity'
   or $operation eq 'rmactivity') {
    return ProcessActivity ($operation, $vob, %oplog);
  } elsif ($operation eq 'mkcheckpoint'
        or $operation eq 'rmcheckpoint') {
    return ProcessBaseline ($operation, $vob, %oplog);
  } elsif ($operation eq 'checkin'
        or $operation eq 'checkout'
        or $operation eq 'rmelem'
        or $operation eq 'rmver'
        or $operation eq 'uncheckout') {
    return ProcessElement ($operation, $vob, %oplog);
  } elsif ($operation eq 'rename') {
    return ProcessRename ($vob, %oplog);
  } # if
} # ProcessOperation

sub ProcessOplog (%) {
  my (%vob) = @_;
  
  # Start dumpoplog off at the appropriate oplog number
  my $cmd = 'multitool dumpoplog -long -invob '
          . Clearcase::vobtag ($vob{name})
          . " -from $vob{epoch}";

  # Start a pipe
  open my $oplog, "$cmd|"
    or error "Cannot execute $cmd", 1;

  my $inRecord;
  
  while (<$oplog>) {
    # Look for the next oplog entry
    if (/(\d+):/) {
      $vob{epoch} = $1;
      $inRecord = 1;
      next;
    } elsif (/^$/) {
      $inRecord = 0;
      next;
    } elsif (!$inRecord) {
      next;
    } # if
    
    my ($operation, $status, @output);
    
    if (/op= (\S+)/) {
      $operation = $1;
    } else {
      $operation = '';
    } # if

    ProcessOperation $operation, $vob{name}, ParseOplog $oplog;

    # Update vob's last_oplog
    my ($err, $msg) = $ccdb->UpdateVob ($vob{name}, \%vob);
    
    $log->err ("Unable to update vob:$vob{name}\'s epoch to "
             . $vob{epoch})
      if $err;      
  } # while
  
  close $oplog;
  
  return;
} # ProcessOplog

sub ProcessVob ($) {
  my ($name) = @_;
  
  my ($err, $msg);

  my %vob = $ccdb->GetVob ($name);
  
  $log->msg ("Processing vob:$name ($vob{type})");
    
  unless (%vob) {
    my $vob = Clearcase::Vob->new (Clearcase::vobtag $name);
    
    ($err, $msg) = $ccdb->AddVob ({
      name => $name,
      type => $vob->vob_registry_attributes !~ /ucmvob/ ? 'base' : 'ucm', 
    });
  
    if ($err) {
      $log->err ("Unable to add vob $name (Error: $err)\n$msg");
    } else {
      $totals{'Vobs added'}++;
    } # if

    %vob = $ccdb->GetVob ($name);
  } # unless
  
  ProcessOplog %vob;
} # ProcessVob

sub EndProcess {
  $totals{Errors}   = $log->errors;
  $totals{Warnings} = $log->warnings;

  Stats \%totals, $log;
} # EndProcess

# Main
local $| = 1;

my $startTime = time;

GetOptions (
  \%opts,
  'verbose' => sub { set_verbose },
  'usage'   => sub { Usage },
  'vob=s',
) or Usage "Unknown option";

$log = Logger->new;

$SIG{__DIE__} = $SIG{INT} = $SIG{ABRT} = $SIG{QUIT} = $SIG{USR2} = 'EndProcess';

my @vobs;

if ($opts{vob}) {
  push @vobs, $opts{vob};
} else {
  # Do UCM vobs first
  my (@ucmvobs, @basevobs);
  
  push @ucmvobs, $$_{name}
    foreach ($ccdb->FindVob ('*', 'ucm'));
  
  # Add on base vobs
  push @basevobs, $$_{name}
    foreach ($ccdb->FindVob ('*', 'base'));
    
  push @vobs, $_ foreach (sort @ucmvobs);
  push @vobs, $_ foreach (sort @basevobs);
} # if

if (@vobs == 1) {
  $log->msg ('1 vob to process');
} else {
  $log->msg (scalar @vobs . ' vobs to process');
} # if

foreach (@vobs) {
  ProcessVob $_;
  
  $totals{'Vobs processed'}++;
} # foreach

display_duration $startTime, $log;

$totals{Errors}   = $log->errors;
$totals{Warnings} = $log->warnings;

Stats \%totals, $log;
