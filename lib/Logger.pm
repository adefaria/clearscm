=pod

=head1 NAME $RCSfile: Logger.pm,v $

Object oriented interface to handling logfiles

=head1 VERSION

=over

=item Author:

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision:

$Revision: 1.23 $

=item Created:

Fri Mar 12 10:17:44 PST 2004

=item Modified:

$Date: 2012/01/06 22:00:09 $

=back

=head1 SYNOPSIS

Perl module for consistent creation and writing to logfiles

  $log = Logger->new (
    path	=> "/tmp"
    timestamped	=> "yes",
    append	=> "yes",
  );

  $log->msg ("This message might appear on STDOUT");
  $log->log ("Stuff this message into the logfile");

  if (!$log->logcmd ("ls /non-existant-dir")) {
    $log->err ("Unable to proceed", 1);
  } # if

  $log->maillog (
    to          => "Andrew\@ClearSCM.com",
    subject     => "Logger test",
    heading     => "Results of Logging"
  );

=head1 DESCRIPTION

Logger creates a log object that provides easy methods to log messages, errors,
commands, etc. to log files. Logfiles can be created as being transient in that
they will automatically disappear (unless you call the err method). You can
capture the output of commands into log files and even have them autoamatically
timestamped. Finally you can have logfiles automatically mailed.

=head1 ROUTINES

The following routines are exported:

=cut

package Logger;

use strict;
use warnings;

use base 'Exporter';

use FindBin;
use File::Spec;
use IO::Handle;
use Cwd;

use Display;
use OSDep;
use DateUtils;
use Mail;
use Utils;

my ($error_color, $warning_color, $command_color, $highlight_color, $normal) = "";

my $me;

BEGIN {
  # Extract relative path and basename from script name.
  $me = $FindBin::Script;

  # Remove .pl for Perl scripts that have that extension
  $me =~ s/\.pl$//;
} # BEGIN

sub new(;%) {
  my ($class, %parms) = @_;

=pod

=head2 new (<parms>)

Construct a new Logger object. The following OO style arguments are
supported:

Parameters:

=for html <blockquote>

=over

=item name:

Name of the leaf portion of the log file. Default is the name of the
script with ".log" appended to the logfile name. So if the calling
script was called "getdb" the default log file would be called
"getdb.log" (Default: Script name).

=item path:

Path to create the logfile in (Default: Current working directory)

=item disposition:

One of "temp" or "perm". Logfiles that are of disposition temp will be
deleted when the process ends unless any calls have been made to the
err method (Default: perm)

=item timestamped:

If set to 0 then no timestamps will be used. If set to 1 then all
lines logged will be preceeded with a timestamp (Default: 0)

=item append:

If defined the logfile will be appended to (Default: Overwrite)

=item extension

If defined an alternate extension to use for the log file (e.g. log.html)

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Logger object

=back

=for html </blockquote>

=cut

  my $cwd = cwd;

  my $name        = $parms{name}        ? $parms{name}        : $me;
  my $path        = $parms{path}        ? $parms{path}        : $cwd;
  my $disposition = $parms{disposition} ? $parms{disposition} : 'perm';
  my $timestamped = $parms{timestamped} ? $parms{timestamped} : 'FALSE';  
  my $append      = $parms{append}      ? '>>'                : '>';
  my $logfile;

  if ($parms{extension}) {
    $name .= ".$parms{extension}" unless $parms{extension} eq '';
  } else {
    $name .= '.log';
  } # if

  open $logfile, $append, "$path/$name"
    or error "Unable to open logfile $path/$name - $!", 1;

  # Set unbuffered output
  $logfile->autoflush();

  set_verbose if $ENV{VERBOSE};
  set_debug   if $ENV{DEBUG};

  return bless {
    path        => $path,
    name        => $name,
    handle      => $logfile,
    timestamped => $parms {timestamped},
    disposition => $disposition,
    errors      => 0,
    warnings    => 0,
  }, $class; # bless
} # new

sub append($) {
  my ($self, $filename) = @_;

=pod

=head3 append ($filename)

Appends $filename to the end of the current logfile

Parameters:

=for html <blockquote>

=over

=item $filename

Filename to append to the logfile

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Nothing

=back

=for html </blockquote>

=cut

  open my $file, '<', $filename
    or return 1;

  while (<$file>) {
    $self->log ($_);
  } # while

  close $file;

  return;
} # append

