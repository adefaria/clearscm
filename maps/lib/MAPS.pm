################################################################################
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
use Exporter;
use Encode;

use MAPSLog;
use MIME::Entity;

use Display;
use MyDB;
use Utils;
use DateUtils;

use base qw(Exporter);

our $db;

our $VERSION = '2.1';

# Globals
my $userid = $ENV{MAPS_USERNAME} ? $ENV{MAPS_USERNAME} : $ENV{USER};
my %useropts;
my $mailLoopMax = 5;

our @EXPORT = qw(
  Add2Blacklist
  Add2Nulllist
  Add2Whitelist
  AddEmail
  AddList
  AddLog
  AddUser
  AddUserOptions
  Blacklist
  CheckEmail
  CleanEmail
  CleanLog
  CleanList
  CountEmail
  CountList
  CountLog
  CountLogDistinct
  Decrypt
  DeleteEmail
  DeleteList
  Encrypt
  FindEmail
  FindList
  FindLog
  FindUser
  FindUsers
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

# Insternal routines
sub _cleanTables($$;$) {
  my ($table, $timestamp, $dryrun) = @_;

  my $condition = "userid = '$userid' and timestamp < '$timestamp'";

  if ($dryrun) {
    return $db->count ($table, $condition);
  } else {
    my ($count, $msg) = $db->delete ($table, $condition);

    return $count;
  }    # if
}    # _cleanTables

sub _retention2Days($) {
  my ($retention) = @_;

  # Of the retnetion periods I'm thinking of where they are <n> and then
  # something like (days|weeks|months|years) none are tricky except for months
  # because months, unlike (days|weeks|years) are ill-defined. Are there 28, 29
  # 30 or 31 days in a month? Days are simple <n> days. Weeks are simple <n> * 7
  # days. Years are simple - just change the year (a little oddity of 365 or
  # 366) days this year? To keep things simple, we will ignore the oddities of
  # leap years and just use 30 for number of days in month. We really don't need
  # to be that accurate here...
  #
  # BTW we aren't checking for odd things like 34320 weeks or 5000 years...
  if ($retention =~ /(\d+)\s+(day|days)/) {
    return $1;
  } elsif ($retention =~ /(\d+)\s+(week|weeks)/) {
    return $1 * 7;
  } elsif ($retention =~ /(\d+)\s+(month|months)/) {
    return $1 * 30;
  } elsif ($retention =~ /(\d+)\s+(year|years)/) {
    return $1 * 365;
  }    # if
}    # _retention2Days

sub _getnext() {
  return $db->getnext;
}    # _getnext

sub OpenDB($$) {
  my ($username, $password) = @_;

  my $dbname   = 'MAPS';
  my $dbserver = $ENV{MAPS_SERVER} || 'localhost';

  $db = MyDB->new ($username, $password, $dbname, $dbserver);

  croak "Unable to instantiate MyDB ($username\@$dbserver:$dbname)" unless $db;

  return;
}    # OpenDB

BEGIN {
  my $MAPS_username = "maps";
  my $MAPS_password = "spam";

  OpenDB ($MAPS_username, $MAPS_password);
}    # BEGIN

sub Add2Blacklist(%) {
  my (%params) = @_;

  # Add2Blacklist will add an entry to the blacklist
  # First SetContext to the userid whose black list we are adding to
  SetContext ($params{userid});

  # Add to black list
  $params{sequence} = 0;
  my ($err, $msg) = AddList (%params);

  # Log that we black listed the sender
  Info (
    "Added $params{sender} to " . ucfirst $params{userid} . "'s black list");

  # Delete old emails
  my $count = DeleteEmail (
    userid => $params{userid},
    sender => $params{sender},
  );

  # Log out many emails we managed to remove
  Info ("Removed $count emails from $params{sender}");

  return $count;
}    # Add2Blacklist

sub Add2Nulllist(%) {
  my (%params) = @_;

  # First SetContext to the userid whose null list we are adding to
  SetContext ($params{userid});

  # Add to null list
  $params{sequence} = 0;
  my ($err, $msg) = AddList (%params);

  # Log that we null listed the sender
  Info ("Added $params{sender} to " . ucfirst $params{userid} . "'s null list");

  # Delete old emails
  my $count = DeleteEmail (
    userid => $params{userid},
    sender => $params{sender},
  );

  # Log out many emails we managed to remove
  Info ("Removed $count emails from $params{sender}");

  return;
}    # Add2Nulllist

sub Add2Whitelist(%) {
  my (%params) = @_;

  # Add2Whitelist will add an entry to the whitelist
  # First SetContext to the userid whose white list we are adding to
  SetContext ($params{userid});

  # Add to white list
  $params{sequence} = 0;

  my ($err, $msg) = AddList (%params);

  return -$err, $msg if $err;

  # Log that we registered a user
  Logmsg (
    userid  => $params{userid},
    type    => 'registered',
    sender  => $params{sender},
    message => 'Registered new sender',
  );

  # Check to see if there are any old messages to deliver
  ($err, $msg) = $db->find (
    'email',
    "sender = '$params{sender}'",
    ['userid', 'sender', 'data']
  );

  return ($err, $msg) if $err;

  # Deliver old emails
  my $messages = 0;
  my $status   = 0;

  while (my $rec = $db->getnext) {
    last unless $rec->{userid};

    $status = Whitelist ($rec->{sender}, $rec->{data});

    last if $status;

    $messages++;
  }    # while

  # Return if we has a problem delivering email
  return -1, 'Problem delivering some email' if $status;

  # Remove delivered messages
  DeleteEmail (
    userid => $params{userid},
    sender => $params{sender},
  );

  return $messages, 'Messages delivered';
}    # Add2Whitelist

sub AddEmail(%) {
  my (%rec) = @_;

  CheckParms (['userid', 'sender', 'subject', 'data'], \%rec);

  $rec{timestamp} = UnixDatetime2SQLDatetime (scalar (localtime));

  return $db->add ('email', %rec);
}    # AddEmail

sub AddList(%) {
  my (%rec) = @_;

  CheckParms (['userid', 'type', 'sender', 'sequence'], \%rec);

  croak "Type $rec{type} not valid. Must be one of white, black or null"
    unless $rec{type} =~ /(white|black|null)/;

  croak "Sender must contain \@" unless $rec{sender} =~ /\@/;

  $rec{retention} //= '';
  $rec{retention} = lc $rec{retention};

  $rec{hit_count} //= $db->count ('email',
    "userid = '$rec{userid}' and sender like '%$rec{sender}%'");

  ($rec{pattern}, $rec{domain}) = split /\@/, delete $rec{sender};

  $rec{sequence} = GetNextSequenceNo (%rec);

  $rec{last_hit} //= UnixDatetime2SQLDatetime (scalar (localtime));

  return $db->add ('list', %rec);
}    # AddList

