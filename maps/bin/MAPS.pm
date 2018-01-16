#!/usr/bin/perl
#################################################################################
#
# File:         $RCSfile: MAPS.pm,v $
# Revision:  $Revision: 1.1 $
# Description:  Main module for Mail Authentication and Permission System (MAPS)
# Author:       Andrew@DeFaria.com
# Created:      Fri Nov 29 14:17:21  2002
# Modified:     $Date: 2013/06/12 14:05:47 $
# Language:     perl
#
# (c) Copyright 2000-2006, Andrew@DeFaria.com, all rights reserved.
#
################################################################################
package MAPS;

use strict;

use FindBin;

use MAPSDB;
use MAPSLog;
use MAPSFile;
use MAPSUtil;
use MIME::Entity;

use vars qw (@ISA @EXPORT);
use Exporter;

@ISA = qw (Exporter);

@EXPORT = qw (
  Add2Blacklist
  Add2Nulllist
  Add2Whitelist
  AddEmail
  AddList
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
);

my $mapsbase = "$FindBin::Bin/..";

# Forwards
sub Add2Blacklist;
sub Add2Nulllist;
sub Add2Whitelist;
sub AddEmail;
sub AddList;
sub AddUser;
sub AddUserOptions;
sub Blacklist;
sub CleanEmail;
sub CleanLog;
sub CountMsg;
sub Decrypt;
sub DeleteEmail;
sub DeleteList;
sub DeleteLog;
sub Encrypt;
sub FindEmail;
sub FindList;
sub FindLog;
sub FindUser;
sub ForwardMsg;
sub GetContext;
sub GetEmail;
sub GetList;
sub GetLog;
sub GetUser;
sub GetUserOptions;
sub Login;
sub Nulllist;
sub OnBlacklist;
sub OnNulllist;
sub OnWhitelist;
sub OptimizeDB;
sub ReadMsg;
sub ResequenceList;
sub ReturnList;
sub ReturnListEntry;
sub ReturnMsg;
sub ReturnMessages;
sub ReturnSenders;
sub SaveMsg;
sub SearchEmails;
sub SendMsg;
sub SetContext;
sub Space;
sub UpdateList;
sub UpdateUser;
sub UpdateUserOptions;
sub UserExists;
sub Whitelist;

BEGIN {
  my $MAPS_username = "maps";
  my $MAPS_password = "spam";

  OpenDB $MAPS_username, $MAPS_password;
} # BEGIN

END {
  CloseDB;
} # END

sub Add2Blacklist {
  # Add2Blacklist will add an entry to the blacklist
  my ($sender, $userid, $comment) = @_;

  # First SetContext to the userid whose black list we are adding to
  MAPSDB::SetContext $userid;

  # Add to black list
  AddList "black", $sender, 0, $comment;

  # Log that we black listed the sender
  Info "Added $sender to " . ucfirst $userid . "'s black list";

  # Delete old emails
  my $count = DeleteEmail $sender;

  # Log out many emails we managed to remove
  Info "Removed $count emails from $sender"
} # Add2Blacklist

sub Add2Nulllist ($$;$$) {
  # Add2Nulllist will add an entry to the nulllist
  my ($sender, $userid, $comment, $hit_count) = @_;
  
  # First SetContext to the userid whose null list we are adding to
  MAPSDB::SetContext $userid;

  # Add to null list
  AddList "null", $sender, 0, $comment, $hit_count;

  # Log that we null listed the sender
  Info "Added $sender to " . ucfirst $userid . "'s null list";

  # Delete old emails
  my $count = DeleteEmail $sender;

  # Log out many emails we managed to remove
  Info "Removed $count emails from $sender"
} # Add2Nulllist

sub Add2Whitelist ($$;$) {
  # Add2Whitelist will add an entry to the whitelist
  my ($sender, $userid, $comment) = @_;

  # First SetContext to the userid whose white list we are adding to
  MAPSDB::SetContext $userid;

  # Add to white list
  AddList 'white', $sender, 0, $comment;

  # Log that we registered a user
  Logmsg "registered", $sender, "Registered new sender";

  # Check to see if there are any old messages to deliver
  my $handle = FindEmail $sender;

  my ($dbsender, $subject, $timestamp, $message);

  # Deliver old emails
  my $messages    = 0;
  my $return_status  = 0;

  while (($userid, $dbsender, $subject, $timestamp, $message) = GetEmail $handle) {
    last 
      unless $userid;

    $return_status = Whitelist $sender, $message;

    last
      if $return_status;

    $messages++;
  } # while

  # Done with $handle
  $handle->finish;

  # Return if we has a problem delivering email
  return $return_status
    if $return_status;

  # Remove delivered messages.
  DeleteEmail $sender;

  return $messages;
} # Add2Whitelist

