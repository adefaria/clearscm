=pod

=head1 NAME $RCSfile: Speak.pm,v $

Convert text to speach using Google's engine and play it on speakers

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@DeFaria.com>

=item Revision

$Revision: 1.0 $

=item Created

Wed 24 Feb 2021 11:05:36 AM PST

=item Modified


=back

=head1 SYNOPSIS

This module offers subroutines to convert text into speach and speak them.

=head2 DESCRIPTION

This module exports subroutines to process text to speach and speak them.

=head1 ROUTINES

The following routines are exported:

=cut

package Speak;

use strict;
use warnings;

use base 'Exporter';

use FindBin;

use lib "$FindBin::Bin/../lib";

use Display;
use Logger;
use Utils;

our @EXPORT = qw(speak);

sub speak (;$$) {
  my ($msg, $log) = @_;

=pod

=head2 speak($msg, $log)

Convert $msg to speach.

Note this currently uses an external script to do the conversion. I intend to
re-write that into Perl here eventually.

Parameters:

=for html <blockquote>

=over

=item $msg:

Message to speak. If $msg is defined and scalar then that is the message
to speak. If it is a file handle then the text will be read from that file.
Otherwise the text in the clipboard will be used.

=item $log

If provided, errors and messages will be logged to the logfile, otherwise stdout

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Nothing

=back

=for html </blockquote>

=cut

  if (-f "$FindBin::Bin/shh") {
    if ($log) {
      $log->msg("Not speaking because we were asked to be quiet - $msg");
    } else {
      verbose "Not speaking because we were asked to be quiet - $msg";
    } # if

    return;
  } # if

  # Handle the case where $msg is a filehandle
  $msg = <$msg> if ref $msg eq 'GLOB';

  # We can't have two speakers going at the same time so if we have an error
  # backoff a little and try again.
  my $attempts   = 0;
  my $maxretries = 3;
  my $backoff    = 2;

  my ($status, @output);

  while ($attempts++ < $maxretries) {
    ($status, @output) = Execute "/usr/local/bin/gt \"$msg\"";

    if ($status) {
      my $errmsg = "Unable to speak (Status: $status) - " . join "\n", @output;

      if ($log) {
        $log->err($errmsg);
      } else {
        error $errmsg;
      } # if

      sleep $backoff++;
    } else {
      return; # We said our piece...
    } # if
  } # while

  my $errmsg = 'Maximum retries exceeded - terminating';

  if ($log) {
    $log->err($errmsg, $status);
  } else {
    error $errmsg, $status;
  } # if

  return;
} # speak

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