sub AddLog(%) {
  my (%params) = @_;

  # Some email senders are coming in mixed case. We don't want that
  $params{sender} = $params{sender} ? lc $params{sender} : '';

  $params{timestamp} = UnixDatetime2SQLDatetime (scalar (localtime));

  return $db->add ('log', %params);
}    # AddLog

sub AddUser(%) {
  my (%rec) = @_;

  CheckParms (['userid', 'name', 'email', 'password'], \%rec);

  return 1 if UserExists ($rec{userid});

  return $db->add ('user', %rec);
}    # Adduser

sub AddUserOptions(%) {
  my (%rec) = @_;

  croak ('Userid is required') unless $rec{userid};
  croak ('No options to add')  unless $rec{options};

  return (1, "User doesn't exists") unless UserExist ($rec{userid});

  my %useropts = delete $rec{userid};
  my %opts     = delete $rec{options};

  my ($err, $msg);

  for my $key (%opts) {
    $useropts{name}  = $_;
    $useropts{value} = $opts{$_};

    ($err, $msg) = $db->add ('useropts', %useropts);

    last if $err;
  }    # for

  return ($err, $msg) if $err;
  return;
}    # AddUserOptions

sub Blacklist(%) {

  # Blacklist will send a message back to the $sender telling them that
  # they've been blacklisted. Currently we save a copy of the message.
  # In the future we should just disregard the message.
  my (%rec) = @_;

  # Check to see if this sender has already emailed us.
  my $msg_count = $db->count ('email',
    "userid='$rec{userid}' and sender like '%$rec{sender}%'");

  if ($msg_count < $mailLoopMax) {

    # Bounce email
    my @spammsg = split "\n", $rec{data};

    SendMsg (
      userid  => $rec{userid},
      sender  => $rec{sender},
      subject => 'Your email has been discarded by MAPS',
      msgfile => "$mapsbase/blacklist.html",
      data    => $rec{data},
    );

    Logmsg (
      userid  => $userid,
      type    => 'blacklist',
      sender  => $rec{sender},
      message => 'Sent blacklist reply',
    );
  } else {
    Logmsg (
      userid  => $userid,
      type    => 'mailloop',
      sender  => $rec{sender},
      message => 'Mail loop encountered',
    );
  }    # if

  $rec{hit_count}++ if $rec{sequence};

  RecordHit (
    userid    => $userid,
    type      => 'black',
    sequence  => $rec{sequence},
    hit_count => $rec{hit_count},
  );

  return;
}    # Blacklist

sub CheckEmail(;$$) {
  my ($username, $domain) = @_;

  return lc "$username\@$domain" if $username and $domain;

  # Check to see if a full email address in either $username or $domain
  if ($username) {
    if ($username =~ /(.*)\@(.*)/) {
      return lc "$1\@$2";
    } else {
      return lc "$username\@";
    }    # if
  } elsif ($domain) {
    if ($domain =~ /(.*)\@(.*)/) {
      return lc "$1\@$2";
    } else {
      return "\@$domain";
    }    # if
  }    # if
}    # CheckEmail

