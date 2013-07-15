#!/usr/bin/perl

=pod

=head1 NAME $RCSfile: update.pl,v $

Updates the CCDB database

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.4 $

=item Created:

Fri Mar 11 19:09:52 PST 2011

=item Modified:

$Date: 2011/05/05 18:37:05 $

=back

=head1 SYNOPSIS

 Usage update.pl: [-u|sage] [-ve|rbose] [-deb|ug]
 
                  [-vo|b <vob>]
 
                  [[-p|vob <pvob>]|
                   [[-p|vob <pvob> -a|ctivity <activity>]|
                    [-p|vob <pvob> -b|aseline <baseline>]|
                    [-p|vob <pvob> -s|tream <stream>]]]
                    
                  [-o|plog [<vob>]]
                  
                  [-c|heckchangesets]
                   
 Where:
   -u|sage:       Displays usage
 
   -ve|rbose:     Be verbose
   -deb|ug:       Output debug messages
   
   -vo|b <vob>:           Vob to process
 
   -p|vob <pvob>:         PVOB to operate on
   -a|ctivity <activity>: Activity to process
   -b|aseline <baseline>: Baseline to process
   -s|tream <stream>:     Stream to process
   
   -o|plog [<vob>]:       Process oplog (Default: All vobs)
   
   -ch
     
=head1 DESCRIPTION

This script updates the CCDB database with Clearcase UCM meta data. It operates
in 2 modes.

=head2 Update mode

In this mode, indicated by specifying either no options or a -pvob and 
optionally one of -activity, -baseline or -stream, update.pl will query 
Clearcase and gather all metadata for the specified option. 

You can run update.pl with no paramters to process all pvobs in the current
registry region of you can specify a -pvob to process. This is generally how
the script is run. Note you can parallelize update.pl by running it multiple
times each with its own -pvob. In this case the script will log activity to
update.<pvob>.log.

Or you can run "fix ups" to add individual activities, baselines or streams by
specifying -activity (or -baseline/-stream) and its -pvob. Note however that
the object is not validated (In such cases we don't check that say activity and
pvob are valid - we just add them to the database).

Additionally you can use -vob to add a vob to CCDB. This should be a relatively
infrequent operation and it is necessary to add vobs that -oplog will process.

=head2 Check Change Sets mode

Even with this script initially popullating CCDB and with the appropriate 
triggers set to fire to keep CCDB up to date, and even with -oplog mode to apply
changes from other sites the CCDB may still become out of sync with Clearcase. 
This is due to the fact that orphaned files can effect change set membership in
UCM and Clearcase does not call any triggers or otherwise notify you of the 
problem. To illustrate, if the user is running under UCM and checks out a 
directory, makes an element and checks it in, but then cancels the checkout of
the directory, Clearcase is forced to orphan the file by placing it in 
lost+found. A warning is issued to the user, however no triggers are called. 

Investigating the change set we see that the elements that were orphaned are
indicated in the change set but their paths have been altered to indicate that
the elements are in lost+found! One would think that Clearcase would fire the
chactivity trigger but it seems that trigger is only fired when elements change
from one activity to another. In this case the elements are changing, but the
activity is the same activity. To me this is a bug and Clearcase should fire the
chactivity trigger with CLEARCASE_ACTIVITY == CLEARCASE_TO_ACTIVITY. If this 
were the case we could handle this situation with triggers.

Check change set mode instead goes through all of the changesets in CCDB and
verifies that the changeset in CCDB matches the changeset as listed by 
lsactivity -long. If not it updates it. This is an intense activity that will
be time consuming but I can see no other way to fix up this problem.

=cut

use strict;
use warnings;

use FindBin;
use Getopt::Long;

use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use CCDB;
use Clearcase;
use Clearcase::Vob;
use Clearcase::UCM;
use Clearcase::UCM::Activity;
use Clearcase::Element;
use Display;
use Logger;
use TimeUtils;
use Utils;

my $VERSION  = '$Revision: 1.4 $';
  ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);

my (%opts, %totals, $log);

my $ccdb = CCDB->new;

# Forwards
sub ProcessFolder ($$);

