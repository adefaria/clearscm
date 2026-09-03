#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 7;
use FindBin;

use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../lib";

use MAPS qw(CheckSPF CheckDKIM CheckDMARC ReadMsg SendMsg);

# Test 1: CheckSPF handles missing or invalid inputs gracefully
is(CheckSPF(undef, 'sender@example.com', 'example.com'), 'none', 'CheckSPF returns none without IP');

# Test 2: CheckDKIM handles plain unsigned message
my $raw_msg = "From: sender\@example.com\nSubject: Test\n\nThis is a test body.\n";
is(CheckDKIM($raw_msg), 'none', 'CheckDKIM returns none for unsigned message');

# Test 3: CheckDMARC handles aligned pass inputs
is(CheckDMARC('example.com', 'pass', 'pass', 'sender@example.com', '127.0.0.1'), 'pass', 'CheckDMARC passes with passing SPF & DKIM');

# Test 4: CheckDMARC handles failing inputs
is(CheckDMARC('google.com', 'fail', 'fail', 'sender@google.com', '1.2.3.4'), 'fail', 'CheckDMARC fails with failing SPF & DKIM');

# Test 5 & 6: Header parsing of Received header & client IP extraction
my $email_with_received = <<'EOM';
From sender@example.com Sat Aug 24 10:00:00 2026
Received: from mail.example.com (mail.example.com [198.51.100.25]) by defaria.com with ESMTP id 12345; Sat, 24 Aug 2026 10:00:00 -0700
From: Sender <sender@example.com>
To: Andrew <andrew@defaria.com>
Subject: Test Email

Hello world.
EOM

open my $fh, '<', \$email_with_received or die "Cannot open memory string: $!";
my %msgInfo = ReadMsg($fh, 1);
close $fh;

is($msgInfo{client_ip}, '198.51.100.25', 'Extracted client IP from Received header');
is($msgInfo{sender}, 'sender@example.com', 'Extracted sender address correctly');

# Test 7: Verify MIME Entity creation with Cc header
my %msg_headers = (
  From    => "MAPS\@DeFaria.com",
  To      => 'sender@example.com',
  Subject => 'Test Auth Failure Notice',
  Type    => 'text/html',
  Data    => ['<p>Test Notice</p>'],
  Cc      => 'Andrew@DeFaria.com',
);
my $mime = MIME::Entity->build(%msg_headers);
is($mime->head->get('Cc'), "Andrew\@DeFaria.com\n", 'CC header attached correctly in MIME Entity');
