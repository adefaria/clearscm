#!/usr/bin/perl
#################################################################################
#
# File:         $RCSfile: MAPS.pm,v $
# Revision:     $Revision: 1.1 $
# Description:  Main module for Mail Authentication and Permission System (MAPS)
# Author:       Andrew@DeFaria.com
# Created:      Fri Nov 29 14:17:21  2002
# Modified:     $Date: 2013/06/12 14:05:47 $
# Language:     perl
#
# (c) Copyright 2000-2018, Andrew@DeFaria.com, all rights reserved.
#
################################################################################
package MAPS;

use strict;
use warnings;

use DBI;
use Carp;
use FindBin;
use vars qw(@ISA @EXPORT);
use Exporter;

use MAPSLog;
use MAPSFile;
use MAPSUtil;
use MIME::Entity;

# Globals
my $userid = $ENV{MAPS_USERNAME} ? $ENV{MAPS_USERNAME} : $ENV{USER};
my %useropts;
my $DB;

@ISA = qw(Exporter);

@EXPORT = qw(
  Add2Blacklist
  Add2Nulllist
  Add2Whitelist
  AddEmail
  AddList
  AddLog
  AddUser
  AddUserOptions
  Blacklist
  CleanEmail
  CleanLog
  CleanList
  CountMsg
  Decrypt
  DeleteEmail
  DeleteList
  DeleteLog
  Encrypt
  FindEmail
  FindList
  FindLog
  FindUser
  ForwardMsg
  GetContext
  GetEmail
  GetList
  GetLog
  GetNextSequenceNo
  GetRows
  GetUser
  GetUserOptions
  ListLog
  ListUsers
  Login
  Nulllist
  OnBlacklist
  OnNulllist
  OnWhitelist
  OptimizeDB
  ReadMsg
  ResequenceList
  ReturnList
  ReturnListEntry
  ReturnMsg
  ReturnMessages
  ReturnSenders
  SaveMsg
  SearchEmails
  SetContext
  Space
  UpdateList
  UpdateUser
  UpdateUserOptions
  UserExists
  Whitelist
  count
  countlog
  count_distinct
);

my $mapsbase = "$FindBin::Bin/..";

sub Add2Blacklist($$$) {
  # Add2Blacklist will add an entry to the blacklist
  my ($sender, $userid, $comment) = @_;

  # First SetContext to the userid whose black list we are adding to
  SetContext($userid);

  # Add to black list
  AddList("black", $sender, 0, $comment);

  # Log that we black listed the sender
  Info("Added $sender to " . ucfirst $userid . "'s black list");

  # Delete old emails
  my $count = DeleteEmail($sender);

  # Log out many emails we managed to remove
  Info("Removed $count emails from $sender");

  return;
} # Add2Blacklist

sub Add2Nulllist($$;$$) {
  # Add2Nulllist will add an entry to the nulllist
  my ($sender, $userid, $comment, $hit_count) = @_;

  # First SetContext to the userid whose null list we are adding to
  SetContext($userid);

  # Add to null list
  AddList("null", $sender, 0, $comment, $hit_count);

  # Log that we null listed the sender
  Info("Added $sender to " . ucfirst $userid . "'s null list");

  # Delete old emails
  my $count = DeleteEmail($sender);

  # Log out many emails we managed to remove
  Info("Removed $count emails from $sender");

  return;
} # Add2Nulllist

sub Add2Whitelist($$;$) {
  # Add2Whitelist will add an entry to the whitelist
  my ($sender, $userid, $comment) = @_;

  # First SetContext to the userid whose white list we are adding to
  SetContext($userid);

  # Add to white list
  AddList('white', $sender, 0, $comment);

  # Log that we registered a user
  Logmsg("registered", $sender, "Registered new sender");

  # Check to see if there are any old messages to deliver
  my $handle = FindEmail($sender);

  my ($dbsender, $subject, $timestamp, $message);

  # Deliver old emails
  my $messages      = 0;
  my $return_status = 0;

  while (($userid, $dbsender, $subject, $timestamp, $message) = GetEmail($handle)) {
    last unless $userid;

    $return_status = Whitelist($sender, $message);

    last if $return_status;

    $messages++;
  } # while

  # Done with $handle
  $handle->finish;

  # Return if we has a problem delivering email
  return $return_status if $return_status;

  # Remove delivered messages.
  DeleteEmail($sender);

  return $messages;
} # Add2Whitelist

sub AddEmail($$$) {
  my ($sender, $subject, $data) = @_;

  # "Sanitize" some fields so that characters that are illegal to SQL are escaped
  $sender = 'Unknown' if (!defined $sender || $sender eq '');
  $sender  = $DB->quote($sender);
  $subject = $DB->quote($subject);
  $data    = $DB->quote($data);

  my $timestamp = UnixDatetime2SQLDatetime(scalar(localtime));
  my $statement = "insert into email values (\"$userid\", $sender, $subject, \"$timestamp\", $data)";

  $DB->do ($statement)
    or DBError('AddEmail: Unable to do statement', $statement);

  return;
} # AddEmail

sub AddList($$$;$$$) {
  my ($listtype, $pattern, $sequence, $comment, $hit_count, $last_hit) = @_;

  $hit_count //= CountMsg($pattern);

  my ($user, $domain)  = split /\@/, $pattern;

  if (!$domain || $domain eq '') {
    $domain  = 'NULL';
    $pattern = $DB->quote($user);
  } else {
    $domain  = "'$domain'";

    if ($user eq '') {
      $pattern = 'NULL';
    } else {
      $pattern = $DB->quote($user);
    } # if
  } # if

  if (!$comment || $comment eq '') {
    $comment = 'NULL';
  } else {
    $comment = $DB->quote($comment);
  } # if

  # Get next sequence #
  if ($sequence == 0) {
    $sequence = GetNextSequenceNo($userid, $listtype);
  } # if

  $last_hit //= UnixDatetime2SQLDatetime(scalar (localtime));

  my $statement = "insert into list values (\"$userid\", \"$listtype\", $pattern, $domain, $comment, $sequence, $hit_count, \"$last_hit\")";

  $DB->do($statement)
    or DBError('AddList: Unable to do statement', $statement);

  return;
} # AddList

sub AddLog ($$$) {
  my ($type, $sender, $msg) = @_;

  my $timestamp = UnixDatetime2SQLDatetime(scalar(localtime));
  my $statement;

  # Use quote to protect ourselves
  $msg = $DB->quote($msg);

  if ($sender eq '') {
    $statement = "insert into log values (\"$userid\", \"$timestamp\", null, \"$type\", $msg)";
  } else {
    $statement = "insert into log values (\"$userid\", \"$timestamp\", \"$sender\", \"$type\", $msg)";
  } # if

  $DB->do($statement)
    or DBError('AddLog: Unable to do statement', $statement);

  return;
} # AddLog

