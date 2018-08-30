#!/usr/bin/perl
use strict;
use warnings;

=pod

=head1 NAME $RCSfile: cqquery.pl,v $

Clearquest Query

This command line tool allows for a simplified access to Clearquest database 
and supports an SQL like syntax to allow you to select and update data quickly.
It has the ability to talk to a running Clearquest::Server process so you can 
use it on systems that do not have Clearques installed.

Currently the command langauge is limited - no joins or multiple tables, only
very simple where conditions, etc. This may improve over time.

All actions are logged to cqquery.log.

Note that CmdLine is in use so you have a fully command history stack (subject, 
of course, to whether or not you have Term::ReadLine::Gnu installed. For cqperl
that's a no go. For Cygwin's Perl or Linux based Perl's you do or can install it
from CPAN) as well as CmdLine builtins like history and help.

Control-C handling is also supported.

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.3 $

=item Created:

Mon Oct 24 16:19:15 PDT 2011

=item Modified:

$Date: 2012/12/18 19:44:10 $

=back

=head1 SYNOPSIS

 Usage: cqquery [-u|sage] [-v|erbose] [-d|ebug]
                [-username <username>] [-password <password>]
                [-database <database>] [-dbset <dbset>]
                [-histfile <histfile>]
                [-[no]c|qd] 

 Where:
   -usa|ge:     Displays usage
   -v|erbose:   Be verbose
   -de|bug:     Output debug messages

   -h|istfile <histfile>: History file to use

   -use|rname <username>: Username name to use
   -p|assword <password>: Password to use
   -da|tabase <database>: Database to use
   -db|set    <dbset>:    DB Set to use
   -[no]c|qd:             If set then look for a Clearquest::Server

=head1 FILES
   
Configuration data is stored in ../etc/cqdservice.conf which defines the 
defaults for things like username/password/db, etc. These are overridden by the
environent (-username is CQD_USERNAME, -password is CQDPASSWORD, etc.  for
server based connections, CQ_USERNAME, CQPASSWORD, etc. for direct connections).
Command line options (e.i. -username) override both the environment and the 
config file.
   
=cut

# TODO: This needs major revision...

use FindBin;
use Term::ANSIColor;
use Getopt::Long;

use lib "$FindBin::Bin/../lib";

use CmdLine;
use Display;
use Logger;
use Utils;

my $VERSION  = '$Revision: 1.3 $';
  ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);

my %cmds = (
  select => {
    help        => 'select <fields> from <table> [where <condition>]',
    description => 'Selects fields from a table with an optional condiiton. 
Currently conditions are limited.    
',    
  },

  update => {
    help        => 'update <table> set <field> = <expr> [where <condition>]',
    description => 'Update a field in a table based on an optional condition',
  },
  
  insert => {
    help        => 'insert [into] <table> <fields> values <values>',
    description => 'Insert a new record into table',
  },
  
  delete => {
    help        => 'delete [from] <table> [where <condition>]',
    description => 'Delete records from table based on condition (not implemented)',
  },
);
  
my (%opts, $cq, $log, $pipe);

sub interrupt () {
  display_nolf
    color ('yellow')
  . '<Control-C>'
  . color ('reset')
  . '... '
  . color ('red')
  . "Abort current operation (y/N)?"
  . color ('reset');

  my $response = <STDIN>;
  chomp $response;

  die "Operation aborted\n"  if $response =~ /^\s*(y|yes)/i;

  display color ('cyan') . 'Continuing...' . color ('reset');
} # interrupt

sub pipeInterrupt () {
  StopPipe $pipe;
  
  undef $pipe;
} # pipeInterrupt

sub findRecords ($$;@) {
  my ($table, $condition, @fields) = @_;
  
  my ($result, $nbrRecs) = $cq->find ($table, $condition, @fields);
  
  $nbrRecs ||= 0;
  
  my $msg = "$nbrRecs records qualified";
  
  $SIG{PIPE} = \&pipeInterrupt;
  
  $pipe = StartPipe $ENV{PAGER};
  
  PipeOutput $msg, $pipe; 
  
  $log->log ($msg);
  
  return ($result, $nbrRecs);
} # findRecords

sub select ($$@) {
  my ($table, $condition, @fields) = @_;

  my ($result, $nbrRecs) = findRecords ($table, $condition, @fields);
  
  if ($cq->errnbr) {
    error $result;

    return;
  } # if
  
  while (my %record = $cq->getNext ($result)) {
    last unless $pipe;
    
    foreach (@fields) {
      last unless $pipe;
      
      my $line = $record{$_} ? "$_: $record{$_}" : "$_ <undef>";
      
      $log->log ($line);

      PipeOutput $line, $pipe;
    } # foreach
  } # while
  
  StopPipe $pipe;
  
  undef $pipe;
} # select

sub update ($$%) {
  my ($table, $condition, %update) = @_;
  
  my ($result, $nbrRecs) = findRecords ($table, $condition);
  
  if ($cq->errnbr) {
    error $result;

    return;
  } # if
  
  $nbrRecs ||= 0;
  
  $log->disp ("$nbrRecs records qualified");

  my ($processed, $updated) = (0, 0);
    
  while (my %record = $cq->getNext ($result)) {
    $processed++;
    
    my $key = $cq->key ($table, $record{dbid});
    
    $log->disp ("Updating $key", 1);

    my $errmsg = $cq->updateRec ($table, $record{dbid}, %update);
  
    if ($errmsg ne '') {
      $log->disp (color ('red') . ' failed!!' . color ('reset'));
      $log->incrementErr;
      $log->log ($errmsg);
    } else {
      $log->disp (color ('green' ). ' succeeded.' . color ('reset'));

      $updated++;
    } # if
  } # while
  
  my $errors = $log->errors;

  return unless $processed;
    
  my $msg;
  
  $msg = $processed;    
    
  if ($processed == 1) {
    $log->disp ('One record processed');
  } else {
    $log->disp ("$processed records processed");
  } # if

  if ($updated == 1) {
    $log->disp ('One record updated');
  } else {
    $log->disp ("$updated records updated");
  } # if

  if ($errors == 1) {
    $log->disp ('One error (Check ' . $log->fullname . ' for more info)');
  } elsif ($errors > 1) {
    $log->disp ("$errors errors (Check " . $log->fullname . ' for more info)');
  } else {
    $log->disp ("$errors errors");
  } # if
} # update

