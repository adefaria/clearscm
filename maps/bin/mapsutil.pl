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

use FindBin;

use lib "$FindBin::Bin/../lib";

use MAPS;
use MAPSLog;

use Term::ReadLine;
use Term::ReadLine::Gnu;
use Term::ReadKey;

my $maps_username;

sub EncryptPassword($$) {
  my ($password, $userid) = @_;

  my $encrypted_password = Encrypt $password, $userid;

  print "Password: $password = $encrypted_password\n";

  return;
} # EncryptPassword

sub DecryptPassword($$) {
  my ($password, $userid) = @_;

  my $decrypted_password = Decrypt($password, $userid);

  print "Password: $password = $decrypted_password\n";

  return;
} # DecryptPassword

sub Resequence($$) {
  my ($userid, $type) = @_;

  MAPS::ResequenceList($userid, $type);
} # Resequence

sub GetPassword() {
  print "Password:";
  ReadMode "noecho";
  my $password = ReadLine(0);
  chomp $password;
  print "\n";
  ReadMode "normal";

  return $password;
} # GetPassword

sub Login2MAPS($;$) {
  my ($username, $password) = @_;

  if ($username ne '') {
    $password = GetPassword if !defined $password or $password eq "";
  } # if

  while (Login($username, $password) != 0) {
    print "Login failed!\n";
    print "Username:";
    $username = <>;
    if ($username eq "") {
      print "Login aborted!\n";
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
    print "Unknown list file: $listfilename\n";
    return;
  } # if

  my $listfile;

  if (!open $listfile, '<', $listfilename) {
    print "Unable to open $listfilename\n";
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
    print "No messages found to load ";
  } elsif ($sequence == 1) {
    print "Loaded 1 message ";
  } else {
    print "Loaded $sequence messages ";
  } # if
  print "from $listfilename\n";

  close $listfile;
} # LoadListFile

sub LoadEmail($) {
  # This function loads an mbox file.
  my ($filename) = @_;

  my $file;

  if (!open $file, '<', $filename) {
    print "Unable to open \"$filename\" - $!\n";
    return;
  } # if

  binmode $file;

  my $nbr_msgs;

  while (!eof $file) {
    my ($sender, $reply_to, $subject, $data) = ReadMsg (*$file);

    $nbr_msgs++;

    AddEmail($sender, $subject, $data);

    Info("Added message from $sender to email");
  } # while

  if ($nbr_msgs == 0) {
    print "No messages found to load ";
  } elsif ($nbr_msgs == 1) {
    print "Loaded 1 message ";
  } else {
    print "Loaded $nbr_msgs messages ";
  } # if
  print "from $file\n";
} # LoadEmail

sub DumpEmail($) {
  # This function unloads email to a mbox file.
  my ($filename) = @_;

  my $file;

  if (!open $file, '>', $filename) {
    print "Unable to open \"$filename\" - $!\n";
    return;
  } # if

  binmode $file;

  my $i      = 0;
  my $handle = FindEmail;
  
  my ($userid, $sender, $subject, $timestamp, $message);

  while (($userid, $sender, $subject, $timestamp, $message) = GetEmail($handle)) {
    print $file $message;
    $i++;
  } # while

  print "$i messages dumped to $file\n";

  close $file;
} # DumpEmail

sub SwitchUser($) {
  my ($new_user) = @_;

  if ($new_user = Login2MAPS($new_user)) {
    print "You are now logged in as $new_user\n";
  } # if
} # SwitchContext

sub ShowSpace($) {
  my ($detail) = @_;

  my $userid = GetContext;

  if ($detail) {
    my %msg_space = Space($userid);

    for (sort (keys (%msg_space))) {
      my $sender = $_;
      my $size   = $msg_space{$_};
      format PER_MSG=
@######### @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$size,$sender
.
$~ = "PER_MSG";
      write ();
    } # foreach
  } else {
    my $total_space = Space($userid);

    $total_space = $total_space / (1024 * 1024);

    format TOTALSIZE=
Total size @###.### Meg
$total_space
.
$~ = "TOTALSIZE";
    write ();
  } # if
} # ShowSpace

sub ShowUser() {
  print "Current userid is " . GetContext() . "\n";
} # ShowContext

sub ShowUsers() {
  my ($handle) = FindUser;

  my ($userid, $name, $email);

  format USERLIST =
User ID: @<<<<<<<<< Name: @<<<<<<<<<<<<<<<<<<< Email: @<<<<<<<<<<<<<<<<<<<<<<<
$userid,$name,$email
.
$~ = "USERLIST";
  while (($userid, $name, $email) = GetUser($handle)) {
    last if ! defined $userid;
    write();
  } # while

  $handle->finish;
} # ShowUsers

sub ShowEmail() {
  my ($handle) = FindEmail;

  my ($userid, $sender, $subject, $timestamp, $message);

format EMAIL =
@<<<<<<<<<<<<<<<<<<<@<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$timestamp,$sender,$subject
.
$~ = "EMAIL";
  while (($userid, $sender, $subject, $timestamp, $message) = GetEmail($handle)) {
    last unless $userid;
    write();
  } # while

  $handle->finish;
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
  while (($userid, $timestamp, $sender, $type, $message) = GetLog $handle) {
    last unless $userid;
    write();
  } # while

  $handle->finish;
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

  while (@list = ReturnList($type, $next, $lines)) {
    for (@list) {
      %record = %{$_};
      write();
    } # for
    print "Hit any key to continue";
    ReadLine (0);
    $next += $lines;
  } # while
} # ShowList

sub ShowStats($) {
  my ($nbr_days) = @_;

  $nbr_days ||= 1;

  my %dates = GetStats($nbr_days);

  for my $date (keys(%dates)) {
    for (keys(%{$dates{$date}})) {
      print "$date $_:";
      print "\t$dates{$date}{$_}\n";
    } # for
  } # for
} # ShowStats

sub Deliver($) {
  my ($filename) = @_;

  my $message;

  if (!open $message, '<', $filename) {
    print "Unable to open message file $filename\n";
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

sub ParseCommand($$$$$){
  my ($cmd, $parm1, $parm2, $parm3,$parm4) = @_;

  $_ = $cmd . ' ';

  SWITCH: {
    /^$/ && do {
      last SWITCH
    };

    /^resequence / && do {
      Resequence(GetContext(), $parm1);
      last SWITCH
    };

    /^encrypt / && do {
      EncryptPassword($parm1, $parm2);
      last SWITCH
    };

    /^decrypt / && do {
      my $password = UserExists(GetContext());
      DecryptPassword($password, $maps_username);
      last SWITCH
    };

    /^deliver / && do {
      Deliver($parm1);
      last SWITCH
    };

    /^add2whitelist / && do {
      Add2Whitelist($parm1, GetContext(), $parm2);
      last SWITCH
    };

    /^showusers / && do {
      ShowUsers;
      last SWITCH
    };

    /^adduser / && do {
      AddUser($parm1, $parm2, $parm3, $parm4);
      last SWITCH;
    };

    /^cleanemail / && do {
      if ($parm1 eq '') {
        $parm1 = "9999-12-31 23:59:59";
      } # if
      my $nbr_entries = CleanEmail($parm1);
      print "$nbr_entries email entries cleaned\n";
      last SWITCH;
    };

    /^deleteemail / && do {
      my $nbr_entries = DeleteEmail($parm1);
      print "$nbr_entries email entries deleted\n";
      last SWITCH;
    };

    /^cleanlog / && do {
      if ($parm1 eq '') {
        $parm1 = "9999-12-31 23:59:59";
      } # if
      my $nbr_entries = CleanLog($parm1);
      print "$nbr_entries log entries cleaned\n";
      last SWITCH;
    };

    /^loadlist / && do {
      LoadListFile($parm1);
      last SWITCH;
    };

    /^loademail / && do {
      LoadEmail($parm1);
      last SWITCH;
    };

    /^dumpemail / && do {
      DumpEmail($parm1);
      last SWITCH;
    };

    /^log / && do {
      Logmsg("info", "$parm1 $parm2", $parm3);
      last SWITCH;
    };

    /^switchuser / && do {
      SwitchUser($parm1);
      last SWITCH;
    };

    /^showuser / && do {
      ShowUser;
      last SWITCH;
    };

    /^showemail / && do {
      ShowEmail;
      last SWITCH
    };

    /^showlog / && do {
      ShowLog($parm1);
      last SWITCH
    };

    /^showlist / && do {
      ShowList($parm1);
      last SWITCH
    };

    /^space / && do {
      ShowSpace($parm1);
      last SWITCH
    };

    /^showstats / && do {
      ShowStats($parm1);
      last SWITCH
    };

    /^help / && do {
      print "Valid commands are:\n\n";
      print "adduser <userid> <realname> <email> <password>\tAdd user to DB\n";
      print "add2whitelist <sender> <name>\t\tAdd sender to whitelist\n";
      print "cleanlog     [timestamp]\t\tCleans out old log entries\n";
      print "log          <message>\t\t\tLogs a message\n";
      print "loadlist     <listfile>\t\t\tLoad a list file\n";
      print "cleanemail   [timestamp]\t\tCleans out old email entries\n";
      print "deliver      <message>\t\t\tDelivers a message\n";
      print "loademail    <mbox>\t\t\tLoad an mbox file\n";
      print "dumpemail    <mbox>\t\t\tDump email from DB to an mbox file\n";
      print "deleteemail  <sender>\t\t\tDelete email from sender\n";
      print "switchuser   <userid>\t\t\tSwitch to user\n";
      print "showuser\t\t\t\tShow current user\n";
      print "showusers\t\t\t\tShows users in the DB\n";
      print "showemail\t\t\t\tDisplays email\n";
      print "showlog      <nbr>\t\t\tDisplays <nbr> log entries\n";
      print "space\t     <detail>\t\t\tDisplay space usage\n";
      print "showlist     <type>\t\t\tShow list by type\n";
      print "showstats    <nbr>\t\t\tDisplays <nbr> days of stats\n";
      print "encrypt      <password>\t\t\tEncrypt a password\n";
      print "resequence   <list>\t\t\tResequences a list\n";
      print "help\t\t\t\t\tThis screen\n";
      print "exit\t\t\t\t\tExit mapsutil\n";
      last SWITCH;
    };

    print "Unknown command: $_";

    print " ($parm1" if $parm1;
    print ", $parm2" if $parm2;
    print ", $parm3" if $parm3;
    print ", $parm4" if $parm4;
    print ")\n";
  } # SWITCH
} # ParseCommand

$maps_username = $ENV{MAPS_USERNAME} ? $ENV{MAPS_USERNAME} : $ENV{USER};

my $username   = Login2MAPS($maps_username, $ENV{MAPS_PASSWORD});

if ($ARGV[0]) {
  ParseCommand($ARGV[0], $ARGV[1], $ARGV[2], $ARGV[3], $ARGV[4]);
  exit;
} # if

# Use ReadLine
my $term = new Term::ReadLine 'mapsutil';

while (1) {
  $_ = $term->readline ("MAPSUtil:");

  last unless $_;

  my ($cmd, $parm1, $parm2, $parm3, $parm4) = split;

  last if ($cmd =~ /exit/i || $cmd =~ /quit/i);

  ParseCommand($cmd, $parm1, $parm2, $parm3, $parm4) if defined $cmd;
} # while

print "\n" unless $_;

exit;
