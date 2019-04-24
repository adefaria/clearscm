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

=hade1 SYNOPSIS

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

sub unseenMsgs() {
  my %unseenMsgs;

  for (my $i = 1; $i <= $IMAP->status; $i++) {
    $unseenMsgs{$i} = 0 unless $IMAP->seen($i);
  } # for

  return %unseenMsgs;
} # unseenMsgs 

sub Connect2IMAP() {
  $log->msg("Connecting to $opts{imap} as $opts{username}");

  $IMAP = Net::IMAP::Simple->new($opts{imap}) ||
    error("Unable to connect to IMAP server $opts{imap}: " . $Net::IMAP::Simple::errstr, 1);

  $log->msg("Connected");

  $log->msg("Logging onto $opts{imap} as $opts{username}");

  unless ($IMAP->login($opts{username}, $opts{password})) {
    $log->err("Login to $opts{imap} as $opts{username} failed: " . $IMAP->errstr, 1);
  } # unless

  $log->msg("Logged on");

  # Focus on INBOX only
  $IMAP->select('INBOX');

  # Setup %unseen to have each unseen message index set to 0 meaning not read
  # aloud yet
  %unseen = unseenMsgs;
} # Connect2IMAP

sub MonitorMail() {
  $log->msg("Monitoring email");

  while () {
    # First close and reselect the INBOX to get its current status
    $IMAP->close;
    $IMAP->select('INBOX');

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

      my $email = Email::Simple->new(join '', @{$IMAP->top($_)});

      my $from = $email->header('From');

      # Extract the name only when the email is of the format "name <email>"
      if ($from =~ /^(.*)\<(\S*)>/) {
        $from = $1 if $1 ne '';
      } # if

      my $subject = $email->header('Subject');

      if ($subject =~ /=?\S+?(Q|B)\?(.+)\?=/) {
        $subject = decode_base64($2);
      } # if

      # Now speak it!
      my $logmsg = "From $from $subject";
      my $msg = "Message from $from... " . quotemeta $subject;
      $msg =~ s/\"/\\"/g;

      if (get_verbose) {
        $log->msg($logmsg);
      } else {
        $log->log($logmsg);
      } # if

      my $cmd = "/usr/local/bin/gt \"$msg\"";

      my ($status, @output) = Execute $cmd;

      if ($status) {
        $log->err("Unable to execute $cmd" . join("\n", @output));
      } # if

      $unseen{$_} = 1;
    } # for

    verbose "Sleeping for $opts{sleep} minutes";
    sleep 60 * $opts{sleep};
    verbose "Ah that was refreshing!";
  } # while
} # MonitorMail

END {
  $IMAP->quit if $IMAP;
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

EnterDaemonMode if $opts{daemon};

$log = Logger->new(
  path        => '/var/log',
  timestamped => 'yes',
  append      => 'yes',
);

Connect2IMAP;
MonitorMail;
