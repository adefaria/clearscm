#!/usr/bin/env /opt/rational/clearquest/bin/cqperl
##############################################################################
#
# Name: cqtool
#
# Description:	cqtool is an interface to Clearquest to perform some simple
#		actions to the RANCQ database. It is used primarily by ucmwb
#		but it also supports a command line interface.
#
#		The following commands are supported:
#
#		activate <wor> <project> <est_hours> <startdate> <enddate>:
#			Activate WOR
#		assign <wor> <assignee> <project> <planned_hours> <startdate>:
#			Assign the WOR
#		clone <wor>:
#			Clones a WOR
#		comment <wor> <comment>
#			Add a comment to the Notes_Entry field for the WOR
#		complete <wor> <actual_hours>:
#			Complete WOR
#		createhd:
#			Create a new Help Desk Ticket
#		createwor:
#			Create a new WOR
#		effort <wor> <hours>:
#			Update the WOR's actual hours
#		exit|quit:
#			Exits cqtool
#		help:
#			This display
#		link <parent wor> <child wor>:
#			Link a parent WOR to a child WOR
#		resolve <wor>:
#			Resolve WOR
#		set <wor> <field> <value>
#			Set <field> to <value> for the <wor>
#		usage:
#			Displays command line usage
#		version:
#			Displays version of cqtool
#
#		Many of these commands simply perform actions on a wor. Two
#		of these commands, createwor and createhd have Perl/Tk GUI
#		interfaces.
#
# Command line usage:
#
# Usage: cqtool\t[-usage|help] [-verbose] [-debug]
#	[-userid <user>] [-password <password>] [<command>]
#
# Where:
#
#   -usage|help:	Display usage
#   -verbose:		Turn on verbose mode
#   -debug:		Turn on debug mode
#   -userid:		User ID to log into Clearquest database as
#   -password:		Password to use
#   <command>		If specified then cqtool executes <command> and
#			exits
#
# Environment:		cqtool supports the following environment variables
#			that are used mostly for tesing purposes
#
#	CQ_DBSET:	Clearquest DBSET to open (e.g. XTST3 for testing -
#			default RANCQ)	
#	CQ_USER:	User name to log into the $CQ_DBSET database with
#	CQ_PASSWORD:	Password to use to log into the $CQ_DBSET with.
#
# Author: Andrew@DeFaria.com
#
# (c) Copyright 2007, General Dynamics, all rights reserved
#
##############################################################################
use strict;
use warnings;

use CQPerlExt;
use FindBin;
use Getopt::Long;
use Term::ANSIColor qw (:constants);

use lib ("$FindBin::Bin", "$FindBin::Bin/../lib");

use SCCM::Misc;
use Display;
use CQTool;
use CreateWORUI;
use CreateHelpDeskUI;
use Logger;

my $VERSION		= BOLD GREEN . "1.1" . RESET;
my $PROMPT		= BOLD YELLOW . ">>" . RESET;
my $UCMWB_PROMPT	= ">>";
my $DESC		= BOLD RED . "$FindBin::Script" .
			  RESET      " Version " .
	                  $VERSION .
			  CYAN ": Program to talk to Clearquest" .
			  RESET;

# Globals
my $_userid	= $ENV{CQ_USER}  ? $ENV{CQ_USER} : $ENV{USER};
my $_password	= $ENV{CQ_PASSWORD};
my $_db_name	= $ENV{CQ_DBSET} ? $ENV{CQ_DBSET} : "RANCQ";
my $_ucmwb;

my $_log;

if (get_debug) {
  $_log = new Logger (
    path => "/tmp",
    append => 1,
  );
} # if

my %_commands = (
  activate	=> \&activate,
  assign	=> \&assign,
  clone		=> \&clone,
  comment	=> \&comment,
  complete	=> \&complete,
  createhd	=> \&createHelpDesk,
  createwor	=> \&createWOR,
  effort	=> \&effort,
  exit		=> \&shutdown,
  help		=> \&help,
  link		=> \&linkParentWor2ChildWor,
  quit		=> \&shutdown,
  resolve	=> \&resolve,
  set		=> \&set,
  usage		=> \&usage,
  version	=> \&announce,
);

