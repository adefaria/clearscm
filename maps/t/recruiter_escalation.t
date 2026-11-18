#!/usr/bin/perl
################################################################################
#
# File:         recruiter_escalation.t
# Description:  Unit and integration tests for Recruiter Domain Strike
#               Escalation & Blacklist Consolidation (MAPS.pm &
#               bin/audit_recruiter_domains.pl)
#
################################################################################
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Temp qw(tempfile);

$ENV{MAPS_TEST_NO_DISPATCH} = 1;

use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../lib";

use MAPS qw(
  %FREE_DOMAINS
  Add2Blacklist
  Add2Whitelist
  check_and_escalate_recruiter_domain
  DeleteList
  FindList
  GetList
  IsFreeDomain
  OnBlacklist
  ResequenceList
);

my $test_user = 'andrew';
my $dbh       = $MAPS::db->{db};

#-------------------------------------------------------------------------------
# 1. Public / Shared Email Provider Exclusion Guardrails (%FREE_DOMAINS)
#-------------------------------------------------------------------------------
my @required_free_domains = qw(
  gmail.com yahoo.com hotmail.com outlook.com aol.com icloud.com
  me.com mac.com protonmail.com proton.me live.com msn.com
  comcast.net sbcglobal.net att.net verizon.net cox.net
);

for my $dom (@required_free_domains) {
  ok ($FREE_DOMAINS{$dom}, "%FREE_DOMAINS contains required public provider: $dom");
  my ($is_free, $match) = IsFreeDomain ($dom);
  ok ($is_free && $match eq $dom, "IsFreeDomain matches $dom");
}

my ($sub_free, $sub_match) = IsFreeDomain ('mail.proton.me');
ok ($sub_free && $sub_match eq 'proton.me', 'IsFreeDomain matches subdomain of public provider');

my ($spoof_free, undef) = IsFreeDomain ('gmail.com.staffing-spam.org');
ok (!$spoof_free, 'IsFreeDomain rejects deceptive suffix domain gmail.com.staffing-spam.org');

#-------------------------------------------------------------------------------
# 2. Read-Only Guarantee for audit_recruiter_domains.pl (Default --dry-run)
#-------------------------------------------------------------------------------
my $count_before = $MAPS::db->count ('list', "userid='$test_user' and type='black'");
my ($tmp_fh, $tmp_report) = tempfile ('maps_recruiter_audit_XXXX', DIR => '/tmp', SUFFIX => '.txt');
close $tmp_fh;

my $audit_script = "$FindBin::Bin/../bin/audit_recruiter_domains.pl";
my $dry_out      = `$audit_script --output="$tmp_report" 2>&1`;
my $dry_rc       = $? >> 8;

