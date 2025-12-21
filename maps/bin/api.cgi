#!/usr/bin/perl
use strict;
use warnings;

use JSON;
use CGI;
use FindBin;

use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../lib";

use MAPS;
use MAPSWeb;
use MAPSLog;
use DateUtils;

my $q = CGI->new;

my $action = $q->param ('action') || '';
$action =~ s/^\s+|\s+$//g;

my $start = $q->param ('start') || 0;
my $lines = $q->param ('lines') || 20;

sub send_json {
  my ($data, $cookie) = @_;
  if ($cookie) {
    print $q->header (-type => 'application/json', -cookie => $cookie);
  } else {
    print $q->header ('application/json');
  }
  print encode_json($data);
  exit;
} ## end sub send_json

if ($action eq 'login') {
  my $user = $q->param ('username');
  my $pass = $q->param ('password');

  my $res = MAPS::Login ($user, $pass);

  if ($res == 0) {
    my $cookie = $q->cookie (
      -name    => 'MAPSUser',
      -value   => $user,
      -expires => '+30d',
      -path    => '/maps'
    );
    send_json ({status => 'success', userid => $user}, $cookie);
  } else {
    send_json ({status => 'error', message => 'Invalid credentials'});
  }
} ## end if ($action eq 'login')

my $userid = $q->param ('userid');
unless ($userid) {
  send_json ({status => 'error', message => 'Missing userid'});
}

MAPS::SetContext ($userid);

