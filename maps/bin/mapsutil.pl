#!/usr/bin/perl
################################################################################
# File:         $RCSfile: mapsutil,v $
# Revision:     $Revision: 1.1 $
# Description:  This script implements a small command interpreter to exercise
#               MAPS functions.
# Author:       Andrew@DeFaria.com
# Created:      Fri Nov 29 14:17:21  2002
# Modified:     $Date: 2013/06/12 14:05:47 $
# Language:     perl
#
# (c) Copyright 2000-2006, Andrew@DeFaria.com, all rights reserved.
#
################################################################################
use strict;
use warnings;

use 5.026;

# For use of the given/when (See https://perlmaven.com/switch-case-statement-in-perl5)
no warnings 'experimental';

use FindBin;

use Term::ReadKey;

use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../lib";

use MAPS;
use MAPSLog;
use MyDB;

use CmdLine;
use Utils;

my %cmds = (
  adduser => {
    help        => 'Add a user to MAPS',
    description => 'Usage: adduser <userid> <name> <email> <password>',
  },
  add2whitelist => {
    help        => 'Add sender to whitelist',
    description => 'Usage: add2whitelist <sender> <retention>',
  },
  cleanlog => {
    help        => 'Cleans out old log entries',
    description => 'Usage; cleanlog [timestamp]'
  },
  log => {
    help        => 'Logs a message',
    description => 'Usage: log <message>',
  },
  loadlist => {
    help        => 'Load a list file',
    description => 'Usage: loadlist <listfile>',
  },
  cleanemail => {
    help        => 'Cleans out old email entries',
    description => 'Usage: cleanemail [timestamp]',
  },
  deliver => {
    help        => 'Delivers a message',
    description => 'Usage: deliver <message>',
  },
  loademail => {
    help        => 'Load an mbox file',
    description => 'Usage: loademail <mbox>',
  },
  dumpemail => {
    help        => 'Dump email from DB to mbox file',
    description => 'Usage: ',
  },
  decrypt => {
    help        => 'Decrypt a password',
    description => 'Usage: decrypt <password>',
  },
  switchuser => {
    help        => 'Switch to user',
    description => 'Usage: switchuser <userid>',
  },
  setpassword => {
    help        => "Set a user's password",
    description => 'Usage: setpassword',
  },
  showuser => {
    help        => 'Show current user',
    description => 'Usage: showuser',
  },
  showusers => {
    help        => 'Shows users in the DB',
    description => 'Usage: showusers',
  },
  showemail => {
    help        => 'Displays email',
    description => 'Usage: showemail',
  },
  showlog => {
    help        => 'Displays <nbr> log entires',
    description => 'Usage: showlog <nbr>',
  },
  space => {
    help        => 'Display space usage',
    description => 'Usage: space',
  },
  showlist => {
    help        => 'Show list by <type>',
    description => 'Usage: showlist <type>',
  },
  encrypt => {
    help        => 'Encrypt a password',
    description => 'Usage: encrypt <password>',
  },
  resequence => {
    help        => 'Resequences a <list>',
    description => 'Usage: resequence <list>',
  },
);

my $userid = GetContext;

sub EncryptPassword($$) {
  my ($password, $userid) = @_;

  my $encrypted_password = Encrypt $password, $userid;

  say "Encrypted password: '$encrypted_password'";

  return;
} # EncryptPassword

sub DecryptPassword($$) {
  my ($password, $userid) = @_;

  my $decrypted_password = Decrypt($password, $userid);

  say "Decrypted password: $decrypted_password";

  return;
} # DecryptPassword

sub Resequence($$) {
  my ($userid, $type) = @_;

  ResequenceList(
    userid => $userid,
    type   => $type,
  );
} # Resequence

sub Login2MAPS($;$) {
  my ($username, $password) = @_;

  if ($username ne '') {
    $password = GetPassword unless $password;
  } # if

  while (Login($username, $password) != 0) {
    say "Login failed!";

    print "Username:";

    $username = <>;

    if ($username eq '') {
      say "Login aborted!";

      return undef;
    } # if

    chomp $username;

    $password = GetPassword;
  } # if

  return $username;
} # Login2MAPS

sub LoadListFile($) {
  # This function loads a ".list" file. This is to "import" our old ".list"
  # files. Note it assumes that the ".list" files have specific names.
  my ($listfilename) = @_;

  my $listtype;

  if ($listfilename eq "white.list") {
    $listtype = "white";
  } elsif ($listfilename eq "black.list") {
    $listtype = "black";
  } elsif ($listfilename eq "null.list") {
    $listtype = "null";
  } else {
    say "Unknown list file: $listfilename";
    return;
  } # if

  my $listfile;

  if (!open $listfile, '<', $listfilename) {
    say "Unable to open $listfilename";
    return;
  } # if

  my $sequence = 0;

  Info("Adding $listfilename to $listtype list");

  while ($listfile) {
    chomp;
    next if m/^#/ || m/^$/;

    my ($pattern, $comment) = split /\,/;

    AddList($listtype, $pattern, 0, $comment);
    $sequence++;
  } # while

  if ($sequence == 0) {
    say "No messages found to load";
  } elsif ($sequence == 1) {
    say "Loaded 1 message ";
  } else {
    say "Loaded $sequence messages";
  } # if

  say "from $listfilename";

  close $listfile;
} # LoadListFile

