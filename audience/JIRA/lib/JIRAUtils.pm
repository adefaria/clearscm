=pod

=head1 NAME $RCSfile: JIRAUtils.pm,v $

Some shared functions dealing with JIRA

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.0 $

=item Created

Fri Mar 12 10:17:44 PST 2004

=item Modified

$Date: 2013/05/30 15:48:06 $

=back

=head1 ROUTINES

The following routines are exported:

=cut

package JIRAUtils;

use strict;
use warnings;

use base 'Exporter';

use FindBin;
use Display;
use Carp;
use DBI;

use JIRA::REST;
use BugzillaUtils;

our ($jira, %opts);

our @EXPORT = qw (
  addJIRAComment
  addDescription
  Connect2JIRA
  findIssue
  getIssue
  getIssueLinks
  getIssueLinkTypes
  getRemoteLinks
  updateIssueWatchers
  linkIssues
  addRemoteLink
  getRemoteLink
  removeRemoteLink
  getRemoteLinkByBugID
  promoteBug2JIRAIssue
  findRemoteLinkByBugID
);

my (@issueLinkTypes, %total, %cache, $jiradb);

sub _checkDBError ($;$) {
  my ($msg, $statement) = @_;

  $statement //= 'Unknown';
  
  $main::log->err ('JIRA database not opened!', 1) unless $jiradb;
  
  my $dberr    = $jiradb->err;
  my $dberrmsg = $jiradb->errstr;
  
  $dberr    ||= 0;
  $dberrmsg ||= 'Success';

  my $message = '';
  
  if ($dberr) {
    my $function = (caller (1)) [3];

    $message = "$function: $msg\nError #$dberr: $dberrmsg\n"
             . "SQL Statement: $statement";
  } # if

  $main::log->err ($message, 1) if $dberr;

  return;
} # _checkDBError

sub openJIRADB (;$$$$) {
  my ($dbhost, $dbname, $dbuser, $dbpass) = @_;

  $dbhost //= $main::opts{jiradbhost};
  $dbname //= 'jiradb';
  $dbuser //= 'adefaria';
  $dbpass //= 'reader';
  
  $main::log->msg ("Connecting to JIRA ($dbuser\@$dbhost)...");
  
  $jiradb = DBI->connect (
    "DBI:mysql:$dbname:$dbhost",
    $dbuser,
    $dbpass, {
      PrintError => 0,
      RaiseError => 1,
    },
  );

  _checkDBError "Unable to open $dbname ($dbuser\@$dbhost)";
  
  return $jiradb;
} # openJIRADB

sub Connect2JIRA (;$$$) {
  my ($username, $password, $server) = @_;

  my %opts;
  
  $opts{username} = $username || 'jira-admin';
  $opts{password} = $password || $ENV{PASSWORD}    || 'jira-admin';
  $opts{server}   = $server   || $ENV{JIRA_SERVER} || 'jira-dev:8081';
  $opts{URL}      = "http://$opts{server}/rest/api/latest";
  
  $main::log->msg ("Connecting to JIRA ($opts{username}\@$opts{server})");
  
  $jira = JIRA::REST->new ($opts{URL}, $opts{username}, $opts{password});

  # Store username as we might need it (see updateIssueWatchers)
  $jira->{username} = $opts{username};
  
  return $jira;  
} # Connect2JIRA

sub addDescription ($$) {
  my ($issue, $description) = @_;
  
  if ($main::opts{exec}) {
    eval {$jira->PUT ("/issue/$issue", undef, {fields => {description => $description}})};
  
    if ($@) {
      return "Unable to add description\n$@";
    } else {
      return 'Description added';
    } # if
  } # if
} # addDescription

sub addJIRAComment ($$) {
  my ($issue, $comment) = @_;
  
  if ($main::opts{exec}) {
    eval {$jira->POST ("/issue/$issue/comment", undef, { body => $comment })};
  
    if ($@) {
      return "Unable to add comment\n$@";
    } else {
      return 'Comment added';
    } # if
  } else {
    return "Would have added comments to $issue";
  } # if
} # addJIRAComment

