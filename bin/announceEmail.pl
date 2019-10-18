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

$Revision: 1.0 $

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
   -usa|ge:    Print this usage
   -h|elp:     Detailed help
   -v|erbose:  Verbose mode (Default: -verbose)
   -de|bug:    Turn on debugging (Default: Off)
   -da|emon:   Run in daemon mode (Default: -daemon)
   -use|rname: User name to log in with (Default: $USER)
   -p|assword: Password to use (Default: prompted)
   -i|map:     IMAP server to talk to (Default: defaria.com)
   -s|leep:    Number of minutes to sleep inbetween checking mail (Default: 1)

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
use Net::IMAP::Simple;
use Email::Simple;
use MIME::Base64;

use lib "$FindBin::Bin/../lib";

use Display;
use Logger;
use Utils;

my $defaultIMAPServer = 'defaria.com';
my $defaultSleeptime  = 1;
my $IMAP;
my %unseen;
my $log;

my %opts = (
  usage    => sub { pod2usage },
  help     => sub { pod2usage(-verbose => 2)},
  verbose  => sub { set_verbose },
  debug    => sub { set_debug },
  daemon   => 1,
  username => $ENV{USER},
  password => $ENV{PASSWORD},
  imap     => $defaultIMAPServer,
  sleep    => $defaultSleeptime,
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

sub debugit($) {
  my ($msg) = @_;

  $log->msg($msg) if get_debug;

  return;
} # logit

sub unseenMsgs() {
  my %unseenMsgs;

  for (my $i = 1; $i <= $IMAP->status; $i++) {
    $unseenMsgs{$i} = 0 unless $IMAP->seen($i);
  } # for

  return %unseenMsgs;
} # unseenMsgs 

sub Connect2IMAP() {
  $log->msg("Connecting to $opts{imap} as $opts{username}...", 1);

  $IMAP = Net::IMAP::Simple->new($opts{imap}) ||
    $log->err("Unable to connect to IMAP server $opts{imap}: " . $Net::IMAP::Simple::errstr, 1);

  $log->msg(' connected');

  $log->msg("Logging onto $opts{imap} as $opts{username}...", 1);

  unless ($IMAP->login($opts{username}, $opts{password})) {
    $log->err("Login to $opts{imap} as $opts{username} failed: " . $IMAP->errstr, 1);
  } # unless

  $log->msg(' logged on');

  # Focus on INBOX only
  $IMAP->select('INBOX');

  # Setup %unseen to have each unseen message index set to 0 meaning not read
  # aloud yet
  %unseen = unseenMsgs;

  return;
} # Connect2IMAP

sub MonitorMail() {
  my $msg = "Now monitoring email for $opts{username}\@$opts{imap}";

  $log->msg($msg);

  my $cmd = "/usr/local/bin/gt \"$msg\"";

  my ($status, @output) = Execute $cmd;

  while () {
    # First close and reselect the INBOX to get its current status
    debugit "Reconnecting to INBOX";
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

    debugit "Processing newUnseen";
    for (keys %newUnseen) {
      next if $unseen{$_};

      my @msglines = $IMAP->top($_);

      # What happens at INBOX 0? Does top return empty array?
      $log->err("Unable to get top for $_ - " . $IMAP->errstr(), 1) unless @msglines;

      my $email = Email::Simple->new(join '', @msglines);

      my $from = $email->header('From');

      # Extract the name only when the email is of the format "name <email>"
      if ($from =~ /^"?(.*?)"?\s*\<(\S*)>/) {
        $from = $1 if $1 ne '';
      } # if

      my $subject = $email->header('Subject');

      if ($subject =~ /=?\S+?(Q|B)\?(.+)\?=/) {
        $subject = decode_base64($2);
      } # if

      # Google Talk doesn't like #
      $subject =~ s/\#//g;

      # Now speak it!
      debugit "Speaking message from $from";
      my $logmsg = "From $from $subject";

      $msg = "Message from $from... " . quotemeta $subject;
      $msg =~ s/\"/\\"/g;

      debugit $logmsg;

      $cmd = "/usr/local/bin/gt \"$msg\"";

      my $hour = (localtime)[2];

      # Only announce if after 6 Am. Not this will announce up until
      # midnight but that's ok. I want midnight to 6 Am as silent time.
      if ($hour > 6) {
        ($status, @output) = Execute $cmd;

        if ($status) {
          $log->err("Unable to execute $cmd" . join("\n", @output));
        } # if
      } # if

      $unseen{$_} = 1;
    } # for

    debugit "Sleeping for $opts{sleep} minutes";
    sleep 60 * $opts{sleep};
    debugit "Ah that was refreshing!";
  } # while

  return;
} # MonitorMail

$SIG{USR2} = \&MonitorMail;

END {
  $IMAP->quit if $IMAP;

  $log->msg("$FindBin::Script ending!");
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
  'password=s',
  'imap=s',
  'sleep',
);

unless ($opts{password}) {
  verbose "I need $opts{username}'s password";
  $opts{password} = GetPassword;
} # unless

$opts{debug} = get_debug;

EnterDaemonMode if $opts{daemon};

$log = Logger->new(
  path        => '/var/log',
  timestamped => 'yes',
  append      => 'yes',
);

Connect2IMAP;

MonitorMail;
