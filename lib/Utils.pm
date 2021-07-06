=pod

=head1 NAME $RCSfile: Utils.pm,v $

Utils - Simple and often used utilities

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.26 $

=item Created

Thu Jan  5 15:15:29 PST 2006

=item Modified

$Date: 2013/03/28 21:18:55 $

=back

=head1 SYNOPSIS

This module seeks to encapsulate useful utilities, things that are often done
over and over again but who's classification is miscellaneous.

  EnterDaemonMode

  my @children = GetChildren ($pid);

  my @lines = ReadFile ("/tmp/file");

  print "Found foo!\n" if InArray ("foo", @bar);

  my ($status, @output) = Execute ("ps -ef");

=head1 DESCRIPTION

A collection of utility type subroutines.

=head1 ROUTINES

The following routines are exported:

=cut

package Utils;

use strict;
use warnings;

use FindBin;

use base 'Exporter';

use POSIX qw (setsid);
use File::Spec;
use Carp;
use Term::ReadKey;

use OSDep;
use Display;

our @EXPORT = qw (
  EnterDaemonMode
  Execute
  GetChildren
  GetPassword
  InArray
  LoadAvg
  PageOutput
  PipeOutput
  PipeOutputArray
  ReadFile
  RequiredFields
  RedirectOutput
  StartPipe
  Stats
  StopPipe
  Usage
);

sub _restoreTerm () {
  # In case the user hits Ctrl-C
  print "\nControl-C\n";

  ReadMode 'normal';

  exit;
} # _restoreTerm

sub EnterDaemonMode (;$$$) {
  my ($logfile, $errorlog, $pidfile) = @_;

=pod

=head2 EnterDaemonMode ($logfile, $errorlog)

There is a right way to enter "daemon mode" and this routine is for that. If you
call EnterDaemonMode your process will be disassociated from the terminal and
enter into a background mode just like a good daemon.

Parameters:

=for html <blockquote>

=over

=item $logfile

File name of where to redirect STDOUT for the daemon (Default: $NULL)

=item $errorlog

File name of where to redirect STDERR for the daemon (Default: $NULL)

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Doesn't return

=back

=for html </blockquote>

=cut

  $logfile  ||= $NULL;
  $errorlog ||= $NULL;

  my $file;

  # Redirect STDIN to $NULL
  open STDIN, '<', $NULL
    or error "Can't read $NULL ($!)", 1;

  # Redirect STDOUT to logfile
  open STDOUT, '>>', $logfile
    or error "Can't write to $logfile ($!)", 1;

  # Redirect STDERR to errorlog
  open STDERR, '>>', $errorlog
    or error "Can't write to $errorlog ($!)", 1;

  # Change the current directory to /
  my $ROOT = $ARCHITECTURE eq "windows" ? "C:\\" : "/";
  chdir $ROOT
    or error "Can't chdir to $ROOT ($!), 1";

  # Turn off umask
  umask 0;

  # Now fork the daemon
  defined (my $pid = fork)
    or error "Can't create daemon ($!)", 1;

  # Now the parent exits
  exit if $pid;

  # Write pidfile if specified
  if ($pidfile) {
    $pidfile =  File::Spec->rel2abs ($pidfile); 

    open $file, '>', $pidfile
      or warning "Unable to open pidfile $pidfile for writing - $!";  

    print $file "$$\n";

    close $file; 
  } # if

  # Set process to be session leader
  setsid ()
    or error "Can't start a new session ($!)", 1;

  return;
} # EnterDaemonMode

sub Execute ($) {
  my ($cmd) = @_;

=pod

=head2 Execute ($command)

We all execute OS commands and then have to deal with the output and return
codes and the like. How about an easy Execute subroutine. It takes one
parameter, the command to execute, executes it and returns two parameters, the
output in a nice chomped array and the status.

Parameters:

=for html <blockquote>

=over

=item $command

Command to execute

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item A status scalar and an array of lines output from the command (if any).

Note, no redirection of STDERR is included. If you want STDERR included in
STDOUT then do so in the $command passed in.

=back

=for html </blockquote>

=cut

  local $SIG{CHLD} = 'DEFAULT';

  my @output = `$cmd`;
  my $status = $?;

  chomp @output;

  return ($status, @output);
} # Execute

sub GetChildren (;$) {
  my ($pid) = @_;

=pod

=head2 GetChildren ($pid)

Returns an array of children pids for the passed in $pid.

NOTE: This assumes that the utility pstree exists and is in the callers PATH.

Parameters:

=for html <blockquote>

=over

=item $pid

$pid to return the subtree of (Default: pid of init)

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Array of children pids

=back

=for html </blockquote>

=cut

  my @children = ();

  $pid = 1 if !$pid;

  my @output = `pstree -ap $pid`;

  return @children if $? == 0;

  chomp @output;

  foreach (@output) {
    # Skip the pstree process and the parent process - we want only
    # our children.
    next if /pstree/ or /\($pid\)/;

    if (/\((\d+)\)/) {
      push @children, $1;
    } # if
  } # foreach

  return @children;
} # GetChildren

