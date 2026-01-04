#!/usr/bin/perl

=pod

=head1 NAME $RCSfile: announceEmail.pl,v $

Monitors an IMAP Server and announce incoming emails by extracting the subject
line and from line and then pushing that into "GoogleTalk".

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@DeFaria.com>

=item Revision

$Revision: 1.2 $

=item Created:

Thu Apr  4 13:40:10 MST 2019

=item Modified:

$Date: 2019/04/04 13:40:10 $

=back

=head1 SYNOPSIS

 Usage: announceEmail.pl [-usa|ge] [-h|elp] [-v|erbose] [-de|bug]
                         [-use|rname <username>] [-p|assword <password>]
                         [-i|map <server>] [-t|imeout <secs>]
                         [-an|nouce] [-ap|pend] [-da|emon] [-n|name <name>]
                         [-uses|sl] [-useb|locking]

 Where:
   -usa|ge       Print this usage
   -h|elp        Detailed help
   -v|erbose     Verbose mode (Default: -verbose)
   -de|bug       Turn on debugging (Default: Off)

   -user|name    User name to log in with (Default: $USER)
   -p|assword    Password to use (Default: prompted)
   -i|map        IMAP server to talk to (Default: defaria.com)
   -t|imeout <s> Timeout IMAP idle call (Sefault: 1200 seconds or 20 minutes)

   -an|nounce    Announce startup (Default: False)
   -ap|pend      Append to logfile (Default: Noappend)
   -da|emon      Run in daemon mode (Default: -daemon)
   -n|ame        Name of account (Default: imap)
   -uses|sl      Whether or not to use SSL to connect (Default: False)
   -useb|locking Whether to block on socket (Default: False)

 Signals:
   $SIG{USR1}:   Toggles debug option
   $SIG{USR2}:   Reestablishes connection to IMAP server

=head1 DESCRIPTION

This script will connect to an IMAP server, login and then monitor the user's
INBOX. When new messages arrive it will extract the From address and Subject
from the message and compose a message to be used by "Google Talk" to announce
the email. The message will be similar to:

  "<From> emailed <Subject>"

=cut

use strict;
use warnings;
use feature 'state';

use FindBin;
use Getopt::Long;
use Mail::IMAPTalk;
use MIME::Base64;
use Encode qw(decode);
use Pod::Usage;
use URI::Escape qw(uri_escape_utf8);
use Proc::ProcessTable;

use lib "$FindBin::Bin/../lib";

use Display;
use Logger;
use Speak;
use TimeUtils;
use Utils;

my $processes = Proc::ProcessTable->new;

for my $process (@{$processes->table}) {
  if ($process->cmndline eq $0 and $process->pid != $$) {
    verbose "$FindBin::Script already running";

    exit 0;
  }    # if
}    # for

my $defaultIMAPServer = 'defaria.com';
my $IMAP;
my %unseen;
my $log;

my @greetings = (
  'Incoming message',
  'You have received a new message',
  'Hey I found this in your inbox',
  'For some unknown reason this guy send you a message',
  'Did you know you just got a message',
  'Potential spam',
  'You received a communique',
  'I was looking in your inbox and found a message',
  'Not sure you want to hear this message',
  'Good news',
  "What's this? A new message",
);

my $icon          = '/home/andrew/.icons/Thunderbird.jpg';
my $notifyTimeout = 5 * 1000;
my $IMAPTimeout   = 20 * 60;

my %opts = (
  usage    => sub {pod2usage},
  help     => sub {pod2usage (-verbose => 2)},
  verbose  => sub {set_verbose},
  debug    => sub {set_debug},
  daemon   => 1,
  timeout  => $IMAPTimeout,
  username => $ENV{USER},
  password => $ENV{PASSWORD},
  imap     => $defaultIMAPServer,
  port     => undef,
  insecure => 0,
);

sub notify($) {
  my ($msg) = @_;

  my $cmd = "notify-send -i $icon -t $notifyTimeout '$msg'";

  Execute $cmd;

  return;
}    # notify

sub interrupted {
  if (get_debug) {
    notify 'Turning off debugging';
    set_debug 0;
  } else {
    notify ('Turning on debugging');
    set_debug 1;
  }    # if

  return;
}    # interrupted

sub Connect2IMAP(;$$);
sub MonitorMail;

# $SIG{USR2} = \&restart;

sub unseenUIDs() {
  $IMAP->select ('inbox')
    or do {
    my $err = "Unable to select inbox: " . $@;
    $log->err ($err);    # Log without exit
    die $err;            # Die to trigger retry/reconnect
    };

  # Return a hash of UIDs
  my @uids = @{$IMAP->search ('not', 'seen')};
  return map {$_ => 0} @uids;
}    # unseenUIDs

