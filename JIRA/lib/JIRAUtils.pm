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

our $jira;

our @EXPORT = qw (
  Connect2JIRA
  addDescription
  addJIRAComment
  addRemoteLink
  attachFiles2Issue
  attachmentExists
  blankBugzillaNbr
  copyGroupMembership
  count
  findIssue
  findIssues
  findRemoteLinkByBugID
  getIssue
  getIssueFromBugID
  getIssueLinkTypes
  getIssueLinks
  getIssueWatchers
  getIssues
  getNextIssue
  getRemoteLink
  getRemoteLinkByBugID
  getRemoteLinks
  getUsersGroups
  linkIssues
  promoteBug2JIRAIssue
  removeRemoteLink
  renameUsers
  updateColumn
  updateIssueWatchers
  updateUsersGroups
);

my (@issueLinkTypes, %cache, $jiradb, %findQuery);

my %tables = (
  ao_08d66b_filter_display_conf => [
                                     {column    => 'user_name'}
                                   ],
  ao_0c0737_vote_info           => [
                                     {column    => 'user_name'}
                                   ],
  ao_3a112f_audit_log_entry     => [
                                     {column    => 'user'}
                                   ],                                   
  ao_563aee_activity_entity     => [
                                     {column    => 'username'}
                                   ],
  ao_60db71_auditentry          => [
                                     {column    => 'user'}
                                   ],
  ao_60db71_boardadmins         => [
                                     {column    => "'key'"}
                                   ],
  ao_60db71_rapidview           => [
                                     {column    => 'owner_user_name'}
                                   ],
  ao_caff30_favourite_issue     => [
                                     {column    => 'user_key'}
                                   ],
#  app_user                      => [
#                                     {column    => 'user_key'},
#                                     {column    => 'lower_user_name'},
#                                   ],
  audit_log                     => [
                                     {column    => 'author_key'}
                                   ],
  avatar                        => [
                                     {column    => 'owner'}
                                   ],
  changegroup                   => [
                                     {column    => 'author'}
                                   ],
  changeitem                    => [
                                     {column    => 'oldvalue',
                                      condition => 'field = "assignee"'},
                                     {column    => 'newvalue',
                                      condition => 'field = "assignee"'},
                                   ],
  columnlayout                  => [
                                     {column    => 'username'},
                                   ],
  component                     => [
                                     {column    => 'lead'},
                                   ],
  customfieldvalue              => [
                                     {column    => 'stringvalue'},
                                   ],
  favouriteassociations         => [
                                     {column    => 'username'},
                                   ],                                   
#  cwd_membership                => [
#                                     {column    => 'child_name'},
#                                     {column    => 'lower_child_name'},
#                                   ],
  fileattachment                => [
                                     {column    => 'author'},
                                   ],
  filtersubscription            => [
                                     {column    => 'username'},
                                   ],
  jiraaction                    => [
                                     {column    => 'author'},
                                   ],
  jiraissue                     => [
                                     {column    => 'reporter'},
                                     {column    => 'assignee'},
                                   ],
  jiraworkflows                 => [
                                     {column    => 'creatorname'},
                                   ],
  membershipbase                => [
                                     {column    => 'user_name'},
                                   ],
  os_currentstep                => [
                                     {column    => 'owner'},
                                     {column    => 'caller'},
                                   ],
  os_historystep                => [
                                     {column    => 'owner'},
                                     {column    => 'caller'},
                                   ],
  project                       => [
                                     {column    => 'lead'},
                                   ],
  portalpage                    => [
                                     {column    => 'username'},
                                   ],
  schemepermissions             => [
                                     {column    => 'perm_parameter',
                                      condition => 'perm_type = "user"'},
                                   ],
  searchrequest                 => [
                                     {column    => 'authorname'},
                                     {column    => 'username'},
                                   ],
  userassociation               => [
                                     {column    => 'source_name'},
                                   ],
  userbase                      => [
                                     {column    => 'username'},
                                   ],
  userhistoryitem               => [
                                     {column    => 'username'}
                                   ],
  worklog                       => [
                                     {column    => 'author'},
                                   ],
);

