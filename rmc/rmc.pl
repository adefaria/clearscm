#!/usr/bin/perl
use strict;
use warnings;

use CGI qw (
  :standard
  :cgi-lib 
  start_div end_div 
  *table 
  start_Tr end_Tr
  start_td end_td
  start_pre end_pre
  start_thead end_thead
);

=pod

=head1 NAME rmc.pl

Release Mission Control: Customized Release Notes

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: #7 $

=item Created

Thu Mar 20 10:11:53 PDT 2014

=item Modified

$Date: 2015/07/22 $

=back

=head1 SYNOPSIS

  $ rmc.pl [-username <username>] [-password <password>] 
           [-client client] [-port] [-[no]html] [-csv]
           [-comments] [-files] [-description]
                
           -from <revRange> [-to <revRange>]
           [-branchpath <path>]
                 
           [-verbose] [-debug] [-help] [-usage]

  Where:

    -v|erbose:     Display progress output
    -deb|ug:       Display debugging information
    -he|lp:        Display full help
    -usa|ge:       Display usage
    -p|ort:        Perforce server and port (Default: Env P4PORT).
    -use|rname:    Name of the user to connect to Perforce with with
                   (Default:Env P4USER).
    -p|assword:    Password for the user to connect to Perforce with
                   (Default: Env P4PASSWD).
    -cl|ient:      Perforce Client (Default: Env P4CLIENT)
    -co|mments:    Include comments in output
    -fi|les:       Include files in output
    -cs|v:         Produce a csv file
    -des|cription: Include description from Bugzilla
    -fr|om:        From revSpec
    -l|ong:        Shorthand for -comments & -files
    -t|o:          To revSpec (Default: @now)
    -b|ranchpath:  Path to limit changes to
    -[no]ht|ml:    Whether or not to produce html output

Note that revSpecs are Perforce's way of handling changelist/label/dates. For
more info see p4 help revisions. For your reference:

  #rev    - A revision number or one of the following keywords:
  #none   - A nonexistent revision (also #0).
  #head   - The current head revision (also @now).
  #have   - The revision on the current client.
  @change - A change number: the revision as of that change.
  @client - A client name: the revision on the client.
  @label  - A label name: the revision in the label.
  @date   - A date or date/time: the revision as of that time.
            Either yyyy/mm/dd or yyyy/mm/dd:hh:mm:ss
            Note that yyyy/mm/dd means yyyy/mm/dd:00:00:00.
            To include all events on a day, specify the next day.

=head1 DESCRIPTION

This script produces release notes on the web or in a .csv file. You can also
produce an .html file by using -html and redirecting stdout.

=cut

use FindBin;
use Getopt::Long;
use Pod::Usage;

use P4;

use lib "$FindBin::Bin/../../Web/common/lib";
use lib "$FindBin::Bin/../../common/lib";
use lib "$FindBin::Bin/../../lib";
use lib "$FindBin::Bin/../lib";

use Display;
use DateUtils;
use JIRAUtils;
use Utils;

#use webutils;

# Globals
my $VERSION  = '$Revision: #7 $';
  ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);

my $p4;
my @labels;
my $headerPrinted;
my $p4ticketsFile = '/opt/audience/perforce/p4tickets';

my $bugsweb = 'http://bugs.audience.local/show_bug.cgi?id=';
my $p4web   = 'http://p4web.audience.local:8080';
my $jiraWeb = 'http://jira.audience.local/browse/';
my %opts;

my $changesCommand = '';

local $| = 1;

my $title    = 'Release Mission Control';
my $subtitle = 'Select from and to revspecs to see the bugs changes between them';
my $helpStr  = 'Both From and To are Perforce '
             . i ('revSpecs')
             . '. You can use changelists, labels, dates or clients. For more'
             . ' see p4 help revisions or '
             . a {
                 href   => 'http://www.perforce.com/perforce/r12.2/manuals/cmdref/o.fspecs.html#1047453',
                 target => 'rmcHelp',
               },
               'Perforce File Specifications',
             .  '.'
             . br
             . b ('revSpec examples') 
             . ': &lt;change&gt;, &lt;client&gt;, &lt;label&gt, '
             . '&lt;date&gt; - yyyy/mm/dd or yyyy/mm/dd:hh:mm:ss'
             . br
             . b ('Note:')
             . ' To show all changes after label1 but before label2 use >label1 for From and @label2 for To. Or specify To as now';
