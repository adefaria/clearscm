#!/usr/bin/perl

=pod

=head1 announceEmail.pl

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
                         [-uses|sl]

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

use FindBin;
use Getopt::Long;
use Mail::IMAPTalk;
use MIME::Base64;
use Pod::Usage;
use Proc::ProcessTable;
use Encode qw(decode);

use lib "$FindBin::Bin/../lib";

use Display;
use Logger;
use Speak qw(speak);
use TimeUtils;
use Utils;

my $defaultIMAPServer = 'defaria.com';
my $IMAPTimeout       = 20 * 60;
my $IMAP;
my %unseen;
my %spoken_ids;             # Track spoken Message-IDs to avoid duplicates
my $last_check_time = 0;    # Throttle connection check
my $log;
my $got_update = 0;

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
);

GetOptions (
  \%opts,       'usage',  'help',      'verbose', 'debug',      'daemon!',
  'username=s', 'name=s', 'debug',     'daemon!', 'username=s', 'name=s',
  'password=s', 'imap=s', 'timeout=i', 'usessl',  'announce!',  'append',
) || pod2usage;

local $| = 1;    # Enable global autoflush

# Logic for Greeting Name:
# If -name specified or derived from username -> " on $name"
# Else (default) -> ""
my $display_name = '';

if (defined $opts{name}) {
  $display_name = " on $opts{name}";

} elsif ($opts{username} =~ /.*\@(.*)$/) {
  $opts{name} = $1;
  $display_name = " on $1";

} else {
  $opts{name} = $opts{imap};
}    # if

unless ($opts{password}) {
  verbose "I need $opts{username}'s password";
  $opts{password} = GetPassword;
}    # unless

if ($opts{username} =~ /(.*)\@/) {
  $opts{user} = $1;
} else {
  $opts{user} = $opts{username};
}    # if

if ($opts{daemon}) {

  # Perl complains if we reference $DB::OUT only once
  {
    no warnings 'once';                        ## no critic (ProhibitNoWarnings)
    EnterDaemonMode unless defined $DB::OUT;   # or get_debug;
  }
  use warnings;
}    # if

my $email = "$opts{user}\@$opts{name}";

# Special case my email addresses
if ($email =~ /^andrew\@defaria/i) {
  $email = 'Andrew@DeFaria.com';
} elsif ($email =~ /^adefaria\@{1,1}gmail/i) {
  $email = 'adefaria@gmail.com';
}

$log = Logger->new (
  path        => '/var/local/log',
  name        => "$Logger::me.$opts{name}",
  timestamped => 'yes',
  append      => $opts{append},
);

my $processes = Proc::ProcessTable->new;

for my $process (@{$processes->table}) {

# Check for process name matching "announceEmail.pl <email>" (the renamed process)
# or just the script name if it hasn't renamed itself yet (race condition protection)
  if ((
         $process->cmndline =~ /\bannounceEmail\.pl\s+\Q$email\E$/
      or $process->cmndline eq $0
    )
    and $process->pid != $$
    )
  {
    verbose "$FindBin::Script $email already running (PID "
      . $process->pid . ")";
    exit 0;
  }    # if
}    # for

local $0 = "announceEmail.pl $email";

my $name      = $display_name;
my @greetings = (
  "Incoming message$name",
  "You have received a new message$name",
  "Hey I found this in your$name inbox",
  "For some unknown reason this guy send you a message$name",
  "Did you know you just got a message$name",
  "Potential spam$name",
  "You received a communique$name",
  "I was looking in your$name inbox and found a message",
  "Not sure you want to hear this message$name",
  "Good news$name",
  "What's this? A new message$name",
);

my $icon          = '/home/andrew/.icons/Thunderbird.jpg';
my $notifyTimeout = 5 * 1000;

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

sub Connect2IMAP;
sub MonitorMail;

sub response_handler {

# The callback receives the atom (e.g. 'EXISTS') as the first argument, not the object.
# We use the global $IMAP object to terminate the IDLE command.
  my $atom = shift;
  $log->dbug ("response_handler called with atom: $atom") if defined $atom;
  $got_update = 1;
  return 1;
}    # response_handler