sub AddUser($$$$) {
  my ($userid, $realname, $email, $password) = @_;

  $password = Encrypt($password, $userid);

  if (UserExists($userid)) {
    return 1;
  } else {
    my $statement = "insert into user values ('$userid', '$realname', '$email', '$password')";

    $DB->do($statement)
      or DBError('AddUser: Unable to do statement', $statement);
  } # if

  return 0;
} # Adduser

sub AddUserOptions($%) {
  my ($userid, %options) = @_;

  for (keys %options) {
    return 1 if !UserExists($userid);

    my $statement = "insert into useropts values ('$userid', '$_', '$options{$_}')";

    $DB->do($statement)
      or DBError('AddUserOption: Unable to do statement', $statement);
  } # for

  return 0;
} # AddUserOptions

sub Blacklist($%) {
  # Blacklist will send a message back to the $sender telling them that
  # they've been blacklisted. Currently we save a copy of the message.
  # In the future we should just disregard the message.
  my ($sender, $sequence, $hit_count, @msg)  = @_;

  # Check to see if this sender has already emailed us.
  my $msg_count = CountMsg($sender);

  if ($msg_count < 5) {
    # Bounce email
    SendMsg($sender, "Your email has been discarded by MAPS", "$mapsbase/blacklist.html", @msg);
    Logmsg("blacklist", $sender, "Sent blacklist reply");
  } else {
    Logmsg("mailloop", $sender, "Mail loop encountered");
  } # if

  RecordHit("black", $sequence, ++$hit_count) if $sequence;

  return;
} # Blacklist

sub CheckOnList ($$;$) {
  # CheckOnList will check to see if the $sender is on the $listfile.
  # Return 1 if found 0 if not.
  my ($listtype, $sender, $update) = @_;

  $update //= 1;

  my $status = 0;
  my ($rule, $sequence, $hit_count);

  my $statement = 'select pattern, domain, comment, sequence, hit_count '
                . "from list where userid = '$userid' and type = '$listtype' "
                . 'order by sequence';

  my $sth = $DB->prepare($statement)
    or DBError('CheckOnList: Unable to prepare statement', $statement);

  $sth->execute
    or DBError('CheckOnList: Unable to execute statement', $statement);

  while (my @row = $sth->fetchrow_array) {
    last if !@row;

       $hit_count = pop (@row);
       $sequence  = pop (@row);
    my $comment   = pop (@row);
    my $domain    = pop (@row);
    my $pattern   = pop (@row);
    my $email_on_file;

    unless ($domain) {
      $email_on_file = $pattern;
    } else {
      unless ($pattern) {
        $email_on_file = '@' . $domain;
      } else {
        $email_on_file = $pattern . '@' . $domain;
      } # if
    } # unless

    # Escape some special characters
    $email_on_file =~ s/\@/\\@/;
    $email_on_file =~ s/^\*/.\*/;

    # We want to terminate the search string with a "$" iff there's an
    # "@" in there. This is because some "email_on_file" may have no
    # domain (e.g. "mailer-daemon" with no domain). In that case we
    # don't want to terminate the search string with a "$" rather we
    # wish to terminate it with an "@". But in the case of say
    # "@ti.com" if we don't terminate the search string with "$" then
    # "@ti.com" would also match "@tixcom.com"!
    my $search_for = $email_on_file =~ /\@/
                   ? "$email_on_file\$"
                   : !defined $domain
                   ? "$email_on_file\@"
                   : $email_on_file;
    if ($sender and $sender =~ /$search_for/i) {
      $rule   = "Matching rule: ($listtype:$sequence) \"$email_on_file\"";
      $rule  .= " - $comment" if $comment and $comment ne '';
      $status = 1;

      RecordHit($listtype, $sequence, ++$hit_count) if $update;

      last;
    } # if
  } # while

  $sth->finish;

  return ($status, $rule, $sequence, $hit_count);
} # CheckOnList

sub CleanEmail($) {
  my ($timestamp) = @_;

  # First see if anything needs to be deleted
  my $count = 0;

  my $statement = "select count(*) from email where userid = '$userid' and timestamp < '$timestamp'";

  # Prepare statement
  my $sth = $DB->prepare($statement)
    or DBError('CleanEmail: Unable to prepare statement', $statement);

  # Execute statement
  $sth->execute
    or DBError('CleanEmail: Unable to execute statement', $statement);

  # Get return value, which should be how many entries were deleted
  my @row = $sth->fetchrow_array;

  # Done with $sth
  $sth->finish;

  # Retrieve returned value
  unless ($row[0]) {
    $count = 0
  } else {
    $count = $row[0];
  } # unless

  # Just return if there's nothing to delete
  return $count if ($count == 0);

  # Delete emails for userid whose older than $timestamp
  $statement = "delete from email where userid = '$userid' and timestamp < '$timestamp'";

  # Prepare statement
  $sth = $DB->prepare($statement)
    or DBError('CleanEmail: Unable to prepare statement', $statement);

  # Execute statement
  $sth->execute
    or DBError('CleanEmail: Unable to execute statement', $statement);

  return $count;
} # ClearEmail

sub CleanLog($) {
  my ($timestamp) = @_;

  # First see if anything needs to be deleted
  my $count = 0;

  my $statement = "select count(*) from log where userid = '$userid' and timestamp < '$timestamp'";

  # Prepare statement
  my $sth = $DB->prepare($statement)
    or DBError($DB, 'CleanLog: Unable to prepare statement', $statement);

  # Execute statement
  $sth->execute
    or DBError('CleanLog: Unable to execute statement', $statement);

  # Get return value, which should be how many entries were deleted
  my @row = $sth->fetchrow_array;

  # Done with $sth
  $sth->finish;

  # Retrieve returned value
  unless ($row[0]) {
    $count = 0
  } else {
    $count = $row[0];
  } # unless

  # Just return if there's nothing to delete
  return $count if ($count == 0);

  # Delete log entries for userid whose older than $timestamp
  $statement = "delete from log where userid = '$userid' and timestamp < '$timestamp'";

  # Prepare statement
  $sth = $DB->prepare($statement)
    or DBError('CleanLog: Unable to prepare statement', $statement);

  # Execute statement
  $sth->execute
    or DBError('CleanLog: Unable to execute statement', $statement);

  return $count;
} # CleanLog