sub _checkDBError ($;$) {
  my ($msg, $statement) = @_;

  $statement //= 'Unknown';

  if ($main::log) {
   $main::log->err ('JIRA database not opened!', 1) unless $jiradb;
  } # if

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

  if ($main::log) {
    $main::log->err ($message, 1) if $dberr;
  } # if

  return;
} # _checkDBError

sub openJIRADB (;$$$$) {
  my ($dbhost, $dbname, $dbuser, $dbpass) = @_;

=pod

=head2 openJIRADB ()

Opens the JIRA database directly using MySQL. This is only for certain 
operations for which there is no corresponding REST interface

Parameters:

=for html <blockquote>

=over

=item $dbhost

Name of the database host

=item $dbname

database name

=item $dbuser

Database user name

=item $dbpass

Database user's password

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item $dbhandle

Handle for database

=back

=for html </blockquote>

=cut

  $dbhost //= $main::opts{jiradbhost};
  $dbname //= 'jiradb';
  $dbuser //= 'root';
  $dbpass //= '*********';

  $main::log->msg ("Connecting to JIRA ($dbuser\@$dbhost)...") if $main::log;

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

=pod

=head2 Connect2JIRA ()

Establishes a connection to the JIRA instance using the REST API

Parameters:

=for html <blockquote>

=over

=item $username

Username to authenticate with

=item $password

Password to authenticate with

=item $server

JIRA server to connect to

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item $jira

JIRA REST handle

=back

=for html </blockquote>

=cut

  my %opts;

  $opts{username} = $username || 'jira-admin';
  $opts{password} = $password || $ENV{PASSWORD}    || '********';
  $opts{server}   = $server   || $ENV{JIRA_SERVER} || 'jira-dev';
  $opts{URL}      = "http://$opts{server}/rest/api/latest";

  $main::log->msg ("Connecting to JIRA ($opts{username}\@$opts{server})") if $main::log;

  $jira = JIRA::REST->new ($opts{URL}, $opts{username}, $opts{password});

  # Store username as we might need it (see updateIssueWatchers)
  $jira->{username} = $opts{username};

  return $jira;  
} # Connect2JIRA

sub count ($$) {
  my ($table, $condition) = @_;

=pod

=head2 count ()

Return the count of a table in the JIRA database given a condition

Parameters:

=for html <blockquote>

=over

=item $table

Name of table to perform count of

=item $condition

MySQL condition to apply

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item $count

Count of qualifying entries

=back

=for html </blockquote>

=cut

  my $statement;

  $jiradb = openJIRADB unless $jiradb;

  if ($condition) {
    $statement = "select count(*) from $table where $condition";
  } else {
    $statement = "select count(*) from $table";
  } # if

  my $sth = $jiradb->prepare ($statement);

  _checkDBError 'count: Unable to prepare statement', $statement;

  $sth->execute;

  _checkDBError 'count: Unable to execute statement', $statement;

  # Get return value, which should be how many message there are
  my @row = $sth->fetchrow_array;

  # Done with $sth
  $sth->finish;

  my $count;

  # Retrieve returned value
  unless ($row[0]) {
    $count = 0
  } else {
    $count = $row[0];
  } # unless

  return $count
} # count

