=pod

=head1 NAME $RCSfile: Display.pm,v $

Simple and consistant display routines for Perl

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.45 $

=item Created

Fri Mar 12 10:17:44 PST 2004

=item Modified

$Date: 2013/05/30 15:48:06 $

=back

=head1 SYNOPSIS

This module seeks to make writing output simpler and more consistant. Messages
are classified as display (informational - always displayed), verbose (written
only if $verbose is set) and debug (written only if $debug is set). There are
also routines for error(s) and warning(s) which support optional parameters for
error number and warning number. If error number is specified then the process
is also terminated.

 display "message";
 verbose "$n records processed";
 verbose2 "Processing record #$recno";
 warning "Unable to find record", 1;
 debug "Reached here...";
 error "Can't continue", 2;

=head2 DESCRIPTION

This module implements several routines to provide and easy and
consistant interface to writing output in Perl. Perl has lots of ways
to do such things but these methods seek to be self explainitory and
to provide convenient parameters and defaults so as to make coding
easier.

There are also some other routines, i.e. get_debug, that will return
$debug in case you want to execute other Perl code only when
debugging:

  if (get_debug) {
    foreach (@output_line) {
      debug $_;
    } # foreach
  } # if

By default these routines write lines complete with the terminating
"\n". I find that this is most often what you are doing. There are
corresponding <routine>_nolf versions for display and verbose in case
you wish to not terminate lines. Or use the new say function.

Also, routines like display support a file handle parameter if you
wish to say display into a file - Default STDOUT.

Both version and debug support levels and have convienence functions:
verbose1, debug2. Three levels of conienence functions are supplied
although an unlimited amount can be supported directly through
verbose/debug. See documentaton for those functions for details.

=head1 ROUTINES

The following routines are exported:

=cut

package Display;

use strict;
use warnings;

use base 'Exporter';

use FindBin;
use File::Spec;
use Term::ANSIColor qw(color);
use Carp;
use Config;

our @EXPORT = qw (
  debug debug1 debug2 debug3
  display
  display_err
  display_error
  display_nolf
  error
  get_debug
  get_me
  get_trace
  get_verbose
  say
  set_debug
  set_me
  set_trace
  set_verbose
  trace
  trace_enter
  trace_exit
  verbose verbose1 verbose2 verbose3
  verbose_nolf
  warning
);

my ($me, $verbose, $debug, $trace);

BEGIN {
  $me = $FindBin::Script;
  $me =~ s/\.pl$//;

  $verbose = $ENV{VERBOSE};
  $debug   = $ENV{DEBUG};
  $trace   = $ENV{TRACE};
} # BEGIN

sub display_err ($;$$);

sub debug ($;$$$) {
  my ($msg, $handle, $nolinefeed, $level) = @_;

=pod

=head2 debug[1-3] ($msg, $handle, $nolinefeed, $level)

Write $msg to $handle (default STDERR) with a "\n" unless $nolinefeed
is defined. Messages are written only if written if $debug is set and
=< $level. $level defaults to 1.

debug1, debug2 and debug3 are setup as convienence functions that are
equivalent to calling debug with $level set to 1, 2 or 3 respectively

Parameters:

=for html <blockquote>

=over

=item $msg:

Message to display

=item $handle:

File handle to display to (Default: STDERR)

=item $nolinefeed:

If defined no linefeed is displayed at the end of the message.

=item $level

If defined, if $level =< $debug then the debug message is displayed.

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Nothing

=back

=for html </blockquote>

=cut

  return
    unless $debug;

  return
    if $debug == 0;

  $level ||= 1;
  $msg   ||= '';

  if (($handle and -t $handle) or (-t *STDERR)) {
    $msg = color ('cyan')
         . $me
         . color ('reset')
         . ': '
         . color ('magenta')
         . "DEBUG"
         . color ('reset')
         . ": $msg";
  } else {
    $msg = "$me: DEBUG: $msg";
  } # if

  display_err $msg, $handle, $nolinefeed if $debug and $level <= $debug;

  return;
} # debug

sub debug1 ($;$$) {
  my ($msg, $handle, $nolinefeed) = @_;

  debug $msg, $handle, $nolinefeed, 1;

  return;
} # debug1