sub CleanList($;$) {
  my ($timestamp, $listtype) = @_;

  $listtype //= 'null';

  # First see if anything needs to be deleted
  my $count = 0;

  my $statement = "select count(*) from list where userid = '$userid' and type = '$listtype' and last_hit < '$timestamp'";

  # Prepare statement
  my $sth = $DB->prepare($statement)
    or DBError($DB, 'CleanList: Unable to prepare statement', $statement);

  # Execute statement
  $sth->execute
    or DBError('CleanList: Unable to execute statement', $statement);

  # Get return value, which should be how many entries were deleted
  my @row = $sth->fetchrow_array;

  # Done with $sth
  $sth->finish;

  # Retrieve returned value
  $count = $row[0] ? $row[0] : 0;

  # Just return if there's nothing to delete
  return $count if ($count == 0);

  # Get data for these entries
  $statement = "select type, sequence, hit_count from list where userid = '$userid' and type = '$listtype' and last_hit < '$timestamp'";

  # Prepare statement
  $sth = $DB->prepare($statement)
    or DBError('CleanList: Unable to prepare statement', $statement);

  # Execute statement
  $sth->execute
    or DBError('CleanList: Unable to execute statement', $statement);

  $count = 0;

  while (my @row = $sth->fetchrow_array) {
    last if !@row;

    my $hit_count = pop(@row);
    my $sequence  = pop(@row);
    my $listtype  = pop(@row);

    if ($hit_count == 0) {
      $count++;

      $statement = "delete from list where userid='$userid' and type='$listtype' and sequence=$sequence";
      $DB->do($statement)
        or DBError('CleanList: Unable to execute statement', $statement);
    } else {
      # Age entry: Sometimes entries are initially very popular and
      # the $hit_count gets very high quickly. Then the domain is
      # abandoned and no activity happens. One case recently observed
      # was for phentermine.com. The $hit_count initially soared to
      # 1920 within a few weeks. Then it all stopped as of
      # 07/13/2007. Obvisously this domain was shutdown. With the
      # previous aging algorithm of simply subtracting 1 this
      # phentermine.com entry would hang around for over 5 years!
      #
      # So the tack here is to age the entry by 10% until the $hit_count
      # is less than 30 then we revert to the old method of subtracting 1.
      if ($hit_count < 30) {
        $hit_count--;
      } else {
        $hit_count = int($hit_count / 1.1);
      } # if

      $statement = "update list set hit_count=$hit_count where userid='$userid' and type='$listtype' and sequence=$sequence;";
      $DB->do($statement)
        or DBError('CleanList: Unable to execute statement', $statement);
    } # if
  } # while

  ResequenceList($userid, $listtype);

  return $count;
} # CleanList

sub CloseDB() {
  $DB->disconnect;

  return;
} # CloseDB

sub CountMsg($) {
  my ($sender) = @_;

  return count('email', "userid = '$userid' and sender like '%$sender%'");
} # CountMsg

sub DBError($$) {
  my ($msg, $statement) = @_;

  print 'MAPS::' . $msg . "\nError #" . $DB->err . ' ' . $DB->errstr . "\n";

  if ($statement) {
    print "SQL Statement: $statement\n";
  } # if

  exit $DB->err;
} # DBError

sub Decrypt ($$) {
  my ($password, $userid) = @_;

  my $statement = "select decode('$password','$userid')";

  my $sth = $DB->prepare($statement)
    or DBError('Decrypt: Unable to prepare statement', $statement);

  $sth->execute
    or DBError('Decrypt: Unable to execute statement', $statement);

  # Get return value, which should be the encoded password
  my @row = $sth->fetchrow_array;

  # Done with $sth
  $sth->finish;

  return $row[0]
} # Decrypt

sub DeleteEmail($) {
  my $sender = shift;

  my ($username, $domain) = split /@/, $sender;
  my $condition;

  if ($username eq '') {
    $condition = "userid = '$userid' and sender like '%\@$domain'";
  } else {
    $condition = "userid = '$userid' and sender = '$sender'";
  } # if

  # First see if anything needs to be deleted
  my $count = count('email', $condition);

  # Just return if there's nothing to delete
  return $count if ($count == 0);

  my $statement = 'delete from email where ' . $condition;

  $DB->do($statement)
    or DBError('DeleteEmail: Unable to execute statement', $statement);

  return $count;
} # DeleteEmail

sub DeleteList($$) {
  my ($type, $sequence) = @_;

  # First see if anything needs to be deleted
  my $count = count('list', "userid = '$userid' and type = '$type' and sequence = '$sequence'");

  # Just return if there's nothing to delete
  return $count if ($count == 0);

  my $statement = "delete from list where userid = '$userid' and type = '$type' and sequence = '$sequence'";

  $DB->do($statement)
    or DBError('DeleteList: Unable to execute statement', $statement);

  return $count;
} # DeleteList

sub DeleteLog($) {
  my ($sender) = @_;

  my ($username, $domain) = split /@/, $sender;
  my $condition;

  if ($username eq '') {
    $condition = "userid = '$userid' and sender like '%\@$domain'";
  } else {
    $condition = "userid = '$userid' and sender = '$sender'";
  } # if

  # First see if anything needs to be deleted
  my $count = count('log', $condition);

  # Just return if there's nothing to delete
  return $count if ($count == 0);

  my $statement = 'delete from log where ' . $condition;

  $DB->do($statement)
    or DBError('DeleteLog: Unable to execute statement', $statement);

  return $count;
} # DeleteLog

sub Encrypt($$) {
  my ($password, $userid) = @_;

  my $statement = "select encode('$password','$userid')";

  my $sth = $DB->prepare($statement)
    or DBError('Encrypt: Unable to prepare statement', $statement);

  $sth->execute
    or DBError('Encrypt: Unable to execute statement', $statement);

  # Get return value, which should be the encoded password
  my @row = $sth->fetchrow_array;

  # Done with $sth
  $sth->finish;

  return $row[0];
} # Encrypt

sub FindEmail(;$) {
  my ($sender) = @_;

  my $statement;

  if (!defined $sender || $sender eq '') {
    $statement = "select * from email where userid = '$userid'";
  } else {
    $statement = "select * from email where userid = '$userid' and sender = '$sender'";
  } # if

  my $sth = $DB->prepare($statement)
    or DBError('FindEmail: Unable to prepare statement', $statement);

  $sth->execute
    or DBError('FindEmail: Unable to execute statement', $statement);

  return $sth;
} # FindEmail