sub findIssue ($%) {
  my ($bugid, %bugmap) = @_;
  
=pod
  # Check the cache...
  if ($cache{$bugid}) {
    if ($cache{$bugid} =~ /^\d+/) {
      # We have a cache hit but the contents here are a bugid. This means we had
      # searched for the corresponding JIRA issue for this bug before and came
      # up empty handed. In this situtaion we really have:
      return "Unable to find a JIRA issue for Bug $bugid"; 
    } else {
      return $cache{$bugid};
    } # if
  } # if
=cut  
  my $issue;

  my %query = (
    jql    => "\"Bugzilla Bug Number\" ~ $bugid",
    fields => [ 'key' ],
  );
  
  eval {$issue = $jira->GET ("/search/", \%query)};

  my $issueID = $issue->{issues}[0]{key};
  
  if (@{$issue->{issues}} > 2) {
    $main::log->err ("Found more than 2 issues for Bug ID $bugid");
    
    return "Found more than 2 issues for Bug ID $bugid";
  } elsif (@{$issue->{issues}} == 2) {
    my ($issueNum0, $issueNum1);
    
    if ($issue->{issues}[0]{key} =~ /(\d+)/) {
      $issueNum0 = $1;
    } # if
    
    if ($issue->{issues}[1]{key} =~ /(\d+)/) {
      $issueNum1 = $1;
    } # if
    
    if ($issueNum0 < $issueNum1) {
      $issueID = $issue->{issues}[1]{key};
    } # if
    
    # Let's mark them as clones. See if this clone link already exists...
    my $alreadyCloned;
    
    for (getIssueLinks ($issueID, 'Cloners')) {
      my $inwardIssue  = $_->{inwardIssue}{key}  || '';
      my $outwardIssue = $_->{outwardIssue}{key} || '';
      
      if ("RDBNK-$issueNum0" eq $inwardIssue  ||
          "RDBNK-$issueNum0" eq $outwardIssue ||
          "RDBNK-$issueNum1" eq $inwardIssue  ||
          "RDBNK-$issueNum1" eq $outwardIssue) {
         $alreadyCloned = 1;
         
         last;
      } # if
    } # for

    unless ($alreadyCloned) {
      my $result = linkIssues ("RDBNK-$issueNum0", 'Cloners', "RDBNK-$issueNum1");
    
      return $result if $result =~ /Unable to/;
    
      $main::log->msg ($result);
    } # unless
  } # if

  if ($issueID) {
    $main::log->msg ("Found JIRA issue $issueID for Bug $bugid");
  
    #$cache{$bugid} = $issueID;
      
    #return $cache{$bugid};
    return $issueID;
  } else {
    my $status = $bugmap{$bugid} ? 'Future JIRA Issue'
                                 : "Unable to find a JIRA issue for Bug $bugid";
    
    # Here we put this bugid into the cache but instead of a the JIRA issue
    # id we put the bugid. This will stop us from adding up multiple hits on
    # this bugid.
    #$cache{$bugid} = $bugid;

    return $status;
  } # if
} # findJIRA

sub getIssue ($;@) {
  my ($issue, @fields) = @_;
  
  my $fields = @fields ? "?fields=" . join ',', @fields : '';

  return $jira->GET ("/issue/$issue$fields");
} # getIssue

sub getIssueLinkTypes () {
  my $issueLinkTypes = $jira->GET ('/issueLinkType/');
  
  map {push @issueLinkTypes, $_->{name}} @{$issueLinkTypes->{issueLinkTypes}};
  
  return @issueLinkTypes
} # getIssueLinkTypes

sub linkIssues ($$$) {
  my ($from, $type, $to) = @_;
  
  unless (@issueLinkTypes) {
    getIssueLinkTypes;
  } # unless
  
  unless (grep {$type eq $_} @issueLinkTypes) {
    $main::log->err ("Type $type is not a valid issue link type\nValid types include:\n" 
               . join "\n\t", @issueLinkTypes);
               
    return "Unable to $type link $from -> $to";           
  } # unless  
  
  my %link = (
    inwardIssue  => {
      key        => $from,
    },
    type         => {
      name       => $type,
    },
    outwardIssue => {
      key        => $to,
    },
    comment      => {
      body       => "Link ported as part of the migration from Bugzilla: $from <-> $to",
    },
  );
  
  $main::total{'IssueLinks Added'}++;
  
  if ($main::opts{exec}) {
    eval {$jira->POST ("/issueLink", undef, \%link)};
    
    if ($@) {
      return "Unable to $type link $from -> $to\n$@";
    } else {
      return "Made $type link $from -> $to";
    } # if
  } else {
    return "Would have $type linked $from -> $to";
  } # if
} # linkIssue

sub getRemoteLink ($;$) {
  my ($jiraIssue, $id) = @_;
  
  $id //= '';
  
  my $result;
  
  eval {$result = $jira->GET ("/issue/$jiraIssue/remotelink/$id")};
  
  return if $@;
  
  my %remoteLinks;

  if (ref $result eq 'ARRAY') {
    map {$remoteLinks{$_->{id}} = $_->{object}{title}} @$result;  
  } else {
    $remoteLinks{$result->{id}} = $result->{object}{title};
  } # if
    
  return \%remoteLinks;
} # getRemoteLink

