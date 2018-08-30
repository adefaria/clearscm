#!/usr/bin/perl
use strict;
use warnings;

=pod

=head1 NAME updateWatchLists.pl

Copy CC lists from Bugzilla -> JIRA

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

 Updates JIRA watchlists by copying the CC list information from Bugzilla
 
  $ updateWatchLists.pl [-login <login email>] [-products product1,
                        product2,...] [-[no]exec]
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

This script updates JIRA watchlists by copying the CC List information from
Bugzilla to JIRA.

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
use JIRA::REST;

use Getopt::Long; 
use Pod::Usage;

# Login should be the email address of the bugzilla account which has 
# priviledges to create products and components
our %opts = (
  exec           => 0,
  bugzillaserver => $ENV{BUGZILLASERVER} || 'bugs-dev',
  jiraserver     => $ENV{JIRASERVER}     || 'jira-dev:8081',
  username       => 'jira-admin',
  password       => 'jira-admin',
  usage          => sub { pod2usage },
  help           => sub { pod2usage (-verbose => 2)},
  verbose        => sub { set_verbose },
);

our ($log, %total);

my ($bugzilla, $jira);

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
  ) or pod2usage;
  
  $log = Logger->new;
  
  if ($opts{file}) {
    open my $file, '<', $opts{file} 
      or die "Unable to open $opts{file} - $!";
      
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
  
  for (@{$opts{bugids}}) {
    my $issue = findIssue $_;
    
    if ($issue =~ /^Future JIRA Issue/ or $issue =~ /^Unable to find/) {
      $log->msg ($issue);
    } else {
      my %watchers = getWatchers $_;
      
      $log->msg ('Found ' . scalar (keys %watchers) . " watchers for JIRA Issue $issue");
      
      my $result = updateIssueWatchers ($issue, %watchers);
      
      if ($result =~ /^Unable to/) {
        $total{'Missing JIRA Issues'}++;
        
        $log->err ($result);
      } else {
        $total{'Issues updated'}++;
      } # if
    } # if
  } # for

  display_duration $startTime, $log;
  
  Stats (\%total, $log) unless $opts{quiet};
  
  return  0;
} # main

exit main;