sub changeset ($$) {
  my ($activity, $pvob) = @_;
  
  $pvob = Clearcase::vobtag $pvob;
  
  my $cmd = "lsact -fmt \"%[versions]CQp\" $activity\@$pvob";

  my ($status, @output) = $Clearcase::CC->execute ($cmd);

  $log->err ("Unable to execute $cmd\n" . join ("\n", @output), $status)
    if $status;

  # Need to split up change set. It's presented to us as quoted and space 
  # separated however the change set elements themselves can have spaces in 
  # them! e.g.:
  #
  #   "/vob/foo/file name with spaces@@/main/1", "/vob/foo/file name2@@/main/2"
  #
  # So we'll split on '", ""'! Note that this will leave us with the first
  # element with a leading '"' and the last element with a trailing '"' which
  # we will have to handle.
  #
  # Additionally we will call collapseOverExtendedViewPathname to normalize
  # the over extended pathnames to element hashes.
  my (@changeset);
  
  @output = split /\", \"/, $output[0]
    if $output[0];
  
  foreach (@output) {
    # Skip any cleartool warnings. We are getting warnings of the form:
    # "A version in the change set of activity "63332.4" is currently 
    # unavailable". Probably some sort of subtle corruption that we can ignore.
    # (It should be fixed but we aren't going to be doing that here!)
    next if /cleartool: Warning/;

    # Strip any remaining '"'s
    s/^\"//; s/\"$//;

    # Remove vob prefix but keep the leading "/"
    $_ = '/' . Clearcase::vobname $_;
    
    my %element = Clearcase::Element::collapseOverExtendedVersionPathname $_;
    
    push @changeset, \%element;
  } # foreach
  
  return @changeset;
} # changeset

sub baselineActivities (%) {
  my (%baseline) = @_;
  
  my $pvobTag = Clearcase::vobtag $baseline{pvob};
  
  my $cmd = "lsbl -fmt \"%[activities]p\" $baseline{name}\@$pvobTag";
  
  my ($status, @output) = $Clearcase::CC->execute ($cmd);
  
  $log->err ("Unable to execute $cmd\n" . join ("\n", @output), $status)
    if $status;
    
  $output[0] ||= '';

  return split / /, $output[0];
} # baselineActivities

sub UpdatePvob ($) {
  my ($pvob) = @_;
  
  my %pvob = $ccdb->GetVob ($pvob);
  
  return if %pvob;
  
  my ($err, $msg) = $ccdb->AddVob ({
    name => $pvob,
    type => 'ucm',
  });
  
  if ($err) {
    $log->err ("Unable to add pvob:$pvob\n$msg");
  } else {
    $totals{'Pvobs added'}++;
      
    $log->msg ("Added pvob:$pvob");
  } # if
  
  return;
} # UpdatePvob

sub UpdateFolder ($$) {
  my ($folder, $pvob) = @_;
  
  my %folder = $ccdb->GetFolder ($folder, $pvob);
  
  return if %folder;
  
  my ($err, $msg) = $ccdb->AddFolder ({
    name => $folder,
    pvob => $pvob,
  });
  
  if ($err) {
    $log->err ("Unable to add folder:$folder\n$msg");
  } else {
    $totals{'Folders added'}++;
    
    $log->msg ("Added folder:$folder");
  } # if
  
  return;
} # UpdateFolder

sub UpdateSubfolder ($$$) {
  my ($parent, $subfolder, $pvob) = @_;
  
  my %subfolder = $ccdb->GetSubfolder ($parent, $subfolder, $pvob);
  
  return if %subfolder;
  
  my ($err, $msg) = $ccdb->AddSubfolder ({
    parent    => $parent,
    subfolder => $subfolder,
    pvob      => $pvob,
  });
  
  if ($err) {
    $log->err ("Unable to add subfolder:$parent/$subfolder\n$msg");
  } else {
    $totals{'Subfolders added'}++;
    
    $log->msg ("Added subfolder:$parent/$subfolder");
  } # if
  
  return;
} # UpdateSubfolder