##############################################################################
# Forwards
##############################################################################
sub commandLoop (@);

##############################################################################
# Main
##############################################################################
MAIN: {
  GetOptions (
    "usage"		=> sub { usage () },
    "verbose"		=> sub { set_verbose () },
    "debug"		=> sub { set_debug () },
    "userid=s"		=> \$_userid,
    "password=s"	=> \$_password,
    "database=s"	=> \$_db_name,
    "ucmwb"		=> \$_ucmwb,
  ) || usage ();

  exit (commandLoop(@ARGV));
} # MAIN

##############################################################################
# Subroutines
##############################################################################

#-----------------------------------------------------------------------------
# shutdown (): Ends program
#-----------------------------------------------------------------------------
sub shutdown () {
  exit (0);
} # exit

#-----------------------------------------------------------------------------
# help (): Displays help
#-----------------------------------------------------------------------------
sub help () {
  display ($DESC);
  display <<END;

Valid commands are:

activate <wor> <project> <est_hours> <startdate> <enddate>:
	Activate WOR
assign <wor> <assignee> <project> <planned_hours> <startdate>:
	Assign the WOR
clone <wor>:
	Clones a WOR
comment <wor> <comment>
	Add a comment to the Notes_Entry field for the WOR
complete <wor> <actual_hours>:
	Complete WOR
createhd:
	Create a new Help Desk Ticket
createwor:
	Create a new WOR
effort <wor> <hours>:
	Update the WOR's actual hours
exit|quit:
	Exits $FindBin::Script
help:
	This display
link <parent wor> <child wor>:
	Link a parent WOR to a child WOR
resolve <wor>:
	Resolve WOR
set <wor> <field> <value>
	Set <field> to <value> for the <wor>
usage:
	Displays command line usage
version:
	Displays version of $FindBin::Script
END
} # help

#-----------------------------------------------------------------------------
# announce (): Announce ourselves
#-----------------------------------------------------------------------------
sub announce () {
  display ($DESC);
} # Announce

#-----------------------------------------------------------------------------
# dberror ($): Handle errors when talking to Clearquest. Note we need to reset
#    	       the database connection if an error happens.
#-----------------------------------------------------------------------------
sub dberror ($) {
  my ($msg) = @_;

  # Need to not only report the error but to reopen the
  # database. Something gets corruppted if we don't!
  error ($msg);

  closeDB ();

  openDB ($_userid, $_password, $_db_name);
} # DBError

#-----------------------------------------------------------------------------
# getEntity ($$): Get an entity from Clearquest
#-----------------------------------------------------------------------------
sub getEntity ($$) {
  my ($recordname, $wor) = @_;

  my $entity;

  eval {
    $entity = $CQTool::session->GetEntity ($recordname, $wor);
  };

  if ($@) {
    chomp $@;
    dberror ($@);
    return undef;
  } else {
    return $entity;
  } # if
} # getEntity

#-----------------------------------------------------------------------------
# set ($$$): Set $field to $value for $wor
#-----------------------------------------------------------------------------
sub set ($$@) {
  my ($wor, $field, $value) = @_;

  if (!$wor or $wor eq "") {
    error ("WOR is required");
    return 1;
  } # if

  if (!$field or $field eq "") {
    error ("Field is required");
    return 1;
  } # if

  my $entity	= getEntity ("WOR", $wor);

  return 1 if !$entity;

  $session->EditEntity ($entity, "modify");

  $_log->msg ("Modifying $field to \"$value\"") if get_debug;
  eval {
    $entity->SetFieldValue ($field, $value);
  };

  if ($@) {
    dberror ("$field set failed for WOR $wor:\n$@");
    return 2;
  } # if

  my $status = $entity->Validate ();

  if ($status ne "") {
    $entity->Revert ();
    error ("$field validate failed for WOR $wor:\n$status");
    return 2;
  } # if

  $status = $entity->Commit ();

  if ($status ne "") {
    error ("$field update failed during Submit for $wor:\n$status");
    return 2;
  } # if

   return 0;
} # set