sub CheckOnList2 ($$;$) {

  # CheckOnList will check to see if the $sender is on the list.  Return 1 if
  # found 0 if not.
  my ($listtype, $sender, $update) = @_;

  $update //= 1;

  my ($status, $rule, $sequence);

  my $table     = 'list';
  my $condition = "userid='$userid' and type='$listtype'";

  my ($err, $errmsg) = $db->find ($table, $condition, '*', 'order by sequence');

  my ($email_on_file, $rec);

  while ($rec = $db->getnext) {
    unless ($rec->{domain}) {
      $email_on_file = $rec->{pattern};
    } else {
      unless ($rec->{pattern}) {
        $email_on_file = '@' . $rec->{domain};
      } else {
        $email_on_file = $rec->{pattern} . '@' . $rec->{domain};
      }    # if
    }    # unless

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
    my $search_for =
        $email_on_file =~ /\@/  ? "$email_on_file\$"
      : !defined $rec->{domain} ? "$email_on_file\@"
      :                           $email_on_file;
    if ($sender and $sender =~ /$search_for/i) {
      $status = 1;

      $rec->{hit_count} //= 0;

      RecordHit (
        userid    => $userid,
        type      => $listtype,
        sequence  => $rec->{sequence},
        hit_count => $rec->{hit_count} + 1,
      ) if $update;

      last;
    }    # if
  }    # while

  return ($status, $rec);
}    # CheckOnList2

sub CheckOnList ($$;$) {

  # CheckOnList will check to see if the $sender is on the list.  Return 1 if
  # found 0 if not.
  my ($listtype, $sender, $update) = @_;

  $update //= 1;

  my $status = 0;
  my ($rule, $sequence);

  my $table     = 'list';
  my $condition = "userid='$userid' and type='$listtype'";

  my ($err, $errmsg) = $db->find ($table, $condition, '*', 'order by sequence');

  my ($email_on_file, $rec);

  while ($rec = $db->getnext) {
    unless ($rec->{domain}) {
      $email_on_file = $rec->{pattern};
    } else {
      unless ($rec->{pattern}) {
        $email_on_file = '@' . $rec->{domain};
      } else {
        $email_on_file = $rec->{pattern} . '@' . $rec->{domain};
      }    # if
    }    # unless

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
    my $search_for =
        $email_on_file =~ /\@/  ? "$email_on_file\$"
      : !defined $rec->{domain} ? "$email_on_file\@"
      :                           $email_on_file;
    if ($sender and $sender =~ /$search_for/i) {
      my $comment = $rec->{comment} ? " - $rec->{comment}" : '';

      $rule =
"Matching rule: ($listtype:$rec->{sequence}) \"$email_on_file$comment\"";
      $rule .= " - $rec->{comment}" if $rec->{comment};
      $status = 1;

      $rec->{hit_count} //= 0;

      RecordHit (
        userid    => $userid,
        type      => $listtype,
        sequence  => $rec->{sequence},
        hit_count => $rec->{hit_count} + 1,
      ) if $update;

      last;
    }    # if
  }    # while

  return ($status, $rule, $rec->{sequence}, $rec->{hit_count});
}    # CheckOnList

sub CleanEmail($;$) {
  my ($timestamp, $dryrun) = @_;

  return _cleanTables 'email', $timestamp, $dryrun;
}    # ClearEmail

sub CleanLog($;$) {
  my ($timestamp, $dryrun) = @_;

  return _cleanTables ('log', $timestamp, $dryrun);
}    # CleanLog

sub CleanList(%) {
  my (%params) = @_;

  CheckParms (['userid', 'type'], \%params);

  my $dryrunstr = $params{dryrun} ? '(dryrun)' : '';

  my $table     = 'list';
  my $condition = "userid='$params{userid}' and type='$params{type}'";
  my $count     = 0;
  my $msg;

  # First let's go through the list to see if we have an domain level entry
  # (e.g. @spammer.com) and also individual entries (baddude@spammer.com) then
  # we don't really need any of the individual entries since the domain block
  # covers them.
  $db->find ($table, $condition, ['domain'], ' and pattern is null');

  while (my $domains = $db->getnext) {
    for my $recs (
      $db->get (
        $table, $condition,
        ['sequence', 'pattern', 'domain'],
        " and domain='$domains->{domain}' and pattern is not null"
      )
      )
    {
      if (@$recs and not $params{dryrun}) {
        for my $rec (@$recs) {
          DeleteList (
            userid   => $params{userid},
            type     => $params{type},
            sequence => $rec->{sequence},
          );

          $params{log}
            ->msg ("Deleted $params{userid}:$params{type}:$rec->{sequence} "
              . "$rec->{pattern}\@$rec->{domain} $dryrunstr")
            if $params{log};

          $count++;
        }    # for
      } elsif (@$recs) {
        if ($params{log}) {
          $params{log}->msg (
            "The domain $domains->{domain} has the following subrecords");

          for my $rec (@$recs) {
            $params{log}->msg ("$rec->{pattern}\@$rec->{domain}");
          }    # for
        }    # if
      }    # if
    }    # for
  }    # while

  $condition =
"userid='$params{userid}' and type='$params{type}' and retention is not null";

  # First see if anything needs to be deleted
  ($count, $msg) = $db->count ($table, $condition);

  return 0 unless $count;

  $count = 0;

  my ($err, $errmsg) = $db->find ($table, $condition);

  croak "Unable to find $params{type} entries for $condition - $errmsg" if $err;

  my $todaysDate = Today2SQLDatetime;

  while (my $rec = $db->getnext) {
    my $days = _retention2Days ($rec->{retention});

    my $agedDate = SubtractDays ($todaysDate, $days);

    # If last_hit < retentiondays then delete
    if (Compare ($rec->{last_hit}, $agedDate) == -1) {
      unless ($params{dryrun}) {
        DeleteList (
          userid   => $params{userid},
          type     => $params{type},
          sequence => $rec->{sequence},
        );

        if ($params{log}) {
          $rec->{pattern} //= '';
          $rec->{domain}  //= '';

          $params{log}
            ->msg ("Deleted $rec->{userid}:$params{type}:$rec->{sequence} "
              . "$rec->{pattern}\@$rec->{domain} $dryrunstr");
          $params{log}
            ->dbug ("last hit = $rec->{last_hit} < agedDate = $agedDate");
        }    # if
      }    # unless

      $count++;
    } else {
      $params{log}->dbug (
        "$rec->{userid}:$params{type}:$rec->{sequence}: nodelete $dryrunstr "
          . "last hit = $rec->{last_hit} >= agedDate = $agedDate")
        if $params{log};
    }    # if
  }    # while

  ResequenceList (
    userid => $params{userid},
    type   => $params{type},
  ) if $count && !$params{dryrun};

  return $count;
}    # CleanList