sub insert ($%) {
  my ($table, %values) = @_;
  
  my $errmsg = $cq->insert ($table, %values);
  
  if ($errmsg ne '') {
    $log->err ("Unable to insert record:\n$errmsg");
  } else {
    $log->disp ("Inserted record");
  } # if
} # insert

sub evaluate ($) {
  my ($line) = @_;
  
  my @fields;
  
  # Mimic simple SQL statements...
  if ($line =~ /^\s*select\s+([\w, ]+)\s+from\s+(\S+)(.*)\;*/i) {
    my ($table, $condition, $rest);
    
    @fields = split (/\s*,\s*/, $1);
    $table  = $2;
    $rest   = $3;
  
    # Trim any trailing ';' from table in case the person didn't enter a where
    # clause
    $table =~ s/\;$//;
      
    if ($rest =~ /\s*where\s+(.*?)\;*$/i) {
      $condition = $1;
    } elsif ($rest !~ /^\s*$/) {
      error "Syntax error in select statement\n\n\t$line";
      
      return 1;
    } # if
    
    return ::select ($table, $condition, @fields);
  } elsif ($line =~ /^\s*update\s+(\S+)\s+set\s+(\S+)\s*=\s*(.*)/i) {
    my ($table, $condition, %update, $rest);
    
    $table = $1;
    $rest  = $3;
    
    my $fieldName = $2;

    my $value;
        
    if ($rest =~ /(.*)\s+where\s+(.*)/) {
      $value     = $1;
      $condition = $2;
    } else {
      $value = $rest;
    } # if
    
    # Fix up $value;
    $value =~ s/^\s*["'](.*)/$1/;
    $value =~ s/(.*)["']\s*$/$1/;
    
    $update{$fieldName} = $value;
    
    return update ($table, $condition, %update);
  } elsif ($line =~ /^\s*insert\s+(into)*\s+(\S+)\s+([\w, ]+)\s+values*\s+([\w, ]+)\;*/i) {
    my ($table, @values);
  
    $table  = $2;
    @fields = split /\s*,\s*/, $3;
    @values = split /\s*,\s*/, $4;

    my %values;
    
    $values{$_} = shift @values foreach (@fields);
    
    return ::insert ($table, %values);    
  } elsif ($line =~/^\s*shutdown\s*$/) {
    $cq->shutdown;
    
    exit;
  } elsif ($line =~ /^\s*$/) {
    return;
  } else {
    $log->err ("Unknown command: $line");
    
    return 1;
  } # if
} # evaluate

## Main
$| = 1;

# Use test database for now...
$opts{database} = 'mobct';
$opts{histfile} = $ENV{CQQUERY_HISTFILE} || "./${FindBin::Script}_hist";
$opts{cqd} = 1;

GetOptions (
  \%opts,
  usage   => sub { Usage },
  verbose => sub { set_verbose },
  debug   => sub { set_debug },
  'cqd!',
  'username=s',
  'database=s',
  'password=s',
  'histfile=s',
  'dbset=s',
) || Usage;

display "$FindBin::Script v$VERSION";

$SIG{INT} = \&interrupt;

if ($opts{cqd}) {
  require Clearquest::Client;  
  $cq  = Clearquest::Client->new (%opts);
} else {
  require Clearquest;
  $cq  = Clearquest->new (\%opts);
} # if

$log = Logger->new;

my $me = $FindBin::Script;
   $me =~ s/\.pl$//;

my $prompt = color ('bold green') . "$me:" . color ('reset');
$prompt="$me:";

$CmdLine::cmdline->set_histfile ($opts{histfile});  
$CmdLine::cmdline->set_prompt ($prompt);
$CmdLine::cmdline->set_cmds (%cmds);
$CmdLine::cmdline->set_eval (\&evaluate);

my ($line, $result);

my $dbconnection = $cq->username . '@' . $cq->database . '/' . $cq->dbset; 
   $dbconnection .= ' (Server: ' . $cq->host . ':' . $cq->port . ')'
     if ref $cq eq 'Clearquest::Client';

my $msg = "Opening database $dbconnection";
     
verbose_nolf color ('dark white') . "$msg..." . color ('reset');
$log->log ($msg, 1);  

unless ($cq->connect) {
  $log->msg (color ('red') . ' Failed!' . color ('reset'));

  $log->err ("Unable to connect to database $dbconnection", 1);
} else {
  verbose color ('dark white') . ' connected' . color ('reset');
  $log->log (' connected');
} # unless

# Single execution from command line
if ($ARGV[0]) {
  my $result = evaluate join ' ', @ARGV;

  $result ||= 1;

  exit $result;
} # if

while (($line, $result) = $CmdLine::cmdline->get ()) {
  last unless defined $line;
  
  $log->log ("$me: $line");
  
  last if $line =~ /exit|quit/i;
  
  my $result = evaluate ($line);
} # while

$cq->disconnect;

exit;