sub addDescription ($$) {
  my ($issue, $description) = @_;
  
=pod

=head2 addDescription ()

Add a description to a JIRA issue

Parameters:

=for html <blockquote>

=over

=item $issue

Issue ID

=item $description

Description to add

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item <nothing>

=back

=for html </blockquote>

=cut

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

=pod

=head2 addJIRAComment ()

Add a comment to a JIRA issue

Parameters:

=for html <blockquote>

=over

=item $issue

Issue ID

=item $comment

Comment to add

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item <nothing>

=back

=for html </blockquote>

=cut

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

sub blankBugzillaNbr ($) {
  my ($issue) = @_;

  eval {$jira->PUT ("/issue/$issue", undef, {fields => {'Bugzilla Bug Origin' => ''}})};
  #eval {$jira->PUT ("/issue/$issue", undef, {fields => {'customfield_10132' => ''}})};

  if ($@) {
    return "Unable to blank Bugzilla number$@\n"
  } else {
    return 'Corrected'
  } # if
} # blankBugzillaNbr

sub attachmentExists ($$) {
  my ($issue, $filename) = @_;

=pod

=head2 attachmentExists ()

Determine if an attachment to a JIRA issue exists

Parameters:

=for html <blockquote>

=over

=item $issue

Issue ID

=item $filename

Filename of attachment

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item <nothing>

=back

=for html </blockquote>

=cut

  my $attachments = getIssue ($issue, qw(attachment));

  for (@{$attachments->{fields}{attachment}}) {
    return 1 if $filename eq $_->{filename};
  } # for

  return 0;
} # attachmentExists

sub attachFiles2Issue ($@) {
  my ($issue, @files) = @_;

=pod

=head2 attachFiles2Issue ()

Attach a list of files to a JIRA issue

Parameters:

=for html <blockquote>

=over

=item $issue

Issue ID

=item @files

List of filenames

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item <nothing>

=back

=for html </blockquote>

=cut  

  my $status = $jira->attach_files ($issue, @files);

  return $status;
} # attachFiles2Issue

sub getIssueFromBugID ($) {
  my ($bugid) = @_;

  my $issue;

  my %query = (
    jql    => "\"Bugzilla Bug Origin\" ~ $bugid",
    fields => [ 'key' ],
  );

  eval {$issue = $jira->GET ("/search/", \%query)};

  my $issueID = $issue->{issues}[0]{key};

  return $issue->{issues} if @{$issue->{issues}} > 1;
  return $issueID;
} # getIssueFromBugID

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
    jql    => "\"Bugzilla Bug Origin\" ~ $bugid",
    fields => [ 'key' ],
  );

  eval {$issue = $jira->GET ("/search/", \%query)};

  my $issueID = $issue->{issues}[0]{key};

  if (@{$issue->{issues}} > 2) {
    $main::log->err ("Found more than 2 issues for Bug ID $bugid") if $main::log;

    return "Found more than 2 issues for Bug ID $bugid";
  } elsif (@{$issue->{issues}} == 2) {
    my ($issueNum0, $issueNum1, $projectName0, $projectName1);

    if ($issue->{issues}[0]{key} =~ /(.*)-(\d+)/) {
      $projectName0 = $1;
      $issueNum0    = $2;
    } # if

    if ($issue->{issues}[1]{key} =~ /(.*)-(\d+)/) {
      $projectName1 = $1;
      $issueNum1    = $2;
    } # if

    if ($issueNum0 < $issueNum1) {
      $issueID = $issue->{issues}[1]{key};
    } # if

    # Let's mark them as clones. See if this clone link already exists...
    my $alreadyCloned;

    for (getIssueLinks ($issueID, 'Cloners')) {
      my $inwardIssue  = $_->{inwardIssue}{key}  || '';
      my $outwardIssue = $_->{outwardIssue}{key} || '';

      if ("$projectName0-$issueNum0" eq $inwardIssue  ||
          "$projectName0-$issueNum0" eq $outwardIssue ||
          "$projectName1-$issueNum1" eq $inwardIssue  ||
          "$projectName1-$issueNum1" eq $outwardIssue) {
         $alreadyCloned = 1;

         last;
      } # if
    } # for

    unless ($alreadyCloned) {
      my $result = linkIssues ("$projectName0-$issueNum0", 'Cloners', "$projectName1-$issueNum1");

      return $result if $result =~ /Unable to/;

      $main::log->msg ($result) if $main::log;
    } # unless
  } # if

  if ($issueID) {
    $main::log->msg ("Found JIRA issue $issueID for Bug $bugid") if $main::log;

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

sub findIssues (;$@) {
  my ($condition, @fields) = @_;

=pod

=head2 findIssues ()

Set up a find for JIRA issues based on a condition

Parameters:

=for html <blockquote>

=over

=item $condition

Condition to use. JQL is supported

=item @fields

List of fields to retrieve data for

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item <nothing>

=back

=for html </blockquote>

=cut  

  push @fields, '*all' unless @fields;

  $findQuery{jql}        = $condition || '';
  $findQuery{startAt}    = 0;
  $findQuery{maxResults} = 1;
  $findQuery{fields}     = join ',', @fields;

  return;
} # findIssues

sub getNextIssue () {
  my $result;

=pod

=head2 getNextIssue ()

Get next qualifying issue. Call findIssues first

Parameters:

=for html <blockquote>

=over

=item <none>

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item %issue

Perl hash of the fields in the next JIRA issue

=back

=for html </blockquote>

=cut

  eval {$result = $jira->GET ('/search/', \%findQuery)};

  $findQuery{startAt}++;

  # Move id and key into fields
  return unless @{$result->{issues}};

  $result->{issues}[0]{fields}{id} = $result->{issues}[0]{id};
  $result->{issues}[0]{fields}{key} = $result->{issues}[0]{key};

  return %{$result->{issues}[0]{fields}};
} # getNextIssue

sub getIssues (;$$$@) {
  my ($condition, $start, $max, @fields) = @_;

=pod

=head2 getIssues ()

Get the @fields of JIRA issues based on a condition. Note that JIRA limits the
amount of entries returned to 1000. You can get fewer. Or you can use $start
to continue from where you've left off. 

Parameters:

=for html <blockquote>

=over

=item $condition

JQL condition to apply

=item $start

Starting point to get issues from

=item $max

Max number of entrist to get

=item @fields

List of fields to retrieve

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item @issues

Perl array of hashes of JIRA issue records

=back

=for html </blockquote>

=cut

  push @fields, '*all' unless @fields;

  my ($result, %query);

  $query{jql}        = $condition || '';
  $query{startAt}    = $start     || 0;
  $query{maxResults} = $max       || 50;
  $query{fields}     = join ',', @fields;

  eval {$result = $jira->GET ('/search/', \%query)};

  # We sometimes get an error here when $result->{issues} is undef.
  # I suspect this is when the number of issues just happens to be
  # an even number like on a $query{maxResults} boundry. So when
  # $result->{issues} is undef we assume it's the last of the issues.
  # (I should really verify this).
  if ($result->{issues}) {
    return @{$result->{issues}};
  } else {
    return;
  } # if
} # getIssues

sub getIssue ($;@) {
  my ($issue, @fields) = @_;

=pod

=head2 getIssue ()

Get individual JIRA issue

Parameters:

=for html <blockquote>

=over

=item $issue

Issue ID

=item @fields

List of fields to retrieve

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item %issue

Perl hash of JIRA issue

=back

=for html </blockquote>

=cut

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
    $main::log->err ("Type $type is not a valid issue link type\nValid types include:\n\t" 
               . join "\n\t", @issueLinkTypes) if $main::log;

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

=pod

=head2 getRemoteLink ()

Retrieve a remote link

Parameters:

=for html <blockquote>

=over

=item $jiraIssue

Issue ID

=item $id

Which ID to retrieve

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item %issue

Perl hash of remote links

=back

=for html </blockquote>

=cut

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

  $main::log->msg ($result . " (BugID $bugid)") if $main::log;

  for (@{findRemoteLinkByBugID $bugid}) {
    my %record = %$_;

    $result = removeRemoteLink ($record{issue}, $record{id});

    # We may not care if we couldn't remove this link because it may have been
    # removed by a prior pass.
    return $result if $result =~ /Unable to remove link/;

    if ($main::log) {
      $main::log->msg ($result) unless $result eq '';
    } # if
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
  } # for

  return @issueLinks;
} # getIssueLinks

sub getIssueWatchers ($) {
  my ($issue) = @_;

  my $watchers;

  eval {$watchers = $jira->GET ("/issue/$issue/watchers")};

  return if $@;

  # The watcher information returned by the above is incomplete. Let's complete
  # it.
  my @watchers;

  for (@{$watchers->{watchers}}) {
    my $user;

    eval {$user = $jira->GET ("/user?username=$_->{key}")};

    unless ($@) {
      push @watchers, $user;
    } else {
      if ($main::log) {
        $main::log->err ("Unable to find user record for $_->{name}")
          unless $_->{name} eq 'jira-admin';
      }# if
    } # unless
  } # for

  return @watchers;
} # getIssueWatchers

sub updateIssueWatchers ($%) {
  my ($issue, %watchers) = @_;

=pod

=head2 updateIssueWatchers ()

Updates the issue watchers list

Parameters:

=for html <blockquote>

=over

=item $issue

Issue ID

=item %watchers

List of watchers to add

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item $error 

Error message or '' to indicate no error

=back

=for html </blockquote>

=cut

  my $existingWatchers;

  eval {$existingWatchers = $jira->GET ("/issue/$issue/watchers")};

  return "Unable to get issue $issue\n$@" if $@;

  for (@{$existingWatchers->{watchers}}) {
    # Cleanup: Remove the current user from the watchers list.
    # If he's on the list then remove him.
    if ($_->{name} eq $jira->{username}) {
      $jira->DELETE ("/issue/$issue/watchers?username=$_->{name}");

      $main::total{"Admins destroyed"}++;
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
        $main::log->warn ("Unable to add user $_ as a watcher to JIRA Issue $issue") if $main::log;

        $main::total{'Watchers skipped'}++;
      } else {
        $issueUpdated = 1;

        $main::total{'Watchers added'}++;
      } # if
    } else {
      $main::log->msg ("Would have added user $_ as a watcher to JIRA Issue $issue") if $main::log;

      $main::total{'Watchers that would have been added'}++;
    } # if
  } # for

  $main::total{'Issues updated'}++ if $issueUpdated;

  return '';
} # updateIssueWatchers