sub UpdateProject ($$$) {
  my ($project, $folder, $pvob) = @_;
  
  my %project = $ccdb->GetProject ($project, $folder, $pvob);
  
  return if %project;
  
  my ($err, $msg) = $ccdb->AddProject ({
    name   => $project,
    folder => $folder,
    pvob   => $pvob,
  });
  
  if ($err) {
    $log->err ("Unable to add project:$project folder:$folder pvob:$pvob\n$msg");
  } else {
    $totals{'Projects added'}++;
    
    $log->msg ("Added Project:$project");
  } # if
  
  return;
} # UpdateProject

sub UpdateStream ($$) {
  my ($name, $pvob) = @_;
  
  my %stream = $ccdb->GetStream ($name, $pvob);
    
  return if %stream;

  # Determine the integration stream for this stream's project. First get
  # project for the stream.
  my $pvobTag = Clearcase::vobtag ($pvob);

  my $cmd = "lsstream -fmt \"%[project]p\" $name\@$pvobTag";
  
  my ($status, @output) = $Clearcase::CC->execute ($cmd);
  
  if ($status) {
    $log->err ("Unable to execute $cmd\n" . join ("\n", @output));

    return;
  } # if

  # Now get the intergration stream for this project
  $cmd = "lsproject -fmt \"%[istream]p\" $output[0]\@$pvobTag";
  
  ($status, @output) = $Clearcase::CC->execute ($cmd);
  
  if ($status) {
    $log->err ("Unable to execute $cmd\n" . join ("\n", @output));
    
    return;
  } # if

  my $type = 'integration'
    if $name eq $output[0];

  my ($err, $msg) = $ccdb->AddStream ({
    name => $name,
    pvob => $pvob,
    type => $type,    
  });

  if ($err) {
    $log->err ( "Unable to add stream:$name\n$msg");
  } else {
    $log->msg ("Added stream:$name");
    $totals{'Streams added'}++;
  } # if
} # UpdateStream

sub UpdateChangeset ($$$) {
  my ($activity, $pvob, $element) = @_;
  
  my %element = (
    name    => '/' . Clearcase::vobname $element->pname,
    version => $element->version,
  );
  
  my %changeset = $ccdb->GetChangeset (
    $activity, 
    '/' . Clearcase::vobname $element->pname,
    $element->version,
    $pvob,
  );
  
  return if %changeset;
  
  my ($err, $msg) = $ccdb->AddChangeset ({
    activity => $activity,
    element  => $element{name},
    version  => $element{version},
    pvob     => $pvob,
      
  });
  
  if ($err) {
    $log->err ("Unable to add changeset activity:$activity "
             . "element:$element{name}$Clearcase::SFX$element{version}\n$msg");
  } else {
    $totals{'Changesets added'}++;

    $log->msg ("Linked activity:$activity -> element:$element{name}");  
  } # if

  return;
} # UpdateChangeset

sub UpdateActivity ($$) {
  my ($name, $pvob) = @_;
  
  my %activity = $ccdb->GetActivity ($name, $pvob);
    
  return if %activity;

  my ($err, $msg) = $ccdb->AddActivity ({
    name => $name,
    pvob => $pvob,
  });

  if ($err) {
    $log->err ("Unable to add activity:$name\n$msg");
  } else {
    $totals{'Activities added'}++;

    $log->msg ("Added activity $name");
  } # if
  
  return;  
} # UpdateActivity

sub UpdateBaselineActivityXref (%) {
  my (%baseline) = @_;
  
  $log->msg ("Processing Baseline Activities for $baseline{name}");

  my %baselineActivityXref = (
    baseline => $baseline{name},
    pvob     => $baseline{pvob},
  );
  
  foreach (baselineActivities %baseline) {
    my ($err, $msg);
    
    # Often activities in a baseline have not yet been added so add them here.
    # (Not sure why this is the case...)
    
    my %existingRec = $ccdb->GetActivity ($_, $baseline{pvob});
    
    UpdateActivity $_, $baseline{pvob}
      unless %existingRec;
    
    $baselineActivityXref{activity} = $_;
    
    %existingRec = $ccdb->GetBaselineActivityXref (
      $baselineActivityXref{baseline},
      $baselineActivityXref{activity},
      $baselineActivityXref{pvob}
    );
    
    unless (%existingRec) {
      ($err, $msg) = $ccdb->AddBaselineActivityXref (\%baselineActivityXref);

      if ($err) {
        $log->err ("Unable to add baseline:$baselineActivityXref{name}"
                 . " activity: $baselineActivityXref{activity}\n"
                 . $msg
        );
      } else {
        $totals{'Baseline Activity Xrefs added'}++;
      } # if
    } # unless
  } # foreach

  $log->msg ("Processed Baseline Activities for $baseline{name}");
  
  return;
} # UpdateBaselineActivityXref