sub CountEmail(%) {
  my (%params) = @_;

  CheckParms (['userid'], \%params);

  my $table     = 'email';
  my $condition = "userid='$params{userid}'";
  $condition .= " and $params{additional}" if $params{additional};

  return $db->count ($table, $condition);
}    # CountEmail

sub CountList(%) {
  my (%params) = @_;

  CheckParms (['userid', 'type'], \%params);

  my $table     = 'list';
  my $condition = "userid='$params{userid}' and type='$params{type}'";

  return $db->count ($table, $condition);
}    # CountList

sub CountLog(%) {
  my (%params) = @_;

  CheckParms (['userid'], \%params);

  my ($additional_condition) = delete $params{additional} || '';

  my $condition = "userid='$userid'";
  $condition .= " and $additional_condition" if $additional_condition;

  return $db->count ('log', $condition);
}    # CountLog

sub CountLogDistinct(%) {
  my (%params) = @_;

  CheckParms (['userid', 'column'], \%params);

  my ($additional_condition) = delete $params{additional} || '';

  my $condition = "userid='$userid'";
  $condition .= " and $additional_condition" if $additional_condition;

  return $db->count_distinct ('log', $params{column}, $condition);
}    # CountLog

sub Decrypt ($$) {
  my ($password, $userid) = @_;

  return $db->decode ($password, $userid);
}    # Decrypt

sub DeleteEmail(%) {
  my (%rec) = @_;

  my $table = 'email';

  CheckParms (['userid', 'sender'], \%rec);

  my ($username, $domain) = split /@/, $rec{sender};
  my $condition;

  if ($username) {
    $condition = "userid = '$rec{userid}' and sender = '$rec{sender}'";
  } else {
    $condition = "userid = '$rec{userid}' and sender like '%\@$domain'";
  }    # if

  return $db->delete ($table, $condition);
}    # DeleteEmail

sub DeleteList(%) {
  my (%rec) = @_;

  CheckParms (['userid', 'type', 'sequence'], \%rec);

  my $condition =
      "userid = '$rec{userid}' and "
    . "type = '$rec{type}' and "
    . "sequence = $rec{sequence}";

  return $db->delete ('list', $condition);
}    # DeleteList

sub Encrypt($$) {
  my ($password, $userid) = @_;

  return $db->encode ($password, $userid);
}    # Encrypt

sub FindEmail(%) {
  my (%params) = @_;

  CheckParms (['userid'], \%params);

  my $table     = 'email';
  my $condition = "userid='$params{userid}'";
  $condition .= " and sender='$params{sender}'"       if $params{sender};
  $condition .= " and timestamp='$params{timestamp}'" if $params{timestamp};

  return $db->find ($table, $condition);
}    # FindEmail

sub FindList(%) {
  my (%params) = @_;

  my ($type, $sender) = @_;

  CheckParms (['userid', 'type'], \%params);

  my $table     = 'list';
  my $condition = "userid='$params{userid}' and type='$params{type}'";

  if ($params{sender}) {
    my ($username, $domain) = split /\@/, $params{sender};

    # Split will return '' if either username or domain is missing. This messes
    # up SQL's find as '' ~= NULL. Therefore we only specify username or domain
    # if it is present.
    $condition .= " and pattern='$username'" if $username;
    $condition .= " and domain='$domain'"    if $domain;
  }    # if

  return $db->find ($table, $condition);
}    # FindList

