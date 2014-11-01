#!/usr/bin/perl
use strict;
use warnings;

=pod

=head1 NAME importComments.pl

This will import the comments from Bugzilla and update the corresponding JIRA
Issues.

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

  $ importComments.pl [-bugzillaserver <bugshost>] [-login <login email>]
                      [-jiraserver <server>]
                      [-username <username>] [-password <password>] 
                      [-bugids bugid,bugid,... | -file <filename>] 
                      [-[no]exec]
                      [-verbose] [-help] [-usage]

  Where:

    -v|erbose:       Display progress output
    -he|lp:          Display full help
    -usa|ge:         Display usage
    -[no]e|xec:      Whether or not to update JIRA. -noexec says only 
                     tell me what you would have updated.
    -use|rname:      Username to log into JIRA with (Default: jira-admin)
    -p|assword:      Password to log into JIRA with (Default: jira-admin's 
                     password)
    -bugzillaserver: Machine where Bugzilla lives (Default: bugs-dev)
    -jiraserver:     Machine where Jira lives (Default: jira-dev)
    -bugi|ds:        Comma separated list of BugIDs to process
    -f|ile:          File of BugIDs, one per line

=head1 DESCRIPTION

This will import the comments from Bugzilla and update the corresponding JIRA
Issues.

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
  jiraserver     => $ENV{JIRASERVER}     || 'jira-dev:8081',
  username       => $ENV{USERNAME},
  password       => $ENV{PASSWORD},
  usage          => sub { pod2usage },
  help           => sub { pod2usage (-verbose => 2)},
  verbose        => sub { set_verbose },
  quiet          => 0,
);

our ($log, %total);

sub sanitize ($) {
  my ($str) = @_;
  
  my $p4web    = 'http://p4web.audience.local:8080/@md=d&cd=//&c=vLW@/';
  my $bugzilla = 'http://bugs.audience.com/show_bug.cgi?id=';

  # 0x93 (147) and 0x94 (148) are "smart" quotes
  $str =~ s/[\x93\x94]/"/gm;
  # 0x91 (145) and 0x92 (146) are "smart" singlequotes
  $str =~ s/[\x91\x92]/'/gm;
  # 0x96 (150) and 0x97 (151) are emdashes
  $str =~ s/[\x96\x97]/--/gm;
  # 0x85 (133) is an ellipsis
  $str =~ s/\x85/.../gm;
  # 0x95 &bull; replacement for unordered list
  $str =~ s/\x95/*/gm;

  # Make P4Web links for "CL (\d{3,6}+)"
  $str =~ s/CL\s*(\d{3,6}+)/CL \[$1|${p4web}$1\?ac=10\]/igm;

  # Make Bugzilla links for "Bug ID (\d{1,5}+)"
  $str =~ s/Bug\s*ID\s*(\d{1,5}+)/Bug \[$1|${bugzilla}$1\]/igm;

  # Make Bugzilla links for "Bug # (\d{1,5}+)"
  $str =~ s/Bug\s*#\s*(\d{1,5}+)/Bug \[$1|${bugzilla}$1\]/igm;

  # Make Bugzilla links for "Bug (\d{1,5}+)"
  $str =~ s/Bug\s*(\d{1,5}+)/Bug \[$1|${bugzilla}$1\]/igm;

  # Convert bug URLs to be more proper
  $str =~ s/https\:\/\/bugs\.audience\.com\/show_bug\.cgi\?id=(\d{1,5}+)/Bug \[$1|${bugzilla}$1\]/igm;

  return $str;
} # sanitize

sub addComments ($$) {
  my ($jiraIssue, $bugid) = @_;
  
  my @comments = @{getBugComments ($bugid)};
  
  # Note: In Bugzilla the first comment is considered the description.
  my $description = shift @comments;
  
  my $result = addDescription $jiraIssue, sanitize $description;
  
  $total{'Descriptions added'}++;
  
  return $result if $result =~ /^Unable to add comment/;
   
  # Process the remaining comments  
  for (@comments) {
    $result = addJIRAComment $jiraIssue, sanitize $_;
    
    if ($result =~ /Comment added/) {
      $total{'Comments imported'}++;
    } else {
      return $result;
    } # if
  } # for
  
  $result = '' unless $result;
  
  return $result;
} # addComments

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
    'relinkbugzilla'
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
    unless $opts{bugids};
  
  openBugzilla $opts{bugzillaserver}
    or $log->err ("Unable to connect to $opts{bugzillaserver}", 1);
  
  Connect2JIRA ($opts{username}, $opts{password}, $opts{jiraserver})
    or $log->err ("Unable to connect to $opts{jiraserver}", 1);

  $log->msg ("Processing comments");

  for (@{$opts{bugids}}) {
    my $jiraIssue = findIssue $_;
    
    if ($jiraIssue =~ /^[A-Z]{1,5}-\d+$/) {
      my $result = addComments $jiraIssue, $_;
      
      if ($result =~ /^Unable/) {
        $total{'Comment failures'}++;

        $log->err ("Unable to add comments for $jiraIssue ($_)\n$result");
      } elsif ($result =~ /^Comment added/) {
        $log->msg ("Added comments for $jiraIssue ($_)");
      } elsif ($result =~ /^Would have linked/) {
        $total{'Comments would be added'}++;
      } # if
    } else {
      $total{'Missing JIRA Issues'}++;
      
      $log->err ("Unable to find JIRA Issue for Bug $_");
    } # if
  } # for

  display_duration $startTime, $log;
  
  Stats (\%total, $log) unless $opts{quiet};

  return 0;
} # main

exit main;