sub AddEmail ($$$) {
  my ($sender, $subject, $data) = @_;

  MAPSDB::AddEmail $sender, $subject, $data;
} # AddEmail

sub AddList ($$$;$$$) {
  my ($listtype, $pattern, $sequence, $comment, $hit_count, $last_hit) = @_;

  $hit_count //= CountMsg $pattern;

  MAPSDB::AddList $listtype, $pattern, $sequence, $comment, $hit_count, $last_hit;
} # AddList

sub AddUser ($$$$) {
  my ($userid, $realname, $email, $password) = @_;

  return MAPSDB::AddUser $userid, $realname, $email, $password;
} # AddUser

sub AddUserOptions ($%) {
  my ($userid, %options) = @_;

  my $status;

  foreach (keys (%options)) {
    $status = MAPSDB::AddUserOption $userid, $_, $options{$_};
    last if $status ne 0;
  } # foreach

  return $status;
} # AddUserOptions

sub Blacklist ($$$@) {
  # Blacklist will send a message back to the $sender telling them that
  # they've been blacklisted. Currently we save a copy of the message.
  # In the future we should just disregard the message.
  my ($sender, $sequence, $hit_count, @msg)  = @_;

  # Check to see if this sender has already emailed us.
  my $msg_count = CountMsg $sender;

  if ($msg_count lt 5) {
    # Bounce email
    SendMsg ($sender, "Your email has been discarded by MAPS", "$mapsbase/blacklist.html", @msg);
    Logmsg "blacklist", $sender, "Sent blacklist reply";
  } else {
    Logmsg "mailloop", $sender, "Mail loop encountered";
  } # if

  RecordHit "black", $sequence, ++$hit_count if $sequence;
} # Blacklist

sub CleanEmail ($) {
  my ($timestamp) = @_;

  MAPSDB::CleanEmail $timestamp;
} # CleanEmail

sub CleanLog ($) {
  my ($timestamp) = @_;

  MAPSDB::CleanLog $timestamp;
} # CleanLog

sub CleanList ($;$) {
  my ($timestamp, $listtype) = @_;

  MAPSDB::CleanList $timestamp, $listtype;
} # CleanList

sub CountMsg ($) {
  my ($sender) = @_;

  return MAPSDB::CountMsg $sender;
} # CountMsg

sub Decrypt ($$) {
  my ($password, $userid) = @_;

  return MAPSDB::Decrypt $password, shift;
} # Decrypt

sub DeleteEmail ($) {
  my ($sender) = @_;

  return MAPSDB::DeleteEmail $sender;
} # DeleteEmail

sub DeleteList ($$) {
  my ($type, $sequence) = @_;

  return MAPSDB::DeleteList $type, $sequence;
} # DeleteList

sub DeleteLog ($) {
  my ($sender) = @_;

  return MAPSDB::DeleteLog $sender;
} # DeleteLog

sub Encrypt ($$) {
  my ($password, $userid) = @_;

  return MAPSDB::Encrypt $password, $userid;
} # Encrypt

sub FindEmail (;$) {
  my ($sender) = @_;

  return MAPSDB::FindEmail $sender;
} # FindEmail

sub FindList ($;$) {
  my ($type, $sender) = @_;

  return MAPSDB::FindList $type, $sender;
} # FindList

sub FindLog ($) {
  my ($how_many) = @_;

  my $start_at = 0;
  my $end_at   = MAPSDB::countlog ();

  if ($how_many < 0) {
    $start_at = $end_at - abs ($how_many);
    $start_at = 0 if ($start_at < 0);
  } # if

  return MAPSDB::FindLog $start_at, $end_at;
} # FindLog

sub FindUser (;$) {
  my ($userid) = @_;

  return MAPSDB::FindUser $userid
} # FindUser

sub GetContext () {
  return MAPSDB::GetContext ();
} # GetContext

sub GetEmail ($) {
  my ($handle) = @_;

  return MAPSDB::GetEmail $handle;
} # GetEmail