sub UpdateBaseline ($$) {
  my ($name, $pvob) = @_;
  
  my %baseline = $ccdb->GetBaseline ($name, $pvob);
    
  return if %baseline;

  my ($err, $msg) = $ccdb->AddBaseline ({
    name => $name,
    pvob => $pvob, 
  });

  if ($err) {
    $log->err ("Unable to add baseline:$name\n$msg");
  } else {
    $totals{'Baselines added'}++;
    
    $log->msg ("Added baseline:$name");
    
    my %baseline = $ccdb->GetBaseline ($name, $pvob);
      
    UpdateBaselineActivityXref (%baseline);
  } # if
  
  return;
} # Updatebaseline

sub UpdateStreamActivityXref ($$$) {
  my ($stream, $activity, $pvob) = @_;
  
  my %streamActivityXref = $ccdb->GetStreamActivityXref (
    $stream,
    $activity,
    $pvob,
  );
  
  return if %streamActivityXref;
  
  my ($err, $msg) = $ccdb->AddStreamActivityXref ({
    stream   => $stream,
    activity => $activity,
    pvob     => $pvob,
  });
  
  if ($err) {
    $log->err ("Unable to add stream_activity_xref stream:$stream "
             . "activity:$activity\n$msg");
    return;
  } else {
    $totals{'Stream Activity Xrefs added'}++;
    
    $log->msg ("Linked stream:$stream -> activity:$activity");  
  } # if

  return;
} # UpdateStreamActivityXref

sub ProcessElements ($$) {
  my ($name, $pvob) = @_;
  
  $log->msg ("Finding changeset for activity:$name");
  
  my $activity = Clearcase::UCM::Activity->new ($name, $pvob);
  
  foreach ($activity->changeset) {
    my ($element) = $_;
    
    # Remove vob prefix but keep the leading "/"
    my $elementName = '/' . Clearcase::vobname $element->pname;
        
    $log->msg (
      "Processing element:$elementName"
    . $Clearcase::SFX
    . $element->version
    );

    UpdateChangeset $name, $pvob, $element;    
  } # foreach;
  
  $log->msg ("Processed changeset for activity:$name");

  return;
} # ProcessElements

sub ProcessActivities ($$) {
  my ($stream, $pvob) = @_;
  
  $log->msg ("Finding activities in stream:$stream");
  
  my $pvobTag = Clearcase::vobtag ($pvob);
  
  my $cmd = "lsstream -fmt \"%[activities]p\" $stream\@$pvobTag";
  
  my ($status, @output) = $Clearcase::CC->execute ($cmd);

  if ($status) {
    $log->err ("Unable to execute $cmd\n" . join ("\n", @output), $status);
    
    return;
  } # if

  $output[0] ||= '';
  
  foreach (sort split / /, $output[0]) {
    next if /^DEFAULT.*NO_CHECKIN/;

    UpdateActivity ($_, $pvob);
    
    $totals{'Activities processed'}++;
    
    UpdateStreamActivityXref $stream, $_, $pvob;
    
    ProcessElements $_, $pvob;
  } # foreach
  
  $log->msg ("Processed activities in stream:$stream");
  
  return;
} # ProcessActivities