sub debug2 ($;$$) {
  my ($msg, $handle, $nolinefeed) = @_;

  debug $msg, $handle, $nolinefeed, 2;

  return;
} # debug1

sub debug3 ($;$$) {
  my ($msg, $handle, $nolinefeed) = @_;

  debug $msg, $handle, $nolinefeed, 2;

  return;
} # debug1

sub display (;$$$) {
  my ($msg, $handle, $nolinefeed) = @_;

=pod

=head2 display ($msg, $handle, $nolinefeed)

Write $msg to $handle (default STDOUT) with a "\n" unless $nolinefeed
is defined.

Parameters:

=for html <blockquote>

=over

=item $msg:

Message to display

=item $handle:

File handle to display to (Default: STDOUT)

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

  $msg  ||= '';
  $handle = *STDOUT unless $handle;

  print $handle $msg;
  print $handle "\n" unless $nolinefeed;

  return;
} # display

sub display_err ($;$$) {
  my ($msg, $handle, $nolinefeed) = @_;

=pod

=head2 display_err ($msg, $handle, $nolinefeed)

Displays $msg to STDERR

Parameters:

=for html <blockquote>

=over

=item $msg:

Message to display

=item $handle:

File handle to display to (Default: STDOUT)

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

  $msg  ||= '';
  $handle = *STDERR if !$handle;

  print $handle $msg;
  print $handle "\n" if !$nolinefeed;

  return;
} # display_err

sub display_error ($;$$$) {
  my ($msg, $errno, $handle, $nolinefeed) = @_;

=pod

=head2 display_error ($msg, $errno, $handle, $nolinefeed)

Displays colorized $msg to STDERR

Parameters:

=for html <blockquote>

=over

=item $msg:

Message to display

=item $errno

Error no to display (if any)

=item $handle:

File handle to display to (Default: STDOUT)

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

  $msg ||= '';

  unless ($errno) {
    if (($handle and -t $handle) or (-t *STDERR) and ($Config{perl} ne 'ratlperl')) {
      $msg = color ('cyan') 
           . $me
           . color ('reset')
           . ': '
           . color ('red')
           . 'ERROR'
           . color ('reset')
           . ": $msg";
    } else {
      $msg = "$me: ERROR: $msg";
    } # if
  } else {
    if (($handle and -t $handle) or (-t *STDERR) and ($Config{perl} ne 'ratlperl')) {
      $msg = color ('cyan')
           . $me
           . color ('reset')
           . ': '
           . color ('red')
           . "ERROR #$errno"
           . color ('reset')
           . ": $msg";
    } else {
      $msg = "$me: ERROR #$errno: $msg";
    } # if
  } # if

  display_err $msg, $handle, $nolinefeed;

  return;
} # display_error

sub display_nolf ($;$) {
  my ($msg, $handle) = @_;

=pod

=head2 display_nolf ($msg, $handle)

Equivalent of display ($msg, $handle, "nolf").

Parameters:

=for html <blockquote>

=over

=item $msg:

Message to display

=item $handle:

File handle to display to (Default: STDOUT)

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Nothing

=back

=for html </blockquote>

=cut

  display $msg, $handle, "nolf";

  return;
} # display_nolf

sub error ($;$$$) {
  my ($msg, $errno, $handle, $nolinefeed) = @_;

=pod

=head2 error ($msg, $errno, $handle, $nolinefeed)

Write $msg to $handle (default STDERR) with a "\n" unless $nolinefeed
is defined. Preface message with "<script name>: ERROR: " so that
error messages are clearly distinguishable. If $errno is specified it
is included and the process it terminated with the exit status set to
$errno.

Parameters:

=for html <blockquote>

=over

=item $msg:

Message to display

=item $handle:

File handle to display to (Default: STDOUT)

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

  display_error $msg, $errno, $handle, $nolinefeed;

  exit $errno if $errno;

  return;
} # error

sub get_debug {

=pod

=head2 get_debug

Returns $debug.

Parameters:

=for html <blockquote>

None

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item $debug

=back

=for html </blockquote>

=cut

  return $debug;
} # get_debug

sub get_trace {

=pod

=head2 get_trace

Returns $trace.

Parameters:

=for html <blockquote>

None

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item $trace

=back

=for html </blockquote>

=cut

  return $trace;
} # get_trace