sub Connect2IMAP(;$$) {

  my ($quiet, $ignore_existing) = @_;
  $log->dbug ("Connecting to $opts{imap} as $opts{username}");

  if ($opts{password}) {
    my $len = length ($opts{password});
    $log->dbug ("Password present ($len chars)");
  } else {
    $log->dbug ("Password missing!");
  }

  my $port = $opts{port};
  unless ($port) {
    if ($opts{usessl}) {
      $port = 993;
    } else {
      $port = 143;
    }    # if
  }    # unless
  $log->dbug ("Using port: $port" . ($opts{usessl} ? " (SSL)" : ""));

  my %ssl_opts;
  if ($opts{insecure}) {
    $log->dbug ("SSL Verification disabled");
    $ssl_opts{SSL_verify_mode} = 0;
  }

  # Destroy any old connections
  undef $IMAP;

  $IMAP = Mail::IMAPTalk->new (
    Server      => $opts{imap},
    Port        => $port,
    Username    => $opts{username},
    Password    => $opts{password},
    UseSSL      => $opts{usessl},
    UseBlocking => $opts{useblocking},
    %ssl_opts,
  );

  unless ($IMAP) {
    $log->err (
      "Unable to connect to IMAP server $opts{imap}: $@\n(System Error: $!)")
      unless $quiet;
    return 0;
  } ## end unless ($IMAP)

  # Turn on UID mode
  $IMAP->uid (1);

  $log->dbug ("Connected to $opts{imap} as $opts{username}");

  # Focus on INBOX only
  $IMAP->select ('inbox');

  # Setup %unseen to have each unseen message UID set to 0 meaning not read
  # aloud yet. Preserve existing state to avoid re-announcing on reconnect.
  # If $ignore_existing is set, mark them as read (1).
  my %serverUnseen = unseenUIDs;
  for (keys %serverUnseen) {
    $unseen{$_} //= $ignore_existing ? 1 : 0;
  }

  return 1;
}    # Connect2IMAP