#-----------------------------------------------------------------------------
# clone ($): Clone a WOR
#-----------------------------------------------------------------------------
sub clone ($) {
  my ($wor) = @_;

  if (!$wor) {
    error ("WOR not specified!");
    return 1;
  } # if

  $entity = getEntity ("WOR", $wor);

  return 1 if !$entity;

  # Check state
  my $state = $entity->GetFieldValue ("state")->GetValue ();

  if ($state ne "Closed") {
    error ("WOR $wor not closed - Unable to clone!");
    return 1;
  } # if

  verbose ("Cloning WOR $wor...");

  my $result = 0;

  eval {
    # Currently Clone doesn't return a proper result but eventually...
    $result = $CQTool::session->FireRecordScriptAlias ($entity, "Clone");
  };

  if ($@) {
    chomp $@;
    dberror ($@);
    return 1;
  } # if

  return $result;
} # clone

#-----------------------------------------------------------------------------
# effort ($$): Update actual hours for a WOR
#-----------------------------------------------------------------------------
sub effort ($$) {
  my ($wor, $actualHrs) = @_;

  return set $wor, "ActualEffort", $actualHrs;
} # effort

#-----------------------------------------------------------------------------
# comment (): Update the Notes_Entry comment field for a WOR
#-----------------------------------------------------------------------------
sub comment ($) {
  my ($wor) = @_;

  if (!$wor) {
    error "WOR not defined in call to comment!";
    return 1;
  } # if

  if (!$_ucmwb) {
    display ("Enter comments below. When finished, enter \".\" on a line by itself or hit ^D:");
  } else {
    # We still need to prompt for the comments however signal UCMWB
    # that command is ready for more input.
    display_nolf ($UCMWB_PROMPT);
  } # if

  my $comments;

  while (<STDIN>) {
    last if $_ eq ".\n";
    $comments .= $_;
  } # while

  chomp $comments;

  $_log->msg ("Comments:\n$comments") if get_debug;

  return set $wor, "Note_Entry", $comments;
} # Comment

#-----------------------------------------------------------------------------
# linkParentWor2ChildWor ($$): Link a child WOR to a parent WOR
#-----------------------------------------------------------------------------
sub linkParentWor2ChildWor ($$) {
  my ($parentWor, $childWor) = @_;

  my $status;

  verbose ("Linking $parentWor -> $childWor...");

  my $childentity	= getEntity ("WOR", $childWor);
  my $parententity	= getEntity ("WOR", $parentWor);

  return 1 unless $childentity and $parententity;

  $session->EditEntity ($parententity, "modify");

  $parententity->AddFieldValue ("wor_children", $childWor);

  $status = $parententity->Validate ();

  if ($status ne "") {
    $parententity->Revert ();
    error ("Validation failed while attempting to add child WOR $childWor to parent WOR $parentWor:\n$status");
    return 1;
  } # if

  eval {
    $status = $parententity->Commit ();
  };

  $status = $@ if $@;

  if ($status ne "") {
    (error "Commit failed while trying to add child WOR $childWor to parent WOR $parentWor:\n$status");
    return 2;
  } # if

  debug "Modifying child $childWor...";
  $session->EditEntity ($childentity, "modify");

  $childentity->SetFieldValue ("wor_parent", $parentWor);

  $status = $childentity->Validate ();

  if ($status ne "") {
    $childentity->Revert ();
    error "Validation failed while attempting to add parent WOR $parentWor to child WOR $childWor:\n$status";
    return 1;
  } # if

  eval {
    $status = $childentity->Commit ();
  };

  $status = $@ if $@;

  if ($status ne "") {
    error "Commit failed while trying to add parent WOR $parentWor to child WOR $childWor:\n$status";
    return 2;
  } # if

  return 0;
} # linkParentWor2ChildWor