sub getRemoteLinks (;$) {
  my ($bugid) = @_;
  
  $jiradb = openJIRADB unless $jiradb;
  
  my $statement = 'select url from remotelink';

  $statement .= " where url like 'http://bugs%'";  
  $statement .= " and url like '%$bugid'" if $bugid; 
  $statement .= " group by issueid desc";
  
  my $sth = $jiradb->prepare ($statement);
  
  _checkDBError 'Unable to prepare statement', $statement;
  
  $sth->execute;
  
  _checkDBError 'Unable to execute statement', $statement;

  my %bugids;
  
  while (my $record = $sth->fetchrow_array) {
    if ($record =~ /(\d+)$/) {
      $bugids{$1} = 1;
    } # if 
  } # while
  
  return keys %bugids;
} # getRemoteLinks

sub findRemoteLinkByBugID (;$) {
  my ($bugid) = @_;
  
  my $condition = 'where issueid = jiraissue.id and jiraissue.project = project.id';
  
  if ($bugid) {
    $condition .= " and remotelink.url like '%id=$bugid'";
  } # unless
  
  $jiradb = openJIRADB unless $jiradb;

  my $statement = <<"END";
select 
  remotelink.id, 
  concat (project.pkey, '-', issuenum) as issue,
  relationship
from
  remotelink,
  jiraissue,
  project
$condition
END

  my $sth = $jiradb->prepare ($statement);
  
  _checkDBError 'Unable to prepare statement', $statement;
  
  $sth->execute;
  
  _checkDBError 'Unable to execute statement', $statement;
  
  my @records;
  
  while (my $row = $sth->fetchrow_hashref) {
    $row->{bugid} = $bugid;
        
    push @records, $row;
  } # while
  
  return \@records;
} # findRemoteLinkByBugID

sub promoteBug2JIRAIssue ($$$$) {
  my ($bugid, $jirafrom, $jirato, $relationship) = @_;

  my $result = linkIssues $jirafrom, $relationship, $jirato;
        
  return $result if $result =~ /Unable to link/;
  
  $main::log->msg ($result . " (BugID $bugid)");
  
  for (@{findRemoteLinkByBugID $bugid}) {
    my %record = %$_;
    
    $result = removeRemoteLink ($record{issue}, $record{id});
    
    # We may not care if we couldn't remove this link because it may have been
    # removed by a prior pass.
    return $result if $result =~ /Unable to remove link/;
    
    $main::log->msg ($result) unless $result eq '';
  } # for
  
  return $result;
} # promoteBug2JIRAIssue

sub addRemoteLink ($$$) {
  my ($bugid, $relationship, $jiraIssue) = @_;
  
  my $bug = getBug $bugid;
  
  # Check to see if this Bug ID already exists on this JIRA Issue, otherwise
  # JIRA will duplicate it! 
  my $remoteLinks = getRemoteLink $jiraIssue;
  
  for (keys %$remoteLinks) {
    if ($remoteLinks->{$_} =~ /Bug (\d+)/) {
      return "Bug $bugid is already linked to $jiraIssue" if $bugid == $1;
    } # if
  } # for
  
  # Note this globalid thing is NOT working! ALl I see is null in the database
  my %remoteLink = (
#    globalid     => "system=http://bugs.audience.com/show_bug.cgi?id=$bugid",
#    application  => {
#      type       => 'Bugzilla',
#      name       => 'Bugzilla',
#    },
    relationship => $relationship, 
    object       => {
      url        => "http://bugs.audience.com/show_bug.cgi?id=$bugid",
      title      => "Bug $bugid",
      summary    => $bug->{short_desc},
      icon       => {
        url16x16 => 'http://bugs.audience.local/favicon.png',
        title    => 'Bugzilla Bug',
      },
    },
  );
  
  $main::total{'RemoteLink Added'}++;
  
  if ($main::opts{exec}) {
    eval {$jira->POST ("/issue/$jiraIssue/remotelink", undef, \%remoteLink)};
  
    return $@;
  } else {
    return "Would have linked $bugid -> $jiraIssue";
  } # if
} # addRemoteLink

