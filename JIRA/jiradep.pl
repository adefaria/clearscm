#!/usr/bin/perl
use strict;
use warnings;

=pod

=head1 NAME jiradep.pl

Update Bugzilla dependencies (Dependencies/Blockers/Duplicates and Related),
transfering those relationships over to any matching JIRA issues. 

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: #1 $

=item Created

Thu Mar 20 10:11:53 PDT 2014

=item Modified

$Date: 2014/05/23 $

=back

=head1 SYNOPSIS

  $ jiradep.pl [-bugzillaserver <bugshost>] [-login <login email>]
               [-jiraserver <server>]
               [-username <username>] [-password <password>] 
               [-bugids bugid,bugid,... | -file <filename>] 
               [-[no]exec] [-linkbugzilla] [-relinkbugzilla]
               [-verbose] [-help] [-usage]

  Where:

    -v|erbose:       Display progress output
    -he|lp:          Display full help
    -usa|ge:         Display usage
    -[no]e|xec:      Whether or not to update Bugilla. -noexec says only 
                     tell me what you would have updated.
    -use|rname:      Username to log into JIRA with (Default: jira-admin)
    -p|assword:      Password to log into JIRA with (Default: jira-admin's 
                     password)
    -bugzillaserver: Machine where Bugzilla lives (Default: bugs-dev)
    -jiraserver:     Machine where Jira lives (Default: jira-dev)
    -bugi|ds:        Comma separated list of BugIDs to process
    -f|ile:          File of BugIDs, one per line
    -linkbugzilla:   If specified and we find that we cannot translate
                     a Bugzilla Bud ID to a JIRA Issue then create a 
                     remote link for the Bugzilla Bug. (Default:
                     do not create Bugzilla remote links).
    -relinkbugzilla: Scan current Remote Bugzilla links and if there
                     exists a corresponding JIRA issue, remove the 
                     Remote Bugzilla link and make it a JIRA Issue
                     link.
    -jiradbhost:     Host name of the machine where the MySQL jiradb
                     database is located (Default: cm-db-ldev01)

=head1 DESCRIPTION

This script will process all BugIDs translating them into JIRA Issues, if
applicable. It will then determine the relationships of this BugID in Bugzilla -
what it blocks, what it depends on, if it's a duplicate of another bug or if
it has any related links. Those too will be translated to JIRA issues, again,
if applicable. Then the JIRA issue will be updates to reflect these 
relationships. 

Note that it's not known at this time what to do for situations where BugIDs
cannot be translated into JIRA issues if such Bugzilla bugs have not yet been
migrated to JIRA. There's a though to simply make a Bugzilla Link but we will
need to keep that in mind and when we import the next project to JIRA these
old, no longer used Bugzilla Links should be converted to their corresponding 
JIRA issue. Perhaps this script can do that too.

=cut

use FindBin;
use lib "$FindBin::Bin/lib";

$| = 1;

use DBI;
use Display;
use Logger;
use TimeUtils;
use Utils;
use JIRAUtils;
use BugzillaUtils;

use Getopt::Long; 
use Pod::Usage;

our %opts = (
  exec           => 0,
  bugzillaserver => $ENV{BUGZILLASERVER} || 'bugs-dev',
  jiraserver     => $ENV{JIRASERVER}     || 'jira-dev',
  jiradbhost     => $ENV{JIRA_DB_HOST}   || 'cm-db-ldev01',
  username       => 'jira-admin',
  password       => 'jira-admin',
  usage          => sub { pod2usage },
  help           => sub { pod2usage (-verbose => 2)},
  verbose        => sub { set_verbose },
  quiet          => 0,
  usage          => sub { pod2usage },
  help           => sub { pod2usage (-verbose => 2)},
);

our ($log, %total);

my %relationshipMap = (
  Blocks    => 'Dependencies Linked',
  Duplicate => 'Duplicates Linked',
  Related   => 'Related Linked',
);