sub FindLog($) {
  my ($how_many) = @_;

  my $start_at = 0;
  my $end_at   = CountLog (userid => $userid,);

  if ($how_many < 0) {
    $start_at = $end_at - abs ($how_many);
    $start_at = 0 if ($start_at < 0);
  }    # if

  my $table      = 'log';
  my $condition  = "userid='$userid'";
  my $additional = "order by timestamp limit $start_at, $end_at";

  return $db->find ($table, $condition, '*', $additional);
}    # FindLog

sub FindUser(%) {
  my (%params) = @_;

  my $table     = 'user';
  my $condition = '';

  $condition = "userid='$userid'" if $params{userid};

  return $db->find ($table, $condition, $params{fields});
}    # FindUser

sub FindUsers() {
  return $db->find ('user', '', ['userid']);
}    # FindUsers

sub GetEmail() {
  goto &_getnext;
}    # GetEmail

sub GetContext() {
  return $userid;
}    # GetContext

sub GetList() {
  goto &_getnext;
}    # GetList

sub GetLog() {
  goto &_getnext;
}    # GetLog

sub GetNextSequenceNo(%) {
  my (%rec) = @_;

  CheckParms (['userid', 'type'], \%rec);

  my $table     = 'list';
  my $condition = "userid='$rec{userid}' and type='$rec{type}'";

  my $count = $db->count ('list', $condition);

  return $count + 1;
}    # GetNextSequenceNo

sub GetUser() {
  goto &_getnext;
}    # GetUser

sub GetUserInfo($) {
  my ($userid) = @_;

  return %{$db->getone ('user', "userid='$userid'", ['name', 'email'])};
}    # GetUserInfo

sub GetUserOptions($) {
  my ($userid) = @_;

  my $table     = 'useropts';
  my $condition = "userid='$userid'";

  $db->find ($table, $condition);

  my %useropts;

  while (my $rec = $db->getnext) {
    $useropts{$rec->{name}} = $rec->{value};
  }    # while

  return %useropts;
}    # GetUserOptions

sub Login($$) {
  my ($userid, $password) = @_;

  $password = Encrypt ($password, $userid);

  # Check if user exists
  my $dbpassword = UserExists ($userid);

  # Return -1 if user doesn't exist
  return -1 unless $dbpassword;

  # Return -2 if password does not match
  if ($password eq $dbpassword) {
    SetContext ($userid);
    return 0;
  } else {
    return -2;
  }    # if
}    # Login

sub Nulllist($;$$) {

  # Nulllist will simply discard the message.
  my ($sender, $sequence, $hit_count) = @_;

  RecordHit (
    userid    => $userid,
    type      => 'null',
    sequence  => $sequence,
    hit_count => ++$hit_count,
  ) if $sequence;

  # Discard Message
  Logmsg (
    userid  => $userid,
    type    => 'nulllist',
    sender  => $sender,
    message => 'Discarded message'
  );

  return;
}    # Nulllist

sub OnBlacklist($;$) {
  my ($sender, $update) = @_;

  return CheckOnList2 ('black', $sender, $update);
}    # OnBlacklist

sub OnNulllist($;$) {
  my ($sender, $update) = @_;

  return CheckOnList2 ('null', $sender, $update);
}    # CheckOnNulllist

sub OnWhitelist($;$$) {
  my ($sender, $userid, $update) = @_;

  SetContext ($userid) if $userid;

  return CheckOnList2 ('white', $sender, $update);
}    # OnWhitelist

sub OptimizeDB() {
  my @tables = qw(email list log user useropts);

  my ($err, $msg) = $db->lock ('read', \@tables);

  croak "Unable to lock table - $msg" if $err;

  ($err, $msg) = $db->check (\@tables);

  croak 'Unable to check tables ' . $msg if $err;

  ($err, $msg) = $db->optimize (\@tables);

  croak 'Unable to optimize tables ' . $msg if $err;

  return $db->unlock ();
}    # OptimizeDB