sub get_verbose {

=pod

=head2 get_verbose

Returns $verbose.

Parameters:

=for html <blockquote>

None

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item $verbose

=back

=for html </blockquote>

=cut

  return $verbose;
} # set_verbose

sub set_debug {
  my ($newValue) = @_;

=pod

=head2 set_debug

Sets $debug.

Parameters:

=for html <blockquote>

=over

=item newValue

New value to set $verbose to. If not specified then $verbose is set to
1. The only other sensible value would be 0 to turn off verbose.

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Old setting of $verbose

=back

=for html </blockquote>

=cut

  my $returnValue = $debug ? $debug : 0;

  $debug = defined $newValue ? $newValue : 1;

  return $returnValue;
} # set_debug

sub get_me () {

=pod

=head2 get_me ($me)

Gets $me which is used by error. Module automatically calculates the
basename of the script that called it.

Parameters:

=over

=item none

=back

Returns:

=for html <blockquote>

=over

=item $me

=back

=for html </blockquote>

=cut

  return $me;
} # get_me

sub set_me {
  my ($whoami) = @_;

=pod

=head2 set_me ($me)

Sets $me which is used by error. Module automatically calculates the
basename of the script that called it.

Parameters:

=over

=item $me

String to set $me as

=back

Returns:

=for html <blockquote>

=over

=item Nothing

=back

=for html </blockquote>

=cut

  $me = $whoami;

  return;
} # set_me

sub set_trace (;$) {
  my ($newValue) = @_;

=pod

=head2 set_trace

Sets $trace.

Parameters:

=for html <blockquote>

=over

=item newValue

New value to set $trace to. If not specified then $trace is set to
1. The only other sensible value would be 0 to turn off trace.

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Old setting of $trace

=back

=for html </blockquote>

=cut

  my $returnValue = $trace ? $trace : 0;

  $trace = defined $newValue ? $newValue : 1;

  return $returnValue;
} # set_trace

sub set_verbose (;$) {
  my ($newValue) = @_;

=pod

=head2 set_verbose

Sets $verbose.

Parameters:

=for html <blockquote>

=over

=item newValue

New value to set $verbose to. If not specified then $verbose is set to
1. The only other sensible value would be 0 to turn off verbose.

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Old setting of $verbose

=back

=for html </blockquote>

=cut

  my $returnValue = $verbose ? $verbose : 0;

  $verbose = defined $newValue ? $newValue : 1;

  return $returnValue;
} # set_verbose

sub trace (;$$) {
  my ($msg, $type) = @_;

=pod

=head2 trace

Emit trace statements from within a subroutine

Parameters:

=for html <blockquote>

=over

=item msg

Optional message to display

=item type

Optional prefix to message. Used by trace_enter and trace_exit. If not
specified the string "In " is used.

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Name of the calling subroutine, if known

=back

=for html </blockquote>

=cut

  return
    unless $trace;

  $msg    = $msg  ? ": $msg" : '';
  $type ||= 'In';

  croak 'Type should be ENTER, EXIT or undef'
    unless $type eq 'ENTER' ||
           $type eq 'EXIT'  ||
           $type eq 'In';

  my $stack = $type eq 'In' ? 1 : 2;

  my ($package, $filename, $line, $subroutine) = caller ($stack);

  if ($subroutine) {
    $subroutine =~ s/^main:://
  } else {
    $subroutine = 'main';
  } # if

  if (-t STDOUT) {
    display color ('cyan')
          . "$type "
          . color ('yellow')
          . color ('bold')
          . $subroutine
          . color ('reset')
          . $msg;
  } else {
    display "$type $subroutine$msg";
  } # if

  return $subroutine;
} # trace

sub trace_enter (;$) {
  my ($msg) = @_;

=pod

=head2 trace_enter

Emit enter trace for a subroutine

Parameters:

=for html <blockquote>

=over

=item msg

Optional message to display along with "ENTER <sub>"

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Name of the calling subroutine, if known

=back

=for html </blockquote>

=cut

  return trace $msg, "ENTER";
} # trace_enter