sub LoadEmail($) {
  # This function loads an mbox file.
  my ($filename) = @_;

  my $file;

  open $file, '<', $filename
    or die "Unable to open \"$filename\" - $!\n";

  binmode $file;

  my $nbr_msgs;

  while (!eof $file) {
    my %msgInfo = ReadMsg *$file;

    $nbr_msgs++;

    AddEmail(
      userid  => $userid,
      sender  => $msgInfo{sender},
      subject => $msgInfo{subject},
      data    => $msgInfo{data},
    );

    Info("Added message from $msgInfo{sender} to email");
  } # while

  if ($nbr_msgs == 0) {
    say "No messages found to load";
  } elsif ($nbr_msgs == 1) {
    say "Loaded 1 message";
  } else {
    say "Loaded $nbr_msgs messages";
  } # if

  say "from $file";
} # LoadEmail

sub DumpEmail($) {
  # This function unloads email to a mbox file.
  my ($filename) = @_;

  my $file;

  open $file, '>', $filename or
    die "Unable to open \"$filename\" - $!\n";

  binmode $file;

  my $i = 0;

  my ($err, $msg) = $MAPS::db->find(
    'email',
    "userid = '$userid'",
    qw(data),
  );

  croak $msg if $msg;

  while (my $rec = $MAPS::db->getnext) {
    say $file $rec->{data};
    $i++;
  } # while

  say "$i messages dumped to $file";

  close $file;
} # DumpEmail

sub SwitchUser($) {
  my ($new_user) = @_;

  if ($new_user = Login2MAPS($new_user)) {
    say "You are now logged in as $new_user";
  } # if
} # SwitchContext

sub SetPassword() {
  FindUser(userid => $userid);

  my $rec = GetUser;

  return unless $rec;

  my $password = GetPassword('Enter new password');
  my $repeat   = GetPassword('Enter new password again');

  if ($password ne $repeat) {
    say "Passwords don't match!";
  } else {
    $rec->{password} = Encrypt($password, $userid);

    UpdateUser(%$rec);

    say "Password updated";
  } # if

  return;
} # SetPassword

sub ShowSpace() {
  my $userid = GetContext;

  my $total_space = Space($userid);

  $total_space = $total_space / (1024 * 1024);

  format TOTALSIZE=
Total size @###.### Meg
$total_space
.
$~ = "TOTALSIZE";

  write();
} # ShowSpace

sub ShowUser() {
  say "Current userid is " . GetContext();
} # ShowContext

sub ShowUsers() {
  FindUser(
    fields => ['userid', 'name', 'email'],
  );

  my $rec;

  format USERLIST =
User ID: @<<<<<<<<< Name: @<<<<<<<<<<<<<<<<<<< Email: @<<<<<<<<<<<<<<<<<<<<<<<
$rec->{userid},$rec->{name},$rec->{email}
.
$~ = "USERLIST";
  while ($rec = GetUser) {
    last unless $rec->{userid};
    write;
  } # while
} # ShowUsers

sub ShowEmail() {
  my ($err, $msg) = $MAPS::db->find(
    'email',
    "userid='$userid'",
    qw(userid timestamp sender subject),
  );

my ($timestamp, $sender, $subject);

format EMAIL =
@<<<<<<<<<<<<<<<<<<<@<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$timestamp,$sender,$subject
.

$~ = "EMAIL";
  while (my $rec = $MAPS::db->getnext) {
    last unless $rec->{userid};

   $timestamp = $rec->{timestamp};
   $sender    = $rec->{sender};
   $subject   = $rec->{subject};

    write();
  } # while
} # ShowEmail

sub ShowLog($) {
  my ($how_many) = @_;

  $how_many = defined $how_many ? $how_many : -20;

  my $handle = FindLog($how_many);

  my ($userid, $timestamp, $sender, $type, $message);

format LOG =
@<<<<<<<<<<<<<<<<<<<@<<<<<<<<< @<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$timestamp,$type,$sender,$message
.
$~ = "LOG";

  my $count = 0;

  while (my $rec = GetLog) {
    $timestamp = $rec->{timestamp} || '';
    $type      = $rec->{type}      || '';
    $sender    = $rec->{sender}    || '';
    $message   = $rec->{message}   || '';

    $count++;

    last if $count > $how_many;

    write;
  } # while

  return;
} # ShowLog