sub getUsersGroups ($) {
  my ($username) = @_;

=pod

=head2 getUsersGroups ()

Returns the groups that the user is a member of

Parameters:

=for html <blockquote>

=over

=item $username

Username

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item @groups

List of groups

=back

=for html </blockquote>

=cut
  
  my ($result, %query);

  %query = (
    username => $username,
    expand   => 'groups',
  );

  eval {$result = $jira->GET ('/user/', \%query)};

  my @groups;

  for (@{$result->{groups}{items}}) {
    push @groups, $_->{name};
  } # for

  return @groups;
} # getusersGroups

sub updateUsersGroups ($@) {
  my ($username, @groups) = @_;

=pod

=head2 updateUsersGroups ()

Updates the users group membership

Parameters:

=for html <blockquote>

=over

=item $username

Username to operate on

=item @groups

List of groups the user should be a member of

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item @errors

List of errors (if any)

=back

=for html </blockquote>

=cut

  my ($result, @errors);

  my @oldgroups = getUsersGroups $username;

  # We can't always add groups to the new user due to either the group not being
  # in the new LDAP directory or we are unable to see it. If we attempt to JIRA
  # will try to add the group and we don't have write permission to the 
  # directory. So we'll just return @errors and let the caller deal with it.  
  for my $group (@groups) {
    next if grep {$_ eq $group} @oldgroups;

    eval {$result = $jira->POST ('/group/user', {groupname => $group}, {name => $username})};

    push @errors, $@ if $@;  
  } # for

  return @errors;
} # updateUsersGroups