sub FindList($;$) {
  my ($type, $sender) = @_;

  my $statement;

  unless ($sender) {
    $statement = "select * from list where userid = '$userid' and type = '$type'";
  } else {
    my ($pattern, $domain) = split /\@/, $sender;
    $statement = "select * from list where userid = '$userid' and type = '$type' " .
                 "and pattern = '$pattern' and domain = '$domain'";
  } # unless

  # Prepare statement
  my $sth = $DB->prepare($statement)
    or DBError('FindList: Unable to prepare statement', $statement);

  # Execute statement
  $sth->execute
    or DBError('FindList: Unable to execute statement', $statement);

  # Get return value, which should be how many entries were deleted
  return $sth;
} # FindList

sub FindLog($) {
  my ($how_many) = @_;

  my $start_at = 0;
  my $end_at   = countlog();

  if ($how_many < 0) {
    $start_at = $end_at - abs ($how_many);
    $start_at = 0 if ($start_at < 0);
  } # if

  my $statement = "select * from log where userid = '$userid' order by timestamp limit $start_at, $end_at";

  # Prepare statement
  my $sth = $DB->prepare($statement)
    or DBError('FindLog: Unable to prepare statement', $statement);

  # Execute statement
  $sth->execute
    or DBError('FindLog: Unable to execute statement', $statement);

  # Get return value, which should be how many entries were deleted
  return $sth;
} # FindLog

sub FindUser(;$) {
  my ($userid) = @_;

  my $statement;

  if (!defined $userid || $userid eq '') {
    $statement = 'select * from user';
  } else {
    $statement = "select * from user where userid = '$userid'";
  } # if

  my $sth = $DB->prepare($statement)
    or DBError('FindUser: Unable to prepare statement', $statement);

  $sth->execute
    or DBError('FindUser: Unable to execute statement', $statement);

  return $sth;
} # FindUser

sub GetContext() {
  return $userid;
} # GetContext

sub GetEmail($) {
  my ($sth) = @_;

  my @email;

  if (@email = $sth->fetchrow_array) {
    my $message   = pop @email;
    my $timestamp = pop @email;
    my $subject   = pop @email;
    my $sender    = pop @email;
    my $userid    = pop @email;
    return $userid, $sender, $subject, $timestamp, $message;
  } else {
    return;
  } # if
} # GetEmail

sub GetList($) {
  my ($sth) = @_;

  my @list;

  if (@list = $sth->fetchrow_array) {
    my $last_hit  = pop @list;
    my $hit_count = pop @list;
    my $sequence  = pop @list;
    my $comment   = pop @list;
    my $domain    = pop @list;
    my $pattern   = pop @list;
    my $type      = pop @list;
    my $userid    = pop @list;
    return $userid, $type, $pattern, $domain, $comment, $sequence, $hit_count, $last_hit;
  } else {
    return;
  } # if
} # GetList

sub GetLog($) {
  my ($sth) = @_;

  my @log;

  if (@log = $sth->fetchrow_array) {
    my $message   = pop @log;
    my $type      = pop @log;
    my $sender    = pop @log;
    my $timestamp = pop @log;
    my $userid    = pop @log;
    return $userid, $timestamp, $sender, $type, $message;
  } else {
    return;
  } # if
} # GetLog

sub GetNextSequenceNo($$) {
  my ($userid, $listtype) = @_;

  my $count = count ('list', "userid = '$userid' and type = '$listtype'");

  return $count + 1;
} # GetNextSequenceNo

sub GetUser($) {
  my ($sth) = @_;

  my @user;

  if (@user = $sth->fetchrow_array) {
    my $password = pop @user;
    my $email    = pop @user;
    my $name     = pop @user;
    my $userid   = pop @user;
    return ($userid, $name, $email, $password);
  } else {
    return;
  } # if
} # GetUser

sub GetUserInfo($) {
  my ($userid) = @_;

  my $statement = "select name, email from user where userid='$userid'";

  my $sth = $DB->prepare($statement)
    or DBError('GetUserInfo: Unable to prepare statement', $statement);

  $sth->execute
    or DBError('GetUserInfo: Unable to execute statement', $statement);

  my @userinfo   = $sth->fetchrow_array;
  my $user_email = lc (pop @userinfo);
  my $username   = lc (pop @userinfo);

  $sth->finish;

  return ($username, $user_email);
} # GetUserInfo

sub GetUserOptions($) {
  my ($userid) = @_;

  my $statement = "select * from useropts where userid = '$userid'";

  my $sth = $DB->prepare($statement)
    or DBError('GetUserOptions: Unable to prepare statement', $statement);

  $sth->execute
    or DBError('GetUserOptions: Unable to execute statement', $statement);

  my @useropts;

  # Empty hash
  %useropts = ();

  while (@useropts = $sth->fetchrow_array) {
    my $value = pop @useropts;
    my $name  = pop @useropts;

    pop @useropts;

    $useropts{$name} = $value;
  } # while

  $sth->finish;

  return %useropts;
} # GetUserOptions

sub GetRows ($) {
  my ($statement) = @_;

  my $sth = $DB->prepare($statement)
    or DBError('Unable to prepare statement' , $statement);

  $sth->execute
    or DBError('Unable to execute statement' , $statement);

  my @array;

  while (my @row = $sth->fetchrow_array) {
    for (@row) {
      push @array, $_;
    } # for
  } # while

  return @array;
} # GetRows

sub Login($$) {
  my ($userid, $password) = @_;

  $password = Encrypt($password, $userid);

  # Check if user exists
  my $dbpassword = UserExists($userid);

  # Return -1 if user doesn't exist
  return -1 if !$dbpassword;

  # Return -2 if password does not match
  if ($password eq $dbpassword) {
    SetContext($userid);
    return 0
  } else {
    return -2
  } # if
} # Login

sub Nulllist($;$$) {
  # Nulllist will simply discard the message.
  my ($sender, $sequence, $hit_count) = @_;

  RecordHit("null", $sequence, ++$hit_count) if $sequence;

  # Discard Message
  Logmsg("nulllist", $sender, "Discarded message");

  return;
} # Nulllist

sub OnBlacklist($;$) {
  my ($sender, $update) = @_;

  return CheckOnList('black', $sender, $update);
} # OnBlacklist

sub OnNulllist($;$) {
  my ($sender, $update) = @_;

  return CheckOnList("null", $sender, $update);
} # CheckOnNulllist

sub OnWhitelist($;$$) {
  my ($sender, $userid, $update) = @_;

  SetContext($userid) if $userid;

  return CheckOnList("white", $sender, $update);
} # OnWhitelist

