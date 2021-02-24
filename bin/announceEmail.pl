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

 Usage: announceEmail.pl [-usa|ge] [-h|elp] [-v|erbose] [-de|bug] [-da|emon]
                         [-use|rname <username>] [-p|assword <password>]
                         [-i|map <server]

 Where:
   -usa|ge:      Print this usage
   -h|elp:       Detailed help
   -v|erbose:    Verbose mode (Default: -verbose)
   -de|bug:      Turn on debugging (Default: Off)
   -da|emon:     Run in daemon mode (Default: -daemon)
   -user|name:   User name to log in with (Default: $USER)
   -p|assword:   Password to use (Default: prompted)
   -n|ame:       Name of account (Default: imap)
   -i|map:       IMAP server to talk to (Default: defaria.com)
   -uses|sl:     Whether or not to use SSL to connect (Default: False)
   -useb|locking Whether to block on socket (Default: False)
   -a-nnounce    Announce startup (Default: False)

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
use Pod::Usage;
use Mail::IMAPTalk;
use MIME::Base64;

use lib "$FindBin::Bin/../lib";

use Display;
use Logger;
use Speak;
use TimeUtils;
use Utils;

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
);

my %opts = (
  usage       => sub { pod2usage },
  help        => sub { pod2usage(-verbose => 2)},
  verbose     => sub { set_verbose },
  debug       => sub { set_debug },
  daemon      => 1,
  username    => $ENV{USER},
  password    => $ENV{PASSWORD},
  imap        => $defaultIMAPServer,
  usessl      => 0,
  useblocking => 0,
  announce    => 0,
);

sub interrupted {
  if (get_debug) {
    $log->msg("Turning off debugging");
    set_debug 0;
  } else {
    $log->msg("Turning on debugging");
    set_debug 1;
  } # if

  return;
} # interrupted

$SIG{USR1} = \&interrupted;

sub unseenMsgs() {
  $IMAP->select('inbox') or
    $log->err("Unable to select inbox: " . get_last_error(), 1);

  return map { $_=> 0 } @{$IMAP->search('not', 'seen')};
} # unseenMsgs 

sub Connect2IMAP() {
  $log->dbug("Connecting to $opts{imap} as $opts{username}");

  $IMAP = Mail::IMAPTalk->new(
    Server      => $opts{imap},
    Username    => $opts{username},
    Password    => $opts{password},
    UseSSL      => $opts{usessl},
    UseBlocking => $opts{useblocking},
  ) or $log->err("Unable to connect to IMAP server $opts{imap}: $@", 1);

  $log->dbug("Connected to $opts{imap} as $opts{username}");

  # Focus on INBOX only
  $IMAP->select('inbox');

  # Setup %unseen to have each unseen message index set to 0 meaning not read
  # aloud yet
  %unseen = unseenMsgs;

  return;
} # Connect2IMAP

sub MonitorMail() {
  MONITORMAIL:

  # First close and reselect the INBOX to get its current status
  $IMAP->close;
  $IMAP->select('INBOX')
    or $log->err("Unable to select INBOX - ". $IMAP->errstr(), 1);

  # Go through all of the unseen messages and add them to %unseen if they were
  # not there already from a prior run and read
  my %newUnseen = unseenMsgs;

  # Now clean out any messages in %unseen that were not in the %newUnseen and
  # marked as previously read
  for (keys %unseen) {
    if (defined $newUnseen{$_}) {
      if ($unseen{$_}) {
        delete $newUnseen{$_};
      } # if
    } else {
      delete $unseen{$_}
    } # if
  } # for

  for (keys %newUnseen) {
    next if $unseen{$_};

    my $envelope = $IMAP->fetch($_, '(envelope)');
    my $from     = $envelope->{$_}{envelope}{From};
    my $subject  = $envelope->{$_}{envelope}{Subject};
       $subject //= 'Unknown subject';

    # Extract the name only when the email is of the format "name <email>"
    if ($from =~ /^"?(.*?)"?\s*\<(\S*)>/) {
      $from = $1 if $1 ne '';
    } # if

    if ($subject =~ /=?\S+?(Q|B)\?(.+)\?=/) {
      $subject = decode_base64($2);
    } # if

    # Google Talk doesn't like #
    $subject =~ s/\#//g;

    # Now speak it!
    my $logmsg = "From $from $subject";

    my $greeting = $greetings[int rand $#greetings];
    my $msg      = "$greeting from $from... $subject";
       $msg      =~ s/\"/\\"/g;

    my $hour = (localtime)[2];

    # Only announce if after 6 Am. Note this will announce up until
    # midnight but that's ok. I want midnight to 6 Am as silent time.
    if ($hour >= 7) {
      speak $msg, $log;
      $log->msg($logmsg);
    } else {
      $log->msg("$logmsg [silent]");
    } # if

    $unseen{$_} = 1;
  } # for

  # Re-establish callback
  eval { $IMAP->idle(\&MonitorMail) };

  # If we return from idle then the server went away for some reason. With Gmail
  # the server seems to time out around 30-40 minutes. Here we simply reconnect
  # to the imap server and continue to MonitorMail.
  $log->dbug("MonitorMail: Connection to $opts{imap} ended. Reconnecting");

  # Destroy current IMAP connection
  $log->dbug("MonitorMail: Destorying IMAP connection to $opts{imap}");

  undef $IMAP;

  # Re-establish connection
  Connect2IMAP;

  $log->dbug("MonitorMail: Reconnected to IMAP server $opts{imap}");

  # MonitorMail again - the dreaded goto! Seems the cleanest way to restart
  # in this instance. I could call MonitorMail() recursively but that would
  # leave junk on the stack.
  $log->dbug('MonitorMail: Going back to the top of the loop');

  goto MONITORMAIL;

  return; # To make perlcritic happy
} # MonitorMail

END {
  # If $log is not yet defined then the exit is not unexpected
  if ($log) {
    my $msg = "$FindBin::Script ending unexpectedly!";

    speak $msg, $log;

    $log->err($msg);
  } # if
} # END

## Main
GetOptions(
  \%opts,
  'usage',
  'help',
  'verbose',
  'debug',
  'daemon!',
  'username=s',
  'name=s',
  'password=s',
  'imap=s',
  'usessl',
  'useblocking',
  'announce!',
) || pod2usage;

unless ($opts{password}) {
  verbose "I need $opts{username}'s password";
  $opts{password} = GetPassword;
} # unless

$opts{name} //= $opts{imap};

if ($opts{username} =~ /.*\@(.*)$/) {
  $opts{name} = $1;
} # if

if ($opts{daemon}) {
  # Perl complains if we reference $DB::OUT only once
  my $foo = $DB::OUT;
  EnterDaemonMode unless defined $DB::OUT;
} # if

$log = Logger->new(
  path        => '/var/log',
  name        => "$Logger::me.$opts{name}",
  timestamped => 'yes',
  append      => 'yes',
);

Connect2IMAP;

if ($opts{username} =~ /(.*)\@/) {
  $opts{user} = $1;
} else {
  $opts{user} = $opts{username};
} # if

my $msg = "Now monitoring email for $opts{user}\@$opts{name}";

speak $msg, $log if $opts{announce};

$log->msg($msg);

MonitorMail;

# Should not get here
$log->err("Falling off the edge of $0", 1);