sub trace_exit (;$) {
  my ($msg) = @_;

=pod

=head2 trace_exit

Emit exit trace for a subroutine

Parameters:

=for html <blockquote>

=over

=item msg

Optional message to display along with "EXIT <sub>". Useful in
distinguishing multiple exit/returns.

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item none

=back

=for html </blockquote>

=cut

  trace $msg, "EXIT";

  return
} # trace_exit

sub verbose ($;$$$) {
  my ($msg, $handle, $nolinefeed, $level) = @_;

=pod

=head2 verbose[1-3] ($msg, $handle, $nolinefeed, $level)

Write $msg to $handle (default STDOUT) with a "\n" unless $nolinefeed
is defined. Messages are written only if written if $verbose is set
and <= $level. $level defaults to 1.

verbose1, verbose2 and verbose3 are setup as convienence functions
that are equivalent to calling verbose with $level set to 1, 2 or 3
respectively

Parameters:

=for html <blockquote>

=over

=item $msg

Message to display

=item $handle

File handle to display to (Default: STDOUT)

=item $nolinefeed

If defined no linefeed is displayed at the end of the message.

=item $level

If defined, if $level <= $verbose then the verbose message is
displayed.

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Nothing

=back

=for html </blockquote>

=cut

  $level   ||= 1;
  $verbose ||= 0;

  display $msg, $handle, $nolinefeed if $verbose and $level <= $verbose;

  return;
} # verbose

sub verbose1 ($;$$) {
  my ($msg, $handle, $nolinefeed) = @_;

  verbose $msg, $$handle, $nolinefeed, 1;

  return;
} # verbose1

sub verbose2 ($;$$) {
  my ($msg, $handle, $nolinefeed) = @_;

  verbose $msg, $handle, $nolinefeed, 2;

  return;
} # verbose1

sub verbose3 ($;$$) {
  my ($msg, $handle, $nolinefeed) = @_;

  verbose $msg, $handle, $nolinefeed, 3;

  return;
} # verbose1

sub verbose_nolf ($;$) {
  my ($msg, $handle) = @_;

=pod

=head2 verbose_nolf ($msg, $handle)

Equivalent of verbose ($msg, $handle, "nolf")

Parameters:

=for html <blockquote>

=over

=item $msg

Message to display

=item $handle

File handle to display to (Default: STDOUT)

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Nothing

=back

=for html </blockquote>

=cut

  verbose $msg, $handle, "nolf";

  return;
} # verbose_nolf

sub warning ($;$$$) {
  my ($msg, $warnno, $handle, $nolinefeed) = @_;

=pod

=head2 warning  ($msg, $handle, $nolinefeed)

Write $msg to $handle (default STDERR) with a "\n" unless $nolinefeed
is defined. Preface message with "<script name>: WARNING: " so that
warning messages are clearly distinguishable.

Parameters:

=for html <blockquote>

=over

=item $msg:

Message to display

=item $handle:

File handle to display to (Default: STDOUT)

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

  $msg ||= '';

  unless ($warnno) {
    if (($handle and -t $handle) or (-t *STDERR) and ($Config{perl} ne 'ratlperl')) {
      $msg = color ('cyan')
           . $me
           . color ('reset')
           . ": "
           . color ('yellow')
           . "WARNING"
           . color ('reset')
           . ": $msg";
    } else {
      $msg = "$me: WARNING: $msg";
    } # if
  } else {
    if (($handle and -t $handle) or (-t *STDERR) and ($Config{perl} ne 'ratlperl')) {
      $msg = color ('cyan')
           . $me
           . color ('reset')
           . ": "
           . color ('yellow')
           . "WARNING #$warnno"
           . color ('reset')
           . ": $msg";
    } else {
      $msg = "$me: WARNING #$warnno: $msg";
    } # if
  } # if

  display_err $msg, $handle, $nolinefeed;

  return;
} # warning

1;

=pod

=head1 CONFIGURATION AND ENVIRONMENT

DEBUG: If set then $debug is set to this level.

VERBOSE: If set then $verbose is set to this level.

TRACE: If set then $trace is set to this level.

=head1 DEPENDENCIES

=head2 Perl Modules

L<File::Spec|File::Spec>

L<Term::ANSIColor|Term::ANSIColor>

=head1 INCOMPATABILITIES

None yet...

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head1 LICENSE AND COPYRIGHT

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