if ($action eq 'stats') {
  my $today = Today2SQLDatetime;
  my $date  = substr $today, 0, 10;

  my %stats = MAPSLog::GetStats (
    userid => $userid,
    days   => 1,
    date   => $date
  );

  my $data = $stats{$date} || {};

  my $processed = 0;
  foreach my $type (@MAPSLog::Types) {
    $processed += $data->{$type} || 0;
  }
  $data->{processed} = $processed;

  send_json ({status => 'success', data => $data});

} elsif ($action eq 'top20') {
  my $data = \@{[MAPS::ReturnTopDomains (userid => $userid, lines => 20)]};
  send_json ({status => 'success', data => $data});

} elsif ($action eq 'returned') {
  my $date     = $q->param ('date') || substr (Today2SQLDatetime, 0, 10);
  my $req_type = $q->param ('type') || 'returned';
  if    ($req_type eq 'white') {$req_type = 'whitelist';}
  elsif ($req_type eq 'black') {$req_type = 'blacklist';}
  elsif ($req_type eq 'null')  {$req_type = 'nulllist';}

  my @senders = MAPS::ReturnSenders (
    userid   => $userid,
    type     => $req_type,
    lines    => $lines,
    start_at => $start,
    date     => $date
  );
  my @data;
  foreach my $sender (@senders) {
    my $msgs     = MAPS::ReturnMessages (userid => $userid, sender => $sender);
    my @day_msgs = grep {$_->{timestamp} =~ /^$date/} @$msgs;

    my %list_info;
    foreach my $type (qw(white black null)) {
      my ($status, $rec) = MAPS::CheckOnList2 ($type, $sender, 0);
      if ($status) {
        $list_info{list}      = ucfirst ($type);
        $list_info{hits}      = $rec->{hit_count};
        $list_info{retention} = $rec->{retention};
        $list_info{comment}   = $rec->{comment};
        $list_info{sequence}  = $rec->{sequence};

        my $p = $rec->{pattern} // '';
        my $d = $rec->{domain}  // '';
        if    ($p && $d) {$list_info{rule} = "$p\@$d";}
        elsif ($d)       {$list_info{rule} = "\@$d";}
        else             {$list_info{rule} = $p;}

        last;
      }    # if
    }    # foreach

    push @data, {sender => $sender, messages => \@day_msgs, %list_info};
  } ## end foreach my $sender (@senders)
  send_json ({status => 'success', data => \@data});

} elsif ($action eq 'display') {
  my $sender       = $q->param ('sender');
  my $msg_date     = $q->param ('msg_date');
  my $header_color = $q->param ('header_color');
  my $html         = MAPSWeb::GetMessageDisplay (
    userid       => $userid,
    sender       => $sender,
    msg_date     => $msg_date,
    header_color => $header_color
  );
  send_json ({status => 'success', data => $html});

} elsif ($action =~ /^add_(white|black|null)$/) {
  my $type      = $1;
  my $sender    = $q->param ('sender');
  my $retention = $q->param ('retention');
  my $comment   = $q->param ('comment');
  my $msg       = '';
  my $res;

  $sender = '@' . $sender unless $sender =~ /@/;

  my $ret_msg;
  if ($type eq 'white') {
    ($res, $ret_msg) = MAPS::Add2Whitelist (
      userid    => $userid,
      sender    => $sender,
      retention => $retention,
      comment   => $comment
    );
    send_json ({status => 'error', message => $ret_msg}) if $res < 0;
    $msg = "Added $sender to whitelist";
  } elsif ($type eq 'black') {
    ($res, $ret_msg) = MAPS::Add2Blacklist (
      userid    => $userid,
      sender    => $sender,
      retention => $retention,
      comment   => $comment
    );
    send_json ({status => 'error', message => $ret_msg}) if $res < 0;
    $msg = "Added $sender to blacklist";
  } elsif ($type eq 'null') {
    ($res, $ret_msg) = MAPS::Add2Nulllist (
      userid    => $userid,
      sender    => $sender,
      retention => $retention,
      comment   => $comment
    );
    send_json ({status => 'error', message => $ret_msg})
      if defined $res && $res < 0;
    $msg = "Added $sender to nulllist";
  } ## end elsif ($type eq 'null')

  $msg .= " - $ret_msg" if defined $res && $res > 0;
  send_json ({status => 'success', message => $msg});

} elsif ($action eq 'get_whole_list') {
  my $type = $q->param ('type');
  my ($list) = MAPS::ReturnWholeList (
    userid => $userid,
    type   => $type
  );
  send_json ({status => 'success', data => $list});

} elsif ($action eq 'update_list') {
  my $type      = $q->param ('type');
  my $sequence  = $q->param ('sequence');
  my $pattern   = $q->param ('pattern');
  my $domain    = $q->param ('domain');
  my $hit_count = $q->param ('hit_count');
  my $retention = $q->param ('retention');
  my $comment   = $q->param ('comment');

  my ($err, $msg) = MAPS::UpdateList (
    userid    => $userid,
    type      => $type,
    sequence  => $sequence,
    pattern   => $pattern,
    domain    => $domain,
    hit_count => $hit_count,
    retention => $retention,
    comment   => $comment
  );

  send_json ({status => 'error',   message => $msg}) if $err;
  send_json ({status => 'success', message => 'Entry updated'});

} elsif ($action eq 'search') {
  my $str    = $q->param ('str');
  my @emails = MAPS::SearchEmails (
    userid => $userid,
    search => $str
  );
  send_json ({status => 'success', data => \@emails});

} elsif ($action eq 'check_list_entry') {
  my $type   = $q->param ('type');
  my $sender = $q->param ('sender');
  my ($status, $rec) = MAPS::CheckOnList2 ($type, $sender, 0);

  if ($status) {
    send_json ({status => 'found', data => $rec});
  } else {
    send_json ({status => 'not_found'});
  }

} elsif ($action eq 'check_address') {
  my $email = $q->param ('email');
  $email = lc $email;
  my ($user, $domain) = $email =~ /(.+)\@(.+)/;
  my $msg;

  if (!$user || !$domain) {
    $msg = "Illegal email address $email";
  } else {
    my $username = lc $userid;
    if ($domain eq "defaria.com" && $user ne $username) {
      $msg = "Nulllist - $email is from this domain but is not from $username";
    } else {
      my ($status, $rec);
      if (($status, $rec) = MAPS::OnWhitelist ($email, $username, 0)
        and $status)
      {
        $msg =
            "Sender $email would be whitelisted (Matches: "
          . ($rec->{pattern} // '') . '@'
          . ($rec->{domain}  // '') . ")";
      } elsif (($status, $rec) = MAPS::OnBlacklist ($email, 0) and $status) {
        $msg =
            "Sender $email would be blacklisted (Matches: "
          . ($rec->{pattern} // '') . '@'
          . ($rec->{domain}  // '') . ")";
      } elsif (($status, $rec) = MAPS::OnNulllist ($email, 0) and $status) {
        $msg =
            "Sender $email would be nulllisted (Matches: "
          . ($rec->{pattern} // '') . '@'
          . ($rec->{domain}  // '') . ")";
      } else {
        $msg = "Sender $email would be returned";
      }
    } ## end else [ if ($domain eq "defaria.com"...)]
  } ## end else [ if (!$user || !$domain)]
  send_json ({status => 'success', message => $msg});

} elsif ($action =~ /^(white|black|null)$/) {
  my ($list) = MAPS::ReturnList (
    userid   => $userid,
    type     => $action,
    lines    => $lines,
    start_at => $start
  );
  send_json ({status => 'success', data => $list});

} else {
  send_json ({status => 'error', message => "Unknown action: '$action'"});
}