my @columnHeadings = (
  '#',
  'Changelist',
  'Bug ID',
  'Issue',
  'Type',
  'Status',
  'Fix Versions',
  'User ID',
  'Date',
  '# of Files',
  'Summary',
  'Checkin Comments',
  'Files',
);

sub displayForm (;$$$);

sub footing (;$) {
  my ($startTime) = @_;
  
  print '<center>', a { 
    href => url (-relative => 1). "?csv=1&from=$opts{from}&to=$opts{to}&branchpath=$opts{branchpath}",
  }, 'Export CSV</center>' if $opts{from} or $opts{to};

  print end_form;
  
  my $script = $FindBin::Script =~ /index.pl/
             ? 'rmc.pl'
             : $FindBin::Script;

  my ($sec, $min, $hour, $mday, $mon, $year) = 
    localtime ((stat ($script))[9]);

  $year += 1900;
  $mon++;

  my $dateModified   = "$mon/$mday/$year @ $hour:$min";
  my $secondsElapsed = $startTime ? time () - $startTime . ' secs' : '';

  print end_div;

  print start_div {-class => 'copyright'};
    print "$script version $VERSION: Last modified: $dateModified";
    print " ($secondsElapsed)" if $secondsElapsed;
    print br "Copyright &copy; $year, Audience - All rights reserved - Design by ClearSCM";
  print end_div;

  print end_html;

  return;
} # footing

sub errorMsg ($;$) {
  my ($msg, $exit) = @_;

  unless ($opts{html}) {
    error ($msg, $exit);
    
    return
  } # if
  
  unless ($headerPrinted) {
    print header;
    print start_html;
    
    $headerPrinted =1;
  } # unless

  print font ({class => 'error'}, '<br>ERROR: ') . $msg;

  if ($exit) {
    footing;
    exit $exit;
  } # if
} # errorMsg

sub debugMsg ($) {
  my ($msg) = @_;
  
  return unless $opts{debug};

  unless ($opts{html}) {
    debug $msg;
    
    return
  } # if
  
  unless ($headerPrinted) {
    print header;
    print start_html;
    
    $headerPrinted = 1;
  } # unless

  print font ({class => 'error'}, '<br>DEBUG: ') . $msg;
} # debugMsg

sub formatTimestamp (;$) {
  my ($time) = @_;
  
  my $date          = YMDHMS ($time);
  my $formattedDate = substr ($date, 0, 4) . '-'
                    . substr ($date, 4, 2) . '-'
                    . substr ($date, 6, 2) . ' '
                    . substr ($date, 9);
  
  return $formattedDate;
} # formatTimestamp

sub p4errors ($) {
  my ($cmd) = @_;

  my $msg  = "Unable to run \"p4 $cmd\"";
     $msg .= $opts{html} ? '<br>' : "\n";

  if ($p4->ErrorCount) {
    displayForm $opts{from}, $opts{to}, $opts{branchpath};

    errorMsg $msg . $p4->Errors, $p4->ErrorCount;
  } # if

  return;
} # p4errors

sub p4connect () {
  $p4 = P4->new;

  $p4->SetUser     ($opts{username});
  $p4->SetClient   ($opts{client}) if $opts{client};
  $p4->SetPort     ($opts{port});
  
  if ($opts{username} eq 'shared') {
  	$p4->SetTicketFile ($p4ticketsFile);
  } else {
    $p4->SetPassword ($opts{password});
  } # if

  verbose_nolf "Connecting to Perforce server $opts{port}...";
  $p4->Connect or die "Unable to connect to Perforce Server\n";
  verbose 'done';

  unless ($opts{username} eq 'shared') {
    verbose_nolf "Logging in as $opts{username}\@$opts{port}...";

    $p4->RunLogin;

    p4errors 'login';

    verbose 'done';
  } # unless

  return $p4;
} # p4connect