sub ProcessBaselines ($$) {
  my ($stream, $pvob) = @_;
  
  $log->msg ("Finding baselines in stream:$stream");
  
  my $pvobTag = Clearcase::vobtag ($pvob);
  
  my $cmd = "lsbl -stream $stream\@$pvobTag -short";
  
  my ($status, @baselines) = $Clearcase::CC->execute ($cmd);

  if ($status) {
    $log->err ("Unable to execute $cmd\n" . join ("\n", @baselines));

    return;
  } # if

  foreach (sort @baselines) {
    UpdateBaseline ($_, $pvob);
    
    $totals{'Baselines processed'}++;
  } # foreach
  
  $log->msg ("Processed baselines in stream:$stream");
  
  return;
} # ProcessBaselines

sub ProcessStream ($$) {
  my ($name, $pvob) = @_;

  $totals{'Streams processed'}++;
  
  UpdateStream $name, $pvob;
  
  ProcessActivities $name, $pvob;
  ProcessBaselines  $name, $pvob;
  
  return;
} # ProcessStream

sub ProcessProject ($$$) {
  my ($project, $folder, $pvob) = @_;
  
  my $pvobTag = Clearcase::vobtag $pvob;  

  $log->msg ("Processing project:$project\@$pvobTag");

  UpdateProject ($project, $folder, $pvob);  

  my $cmd = "lsstream -short -in $project\@$pvobTag";
  
  my ($status, @output) = $Clearcase::CC->execute ($cmd); 
  
  if ($status) {
    $log->err ("Unable to execute $cmd\n" . join ("\n", @output));
    
    return;
  } # if
  
  foreach (@output) {
    ProcessStream $_, $pvob;
  } # foreach

  return;
} # ProcessProject

sub ProcessFolder ($$) {
  my ($folder, $pvob) = @_;

  my $pvobTag = Clearcase::vobtag $pvob;
  
  $log->msg ("Processing folder:$folder\@$pvobTag");
  
  UpdateFolder ($folder, $pvob);

  my $cmd = "lsfolder -fmt \"%[contains_folders]p\" $folder\@$pvobTag";
  
  my ($status, @output) = $Clearcase::CC->execute ($cmd);
  
  if ($status) {
    $log->err ("Unable to execute command $cmd (Status: $status)\n"
            . join ("\n", @output), 1);
            
     return;
  } # if

  $output[0] ||= '';
  
  foreach (split / /, $output[0]) {
    ProcessFolder $_, $pvob;

    UpdateSubfolder ($folder, $_, $pvob);    
  } # foreach

  $cmd = "lsfolder -fmt \"%[contains_projects]p\" $folder\@$pvobTag";
  
  ($status, @output) = $Clearcase::CC->execute ($cmd);

  if ($status) {
    $log->err ("Unable to execute command $cmd (Status: $status)\n"
            . join ("\n", @output), 1);

    return;
  } # if
  
  $output[0] ||= '';
  
  foreach (split / /, $output[0]) {
    ProcessProject $_, $folder, $pvob;
  } # foreach
  
  return;
} # ProcessFolder

sub ProcessPvob ($) {
  my ($pvobName) = @_;
  
  $log->msg ("Processing pvob:$pvobName");
  
  UpdatePvob $pvobName;

  ProcessFolder ('RootFolder', $pvobName);
  
  return;
  
  $log->msg ("Finding streams in pvob:$pvobName");
  
  my $pvob = Clearcase::vobtag ($pvobName);
  
  my $cmd = "lsstream -invob $pvob -short";
  my ($status, @streams) = $Clearcase::CC->execute ($cmd);

  $log->err ("Unable to execute $cmd\n" . join ("\n", @streams), $status)
    if $status;

  my %stream = (
    pvob => $pvobName,
  );

  foreach (sort @streams) {
    $stream{name} = $_;
    
    $totals{'Streams processed'}++;
    
    ProcessStream     $stream{name}, $stream{pvob};
  } # foreach
  
  $totals{'Pvobs processed'}++;

  $log->msg ("Finished processing pvob:$pvobName");
  
  return;
} # ProcessPvob