sub copyGroupMembership ($$) {
  my ($from_username, $to_username) = @_;

  return updateUsersGroups $to_username, getUsersGroups $from_username;
} # copyGroupMembership

sub updateColumn ($$$%) {
  my ($table, $oldvalue, $newvalue, %info) = @_;

=pod

=head2 updateColumn ()

Updates a column in the MySQL JIRA database (SQL surgery)

Parameters:

=for html <blockquote>

=over

=item $table

Table to operate on

=item $oldvalue

Old value

=item $newvalue

New value

=item %info

Hash of column names and optional conditions

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item $numrows

Number of rows updated

=back

=for html </blockquote>

=cut

  # UGH! Sometimes values need to be quoted
  $oldvalue = quotemeta $oldvalue;
  $newvalue = quotemeta $newvalue;

  my $condition  =  "$info{column} = '$oldvalue'";
     $condition .= " and $info{condition}" if $info{condition};
  my $statement  = "update $table set $info{column} = '$newvalue' where $condition";

  my $nbrRows = count $table, $condition;

  if ($nbrRows) {
    if ($main::opts{exec}) {
      $main::total{'Rows updated'}++;

      $jiradb->do ($statement);

      _checkDBError 'Unable to execute statement', $statement;
    } else {
      $main::total{'Rows would be updated'}++;

      $main::log->msg ("Would have executed $statement") if $main::log;
    } # if
  } # if 

  return $nbrRows;
} # updateColumn