sub MonitorMail() {
  $log->dbug ("Top of MonitorMail loop");

  # First close and reselect the INBOX to get its current status
  $IMAP->close;
  $IMAP->select ('INBOX')
    or do {
    my $err = "Unable to select INBOX - " . $@;
    $log->err ($err);    # Log
    die $err;            # Die to trigger reconnect loop
    };

  $log->dbug ("Closed and reselected INBOX");

  # Go through all of the unseen messages and add them to %unseen if they were
  # not there already from a prior run and read
  my %newUnseen = unseenUIDs;

# Clean out logic REMOVED to prevent "forgetting" messages during glitches.
# We trust that if a UID is in %unseen, we decided to track it.
# It will grow over time, but memory usage should be negligible for a single user.

  $log->dbug ("Processing new unseen messages");
  for (keys %newUnseen) {
    next if $unseen{$_};

    # Use UID fetch
    my $envelope = $IMAP->fetch ($_, '(envelope)');

    # fetch in UID mode returns a hash keyed by UID.
    # We need to find the element that has the envelope.
    # Since we fetched by one UID, there should be one entry.
    my ($seq_num) = keys %$envelope;
    unless ($seq_num) {
      $log->msg ("Could not fetch envelope for UID $_");
      next;
    }

    my $from    = $envelope->{$seq_num}{envelope}{From};
    my $subject = $envelope->{$seq_num}{envelope}{Subject};
    $subject //= 'Unknown subject';

    # Extract the name only when the email is of the format "name <email>"
    if ($from =~ /^"?(.*?)"?\s*\<(\S*)>/) {
      $from = $1 if $1 ne '';
    }    # if

    $subject = decode ('MIME-Header', $subject);

    # Remove long strings of numbers like order numbers. They are uninteresting
    my $longNumber = 5;
    $subject =~ s/\s+\S*\d{$longNumber,}\S*\s*//g;

    # Now speak it!
    my $logmsg = "From $from $subject";

    my $greeting = $greetings[int rand $#greetings];
    my $msg      = "$greeting from $from... $subject";
    my $hour     = (localtime)[2];
    my $wday     = (localtime)[6];

    # Only announce if after 6 Am. Note this will announce up until
    # midnight but that's ok. I want midnight to 6 Am as silent time.
    # Allison change! On weekends only, quiet announcedEmail from 10 pm till
    # 10 am.
    $log->dbug ("About to speak/log");

    if ($wday == 5 && $hour >= 22) {    # Friday night
      $log->msg ("$logmsg [silent Friday night]");
    } elsif ($wday == 0 or $wday == 6) {    # Saturday / Sunday
      if ($hour <= 10) {
        $log->msg ("$logmsg [silent Saturday or Sunday morning]");
      } else {
        $log->msg  ($logmsg);
        $log->dbug ('Calling speak');
        speak $msg, $log;
      }
    } elsif ($hour >= 7) {
      $log->msg  ($logmsg);
      $log->dbug ('Calling speak');
      speak $msg, $log;
    } else {
      $log->msg ("$logmsg [silent nighttime]");
    }    # if

    $unseen{$_} = 1;
  }    # for

  return;
}    # MonitorMail

END {
  # If $log is not yet defined then the exit is not unexpected
  if ($log) {
    my $msg = "$FindBin::Script $opts{name} ending unexpectedly!";

    speak $msg, $log;

    $log->err ($msg);
  }    # if
}    # END

## Main
GetOptions (
  \%opts,        'usage',     'help',       'verbose',
  'debug',       'daemon!',   'username=s', 'name=s',
  'password=s',  'imap=s',    'timeout=i',  'usessl',
  'useblocking', 'announce!', 'append',     'port=i',
  'insecure',
) || pod2usage;

my $domain = $opts{imap};
$domain =~ s/^imap\.//;
$domain = 'gmail.com' if $domain eq 'google.com';

my $display_user = $opts{username};
$display_user =~ s/\@.*$//;

# Special casing for Andrew@DeFaria.com
if ($domain =~ /^defaria\.com$/i && $display_user eq 'andrew') {
  $display_user = 'Andrew';
  $domain       = 'DeFaria.com';
}

my $script = $FindBin::Script;
$script =~ s/\.pl$//;
local $0 = "$script $display_user\@$domain";

unless ($opts{password}) {
  verbose "I need $opts{username}'s password";
  $opts{password} = GetPassword;
}    # unless

$opts{name} //= $opts{imap};

if ($opts{username} =~ /.*\@(.*)$/) {
  $opts{name} = $1;
}    # if

if ($opts{daemon}) {

  # Perl complains if we reference $DB::OUT only once
  no warnings;
  EnterDaemonMode unless defined $DB::OUT or get_debug;
  use warnings;
}    # if

$log = Logger->new (
  path        => '/var/local/log',
  name        => "$Logger::me.$opts{name}",
  timestamped => 'yes',
  append      => $opts{append},
);

while (1) {
  my $attempts  = 0;
  my $connected = 0;

  while ($attempts < 10) {
    my $quiet = $attempts < 5;

# Pass 1 for ignore_existing on the very first successful connection of the process life?
# Actually, we want to ignore existing only on the FIRST connection of the script run.
# But this loop runs on reconnect too.
# Let's use a state variable.
    state $first_connection = 1;

    if (Connect2IMAP ($quiet, $first_connection)) {
      $connected        = 1;
      $first_connection = 0;
      last;
    }

    $attempts++;
    my $sleep = 60;
    unless ($quiet) {
      $log->msg (
"Connection failed. Retrying in $sleep seconds... (Attempt $attempts/10)"
      );
    }
    sleep $sleep;
  } ## end while ($attempts < 10)

  unless ($connected) {
    $log->err ("Failed to connect after 10 attempts. Exiting.", 1);
  }

  if ($opts{username} =~ /(.*)\@/) {
    $opts{user} = $1;
  } else {
    $opts{user} = $opts{username};
  }    # if

  # Only announce once, not on every reconnect
  state $announced = 0;
  unless ($announced) {
    my $msg = "Now monitoring email for $opts{user}\@$opts{name}";
    speak $msg, $log if $opts{announce};
    $log->msg ($msg);
    $announced = 1;
  } ## end unless ($announced)

  # Main Loop
  while (1) {
    eval {MonitorMail;};
    if ($@) {
      last;    # Break inner loop to reconnect
    }

    # Let's time things
    my $startTime = time;

    # Wait for improvements
    $log->dbug ("Calling IMAP->idle");
    eval {$IMAP->idle (undef, $opts{timeout})};    # No callback, just timeout

    my $msg = 'Returned from IMAP->idle ';

    if ($@) {
      if ($@ =~ /Connection reset by peer/i or $@ =~ /closed by other end/i) {
        $log->msg ("IMAP connection lost (reset by peer). Reconnecting...");
        last;    # Break inner loop to reconnect
      }

      # Other errors
      speak ($msg . $@, $log);
      $log->msg ($msg . $@);

      # Determine if we should reconnect or retry
      last;
    } else {
      $log->msg ($msg . 'no error');
    }

    # Time out check?
    unless ($IMAP->get_response_code ('timeout')) {
      $msg = "IMAP Idle for $opts{name} timed out in " . howlong $startTime,
        time;
      $log->msg ($msg);
    }
  } ## end while (1)

  $log->msg ("MonitorMail loop ended. Reconnecting...");
} ## end while (1)

# Should not get here
$log->err ("Falling off the edge of $0", 1);