sub GetList ($) {
  my ($handle) = @_;

  return MAPSDB::GetList $handle;
} # GetList

sub GetLog ($) {
  my ($handle) = @_;

  return MAPSDB::GetLog $handle;
} # GetLog

sub GetUser ($) {
  my ($handle) = @_;

  return MAPSDB::GetUser $handle;
} # GetUser

sub GetUserOptions ($) {
  my ($userid) = @_;

  return MAPSDB::GetUserOptions $userid;
} # GetUserOptions

sub Login ($$) {
  my ($userid, $password) = @_;

  $password = Encrypt $password, $userid;

  # Check if user exists
  my $dbpassword = UserExists $userid;

  # Return -1 if user doesn't exist
  return -1 if !$dbpassword;

  # Return -2 if password does not match
  if ($password eq $dbpassword) {
    MAPSDB::SetContext $userid;
    return 0
  } else {
    return -2
  } # if
} # Login

sub Nulllist ($;$$) {
  # Nulllist will simply discard the message.
  my ($sender, $sequence, $hit_count) = @_;

  RecordHit "null", $sequence, ++$hit_count if $sequence;

  # Discard Message
  Logmsg "nulllist", $sender, "Discarded message";
} # Nulllist

sub OnBlacklist ($;$) {
  my ($sender, $update) = @_;

  return CheckOnList "black", $sender, $update;
} # CheckOnBlacklist

sub OnNulllist ($;$) {
  my ($sender, $update) = @_;

  return CheckOnList "null", $sender, $update;
} # CheckOnNulllist

sub OnWhitelist ($;$$) {
  my ($sender, $userid, $update) = @_;

  if (defined $userid) {
    MAPSDB::SetContext $userid;
  } # if

  return CheckOnList "white", $sender, $update;
} # OnWhitelist

sub OptimizeDB () {
  return MAPSDB::OptimizeDB ();
} # OptimizeDB