#-----------------------------------------------------------------------------
# assign ($$$$): Assign a WOR
#-----------------------------------------------------------------------------
sub assign ($$$$$) {
  my ($wor, $assignee, $project, $plannedHrs, $startDate) = @_;

  if (!$wor or $wor eq "") {
    error ("WOR is required");
    return 1;
  } # if

  if (!$assignee or $assignee eq "") {
    error ("Assignee must be specified");
    return 1;
  } # if

  if (!$project or $project eq "") {
    error ("UCM Project is required");
    return 1;
  } # if

  if (!$startDate or $startDate eq "") {
    error ("Planned Start Date is required");
    return 1;
  } # if

  my $entity	= getEntity ("WOR", $wor);

  return 1 if !$entity;

  my $state	= $entity->GetFieldValue ("state")->GetValue ();

  if ($state ne "Submitted") {
    error ("WOR $wor is not in Submitted state!\nState: $state");
    return 2;
  } # if

  $session->EditEntity ($entity, "assign");

  $entity->SetFieldValue ("ucm_project",	$project)	if $project	ne "";
  $entity->SetFieldValue ("PlannedStart",	$startDate)	if $startDate	ne "";
  $entity->SetFieldValue ("PlannedEffort",	$plannedHrs)	if $plannedHrs	ne "";
  $entity->SetFieldValue ("Owner",		$assignee)	if $assignee	ne "";

  my $status = $entity->Validate ();

  if ($status ne "") {
    $entity->Revert ();
    error ("Assign failed for WOR $wor:\n$status");
    return 2;
  } # if

  $status = $entity->Commit ();

  if ($status ne "") {
    error ("Assign failed during Submit for WOR $wor:\n$status");
    return 2;
  } # if

  return 0;
} # assign

#-----------------------------------------------------------------------------
# activate (): Activate a WOR
#-----------------------------------------------------------------------------
sub activate ($$$$$) {
  my ($wor, $project, $estHrs, $startDate, $endDate) = @_;

  if (!$wor or $wor eq "") {
    error ("WOR is required");
    return 1;
  } # if

  if (!$project or $project eq "") {
    error ("UCM Project is required");
    return 1;
  } # if

  if (!$startDate or $startDate eq "") {
    error ("Planned Start Date is required");
    return 1;
  } # if

  if (!$endDate or $endDate eq "") {
    error ("Planned End Date is required");
    return 1;
  } # if

  my $entity	= getEntity ("WOR", $wor);

  return 1 if !$entity;

  my $state	= $entity->GetFieldValue ("state")->GetValue ();

  if ($state ne "Assessing") {
    error ("WOR $wor is not in Assessing state!\nstate: $state");
    return 2;
  } # if

  $session->EditEntity ($entity, "activate");

  $entity->SetFieldValue ("ucm_project",	$project)	if $project ne "";
  $entity->SetFieldValue ("EstimatedEffort",	$estHrs)	if $estHrs ne "";
  $entity->SetFieldValue ("PlannedStart",	$startDate)	if $startDate ne "";
  $entity->SetFieldValue ("PlannedEnd",		$endDate)	if $endDate ne "";

  my $status = $entity->Validate ();

  if ($status ne "") {
    $entity->Revert ();
    error ("Activate failed for WOR $wor:\n$status");
    return 2;
  } # if

  $status = $entity->Commit ();

  if ($status ne "") {
    error ("Activate failed during Submit for WOR $wor:\n$status");
    return 2;
  } # if

   return 0;
} # activate

#-----------------------------------------------------------------------------
# resolve ($): Resolve a WOR
#-----------------------------------------------------------------------------
sub resolve ($) {
  my ($wor) = @_;

  if (!$wor or $wor eq "") {
    error ("WOR is required");
    return 1;
  } # if

  my $entity	= getEntity ("WOR", $wor);

  return 1 if !$entity;

  my $state	= $entity->GetFieldValue ("state")->GetValue ();

  if ($state ne "Working") {
    error ("WOR $wor is not in Working state!\nState: $state");
    return 2;
  } # if

  $session->EditEntity ($entity, "resolve");

  my $status = $entity->Validate ();

  if ($status ne "") {
    $entity->Revert ();
    error ("Resolve failed for WOR $wor:\n$status");
    return 2;
  } # if

  $status = $entity->Commit ();

  if ($status ne "") {
    error ("Resolve failed during Submit for WOR $wor:\n$status");
    return 2;
  } # if

   return 0;
} # resolve