sub renameUsers (%) {
  my (%users) = @_;

=pod

=head2 renameUsers ()

Renames users

Parameters:

=for html <blockquote>

=over

=item %users

Hash of old -> new usernames

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item $errors

Number of errors

=back

=for html </blockquote>

=cut

  for my $olduser (sort keys %users) {
    my $newuser = $users{$olduser};

    $main::log->msg ("Renaming $olduser -> $newuser") if $main::log;
    display ("Renaming $olduser -> $newuser");

    if ($main::opts{exec}) {
      $main::total{'Users renamed'}++;
    } else {
      $main::total{'Users would be updated'}++;
    } # if

    for my $table (sort keys %tables) {
      $main::log->msg ("\tTable: $table Column: ", 1) if $main::log;

      my @columns = @{$tables{$table}};

      for my $column (@columns) {
        my %info = %$column;

        $main::log->msg ("$info{column} ", 1) if $main::log;

        my $rowsUpdated = updateColumn ($table, $olduser, $newuser, %info);

        if ($rowsUpdated) {
          my $msg  = " $rowsUpdated row";
             $msg .= 's' if $rowsUpdated > 1;
             $msg .= ' would have been' unless $main::opts{exec};
             $msg .= ' updated';

          $main::log->msg ($msg, 1) if $main::log;
        } # if
      } # for

      $main::log->msg ('') if $main::log;
    } # for

    if (my @result = copyGroupMembership ($olduser, $newuser)) {
      # Skip errors of the form 'Could not add user... group is read-only
      @result = grep {!/Could not add user.*group is read-only/} @result;

      if ($main::log) {
        $main::log->err ("Unable to copy group membership from $olduser -> $newuser\n@result", 1) if @result;
      } # if
    } # if
  } # for

  return $main::log ? $main::log->errors : 0;
} # renameUsers

1;

=pod

=head1 CONFIGURATION AND ENVIRONMENT

DEBUG: If set then $debug is set to this level.

VERBOSE: If set then $verbose is set to this level.

TRACE: If set then $trace is set to this level.

=head1 DEPENDENCIES

=head2 Perl Modules

L<FindBin|FindBin>

L<Carp|Carp>

L<DBI|DBI>

=head3 ClearSCM Perl Modules

=for html <p><a href="/php/scm_man.php?file=lib/Display.pm">Display</a></p>

=for html <p><a href="/php/scm_man.php?file=JIRA/lib/BugzillaUtils.pm">BugzillaUtils</a></p>

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