sub name() {
  my ($self) = @_;

=pod

=head3 name

Returns the leaf portion of logfile name.

Parameters:

=for html <blockquote>

=over

=item None

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Leaf node of log file name

=back

=for html </blockquote>

=cut

  return $self->{name};
} # name

sub fullname() {
  my ($self) = @_;

=pod

=head3 fullname

Returns the full pathname to the logfile

Parameters:

=for html <blockquote>

=over

=item None

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Full pathname to the logfile

=back

=for html </blockquote>

=cut

  return "$self->{path}/$self->{name}";
} # fullname

sub msg($;$) {
  my ($self, $msg, $nolinefeed) = @_;

=pod

=head3 msg ($msg, $nolinefeed)

Similar to log except verbose (See Display.pm) is used to possibly
additionally write the $msg to STDOUT.

Parameters:

=for html <blockquote>

=over

=item $msg:

Message to display

=item $nolinefeed:

If defined no linefeed is displayed at the end of the message.

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Nothing

=back

=for html </blockquote>

=cut

  $self->log ($msg, $nolinefeed);

  verbose $msg, undef, $nolinefeed;

  return;
} # msg

sub disp($;$) {
  my ($self, $msg, $nolinefeed) = @_;

=pod

=head3 disp ($msg, $nolinefeed)

Similar to log except display (See Display.pm) is used to write the $msg to 
STDOUT and to the log file.

Parameters:

=for html <blockquote>

=over

=item $msg:

Message to display

=item $nolinefeed:

If defined no linefeed is displayed at the end of the message.

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Nothing

=back

=for html </blockquote>

=cut

  $self->log ($msg, $nolinefeed);

  display $msg, undef, $nolinefeed;

  return;
} # disp

sub incrementErr(;$) {
  my ($self, $increment) = @_;

=pod

=head3 incrementErr ($msg, $errno)

Increments the error count by $increment

Parameters:

=for html <blockquote>

=over

=item $increment

Amount to increment (Default: 1)

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Nothing

=back

=for html </blockquote>

=cut  

  $increment ||= 1;

  $self->{errors} += $increment;

  return;
} # incrementErr

sub err($;$) {
  my ($self, $msg, $errno) = @_;

=pod

=head3 err ($msg, $errno)

Writes an error message to the log file. Error messages are prepended
with "ERROR" and optionally "#$errno" (if $errno is specified),
followed by the message. If $errno was specified then the string " -
terminating" is appended to the message. Otherwise the number of
errors in the log are incremented and used to determine the logfile's
disposition at close time.

Parameters:

=for html <blockquote>

=over

=item $msg:

Message to display

=item $errno:

Error number to display (also causes termination).

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Nothing

=back

=for html </blockquote>

=cut

  display_error ($msg, $errno); 

  if ($errno) {
    $msg = "ERROR #$errno: $msg - terminating";
  } else {
    $msg = "ERROR: $msg";
  } # if

  $self->msg($msg);

  $self->incrementErr;

  exit $errno if $errno;

  return;
} # err

sub maillog(%) {
  my ($self, %parms) = @_;

=pod

=head3 maillog (<parms>)

Mails the current logfile. "Parms" are the same as the parameters
described for Mail.pm.

Parameters:

=for html <blockquote>

=over

=item <See Mail.pm>

Supports all parameters that Mail::mail supports.

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item None

=back

=for html </blockquote>

=cut

  my $from    = $parms{from};
  my $to      = $parms{to};
  my $cc      = $parms{cc};
  my $subject = $parms{subject};
  my $heading = $parms{heading};
  my $footing = $parms{footing};
  my $mode    = $parms{mode};

  $mode = "plain" unless $mode;

  my $log_filename = "$self->{path}/$self->{name}";

  open my $logfile, '<', $log_filename
    or error "Unable to open logfile $log_filename", 1;

  if ($mode eq 'html') {
    $heading .= '<b>Logfile:</b> ' 
              . "$self->{path}/$self->{name}"
              .'<hr><pre>';
    $footing  = '</pre><hr>'
              . $footing;
  } # if

  mail(
    from    => $from,
    to      => $to,
    cc      => $cc,
    subject => $subject,
    mode    => $mode,
    heading => $heading,
    footing => $footing,
    data    => $logfile
  );

  close $logfile
    or error "Unable to close logfile $log_filename", 1;

  return;
} # maillog