sub ReadMsg ($) {
  # Reads an email message file from $input. Returns sender, subject,
  # date and data, which is a copy of the entire message.
  my ($input) = @_;

  my $sender           = "";
  my $sender_long      = "";
  my $envelope_sender  = "";
  my $reply_to         = "";
  my $subject          = "";
  my $data             = "";
  my @data;

  # Find first message's "From " line indicating start of message
  while (<$input>) {
    chomp;
    last if /^From /;
  } # while

  # If we hit eof here then the message was garbled. Return indication of this
  if (eof $input) {
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

sub ResequenceList ($$) {
  my ($userid, $type) = @_;

  return MAPSDB::ResequenceList $userid, $type;
} # ResequenceList

sub ReturnMessages ($$) {
  my ($userid, $sender) = @_;

  return MAPSDB::ReturnMessages $userid, $sender;
} # ReturnMessages

sub ReturnSenders ($$$;$$) {
  my ($userid, $type, $next, $lines, $date) = @_;

  return MAPSDB::ReturnSenders $userid, $type, $next, $lines, $date;
} # ReturnSenders

sub ReturnList ($$$) {
  my ($type, $start_at, $lines)  = @_;

  return MAPSDB::ReturnList $type, $start_at, $lines;
} # ReturnList

sub ReturnListEntry ($$) {
  my ($type, $sequence) = @_;

  return MAPSDB::ReturnListEntry $type, $sequence;
} # ReturnList

# Added reply_to. Previously we passed reply_to into here as sender. This
# caused a problem in that we were filtering as per sender but logging it
# as reply_to. We only need reply_to for SendMsg so as to honor reply_to
# so we now pass in both sender and reply_to
sub ReturnMsg ($$$$) {
  # ReturnMsg will send back to the $sender the register message.
  # Messages are saved to be delivered when the $sender registers.
  my ($sender, $reply_to, $subject, $data) = @_;

  # Check to see if this sender has already emailed us.
  my $msg_count = CountMsg $sender;

  if ($msg_count < 5) {
    # Return register message
    my @msg;
    foreach (split /\n/,$data) {
      push @msg, "$_\n";
    } # foreach
    SendMsg $reply_to,
            "Your email has been returned by MAPS",
            "$mapsbase/register.html",
            GetContext,
            @msg
      if $msg_count eq 0;
    Logmsg "returned", $sender, "Sent register reply";
    # Save message
    SaveMsg $sender, $subject, $data;
  } else {
    Add2Nulllist $sender, GetContext, "Auto Null List - Mail loop";
    Logmsg "mailloop", $sender, "Mail loop encountered";
  } # if
} # ReturnMsg

sub SaveMsg ($$$) {
  my ($sender, $subject, $data) = @_;

  AddEmail $sender, $subject, $data;
} # SaveMsg

sub SearchEmails ($$) {
  my ($userid, $searchfield) = @_;

  return MAPSDB::SearchEmails $userid, $searchfield;
} # SearchEmails

sub ForwardMsg ($$$) {
  my ($sender, $subject, $data)  = @_;

  my @lines = split /\n/, $data;

  while ($_ = shift @lines) {
    last if ($_ eq "" || $_ eq "\r");
  } # while

  my $to = "renn.leech\@compassbank.com";

  my $msg = MIME::Entity->build (
    From  => $sender,
    To    => $to,
    Subject  => $subject,
    Type  => "text/html",
    Data  => \@lines,
  );

  # Send it
  open MAIL, "| /usr/lib/sendmail -t -oi -oem"
    or die "ForwardMsg: Unable to open pipe to sendmail $!";
  $msg->print(\*MAIL);
  close MAIL;
} # ForwardMsg

sub SendMsg ($$$$@) {
  # SendMsg will send the message contained in $msgfile.
  my ($sender, $subject, $msgfile, $userid, @spammsg) = @_;

  my @lines;

  # Open return message template file
  open RETURN_MSG_FILE, "$msgfile"
    or die "Unable to open return msg file ($msgfile): $!\n";

  # Read return message template file and print it to $msg_body
  while (<RETURN_MSG_FILE>) {
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

  # Close RETURN_MSG_FILE
  close RETURN_MSG_FILE;

  # Create the message, and set up the mail headers:
  my $msg = MIME::Entity->build (
    From  => "MAPS\@DeFaria.com",
    To    => $sender,
    Subject  => $subject,
    Type  => "text/html",
    Data  => \@lines
  );

  # Need to obtain the spam message here...
  $msg->attach (
    Type  => "message",
    Disposition  => "attachment",
    Data  => \@spammsg
  );

  # Send it
  open MAIL, "| /usr/lib/sendmail -t -oi -oem"
    or die "SendMsg: Unable to open pipe to sendmail $!";
  $msg->print(\*MAIL);
  close MAIL;
} # SendMsg

sub SetContext ($) {
  my ($new_user) = @_;

  return MAPSDB::SetContext $new_user;
} # SetContext

sub Space ($) {
  my ($userid) = @_;

  return MAPSDB::Space $userid;
} # Space

sub UpdateList ($$$$$$$) {
  my ($userid, $type, $pattern, $domain, $comment, $hit_count, $sequence) = @_;

  return MAPSDB::UpdateList $userid, $type, $pattern, $domain, $comment, $hit_count, $sequence;
} # UpdateList

sub UpdateUser ($$$$) {
  my ($userid, $fullname, $email, $password) = @_;

  return MAPSDB::UpdateUser $userid, $fullname, $email, $password;
} # UpdateUser

sub UpdateUserOptions ($@) {
  my ($userid, %options)  = @_;

  my $status;

  foreach (keys (%options)) {
    $status = MAPSDB::UpdateUserOption $userid, $_, $options{$_};
    last if $status ne 0;
  }

  return $status;
} # UpdateUserOptions

sub UserExists ($) {
  my ($userid) = @_;

  return MAPSDB::UserExists $userid
} # UserExists

sub Whitelist ($$;$$) {
  # Whitelist will deliver the message.
  my ($sender, $data, $sequence, $hit_count) = @_;

  my $userid = GetContext;

  # Dump message into a file
  open MESSAGE, ">/tmp/MAPSMessage.$$"
    or Error "Unable to open message file (/tmp/MAPSMessage.$$): $!\n", return -1;

  print MESSAGE $data;

  close MESSAGE;

  # Now call MAPSDeliver
  my $status = system "$FindBin::Bin/MAPSDeliver $userid /tmp/MAPSMessage.$$";

  unlink "/tmp/MAPSMessage.$$";

  if ($status eq 0) {
    Logmsg "whitelist", $sender, "Delivered message";
  } else { 
    Error "Unable to deliver message - is MAPSDeliver setgid? - $!";
  } # if

  RecordHit "white", $sequence, ++$hit_count if $sequence;

  return $status;
} # Whitelist

1;
