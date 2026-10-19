#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 24;
use FindBin;

# Prevent test suite from sending real emails over SMTP to admin and abuse desks
$ENV{MAPS_TEST_NO_DISPATCH} = 1;

use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../lib";

use MAPS qw(
  AddEmail
  DeleteEmail
  DeleteList
  ExtractPhishingDetails
  FindList
  GetBaseDomain
  IsProtectedDomain
  OnNulllist
  ReportPhishing
);

#-------------------------------------------------------------------------------
# 1. Unit Tests: IsProtectedDomain & Guardrails
#-------------------------------------------------------------------------------
my ($prot1, $name1) = IsProtectedDomain('gmail.com');
ok($prot1 && $name1 eq 'gmail.com', 'IsProtectedDomain matches exact protected domain');

my ($prot2, $name2) = IsProtectedDomain('mail.protection.outlook.com');
ok($prot2 && $name2 eq 'outlook.com', 'IsProtectedDomain matches subdomain of protected domain');

my ($prot3, undef) = IsProtectedDomain('evil-phish.com');
ok(!$prot3, 'IsProtectedDomain returns false for non-protected domain');

# Crucial security test: Deceptive suffix spoofing must NOT trigger guardrail
my ($prot4, undef) = IsProtectedDomain('gmail.com.attacker.net');
ok(!$prot4, 'IsProtectedDomain correctly rejects deceptive domain (gmail.com.attacker.net)');

#-------------------------------------------------------------------------------
# 2. Unit Tests: GetBaseDomain extraction
#-------------------------------------------------------------------------------
is(GetBaseDomain('mail.sxjdms.com'), 'sxjdms.com', 'GetBaseDomain extracts SLD for standard gTLD');
is(GetBaseDomain('phish.bank.co.uk'), 'bank.co.uk', 'GetBaseDomain extracts ccTLD domain correctly');
is(GetBaseDomain('portal.defence.gov.au'), 'defence.gov.au', 'GetBaseDomain extracts 3-part ccTLD correctly');

#-------------------------------------------------------------------------------
# 3. Unit Tests: ExtractPhishingDetails
#-------------------------------------------------------------------------------
# Realistic Tastytrade lure
my $tastytrade_lure = <<'EOM';
From noreply@mail.sxjdms.com Mon Oct 19 09:00:00 2026
Return-Path: <Noreply@mail.sxjdms.com>
Received: from mail.sxjdms.com (mail.sxjdms.com [185.230.124.201])
    by defaria.com with ESMTP id ABC12345;
    Mon, 19 Oct 2026 09:00:00 -0700
DKIM-Signature: v=1; a=rsa-sha256; c=relaxed/relaxed; s=gammadyne; d=sxjdms.com;
From: Tastytrade Support <Noreply@mail.sxjdms.com>
To: Andrew <Andrew@DeFaria.com>
Subject: Action Required: Form W-9 Verification
Message-ID: <20261019090000.12345@mail.sxjdms.com>

Please update your tax documents immediately.
EOM

my $phish1 = ExtractPhishingDetails($tastytrade_lure);
is($phish1->{envelope_domain}, 'mail.sxjdms.com', 'Extracts envelope domain from Return-Path');
is($phish1->{dkim_domain}, 'sxjdms.com', 'Extracts DKIM domain');
is($phish1->{originating_ip}, '185.230.124.201', 'Extracts connecting IP from Received header');
is($phish1->{brand}, 'Tastytrade', 'Extracts brand from display name');
is($phish1->{offending_domain}, 'sxjdms.com', 'Identifies base domain as offending domain');
ok(!$phish1->{is_protected}, 'Offending domain is correctly marked as not protected');

# Fallback test: Lure with no Return-Path (must fall back to From domain)
my $from_fallback_lure = <<'EOM';
From: "PayPal Security" <alert@security-paypal-update.org>
To: Andrew <Andrew@DeFaria.com>
Subject: Account Suspended

Please login to restore access.
EOM