sub callLink ($$$$) {
  my ($from, $type, $to, $counter) = @_;

  my $bugzillaType;
  
  if ($from =~ /^\d+/) {
    if ($type eq 'Blocks') {
      $bugzillaType = 'is blocked by (Bugzilla)';
    } elsif ($type eq 'Duplicate') {
      $bugzillaType = 'duplicate (Bugzilla)';
    } elsif ($type eq 'Related') {
      $bugzillaType = 'related (Bugzilla)';
    } # if
  } elsif ($to =~ /^\d+/) {
    if ($type eq 'Blocks') {
      $bugzillaType = 'blocks (Bugzilla)';
    } elsif ($type eq 'Duplicate') {
      $bugzillaType = 'duplicate (Bugzilla)';
    } elsif ($type eq 'Related') {
      $bugzillaType = 'related (Bugzilla)';
    } # if
  } # if
    
  $total{$counter}++;

  if ($from =~ /^\d+/ && $to =~ /^\d+/) {
    $total{'Skipped Bugzilla Links'}++;
    
    return "Refusing to link because both from ($from) and to ($to) links are still a Bugzilla link";
  } elsif ($from =~ /^\d+/) {
    if ($opts{linkbugzilla}) {
      my $result = addRemoteLink $from, $bugzillaType, $to;

      $total{'Bugzilla Links'}++ unless $result;
    
      if ($result eq '') {
        return "Created remote $type link between Issue $to and Bug $from";
      } else {
        return $result;
      } # if 
    } else {
      $total{'Skipped Bugzilla Links'}++;
    
      return "Refusing to link because from link ($from) is still a Bugzilla link";
    } # if
  } elsif ($to =~ /^\d+/) {
    if ($opts{linkbugzilla}) {
      my $result = addRemoteLink $to, $bugzillaType, $from;
    
      $total{'Bugzilla Links'}++ unless $result;

      if (!defined $result) {
        print "huh?";
      }
      if ($result eq '') {
        return "Created remote $type link between Issue $from and Bug $to";
      } else {
        return $result;
      } # if 
    } else {
      $total{'Skipped Bugzilla Links'}++;
    
      return "Refusing to link because to link ($to) is still a Bugzilla link";
    } # if
  } # if
   
  my $result = linkIssues $from, $type, $to;
  
  $log->msg ($result);
    
  if ($result =~ /^Unable/) {
    $total{'Link Failures'}++;
  } elsif ($result =~ /^Link made/) {
    $total{'Links made'}++;
  } elsif ($result =~ /^Would have linked/) {
    $total{'Links would be made'}++;
  } # if
      
  return;
} # callLink

sub relinkBugzilla (@) {
  my (@bugids) = @_;
  
  my %mapRelationships = (
    'blocks (Bugzilla)'           => 'Blocks',
    'is blocked by (Bugzilla)'    => 'Blocks',
    'duplicates (Bugzilla)'       => 'Duplicates',
    'is duplicated by (Bugzilla)' => 'Duplicates',
    # old versions...
    'Bugzilla blocks'             => 'Blocks',
    'Bugzilla is blocked by'      => 'Blocks',
    'Bugzilla duplicates'         => 'Duplicates',
    'Bugzilla is duplicated by'   => 'Duplicates',
  );
  
  @bugids = getRemoteLinks unless @bugids;
  
  for my $bugid (@bugids) {
    $total{'Remote Links Scanned'}++;
    
    my $links = findRemoteLinkByBugID $bugid;

    my $jirafrom = findIssue ($bugid);
    
    next if $jirafrom !~ /^[A-Z]{1,5}-\d+$/;
        
    for (@$links) {
      my %link = %$_;
      
      # Found a link to JIRA. Remove remotelink and make an issuelink
      if ($mapRelationships{$link{relationship}}) {
        my ($fromIssue, $toIssue);
        
        if ($link{relationship} =~ / by/) {
          $fromIssue = $jirafrom;
          $toIssue   = $link{issue};
        } else {
          $fromIssue = $link{issue};
          $toIssue   = $jirafrom;
        } # if
        
        my $status = promoteBug2JIRAIssue $bugid, $fromIssue, $toIssue,
                                          $mapRelationships{$link{relationship}};

        $log->err ($status) if $status =~ /Unable to link/;
      } else {
        $log->err ("Unable to handle relationships of type $link{relationship}");
      } # if
    } # for
  } # for
    
  return;
} # relinkBugzilla

