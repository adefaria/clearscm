=pod

=head1 NAME $RCSfile: BugzillaUtils.pm,v $

Some shared functions dealing with Bugzilla. Note this uses DBI to directly
access Bugzilla's database. This requires that your userid was granted access.
For this I setup adefaria with pretty much read only access.

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

=head1 ROUTINES

The following routines are exported:

=cut

package BugzillaUtils;

use strict;
use warnings;

use base 'Exporter';

use FindBin;
use Display;
use Carp;
use DBI;

use lib 'lib';

use JIRAUtils;

our $bugzilla;

our @EXPORT = qw (
  openBugzilla
  getRelationships
  getDependencies
  getBlockers
  getDuplicates
  getRelated
  getBug
  getBugComments
  getWatchers
);

sub _checkDBError ($$) {
  my ($msg, $statement) = @_;

  my $dberr    = $bugzilla->err;
  my $dberrmsg = $bugzilla->errstr;

  $dberr    ||= 0;
  $dberrmsg ||= 'Success';

  my $message = '';

  if ($dberr) {
    my $function = (caller (1)) [3];

    $message = "$function: $msg\nError #$dberr: $dberrmsg\n"
             . "SQL Statement: $statement";
  } # if

  $main::log->err ($message, $dberr) if $dberr;

  return;
} # _checkDBError

sub openBugzilla (;$$$$) {
  my ($dbhost, $dbname, $dbuser, $dbpass) = @_;

  $dbhost //= 'jira-dev';
  $dbname //= 'bugzilla';
  $dbuser //= 'adefaria';
  $dbpass //= 'reader';
  
  $main::log->msg ("Connecting to Bugzilla ($dbuser\@$dbhost)");
  
  $bugzilla = DBI->connect (
    "DBI:mysql:$dbname:$dbhost",
    $dbuser,
    $dbpass, {
      PrintError => 0,
      RaiseError => 1,
    },
  );
  
  _checkDBError 'Unable to execute statement', 'Connect';

  return $bugzilla;
} # openBugzilla

sub getBug ($;@) {
  my ($bugid, @fields) = @_;
  
  push @fields, 'short_desc' unless @fields;
  
  my $statement = 'select ' . join (',', @fields) .
                  " from bugs where bug_id = $bugid";
                  
  my $sth = $bugzilla->prepare ($statement);

  _checkDBError 'Unable to prepare statement', $statement;
  
  _checkDBError 'Unable to execute statement', $statement;

  $sth->execute;

  return $sth->fetchrow_hashref;
} # getBug

sub getBugComments ($) {
  my ($bugid) = @_;
  
  my $statement = <<"END";
select 
  bug_id, 
  bug_when, 
  substring_index(login_name,'\@',1) as username,
  thetext
from
  longdescs,
  profiles
where
  who    = userid and
  bug_id = $bugid 
END
  
  my $sth = $bugzilla->prepare ($statement);
  
  _checkDBError 'Unable to prepare statement', $statement;

  $sth->execute;
  
  _checkDBError 'Unable to execute statement', $statement;
  
  my @comments;
  
  while (my $comment = $sth->fetchrow_hashref) {
    my $commentText = <<"END";
The following comment was entered by [~$comment->{username}] on $comment->{bug_when}:

$comment->{thetext}
END

    push @comments, $commentText;
  } # while
  
  return \@comments;
} # getBugComments

sub getRelationships ($$$$@) {
  my ($table, $returnField, $testField, $relationshipType, @bugs) = @_;
  
  $main::log->msg ("Getting $relationshipType");
  
  my $statement = "select $returnField from $table where $table.$testField = ?";

  my $sth = $bugzilla->prepare ($statement);

  _checkDBError 'Unable to prepare statement', $statement;
  
  my %relationships;

  my %bugmap;
  
  map {$bugmap{$_} = 1} @bugs unless %bugmap;
      
  for my $bugid (@bugs) {
    $sth->execute ($bugid);
    
    _checkDBError 'Unable to exit statement', $statement;
    
    my $result = JIRAUtils::findIssue ($bugid, %bugmap);
    
    if ($result =~ /^Unable/) {
      $main::log->warn ($result);
      
      $main::total{'Missing JIRA Issues'}++;
      
      undef $result;
    } elsif ($result =~ /^Future/) {
      $main::total{'Future JIRA Issues'}++;
      
      undef $result;
    } # if
    
    my $jiraIssue = $result;
    my $key       = $jiraIssue || $bugid;

    my @relationships;
    my $relations = $sth->fetchall_arrayref;
    my @relations;
    
    map {push @relations, $_->[0]} @$relations;
    
    for my $relation (@relations) {
      $jiraIssue = JIRAUtils::findIssue ($relation);
      
      if ($jiraIssue =~ /^Unable/ || $jiraIssue =~ /^Future/) {
        $main::log->warn ($jiraIssue);

        $main::total{'Missing JIRA Issues'}++ if $jiraIssue =~ /^Unable/;
        $main::total{'Future JIRA Issues'}++  if $jiraIssue =~ /^Future/;
        
        push @relationships, $relation;
      } else {
        push @relationships, $jiraIssue;
      } # if
    } # for
      
    push @{$relationships{$key}}, @relationships if @relationships;
  } # for
  
  $main::total{$relationshipType} = keys %relationships;
  
  return \%relationships;
} # getRelationships

sub getDependencies (@) {
  my (@bugs) = @_;

  return getRelationships (
    'dependencies', # table 
    'dependson',    # returned field
    'blocked',      # test field
    'Depends on',   # relationship
    @bugs
  );
} # getDependencies

sub getBlockers (@) {
  my (@bugs) = @_;
  
  return getRelationships (
    'dependencies', 
    'blocked', 
    'dependson', 
    'Blocks',
    @bugs
  );
} # getBlockers

sub getDuplicates (@) {
  my (@bugs) = @_;
  
  return getRelationships (
    'duplicates', 
    'dupe', 
    'dupe_of', 
    'Duplicates',
    @bugs
  );
} # getDuplicates

sub getRelated (@) {
  my (@bugs) = @_;
  
  return getRelationships (
    'bug_see_also', 
    'value', 
    'bug_id', 
    'Relates',
    @bugs
  );
} # getRelated

sub getWatchers ($) {
  my ($bugid) = @_;
  
  my $statement = <<"END";
select 
  profiles.login_name
from 
  cc,
  profiles
where 
  cc.who = profiles.userid and
  bug_id = ?
END

  my $sth = $bugzilla->prepare ($statement);

  _checkDBError 'Unable to prepare statement', $statement;

  $sth->execute ($bugid);

  _checkDBError 'Unable to execute statement', $statement;

  my @rows = @{$sth->fetchall_arrayref};

  my %watchers;

  for (@rows) {
    if ($$_[0] =~ /(.*)\@/) {
      $watchers{$1} = 1;
    } # if

    $main::total{'Watchers Processed'}++;  
  } # for

  return %watchers;
} # getWatchers