my $phish_fallback = ExtractPhishingDetails($from_fallback_lure);
is($phish_fallback->{offending_domain}, 'security-paypal-update.org', 'Falls back to From domain when Return-Path is absent');
is($phish_fallback->{brand}, 'PayPal', 'Extracts brand from From display name');

# Protected provider test
my $gmail_phish = <<'EOM';
Return-Path: <spammer12345@gmail.com>
Received: from mail-relay.google.com ([209.85.220.41]) by defaria.com;
From: Account Alert <spammer12345@gmail.com>
Subject: Security Notification

Click here to verify.
EOM

my $phish2 = ExtractPhishingDetails($gmail_phish);
ok($phish2->{is_protected}, 'Protected provider correctly intercepted by guardrail');

#-------------------------------------------------------------------------------
# 4. End-to-End Integration Tests: Full ReportPhishing Workflow
#-------------------------------------------------------------------------------
my $test_user = 'andrew';
my $offending_sender = 'badguy@attack-test-fixture.org';
my $offending_domain = 'attack-test-fixture.org';

# Insert test email fixture into MAPS email table
my $test_raw_email = <<"EOM";
From $offending_sender Mon Oct 19 10:00:00 2026
Return-Path: <$offending_sender>
Received: from mail.$offending_domain (mail.$offending_domain [198.51.100.99]) by defaria.com;
From: "Tastytrade Spoof" <$offending_sender>
To: $test_user\@defaria.com
Subject: Test Phishing Message
Message-ID: <test-fixture-1234\@$offending_domain>

Test body content.
EOM

AddEmail(
  userid    => $test_user,
  sender    => $offending_sender,
  subject   => 'Test Phishing Message',
  timestamp => '2026-10-19 10:00:00',
  data      => $test_raw_email,
);

# Execute ReportPhishing
my ($err, $msg, $stats) = ReportPhishing(
  userid => $test_user,
  sender => $offending_sender,
);

is($err, 0, 'ReportPhishing executed with 0 error code');
is($stats->{processed}, 1, 'ReportPhishing processed exactly 1 message');
is($stats->{domain}, $offending_domain, 'ReportPhishing targeted correct offending domain');

# Verify Postfix MTA block
my $postmap_check = `postmap -q "$offending_domain" hash:/etc/postfix/sender_access`;
chomp $postmap_check;
is($postmap_check, 'REJECT Phishing / Spoofed domain', 'MTA block confirmed in Postfix sender_access map');

# Verify MAPS Nulllist entry
my ($n_status, $n_rec) = OnNulllist("\@$offending_domain", 0);
ok($n_status, 'Domain added to MAPS Nulllist table');

# Protected Domain End-to-End Test: Report phishing from a Gmail address
my $gmail_sender = 'spammer999@gmail.com';
AddEmail(
  userid    => $test_user,
  sender    => $gmail_sender,
  subject   => 'Gmail Phish Test',
  timestamp => '2026-10-19 10:00:00',
  data      => "Return-Path: <$gmail_sender>\nFrom: $gmail_sender\nSubject: Test\n\nBody\n",
);

my ($g_err, $g_msg, $g_stats) = ReportPhishing(
  userid => $test_user,
  sender => $gmail_sender,
);

is($g_err, 0, 'Protected domain ReportPhishing completed successfully');
like($g_stats->{mta_status}, qr/MTA block skipped/, 'Protected domain was skipped from MTA domain-wide block');

my $gmail_postmap = `postmap -q "gmail.com" hash:/etc/postfix/sender_access`;
is($gmail_postmap, '', 'Protected domain gmail.com was NOT added to Postfix sender_access');

#-------------------------------------------------------------------------------
# 5. Cleanup Test Artifacts
#-------------------------------------------------------------------------------
# Clean up Postfix sender_access
system("sudo bash -c 'sed -i \"/$offending_domain/d\" /etc/postfix/sender_access && postmap /etc/postfix/sender_access'");

# Clean up MAPS Nulllist
DeleteList(
  userid   => $test_user,
  type     => 'null',
  sequence => $n_rec->{sequence},
) if $n_rec && $n_rec->{sequence};
