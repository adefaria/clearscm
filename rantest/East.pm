#############################################################################
#
# Name:		East.pm
#
# Description:	East.pm is a Perl module that encapsulates the East Simulator
#		as an object. Methods are provided to connect, configure and
#		run tests on an East Simulator.
#
# Author:	Andrew@DeFaria.com
#
# Copyright (c) 2008 General Dynamics
#
# All rights reserved except as subject to DFARS 252.227-7014 of contract
# number CP02H8901N issued under prime contract N00039-04-C-2009.
#
# Warning: This document contains technical data whose export is restricted
# by the Arms Export Control Act (Title 22, U.S.C., Sec 2751, et seq.) or the
# Export Administration Act of 1979, as amended, Title, 50, U.S.C., App. 2401
# et seq. Violations of these export laws are subject to severe criminal
# penalties. Disseminate in accordance with provisions of DoD Directive
# 5230.25.
#
##############################################################################
use strict;
use warnings;

package Nethawk::East;

use Carp;
use Expect;
use File::Basename;
use File::Copy;
use File::Path;
use File::Temp qw (tempfile);
use Getopt::Long;

use DateUtils;
use Display;
use Utils;
use Rexec;
use SCCM::Build::Utils;

use constant DEFAULT_TIMEOUT	=> 180;
use constant CCMACHINE		=> "cclinux";
use constant CLEARTOOL		=> "ssh " . CCMACHINE . " \"cd $ENV{PWD} && /opt/rational/clearcase/bin/cleartool\"";

use constant RANHOST		=> "ranray";
use constant RANUSER		=> "pswit";

use constant LOGHOST		=> "seast1";
use constant LOGUSER		=> "pswit";
use constant LOGBASE		=> "$ENV{MNT_DIR}/testlogs";
use constant RANTVL_LOGBASE	=> "/export/rantvl";

# This is a non-standard, but commonly used prompt around here. For
# EAST systems they use a terminator of "]$" as in "[p6258c@ceast1
# p6258c]$ " however on ranray it's more like "[ranray/home/pwit]
# ". So we look for both.
use constant PROMPT		=> qr'(\]\$|\] $)';

############################################################################
# Globals
############################################################################
my %_validTestTypes = (
  "load"	=> "LoadTCRunner",
  "manual"	=> "Manual",
  "pool"	=> "RegressionLoadRunner",
  "tc"		=> "RegressionRunner",
  "ts"		=> "RegressionTSRunner",
  "log"		=> "Rantvl",
  "shell"	=> "Shell",
);

sub LogDebug ($) {
  my ($msg) = @_;

  open FILE, ">>/tmp/rantest.debug.log"
    or die "Unable to open /tmp/rantest.debug.log for append - $!";

  print FILE "$msg";

  close FILE;
} # LogDebug

############################################################################
#
# new: Instantiate a new East object
#
# Parms:
#   none
#
# Returns:	New East object
#
############################################################################
sub new {
  my ($class) = @_;

  bless {
    timeout	=> DEFAULT_TIMEOUT,
    prompt	=> PROMPT,
  }, $class;
} # new

############################################################################
#
# validTestType:	Return a status indicating if the passed in
#			test type is valid (and an error message if not)
# Parms:
#   testType:		Type of test requested
#
# Returns:		List contains a status (0 = valid test type, 1 =
#			invalid test type) and an optional error message.
#
############################################################################
sub validTestType ($) {
  my ($testType) = @_;

  $testType = "<undefined>" if !$testType;

  return (0, "") if InArray (lc $testType, keys %_validTestTypes);

  my $msg = "Type must be one of:\n\n";

  foreach (sort keys %_validTestTypes) {
    $msg .= "  $_\t$_validTestTypes{$_}\n";
  } # foreach

  return (1, $msg);
} # validTestType

############################################################################
#
# inUse:	Check if the unit type and number is in use. Returns undef
#		if it is not being used or an error message if it is.
# Parms:	none
#
# Returns:	List contains a status (0 = not in use, 1 = in use) and an
#		optional error message.
#
############################################################################
sub inUse ($$) {
  my ($self) = @_;

  my $dut = "$self->{unitType}$self->{unitNbr}";

  my $lockfile1 = "$ENV{MNT_DIR}/$ENV{EAST_REL}/DUT/$dut/desktop.lock";
  my $lockfile2 = "$ENV{MNT_DIR}/$ENV{EAST_REL}/loadservers/$dut/desktop.lock";

  my ($owner, @lines);

  if (-f $lockfile1) {
    @lines = `ls -l $lockfile1`;

    $owner = (split /\s+/, $lines[0])[2] if $lines[0];
  } elsif (-f $lockfile2) {
    @lines = `ls -l $lockfile2`;

    $owner = (split /\s+/, $lines[0])[2] if $lines[0];
  } else {
    return undef;
  } # if

  my $owner_name = "Unknown user";

  return "ERROR: $dut is being tested now by $owner_name.\nDo not attempt to start EAST, it could cause serious problems." if !$owner;

  @lines = `ypmatch $owner passwd 2>&1`;

  if ($? == 0) {
    $owner_name = (split /:/, $lines[0])[4];
  } else {
    $owner_name = "ypmatch $owner passwd - failed";
  } # if

  if ($ENV{LOGNAME} eq $owner) {
    return "East in use by you. Exit east using desktop button before starting again.";
  } else {
    return "$dut is being tested now by $owner_name.\nDo not attempt to start EAST, it could cause serious problems.";
  } # if
} # inUse

############################################################################
#
# viewExists:	Checks to see if a remote view exists.
#
# Parms:
#   tag:	View tag to check
#
# Returns:	List contains a status (0 = view does not exist, 1 = view
#		exists) and the optional output from the lsview command.
#
############################################################################
sub viewExists ($) {
  my ($self, $tag) = @_;

  my $cmd = CLEARTOOL . " lsview $tag 2>&1";
  my @lines = `$cmd`;

  return ($?, @lines);
} # viewExists

############################################################################
#
# testExists:	Checks to see if a test exists
#
# Parms:
#   type:	Type of test to check (rbs, rnc or east)
#   name:	Name of test
#
# Returns:	0 if test exists, 1 if it doesn't.
#
############################################################################
sub testExists ($$) {
  my ($self, $type, $name) = @_;

  return 1 unless $self->{view};

  return 1 if $name eq "";

  my $vobPath = "vobs/simdev/tc_data";

  # Now compose testPath
  my $testPath = "$ENV{MNT_DIR}/snapshot_views/$self->{userdir}/$self->{view}/$vobPath";

  if ($type eq "LoadTCRunner") {
    $testPath .= "/tc/profiles/load/$name";
  } elsif ($type eq "RegressionRunner") {
    $testPath .= "/tc/profiles/tc/$name";
  } elsif ($type eq "RegressionLoadRunner") {
    croak "RegressionLoadRunner tests are not supported!";
  } elsif ($type eq "RegressionTSRunner") {
    $testPath .= "/tc/profiles/ts/$name";
  } # if

  return 0 if !-f $testPath;

  # Get test's name. Testname is stored in the profile file with a
  # .script at the end. This later useful when trying to find the
  # logfile as test name, not test filename, is used as part of the
  # component of the path of where the logfile will be written.
  my @lines = `strings $testPath | grep '\\.script'`;

  if ($? == 0 && $lines[0] =~ /(\S+)\.script$/) {
    $self->{testName} = $1;

    # We're looking for the leaf name therefore strip off everything
    # up to the last slash. For example, foo/bar/testname.scipt should
    # result in "testname".
    if ($self->{testName} =~ /.*\/(\S+)/) {
      $self->{testName} = $1;
    } # if
  } # if

  return 1;
} # testExists

############################################################################
#
# getLogFileContents:	Returns an array of the lines in the log file.
#
# Parms:		none
#
# Returns:		Array of lines from the "logical" logfile
#
############################################################################
sub getLogFileContents ($) {
  my ($self, $logFileName) = @_;

  # Get timestamp: A porition of the path to the log file is actually
  # a timestamp of the format MM.DD.YY_HH.MM.SS.MMM. It's difficult to
  # tell what this timestamp will become so we use the following
  # hueristic: We do an "ls -t $logFileName | head -1" on the remote
  # system. This should give us the most recently modified
  # file. Hopefully this will be the log file. However if multiple
  # processes are writing in this directory then there is the
  # possibility that our guess is wrong.
  my @lines = `ls -t $logFileName 2> /dev/null`;

  if ($? != 0) {
    error "Unable to ls -t $logFileName";

    LogDebug "BUG CATCHER: Here are the currently running java processes\n";
    @lines = `ps -efww | grep java | grep -v \'grep java\'`;

    LogDebug $_ foreach (@lines);

    return undef;
  } # if

  chomp $lines[0];

  # Get a list of logfiles
  $logFileName .= "/" . $lines[0] . "/detailedlogs/*_logs_*";

  @lines	= ();
  my @logfiles	= `ls $logFileName 2> /dev/null`;

  chomp @logfiles;

  foreach (@logfiles) {
    # Logfiles still contain binary stuff so use strings(1)
    my @logLines = `strings $_`;

    chomp @logLines;

    push @lines, @logLines;
  } # foreach

  return @lines;
} # getLogFileContents