sub ReadMsg($) {
  my ($input) = @_;

  my (%msgInfo, @data, $envelope_sender);

  # Reads an email message file from $input. Returns sender, subject, date and
  # data, which is a copy of the entire message. Find first message's "From "
  # line indicating start of message.
  while (<$input>) {
    chomp;
    last if /^From /;
  }    # while

  # If we hit eof here then the message was garbled. Return indication of this
  return if eof ($input);

  if (/From (\S*)/) {
    $msgInfo{sender_long} = $envelope_sender = $1;
  }    # if

  push @data, $_ if /^From /;

  while (<$input>) {
    chomp;
    chop if /\r$/;

    push @data, $_;

    # Blank line indicates start of message body
    last if ($_ eq '' || $_ eq "\r");

    # Extract sender's address
    if (/^from: (.*)/i) {
      $msgInfo{sender_long} = $msgInfo{sender} = $1;

      if ($msgInfo{sender} =~ /<(\S*)@(\S*)>/) {
        $msgInfo{sender} = lc ("$1\@$2");
      } elsif ($msgInfo{sender} =~ /(\S*)@(\S*)\ /) {
        $msgInfo{sender} = lc ("$1\@$2");
      } elsif ($msgInfo{sender} =~ /(\S*)@(\S*)/) {
        $msgInfo{sender} = lc ("$1\@$2");
      }    # if
    } elsif (/^subject: (.*)/i) {
      $msgInfo{subject} = decode ("utf8", $1);
    } elsif (/^reply-to: (.*)/i) {
      $msgInfo{reply_to} = $1;

      if ($msgInfo{reply_to} =~ /<(\S*)@(\S*)>/) {
        $msgInfo{reply_to} = lc ("$1\@$2");
      } elsif ($msgInfo{reply_to} =~ /(\S*)@(\S*)\ /) {
        $msgInfo{reply_to} = lc ("$1\@$2");
      } elsif ($msgInfo{reply_to} =~ /(\S*)@(\S*)/) {
        $msgInfo{reply_to} = lc ("$1\@$2");
      }    # if
    } elsif (/^to: (.*)/i) {
      $msgInfo{to} = $1;

      if ($msgInfo{to} =~ /<(\S*)@(\S*)>/) {
        $msgInfo{to} = lc ("$1\@$2");
      } elsif ($msgInfo{to} =~ /(\S*)@(\S*)\ /) {
        $msgInfo{to} = lc ("$1\@$2");
      } elsif ($msgInfo{to} =~ /(\S*)@(\S*)/) {
        $msgInfo{to} = lc ("$1\@$2");
      }    # if
    }    # if
  }    # while

  my @body;

  # Read message body
  while (<$input>) {
    chomp;

    last if (/^From /);

    push @body, $_;
  }    # while

  # Set file pointer back by length of the line just read
  seek ($input, -length () - 1, 1) if !eof $input;

  push @data, @body;

  # Sanitize email addresses
  $envelope_sender =~ s/\<//g;
  $envelope_sender =~ s/\>//g;
  $envelope_sender =~ s/\"//g;
  $envelope_sender =~ s/\'//g;

  $msgInfo{sender} =~ s/\<//g;
  $msgInfo{sender} =~ s/\>//g;
  $msgInfo{sender} =~ s/\"//g;
  $msgInfo{sender} =~ s/\'//g;

  if ($msgInfo{reply_to}) {
    $msgInfo{reply_to} =~ s/\<//g;
    $msgInfo{reply_to} =~ s/\>//g;
    $msgInfo{reply_to} =~ s/\"//g;
    $msgInfo{reply_to} =~ s/\'//g;
  }    # if

  # Determine best addresses
  $msgInfo{sender}   = $envelope_sender unless $msgInfo{sender};
  $msgInfo{reply_to} = $msgInfo{sender} unless $msgInfo{reply_to};

  $msgInfo{data} = join "\n", @data;

  return %msgInfo;
}    # ReadMsg

sub RecordHit(%) {
  my (%rec) = @_;

  CheckParms (['userid', 'type', 'sequence'], \%rec);

  my $table = 'list';
  my $condition =
    "userid='$rec{userid}' and type='$rec{type}' and sequence='$rec{sequence}'";

  # We don't need these fields in %rec as we are not updating them
  delete $rec{sequence};
  delete $rec{type};
  delete $rec{userid};

  # We are, however, updating last_hit
  $rec{last_hit} = UnixDatetime2SQLDatetime (scalar (localtime));

  return $db->modify ($table, $condition, %rec);
}    # RecordHit

sub ResequenceList(%) {
  my (%params) = @_;

  CheckParms (['userid', 'type'], \%params);

  # Data checks
  return 1 unless $params{type} =~ /(white|black|null)/;
  return 2 unless UserExists ($params{userid});

  my $table     = 'list';
  my $condition = "userid='$params{userid}' and type ='$params{type}'";

  # Lock the table
  $db->lock ('write', $table);

  # Get all records for $userid and $type
  my $listrecs = $db->get ($table, $condition, '*', 'order by hit_count desc');

  # Delete all of the list entries for this $userid and $type
  my ($count, $msg) = $db->delete ($table, $condition);

  # Now re-add list entries renumbering them
  my $sequence = 1;

  for (@$listrecs) {
    $_->{sequence} = $sequence++;

    my ($err, $msg) = $db->add ($table, %$_);

    croak $msg if $err;
  }    # for

  $db->unlock;

  return 0;
}    # ResequenceList

sub ReturnList(%) {
  my (%params) = @_;

  CheckParms (['userid', 'type'], \%params);

  my $start_at = delete $params{start_at} || 0;
  my $lines    = delete $params{lines}    || 10;

  my $table      = 'list';
  my $condition  = "userid='$params{userid}' and type='$params{type}'";
  my $additional = "order by sequence limit $start_at, $lines";

  return $db->get ($table, $condition, '*', $additional);
}    # ReturnList