sub main () {
  my $startTime = time;
  
  GetOptions (
    \%opts,
    'verbose',
    'usage',
    'help',
    'exec!',
    'quiet',
    'username=s',
    'password=s',
    'bugids=s@',
    'file=s',
    'jiraserver=s',
    'bugzillaserver=s',
    'linkbugzilla',
    'relinkbugzilla',
    'jiradbhost=s',
  ) or pod2usage;
  
  $log = Logger->new;

  if ($opts{file}) {
    open my $file, '<', $opts{file} 
      or $log->err ("Unable to open $opts{file} - $!", 1);
      
    $opts{bugids} = [<$file>];
    
    chomp @{$opts{bugids}};
  } else {
    my @bugids;
    
    push @bugids, (split /,/, join (',', $_)) for (@{$opts{bugids}}); 
  
    $opts{bugids} = [@bugids];
  } # if
  
  pod2usage 'Must specify -bugids <bugid>[,<bugid>,...] or -file <filename>'
    unless ($opts{bugids} > 0 or $opts{relinkbugzilla});
  
  openBugzilla $opts{bugzillaserver}
    or $log->err ("Unable to connect to $opts{bugzillaserver}", 1);
  
  Connect2JIRA ($opts{username}, $opts{password}, $opts{jiraserver})
    or $log->err ("Unable to connect to $opts{jiraserver}", 1);

  if ($opts{relinkbugzilla}) {
    unless (@{$opts{bugids}}) {
      relinkBugzilla;
    } else {
      relinkBugzilla $_ for @{$opts{bugids}}
    } # unless
        
    Stats (\%total, $log);
    
    exit $log->errors;
  } # if
  
  my %relationships;
  
  # The 'Blocks' IssueLinkType has two types of relationships in it - both
  # blocks and dependson. Since JIRA has only one type - Blocks - we take
  # the $dependson and flip the from and to.
  my $blocks    = getBlockers @{$opts{bugids}};
  my $dependson = getDependencies @{$opts{bugids}};
  
  # Now merge them - we did it backwards!
  for my $fromLink (keys %$dependson) {
    for my $toLink (@{$dependson->{$fromLink}}) {
      push @{$relationships{Blocks}{$toLink}}, $fromLink;
    } # for
  } # for

  #%{$relationships{Blocks}} = %$dependson;
  
  for my $fromLink (keys %$blocks) {
    # Check to see if we already have the reverse of this link
    for my $toLink (@{$blocks->{$fromLink}}) {
      unless (grep {$toLink eq $_} keys %{$relationships{Blocks}}) {
        push @{$relationships{Blocks}{$fromLink}}, $toLink;
      } # unless
    } # for
  } # for
  
  $relationships{Duplicate} = getDuplicates   @{$opts{bugids}};
  $relationships{Relates}   = getRelated      @{$opts{bugids}};
  
  # Process relationships (social programming... ;-)
  $log->msg ("Processing relationships");
  
  for my $type (keys %relationshipMap) {
    for my $from (keys %{$relationships{$type}}) {
      for my $to (@{$relationships{$type}{$from}}) {
        $total{'Relationships processed'}++;
        
        my $result = callLink $from, $type, $to, $relationshipMap{$type};
        
        $log->msg ($result) if $result;
      } # for
    } # for
  } # if

  display_duration $startTime, $log;
  
  Stats (\%total, $log) unless $opts{quiet};

  return;
} # main

main;

exit;