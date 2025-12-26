
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
use Clipboard;

use lib "$FindBin::Bin/../lib";

use Display;
use Logger;
use Utils;
use Config;    # For OS detection

use LWP::UserAgent;
use URI::Escape;
use File::Temp qw(tempfile);
use File::Path qw(rmtree);
use File::Basename;

our @EXPORT = qw(speak);

sub _split_text ($) {
  my ($text) = @_;
  return unless defined $text;

  # Split into sentences max 100 chars
  my @sentences;

  # Basic splitting on punctuation, keeping punctuation
  # This is a simplified version of speak.pl logic
  while ($text =~ /(.{1,100})(?:[.!?;]|$)/g) {
    push @sentences, $1;
  }

  # Fallback if regex missed or text is just one long block
  push @sentences, $text unless @sentences;

  return @sentences;
} ## end sub _split_text ($)

sub _fetch_mp3 ($$$) {
  my ($ua, $text, $lang) = @_;

  my $url =
      "https://translate.google.com/translate_tts?ie=UTF-8&tl=$lang&q="
    . uri_escape ($text)
    . "&total=1&idx=0&client=tw-ob";

  my $response = $ua->get ($url);

  if ($response->is_success) {
    my $content = $response->content;
    if (length ($content) == 0) {
      warn "Fetch successful but content is empty";
      return undef;
    }

    # Check if we got HTML instead of MP3 (e.g. Captcha/Error)
    if ($content =~ /^\s*<(!DOCTYPE|html)/i) {
      warn
"Received HTML response instead of MP3 (likely CAPTCHA/Blocked) from URL: $url";
      return undef;
    }

    return $content;
  } else {
    warn "Failed to fetch TTS: " . $response->status_line;
    return undef;
  }
} ## end sub _fetch_mp3 ($$$)

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

If provided, errors and messages will be logged to the logfile, otherwise to speak.log

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Nothing

=back

=for html </blockquote>

=cut

  $log = Logger->new (
    path        => '/var/local/log',
    name        => 'speak',
    timestamped => 'yes',
    append      => 1,
  ) unless $log;

  if (-f "$FindBin::Bin/../data/shh") {
    $msg .= ' [silent shh]';
    $log->msg ($msg);
    return;
  }

  $msg = Clipboard->paste unless $msg;
  $msg = <$msg> if ref $msg eq 'GLOB';

  $log->msg ($msg);

  # New Implementation
  my $ua = LWP::UserAgent->new;
  $ua->agent ("Mozilla/5.0");

  my @sentences = _split_text ($msg);
  my @mp3_files;

  foreach my $sentence (@sentences) {
    next unless $sentence =~ /\S/;

    my $mp3_data = _fetch_mp3 ($ua, $sentence, 'en');
    next unless $mp3_data;

    my ($fh, $filename) = tempfile (SUFFIX => '.mp3', UNLINK => 0);
    binmode $fh;
    print $fh $mp3_data;
    close $fh;

    push @mp3_files, $filename;
  } ## end foreach my $sentence (@sentences)

  if (@mp3_files) {

    # Combine or play sequentially
    # Using 'sox' to play directly or concatenate would be better,
    # but for compatibility with existing 'play' command:

    # Concatenate using sox if multiple files
    my $final_file;
    if (@mp3_files > 1) {
      my ($fh, $joined) = tempfile (SUFFIX => '.mp3', UNLINK => 0);
      close $fh;
      $final_file = $joined;

      # Using system sox to join.
      # Note: This requires sox with mp3 handler.
      my $cmd = "sox " . join (" ", @mp3_files) . " $final_file";
      system ($cmd);
    } else {
      $final_file = $mp3_files[0];
    }

    # Play it
    if (-f $final_file) {
      if ($ENV{DEBUG_SPEAK}) {
        print "File info for $final_file:\n";
        system ("ls -l $final_file");
        system ("file $final_file");
      }

      # Cross-platform playback logic
      my $os = $^O;

      if ($os eq 'darwin') {

        # macOS
        system ("afplay \"$final_file\"");
      } elsif ($os eq 'MSWin32' || $os eq 'cygwin') {

        # Windows / Cygwin
        # Use powershell for headless playback if available, or start
        # Note: 'start' might pop up a window.
        # Cygwin often has 'play' (sox) as well.

        # Try PowerShell first as it's cleaner
        my $win_path = $final_file;
        if ($os eq 'cygwin') {
          chomp ($win_path = `cygpath -w "$final_file"`);
        }

        # Use PowerShell to play audio hidden
        my $cmd =
          "powershell -c (New-Object Media.SoundPlayer '$win_path').PlaySync()";
        if (system ($cmd) != 0) {

          # Fallback to sox 'play' if powershell fails
          system ("play -q \"$final_file\"");
        }
      } else {

# Linux / Unix
# Use paplay (PulseAudio) if available, as 'play' (sox) often struggles with ALSA/Pulse configuration
        if (-x '/usr/bin/paplay' || -x '/bin/paplay') {
          system ("paplay $final_file");
        } else {
          system ("play -q $final_file");
        }
      } ## end else [ if ($os eq 'darwin') ]

      unlink $final_file;
    } ## end if (-f $final_file)
    ## end if (-f $final_file)
  } ## end if (@mp3_files)

  # Cleanup temp files
  unlink @mp3_files;

  return;
}    # speak

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