sub restart {
  $log->msg ("Restart requested by signal");
  if (defined $IMAP) {$IMAP->logout; undef $IMAP;}
  return;
}    # restart

$SIG{USR1} = \&interrupted;
$SIG{USR2} = \&restart;

sub unseenMsgs() {
  $IMAP->select ('inbox')
    or $log->err ("Unable to select inbox: " . $IMAP->get_last_error (), 1);

  # Use SEARCH to get sequence numbers
  my @msgs     = @{$IMAP->search ('unseen')};
  my @all_msgs = @{$IMAP->search ('all')};
  $log->dbug ("unseenMsgs found "
      . scalar (@msgs)
      . " unseen messages ("
      . join (', ', @msgs)
      . "). Total messages: "
      . scalar (@all_msgs));
  return map {$_ => 0} @msgs;
}    # unseenMsgs

sub Connect2IMAP() {
  $log->dbug ("Connecting to $opts{imap} as $opts{username}");

  # Destroy any old connections
  undef $IMAP;

  $IMAP = Mail::IMAPTalk->new (
    Server   => $opts{imap},
    Username => $opts{username},
    Password => $opts{password},
    UseSSL   => $opts{usessl},
  ) or $log->err ("Unable to connect to IMAP server $opts{imap}: $@", 1);

  $log->dbug ("Connected to $opts{imap} as $opts{username}");

  # Focus on INBOX only
  $IMAP->select ('inbox');

  # Setup %unseen to have each unseen message index set to 0 meaning not read
  # aloud yet. Preserve status of messages we already know about.
  my %serverUnseen = unseenMsgs;
  for my $seq (keys %serverUnseen) {

    # If we haven't tracked it yet, track it as 0 (not spoken)
    # If we HAVE tracked it ($unseen{$seq} exists), keep existing value
    $unseen{$seq} //= 0;
  } ## end for my $seq (keys %serverUnseen)

  # Remove local entries that are no longer on the server
  for (keys %unseen) {
    delete $unseen{$_} unless exists $serverUnseen{$_};
  }

  return;
}    # Connect2IMAP

