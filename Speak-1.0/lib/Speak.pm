
=pod

=head1 NAME

Speak - Convert text to speech using Google's engine and play it on speakers

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

# use lib "$FindBin::Bin/../lib";

our $VERSION = '1.0';

use Config;    # For OS detection

# Inline simple Logger since we want to avoid dependencies
{

  package Speak::Logger;

  use strict;
  use warnings;
  use File::Basename;
  use POSIX qw(strftime);

  sub new {
    my ($class, %args) = @_;
    my $self = {
      path        => $args{path} || '.',
      name        => $args{name} || 'speak',
      timestamped => $args{timestamped},
      append      => $args{append},
      handle      => undef,
    };

    my $mode    = $self->{append} ? '>>' : '>';
    my $logfile = File::Spec->catfile ($self->{path}, $self->{name} . '.log');

    # We try to open the logfile, but if it fails we just warn and carry on
    # effectively logging nowhere (or we could default to STDERR)
    if (open my $fh, $mode, $logfile) {
      my $old_fh = select ($fh);
      $| = 1;    # Autoflush
      select ($old_fh);
      $self->{handle} = $fh;
    } else {
      warn "Could not open logfile $logfile: $!";
    }

    bless $self, $class;
    return $self;
  } ## end sub new

  sub msg {
    my ($self, $msg) = @_;
    return unless defined $msg;

# Print to stdout per original Logger behavior for 'msg' call (it was verbose/display)
# The original code implies msg() writes to log AND stdout (via Display::verbose/display)
# We will replicate basic behavior: print to STDOUT and Log file.

    print "$msg\n";

    if ($self->{handle}) {
      my $timestamp =
        $self->{timestamped}
        ? strftime ("%Y-%m-%d %H:%M:%S", localtime) . ": "
        : "";
      my $fh = $self->{handle};
      print $fh "$timestamp$msg\n";
    } ## end if ($self->{handle})
  } ## end sub msg

  sub DESTROY {
    my $self = shift;
    close $self->{handle} if $self->{handle};
  }
}

sub _get_config {
  my ($file) = @_;
  my %config;
  return %config unless -f $file;

  if (open my $fh, '<', $file) {
    while (my $line = <$fh>) {
      chomp $line;
      next if $line =~ /^\s*[#!]/ || $line =~ /^\s*$/;
      if ($line =~ /^\s*([^:=]+?)\s*[:=]\s*(.*?)\s*$/) {
        my $key = $1;
        my $val = $2;

        # Simple variable interpolation for $ENV
        $val =~ s/\$(\w+)/$ENV{$1} || "\$$1"/ge;
        $config{$key} = $val;
      } ## end if ($line =~ /^\s*([^:=]+?)\s*[:=]\s*(.*?)\s*$/)
    } ## end while (my $line = <$fh>)
    close $fh;
  } ## end if (open my $fh, '<', ...)
  return %config;
} ## end sub _get_config

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

sub _convert_mp3_to_wav ($$) {
  my ($mp3, $wav) = @_;

  # Try ffmpeg
  if (system ("which ffmpeg >/dev/null 2>&1") == 0) {
    return system ("ffmpeg -y -v error -i \"$mp3\" \"$wav\"") == 0;
  }

  # Try mpg123
  if (system ("which mpg123 >/dev/null 2>&1") == 0) {
    return system ("mpg123 -q -w \"$wav\" \"$mp3\"") == 0;
  }

  # Try lame
  if (system ("which lame >/dev/null 2>&1") == 0) {
    return system ("lame --decode --quiet \"$mp3\" \"$wav\"") == 0;
  }

  # Fallback to sox (might fail if no mp3 handler)
  return system ("sox \"$mp3\" \"$wav\"") == 0;
} ## end sub _convert_mp3_to_wav ($$)

sub speak (;$$$) {
  my ($msg, $log, $lang) = @_;

=pod

=head2 speak($msg, $log, $lang)

Convert $msg to speech.

Parameters:

=for html <blockquote>

=over

=item $msg:

Message to speak. If $msg is defined and scalar then that is the message
to speak. If it is a file handle then the text will be read from that file.
Otherwise the text in the clipboard will be used.

=item $log

If provided, errors and messages will be logged to the logfile, otherwise to speak.log

=item $lang

Language code (e.g. 'en', 'en-gb', 'en-au'). Defaults to $ENV{SPEAK_LANG} or 'en'.

=back

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Nothing

=back

=for html </blockquote>

=cut

  $log = Speak::Logger->new (
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

  # Determine language:
  # 1. Argument $lang
  # 2. Environment variable SPEAK_LANG
  # 3. Config file
  # 4. Default 'en'

  unless ($lang) {
    if ($ENV{SPEAK_LANG}) {
      $lang = $ENV{SPEAK_LANG};
    } elsif (-f "$FindBin::Bin/../etc/speak.conf") {
      my %conf = _get_config "$FindBin::Bin/../etc/speak.conf";
      $lang = $conf{language};
    }

    $lang ||= 'en';
  } ## end unless ($lang)

  my @sentences = _split_text ($msg);
  my @mp3_files;

  foreach my $sentence (@sentences) {
    next unless $sentence =~ /\S/;

    my $mp3_data = _fetch_mp3 ($ua, $sentence, $lang);
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
       # System.Media.SoundPlayer only supports WAV, so convert MP3 -> WAV first
        my ($fh_wav, $wav_file) = tempfile (SUFFIX => '.wav', UNLINK => 0);
        close $fh_wav;

        # Convert to WAV using sox
        if (system ("sox \"$final_file\" \"$wav_file\"") == 0) {
          my $win_path = $wav_file;
          if ($os eq 'cygwin') {
            chomp ($win_path = `cygpath -w "$wav_file"`);
          }

          my $cmd_wav =
"powershell -c (New-Object Media.SoundPlayer '$win_path').PlaySync()";
          if (system ($cmd_wav) != 0) {

            # Fallback
            system ("play -q \"$final_file\"");
          }
          unlink $wav_file;
        } else {

          # Conversion failed logic fallback
          my $cmd =
"powershell -c (New-Object Media.SoundPlayer '$win_path').PlaySync()";
          if (system ($cmd) != 0) {

            # Fallback to sox 'play' if powershell fails
            system ("play -q \"$final_file\"");
          }
        } ## end else [ if (system ("sox \"$final_file\" \"$wav_file\""...))]
      } else {

      # Linux / Unix
      # paplay often requires WAV if libsndfile lacks mp3 support (e.g. on Mars)
      # We convert to WAV to be safe.
        if (-x '/usr/bin/paplay' || -x '/bin/paplay') {
          my ($fh_wav, $wav_file) = tempfile (SUFFIX => '.wav', UNLINK => 0);
          close $fh_wav;

          # Convert to WAV
          if (_convert_mp3_to_wav ($final_file, $wav_file)) {
            system ("paplay \"$wav_file\"");
            unlink $wav_file;
          } else {

            # Conversion failed, try playing mp3 directly
            system ("paplay \"$final_file\"");
          }
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