sub log($;$) {
  my ($self, $msg, $nolinefeed) = @_;

=pod

=head3 log ($msg, $nolinefeed)

Writes $msg to the log file. Note this is a "silent" log in that $msg
is simply written to the logfile and not possibly also echoed to
STDOUT (See the msg method).

Parameters:

=for html <blockquote>

=over

=item $msg:

Message to write to log file

=item $nolinefeed:

If defined no linefeed is displayed at the end of the message.

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Nothing

=back

=for html </blockquote>

=cut

  $msg = "$me: " . YMDHM . ": $msg" if $self->{timestamped};

  display $msg, $self->{handle}, $nolinefeed;

  return;
} # log

sub logcmd($) {
  my ($self, $cmd) = @_;

=pod

=head3 logcmd ($cmd)

Execute the command in $cmd storing all output into the logfile

=for html <blockquote>

=over

=item $cmd:

The command $cmd is executed with the results logged to the logfile.

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Scalar representing the exit status of $cmd and an array of the commands output.

=back

=for html </blockquote>

=cut

  display "\$ $cmd", $self->{handle} if get_debug;

  my $status = open my $output, '-|', "$cmd 2>&1";

  if (!$status) {
    $self->{error}++;
    return 1;
  } # if

  my @output;

  while (<$output>) {
    chomp;
    push @output, $_;
    display $_, $self->{handle};
    display $_ if get_debug;
  } # while

  close $output
    or error "Unable to close output ($!)", 1;

  return ($?, @output);
} # logcmd

sub loglines() {
  my ($self) = @_;

=pod

=head3 loglines

Returns an array of lines from the current logfile.

Parameters:

=for html <blockquote>

=over

=item None

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Array of lines from the logfile

=back

=for html </blockquote>

=cut

  return ReadFile "$self->{path}/$self->{name}";
} # loglines

sub warn($;$) {
  my ($self, $msg, $warnno) = @_;

=pod

=head3 warn ($msg, $warnno)

Similar to error but logs the message as a warning. Increments the
warnings count in the object thus also affecting its disposition at
close time. Does not terminate the process if $warnno is specified.

Parameters:

=for html <blockquote>

=over

=item $msg:

Message to write to the logfile

=item $warnno:

Warning number to put in the warn message (if specified)

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Nothing

=back

=for html </blockquote>

=cut

  warning $msg, $warnno;

  if ($warnno) {
    $msg = "WARNING #$warnno: $msg";
  } else {
    $msg = "WARNING: $msg";
  } # if

  $self->log ($msg);
  $self->{warnings}++;

  return;
} # warn

sub errors() {
  my ($self) = @_;

=pod

=head3 errors ()

Returns the number of errors encountered

Parameters:

=for html <blockquote>

=over

=item None

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item $errors

=back

=for html </blockquote>

=cut

  return $self->{errors};
} # errors

sub dbug($) {
  my ($self, $msg) = @_;

  $self->log("DEBUG: $msg") unless get_debug;

  return;
} # dbug

sub warnings() {
  my ($self) = @_;

=pod

=head3 warnings ()

Returns the number of warnings encountered

Parameters:

=for html <blockquote>

=over

=item None

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item $warnings

=back

=for html </blockquote>

=cut

  return $self->{warnings};
} # warnings

sub DESTROY() {
  my ($self) = @_;

  close ($self->{handle});

  if ($self->{disposition} eq 'temp') {
    if ($self->{errors}   == 0 and
      $self->{warnings} == 0) {
      unlink $self->fullname;
    } # if
  } # if

  return;
} # destroy

1;

=pod

=head2 CONFIGURATION AND ENVIRONMENT

DEBUG: If set then $debug in this module is set.

VERBOSE: If set then $verbose in this module is set.

=head2 DEPENDENCIES

=head3 Perl Modules

L<File::Spec>

L<IO::Handle>

=head3 ClearSCM Perl Modules

=for html <p><a href="/php/scm_man.php?file=lib/DateUtils.pm">DateUtils</a></p>

=for html <p><a href="/php/scm_man.php?file=lib/Display.pm">Display</a></p>

=for html <p><a href="/php/scm_man.php?file=lib/Mail.pm">Mail</a></p>

=for html <p><a href="/php/scm_man.php?file=lib/OSDep.pm">OSDep</a></p>

=for html <p><a href="/php/scm_man.php?file=lib/Utils.pm">Utils</a></p>

=head2 INCOMPATABILITIES

None yet...

=head2 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head2 LICENSE AND COPYRIGHT

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