sub ProcessVob ($) {
  my ($name) = @_;
  
  my ($err, $msg);

  my %existingRec = $ccdb->GetVob ($name);
    
  unless (%existingRec) {
    my $vob = Clearcase::Vob->new (Clearcase::vobtag $name);
  
    # If vob doesn't exist then $vob is just an empty shell. Check to see if
    # another field is present to make sure the vob really exists. A vob should
    # always have a region, for example.
    return
      unless $vob->region;
      
    my $vobRegistryAttributes = $vob->vob_registry_attributes;
    
    my $type = ($vobRegistryAttributes and 
                $vobRegistryAttributes =~ /ucmvob/) ? 'ucm' : 'base';
                 
    ($err, $msg) = $ccdb->AddVob ({
      name => $name,
      type => $type,
    });
  
    if ($err) {
      $log->err ("Unable to add vob $name (Error: $err)\n$msg");
    } else {
      $totals{'Vobs added'}++;
    } # if
  } # unless
  
  return;
} # ProcessVob

# Main
local $| = 1;

my $startTime = time;

GetOptions (
  \%opts,
  'verbose' => sub { set_verbose },
  'usage'   => sub { Usage },
  'activity=s',
  'baseline=s',
  'checkchangeset',
  'pvob=s',
  'stream=s',
  'vob=s',
) or Usage "Unknown option";

my $nbrOpts = 0;

$nbrOpts++ if $opts{pvob};
$nbrOpts++ if $opts{activity};
$nbrOpts++ if $opts{baseline};
$nbrOpts++ if $opts{stream};
$nbrOpts++ if $opts{vob};

Usage "Cannot specify -checkchangeset and any other options"
  if $opts{checkchangeset} and $nbrOpts != 0;

Usage "Cannot specify -vob and any other options"
  if $opts{vob} and ($nbrOpts != 1 or $opts{checkchangeset});

my $me = $FindBin::Script;
   $me =~ s/\.pl$//;

if ($opts{activity} and $opts{pvob} and
   ($opts{baseline} or  $opts{stream})) {
  Usage "If -activity is specified then -pvob should be the only other "
      . "option";
  exit 1;
} elsif ($opts{baseline} and $opts{pvob} and
        ($opts{activity} or  $opts{stream})) {
  Usage "If -baseline is specified then -pvob should be the only other "
      . "option";
  exit 1;
} elsif ($opts{stream}   and $opts{pvob} and
        ($opts{activity} or  $opts{baseline})) {
  Usage "If -stream is specified then -pvob should be the only other option";
  exit 1;
} elsif ($opts{pvob}) {
  $nbrOpts = 0;
  
  $nbrOpts++ if $opts{activity};
  $nbrOpts++ if $opts{baseline};
  $nbrOpts++ if $opts{stream};  

  if ($nbrOpts != 0 and $nbrOpts > 1) {
    Usage "If -pvob is specified then it must be used alone or in "
        . "conjunction\nwith only one of -activity, -baseline or -stream "
        . "must be specified\n";
    exit 1;
  } # fi
} # if

if ($opts{activity} and $opts{pvob}) {
  $log = Logger->new;

  $log->msg ("$FindBin::Script V$VERSION");

  UpdateActivity ($opts{activity}, $opts{pvob});
} elsif ($opts{baseline} and $opts{pvob}) {
  $log = Logger->new;

  $log->msg ("$FindBin::Script V$VERSION");

  UpdateBaseline ($opts{baseline}, $opts{pvob});
} elsif ($opts{stream} and $opts{pvob}) {
  $log = Logger->new;

  $log->msg ("$FindBin::Script V$VERSION");

  UpdateStream ($opts{stream}, $opts{pvob});
} elsif ($opts{pvob}) {
  $log = Logger->new (name => "$me.$opts{pvob}");

  $log->msg ("$FindBin::Script V$VERSION");
  
  ProcessPvob $opts{pvob};
} elsif ($opts{checkchangeset}) {
  error "The -checkchangeset option is not implemented yet", 1;
} elsif ($opts{vob}) {
  $log = Logger->new;
  
  $log->msg ("$FindBin::Script V$VERSION");
  
  ProcessVob $opts{vob};
} else {
  $log = Logger->new;
  
  my $UCM = Clearcase::UCM->new;

  $log->msg ("$FindBin::Script V$VERSION");

  ProcessPvob $_
    foreach ($UCM->pvobs);
} # if

display_duration $startTime, $log;

$totals{Errors} = $log->errors;

Stats \%totals, $log;