sub OpenDB($$) {
  my ($username, $password) = @_;

  my $dbname   = 'MAPS';
  my $dbdriver = 'mysql';
  my $dbserver = $ENV{MAPS_SERVER} || 'localhost';

  if (!$DB || $DB eq '') {
    #$dbserver='localhost';
    $DB = DBI->connect("DBI:$dbdriver:$dbname:$dbserver", $username, $password, {PrintError => 0})
      or croak "Couldn't connect to $dbname database as $username\n" . $DBI::errstr;
  } # if

  return $DB;
} # OpenDB

BEGIN {
  my $MAPS_username = "maps";
  my $MAPS_password = "spam";

  OpenDB($MAPS_username, $MAPS_password);
} # BEGIN

END {
  CloseDB;
} # END


sub OptimizeDB() {
  my $statement = 'lock tables email read, list read, log read, user read, useropts read';
  my $sth = $DB->prepare($statement)
      or DBError('OptimizeDB: Unable to prepare statement', $statement);

  $sth->execute
    or DBError('OptimizeDB: Unable to execute statement', $statement);

  $statement = 'check table email, list, log, user, useropts';
  $sth = $DB->prepare($statement)
      or DBError('OptimizeDB: Unable to prepare statement', $statement);

  $sth->execute
    or DBError('OptimizeDB: Unable to execute statement', $statement);

  $statement = 'unlock tables';
  $sth = $DB->prepare($statement)
      or DBError('OptimizeDB: Unable to prepare statement', $statement);

  $sth->execute
    or DBError('OptimizeDB: Unable to execute statement', $statement);

  $statement = 'optimize table email, list, log, user, useropts';
  $sth = $DB->prepare($statement)
      or DBError('OptimizeDB: Unable to prepare statement', $statement);

  $sth->execute
    or DBError('OptimizeDB: Unable to execute statement', $statement);

  return;
} # OptimizeDB

sub ReadMsg($) {
  # Reads an email message file from $input. Returns sender, subject,
  # date and data, which is a copy of the entire message.
  my ($input) = @_;

  my $sender          = '';
  my $sender_long     = '';
  my $envelope_sender = '';
  my $reply_to        = '';
  my $subject         = '';
  my $data            = '';
  my @data;

  # Find first message's "From " line indicating start of message
  while (<$input>) {
    chomp;
    last if /^From /;
  } # while

  # If we hit eof here then the message was garbled. Return indication of this
  if (eof($input)) {
    $data = "Garbled message - unable to find From line";
    return $sender, $sender_long, $reply_to, $subject, $data;
  } # if

  if (/From (\S*)/) {
    $envelope_sender = $1;
    $sender_long     = $envelope_sender;
  } # if

  push @data, $_ if /^From /;

  while (<$input>) {
    chomp;
    push @data, $_;

    # Blank line indicates start of message body
    last if ($_ eq "" || $_ eq "\r");

    # Extract sender's address
    if (/^from: .*/i) {
      $_ = substr ($_, 6);

      $sender_long = $_;

      if (/<(\S*)@(\S*)>/) {
        $sender = lc ("$1\@$2");
      } elsif (/(\S*)@(\S*)\ /) {
        $sender = lc ("$1\@$2");
      } elsif (/(\S*)@(\S*)/) {
        $sender = lc ("$1\@$2");
      } # if
    } elsif (/^subject: .*/i) {
      $subject = substr ($_, 9);
    } elsif (/^reply-to: .*/i) {
      $_ = substr ($_, 10);
      if (/<(\S*)@(\S*)>/) {
        $reply_to = lc ("$1\@$2");
      } elsif (/(\S*)@(\S*)\ /) {
        $reply_to = lc ("$1\@$2");
      } elsif (/(\S*)@(\S*)/) {
        $reply_to = lc ("$1\@$2");
      } # if
    } # if
  } # while

  # Read message body
  while (<$input>) {
    chomp;

    last if (/^From /);
    push @data, $_;
  } # while

  # Set file pointer back by length of the line just read
  seek ($input, -length () - 1, 1) if !eof $input;

  # Sanitize email addresses
  $envelope_sender =~ s/\<//g;
  $envelope_sender =~ s/\>//g;
  $envelope_sender =~ s/\"//g;
  $envelope_sender =~ s/\'//g;
  $sender          =~ s/\<//g;
  $sender          =~ s/\>//g;
  $sender          =~ s/\"//g;
  $sender          =~ s/\'//g;
  $reply_to        =~ s/\<//g;
  $reply_to        =~ s/\>//g;
  $reply_to        =~ s/\"//g;
  $reply_to        =~ s/\'//g;

  # Determine best addresses
  $sender    = $envelope_sender if $sender eq "";
  $reply_to  = $sender          if $reply_to eq "";

  return $sender, $sender_long, $reply_to, $subject, join "\n", @data;
} # ReadMsg

sub RecordHit($$$) {
  my ($listtype, $sequence, $hit_count) = @_;

  my $current_date = UnixDatetime2SQLDatetime(scalar(localtime));

  my $statement = "update list set hit_count=$hit_count, last_hit='$current_date' where userid='$userid' and type='$listtype' and sequence=$sequence";

  $DB->do($statement)
    or DBError('RecordHit: Unable to do statement', $statement);

  return;
} # RecordHit

sub ResequenceList($$) {
  my ($userid, $type) = @_;

  return 1 if $type ne 'white' && $type ne 'black' && $type ne 'null';

  return 2 unless UserExists($userid);

  my $statement = 'lock tables list write';
  my $sth = $DB->prepare($statement)
      or DBError('ResquenceList: Unable to prepare statement', $statement);

  $sth->execute
    or DBError('ResequenceList: Unable to execute statement', $statement);

  # Now get all of the list entries renumbering as we go
  $statement = <<"END";
select
  pattern,
  domain,
  comment,
  sequence,
  hit_count,
  last_hit
from
  list
where
  userid = '$userid' and
  type   = '$type'
order by
  hit_count desc
END

  $sth = $DB->prepare($statement)
    or DBError('ResequenceList: Unable to prepare statement', $statement);

  $sth->execute
    or DBError('ResequenceList: Unable to execute statement', $statement);

  my $sequence = 1;
  my @new_rows;

  while (my @row = $sth->fetchrow_array) {
    last if !@row;

    my %record = (
      last_hit     => pop @row,
      hit_count    => pop @row,
      new_sequence => $sequence++,
      old_sequence => pop @row,
      comment      => $DB->quote(pop @row) || '',
      domain       => $DB->quote(pop @row) || '',
      pattern      => $DB->quote(pop @row) || '',
    );

    push @new_rows, \%record;
  } # while

  # Delete all of the list entries for this $userid and $type
  $statement = "delete from list where userid='$userid' and type='$type'";

  $DB->do($statement)
    or DBError('ResequenceList: Unable to do statement', $statement);

  # Re-add list with new sequence numbers
  for (@new_rows) {
    my %record = %$_;
    my $statement = <<"END";
insert into
  list
values (
  '$userid',
  '$type',
  $record{pattern},
  $record{domain},
  $record{comment},
  '$record{new_sequence}',
  '$record{hit_count}',
  '$record{last_hit}'
)
END

  $DB->do($statement)
    or DBError('ResequenceList: Unable to do statement', $statement);
  } # for

  $statement = 'unlock tables';
  $sth = $DB->prepare($statement)
      or DBError('OptimizeDB: Unable to prepare statement', $statement);

  $sth->execute
    or DBError('OptimizeDB: Unable to execute statement', $statement);

  return 0;
} # ResequenceList