sub getChanges ($;$$) {
  my ($from, $to, $branchpath) = @_;

  $from = "\@$from" unless $from =~ /^@/;
  $to   = "\@$to"   unless $to   =~ /^@/;
  
  my $args;
     #$args    = '-s shelved ';
     $args   .= $branchpath if $branchpath;
     $args   .= $from;
     $args   .= ",$to" if $to;

  my $cmd     = 'changes';
  my $changes = $p4->Run ($cmd, $args);
  
  $changesCommand = "p4 $cmd $args" if $opts{debug};
  
  p4errors "$cmd $args";
  
  unless (@$changes) {
    if ($to =~ /\@now/i) {
      verbose "No changes since $from";
    } else {
      verbose "No changes between $from - $to";
    } # if

    return;
  } else {
    return @$changes;
  } # unless
} # getChanges

sub getJobInfo ($) {
  my ($job) = @_;

  my $jobs = $p4->IterateJobs ("-e $job");

  p4errors "jobs -e $job";

  $job = $jobs->next if $jobs->hasNext;

  return $job;
} # getJobInfo

sub getComments ($) {
  my ($changelist) = @_;

  my $change = $p4->FetchChange ($changelist);

  p4errors "change $changelist";

  return $change->{Description};
} # getComments

sub getFiles ($) {
  my ($changelist) = @_;

  my $files = $p4->Run ('files', "\@=$changelist");

  p4errors "files \@=$changelist";

  my @files;

  push @files, $_->{depotFile} . '#' . $_->{rev} for @$files;

  return @files;
} # getFiles

sub displayForm (;$$$) {
  my ($from, $to, $branchpath) = @_;

  $from //= '<today>';
  $to   //= '<today>';

  print p {align => 'center', class => 'dim'}, $helpStr;

  print start_form {
    method  => 'get',
    actions => $FindBin::Script,
  };

  print start_table {
    class       => 'table',
    align       => 'center',
    cellspacing => 1,
    width       => '95%',
  };

  print Tr [th ['From', 'To']];
  print start_Tr;
  print td {align => 'center'}, textfield (
    -name => 'from',
    value => $from,
    size  => 60,
  );
  print td {align => 'center'}, textfield (
    -name => 'to',
    value => $to,
    size  => 60,
  );
  print end_Tr;
  
  print Tr [th {colspan => 2}, 'Branch/Path'];
  print start_Tr;
  print td {
    colspan => 2,
    align   => 'center',
  }, textfield (
    -name => 'branchpath',
    value => $branchpath,
    size  => 136,
  );
  print end_Tr;

  print start_Tr;
  print td {align => 'center', colspan => 2}, b ('Options:'), checkbox (
    -name   => 'comments',
    id      => 'comments',
    onclick => 'toggleOption ("comments");',
    label   => 'Comments',
    checked => $opts{comments} ? 'checked' : '',
    value   => $opts{comments},
  ), checkbox (
    -name   => 'files',
    id      => 'files',
    onclick => 'toggleOption ("files");',
    label   => 'Files',
    checked => $opts{files} ? 'checked' : '',
    value   => $opts{files},
#  ), checkbox (
#    -name   => 'group',
#    id      => 'group',
#    onclick => 'groupIndicate();',
#    label   => 'Group Indicate',
#    checked => 'checked',
#    value   => $opts{group},
  );

  print end_Tr;

  print start_Tr;
  print td {align => 'center', colspan => 2}, input {
    type  => 'Submit',
    value => 'Submit',
  };
  print end_Tr;
  print end_table;
  print p;

  return;
} # displayForm

