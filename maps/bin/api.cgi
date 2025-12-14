#!/usr/bin/perl
use strict;
use warnings;

use JSON;
use CGI;
use FindBin;

use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../lib";

use MAPS;
use MAPSLog;
use DateUtils;

my $q = CGI->new;
print $q->header ('application/json');

my $action = $q->param ('action') || '';

sub send_json {
  my ($data) = @_;
  print encode_json($data);
  exit;
}

if ($action eq 'login') {
  my $user = $q->param ('username');
  my $pass = $q->param ('password');

  my $res = MAPS::Login ($user, $pass);

  if ($res == 0) {
    send_json ({status => 'success', userid => $user});
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

} else {
  send_json ({status => 'error', message => 'Unknown action'});
}