sub ResequenceListold($$) {
  my ($userid, $type) = @_;

  return 1 if $type ne 'white' && $type ne 'black' && $type ne 'null';

  return 2 unless UserExists($userid);

  my $statement = "select sequence from list where userid = '$userid' "
                . " and type = '$type' order by sequence";

  my $sth = $DB->prepare($statement)
    or DBError('ResequenceList: Unable to prepare statement', $statement);

  $sth->execute
    or DBError('ResequenceList: Unable to execute statement', $statement);

  my $sequence = 1;

  while (my @row = $sth->fetchrow_array) {
    last if !@row;

    my $old_sequence = pop @row;

    if ($old_sequence != $sequence) {
      my $update_statement = "update list set sequence = $sequence " .
                             "where userid = '$userid' and " .
                             "type = '$type' and sequence = $old_sequence";

      $DB->do($update_statement)
        or DBError('ResequenceList: Unable to do statement', $statement);
    } # if

    $sequence++;
  } # while

  return 0;
} # ResequenceList

sub ReturnEmails($$$;$$) {
  my ($userid, $type, $start_at, $nbr_emails, $date) = @_;

  $start_at ||= 0;

  my $statement;

  if ($date) {
    my $sod = $date . ' 00:00:00';
    my $eod = $date . ' 23:59:59';

    if ($type eq 'returned') {
      $statement = <<"END";
select
  log.sender
from
  log,
  email
where
  log.sender    = email.sender and
  log.userid    = '$userid'    and
  log.timestamp > '$sod'       and
  log.timestamp < '$eod'       and
  log.type      = '$type'
group by
  log.sender
limit
  $start_at, $nbr_emails
END
    } else {
      $statement = <<"END";
select
  sender
from
  log
where
  userid    = '$userid'    and
  timestamp > '$sod'       and
  timestamp < '$eod'       and
  type      = '$type'
group by
  sender
limit
  $start_at, $nbr_emails
END
    } # if
  } else {
    if ($type eq 'returned') {
      $statement = <<"END";
select
  log.sender
from
  log,
  email
where
  log.sender   = email.sender and
  log.userid   = '$userid'    and
  log.type     = '$type'
group by 
  log.sender
order by
  log.timestamp desc
limit
  $start_at, $nbr_emails
END
    } else {
      $statement = <<"END";
select
  sender
from
  log
where
  userid   = '$userid'    and
  type     = '$type'
group by
  sender
order by
  timestamp desc
limit
  $start_at, $nbr_emails
END
    } # if
  } # if

  my $sth = $DB->prepare($statement)
    or DBError('ReturnEmails: Unable to prepare statement', $statement);

  $sth->execute
    or DBError('ReturnEmails: Unable to execute statement', $statement);

  my @emails;

  while (my $sender = $sth->fetchrow_array) {
    my $earliestDate;

    # Get emails for this sender. Format an array of subjects and timestamps.
    my @messages;

    $statement = "select timestamp, subject from email where userid = '$userid' " .
                 "and sender = '$sender'";

    my $sth2 = $DB->prepare($statement)
      or DBError('ReturnEmails: Unable to prepare statement', $statement);

    $sth2->execute
      or DBError('ReturnEmails: Unable to execute statement', $statement);

    while (my @row = $sth2->fetchrow_array) {
      my $subject = pop @row;
      my $date    = pop @row;

      if ($earliestDate) {
        my $earliestDateShort = substr $earliestDate, 0, 10;
        my $dateShort         = substr $date,         0, 10;

        if ($earliestDateShort eq $dateShort and
            $earliestDate > $date) {
          $earliestDate = $date if $earliestDateShort eq $dateShort;
        } # if
      } else {
        $earliestDate = $date;
      } # if

      push @messages, [$subject, $date];
    } # while

    # Done with sth2
    $sth2->finish;

    $earliestDate ||= '';

    unless ($type eq 'returned') {
      push @emails, [$earliestDate, [$sender, @messages]];
    } else {
      push @emails, [$earliestDate, [$sender, @messages]]
        if @messages > 0;
    } # unless
  } # while

  # Done with $sth
  $sth->finish;

  return @emails;
} # ReturnEmails

sub ReturnList($$$) {
  my ($type, $start_at, $lines) = @_;

  $lines ||= 10;

  my $statement;

  if ($start_at) {
    $statement = "select * from list where userid = '$userid' " .
                 "and type = '$type' order by sequence "        .
                 "limit $start_at, $lines";
  } else {
    $statement = "select * from list where userid = '$userid' "        .
                 "and type = '$type' order by sequence";
  } # if

  my $sth = $DB->prepare($statement)
    or DBError('ReturnList: Unable to prepare statement', $statement);

  $sth->execute
    or DBError('ReturnList: Unable to execute statement', $statement);

  my @list;
  my $i = 0;

  while (my @row = $sth->fetchrow_array) {
    last if $i++ > $lines;

    my %list;

    $list{last_hit}  = pop @row;
    $list{hit_count} = pop @row;
    $list{sequence}  = pop @row;
    $list{comment}   = pop @row;
    $list{domain}    = pop @row;
    $list{pattern}   = pop @row;
    $list{type}      = pop @row;
    $list{userid}    = pop @row;
    push @list, \%list;
  } # for

  return @list;
} # ReturnList

sub ReturnListEntry($$) {
  my ($type, $sequence) = @_;

  my $statement = "select * from list where userid = '$userid' "        .
                 "and type = '$type' and sequence = '$sequence'";

  my $sth = $DB->prepare($statement)
    or DBError('ReturnListEntry: Unable to prepare statement', $statement);

  $sth->execute
    or DBError('ReturnListEntry: Unable to execute statement', $statement);

  my %list;
  my @row = $sth->fetchrow_array;

  $list{sequence} = pop @row;
  $list{comment}  = pop @row;
  $list{domain}   = pop @row;
  $list{pattern}  = pop @row;
  $list{type}     = pop @row;
  $list{userid}   = pop @row;

  return %list;
} # ReturnListEntry