#-----------------------------------------------------------------------------
# complete ($$): Complete a WOR
#-----------------------------------------------------------------------------
sub complete ($$) {
  my ($wor, $actualHrs) = @_;

  if (!$wor or $wor eq "") {
    error ("WOR is required");
    return 1;
  } # if

  if (!$wor or $wor eq "") {
    error ("Actual Hours are required");
    return 1;
  } # if

  my $entity	= getEntity ("WOR", $wor);

  return 1 if !$entity;

  my $state	= $entity->GetFieldValue ("state")->GetValue ();

  if ($state ne "Verifying") {
    error ("WOR $wor is not in Verifying state!\nState:$state");
    return 2;
  } # if

  $session->EditEntity ($entity, "complete");
  $entity->SetFieldValue ("ActualEffort", $actualHrs) if $actualHrs ne "";

  my $status = $entity->Validate ();

  if ($status ne "") {
    $entity->Revert ();
    error ("Complete failed for WOR $wor:\n$status");
    return 2;
  } # if

  $status = $entity->Commit ();

  if ($status ne "") {
    error ("Complete failed during Submit for WOR $wor:\n$status");
    return 2;
  } # if

   return 0;
} # Complete

#-----------------------------------------------------------------------------
# executeCommand (@): Executes a cqtool command
#-----------------------------------------------------------------------------
sub executeCommand (@) {
  my (@args) = @_;

  my $cmd = lc shift @args;

  return if $cmd eq "";

  if ($_commands{$cmd}) {
    if (!$CQTool::session) {
      if ( # Commands that do not require a database connection
	  !($cmd eq "exit"	or
	    $cmd eq "quit"	or
	    $cmd eq "help"	or
	    $cmd eq "usage"	or
	    $cmd eq "verbose")) {
	verbose "Opening $_db_name as $_userid...";

	if (!$_password) {
	  display_nolf ("${_userid}'s password:");
	  `stty -echo`;
	  $_password = <STDIN>;
	  chomp $_password;
	  display ("");
	  `stty echo`;
	} # if

	openDB ($_userid, $_password, $_db_name);
      } # if
    } # if

    # Treat args: Args that are enclosed in quotes must be
    # combined. For simplicity's sake we will only support matched
    # pairs of double quotes. Anything else results in undefined
    # behavior.
    my (@new_args);

    foreach (@args) {
      # Quoted argument starting
      if (/^\"(.*)\"$/s) {
	push @new_args, $1;
      } else {
	push @new_args, $_;
      } # if
    } # foreach

    $_log->msg ("$cmd (" . join (",", @new_args) . ")") if get_debug;

    return $_commands{$cmd} (@new_args);
  } else {
    error ("Unknown command \"$cmd\" (try help)");
    return 1;
  } # if
} # executeCommand

#-----------------------------------------------------------------------------
# commandLoop (@): This is the interactive command loop
#-----------------------------------------------------------------------------
sub commandLoop (@) {
  my (@args) = @_;

  # For single, command line, commands...
  return executeCommand (@args) if @args;

  announce if !$_ucmwb;

  while () {
    if (!$_ucmwb) {
      display_nolf ($PROMPT . RESET . UNDERLINE);
    } else {
      display_nolf ($UCMWB_PROMPT);
    } # if

    # Read command into $_
    $_ = <STDIN>;
    chomp;

    # If we are not being called by ucmwb, display RESET to stop the
    # UNDERLINE we were using. This keeps the output from being
    # underlined. In ucmwb mode we are not using any of the terminal
    # sequences.
    display_nolf (RESET) if !$_ucmwb;

    # If the user hit Control-d then a ^D is displayed but we remain
    # on the same line. So output a carriage return and exit 0.
    if (!$_) {
      display ("");
      exit 0;
    } # if

    # Special handling for set command since we want to take
    # everything after <field> to be a value, and we may get long
    # values that are space separated and space significant
    # (e.g. description?)
    if (/^\s*(\w+)\s+(\w+)\s+(\w+)\s+(.*)/) {
      if (lc $1 eq "set") {
	my $cmd		= $1;
	my $wor		= $2;
	my $field	= $3;
	my $value	= $4;

	# Change "\n"'s back to \n's
	$value =~ s/\\n/\n/g;

	executeCommand ($cmd, $wor, $field, "\"$value\"");
      } else {
	executeCommand (split);
      } # if
    } else {
      executeCommand (split);
    } # if
  } # while
} # commandLoop