sub displayChangesHTML (@) {
  my (@changes) = @_;

  displayForm $opts{from}, $opts{to}, $opts{branchpath};

  unless (@changes) {
    my $msg  = "No changes found between $opts{from} and $opts{to}";
       $msg .= " for $opts{branchpath}"; 
    print p $msg;

    return;
  } # unless

  my $displayComments = $opts{comments} ? '' : 'none';
  my $displayFiles    = $opts{files}    ? '' : 'none';

  debugMsg "Changes command used: $changesCommand";
  
  print start_table {
    class => 'table-autosort',
    align => 'center',
    width => '95%',
  };
  
  print start_thead;
  print start_Tr;
  print th '#';
  print 
  th {
    class => 'table-sortable:numeric table-sortable',
    title => 'Click to sort',
  }, 'Changelist',
  th {
    class => 'table-sortable:numeric',
    title => 'Click to sort',
  }, 'Bug ID',
  th {
    class => 'table-sortable:numeric',
    title => 'Click to sort',
  }, 'Issue',
  th {
    class => 'table-sortable:default table-sortable',
    title => 'Click to sort',
  }, 'Type',
  th {
    class => 'table-sortable:default table-sortable',
    title => 'Click to sort',
  }, 'Status',
  th {
    class => 'table-sortable:default table-sortable',
    title => 'Click to sort',
  }, 'Fix Version',
  th {
    class => 'table-sortable:default table-sortable',
    title => 'Click to sort',
  }, 'User ID',
  th {
    class => 'table-sortable:default table-sortable',
    title => 'Click to sort',
  }, 'Date',
  th {
    class => 'table-sortable:numeric table-sortable',
    title => 'Click to sort',
  }, '# of Files',
  th 'Summary',
  th {
    id    => 'comments0',
    style => "display: $displayComments",
  }, 'Checkin Comments',
  th {
    id    => 'files0',
    style => "display: $displayFiles",
  }, 'Files';
  print end_Tr;
  print end_thead;
  
  my $i = 0;
  
  for (sort {$b->{change} <=> $a->{change}} @changes) {
    my %change = %$_;

    my @files = getFiles $change{change};
    
    my $job;
    
    for ($p4->Run ('fixes', "-c$change{change}")) { # Why am I uses fixes here?
       $job = getJobInfo $_->{Job};
       last; # FIXME - doesn't handle muliple jobs.
    } # for

    $job->{Description} = font {color => '#aaa'}, 'N/A' unless $job;

    my ($bugid, $jiraIssue);
    
    if ($job->{Job}) {
      if ($job->{Job} =~ /^(\d+)/) {
        $bugid = $1;
      } elsif ($job->{Job} =~ /^(\w+-\d+)/) {
        $jiraIssue = $1;
      }
    } # if

    # Using the following does not guarantee the ordering of the elements 
    # emitted!
    #
    # my $buglink  = a {
    #   href   => "$bugsweb$bugid",
    #   target => 'bugzilla',
    # }, $bugid;
    #
    # IOW sometimes I get <a href="..." target="bugzilla"> and other times I 
    # get <a target="bugzilla" href="...">! Not cool because the JavaScript
    # later on is comparing innerHTML and this messes that up. So we write this
    # out by hand instead.
    my $buglink     = $bugid 
                    ? "<a href=\"$bugsweb$bugid\" target=\"bugzilla\">$bugid</a>"
                    : font {color => '#aaa'}, 'N/A';
    my $jiralink    = $jiraIssue
                    ? "<a href=\"$jiraWeb$jiraIssue\" target=\"jira\">$jiraIssue</a>"
                    : font {color => '#aaa'}, 'N/A';                  
    my $cllink      = "<a href=\"$p4web/$_->{change}?ac=133\" target=\"p4web\">$_->{change}</a>";
    my $userid      = $_->{user};
    my $description = $job->{Description};
    my $jiraStatus  = font {color => '#aaa'}, 'N/A';
    my $issueType   = font {color => '#aaa'}, 'N/A';
    my $fixVersions = font {color => '#aaa'}, 'N/A';
    
    if ($jiraIssue) {
      my $issue;
      
      eval {$issue = getIssue ($jiraIssue, qw (status issuetype fixVersions))};
      
      unless ($@) {
        $jiraStatus = $issue->{fields}{status}{name};
        $issueType  = $issue->{fields}{issuetype}{name};
        
        my @fixVersions;
        
        push @fixVersions, $_->{name} for @{$issue->{fields}{fixVersions}};
          
        $fixVersions = join '<br>', @fixVersions; 
      } # unless
    } # if
    
    print start_Tr {id => ++$i};
        
    # Attempting to "right size" the columns...
    print 
      td {width => '10px',  align => 'center'},                       $i,
      td {width => '15px',  align => 'center', id => "changelist$i"}, $cllink,
      td {width => '60px',  align => 'center', id => "bugzilla$i"},   $buglink,
      td {width => '80px',  align => 'center', id => "jira$i"},       $jiralink,
      td {width => '50px',  align => 'center', id => "type$i"},       $issueType,
      td {width => '50px',  align => 'center', id => "jirastatus$i"}, $jiraStatus,
      td {width => '50px',  align => 'center', id => "fixVersion$i"}, $fixVersions,
      td {width => '30px',  align => 'center', id => "userid$i"},     a {href => "mailto:$userid\@audience.com" }, $userid,
      td {width => '130px', align => 'center'},                       formatTimestamp ($_->{time}),
      td {width => '10px',  align => 'center'},                       scalar @files;
      
    if ($description =~ /N\/A/) {
      print td {id => "description$i", align => 'center'}, $description;
    } else {
      print td {id => "description$i"}, $description;
    } # if
      
    print
      td {id     => "comments$i",
          valign => 'top',
          style  => "display: $displayComments",
      }, pre {class => 'code'}, getComments ($_->{change});

    print start_td {
      id      => "files$i",
      valign  => 'top',
      style   => "display: $displayFiles"
    };

    print start_pre {class => 'code'};

    for my $file (@files) {
      my ($filelink) = ($file =~ /(.*)\#/);
      my ($revision) = ($file =~ /\#(\d+)/);
      
      # Note: For a Perforce "Add to Source Control" operation, revision is 
      # actually "none". Let's fix this.
      $revision = 1 unless $revision;
      
      if ($revision == 1) {
        print a {
          href   => '#',
        }, img {
          src   => "$p4web/rundiffprevsmallIcon?ac=20",
          title => "There's nothing to diff since this is the first revision",
        };
      } else {
        print a {
          href   => "$p4web$filelink?ac=19&rev1=$revision&rev2=" . ($revision - 1),
          target => 'p4web',
        }, img {
          src    => "$p4web/rundiffprevsmallIcon?ac=20",
          title  => "Diff rev #$revision vs. rev #" . ($revision -1),
        };
      } # if
      
      print a {
        href   => "$p4web$filelink?ac=22",
        target => 'p4web',
      }, "$file<br>";
    } # for

    print end_pre;
    print end_td;

    print end_Tr;
  } # for

  print end_table;

  return;
} # displayChangesHTML

sub displayChange (\%;$) {
  my ($change, $nbr) = @_;
  
  $nbr //= 1;
  
  # Note: $change must about -c!
  my $args  = "-c$change->{change}";
  my $cmd   = 'fixes';
  my $fix = $p4->Run ($cmd, $args);

  p4errors "$cmd $args";

  errorMsg "Change $change->{change} is associated with multiple jobs. This case is not handled yet" if @$fix > 1;

  $fix = $$fix[0];
  
  # If there was no fix associated with this change we will use the change data.
  unless ($fix) {
    $fix->{Change} = $change->{change}; 
    $fix->{User}   = $change->{user};
    $fix->{Date}   = $change->{time};
  } # unless
  
  my $job;
  $job = getJobInfo ($fix->{Job}) if $fix->{Job};
  
  unless ($job) {
    chomp $change->{desc};

    $job = {
      Description => $change->{desc},
      Job         => 'Unknown',
    };
  } # unless

  my ($bugid)  = ($job->{Job} =~ /^(\d+)/);
  
  chomp $job->{Description};
  
  my $description  = "$change->{change}";
     $description .= "/$bugid" if $bugid;
     $description .= ": $job->{Description} ($fix->{User} ";
     $description .= ymdhms ($fix->{Date}) . ')';

  display $nbr++ . ") $description";

  if ($opts{comments}) {
    print "\n";
    print "Comments:\n" . '-'x80 . "\n" . getComments ($fix->{Change}) . "\n";
  } # if

  if ($opts{description}) {
    display '';
    display "Description:\n" . '-'x80 . "\n" . $job->{Description};
  } # if

  if ($opts{files}) {
    display "Files:\n" . '-'x80;

    for (getFiles $fix->{Change}) {
      display "\t$_";
    } # for

    display '';
  } # if

  return $nbr;
} # displayChangesHTML

sub displayChanges (@) {
  my (@changes) = @_;

  unless (@changes) {
    my $msg  = "No changes found between $opts{from} and $opts{to}";
       $msg .= " for $opts{branchpath}"; 
    print p $msg;

    return;
  } # unless

  my $i;
  
  debugMsg "Changes command used: $changesCommand";
  
  $i = displayChange %$_, $i for @changes;
    
  return;
} # displayChanges

sub heading ($;$) {
  my ($title, $subtitle) = @_;

  print header unless $headerPrinted;

  $headerPrinted = 1;

  print start_html {
    title   => $title,
    head    => Link ({
      rel   => 'shortcut icon',
      href  => 'http://p4web.audience.local:8080/favicon.ico',
      type  => 'image/x-icon',
    }),
    author  => 'Andrew DeFaria <Andrew@ClearSCM.com>',
    script  => [{
      language => 'JavaScript',
      src      => 'rmc.js',
    }, {
      language => 'JavaScript',
      src      => 'rmctable.js',
    }],
    style      => ['rmc.css'],
    onload     => 'setOptions();',
  }, $title;
  
  print h1 {class => 'title'}, "<center><img src=\"Audience.png\"> $title</center>";
  print h3 "<center><font color='#838'>$subtitle</font></center>" if $subtitle;

  return;
} # heading

sub exportCSV ($@) {
  my ($filename, @data) = @_;

  print header (
    -type       => 'application/octect-stream',
    -attachment => $filename,
  );

  # Print heading line
  my $columns;
  
  # Note that we do not include the '#' column so start at 1
  for (my $i = 1; $i < @columnHeadings; $i++) {
    $columns .= "\"$columnHeadings[$i]\"";
    
    $columns .= ',' unless $i == @columnHeadings;
  } # for
  
  print "$columns\n";
  
  for (sort {$b->{change} <=> $a->{change}} @data) {
    my %change = %$_;

    ## TODO: This code is duplicated (See displayChange). Consider refactoring.
    # Note: $change must be right next to the -c!
    my (%job, $jiraStatus, $issueType, $fixVersions);
    
    for ($p4->Run ('fixes', "-c$change{change}")) {
       %job = %{getJobInfo $_->{Job}};
       last; # FIXME - doesn't handle muliple jobs.
    } # for

    $job{Description} = '' unless %job;

    my ($bugid, $jiraIssue);
    
    if ($job{Job}) {
      if ($job{Job} =~ /^(\d+)/) {
        $bugid = $1;
      } elsif ($job{Job} =~ /^(\w+-\d+)/) {
        $jiraIssue = $1;
      }
    } # if    
  
    if ($jiraIssue) {
      my $issue;
      
      eval {$issue = getIssue ($jiraIssue, qw (status issuetype fixVersions))};
      
      unless ($@) {
        $jiraStatus = $issue->{fields}{status}{name};
        $issueType  = $issue->{fields}{issuetype}{name};

        my @fixVersions;
        
        push @fixVersions, $_->{name} for @{$issue->{fields}{fixVersions}};
          
        $fixVersions = join "\n", @fixVersions; 
      } # unless
    } # if

    my $job;
    
    unless ($job) {
      chomp $change{desc};
  
      $job = {
        Description => $change{desc},
        Job         => 'Unknown',
      };
    } # unless
    ## End of refactor code

    $job{Description} = join ("\r\n", split "\n", $job{Description});
    
    my @files    = getFiles $change{change};
    my $comments = join ("\r\n", split "\n", getComments ($change{change}));
    
    # Fix up double quotes in description and comments
    $job{Description} =~ s/"/""/g;
    $comments         =~ s/"/""/g;
    
    print "$change{change},";
    print $bugid       ? "$bugid,"       : ',';
    print $jiraIssue   ? "$jiraIssue,"   : ',';
    print $issueType   ? "$issueType,"   : ',';
    print $jiraStatus  ? "$jiraStatus,"  : ',';
    print $fixVersions ? "$fixVersions," : ',';
    print "$change{user},";
    print '"' . formatTimestamp ($change{time}) . '",';
    print scalar @files . ',';
    print "\"$job{Description}\",";
    print "\"$comments\",";
    print '"' . join ("\n", @files) . "\"";
    print "\n";
  } # for
  
  return;
} # exportCSV

sub main {
  # Standard opts
  $opts{usage}    = sub { pod2usage };
  $opts{help}     = sub { pod2usage (-verbose => 2)};

  # Opts for this script
  $opts{username}   //= $ENV{P4USER}         || $ENV{USERNAME}    || $ENV{USER};
  $opts{client}     //= $ENV{P4CLIENT};
  $opts{port}       //= $ENV{P4PORT}         || 'perforce:1666';
  $opts{password}   //= $ENV{P4PASSWD};
  $opts{html}       //= $ENV{HTML}           || param ('html')    || 1;
  $opts{html}         = (-t) ? 0 : 1;
  $opts{debug}      //= $ENV{DEBUG}          || param ('debug')   || sub { set_debug };
  $opts{verbose}    //= $ENV{VERBOSE}        || param ('verbose') || sub { set_verbose };
  $opts{jiraserver} //= 'jira';
  $opts{from}         = param 'from';
  $opts{to}           = param 'to';
  $opts{branchpath}   = param ('branchpath') || '//AudEngr/Import/VSS/...';
  $opts{group}        = param 'group';
  $opts{comments}   //= $ENV{COMMENTS}       || param 'comments';
  $opts{files}      //= $ENV{FILES}          || param 'files';
  $opts{long}       //= $ENV{LONG}           || param 'long';
  $opts{csv}        //= $ENV{CSV}            || param 'csv';
  
  GetOptions (
    \%opts,
    'verbose',
    'debug',
    'help',
    'usage',
    'port=s',
    'username=s',
    'password=s',
    'client=s',
    'comments',
    'files',
    'description',
    'long',
    'from=s',
    'to=s',
    'branchpath=s',
    'html!',
    'csv',
  ) || pod2usage;

  $opts{comments} = $opts{files} = 1 if $opts{long};
  $opts{debug}    = get_debug        if ref $opts{debug}   eq 'CODE';
  $opts{verbose}  = get_verbose      if ref $opts{verbose} eq 'CODE';

  # Are we doing HTML?
  if ($opts{html}) {
    require CGI::Carp;

    CGI::Carp->import ('fatalsToBrowser');

    $opts{username} ||= 'shared';
  } # if

  # Needed if using the shared user
  if ($opts{username} eq 'shared') {
    unless (-f $p4ticketsFile) {
      errorMsg "Using 'shared' user but there is no P4TICKETS file ($p4ticketsFile)", 1;
    } # unless
  } else {
    if ($opts{username} and not $opts{password}) {
      $opts{password} = GetPassword "I need the Perforce password for $opts{username}";
    } # if
  } # if

  p4connect;
  
  my $jira = Connect2JIRA (undef, undef, $opts{jiraserver});

  unless ($opts{from} or $opts{to}) {
    if ($opts{html}) {
      heading $title, $subtitle;

      displayForm $opts{from}, $opts{to}, $opts{branchpath};

      footing;

      exit;
    } # if
  } # unless
  
  my $ymd = YMD;
  my $midnight = substr ($ymd, 0, 4) . '/'
               . substr ($ymd, 4, 2) . '/'
               . substr ($ymd, 6, 2) . ':00:00:00';

  $opts{to}   //= 'now';
  $opts{from} //= $midnight;

  $opts{to}     = 'now'     if ($opts{to}   eq '<today>' or $opts{to}   eq '');
  $opts{from}   = $midnight if ($opts{from} eq '<today>' or $opts{from} eq '');

  my $msg = 'Changes made ';
  
  if ($opts{to} =~ /^now$/i and $opts{from} eq $midnight) {
    $msg .= 'today';
  } elsif ($opts{to} =~ /^now$/i) {
    $msg .= "since $opts{from}";
  } else {
    $msg .= "between $opts{from} and $opts{to}";
  } # if

  if ($opts{csv}) {
    my $filename = "$opts{from}_$opts{to}.csv";
    
    $filename =~ s/\//-/g;
    $filename =~ s/\@//g;
    
    debug "branchpath = $opts{branchpath}";
    
    exportCSV $filename, getChanges $opts{from}, $opts{to}, $opts{branchpath};
    
    return;
  } # if

  if ($opts{html}) {
    heading 'Release Mission Control', $msg;
  } else {
    display "$msg\n";
  } # if

  if ($opts{html}) {
    my $startTime = time;
    displayChangesHTML getChanges $opts{from}, $opts{to}, $opts{branchpath};  
    
    footing $startTime;
  } else {
    displayChanges getChanges $opts{from}, $opts{to}, $opts{branchpath};
  } # if

  return;
} # main

main;

exit;
 