############################################################################
#
# getLogFile:	Returns an array of the lines in the log file. Turns out
#		that EAST creates a $self->{testName}_logs_1 file until
#		it gets too large then creates a $self->{testName}_logs_2
#		logfile and so on. So we want to present one logical file
#		from n number of log files.
#
# Parms:	none
#
# Returns:	Array of lines from the "logical" logfile
#
############################################################################
sub getLogFile () {
  my ($self) = @_;

  # Bail out if testName not set
  return () if !$self->{testName};

  # Start path
  my $logFileName = "$ENV{MNT_DIR}/$ENV{EAST_REL}/DUT/$self->{unitType}$self->{unitNbr}/data/logs/";

  # Add on path as per type of test
  if ($self->{class} eq "load") {
    $logFileName .= "load/testcase/$self->{testName}";
  } elsif ($self->{class} eq "tc") {
    $logFileName .= "regression/testcase/$self->{testName}";
  } elsif ($self->{class} eq "ts") {
    # Testsuites can have "parts"
    $logFileName .= "regression/testsuite";

    my @lines;
    my @logfiles = `ls $logFileName 2> /dev/null`;

    chomp @logfiles;

    if (scalar @logfiles > 0) {
      foreach (@logfiles) {
	my @logLines = $self->getLogFileContents ("$logFileName/$_");

	push @lines, @logLines;
      } # foreach

      return @lines;
    } # if
  } elsif ($self->{class} eq "pool") {
    croak "Pool test type not implemented";
  } else  {
    croak "Invalid test case type $self->{class} found";
  } # if

  return $self->getLogFileContents ($logFileName);
} # getLogFile