is ($dry_rc, 0, 'audit_recruiter_domains.pl default dry-run exited with 0');
like ($dry_out, qr/DRY-RUN \(Read-Only Audit/, 'Dry-run output indicates read-only mode');
like ($dry_out, qr/SUMMARY METRICS/, 'Dry-run output contains Summary Metrics section');
like ($dry_out, qr/CONSOLIDATION CANDIDATES OVERVIEW/, 'Dry-run output contains Consolidation Candidates section');
like ($dry_out, qr/SKIPPED \/ FLAGGED EXCEPTIONS/, 'Dry-run output contains Skipped / Flagged Exceptions section');
ok (-s $tmp_report, '--output file was written and is non-empty');
unlink $tmp_report;

my $count_after = $MAPS::db->count ('list', "userid='$test_user' and type='black'");
is ($count_after, $count_before, 'Default --dry-run executed zero INSERT/DELETE changes on blacklist');

#-------------------------------------------------------------------------------
# 3. Ongoing Real-Time Strike Escalation via Add2Blacklist
#-------------------------------------------------------------------------------
my $rt_domain  = 'test-recruiter-escalate-rt.org';
my $rt_sender1 = "alice\@$rt_domain";
my $rt_sender2 = "bob\@$rt_domain";

cleanup_test_domain ($rt_domain);

# Strike 1: Should add individual entry and NOT escalate yet
my ($c1, $msg1) = Add2Blacklist (
  userid  => $test_user,
  sender  => $rt_sender1,
  comment => 'Recruiter',
);
ok ($c1 >= 0, "Strike 1 added for $rt_sender1");
unlike ($msg1, qr/Escalated/i, 'Strike 1 does not trigger domain escalation');

my $rt_dom_cnt1 = $MAPS::db->count (
  'list',
  "userid='$test_user' and type='black' and domain='$rt_domain' and (pattern is null or pattern='')"
);
is ($rt_dom_cnt1, 0, 'No whole-domain block after 1st strike');

# Strike 2: Should automatically escalate to whole-domain block, remove individual rows, and update Postfix
my ($c2, $msg2) = Add2Blacklist (
  userid  => $test_user,
  sender  => $rt_sender2,
  comment => 'recruiter - follow up',
);
ok ($c2 >= 0, "Strike 2 added for $rt_sender2");
like ($msg2, qr/Escalated \@\Q$rt_domain\E to whole-domain block \(2 strikes\)/i, 'Strike 2 automatically escalates domain');

my $rt_dom_row = $MAPS::db->getone (
  'list',
  "userid='$test_user' and type='black' and domain='$rt_domain' and (pattern is null or pattern='')",
  ['pattern', 'domain', 'comment']
);
ok ($rt_dom_row, "Whole-domain block entry created in list for \@$rt_domain");
like ($rt_dom_row->{comment}, qr/recruiter - consolidated domain block \(2 strikes\)/i, 'Consolidated comment preserves strike count');

my $rt_indiv_cnt = $MAPS::db->count (
  'list',
  "userid='$test_user' and type='black' and domain='$rt_domain' and pattern is not null and pattern != ''"
);
is ($rt_indiv_cnt, 0, "Redundant individual rows removed for $rt_domain");

# Verify Postfix sender_access entry
my $postmap_rt = `postmap -q "$rt_domain" hash:/etc/postfix/sender_access`;
chomp $postmap_rt;
like ($postmap_rt, qr/^REJECT\b/, "Postfix sender_access map contains REJECT rule for $rt_domain");

#-------------------------------------------------------------------------------
# 4. Safeguard Verification: Public Provider Never Escalates
#-------------------------------------------------------------------------------
my $pub_sender1 = 'test_recruiter_alpha_991@proton.me';
my $pub_sender2 = 'test_recruiter_beta_992@proton.me';

my ($es_pub, $es_pub_msg) = check_and_escalate_recruiter_domain ($dbh, $pub_sender1, 2, $test_user);
is ($es_pub, 0, 'check_and_escalate_recruiter_domain refuses to escalate proton.me');
like ($es_pub_msg, qr/Skipped public\/shared email provider/i, 'Refusal message cites public provider exclusion');

my $proton_postmap = `postmap -q "proton.me" hash:/etc/postfix/sender_access`;
chomp $proton_postmap;
is ($proton_postmap, '', 'Public provider proton.me was NOT added to Postfix sender_access');

#-------------------------------------------------------------------------------
# 5. Safeguard Verification: Whitelist Precedence Blocks Escalation
#-------------------------------------------------------------------------------
my $wl_domain  = 'test-recruiter-wl-conflict.org';
my $wl_friend  = "trusted.colleague\@$wl_domain";
my $wl_spam1   = "spam.recruiter1\@$wl_domain";
my $wl_spam2   = "spam.recruiter2\@$wl_domain";

cleanup_test_domain ($wl_domain);

Add2Whitelist (
  userid  => $test_user,
  sender  => $wl_friend,
  comment => 'Trusted contact',
);

Add2Blacklist (
  userid  => $test_user,
  sender  => $wl_spam1,
  comment => 'Recruiter',
);
my ($wl_c2, $wl_msg2) = Add2Blacklist (
  userid  => $test_user,
  sender  => $wl_spam2,
  comment => 'Recruiter',
);

unlike ($wl_msg2, qr/Escalated/i, 'Domain with active whitelist entry was NOT auto-escalated on 2nd strike');

my $wl_dom_cnt = $MAPS::db->count (
  'list',
  "userid='$test_user' and type='black' and domain='$wl_domain' and (pattern is null or pattern='')"
);
is ($wl_dom_cnt, 0, 'No whole-domain blacklist entry created for whitelisted domain');

#-------------------------------------------------------------------------------
# 6. Phase 2A Batch Consolidation: audit_recruiter_domains.pl --execute --domains=...
#-------------------------------------------------------------------------------
my $batch_domain = 'test-recruiter-batch-exec.org';
cleanup_test_domain ($batch_domain);

# Insert 3 individual recruiter rows directly (simulating pre-existing historical rows)
for my $u (qw(rec1 rec2 rec3)) {
  my $seq = MAPS::GetNextSequenceNo (userid => $test_user, type => 'black');
  $MAPS::db->add (
    'list',
    userid    => $test_user,
    type      => 'black',
    pattern   => $u,
    domain    => $batch_domain,
    comment   => 'Recruiter',
    sequence  => $seq,
    hit_count => 2,
    last_hit  => '2026-10-01 12:00:00',
  );
}

my $exec_out = `$audit_script --execute --domains="$batch_domain" 2>&1`;
my $exec_rc  = $? >> 8;

is ($exec_rc, 0, 'audit_recruiter_domains.pl --execute exited with 0');
like ($exec_out, qr/\[CONSOLIDATED\] \@\Q$batch_domain\E\s+\|\s+3 strikes/, '--execute output logs consolidated domain and 3 strikes');

my $batch_dom_row = $MAPS::db->getone (
  'list',
  "userid='$test_user' and type='black' and domain='$batch_domain' and (pattern is null or pattern='')",
  ['domain', 'comment', 'hit_count']
);
ok ($batch_dom_row, "Whole-domain entry created for $batch_domain by --execute");
is ($batch_dom_row->{hit_count}, 6, 'Consolidated row summed hit_count (2+2+2=6) from individual entries');
like ($batch_dom_row->{comment}, qr/recruiter - consolidated domain block \(3 strikes\)/i, 'Consolidated comment records 3 strikes');

my $batch_indiv_after = $MAPS::db->count (
  'list',
  "userid='$test_user' and type='black' and domain='$batch_domain' and pattern is not null and pattern != ''"
);
is ($batch_indiv_after, 0, "Individual rows deleted for $batch_domain by --execute");

my $postmap_batch = `postmap -q "$batch_domain" hash:/etc/postfix/sender_access`;
chomp $postmap_batch;
like ($postmap_batch, qr/^REJECT\b/, "Postfix sender_access updated for $batch_domain by --execute");

#-------------------------------------------------------------------------------
# 7. Cleanup All Test Fixtures
#-------------------------------------------------------------------------------
cleanup_test_domain ($rt_domain);
cleanup_test_domain ($wl_domain);
cleanup_test_domain ($batch_domain);
ResequenceList (userid => $test_user, type => 'black');
ResequenceList (userid => $test_user, type => 'white');

done_testing ();

sub cleanup_test_domain {
  my ($dom) = @_;
  $MAPS::db->delete ('list', "userid='$test_user' and domain='$dom'");
  $MAPS::db->delete ('log',  "userid='$test_user' and (sender like '%$dom%' or message like '%$dom%')");
  system ("sudo bash -c 'sed -i \"/$dom/d\" /etc/postfix/sender_access && postmap /etc/postfix/sender_access'");
}