sub GetPassword (;$) {
  my ($prompt) = @_;

=pod

=head2 GetPassword (;$prompt)

Prompt for a password

Parameters:

=for html <blockquote>

=over

=item $prompt

Prompt string to use (Default: "Password:")

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item $password

=back

=for html </blockquote>

=cut  

  $prompt ||= 'Password';

  my $password = '';

  local $| = 1;

  print "$prompt:";

  $SIG{INT} = \&_restoreTerm;

  ReadMode 'cbreak';

  while () {
    my $key;

    while (not defined ($key = ReadKey -1)) { }

    if ($key =~ /(\r|\n)/) {
       print "\n";

       last;
    } # if

    # Handle backspaces
    if ($key eq chr(127)) {
      unless ($password eq '') {
        chop $password;

        print "\b \b";
      } # unless
    } else {
      print '*';

      $password .= $key;
    } # if
  } # while

  ReadMode 'restore'; # Reset tty mode before exiting.

  $SIG{INT} = 'DEFAULT';

  return $password;
} # GetPassword

sub InArray ($@) {
  my ($item, @array) = @_;

=pod

=head2 InArray ($item, @array)

Find an item in an array.

Parameters:

=for html <blockquote>

=over

=item $item

Item to search for

=item @array

Array to search

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item $TRUE if found - $FALSE otherwise

=back

=for html </blockquote>

=cut

  foreach (@array) {
    return $TRUE if $item eq $_;
  } # foreach

  return $FALSE;
} # InArray

sub LoadAvg () {

=pod

=head2 LoadAvg ()

Return an array of the 1, 5, and 15 minute load averages.

Parameters:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item An array of the 1, 5, and 15 minute load averages in a list context.
In a scalar context just the 1 minute load average.

=back

=for html </blockquote>

=cut  

  # TODO: Make it work on Windows...
  return if $^O =~ /win/i;

  open my $loadAvg, '<', '/proc/loadavg'
    or croak "Unable to open /proc/loadavg\n";

  my $load = <$loadAvg>;

  close $loadAvg;

  my @loadAvgs = split /\s/, $load;

  if (wantarray) {
    return @loadAvgs;
  } else {
    return $loadAvgs[0]; # This is the 1 minute average
  }
} # LoadAvg

our $pipe;

sub StartPipe ($;$) {
  my ($to, $existingPipe) = @_;

=pod

=head2 StartPipe ($to, $existingPipe)

Starts a pipeline

Parameters:

=for html <blockquote>

=over

=item $to

String representing the other end of the pipe

=item $existingPipe

Already existing pipe handle (from a previous call to StartPipe)

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item A $pipe to used for PipeOutput

=back

=for html </blockquote>

=cut

  if ($existingPipe) {
    close $existingPipe;

    open $existingPipe, '|-', $to
      or error "Unable to open pipe - $!", 1;

    return $existingPipe;
  } else {
    open $pipe, '|-', $to
      or error "Unable to open pipe - $!", 1;

    return $pipe;
  } # if
} # StartPipe

sub PipeOutputArray ($@) {
  my ($to, @output) = @_;

=pod

=head2 PipeOutputArray ($to, @ouput)

Pipes output to $to

Parameters:

=for html <blockquote>

=over

=item $to

String representing the other end of the pipe to pipe @output to
 
=item @output

Output to pipe

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Nothing

=back

=for html </blockquote>

=cut

  open my $pipe, '|', $to 
    or error "Unable to open pipe - $!", 1;

  foreach (@output) {
    chomp;

    print $pipe "$_\n";
  } # foreach

  return close $pipe;
} # PipeOutputArray

sub PipeOutput ($;$) {
  my ($line, $topipe) = @_;

=pod

=head2 PipeOutput ($line, $topipe)

Pipes a single line to $topipe

Parameters:

=for html <blockquote>

=over

=item $line

Line to output to $topipe.

=item $topipe

A pipe returned by StartPipe (or our $pipe) to which the $line is piped.
 
=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Nothing

=back

=for html </blockquote>

=cut

  $topipe ||= $pipe;

  chomp $line; chop $line if $line =~ /\r$/;

  print $pipe "$line\n";

  return;
} # PipeOutput

sub StopPipe (;$) {
  my ($pipeToStop) = @_;

=pod

=head2 StopPipe ($pipe)

Stops a $pipe.

Parameters:

=for html <blockquote>

=over

=item $pipe

Pipe to stop

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Nothing

=back

=for html </blockquote>

=cut

  $pipeToStop ||= $pipe;

  close $pipeToStop if $pipeToStop;

  return;
} # StopPipe

sub PageOutput (@) {
  my (@output) = @_;
  
=pod

=head2 PageOutput (@ouput)

Pages output to the screen

Parameters:

=for html <blockquote>

=over

=item @output

Output to page

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Nothing

=back

=for html </blockquote>

=cut

  if ($ENV{PAGER}) {
    PipeOutputArray $ENV{PAGER}, @output;
  } else {
    print "$_\n"
      foreach (@output);
  } # if
  
  return;
} # PageOutput