# Added reply_to. Previously we passed reply_to into here as sender. This
# caused a problem in that we were filtering as per sender but logging it
# as reply_to. We only need reply_to for SendMsg so as to honor reply_to
# so we now pass in both sender and reply_to
sub ReturnMsg($$$$) {
  # ReturnMsg will send back to the $sender the register message.
  # Messages are saved to be delivered when the $sender registers.
  my ($sender, $reply_to, $subject, $data) = @_;

  # Check to see if this sender has already emailed us.
  my $msg_count = CountMsg($sender);

  if ($msg_count < 5) {
    # Return register message
    my @msg;

    for (split /\n/,$data) {
      push @msg, "$_\n";
    } # for

    SendMsg($reply_to,
            "Your email has been returned by MAPS",
            "$mapsbase/register.html",
            GetContext,
            @msg)
      if $msg_count == 0;
    Logmsg("returned", $sender, "Sent register reply");
    # Save message
    SaveMsg($sender, $subject, $data);
  } else {
    Add2Nulllist($sender, GetContext, "Auto Null List - Mail loop");
    Logmsg("mailloop", $sender, "Mail loop encountered");
  } # if

  return;
} # ReturnMsg

sub ReturnMessages($$) {
  my ($userid, $sender) = @_;

  my $statement = <<"END";
select
  subject,
  timestamp
from
  email
where
  userid = '$userid' and
  sender = '$sender'
group by
  timestamp desc
END

  my $sth = $DB->prepare($statement)
    or DBError('ReturnMessages: Unable to prepare statement', $statement);

  $sth->execute
    or DBError('ReturnMessages: Unable to execute statement', $statement);

  my @messages;

  while (my @row = $sth->fetchrow_array) {
    my $date    = pop @row;
    my $subject = pop @row;

    push @messages, [$subject, $date];
  } # while

  $sth->finish;

  return @messages;
} # ReturnMessages

# This subroutine returns an array of senders in reverse chronological
# order based on time timestamp from the log table of when we returned
# their message. The complication here is that a single sender may
# send multiple times in a single day. So if spammer@foo.com sends
# spam @ 1 second after midnight and then again at 2 Pm there will be
# at least two records in the log table saying that we returned his
# email. Getting records sorted by timestamp desc will have
# spammer@foo.com listed twice. But we want him listed only once, as
# the first entry in the returned array. Plus we may be called
# repeatedly with different $start_at's. Therefore we need to process
# the whole list of returns for today, eliminate duplicate entries for
# a single sender then slice the resulting array.
sub ReturnSenders($$$;$$) {
  my ($userid, $type, $start_at, $nbr_emails, $date) = @_;

  $start_at ||= 0;

  my $dateCond = '';

  if ($date) {
    my $sod = $date . ' 00:00:00';
    my $eod = $date . ' 23:59:59';

    $dateCond = "and timestamp > '$sod' and timestamp < '$eod'";
  } # if

  my $statement = <<"END";
select
  sender,
  timestamp
from
  log
where
  userid = '$userid' and
  type   = '$type'
  $dateCond
order by 
  timestamp desc
END

  my $sth = $DB->prepare($statement)
    or DBError('ReturnSenders: Unable to prepare statement', $statement);

  $sth->execute
    or DBError('ReturnSenders: Unable to execute statement', $statement);

  # Watch the distinction between senders (plural) and sender (singular)
  my (%senders, %sendersByTimestamp);

  # Run through the results and add to %senders by sender key. This
  # results in a hash that has the sender in it and the first
  # timestamp value. Since we already sorted timestamp desc by the
  # above select statement, and we've narrowed it down to only log
  # message that occurred for the given $date, we will have a hash
  # containing 1 sender and the latest timestamp for the day.
  while (my $senderRef = $sth->fetchrow_hashref) {
    my %sender = %{$senderRef};

    $senders{$sender{sender}} = $sender{timestamp}
      unless $senders{$sender{sender}};
  } # while

  $sth->finish;

  # Make a hash whose keys are the timestamp (so we can later sort on
  # them).
  while (my ($key, $value) = each %senders) {
    $sendersByTimestamp{$value} = $key;
  } # while

  my @senders;

  # Sort by timestamp desc and push on to the @senders array
  push @senders, $sendersByTimestamp{$_}
    for (sort { $b cmp $a } keys %sendersByTimestamp);

  # Finally slice for the given range
  my $end_at = $start_at + $nbr_emails - 1;

  $end_at = (@senders - 1)
    if $end_at > @senders;

  return (@senders) [$start_at .. $end_at];
} # ReturnSenders

sub SaveMsg($$$) {
  my ($sender, $subject, $data) = @_;

  AddEmail($sender, $subject, $data);

  return;
} # SaveMsg

sub SearchEmails($$) {
  my ($userid, $searchfield) = @_;

  my @emails;

  my $statement =
    "select sender, subject, timestamp from email where userid = '$userid' and (
     sender like '%$searchfield%' or subject like '%$searchfield%')
     order by timestamp desc";

  my $sth = $DB->prepare($statement)
    or DBError('SearchEmails: Unable to prepare statement', $statement);

  $sth->execute
    or DBError('SearchEmails: Unable to execute statement', $statement);

  while (my @row = $sth->fetchrow_array) {
    my $date    = pop @row;
    my $subject = pop @row;
    my $sender  = pop @row;

    push @emails, [$sender, $subject, $date];
  } # while

  $sth->finish;

  return @emails;
} # SearchEmails

sub SendMsg($$$$@) {
  # SendMsg will send the message contained in $msgfile.
  my ($sender, $subject, $msgfile, $userid, @spammsg) = @_;

  my @lines;

  # Open return message template file
  open my $return_msg_file, '<', $msgfile
    or die "Unable to open return msg file ($msgfile): $!\n";

  # Read return message template file and print it to $msg_body
  while (<$return_msg_file>) {
    if (/\$userid/) {
      # Replace userid
      s/\$userid/$userid/;
    } # if
    if (/\$sender/) {
      # Replace sender
      s/\$sender/$sender/;
    } #if

    push @lines, $_;
  } # while

  close $return_msg_file;

  # Create the message, and set up the mail headers:
  my $msg = MIME::Entity->build(
    From    => "MAPS\@DeFaria.com",
    To      => $sender,
    Subject => $subject,
    Type    => "text/html",
    Data    => \@lines
  );

  # Need to obtain the spam message here...
  $msg->attach(
    Type        => "message",
    Disposition => "attachment",
    Data        => \@spammsg
  );

  # Send it
  open my $mail, '|-', '/usr/lib/sendmail -t -oi -oem'
    or croak "SendMsg: Unable to open pipe to sendmail $!";

  $msg->print(\*$mail);

  close $mail;

  return;
} # SendMsg

