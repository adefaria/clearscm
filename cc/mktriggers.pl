#!/usr/bin/perl
use strict;
use warnings;

=head2 NAME $RCSfile: mktriggers.pl,v $

Enforce the application of triggers to vobs

=head2 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision:

$Revision: 1.6 $

=item Created:

Sat Apr  3 09:06:11 PDT 2003

=item Modified:

$Date: 2011/03/24 22:22:00 $

=head2 SYNOPSIS

 Usage: mktriggers.pl [-u|sage] [-[no]e|xec] [-[no]a|dd] [-[no]r|eplace]
                      [-[no]p|rivate] [ -vobs ] [-ve|rbose] [-d|ebug]

 Where:

  -u|sage:       Displays usage
  -[no]e|exec:   Execute mode (Default: Do not execute)
  -[no]a|dd:     Add any missing triggers (Default: Don't add)
  -[no]r|eplace: Replace triggers even if already present (Default:
                 Don't replace)

                 Note: If neither -add nor -replace is specified then
                 both -add and -replace are performed.

  -triggers:     Name of triggers.dat file (Default:
                 $FindBin::Bin/../etc/triggers.dat)
  -[no]p|rivate: Process private vobs (Default: Don't process private
                 vobs)

  -ve|rbose:     Be verbose
  -d|ebug:       Output debug messages

  -vob           List of vob tags to apply triggers to (default all vobs)

Note: You can specify -vob /vobs/vob1,/vobs/vob2 -vob /vobs/vob3 which will
result in processing all of /vobs/vobs1, /vobs/vob2 and /vobs/vob3.

=head2 DESCRIPTION

This script parses triggers.dat and created trigger types in vobs. It is
designed to be run periodically (cron(1)) and will add/replace triggers on
all vobs by default. It can also operate on individual vobs if required. The
script is driven by a data file, triggers.dat, which describes which triggers
are to be enforced one which vobs.

=head3 triggers.dat

File format: Lines beginning with "#" are treated as comments Blank lines are
skipped. Spaces and tabs can be used for whitespace.

  # Globals
  WinTriggerPath:	\\<NAS device>\clearscm\triggers
  LinuxTriggerPath:	/net/<NAS device>/clearscm/triggers

  # All vobs get the evil twin trigger
  Trigger: EVILTWIN
    Description:	Evil Twin Prevention Trigger
    Type:		-all -element
    Opkinds:		-preop lnname
    ScriptEngine:	Perl
    Script:		eviltwin.pl
  EndTrigger

  # Only these vobs get this trigger to enforce a naming policy
  # Note the trigger script gets a parameter 
  Trigger: STDNAMES
    Description:	Enforce standard naming policies
    Type:		-all -element
    Opkinds:		-preop lnname
    ScriptEngine:	Perl
    Script:		stdnames.pl -lowercase
    Vobs:		\dbengine, \backend
  EndTrigger

  # All vobs get rmelen trigger except ours!
  Trigger: RMELEM
    Description:	Disable RMELEM
    Type:		-all -element
    Opkinds:		-preop lnname
    ScriptEngine:	Perl
    Script:		rmelem.pl
    Novobs:		\scm
  EndTrigger

=head2 ENVIRONMENT

If the environment variable VEBOSE or DEBUG are set then it's as if -verbose
or -debug was specified.

=head2 COPYRIGHT

Copyright (c) 2004 Andrew DeFaria , ClearSCM, Inc.
All rights reserved.

=cut

use FindBin;

use Getopt::Long;

use lib "$FindBin::Bin/../lib";

use Display;
use OSDep;

# Where is the trigger source code kept?
my ($windows_trig_path, $linux_trig_path);

# Where is the trigger definition file?
my $etc_path = "$FindBin::Bin/../etc";
my $triggerData = "$etc_path/triggers.dat";

sub Usage (;$) {
  my ($msg) = @_;

  display $msg
    if $msg;

  system "perldoc $FindBin::Script";

  exit 1;
} # Usage

sub ParseTriggerData {
  open my $triggerData, '<', $triggerData
    or error "Unable to open $triggerData - $!", 1;

  my @triggers;
  my ($name, $desc, $type, $opkinds, $engine, $script, $vobs, $novobs);

  while (<$triggerData>) {
    chomp; chop if /\r$/;

    next if /^$/; # Skip blank lines
    next if /^\#/; # and comments

    s/^\s+//; # ltrim
    s/\s+$//; # rtrim

    if (/^\s*WinTriggerPath:\s*(.*)/i) {
      $windows_trig_path = $1;
      next;
    } # if

    if (/^\s*LinuxTriggerPath:\s*(.)/i) {
      $linux_trig_path = $1;
      next;
    } # if

    if (/^\s*Trigger:\s*(.*)/i) {
      $name = $1;
      next;
    } # if

    if (/^\s*Description:\s*(.*)/i) {
      $desc = $1;
      next;
    } # if

    if (/^\s*Type:\s*(.*)/i) {
      $type = $1;
      next;
    } # if

    if (/^\s*Opkinds:\s*(.*)/i) {
      $opkinds = $1;
      next;
    } # if

    if (/^\s*ScriptEngine:\s*(.*)/i) {
      $engine = $1;
      next;
    } # if

    if (/^\s*Script:\s*(.*)/i) {
      $script = $1;
      next;
    } # if

    if (/^\s*Vobs:\s*(.*)/i) {
      $vobs = $1;
      next;
    } # if

    if (/^\s*Novobs:\s*(.*)/i) {
      $novobs = $1;
      next;
    } # if

    if (/EndTrigger/) {
      my %trigger;

      $trigger{name}    = $name;
      $trigger{desc}    = $desc;
      $trigger{type}    = $type;
      $trigger{opkinds} = $opkinds;
      $trigger{engine}  = $engine;
      $trigger{script}  = $script;
      $trigger{vobs}    = !$vobs  ? 'all'   : $vobs;
      $trigger{novobs}  = $novobs ? $novobs : '';

      push (@triggers, \%trigger);

      $name = $desc = $type = $opkinds = $engine = $script = $vobs = $novobs = "";
    } # if
  } # while

  close $triggerData;

  error 'You must define WindowsTriggerPath, LinuxTriggerPath or both', 1
    unless ($windows_trig_path or $linux_trig_path);

  return @triggers;
} # ParseTriggerData

sub RemoveVobPrefix ($) {
  my ($vob) = @_;

  if ($ARCH =~ /windows/ or $ARCH =~ /cygwin/) {
    $vob =~ s/^\\//;
  } else {
    $vob =~ s/^\/vobs\///;
  } # if

  return $vob;
} # RemoveVobPrefix

sub MkTriggerType ($$$$%) {
  my ($vob, $exec, $add, $replace, %trigger) = @_;

  my $replaceOpt = '';

  # Need an extra set of "\\" for non Windows systems such as Cygwin
  # since apparently the shell if envoked, collapsing a set of "\\".
  my $vobtag = $ARCH =~ /cygwin/i ? "\\$vob" : $vob;
  my $status = system ("cleartool lstype trtype:$trigger{name}\@$vobtag > $NULL 2>&1");

  if ($status == 0) {
    debug "Found pre-existing trigger $trigger{name}";

    # If we are not replacing then skip by returning
    return
      unless $replace;

    $replaceOpt = '-replace';
  } else {
    debug "No pre-existing trigger $trigger{name}";

    # We need to add the trigger. However, if we are not adding then skip by
    # returning
    return
      unless $add;
  } # if

  error "Sorry I only support ScriptEngines of Perl!" if $trigger{engine} ne "Perl";

  my $win_engine = 'ccperl';
  my $linux_engine = 'Perl';

  my ($script, $parm) = split / /, $trigger{script};

  $parm ||= '';

  my ($win_script, $linux_script, $execwin, $execlinux);

  $execwin = $execlinux = '';

  if ($windows_trig_path) {
    $win_script = $ARCH =~ /cygwin/i ? "\\\\$windows_trig_path\\$script"
                                     : "$windows_trig_path\\$script";

    warning "Unable to find trigger script $win_script ($!)"
      if ($ARCH =~ /windows/i and $ARCH =~ /cygwin/) and not -e $win_script;

    $execwin = "-execwin \"$win_engine $win_script $parm\" ";
  } elsif ($linux_trig_path) {
    $linux_script = "$linux_trig_path/$script";

    warning "Unable to find trigger script $linux_script ($!)"
      if ($ARCH !~ /windows/i and $ARCH !~ /cygwin/) and not -e $linux_script;

    $execlinux = "-execwin \"$win_engine $win_script $parm\" ";
  } # if

  my $command =
    'cleartool mktrtype '          .
    "$replaceOpt "                 .
    "$trigger{type} "              .
    "$trigger{opkinds} "           .
    "-comment \"$trigger{desc}\" " .
    $execwin                       .
    $execlinux                     .
    "$trigger{name}\@$vobtag "     .
    "> $NULL 2>&1";

  debug "Command: $command";

  $vob =~ s/\\\\/\\/;

  $status = 0;
  $status = system $command
    if $exec;

  if ($status) {
    error "Unable to add trigger! Status = $status\nCommand: $command";
    return 1;
  } # if

  if ($replaceOpt) {
    if ($replace) {
      if ($exec) {
	display "Replaced trigger $trigger{name} in $vob";
      } else {
	display "[noexecute] Would have replaced trigger $trigger{name} in $vob";
      } # if
    } # if
  } else {
    if ($add) {
      if ($exec) {
	display "Added trigger $trigger{name} to $vob";
      } else {
	display "[noexecute] Would have added trigger $trigger{name} to $vob";
      } # if
    } # if
  } # if

  return;
} # MkTriggerType

sub VobType ($) {
  my ($vob) = @_;

  # Need an extra set of "\\" for non Windows systems such as Cygwin
  # since apparently the shell if envoked, collapsing a set of "\\".
  $vob = "\\" . $vob if $ARCH =~ /cygwin/;

  my @lines = `cleartool describe vob:$vob`;

  chomp @lines; chop @lines if $lines[0] =~ /\r$/;

  foreach (@lines) {
    return 'ucm'
      if /AdminVOB \<-/;
  } # foreach

  return 'base';
} # VobType

sub MkTriggers ($$$$@) {
  my ($vob, $exec, $add, $replace, @triggers) = @_;

 TRIGGER: foreach (@triggers) {
    my %trigger = %{$_};

    my $vobname = RemoveVobPrefix $vob;

    # Skip vobs on the novobs list
    foreach (split /[\s+|,]/, $trigger{novobs}) {
      my $vobtag = RemoveVobPrefix $_;

      if ($vobname eq RemoveVobPrefix $_) {
	debug "Skipping $vob (on novobs list)";
	next TRIGGER;
      } # if
    } # foreach

    # For triggers whose vob type is "all" or unspecified make the trigger
    if ($trigger{vobs} eq 'all' || $trigger{vobs} eq '') {
      MkTriggerType $vob, $exec, $add, $replace, %trigger;
    } elsif ($trigger{vobs} eq 'base' || $trigger{vobs} eq 'ucm') {
      # If vob type is "base" or "ucm" make sure the vob is of correct type
      my $vob_type = VobType ($vob);

      if ($vob_type eq $trigger{vobs}) {
	MkTriggerType $vob, $exec, $add, $replace, %trigger;
      } else {
	verbose "Trigger $trigger{name} is for $trigger{vobs} vobs but $vob is a $vob_type vob - Skipping...";
      } # if
    } else {
      my @Vobs = split /[\s+|,]/, $trigger{vobs};

      # Otherwise we expect the strings in $triggers{vobs} to be space or comma
      # separated vob tags so we make sure it matches this $vob.
      foreach (@Vobs) {
	if ($vobname eq RemoveVobPrefix $_) {
	  MkTriggerType $vob, $exec, $add, $replace, %trigger;
	  last;
	} # if
      } # foreach
    } # if
  } # foreach

  return;
} # MkTriggers

my ($exec, $add, $replace, $private, @vobs) = (0, 0, 0, 0);

GetOptions (
  usage         => sub { Usage },
  verbose       => sub { set_verbose },
  debug         => sub { set_debug },
  'triggers=s', \$triggerData,
  'exec!',      \$exec,
  'add!',       \$add,
  'replace!',   \$replace,
  'private!',   \$private,
  'vobs=s',     \@vobs,
) or Usage "Invalid parameter";

# This allows comma separated parms like -vob vob1,vob2,etc.
@vobs = split /,/, join (',', @vobs);

# If the user didn't specify -add or -replace then toggle both on
$add = $replace = 1
  unless $add or $replace;

# If the user didn't specify any -vobs then that means all vobs
@vobs = `cleartool lsvob -short`
  unless @vobs;

chomp @vobs; chop @vobs if $vobs[0] =~ /\r/;

# Parse the triggers.dat file
debug "Parsing trigger data ($triggerData)";

my @triggers = ParseTriggerData;

# Iterrate through the list of vobs
debug 'Processing ' . scalar @vobs . ' vobs';

foreach (sort @vobs) {
  # Need an extra set of "\\" for non Windows systems such as Cygwin
  # since apparently the shell if envoked, collapsing a set of "\\".
  my $vob = $ARCH =~ /cygwin/i ? "\\$_" : $_;
  my $line = `cleartool lsvob $vob`;

  # Skip private vobs
  unless ($private) {
    if ($line =~ / private/) {
      verbose "Skipping private vob $vob...";
      next;
    } # if
  } # unless

  $vob =~ s/\\\\/\\/;

  debug "Applying triggers to $vob...";

  MkTriggers $_, $exec, $add, $replace, @triggers;
} # foreach

debug 'All triggers applied';