sub MonitorMail() {
  $log->dbug ("Top of MonitorMail");

  # First close and reselect the INBOX to get its current status
  unless (defined $IMAP) {
    $log->err (
      "IMAP object is undefined in MonitorMail, attempting reconnect...");
    Connect2IMAP;       # Re-attempt connection
    return
      unless
      defined $IMAP;    # Give up if still undefined (Connect2IMAP logs error)
  } ## end unless (defined $IMAP)

  # Check connection liveliness before selecting (with timeout)
  # Only check once every 30 minutes to reduce noise and assume stability
  if (time - $last_check_time > 30 * 60) {
    $log->dbug ("Checking connection state (noop)");
    my $noop_ok = 0;
    my $eval_ok = eval {
      local $SIG{ALRM} = sub {die "alarm\n"};
      alarm 5;
      $noop_ok = $IMAP->noop;
      alarm 0;
      1;
    };
    alarm 0;    # Ensure alarm is off

    if (!$eval_ok || $@ || !$noop_ok) {
      my $reason = $@;
      $reason =~ s/\n//g;    # strip newline
      $reason ||= "noop failed (returned false)";
      my $errstr = $IMAP ? $IMAP->get_last_error () : "IMAP undef";
      $log->warn (
"Connection appears dead (Reason: $reason, IMAP Error: $errstr), reconnecting..."
      );
      Connect2IMAP;
      return unless defined $IMAP;
    } ## end if (!$eval_ok || $@ ||...)

    $last_check_time = time;
  } ## end if (time - $last_check_time...)
  $log->dbug ("Selecting INBOX");
  $IMAP->select ('INBOX')
    or $log->err ("Unable to select INBOX - " . $IMAP->get_last_error (), 1);

  $log->dbug ("Selected INBOX");

  # Go through all of the unseen messages and add them to %unseen if they were
  # not there already from a prior run and read
  my %newUnseen = unseenMsgs;

  # Now clean out any messages in %unseen that were not in the %newUnseen and
  # marked as previously read
  $log->dbug ("Cleaning out unseen");
  for (keys %unseen) {
    if (defined $newUnseen{$_}) {
      if ($unseen{$_}) {
        delete $newUnseen{$_};
      }    # if
    } else {
      delete $unseen{$_};
    }    # if
  }    # for

  SpeakNewMessages (\%newUnseen);

  # Let's time things
  my $startTime = time;

  # Re-establish callback
  # Re-establish callback
  # Wrap in alarm to prevent infinite hang on dead socket
  $got_update = 0;
  $log->dbug ("Calling IMAP->idle");
  my $idle_ok = eval {
    local $SIG{ALRM} = sub {die "alarm\n"};
    alarm ($opts{timeout} + 60);
    $IMAP->idle (\&response_handler, $opts{timeout});
    alarm 0;
    1;
  };
  alarm 0;

  my $msg = 'Returned from IMAP->idle ';

  if ($got_update) {
    $log->dbug ($msg . "NEW MAIL DETECTED");
    return 1;
  }

  if (!$idle_ok || $@) {
    my $err = $@;
    $err =~ s/\n//g;
    if ($err eq "alarm") {
      $log->dbug ($msg . "TIMEOUT (Alarm fired)");

      # This implies we hung. Return failure to trigger reconnect.
      # restart; # No longer recurse
      return 0;
    } else {
      speak ($msg . $err, $log);
    }
  } else {
    $log->dbug ($msg . 'no error');
  }    # if

  # If we return from idle then the server went away for some reason. With Gmail
  # the server seems to time out around 30-40 minutes. Here we simply reconnect
  # to the imap server and continue to MonitorMail.
  unless (defined $IMAP && $IMAP->get_response_code ('timeout')) {
    $msg = "IMAP Idle for $opts{name} timed out in " . howlong $startTime, time;

    $log->dbug ($msg);
  }    # unless

  # restart; # No longer recurse
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

local $0 = "announceEmail.pl $email";

Connect2IMAP;

my $msg = "Now monitoring email for $email";

speak $msg, $log if $opts{announce};

$log->msg ($msg);

my $main_ok = eval {
  while (1) {
    MonitorMail;
    sleep 1;
  }
  1;
};
if (!$main_ok || $@) {
  $log->err ("Fatal error in main loop: $@");
}

sub SpeakNewMessages {
  my ($newUnseen_ref) = @_;

  $log->dbug ("Processing new unseen messages");
  for (keys %$newUnseen_ref) {
    next if $unseen{$_};

    my $envelope = $IMAP->fetch ($_, '(envelope)');
    my $from     = $envelope->{$_}{envelope}{From};
    my $subject  = $envelope->{$_}{envelope}{Subject};
    my $msgid    = $envelope->{$_}{envelope}{'Message-Id'};
    $subject //= 'Unknown subject';

    # Extract the name only when the email is of the format "name <email>"
    if ($from =~ /^"?(.*?)"?\s*\<(\S*)>/) {
      $from = $1 if $1 ne '';
    }    # if

    my $dedupe_key = defined $msgid ? $msgid : "$from|$subject";

    # Skip if we already spoke this message
    if ($spoken_ids{$dedupe_key}) {
      $log->dbug ("Skipping already spoken message: $dedupe_key");
      $unseen{$_} = 1;    # Mark as handled
      next;
    }

    $subject = decode ('MIME-Header', $subject);

    # Google Talk doesn't like #
    $subject =~ s/\#//g;

    # Remove long strings of numbers like order numbers. They are uninteresting
    my $longNumber = 5;
    $subject =~ s/\s+\S*\d{$longNumber,}\S*\s*//g;

    # Now speak it!
    my $logmsg = "From $from $subject";

    my $greeting     = $greetings[int rand $#greetings];
    my $announce_msg = "$greeting from $from... $subject";
    my $hour         = (localtime)[2];
    my $wday         = (localtime)[6];

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

        $log->dbug ('Calling speak');
        speak $announce_msg, $log;
      }
    } elsif ($hour >= 7) {

      $log->dbug ('Calling speak');
      speak $announce_msg, $log;
    } else {
      $log->msg ("$logmsg [silent nighttime]");
    }    # if

    $unseen{$_}              = 1;
    $spoken_ids{$dedupe_key} = 1;
  }    # for

  return;
}    # SpeakNewMessages