sub SetContext($) {
  my ($to_user) = @_;

  my $old_user = $userid;

  if (UserExists($to_user)) {
    $userid = $to_user;

    GetUserOptions($userid);
    return GetUserInfo $userid;
  } else {
    return 0;
  } # if
} # SetContext

sub Space($) {
  my ($userid) = @_;

  my $total_space = 0;
  my %msg_space;

  my $statement = "select * from email where userid = '$userid'";
  my $sth = $DB->prepare($statement)
    or DBError('Unable to prepare statement', $statement);

  $sth->execute
    or DBError('Unable to execute statement', $statement);

  while (my @row = $sth->fetchrow_array) {
    last if !@row;

    my $data      = pop @row;
    my $timestamp = pop @row;
    my $subject   = pop @row;
    my $sender    = pop @row;
    my $user      = pop @row;

    my $msg_space =
      length ($userid)    +
      length ($sender)    +
      length ($subject)   +
      length ($timestamp) +
      length ($data);

    $total_space        += $msg_space;
    $msg_space{$sender} += $msg_space;
  } # while

  $sth->finish;

  return wantarray ? %msg_space : $total_space;
} # Space

sub UpdateList($$$$$$$) {
  my ($userid, $type, $pattern, $domain, $comment, $hit_count, $sequence) = @_;

  if (!$pattern || $pattern eq '') {
    $pattern = 'NULL';
  } else {
    $pattern = "'" . quotemeta ($pattern) . "'";
  } # if

  if (!$domain || $domain eq '') {
    $domain = 'NULL';
  } else {
    $domain = "'" . quotemeta ($domain) . "'";
  } # if

  if (!$comment || $comment eq '') {
    $comment = 'NULL';
  } else {
    $comment = "'" . quotemeta ($comment) . "'";
  } # if

  if (!$hit_count || $hit_count eq '') {
    $hit_count = 0;
  #} else {
  # TODO: Check if numeric
  } # fi

  my $statement =
    'update list set ' .
    "pattern = $pattern, domain = $domain, comment = $comment, hit_count = $hit_count " .
    "where userid = '$userid' and type = '$type' and sequence = $sequence";

  $DB->do($statement)
    or DBError('UpdateList: Unable to do statement', $statement);

  return 0;
} # UpdateList

sub UpdateUser($$$$) {
  my ($userid, $fullname, $email, $password) = @_;

  return 1 if !UserExists($userid);

  my $statement;

  if (!defined $password || $password eq '') {
    $statement = "update user set userid='$userid', name='$fullname', email='$email' where userid='$userid'";
  } else {
    $password = Encrypt $password, $userid;
    $statement = "update user set userid='$userid', name='$fullname', email='$email', password='$password' where userid='$userid'";
  } # if

  $DB->do($statement)
    or DBError('UpdateUser: Unable to do statement', $statement);

  return 0;
} # UpdateUser

sub UpdateUserOptions ($@) {
  my ($userid, %options)  = @_;

  return unless UserExists($userid);

  for (keys(%options)) {
    my $statement = "update useropts set value='$options{$_}' where userid='$userid' and name='$_'";

    $DB->do($statement)
      or DBError('UpdateUserOption: Unable to do statement', $statement);
  } # for

  return;
} # UpdateUserOptions

sub UserExists($) {
  my ($userid) = @_;

  return 0 unless $userid;

  my $statement = "select userid, password from user where userid = '$userid'";

  my $sth = $DB->prepare($statement)
      or DBError('UserExists: Unable to prepare statement', $statement);

  $sth->execute
    or DBError('UserExists: Unable to execute statement', $statement);

  my @userdata = $sth->fetchrow_array;

  $sth->finish;

  return 0 if scalar(@userdata) == 0;

  my $dbpassword = pop @userdata;
  my $dbuserid   = pop @userdata;

  if ($dbuserid ne $userid) {
    return 0;
  } else {
    return $dbpassword;
  } # if
} # UserExists

sub Whitelist ($$;$$) {
  # Whitelist will deliver the message.
  my ($sender, $data, $sequence, $hit_count) = @_;

  my $userid = GetContext;

  # Dump message into a file
  open my $message, '>', "/tmp/MAPSMessage.$$"
    or Error("Unable to open message file (/tmp/MAPSMessage.$$): $!\n"), return -1;

  print $message $data;

  close $message;

  # Now call MAPSDeliver
  my $status = system "$FindBin::Bin/MAPSDeliver $userid /tmp/MAPSMessage.$$";

  unlink "/tmp/MAPSMessage.$$";

  if ($status == 0) {
    Logmsg("whitelist", $sender, "Delivered message");
  } else { 
    Error("Unable to deliver message - is MAPSDeliver setgid? - $!");
  } # if

  RecordHit("white", $sequence, ++$hit_count) if $sequence;

  return $status;
} # Whitelist

sub count($$) {
  my ($table, $condition) = @_;

  my $statement;

  if ($condition) {
    $statement = "select count(*) from $table where $condition";
  } else {
    $statement = "select count(*) from $table";
  } # if

  my $sth = $DB->prepare($statement)
    or DBError('count: Unable to prepare statement', $statement);

  $sth->execute
    or DBError('count: Unable to execute statement', $statement);

  # Get return value, which should be how many message there are
  my @row = $sth->fetchrow_array;

  # Done with $sth
  $sth->finish;

  my $count;

  # Retrieve returned value
  unless ($row[0]) {
    $count = 0
  } else {
    $count = $row[0];
  } # unless

  return $count
} # count

sub count_distinct($$$) {
  my ($table, $column, $condition) = @_;

  my $statement;

  if ($condition) {
    $statement = "select count(distinct $column) from $table where $condition";
  } else {
    $statement = "select count(distinct $column) from $table";
  } # if

  my $sth = $DB->prepare($statement)
    or DBError('count: Unable to prepare statement', $statement);

  $sth->execute
    or DBError('count: Unable to execute statement', $statement);

  # Get return value, which should be how many message there are
  my @row = $sth->fetchrow_array;

  # Done with $sth
  $sth->finish;

  # Retrieve returned value
  unless ($row[0]) {
    return 0;
  } else {
    return $row[0];
  } # unless
} # count_distinct

sub countlog(;$) {
  my ($additional_condition) = @_;

  my $condition = "userid=\'$userid\' ";

  $condition .= "and $additional_condition" if $additional_condition;

  return count_distinct('log', 'sender', $condition);
} # countlog

1;