sub RedirectOutput ($$@) {
  my ($to, $mode, @output) = @_;

=pod

=head2 RedirectOutput ($to, @ouput)

Pages output to the screen

Parameters:

=for html <blockquote>

=over

=item $to

Where to send the output

=item @output

Output to redirect

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Nothing

=back

=for html </blockquote>

=cut

  croak 'Mode must be > or >>'
    unless ($mode eq '>' or $mode eq '>>');

  open my $out, $mode, $to
    or croak "Unable to open $to for writing - $!";

  foreach (@output) {
    chomp;
    print $out "$_\n";
  } # foreach

  return; 
} # RedirectOutput

sub ReadFile ($) {
  my ($filename) = @_;

=pod

=head2 ReadFile ($filename)

How many times have you coded a Perl subroutine, or just staight inline Perl to
open a file, read all the lines into an array and close the file. This routine
does that very thing along with the associated and proper checking of open
failure and even trims the lines in the output array of trailing newlines? This
routine returns an array of the lines in the filename passed in.

Parameters:

=for html <blockquote>

=over

=item $filename

Filename to read

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Array of lines in the file

=back

=for html </blockquote>

=cut

  open my $file, '<', $filename
    or error "Unable to open $filename ($!)", 1;

  if (wantarray) {
    local $/ = "\n";

    my @lines = <$file>;

    close $file
      or error "Unable to close $filename ($!)", 1;

    my @cleansed_lines;

    foreach (@lines) {
      chomp;
      chop if /\r/;
      push @cleansed_lines, $_ if !/^#/; # Discard comment lines
    } # foreach

    return @cleansed_lines;
  } else {
    local $/ = undef;

    return <$file>;
  } # if
} # ReadFile

sub Stats ($;$) {
  my ($total, $log) = @_;

=pod

=head2 Stats ($total, $log)

Reports runtime stats

Parameters:

=for html <blockquote>

=over

=item $total

Reference to a hash of total counters. The keys of the hash will be the labels
and the values of the hash will be the counters.

=item $log

Logger object to log stats to (if specified). Note: if the Logger object has 
errors or warnings then they will be automatically included in the output.

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Nothing

=back

=for html </blockquote>

=cut

  my $msg = "$FindBin::Script Run Statistics:";

  if ($log and ref $log eq 'Logger') {
    $total->{errors}   = $log->{errors};
    $total->{warnings} = $log->{warnings};
  } # if

  if (keys %$total) {
    # Display statistics (if any)
    if ($log) {
      $log->msg ($msg);
    } else {
      display $msg; 
    } # if

    foreach (sort keys %$total) {
      $msg = $total->{$_} . "\t $_";

      if ($log) {
        $log->msg ($total->{$_} . "\t $_");
      } else {
        display $msg;
      } # if
    } # foreach
  } # if

  return;
} # Stats

sub Usage (;$) {
  my ($msg) = @_;

=pod

=head2 Usage ($msg)

Reports usage using perldoc

Parameters:

=for html <blockquote>

=over

=item $msg

Message to output before doing perldoc

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Does not return

=back

=for html </blockquote>

=cut

  display $msg
    if $msg;

  system "perldoc $0";

  exit 1;
} # Usage

sub RequiredFields($$) {

=pod

=head2 RequiredFields($total, $log)

Check if a list of fields are contained in a hash

Parameters:

=for html <blockquote>

=over

=item $fields

Array reference to a list of field names that are required

=item $rec

Hash reference whose key values we are checking

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Message

Returns either an empty string or a string naming the first missing required
field

=back

=for html </blockquote>

=cut

  my ($fields, $rec) = @_;

  for my $fieldname (@$fields) {
    my $found = 0;

    for (keys %$rec) {
      if ($fieldname eq $_) {
        $found = 1;
        last;
      } # if
    } # for

    return "$fieldname is required" unless $found;
  } # for

  return;
} # RequiredFields

END {
  StopPipe;
} # END

1;

=head1 CONFIGURATION AND ENVIRONMENT

None

=head1 DEPENDENCIES

=head2 Perl Modules

L<File::Spec|File::Spec>

L<FindBin>

L<POSIX>

=head2 ClearSCM Perl Modules

=for html <p><a href="/php/scm_man.php?file=lib/Display.pm">Display</a></p>

=for html <p><a href="/php/scm_man.php?file=lib/Logger.pm">Logger</a></p>

=for html <p><a href="/php/scm_man.php?file=lib/OSDep.pm">OSDep</a></p>

=head1 INCOMPATABILITIES

None yet...

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head1 LICENSE AND COPYRIGHT

This Perl Module is freely available; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option) any
later version.

This Perl Module is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License
(L<http://www.gnu.org/copyleft/gpl.html>) for more details.

You should have received a copy of the GNU General Public License along with
this Perl Module; if not, write to the Free Software Foundation, Inc., 59
Temple Place - Suite 330, Boston, MA 02111-1307, USA. reserved.

=cut