sub ReturnMsg(%) {
  my (%params) = @_;

  # ReturnMsg will send back to the $sender the register message.
  # Messages are saved to be delivered when the $sender registers.
  #
  # Added reply_to. Previously we passed reply_to into here as sender. This
  # caused a problem in that we were filtering as per sender but logging it
  # as reply_to. We only need reply_to for SendMsg so as to honor reply_to
  # so we now pass in both sender and reply_to

  CheckParms (['userid', 'sender', 'reply_to', 'subject', 'data'], \%params);

  #my ($sender, $reply_to, $subject, $data) = @_;

  # Check to see if this sender has already emailed us.
  my $msg_count = $db->count ('email',
    "userid='$userid' and sender like '%$params{sender}%'");

  if ($msg_count < $mailLoopMax) {

    # Return register message
    SendMsg (
      userid  => $params{userid},
      sender  => $params{reply_to},
      subject => 'Your email has been returned by MAPS',
      msgfile => "$mapsbase/register.html",
      data    => $params{data},
    ) if $msg_count == 0;

    Logmsg (
      userid  => $params{userid},
      type    => 'returned',
      sender  => $params{sender},
      message => 'Sent register reply',
    );

    # Save message
    SaveMsg ($params{sender}, $params{subject}, $params{data});
  } else {
    Add2Nulllist ($params{sender}, GetContext, "Auto Null List - Mail loop");

    Logmsg (
      userid  => $params{userid},
      type    => 'mailloop',
      sender  => $params{sender},
      message => 'Mail loop encountered',
    );
  }    # if

  return;
}    # ReturnMsg

sub ReturnMessages(%) {
  my (%params) = @_;

  CheckParms (['userid', 'sender'], \%params);

  my $table      = 'email';
  my $condition  = "userid='$params{userid}' and sender='$params{sender}'";
  my $fields     = ['subject', 'timestamp'];
  my $additional = 'group by timestamp order by timestamp desc';

  return $db->get ($table, $condition, $fields, $additional);
}    # ReturnMessages

sub ReturnSenders(%) {
  my (%params) = @_;

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
  CheckParms (['userid', 'type', 'lines'], \%params);

  my $table      = 'log';
  my $condition  = "userid='$params{userid}' and type='$params{type}'";
  my $additional = 'group by timestamp order by timestamp desc';

  $params{start_at} ||= 0;

  if ($params{date}) {
    $condition .= "and timestamp > '$params{date} 00:00:00' and "
      . "timestamp < '$params{date} 23:59:59'";
  }    # if

  $db->find ($table, $condition, '*', $additional);

  # Watch the distinction between senders (plural) and sender (singular)
  my %senders;

  # Run through the results and add to %senders by sender key. This
  # results in a hash that has the sender in it and the first
  # timestamp value. Since we already sorted timestamp desc by the
  # above select statement, and we've narrowed it down to only log
  # message that occurred for the given $date, we will have a hash
  # containing 1 sender and the latest timestamp for the day.
  while (my $rec = $db->getnext) {
    $senders{$rec->{sender}} = $rec->{timestamp}
      unless $senders{$rec->{sender}};
  }    # while

  my (@unsorted, @senders);

  # Here we have a hash in %senders that has email address and timestamp. In the
  # past we would merely create a reverse hash by timestamp and sort that. The
  # The problem is that it is possible for two emails to come in with the same
  # timestamp. By reversing the hash we clobber any row that has a dumplicte
  # timestamp. But we want to sort on timestamp. So first we convers this hash
  # to an array of hashes and then we can sort by timestamp later.
  while (my ($key, $value) = each %senders) {
    push @unsorted, {
      sender    => $key,
      timestamp => $value,
      };
  }    # while

  push @senders, $_->{sender}
    for sort {$b->{timestamp} cmp $a->{timestamp}} @unsorted;

  # Finally slice for the given range
  my $end_at = $params{start_at} + ($params{lines} - 1);

  $end_at = (@senders) - 1 if $end_at >= @senders;

  return (@senders)[$params{start_at} .. $end_at];
}    # ReturnSenders

sub SaveMsg($$$) {
  my ($sender, $subject, $data) = @_;

  AddEmail (
    userid  => $userid,
    sender  => $sender,
    subject => $subject,
    data    => $data,
  );

  return;
}    # SaveMsg

sub SearchEmails(%) {
  my (%params) = @_;

  CheckParms (['userid', 'search'], \%params);

  my $table  = 'email';
  my $fields = ['sender', 'subject', 'timestamp'];
  my $condition =
      "userid='$params{userid}' and (sender like '\%$params{search}\%' "
    . "or subject like '\%$params{search}\%')";
  my $additional = 'order by timestamp desc';

  my ($err, $msg) = $db->find ($table, $condition, $fields, $additional);

  my @emails;

  while (my $rec = $db->getnext) {
    push @emails, $rec;
  }    # while

  return @emails;
}    # SearchEmails