sub ShowList($) {
  my ($type) = @_;

  my $lines = 10;
  my $next  = 0;
  my @list;
  my %record;

format LIST =
@>> @<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<
$record{sequence},$record{pattern},$record{domain},$record{comment}
.
$~ = "LIST";

  # TODO: Why does ReturnList return a one entry array with a many entry array
  # of hashes. Seems it should just return $list[0], right?
  while (@list = ReturnList(
    userid   => $userid,
    type     => $type,
    start_at => $next,
    lines    => $lines)) {
    for (@{$list[0]}) {
      %record = %$_;

      # Format blows up if any field is undefined so...
      $record{pattern} //= '';
      $record{domain}  //= '';
      $record{comment} //= '';
      write();
    } # for

    print 'Hit any key to continue - q to quit';

    ReadMode 'raw';
    my $key = ReadKey(0);
    ReadMode 'normal';

    if ($key eq 'q' or ord $key == 67) {
      print "\n";

      last;
    } # if

    print "\r";

    $next += $lines;
  } # while

  return;
} # ShowList

sub ShowStats($) {
  my ($nbr_days) = @_;

  $nbr_days ||= 1;

  my %dates = GetStats(
    userid => $userid,
    days   => $nbr_days,
  );

  for my $date (keys(%dates)) {
    for (keys(%{$dates{$date}})) {
      say "$date $_:";
      say "\t$dates{$date}{$_}";
    } # for
  } # for
} # ShowStats

sub Deliver($) {
  my ($filename) = @_;

  my $message;

  if (!open $message, '<', $filename) {
    say "Unable to open message file $filename";
    return;
  } # if

  my $data;

  while ($message) {
    $data = $data . $_;
  } # while

  Whitelist "Andrew\@DeFaria.com", $data;

  close $message;

  return;
} # Deliver

sub ExecuteCmd($){
  my ($line) = @_;

  my ($cmd, $parm1, $parm2, $parm3, $parm4) = split /\s+/, $line;

  given ($cmd) {
    when (!$_) {
      return;
    } # when

    when (/^\s*resequence\s*$/) {
      Resequence(GetContext(), $parm1);
    } # when

    when (/^s*encrypt\s*$/) {
      EncryptPassword($parm1, $userid);
    } # when

    when (/^\s*encrypt\s*$/) {
      EncryptPassword($parm1, $userid);
    } # when

    when (/^\s*decrypt\s*$/) {
      DecryptPassword($parm1, $userid);
    } # when

    when (/^\s*deliver\s*$/) {
      Deliver($parm1);
    } # when

    when (/^\s*add2whitelist\s*$/) {
      if ($parm2) {
        $parm2 .= ' ' . $parm3
      } # if

      Add2Whitelist(
        userid    => GetContext,
        type      => 'white',
        sender    => $parm1,
        retention => $parm2,
      );
    } # when

    when (/^\s*showusers\s*$/) {
      ShowUsers;
    } # when

    when (/^\s*adduser\s*$/) {
      AddUser(
        userid   => $parm1,
        name     => $parm2,
        email    => $parm3,
        password => Encrypt($parm4, $userid),
      );
    } # when

    when (/^\s*cleanemail\s*$/) {
      $parm1 = "9999-12-31 23:59:59" unless $parm1;

      say CleanEmail($parm1);
    } # when

    when (/^\s*cleanlog\s*$/) {
      $parm1 = "9999-12-31 23:59:59" unless $parm1;

      say CleanLog($parm1);
    } # when

    when (/^\s*loadlist\s*$/) {
      LoadListFile($parm1);
    } # when

    when (/^\s*loademail\s*$/) {
      LoadEmail($parm1);
    } # when

    when (/^\s*dumpemail\s*$/) {
      DumpEmail($parm1);
    } # when

    when (/^\s*log\s*$/) {
      Logmsg(
        userid  => $userid,
        type    => $parm1,
        sender  => $parm2,
        message => $parm3,
      );
    } # when

    when (/^\s*switchuser\s*$/) {
      SwitchUser($parm1);
    } # when

    when (/^\s*showuser\s*$/) {
      ShowUser;
    } # when

    when (/^\s*showemail\s*$/) {
      ShowEmail;
    } # when

    when (/^\s*showlog\s*$/) {
      ShowLog($parm1);
    } # when

    when (/^\s*showlist\s*$/) {
      ShowList($parm1);
    } # when

    when (/^\s*space\s*$/) {
      ShowSpace;
    } # when

    when (/^\s*showstats\s*$/) {
      ShowStats($parm1);
    } # when

    when (/^\s*setpassword\s*$/) {
      SetPassword;
    } # when

    default {
      say "Unknown command: $_";

      say "Parm1: $parm1" if $parm1;
      say "Parm2: $parm2" if $parm2;
      say "Parm3: $parm3" if $parm3;
      say "Parm4: $parm4" if $parm4;
    } # default
  } # given

  return;
} # ExecuteCmd

my $username = Login2MAPS($userid, $ENV{MAPS_PASSWORD});

if ($ARGV[0]) {
  ExecuteCmd join ' ', @ARGV;
  exit;
} # if

# Use CommandLine
$CmdLine::cmdline->set_cmds(%cmds);
$CmdLine::cmdline->set_eval(\&ExecuteCmd);

while (my ($line, $result) = $CmdLine::cmdline->get) {
  next unless $line;

  last if $line =~ /^\s*exit\s*$/i or $line =~ /^\s*quit\s*$/i;

  ExecuteCmd $line;
} # while

exit;