############################################################################
#
# testResult:	Checks the test's logfile to determine the result
#
# Parms:
#   name:	Name of test
#
# Returns:	A status - 0 if we are able to get the results, 1 if we
#		can't - and a message of "Success", "Failure", "Incomplete"
#		or an error message
#
############################################################################
sub testResult ($) {
  my ($self, $name) = @_;

  my @lines = grep (/EXECUTION STATUS/, $self->getLogFile);

  my $testResult = "Incomplete";

  # Search for EXECUTION STATUS. Note there may be more than one
  # EXECUTION STATUS in the array. If so return the last one.
  if (scalar @lines > 0 && $lines[$#lines] =~ /EXECUTION STATUS :: (.*)/) {
    $testResult = $1;
    $testResult =~ s/\s+$//;
  } # if

  return (0, $testResult);
} # testResult

############################################################################
#
# shell:	Execute a shell script returning the results.
#
# Parms:
#   script:	Script to run.
#   opts:	Additional options passed to script
#
# Returns:      $status of shell exeuction and @lines of output
#
############################################################################
sub shell ($;$@) {
  my ($self, $script, @opts) = @_;

  my ($status, @output) = Execute ($script . join " ", @opts);

  $status >>= 8;

  return ($status, @output);
} # shell

############################################################################
#
# stackOptions:	Stacks options into an array. This is mainly here to handle
#		options that are quoted. Given a string of options like
#		'foo -bar "quoted value"' a simple split /\s+/, $str would
#		result in:
#
#		0 'foo'
#		1 '-bar'
#		2 '"quoted'
#		3 'value"'
#
#		using this function we'll get:
#
#		0 'foo'
#		1 '-bar'
#		2 'quoted value'
#
#		instead.
#
# Parms:
#   str		String of options to stack
#
# Returns:	Array of options stacked with quoted strings occupying a
#		single slot in the array.
#
# Notes:	Doesn't balance quotes. Also, you can use () instead of ""
#		(e.g. -if (condition is specified here)).
#
############################################################################
sub stackOptions ($) {
  my ($options) = @_;

  my (@opts, $str);

  my $hitString = 0;

  foreach (split /\s+/, $options) {
    if ($hitString) {
      if (/(\S*)[\"|\'|\)]$/) {
	$str .= $str ? " $1" : $1;
	$hitString = 0;

	push @opts, $str;

	undef $str;
      } else {
	$str .= $str ? " $_" : $_;
      } # if

      next;
    } else {
      # Handle situation where you got only one "word"
      if (/[\"|\'|\(](\S*)[\"\'\)]/) {
	push @opts, $1;
      } elsif (/[\"|\'|\(](\S*)/) {
	$str .= $str ? " $1" : $1;
	$hitString = 1;
      } else {
	push @opts, $_;
      } # if
    } # if
  } # foreach

  return @opts;
} # stackOptions

############################################################################
#
# rantvl:	Start rantvl
#
# Parms:
#   cmd:	Rantvl command to execute
#
# Returns:      $pid of rantvl process and a message
#
############################################################################
sub rantvl ($) {
  my ($self, $cmd) = @_;

  my $logged_in		= 0;
  my $timedout		= 0;
  my $logging_started	= 0;
  my @lines;

  # First establish an ssh session to RANHOST as RANUSER. Note we are
  # assuming that pre-shared key ssh access has already been set up
  # here.
  $self->{rantvl} = new Expect ("ssh " . RANUSER . "\@" . RANHOST);

  return (1, "Unable to connect to " . RANHOST . " as " . RANUSER)
    unless $self->{rantvl};

  $self->{rantvl}->log_user (get_debug);

  $self->{rantvl}->expect (
    $self->{timeout},

    [ PROMPT,
      sub {
	$logged_in = 1;
      }
    ],

    [ timeout =>
      sub {
	$timedout = 1;
      }
    ],
  );

  if ($timedout) {
    return (1, "Timed out when connecting to " . RANHOST . " as " . RANUSER);
  } elsif (!$logged_in) {
    return (1, "Unable to connect to " . RANHOST . " as ". RANUSER);
  } # if

  # Get test options. It seems GetOptions doesn't support taking input
  # from anything but @ARGV so we'll have to save a copy and restore
  # it.  See eastUsage for more info.
  my $rantvlTimeout	= $self->{timeout};
  my @savedOptions	= @ARGV;
  @ARGV			= stackOptions $cmd;

  # Don't complain about unknown options
  Getopt::Long::Configure "pass_through";

  # Only really care about timeout...
  GetOptions (
    "timeout=i", \$rantvlTimeout,
  );

  # Reassemble $cmd after GetOptions has processed it
  $cmd	= join " ", @ARGV;
  @ARGV	= @savedOptions;

  # Now start rantvl
  $self->{rantvl}->send ("$cmd\n");

  $self->{rantvl}->expect (
    $rantvlTimeout,

    [ qr"^Our pid is ",
      sub {
	my $pid = $_[0]->after;

	if ($pid =~ /(\d+)/) {
	  $logging_started = $1;
	} # if
      }
    ],

    [ PROMPT,
      sub {
	my @output = split /\n/, $_[0]->before;

	foreach (@output) {
	  chomp;
	  chop if /\r$/;
	  push @lines, $_;
	} # foreach
      }
    ],

    [ timeout =>
      sub {
	$timedout = 1;
      }
    ],
  );

  if ($logging_started) {
    return ($logging_started, "Logging started");
  } elsif ($timedout) {
    return (0, "Timed out executing rantvl");
  } else {
    return (0, join "\n", @lines);
  } #if
} # rantvl

############################################################################
#
# rendezvous:	Rendezvous with EAST process by searching the log file for
#		a specific phrase. We will use $self->{timeout} to determine
#		how long we are gonna wait for this phrase to appear. We
#		will divide $self->{timeout} by 10, making 10 attempts. So
#		with a default timeout of 180 seconds, we will try 10 times
#		18 seconds apart, for the phrase to appear before timing
#		out.
#
# Parms:
#   phrase:	Phrase to search for
#   timeout:	How long to time out waiting for the rendezvous
#
# Returns:	undef if rendezvous was successful - error message
#		otherwise.
#
############################################################################
sub rendezvous ($;$) {
  my ($self, $phrase, $timeout) = @_;

  my $status;

  my $attempts = 0;

  $timeout = $timeout ? $timeout : $self->{timeout};

  while (!$status && $attempts++ < 10) {
    display_nolf "Attempt #$attempts" if get_debug;

    my @lines = grep (/$phrase/, $self->getLogFile);

    last if scalar @lines > 0;

    display " sleeping " . $timeout / 10 . " seconds" if get_debug;
    sleep $timeout / 10;
  } # while

  if ($attempts > 10) {
    return "Timed out";
  } else {
    return undef;
  } # if
} # rendezvous

############################################################################
#
# connected:	Checks to see if you're connected to EAST
#
# Parms:
#   none
#
# Returns:	undef if connected - error message otherwise
#
############################################################################
sub connected () {
  my ($self) = @_;

  my $serverLogPath	= "$ENV{MNT_DIR}/$ENV{EAST_REL}/DUT/$self->{unitType}$self->{unitNbr}/data/logs/Server_Logs";
  my $serverLog		= $self->{unitType} eq "rbs"
			? "$serverLogPath/rnc_aal2.log"
			: "$serverLogPath/nodeb_aal2_utran.log";
  my $searchStr		= "Successfully connected to EventServer";
  my $cmd		= "grep -q \"$searchStr\" $serverLog > /dev/null 2>&1";
  my @lines;

  # We'll try up to 2 minutes, every 5 seconds...
  my $timedout = 0;

  while ($timedout < (60 * 2)) {
    @lines = `$cmd`;

    last if $? == 0;

    sleep 5;

    $timedout += 5;
  } # while

  return "Timed out while attempting to rendezvous with server"
    if $timedout >= (60 * 2);

  # Get RBS/RNC version string Must translate unitType and unitNbr
  # into a machine name of the form "ran{type}{nbr}" but we refer to
  # to things as 1-7 and they want things like 01-07. So we do
  # "ran{type}0{nbr}" give us things like ranrbs01 or ranrnc03.

  # Here's another instance where using DNS aliases are messing us up.
  # Pat Phelps was testing on -unit 3m2. But that would have made
  # $machine = ranrnc03m2 and the "grep ^$machine below would fail. So
  # for a kludge we simply substr the first character of
  # $self->{unitNbr}.
  my $machine = "ran$self->{unitType}0" . substr $self->{unitNbr}, 0, 1;

  $cmd  = "/prj/muosran/SWIT/moshell/swstat ";
  $cmd .= "/prj/muosran/SWIT/moshell/sitefiles/$machine ";

  # Here we are grepping for lines begining with ^$machine, however
  # there are more than one, hence the tail -1.
  $cmd .= "| grep ^$machine | tail -1";

  @lines = $self->{msh}->exec ($cmd);

  # For some reason we are sometimes getting junk in $lines [0] so
  # filter out lines that don't have ^$machine in it.
  @lines = grep (/^$machine/, @lines);

  if ($lines[0] && $lines[0] =~ /\w+\s+(\w+)/) {
    my $rstate = $1;

    my $build_no = Utils->getLoadFromRState ($rstate);

    $self->{ran_version} = uc ($self->{unitType}) . ":$rstate-$build_no";
  } # if

  return undef;
} # connected

############################################################################
#
# connect:	Connects to the remote East machine
#
# Parms:
#   view:	View name to set to to run the the test
#   unitType:	Type of unit (rbs, rnc or east)
#   unitNbr:	Number of the unit
#   tm500:	Name of tm500 view (if any)
#   nms:	Name of nms view (if any)
#
# Returns:	Undefined if connection was successful or error message if
#		not
#
############################################################################
sub connect ($$$;$$$$) {
  my ($self, $view, $unitType, $unitNbr, $tm500, $nms, $feature, $secure) = @_;

  $self->{unitType} = lc $unitType;

  croak "ERROR: Type must be rbs, rnc or east"
    unless $self->{unitType} eq "rbs" or
	   $self->{unitType} eq "rnc" or
           $self->{unitType} eq "east";

  $self->{unitNbr} = $unitNbr;

  # Check if unit is in use
  my $msg = $self->inUse;

  return $msg if $msg;

  # Check that view exists
  my ($status, @lines) = $self->viewExists ($view);

  return "View $view does not exist" if $status;

  # Save $view - we'll need it later...
  $self->{view} = $view;

  if ($self->{view} =~ /(\S+)_SIM/) {
    $self->{userdir} = $1;
  } else {
    croak "ERROR: Unable to find userdir";
  } # if

  # Connect as RANUSER@RANHOST and store the connection. We'll need
  # this to secure the node and we'll need this later on too.
  debug "Connecting to ". RANHOST . " as " . RANUSER;

  $self->{msh} = new Rexec (
    host	=> RANHOST,
    username	=> RANUSER,
    prompt	=> PROMPT,
  );

  error "Unable to connect to " . RANHOST . " as " . RANUSER, 1
    unless $self->{msh};

  # Secure node
  if ($secure) {
    my $node   = "$self->{unitType}$self->{unitNbr}";

    # We need to wait for a while since this securenode command takes
    # a while. Looking briefly, securenode took 4'51" to run. So we'll
    # wait up to... 10 minutes...
    my $secureNodeTimeoutMinutes = 10;
    my $secureNodeTimeoutSeconds = $secureNodeTimeoutMinutes * 60;

    verbose "Attempting to secure node $node - This make take a while...\n"
          . "(Will timeout in $secureNodeTimeoutMinutes minutes)";

    my @lines  = $self->{msh}->exec ("/prj/muosran/SWIT/tools/bin/securenode $node", $secureNodeTimeoutSeconds);
    my $status = $self->{msh}->status;

    if ($status != 0) {
      if ($status == 1) {
	error "The node $node is not known", $status;
      } elsif ($status == 2) {
	error "The node $node is not responding", $status;
      } elsif ($status == 3) {
	error "Unable to secure $node", $status;
      } elsif ($status == -1) {
	error "Timed out attempting to secure node $node", $status;
      } else {
	error "Unknown error has occurred", $status;
      } # if
    } else {
      verbose "Node $node secured";
    } # if
  } # if

  debug "Starting $unitType on unit $unitNbr";

  my $cmd = "$self->{unitType} $self->{unitNbr}";

  my $start_str		= "StaRT";
  my $errno_str		= "ReXeCerRoNO=\$?";
  my $compound_cmd	= "echo $start_str; $cmd; echo $errno_str";

  $self->{remote} = new Expect ($compound_cmd);

  $self->{remote}->log_user (get_debug);

  my $result;

  @lines = ();

  $self->{remote}->expect (
    $self->{timeout},

    [ timeout =>
      sub {
	my $exp		= shift;
	my $before	= $exp->before;
	my $after	= $exp->after;
	push @lines, "$cmd timed out";
	$result = -1;
      }
    ],

    [ qr "$start_str",
      sub {
	exp_continue;
      }
    ],

    [ qr "$errno_str",
      sub {
	my $exp		= shift;
	my $before	= $exp->before;
	my $after	= $exp->after;
	
	if ($after =~ /(\d+)/) {
	  $status = $1;
	} # if

	my @output = split /(\n\r)/, $before;

	foreach (@output) {
	  chomp;
	  chop if /\r$/;
	  last if /$errno_str=/;
	  next if /^$/;
	  push @lines, $_;
	} # foreach

	exp_continue;
      }
    ],

    [ $self->{prompt},
      sub {
        debug "Hit prompt";
      }
    ],
  );

  return join "\n", @lines if $status != 0;

  # Set prompt to something distinctive
  $self->{prompt}	= "\@\@\@";
  $cmd			= "export PS1=$self->{prompt}\n";

  $self->{remote}->send ($cmd);

  $self->{remote}->expect (
    $self->{timeout},

    [ timeout =>
      sub {
	$result = "$cmd timed out";
      }
    ],

    [ "^$self->{prompt}",
      sub {
        debug "Hit prompt";
      }
    ],
  );

  return $result if $result;

  # Set TM500_VIEW if passed in
  if ($tm500) {
    $cmd = "export TM500_VIEW=$tm500\n";

    $self->{remote}->send ($cmd);

    $self->{remote}->expect (
      $self->{timeout},

      [ timeout =>
        sub {
  	  $result = "$cmd timed out";
        }
      ],

      [ "^$self->{prompt}",
        sub {
          debug "Hit prompt";
        }
      ],
    );

    return $result if $result;
  } # if

  # Set NMS_VIEW if passed in
  if ($nms) {
    $cmd = "export NMS_VIEW=$nms\n";

    $self->{remote}->send ($cmd);

    $self->{remote}->expect (
      $self->{timeout},

      [ timeout =>
        sub {
  	  $result = "$cmd timed out";
        }
      ],

      [ "^$self->{prompt}",
        sub {
          debug "Hit prompt";
        }
      ],
    );

    return $result if $result;
  } # if

  # Set FEATURE if passed in
  if ($feature) {
    $cmd = "export FEATURE=$feature\n";

    $self->{remote}->send ($cmd);

    $self->{remote}->expect (
      $self->{timeout},

      [ timeout =>
        sub {
  	  $result = "$cmd timed out";
        }
      ],

      [ "^$self->{prompt}",
        sub {
          debug "Hit prompt";
        }
      ],
    );

    return $result if $result;
  } # if

  debug "Starting EAST CLI in view $self->{view} on $self->{unitType}$self->{unitNbr}";

  $cmd		= "start_east_auto $self->{view} $self->{unitType}$self->{unitNbr}";
  $compound_cmd	= "echo $start_str; $cmd; echo $errno_str";

  my $attempts = 0;

  $self->{remote}->send ("$compound_cmd\n");

  $self->{remote}->expect (
    $self->{timeout},

    [ timeout =>
      sub {
	push @lines, "$cmd timed out";
	$status = -1;
      }
    ],

    [ qr "$start_str",
      sub {
        exp_continue;
      }
    ],

    [ qr "$errno_str",
      sub {
	my $exp		= shift;
	my $before	= $exp->before;
	my $after	= $exp->after;
	
	if ($after =~ /(\d+)/) {
	  $status = $1;
	} # if

	my @output = split /(\n\r)/, $before;

	foreach (@output) {
	  chomp;
	  chop if /\r$/;
	  last if /$errno_str=/;
	  next if /^$/;
	  push @lines, $_;
	} # foreach

	exp_continue;
      }
    ],

    [ $self->{prompt},
      sub {
        debug "Hit prompt";
      }
    ],
  );

  unless ($status == 0) {
    return "Unable to execute $cmd" . join "\n", @lines;
  } else {
    return $self->connected;
  } # if
} # connect

############################################################################
#
# eastUsage:	Displays East command options
#
# Parms:
#   msg:	Usage message
#
# Returns:	1 for failure
#
############################################################################
sub eastUsage (;$) {
  my ($msg) = @_;

  my $usage = "ERROR: $msg\n\n" if $msg;

  $usage .= <<END;
Usage: East::exec (<test class> <testname> <opts>)

Where <opts>:

\t[-activecalls <n>]
\t[-displaylevel <n>]
\t[-executionlevel <n>]
\t[-loglevel <n>]
\t[-mode <admin|local>]
\t[-p <property=value>]
\t[-runnerid <id>]
\t[-testbed <name>]
\t[-testenvironment <testenvironmentname>]
\t[-timeout <n>]
\t[-pause <n>]

  -timeout <n>		Specifies the timeout for this test's execution.
			If negative the test will be placed in the
			background. No result is recovered from
			background tests nor are any logfiles analysed
			or stored. If positive then this sets the
			timeout period for this test in seconds.

  -pause <n>		Used in conjunction with -timeout. If test is
			backgrounded then $FindBin::Script will wait
			pause seconds before returning control from
			this test. This allows the backgrounded test
			time to start.

  -name <name>		Names a test. Used in conditional execution.

  -if (<name> <status>)	Run this test if the named test returned <status>
			where <status> is one of

			  . Success
			  . Failure
			  . In Progress
			  . Timed out
			  . Failed to execute
			  . Rendezvous
			  . Failed to rendezvous

Note: -flag is supported by setting the -timeout appropriately. Setting
timeout <= 0 will result in -flag NOT being specified. Setting timeout
> 0 will result in -flag being specified.

Also -run is always set. After all, we're automation here! :-)

For other options see "Command Line in EAST" for more info.
END

  display $usage;

  return 1 if $msg;
} # easeUsage

############################################################################
#
# exec:		Executes a test remotely on East.
#
# Parms:
#   opts	A reference to a hash of options
#   results	A reference to a hash of execution results
#
# Note: $opts{timeout} can be set to the nNumber of seconds to wait
# for test to finish. Default: DEFAULT_TIMEOUT seconds. Set to 0 to
# indicate to wait forever. Note that timeout can be set per
# individual exec of a test case or set view setTimeout for all future
# test exec's or obtained via getTimeout.
#
# Returns:	0 for success, otherwise failure
#
############################################################################
sub exec ($$) {
  my ($self, $opts, $results) = @_;

  my $testResult;

  $self->{class} = lc $$opts{class};

  # The log class is special - It means run rantvl - so we handled it
  # differently here and then return quickly.
  if ($self->{class} eq "log") {
    # You'd think that /prj/muosran/SWIT/tools/bin would be in pswit's
    # path...
    my $cmd = "/prj/muosran/SWIT/tools/bin/$$opts{test}";

    # Add unit and number
    $cmd .= " -$self->{unitType} $self->{unitNbr}";

    # Add flag to get pid
    $cmd .= " -pid";

    # Compose -logpath
    $cmd .= " -logpath $self->{saveTo}";

    # Now start up rantvl
    my ($status, $msg) = $self->rantvl ($cmd);

    # Status is reversed here. The rantvl subroutine returns the pid
    # of the rantvl process for success - 0 for failure. So we flip
    # the boolean here.
    return !$status, $msg;
  } elsif ($self->{class} eq "shell") {
    # The shell class is also special. Here we execute any arbitrary
    # shell command. Initially this has been implemented simply
    # because of a request to be able to pause between test steps
    # (e.g. sleep 10) but it was decided to make this pretty general
    # so any shell command is acceptable. Note we do not evaluate the
    # result of the execution or at least it does not influence the
    # status of the test at this time.
    my ($status, @lines) = $self->shell ($$opts{test});

    if ($status == 0) {
      return $status, "Success";
    } else {
      if (scalar @lines == 0) {
	return $status, "Unknown error occurred while executing $$opts{test}";
      } else {
	return $status, join "\n", @lines;
      } # if
    } # if
  } elsif ($self->{class} eq "manual") {
    # The manual class will be similiar to the shell class except
    # that its intent is to provide an environment for the user
    # to run any number of manual tests and then return to rantest

    # For the user's convenience - put $logpath into the environment
    $ENV{LOGPATH} = LOGBASE . "/$self->{saveTo}";

    display "Perform your manual tests - type exit when finished";

    # Now run the user's shell
    system ($ENV{SHELL});

    print "Did your tests complete successfully? (y/N) ";

    my $response = <STDIN>;

    if ($response =~ /y/i) {
      return 0, "Success";
    } else {
      return 1, "Manual test(s) failed";
    } # if
  } # if

  my ($status, $msg) = validTestType ($self->{class});

  return ($status, $msg) if $status;

  # Convert short type names -> a valid test class
  my $testClass = $_validTestTypes{$self->{class}};

  my $runopts = "-log -run";

  # Get test options. It seems GetOptions doesn't support taking input
  # from anything but @ARGV so we'll have to save a copy and restore
  # it.  See eastUsage for more info.
  my @savedOptions = @ARGV;

  @ARGV = stackOptions $$opts{test};

  # These options should be reset and not linger from one test to the
  # next.
  undef $$opts{if};
  undef $$opts{name};
  undef $$opts{rendezvous};
  undef $$opts{timeout};

  # Default testbed to type & unit #
  $$opts{testbed} = "$self->{unitType}$self->{unitNbr}";

  $status = GetOptions (
    $opts,
    "activecalls=i",
    "displaylevel=i",
    "executionlevel=i",
    "loglevel=i",
    "mode=s",
    "p=s",
    "pause=i",
    "runnerid=s",
    "testbed=s",
    "testenvironment=s",
    "timeout=i",
    "name=s",
    "if=s",
    "rendezvous=s",
  );

  if (!$status) {
    $msg = "Unknown option";

    eastUsage $msg;

    return (1, $msg);
  } # if

  # Reassemble $$opts{test} after GetOptions has processed it
  $$opts{test}	= join " ", @ARGV;
  @ARGV		= @savedOptions;

  # Check other options:
  if (defined $$opts{displaylevel} and
      ($$opts{displaylevel} < 0 or
       $$opts{displaylevel} > 6)) {
    $msg = "displaylevel must be between 0-6";

    eastUsage $msg;

    return (1, $msg);
  } # if

  if (defined $$opts{executionlevel} and
      ($$opts{executionlevel} < 0 or
       $$opts{executionlevel} > 6)) {
    $msg = "executionlevel must be between 0-6";

    eastUsage $msg;

    return (1, $msg);
  } # if

  return (1, "ERROR: Test $$opts{test} does not exist")
    unless $self->testExists ($testClass, $$opts{test});

  # If run sequentially then we add the -flag that says run the test
  # then close the window - Odd I know... Otherwise we omit the -flag
  # which will cause the test to run and the window to remain up.
  $runopts .= " -flag" if !$$opts{timeout} || $$opts{timeout} > 0;

  # Options that must appear in the front
  my $frontopts = "-name $$opts{test}";
  $frontopts   .= " -testbed $$opts{testbed}"			if $$opts{testbed};
  $frontopts   .= " -testenvironment $$opts{testenvironment}"	if $$opts{testenvironment};

  # Process other options
  $runopts .= " -activecalls $$opts{activecalls}"		if $$opts{activecalls};
  $runopts .= " -displaylevel $$opts{displaylevel}"		if $$opts{displaylevel};
  $runopts .= " -executionlevel $$opts{executionlevel}"		if $$opts{executionlevel};
  $runopts .= " -mode $$opts{mode}"				if $$opts{mode};
  $runopts .= " -p $$opts{p}"					if $$opts{p};
  $runopts .= " -runnerid $$opts{runnerid}"			if $$opts{runnerid};

  my $cmd = "java $testClass $frontopts $runopts";

  $cmd .= "&" if $$opts{timeout} && $$opts{timeout} < 0 ||
                 $$opts{rendezvous};

  my $timeout = $$opts{timeout} && $$opts{timeout} > 0 ? $$opts{timeout} : $self->{timeout};

  if ($$opts{if}) {
    my @components	= split " ", $$opts{if};
    my $testName	= shift @components;
    my $result		= lc (join " ", @components);

    if ($$results{$testName} && $$results{$testName} ne $result) {
      $testResult = "Skipped";

      $$results{$$opts{name}} = lc $testResult if $$opts{name};

      return (1, $testResult);
    } # if
  } # if

  debug "\nRunning $cmd";

  my ($startTime, $attempts, $duration);

  my $result = 0;

  use constant MAX_ATTEMPTS => 4;

  $attempts	= 0;
  $duration	= 60;

  my $expectBuffer;

  do {
    $startTime	= time;
    $attempts++;

    $self->{remote}->send ("$cmd\n");

    $self->{remote}->expect (
      $timeout,

      [ timeout =>
        sub {
	  $result = -1;
        }
      ],

      [ $self->{prompt},
        sub {
	  my $exp	= shift;
	  my $before	= $exp->before;
	  my $after	= $exp->after;

	  $expectBuffer = "->$before<->$after<-";
          debug "Hit prompt";
        }
      ],
    );

    $duration = time - $startTime;

    if ($duration < 2 and $attempts > 0) {
      if ($cmd !~ /&$/) {
	if ($$opts{file}) {
	  LogDebug "File: $$opts{file}";
	} else {
	  LogDebug "File: Not set";
	} # if
	LogDebug "That happened too quickly! Attempt #$attempts of " . MAX_ATTEMPTS . " to restart cmd (Duration: $duration)\n$cmd\n";
	LogDebug "Contents of expect buffer:\n$expectBuffer";
	warning "That happened too quickly! Attempt #$attempts of " . MAX_ATTEMPTS . " to restart cmd\n$cmd\n";
	display "The following is debug output:";
	display "-" x 80;
	display "Contents of expect buffer:\n$expectBuffer";
	display "-" x 80;
	display "End of debug output";
      } # if
    } # if

    unless ($duration > 2 or $attempts >= MAX_ATTEMPTS or $cmd =~ /&$/) {
      LogDebug "Looping around for another try\n";
    } # unless
  } until ($duration > 2 or $attempts >= MAX_ATTEMPTS or $cmd =~ /&$/);

  if ($result == -1) {
    # Timed out. Kill stuck process
    $self->{remote}->send ("\cC");

    $self->{remote}->expect (
      $timeout,

      [ $self->{prompt},
        sub {
	  debug "Hit prompt";
	}
      ],
    );

    return (-1, "Timed out");
  } # if

  # If we backgrounded ourselves then there's no real status to
  # retrieve - we must just hope for the best.
  if ($cmd =~ /&$/) {
    # Pause to allow test to start up.
    my $pause = $$opts{pause} ? $$opts{pause} : 0;

    debug "Sleeping $pause seconds";
    sleep $pause;
    debug " Gee that was refressing!";

    if ($$opts{rendezvous}) {
      if ($self->rendezvous ($$opts{rendezvous}, $$opts{timeout})) {
	$testResult = "Unable to rendezvous";

	$$results{$$opts{name}} = lc $testResult if $$opts{name};

	return (1, $testResult);
      } else {
	$testResult = "Rendezvous";

	$$results{$$opts{name}} = lc $testResult if $$opts{name};

	return (0, $testResult);
      } # if
    } else {
      $testResult = "In progress";

      $$results{$$opts{name}} = lc $testResult if $$opts{name};

      return (0, $testResult);
    } # if
  } # if

  ($status, $testResult) = $self->testResult ($$opts{test});

  $$results{$$opts{name}} = lc $testResult if $$opts{name};

  # Get TM500 version used (if any)
  delete $self->{tm500_version};

  my @logLines	= $self->getLogFile;
  my @lines	= grep (/^Command:.*version/, @logLines);

  if ($lines[0] && $lines[0] =~ /\-\-version\s+(.+)/) {
    $self->{tm500_version} = $1;
  } # if

  @lines = grep (/^Simulator version is/, @logLines);

  if ($lines[0] && $lines[0] =~ /Simulator version is\s+(.+)\./) {
    $self->{nms_version} = $1;
  } # if

  return ($status, $testResult);
} # exec

############################################################################
#
# disconnect:	Disconnects from East simulator
#
# Parms:	none
#
# Returns:	nothing
#
############################################################################
sub disconnect {
  my ($self) = @_;

  if ($self->{rantvl}) {
    # Send Control-C to terminate any processes running
    $self->{rantvl}->send ("\cC");

    # Try to exit remote command
    $self->{rantvl}->send ("exit\n");

    # Try a hard close
    $self->{rantvl}->hard_close;

    # Let's remember that we were connected so we know in
    # collectLogFiles that we need to collect the rantvl log files.
    $self->{collectRantvl} = 1;

    # Call destructor on Expect process
    undef $self->{rantvl};
  } # if

  if ($self->{remote}) {
    # Send Control-C to terminate any processes running
    $self->{remote}->send ("\cC");

    # Try to exit remote command
    $self->{remote}->send ("exit\n");

    # Try a hard close
    $self->{remote}->hard_close;

    # Call destructor on Expect process
    undef $self->{remote};
  } # if
} # disconnect

############################################################################
#
# getCollectLogFiles:	Gets CollectLogFiles
#
# Parms:		None
#
# Returns:		collectLogFiles setting
#
############################################################################
sub getCollectLogFiles () {
  my ($self) = @_;

  return $self->{collectLogFiles};
} # getCollectLogFiles

############################################################################
#
# setCollectLogFiles:	Sets CollectLogFiles to notate that we need to
#			collect log files
#
# Parms:		
#   collectLogFiles:	Boolean indictating where or not to collect log 
#			files
#
# Returns:		
#   Old collectLogFiles setting
#
############################################################################
sub setCollectLogFiles ($) {
  my ($self, $collectLogFiles) = @_;

  my $old = $self->{collectLogFiles};

  $self->{collectLogFiles} = $collectLogFiles;

  return $old;
} # setCollectLogFiles

############################################################################
#
# setRantvlStartTime:	Sets rantvlStartTime to notate that we need to
#			collect alarms
#
# Parms:		
#   startTime:		Start time (from time())
#
# Returns:		
#   Nothing
#
############################################################################
sub setRantvlStartTime ($) {
  my ($self, $startTime) = @_;

  $self->{rantvlStartTime} = $startTime;
} # setRantvlStartTime

############################################################################
#
# setTestCaseID:	Sets TestCaseID for later use by collectLogFiles
#
# Parms:		TestCaseID
#
# Returns:		Nothing
#
############################################################################
sub setTestCaseID ($) {
  my ($self, $testCaseID) = @_;

  $self->{testCaseID} = $testCaseID;
} # setTestCaseID

############################################################################
#
# setSaveTo:	Sets saveTo for later use by collectLogFiles
#
# Parms:	
#   path:	Path to save things to
#
# Returns:	Nothing
#
############################################################################
sub setSaveTo ($) {
  my ($self, $saveTo) = @_;

  $self->{saveTo} = $saveTo;
} # setSaveTo

############################################################################
#
# getSaveTo:	Gets saveTo
#
# Parms:	None
#
# Returns:	saveTo path
#
############################################################################
sub getSaveTo ($) {
  my ($self) = @_;

  return $self->{saveTo};
} # getSaveTo

############################################################################
#
# getTimeout:	Returns the timeout value for the remote execution object
#		(if connected)
#
# Parms:	none
#
# Returns:	Timeout value for remote execution object, if connected, or
#		undefined.
#
############################################################################
sub getTimeout () {
  my ($self) = @_;

  return $self->{remote}->getTimeout if $self->{remote}
} # getTimeout

############################################################################
#
# setTimeout:	Sets timeout value for remote execution object for all
#		subsequent exec's.
#
# Parms:
#   timeout:	new timeout value
#
# Returns:	Old timeout value (if previously connected)
#
############################################################################
sub setTimeout ($) {
  my ($self, $timeout) = @_;

  return $self->{remote}->setTimeout ($timeout) if $self->{remote};
} # setTimeout

############################################################################
#
# _checkOutElement:	Checks out, or creates initial version of the passed
#			in file into Clearcase
#
# Parms:
#   file:		Name of file to checkout (mkelem)
#
# Returns:		0 if successful - non-zero if unsuccessful
#
############################################################################
sub _checkOutElement ($;$) {
  my ($file, $eltype) = @_;

  my $parentDir = dirname $file;

  my ($status, @lines);

  # If the file already exists attempt to check it out
  if (-f $file) {
    # Assuming a snapshot view so run update
    ($status, @lines) = Execute CLEARTOOL . " update -log /dev/null $file 2>&1";

    $status >>= 8;

    error ("Unable to update view (Errno: $status)\n" . join ("\n", @lines), 1)
      unless $status == 0;

    $status >>= 8;

    ($status, @lines) = Execute CLEARTOOL . " checkout -nc $file 2>&1";

    $status >>= 8;

    error ("Unable to checkout $file (Errno: $status)\n" . join ("\n", @lines), 1)
      unless $status == 0;
  } else {
    ($status, @lines) = Execute CLEARTOOL . " checkout -nc $parentDir 2>&1";

    $status >>= 8;

    error ("Unable to checkout parent directory $parentDir (Errno: $status)\n" . join ("\n", @lines), 1)
      unless $status == 0;

    # set eltype if passed
    my $eltypeParm = $eltype ? "-eltype $eltype" : "";
    
    # create the new element
    ($status, @lines) = Execute CLEARTOOL . " mkelem $eltypeParm -nc $file 2>&1";

    $status >>= 8;

    error ("Unable to mkelem $file (Errno: $status)\n" . join ("\n", @lines), 1)
      unless $status == 0;

    # Check in parent directory so we don't have to worry about it later
    ($status, @lines) = Execute CLEARTOOL . " checkin -nc $parentDir 2>&1";

    $status >>= 8;

    error ("Unable to checkin parent directory $parentDir (Errno: $status)\n" . join ("\n", @lines), 1)
      unless $status == 0;
  } # if

  return $status;
} # _checkOutElement

############################################################################
#
# _checkInElement:	Checks in the passed in file into Clearcase
#
# Parms:
#   file:		Name of file to checkin
#
# Returns:		0 if successful - 1 if unsuccessful
#
############################################################################
sub _checkInElement ($) {
  my ($element) = @_;

  my ($status, @lines) = Execute CLEARTOOL . " checkin -nc $element 2>&1";

  $status >>= 8;

  error ("Unable to checkin $element (Errno: $status)\n" . join ("\n", @lines), 1)
    unless $status == 0;
} # _checkInElement

############################################################################
#
# _mkDirElement:	Creates a directory element in Clearcase
#
# Parms:
#   dir:		Name of the directory to mkelem
#
# Returns:		0 if successful - 1 if unsuccessful
#
############################################################################
sub _mkDirElement ($) {
  my ($dir) = @_;

  return 0 if -d $dir;

  my $parentDir = dirname $dir;

  my ($status, @lines) = Execute CLEARTOOL . " checkout -nc $parentDir 2>&1";

  $status >>= 8;

  error ("Unable to checkout parent directory $parentDir (Errno: $status)\n" . join ("\n", @lines), 1)
    unless $status == 0;

  eval { mkpath $dir };

  error "Unable to mkpath $dir\n$@", 1 if $@;

  ($status, @lines) = Execute CLEARTOOL . " mkelem -nc -nco $dir 2>&1";

  $status >>= 8;

  error ("Unable to mkdir $dir (Errno: $status)\n" . join ("\n", @lines), 1)
    unless $status == 0;

  return _checkInElement $parentDir;
} # _mkDirElement

############################################################################
#
# _makeTar:	Creates a tarfile
#
# Parms:
#   file:	Name of tarfile to create
#   path:	Path to use in the tarfile
#   files:	Files to tar up
#
# Returns:	0 if successful - 1 if unsuccessful
#
############################################################################
sub _makeTar ($;$$) {
  my ($file, $path, $files) = @_;

  $path = "." unless $path;

  eval { mkpath $path };

  error "Unable to mkpath $path\n$@", 1 if $@;

  my ($status, @lines) = Execute "tar -czf $file -C $path $files";

  $status >>= 8;

  error ("Unable to create tarfile $file (Errno: $status)\n" . join ("\n", @lines), 1)
    unless $status == 0
} # _makeTar

############################################################################
#
# makeBaselinesReadme	Creates a baselines.readme file
#
# Parms:
#   file:		Name of file to create
#
# Returns:		0 if successful - 1 if unsuccessful
#
############################################################################
sub makeBaselinesReadme ($) {
  my ($self, $file) = @_;

  open FILE, ">$file"
    or error "Unable to open $file - $!", return 1;

  my ($status, @lines) = Execute CLEARTOOL . " lsstream -fmt \"\%[found_bls]p\" -view $self->{view}";

  $status >>= 8;

  error ("Unable to get baselines (Errno: $status)\n" . join ("\n", @lines), 1)
    unless $status == 0;

  print FILE "$_\n" foreach (split (" ", $lines[0]));

  close FILE;

  return 0;
} # makeBaselinesReadme

############################################################################
#
# fixUpLogs:	Fix up RNC log files (hotfix)
#
# Parms:	none
#
# Returns:	0 if successful - 1 if unsuccessful
#
############################################################################
sub fixUpLogs () {
  my ($self) = @_;

  my ($status, @lines);

  # Copy over the necessary log files
  my $file	= $self->{unitType} eq "rbs"
		? "rnc_aal5.log"
		: "nodeb_aal5_utran.log";
  my $from	= LOGBASE . "/$self->{saveTo}/EASTLogs/Server_Logs/$file";
  my $to	= "/tmp/$file.$$";
  my $eastfile	= $to;

  unless (-f $from) {
    error "Unable to find $file file";
    return 1;
  } # unless

  my $cmd = "scp -q $from " . RANUSER . "\@" . RANHOST . ":$to";

  ($status, @lines) = Execute $cmd;

  $status >>= 8;

  if ($status != 0) {
    error ("Unable to execute command: $cmd\n" . join ("\n", @lines));
    return $status;
  } # if

  my $rnclog = "RNCLog.txt";

  $file = $self->{unitType} eq "rbs"
	? "RBSLog.txt"
	: "RNCLog.txt";
  $from = LOGBASE . "/$self->{saveTo}/Rantvl/$file";
  $to	= "/tmp/$file.$$";

  my $logfile = $to;

  unless (-f $from) {
    error "Unable to find $file file";
    return 1;
  } # unless

  $cmd = "scp -q $from " . RANUSER . "\@" . RANHOST . ":$to";

  ($status, @lines) = Execute $cmd;

  $status >>= 8;

  if ($status != 0) {
    error ("Unable to execute command: $cmd\n" . join ("\n", @lines));
    return $status;
  } # if

  $status = rename $from, "$from.orig";

  unless ($status) {
    error "Unable to rename $from -> $from.orig";
    return 1;
  } # unless

  (my $buildNbr) = $self->{ran_version} =~ /.*-(.*)/;

  $cmd  = "/prj/muosran/SWIT/tools/bin/mergeEAST2RNC.pl ";
  $cmd .= "-log $logfile -east $eastfile -out $logfile.tmp -build $buildNbr";

  @lines = $self->{msh}->exec ($cmd);
  $status = $self->{msh}->status;

  if ($status != 0) {
    error ("Unable to execute command: $cmd\n" . join ("\n", @lines));
    return $status;
  } # if

  $cmd = "scp -q " . RANUSER . "\@" . RANHOST . ":$logfile.tmp $from";

  ($status, @lines) = Execute $cmd;

  $status >>= 8;

  if ($status != 0) {
    error ("Unable to execute command: $cmd\n" . join ("\n", @lines));
    return $status;
  } # if

  $cmd = "rm -f $eastfile $logfile $logfile.tmp";

  ($status, @lines) = $self->{msh}->exec ($cmd);
  $status = $self->{msh}->status;

  if ($status != 0) {
    error ("Unable to execute command: $cmd\n" . join ("\n", @lines));
  } # if

  return $status;
} # fixUpLogs

############################################################################
#
# collectExtendedLogfiles:	Scours an East logfile for extended logfiles
#				to collect. Extended logfiles are marked in
#				the East logfile.
#
# Collection of TM500, NMS and CDR extended logfiles:
#
# Look for other logs. Other logs are logs like those produced by TM500 and
# NMS and CDR. They are noted in the main log file in the format of:
#
#	[LOG]
#	<type> <IP Address> <Logfile>
#	<type> <IP Address> <Logfile>
#	...
#	[/LOG]
#
# Where:
#
#	<type>:		TM500|NMS|CDR
#	<IP Address>	IP address of the machine (why they don't use names...)
#	<Logfile>	Windows path like:
#
#			C:\TM500\TestLogs\MDL.cmd.2008.04.02-10.24.27.log
#
# We need to take the above and formulate an scp command like:
#
#	scp -q pswit@<IP Address>:<Logfile> TM500Logs
#
# Note that pswit is a generic user and we have previously configured
# pre-shared ssh access for all users to pswit@<rantm501-rantm507> and
# <Logfile> has been transformed from "\"'s -> "/"'s because "/"'s also work
# and work better!
#
# Parms:		none
#
# Returns:		0 if successful - 1 if unsuccessful
#
############################################################################
sub collectExtendedLogFiles () {
  my ($self) = @_;

  # Create @tarfiles if it doesn't already exist
  unless ($self->{tarfiles}) {
    $self->{tarfiles} = ();
  } # unless

  my $logpath	= LOGBASE . "/$self->{saveTo}";
  my $tm500dir	= "$logpath/TM500Logs";
  my $nmsdir	= "$logpath/NMSLogs";
  my $cdrdir	= "$logpath/CDRLogs";

  my @logLines = $self->getLogFile;

  my $tm500Found	= 0;
  my $nmsFound		= 0;
  my $cdrFound		= 0;
  my $hitlog		= 0;

  foreach (@logLines) {
    chomp;

    if (/^\[LOG\]/) {
      $hitlog = 1;
      next;
    } elsif (/^\[\/LOG\]/) {
      $hitlog = 0;
    } else {
      if ($hitlog == 1 and /(\S+)\s+(\S+)\s+(\S+)/) {
	my ($type, $dir, $ip, $logfile);

	if ($1 eq "TM500") {
	  $tm500Found	= 1;
	  $dir		= $tm500dir;
	} elsif ($1 eq "NMS") {
	  $nmsFound	= 1;
	  $dir		= $nmsdir;
	} elsif ($1 eq "CDR") {
	  $cdrFound	= 1;
	  $dir		= $cdrdir;
	} # if

	$type		= $1;
	$ip		= $2;
	$logfile	= $3;
	$logfile	=~ s/\\/\//g;

	unless (-d $dir) {
	  eval { mkpath $dir };

	  error "Unable to mkpath $dir\n$@", 1 if $@;
	} # unless

	# scp is failing for some strange reason for NMS. The
	# following code is to try to help figure out what's going on
	# when scp fails.

	# Only do this for NMS
	if ($type eq "NMS") {
	  # Does the $logfile exist to start with?
	  my $cmd = "ssh pswit\@$ip ls $logfile";

	  my ($status, @lines) = Execute $cmd;

	  $status >>= 8;

	  LogDebug "WARNING: From file, $logfile, does not exist on $ip" if $status != 0;
	} # if

	my $cmd = "scp -q pswit\@$ip:$logfile $dir";

	my ($status, @lines) = Execute $cmd;

	$status >>= 8;

	if ($type eq "NMS") {
	  if ($status != 0) {
	    LogDebug "Unable to execute $cmd";
	    LogDebug "Lines contains:";
	    LogDebug $_ foreach (@lines);

	    my $i = 0;

	    do {
	      sleep 1;

	      ($status, @lines) = Execute $cmd;

	      $status >>= 8;
	      $i++;
	    } until ($status == 0 or $i >= 2);
	  } # if
	} # if

	error ("Unable to scp logfile $logfile (Errno: $status)\n$cmd\n" . join ("\n", @lines))
	  unless $status == 0;
      } # if
    } # if
  } # foreach

  if ($tm500Found) {
    push @{$self->{tarfiles}}, {
      type	=> "TM500",
      tarfile	=> "TM500Logs.tgz",
      path	=> $tm500dir,
      files	=> ".",
    };
  } # if

  if ($nmsFound) {
    push @{$self->{tarfiles}}, {
      type	=> "NMS",
      tarfile	=> "NMSLogs.tgz",
      path     	=> $nmsdir,
      files	=> ".",
    };
  } # if

  if ($cdrFound) {
    push @{$self->{tarfiles}}, {
      type	=> "CDR",
      tarfile	=> "CDRLogs.tgz",
      path     	=> $cdrdir,
      files	=> ".",
    };
  } # if
} # collectExtendedLogFiles

############################################################################
#
# createPCScannerLogs:	Creates PC Scanner logs  using msh
#
# Parms:		none
#
# Returns:		0 if successful - 1 if unsuccessful
#
############################################################################
sub createPCScannerLogs ($) {
  my ($self, $node) = @_;

  my ($status, @lines);

  # Determine how long this test was running
  my $duration	= time - $self->{rantvlStartTime};

  # Kind of an odd algorithim: Compute to the nearest 1/4 hour
  my $hours	= int ($duration / (60 * 60));
  my $fractions	= int (($duration % (60 * 60)) / 60);

  if ($fractions < 15) {
    $fractions = 25;
  } elsif ($fractions < 30) {
    $fractions = 5;
  } elsif ($fractions < 45) {
    $fractions = 75
  } else {
    $fractions = 0;
    $hours++;
  } # if

  my $prompt	= uc $node . '.*>';
  my $timeout	= 30;
  my $noFiles	= 0;

  verbose_nolf "Collecting PC Scanner logs from the last $hours.$fractions hours...";

  my $cmd = "ssh -t " . RANUSER . "@" . RANHOST. " /prj/muosran/SWIT/moshell/moshell $node";
  my $msh = new Expect ($cmd);

  error "Unable to start msh", 1 unless $msh;

  $msh->log_user (get_debug);

  $msh->expect (
    $timeout,

    [ qr "$prompt",
      sub {
	debug "Hit prompt!";
      }
    ],

    [ timeout =>
      sub {
	error "Timed out looking for moshell prompt", 1;
      }
    ],
  );

  $cmd = "pmr -m $hours.$fractions";

  $msh->send ("$cmd\n");

  $msh->expect (
    $timeout,

    [ qr "Your Choice: " ],

    [ qr "No xml files to parse !",
      sub {
	$noFiles = 1;
      }
    ],

    [ timeout =>
      sub {
	error "Timed out looking for \"Your Choice:\"", 1;
      }
    ],
  );

  if ($noFiles) {
    verbose " No logs to process - skipping";
    return -1;
  } # if

  $cmd = "x";

  $msh->send ("$cmd\n");

  $msh->expect (
    $timeout,

    [ qr "$prompt" ],

    [ timeout =>
      sub {
	error "Timed out looking for moshell prompt", 1;
      }
    ],
  );

  my $proxy_id;

  $cmd = "pst";

  $msh->send ("$cmd\n");

  $msh->expect (
    $timeout,

    [ qr "$prompt",
      sub {
	my $exp = shift;

	my $before = $exp->before;

	if ($before =~ /(\d+).*RNCScanner/) {
	  $proxy_id = $1;
	} # if
      }
    ],

    [ timeout =>
      sub {
	error "Timed out looking for moshell prompt", 1;
      }
    ],
  );

  unless ($proxy_id) {
    error "Unable to find proxy_id";
    return 1;
  } # unless

  $cmd = "pbl $proxy_id";

  $msh->send ("$cmd\n");

  $msh->expect (
    $timeout,

    [ qr "$prompt" ],

    [ timeout =>
      sub {
	error "Timed out looking for moshell prompt", 1;
      }
    ],
  );

  return 0;
} # createPCScannerLogs

############################################################################
#
# collectRanTVLLogs:	Collect rantvl logs
#
# Parms:		$logPath: Path to logfiles
#
# Returns:		0 if successful - 1 if unsuccessful
#
############################################################################
sub collectRanTVLLogs ($) {
  my ($self, $logpath) = @_;

  return unless ($self->{collectRantvl});

  my ($status, @lines);

  # SIMCQ00007155: We now have unitNbr's like '3m2' which are really
  # the same machine as as ranrnc03. While ranrnc03m2 is DNS aliased
  # to ranrnc03, it causes problems because we assume that that will
  # be the prompt for moshell (see createPCScannerLogs). The following
  # substr uses only the first character of unitNbr which makes the
  # assumption that unitNbr 3 (ranrnc03) is the same machine as
  # unitNbr 3m2 (ranrnc03m2).
  my $DUTHost	= "ran" . $self->{unitType} . "0" . substr ($self->{unitNbr}, 0, 1);

  if ($self->{unitType} eq "rnc") {
    # Create PC Scanner logs
    $status = $self->createPCScannerLogs ($DUTHost);

    unless ($status == 0) {
      warning "Unable to create PCScannerLogs" if $status > 0;
    } else {
      verbose " done";

      # Move files to testlogs
      my $from	= "~" . RANUSER . "/moshell_logfiles/logs_moshell/pmfiles/$DUTHost.gddsi.com/pm";
      my $to	= "$logpath/PCScannerLogs";

      # Create the remote directory
      my $cmd = "mkdir -p $to; chmod g+w $to";

      ($status, @lines) = Execute ($cmd);

      $status >>= 8;

      error ("Unable to execute $cmd\n" . join ("\n", @lines), 1)
	if $status != 0;

      # Copy files
      $cmd = "scp -qrp " . RANUSER . "@" . RANHOST . ":$from/* $to";

      ($status, @lines) = Execute $cmd;

      $status >>= 8;

      error ("Unable to execute $cmd\n" . join ("\n", @lines), 1)
	if $status != 0;

      $status = $self->{msh}->exec ("rm -rf $from/*");
      @lines  = $self->{msh}->lines;

      error ("Unable to execute $cmd\n" . join ("\n", @lines), 1)
	if $status != 0;

      push @{$self->{tarfiles}}, {
	type		=> "PCScanner",
	tarfile		=> "PCScannerLogs.tgz",
	path		=> $to,
	files		=> ".",
      };
    } # if
  } # if

  my $from	= RANTVL_LOGBASE . "/$self->{saveTo}";
  my $to	= "$logpath/Rantvl";

  eval { mkpath $to };

  error "Unable to mkpath $to\n$@", 1 if $@;

  # Get any alarms
  if ($self->{rantvlStartTime}) {
    use POSIX qw (ceil);

    my $minutes	= ceil ((time - $self->{rantvlStartTime}) / 60);
    my $DUTHost	= "ran" . $self->{unitType} . "0" . $self->{unitNbr};
    my $logfile	= $to . (($self->{unitType} eq "rnc") ? "/RNCAlarms.txt" : "/RBSAlarms.txt");
    my $cmd	= "domsh -v -q -h $DUTHost -m \"lgar ${minutes}m\" > $logfile";

    my ($status, @lines) = Execute $cmd;

    $status >>= 8;

    error ("Unable to execute $cmd\n" . join "\n", @lines) if $status != 0;
  } # if

  # Copy files
  my $cmd = "scp -rpq " . RANUSER . "\@" . RANHOST . ":$from/* $to";

  ($status, @lines) = Execute $cmd;

  $status >>= 8;

  return $status if $status;

  verbose_nolf ".";

  # Removed copies
  $cmd = "ssh " . RANUSER . "\@" . RANHOST . " rm -rf $from";

  ($status, @lines) = Execute $cmd;

  $status >>= 8;

  return $status if $status;

  verbose_nolf ".";

  push @{$self->{tarfiles}}, {
    type		=> "RANTVL",
    tarfile		=> "RANTVLLogs.tgz",
    path		=> $to,
    files		=> ".",
  };

  return 0;
} # collectRanTVLLogs

############################################################################
#
# collectLogfiles:	Saves the logfiles for an EAST test run
#
# Parms:		none
#
# Returns:		0 if successful - 1 if unsuccessful
#
############################################################################
sub collectLogFiles (;$$) {
  my ($self, $testErrors, $checkin_on_error) = @_;

  return 0 unless $self->{collectLogFiles};

  $testErrors       ||= 0;
  $checkin_on_error ||= 1;

  $self->{saveTo} = "." unless $self->{saveTo};

  my $viewPath = "$ENV{MNT_DIR}/snapshot_views/$self->{userdir}/$self->{view}";

  # Copy relevant logs from
  my $eastLogBase = "$ENV{MNT_DIR}/$ENV{EAST_REL}/DUT/$self->{unitType}$self->{unitNbr}/data/logs";

  # To here
  my $logpath = LOGBASE . "/$self->{saveTo}";

  verbose "logpath=$logpath";

  eval { mkpath "$logpath/EASTLogs" };

  error "Unable to mkpath $logpath/EASTLogs\n$@", 1 if $@;

  verbose "Collecting logfiles";

  foreach ("Server_Logs", "regression", "load") {
    next unless -e "$eastLogBase/$_";

    my $cmd = "cp -rp $eastLogBase/$_ $logpath/EASTLogs";

    my ($status, @lines) = Execute $cmd;

    $status >>= 8;

    error "Unable to copy $eastLogBase/$_ -> $logpath/EASTLogs", 1 if $status != 0;
  } # foreach

  # We always save EAST logs
  push @{$self->{tarfiles}}, {
    type	=> "EAST",
    tarfile	=> "EASTLogs.tgz",
    path	=> "$logpath/EASTLogs",
    files	=> ".",
  };

  my $status = $self->collectRanTVLLogs ($logpath);

  return $status if $status;

  verbose "All logfiles collected";

  # Report logfiles created
  if (get_verbose) {
    display "Logfiles created this run:";

    my $cmd = "find " . LOGBASE . "/$self->{saveTo}";

    print $_ foreach (`$cmd`);
  } # if

  $self->fixUpLogs if $self->{collectRantvl};

  # If we are "run for record" then $self->{testCaseID} should be
  # set. If not then we're all done and can return.
  unless ($self->{testCaseID}) {
    $self->{collectLogFiles} = 0;

    return 0;
  } # unless

  # if $checkin_on_error is not defined set it to false
  if ( !defined $checkin_on_error) {
    $checkin_on_error = "0";
  } # if

  # check with user to see if they want to check in logs if errors were encountered
  if ( ( $testErrors > 0 ) && ( $checkin_on_error == 0 ) ) {
    display_nolf "Errors encountered. Do you still want to check in the log files? (y/n) ";
      
    my $response = <STDIN>;

    return 1 unless $response =~ /y/i;
  } # if

  verbose_nolf "Checking in tar files for run for record"
    if scalar @{$self->{tarfiles}} > 0;

  foreach (@{$self->{tarfiles}}) {
    my $to = "$viewPath/vobs";

    if ($$_{type} eq "EAST") {
      $to .= "/simdev_log";
    } elsif ($$_{type} eq "TM500") {
      $to .= "/tm500_log";
    } elsif ($$_{type} eq "RANTVL" or $$_{type} eq "CDR" or $$_{type} eq "PCScanner") {
      $to .= "/rantest_build3_log";
    } elsif ($$_{type} eq "NMS") {
      $to .= "/nms_sim_log";
    } else {
      error "Unknown tarfile type: $$_{type}";
      next;
    } # if

    $to .= "/$self->{testCaseID}";

    # Create testcaseID directory if necessary
    _mkDirElement $to;

    # Will create element if necessary
    _checkOutElement "$to/$$_{tarfile}";

    # Remove either old tarfile or empty container. We're about to fill it.
    my ($status, @lines) = Execute "rm -f $to/$$_{tarfile}";

    $status >>= 8;

    error "Unable to remove old tarfile", 1
      unless $status == 0;

    _makeTar "$to/$$_{tarfile}", $$_{path}, $$_{files};

    # Check in the element
    _checkInElement "$to/$$_{tarfile}";

    verbose_nolf ".";
  } # foreach

  verbose " done"
    if scalar @{$self->{tarfiles}} > 0;

  verbose_nolf "Capturing baselines.";

  # We put baselines into here
  my $to = "$viewPath/vobs/rantest_build3_log/$self->{testCaseID}/baselines.readme";

  _checkOutElement $to;

  # Remove either old file or empty container. We're about to fill it.
  my @lines;

  ($status, @lines) = Execute "rm -f $to";

  $status >>= 8;

  error "Unable to remove baseline.readme", 1
    unless $status == 0;

  $self->makeBaselinesReadme ($to);

  # Check in the element
  _checkInElement $to;

  verbose " done";

  $self->{collectLogFiles} = 0;

  return 0;
} # collectLogFiles

1;

=head1 NAME

Nethawk::East - East Object Model module

=head1 VERSION

Version 1.0 - January 17, 2008

=head1 DESCRIPTION

Encapsulates the East Simulator as an object. Methods are provided to
connect, configure and run tests on an East Simulator.

=head1 SYNOPSIS

use Nethawk::East;

$e = new Nethawk::East;

=head1 METHODS

=head2 new (<parms>)

Construct a new East object. The following OO style arguments are
supported:

Parameters:

=over

=item host:

Name of host to connect through. Default: raneast

=item username:

Username to connect as. Default $USER

=item password:

Password to use. Default passwordless.

=item debug:

If set then the East object will emit debugging information

=back

=head2 validTestType (type)

Return a status indicating if the passed in test type is valid (and an
error message if not)

=over

=item testType

Type of test requested

=item Returns

List contains a status (0 = valid test type, 1 = invalid test type)
and an optional error message.

=back

=head2 inUse ()

Determines if the unit of type type is in use.

=over

=item Returns undef if not in use or an error message if in use

=back

=head2 viewExists (view)

Determines if the view exists on the remote host

=over

=item view

View tag to check

=item Returns

1 if view exists - 0 otherwise

=back

=head2 testExists (type, name)

Determines if the named test exists for that test type

=over

=item type

Specifies what type of test to check

=item name

Specifies the name of the test

=item Returns 1 if test exists - 0 otherwise

=back

=head2 getLogFile ()

Returns the log in an array

=over

=item None

=item Returns

An array of lines from the log file. Note that although EAST logfiles
are binary, this method first passes the file through strings(1).

=back

=head2 testResult (name)

Checks the test's logfile to determine the result

Parameters:

=over

=item name

Name of test

=item Returns

A status - 0 if we are able to get the results, 1 if we can't - and a
message of "Success", "Failure", "Incomplete" or an error message

=back

=head2 shell (script, opts)

Execute a shell script returning the results.

Parameters:

=over

=item script

Script to run

=item opts

Additional options passed to script

=item Returns

$status of shell exeuction and @lines of output

=back

=head2 rantvl (cmd)

Start rantvl

Parameters:

=over

=item cmd

Rantvl command to execute

=item Returns

$pid of rantvl process and a message

=back

=head2 rendezvous (phrase, timeout)

Rendezvous with EAST process by searching the log file for a specific
phrase. We will use $self->{timeout} to determine how long we are
gonna wait for this phrase to appear. We will divide $self->{timeout}
by 10, making 10 attempts. So with a default timeout of 180 seconds,
we will try 10 times 18 seconds apart, for the phrase to appear before
timing out.

Parameters:

=over

=item phrase

Phrase to search for

=item timeout

How long to time out waiting for the rendezvous

=item Returns

undef if rendezvous was successful - error message otherwise.

=back

=head2 connected ()

Checks to see if you're connected to EAST

Parameters:

=item None

=item Returns

undef if connected - error message otherwise

=back

=head2 connect (view, unitType, unitNbr, tm500, nms)

Connects to the remote East machine

Parameters:

=over

=item view

View name to set to to run the the test

=item unitType

Type of unit (rbs, rnc or east)

=item unitNbr

Number of the unit

=item tm500

Name of tm500 view (if any)

=item nms

Name of nms view (if any)

=item Returns

Undefined if connection was successful or error message if not

=back

=head2 exec (class, name, timeout)

Parameters:

=over

=item class

Specifies which class of test. Must be one of:

 load	LoadTCRunner
 pool	RegressionLoadRunner
 tc	RegressionRunner
 ts 	RegressionTSRunner

=item name

Name of the test. Currently this is the filename for the test.

=item timeout

(Optional) Timeout value for this command

=item returns status of remotely executed test.

=back

=head2 disconnect ()

Parameters:

=over

=item none

=back

=head2 setCollectLogFiles (collectLogFiles)

Sets CollectLogFiles to notate that we need to collect log files

Parameters:		

=over

=item collectLogFiles

Boolean indictating where or not to collect log files

=item Returns

Old collectLogFiles setting

=back

=head setTestCaseID

Sets TestCaseID for later use by collectLogFiles

Parameters:

=over

=item TestCaseID

=item Returns

Nothing

=back

=head2 setSaveTo (path)

Sets saveTo for later use by collectLogFiles

Parameters:

=over

=item path

Path to save things to

=item Returns

Nothing

=back

=head2 getSaveTo ()

Gets saveTo

Parameters:

=over

=item None

=item Returns

saveTo path

=back

=head2 getTimeout ()

Returns the timeout value for the remote execution object (if
connected)

Parameters

=over

=item None

= item Returns

Timeout value for remote execution object, if connected, or undefined.

=head2 collectLogFiles ()

Saves the logfiles for an EAST test run

Parameters:

=over

=item None

=item Returns

0 if successful - 1 if unsuccessful

=back

=head2 setTimeout (timeout)

Sets timeout value for remote execution object for all subsequent
exec's.

Parameters:

=over

=item timeout

New timeout value

=item Returns

Old timeout value (if previously connected)

=head1 ALSO SEE

None.

=head1 KNOWN DEFECTS

None.

=head1 TODO

=over 4

=item ...

=back

=head1 DEVELOPERS

=over 4

=item Andrew@DeFaria.com (Original Author)

=item Gantry York, gantry.york@gdc4s.com (Maintainer)

=back

=head1 LICENSE & COPYRIGHT

Copyright (c) 2008 General Dynamics, Inc.  All Rights Reserved.