sub SendMsg(%) {

  # SendMsg will send the message contained in $msgfile.
  my (%params) = @_;

  #my ($sender, $subject, $msgfile, $userid, @spammsg) = @_;

  my @lines;

  # Open return message template file
  open my $return_msg_file, '<', $params{msgfile}
    or die "Unable to open return msg file ($params{msgfile}): $!\n";

  # Read return message template file and print it to $msg_body
  while (<$return_msg_file>) {
    if (/\$userid/) {

      # Replace userid
      s/\$userid/$userid/;
    }    # if
    if (/\$sender/) {

      # Replace sender
      s/\$sender/$params{sender}/;
    }    #if

    push @lines, $_;
  }    # while

  close $return_msg_file;

  # Create the message, and set up the mail headers:
  my $msg = MIME::Entity->build (
    From    => "MAPS\@DeFaria.com",
    To      => $params{sender},
    Subject => $params{subject},
    Type    => "text/html",
    Data    => \@lines
  );

  # Need to obtain the spam message here...
  my @spammsg = split "\n", $params{data};

  $msg->attach (
    Type        => "message",
    Disposition => "attachment",
    Data        => \@spammsg
  );

  # Send it
  open my $mail, '|-', '/usr/lib/sendmail -t -oi -oem'
    or croak "SendMsg: Unable to open pipe to sendmail $!";

  $msg->print (\*$mail);

  close $mail;

  return;
}    # SendMsg

sub SetContext($) {
  my ($to_user) = @_;

  if (UserExists ($to_user)) {
    $userid = $to_user;

    return GetUserOptions $userid;
  } else {
    return 0;
  }    # if
}    # SetContext

sub Space($) {
  my ($userid) = @_;

  my $total_space = 0;
  my $table       = 'email';
  my $condition   = "userid='$userid'";

  $db->find ($table, $condition);

  while (my $rec = $db->getnext) {
    $total_space +=
      length ($rec->{userid}) +
      length ($rec->{sender}) +
      length ($rec->{subject}) +
      length ($rec->{timestamp}) +
      length ($rec->{data});
  }    # while

  return $total_space;
}    # Space

sub UpdateList(%) {
  my (%rec) = @_;

  CheckParms (['userid', 'type', 'sequence'], \%rec);

  my $table = 'list';
  my $condition =
"userid = '$rec{userid}' and type = '$rec{type}' and sequence = $rec{sequence}";

  if ($rec{pattern} =~ /\@/ && !$rec{domain}) {
    ($rec{pattern}, $rec{domain}) = split /\@/, $rec{pattern};
  } elsif (!$rec{pattern} && $rec{domain} =~ /\@/) {
    ($rec{pattern}, $rec{domain}) = split /\@/, $rec{domain};
  } elsif (!$rec{pattern} && !$rec{domain}) {
    return "Must specify either Username or Domain";
  }    # if

  $rec{pattern} //= 'null';
  $rec{domain}  //= 'null';
  $rec{comment} //= 'null';

  if ($rec{retention}) {
    $rec{retention} = lc $rec{retention};
  }    # if

  return $db->update ($table, $condition, %rec);
}    # UpdateList

sub UpdateUser(%) {
  my (%rec) = @_;

  CheckParms (['userid', 'name', 'email'], \%rec);

  return 1 unless UserExists ($rec{userid});

  my $table     = 'user';
  my $condition = "userid='$rec{userid}'";

  return $db->update ($table, $condition, %rec);
}    # UpdateUser

sub UpdateUserOptions ($@) {
  my ($userid, %options) = @_;

  return unless UserExists ($userid);

  my $table     = 'useropts';
  my $condition = "userid='$userid' and name=";

  $db->update ($table, "$condition'$_'", (name => $_, value => $options{$_}))
    for (keys %options);

  return;
}    # UpdateUserOptions

sub UserExists($) {
  my ($userid) = @_;

  return 0 unless $userid;

  my $table     = 'user';
  my $condition = "userid='$userid'";

  my $rec = $db->get ($table, $condition);

  return 0 if scalar (@$rec) == 0;

  return $rec->[0]{password};
}    # UserExists

sub Whitelist ($$;$$) {

  # Whitelist will deliver the message.
  my ($sender, $data, $sequence, $hit_count) = @_;

  my $userid = GetContext;

  # Dump message into a file
  my $msgfile = "/tmp/MAPSMessage.$$";

  open my $message, '>', $msgfile
    or error ("Unable to open message file ($msgfile): $!\n"), return -1;

  print $message $data;

  close $message;

  # Now call MAPSDeliver
  my ($status, @output) = Execute "$FindBin::Bin/MAPSDeliver $userid $msgfile";

  if ($status != 0) {
    my $msg = "Unable to deliver message (message left at $msgfile\n\n";
    $msg .= join "\n", @output;

    Logmsg (
      userid  => $userid,
      type    => 'whitelist',
      sender  => $sender,
      message => $msg,
    );

    Error ($msg, 1);
  }    # if

  unlink $msgfile;

  if ($status == 0) {
    Logmsg (
      userid  => $userid,
      type    => 'whitelist',
      sender  => $sender,
      message => 'Delivered message',
    );
  } else {
    error ("Unable to deliver message - is MAPSDeliver setgid? - $!", $status);
  }    # if

  $hit_count++ if $sequence;

  RecordHit (
    userid    => $userid,
    type      => 'white',
    sequence  => $sequence,
    hit_count => $hit_count,
  );

  return $status;
}    # Whitelist

1;