sub removeRemoteLink ($;$) {
  my ($jiraIssue, $id) = @_;
  
  $id //= '';
  
  my $remoteLinks = getRemoteLink ($jiraIssue, $id);
  
  for (keys %$remoteLinks) {
    my $result;
    
    $main::total{'RemoteLink Removed'}++;
  
    if ($main::opts{exec}) {
      eval {$result = $jira->DELETE ("/issue/$jiraIssue/remotelink/$_")};

      if ($@) {  
        return "Unable to remove remotelink $jiraIssue ($id)\n$@" if $@;
      } else {
        my $bugid;
        
        if ($remoteLinks->{$_} =~ /(\d+)/) {
          return "Removed remote link $jiraIssue (Bug ID $1)";
        } # if
      } # if
      
      $main::total{'Remote Links Removed'}++;
    } else {
      if ($remoteLinks->{$_} =~ /(\d+)/) {
        return "Would have removed remote link $jiraIssue (Bug ID $1)";
      } # if
    } # if
  } # for  
} # removeRemoteLink

sub getIssueLinks ($;$) {
  my ($issue, $type) = @_;
  
  my @links = getIssue ($issue, ('issuelinks'));
  
  my @issueLinks;

  for (@{$links[0]->{fields}{issuelinks}}) {
     my %issueLink = %$_;
     
     next if ($type && $type ne $issueLink{type}{name});
     
     push @issueLinks, \%issueLink;  
  }
  
  return @issueLinks;
} # getIssueLinks

sub updateIssueWatchers ($%) {
  my ($issue, %watchers) = @_;

  my $existingWatchers;
  
  eval {$existingWatchers = $jira->GET ("/issue/$issue/watchers")};
  
  return "Unable to get issue $issue\n$@" if $@;
  
  for (@{$existingWatchers->{watchers}}) {
    # Cleanup: Remove the current user from the watchers list.
    # If he's on the list then remove him.
    if ($_->{name} eq $jira->{username}) {
      $jira->DELETE ("/issue/$issue/watchers?username=$_->{name}");
      
      $total{"Admins destroyed"}++;
    } # if
    
    # Delete any matching watchers
    delete $watchers{lc ($_->{name})} if $watchers{lc ($_->{name})};
  } # for

  return '' if keys %watchers == 0;
  
  my $issueUpdated;
  
  for (keys %watchers) {
    if ($main::opts{exec}) {
      eval {$jira->POST ("/issue/$issue/watchers", undef, $_)};
    
      if ($@) {
        $main::log->warn ("Unable to add user $_ as a watcher to JIRA Issue $issue");
      
        $main::total{'Watchers skipped'}++;
      } else {
        $issueUpdated = 1;
        
        $main::total{'Watchers added'}++;
      } # if
    } else {
      $main::log->msg ("Would have added user $_ as a watcher to JIRA Issue $issue");
      
      $main::total{'Watchers that would have been added'}++;
    } # if
  } # for
  
  $main::total{'Issues updated'}++ if $issueUpdated;
  
  return '';
} # updateIssueWatchers

=pod

I'm pretty sure I'm not using this routine anymore and I don't think it works.
If you wish to reserect this then please test.

sub updateWatchers ($%) {
  my ($issue, %watchers) = @_;

  my $existingWatchers;
  
  eval {$existingWatchers = $jira->GET ("/issue/$issue/watchers")};
  
  if ($@) {
    error "Unable to get issue $issue";
    
    $main::total{'Missing JIRA Issues'}++;
    
    return;
  } # if
  
  for (@{$existingWatchers->{watchers}}) {
    # Cleanup: Mike Admin Cogan was added as a watcher for each issue imported.
    # If he's on the list then remove him.
    if ($_->{name} eq 'mcoganAdmin') {
      $jira->DELETE ("/issue/$issue/watchers?username=$_->{name}");
      
      $main::total{"mcoganAdmin's destroyed"}++;
    } # if
    
    # Delete any matching watchers
    delete $watchers{$_->{name}} if $watchers{$_->{name}};
  } # for

  return if keys %watchers == 0;
  
  my $issueUpdated;
  
  for (keys %watchers) {
    if ($main::opts{exec}) {
      eval {$jira->POST ("/issue/$issue/watchers", undef, $_)};
    
      if ($@) {
        error "Unable to add user $_ as a watcher to JIRA Issue $issue";
      
        $main::total{'Watchers skipped'}++;
      } else {
        $main::total{'Watchers added'}++;
        
        $issueUpdated = 1;
      } # if
    } else {
      $main::log->msg ("Would have added user $_ as a watcher to JIRA Issue $issue");
      
      $main::total{'Watchers that would have been added'}++;
    } # if
  } # for
  
  $main::total{'Issues updated'}++ if $issueUpdated;
  
  return;
} # updateWatchers
=cut

1;
