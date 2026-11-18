#!/usr/bin/perl
################################################################################
#
# File:         audit_recruiter_domains.pl
# Description:  MAPS Recruiter Domain Strike Escalation & Blacklist Consolidation
#               Scans MAPS blacklist for recruiter entries, groups by domain,
#               outputs a consolidation audit report (default --dry-run), and
#               consolidates approved multi-strike domains in --execute mode.
# Author:       Andrew@DeFaria.com
# Language:     Perl
#
################################################################################
use strict;
use warnings;

use FindBin;
use Getopt::Long;
use DBI;
use POSIX qw(strftime);

use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../lib";

use MAPS qw(
  %FREE_DOMAINS
  @FREE_DOMAINS
  DeleteEmail
  IsFreeDomain
  OnWhitelist
  ResequenceList
  SetContext
  TriggerPostfixDomainBlock
  UserExists
);
use MAPSLog;
use DateUtils;

my $dry_run     = 1;
my $execute     = 0;
my $threshold   = 2;
my @cli_domains = ();
my $output_file = '';
my $userid      = $ENV{MAPS_USERNAME} || $ENV{USER} || 'andrew';
my $do_postfix  = 1;
my $help        = 0;

GetOptions (
  'dry-run|dryrun|n!' => \$dry_run,
  'execute|e'         => \$execute,
  'threshold|t=i'     => \$threshold,
  'domains|domain=s@' => \@cli_domains,
  'output|o=s'        => \$output_file,
  'userid|user|u=s'   => \$userid,
  'postfix!'          => \$do_postfix,
  'help|h|?'          => \$help,
) or usage (2);

usage (0) if $help;

if ($execute) {
  $dry_run = 0;
}

if ($threshold < 1) {
  die "Error: --threshold must be >= 1 (got $threshold)\n";
}

if (!UserExists ($userid) && UserExists ('andrew')) {
  $userid = 'andrew';
}
SetContext ($userid);

# Parse optional --domains=foo.com,bar.com filter
my %approved_domains_filter;
my $has_domain_filter = 0;
for my $item (@cli_domains) {
  for my $d (split (/\s*,\s*/, $item)) {
    $d = lc ($d);
    $d =~ s/^[\.\@\s]+|\s+$//g;
    if ($d ne '') {
      $approved_domains_filter{$d} = 1;
      $has_domain_filter = 1;
    }
  }
}

my $dbh = $MAPS::db->{db};
die "Error: Database handle unavailable\n" unless $dbh;

#-------------------------------------------------------------------------------
# 1. Read-Only Sweep: Fetch Blacklist & Whitelist Data
#-------------------------------------------------------------------------------

# Fetch all existing whole-domain blocks on the blacklist (regardless of comment)
my %existing_whole_domain_blocks;
{
  my $sth = $dbh->prepare (
    "SELECT sequence, domain, comment, hit_count, last_hit, retention "
    . "FROM list WHERE userid = ? AND type = 'black' AND (pattern IS NULL OR pattern = '')"
  );
  $sth->execute ($userid);
  while (my $row = $sth->fetchrow_hashref) {
    my $dom = lc ($row->{domain} // '');
    $dom =~ s/^[\.\@\s]+|\s+$//g;
    next unless $dom ne '';
    $existing_whole_domain_blocks{$dom} = $row;
  }
  $sth->finish;
}

# Fetch all whitelist entries for conflict detection
my %whitelist_by_domain;
{
  my $sth = $dbh->prepare (
    "SELECT sequence, pattern, domain, comment, hit_count, last_hit "
    . "FROM list WHERE userid = ? AND type = 'white' ORDER BY sequence"
  );
  $sth->execute ($userid);
  while (my $row = $sth->fetchrow_hashref) {
    my $dom = lc ($row->{domain} // '');
    $dom =~ s/^[\.\@\s]+|\s+$//g;
    next unless $dom ne '';
    push @{ $whitelist_by_domain{$dom} }, $row;
  }
  $sth->finish;
}

# Query all blacklist entries where comment matches 'recruiter' (case-insensitive)
my $rec_sth = $dbh->prepare (
  "SELECT sequence, pattern, domain, comment, hit_count, last_hit, retention "
  . "FROM list WHERE userid = ? AND type = 'black' AND LOWER(comment) LIKE '%recruiter%' "
  . "ORDER BY sequence"
);
$rec_sth->execute ($userid);

my $total_recruiter_rows        = 0;
my $total_recruiter_indiv_rows  = 0;
my $total_recruiter_domain_rows = 0;

my %domain_groups;

while (my $row = $rec_sth->fetchrow_hashref) {
  $total_recruiter_rows++;

  my $raw_pat = $row->{pattern} // '';
  my $raw_dom = $row->{domain}  // '';

  my ($pat, $dom) = normalize_entry ($raw_pat, $raw_dom);
  next unless $dom ne '';

  $domain_groups{$dom} ||= {
    domain               => $dom,
    indiv_rows           => [],
    distinct_patterns    => {},
    recruiter_domain_row => undef,
    existing_domain_row  => $existing_whole_domain_blocks{$dom},
  };

  if ($pat eq '') {
    $total_recruiter_domain_rows++;
    $domain_groups{$dom}->{recruiter_domain_row} = $row;
    $domain_groups{$dom}->{existing_domain_row} ||= $row;
  } else {
    $total_recruiter_indiv_rows++;
    push @{ $domain_groups{$dom}->{indiv_rows} }, {
      %$row,
      norm_pattern => $pat,
      norm_domain  => $dom,
      address      => "$pat\@$dom",
    };
    $domain_groups{$dom}->{distinct_patterns}->{$pat} = 1;
  }
}
$rec_sth->finish;

#-------------------------------------------------------------------------------
# 2. Classify Domains: Eligible Candidates, Public Providers, Whitelist Conflicts
#-------------------------------------------------------------------------------
my @candidates;
my @skipped_public;
my @whitelist_conflicts_threshold;
my @whitelist_conflicts_below;
my @ rejected_filter_domains;

for my $dom (sort keys %domain_groups) {
  my $grp          = $domain_groups{$dom};
  my $strike_count = scalar (keys %{ $grp->{distinct_patterns} });
  $grp->{strike_count} = $strike_count;

  # Check Public / Shared Provider Exclusion List
  my ($is_free, $free_match) = IsFreeDomain ($dom);
  if ($is_free) {
    $grp->{free_match} = $free_match;
    push @skipped_public, $grp;
    if ($has_domain_filter && $approved_domains_filter{$dom}) {
      push @rejected_filter_domains, "$dom (excluded public/shared email provider: $free_match)";
    }
    next;
  }

  # Check Whitelist Precedence
  my @w_conflicts;
  if ($whitelist_by_domain{$dom}) {
    for my $w (@{ $whitelist_by_domain{$dom} }) {
      my $w_addr = ($w->{pattern} // '') . '@' . ($w->{domain} // $dom);
      $w_addr .= " [$w->{comment}]" if defined $w->{comment} && $w->{comment} ne '';
      push @w_conflicts, $w_addr;
    }
  } else {
    my ($w_status, $w_rec) = OnWhitelist ("\@$dom", $userid, 0);
    if ($w_status && $w_rec) {
      my $w_addr = ($w_rec->{pattern} // '') . '@' . ($w_rec->{domain} // '');
      $w_addr .= " [$w_rec->{comment}]" if defined $w_rec->{comment} && $w_rec->{comment} ne '';
      push @w_conflicts, $w_addr;
    }
  }

  if (@w_conflicts) {
    $grp->{whitelist_conflicts} = \@w_conflicts;
    if ($strike_count >= $threshold) {
      push @whitelist_conflicts_threshold, $grp;
    } else {
      push @whitelist_conflicts_below, $grp;
    }
    if ($has_domain_filter && $approved_domains_filter{$dom}) {
      push @rejected_filter_domains, "$dom (active whitelist conflict: " . join (', ', @w_conflicts) . ")";
    }
    next;
  }

  # Filter by strike threshold (>= N distinct blacklisted addresses)
  if ($strike_count >= $threshold) {
    if ($has_domain_filter && !$approved_domains_filter{$dom}) {
      next;
    }

    my $total_hits = 0;
    my $latest_hit = '';
    for my $r (@{ $grp->{indiv_rows} }) {
      $total_hits += ($r->{hit_count} || 0);
      if (($r->{last_hit} // '') gt $latest_hit) {
        $latest_hit = $r->{last_hit};
      }
    }
    if ($grp->{existing_domain_row}) {
      $total_hits += ($grp->{existing_domain_row}->{hit_count} || 0);
      if (($grp->{existing_domain_row}->{last_hit} // '') gt $latest_hit) {
        $latest_hit = $grp->{existing_domain_row}->{last_hit};
      }
    }

    $grp->{total_hits}       = $total_hits;
    $grp->{latest_hit}       = $latest_hit;
    $grp->{proposed_rule}    = "\@$dom";
    $grp->{proposed_comment} = "recruiter - consolidated domain block ($strike_count strikes)";

    push @candidates, $grp;
  } elsif ($has_domain_filter && $approved_domains_filter{$dom}) {
    push @rejected_filter_domains, "$dom (only $strike_count strike(s), below threshold of $threshold)";
  }
}

# Check for any domains in --domains that were not found in recruiter scan at all
if ($has_domain_filter) {
  for my $req_dom (sort keys %approved_domains_filter) {
    if (!$domain_groups{$req_dom}) {
      my ($is_free, $free_match) = IsFreeDomain ($req_dom);
      if ($is_free) {
        push @rejected_filter_domains, "$req_dom (excluded public/shared email provider: $free_match)";
      } else {
        push @rejected_filter_domains, "$req_dom (no recruiter entries found in blacklist)";
      }
    }
  }
}

# Sort candidates by strike_count descending, then domain ascending
@candidates = sort {
  $b->{strike_count} <=> $a->{strike_count}
    || $a->{domain} cmp $b->{domain}
} @candidates;

@whitelist_conflicts_threshold = sort {
  $b->{strike_count} <=> $a->{strike_count}
    || $a->{domain} cmp $b->{domain}
} @whitelist_conflicts_threshold;

# Calculate summary metrics
my $total_candidate_domains = scalar (@candidates);
my $total_rows_replaced     = 0;
my $new_domain_rows_added   = 0;
for my $c (@candidates) {
  $total_rows_replaced += scalar (@{ $c->{indiv_rows} });
  $new_domain_rows_added++ unless $c->{existing_domain_row};
}
my $net_row_reduction = $total_rows_replaced - $new_domain_rows_added;

#-------------------------------------------------------------------------------
# 3. Generate Structured Audit Report
#-------------------------------------------------------------------------------
my @report_lines;
my $now_str  = strftime ('%Y-%m-%d %H:%M:%S %Z', localtime);
my $mode_str = $dry_run ? 'DRY-RUN (Read-Only Audit — No DB or Postfix Changes)' : 'EXECUTE (Live DB Consolidation & Postfix Update)';

push @report_lines, '=' x 80;
push @report_lines, 'MAPS RECRUITER DOMAIN STRIKE ESCALATION & BLACKLIST CONSOLIDATION REPORT';
push @report_lines, '=' x 80;
push @report_lines, sprintf ("%-28s : %s", 'Generated At', $now_str);
push @report_lines, sprintf ("%-28s : %s", 'Execution Mode', $mode_str);
push @report_lines, sprintf ("%-28s : %s", 'MAPS User Context', $userid);
push @report_lines, sprintf ("%-28s : >= %d distinct recruiter addresses / domain", 'Strike Threshold', $threshold);
if ($has_domain_filter) {
  push @report_lines, sprintf ("%-28s : %s", 'Domain Filter (--domains)', join (', ', sort keys %approved_domains_filter));
}
push @report_lines, '';

push @report_lines, '-' x 80;
push @report_lines, '1. SUMMARY METRICS';
push @report_lines, '-' x 80;
push @report_lines, sprintf ("  %-48s : %d", 'Total Recruiter Blacklist Entries Scanned', $total_recruiter_rows);
push @report_lines, sprintf ("    %-46s : %d", '- Individual Recruiter Address Entries', $total_recruiter_indiv_rows);
push @report_lines, sprintf ("    %-46s : %d", '- Existing Whole-Domain Recruiter Blocks', $total_recruiter_domain_rows);
push @report_lines, sprintf ("  %-48s : %d", 'Total Distinct Recruiter Domains Scanned', scalar (keys %domain_groups));
push @report_lines, sprintf ("  %-48s : %d", 'Candidate Domains Eligible for Consolidation', $total_candidate_domains);
push @report_lines, sprintf ("  %-48s : %d", 'Total Individual Address Rows to be Replaced', $total_rows_replaced);
push @report_lines, sprintf ("  %-48s : %d", 'New Whole-Domain Block Rows to be Inserted', $new_domain_rows_added);
push @report_lines, sprintf ("  %-48s : %d rows", 'Net Blacklist Table Row Reduction', $net_row_reduction);
push @report_lines, sprintf ("  %-48s : %d", 'Skipped Public/Shared Email Provider Domains', scalar (@skipped_public));
push @report_lines, sprintf ("  %-48s : %d (>= threshold), %d (< threshold)",
  'Flagged Whitelist Conflict Domains',
  scalar (@whitelist_conflicts_threshold),
  scalar (@whitelist_conflicts_below)
);
push @report_lines, '';

push @report_lines, '-' x 80;
push @report_lines, '2. CONSOLIDATION CANDIDATES OVERVIEW (Sorted by Strike Count Descending)';
push @report_lines, '-' x 80;

if (!@candidates) {
  push @report_lines, '  No eligible candidate domains met the consolidation criteria.';
} else {
  push @report_lines, sprintf (
    "  %-4s %-26s %-8s %-14s %-6s %-30s",
    'Rank', 'Domain', 'Strikes', 'Domain Block?', 'Hits', 'Proposed Consolidated Rule'
  );
  push @report_lines, '  ' . ('-' x 76);

  my $rank = 1;
  for my $c (@candidates) {
    my $exists_str = $c->{existing_domain_row} ? 'Yes' : 'No';
    push @report_lines, sprintf (
      "  %-4d %-26s %-8d %-14s %-6d %-30s",
      $rank++,
      $c->{domain},
      $c->{strike_count},
      $exists_str,
      $c->{total_hits},
      $c->{proposed_rule}
    );
  }
}
push @report_lines, '';

push @report_lines, '-' x 80;
push @report_lines, '3. DETAILED CONSOLIDATION CANDIDATE BREAKDOWN';
push @report_lines, '-' x 80;

if (!@candidates) {
  push @report_lines, '  None.';
} else {
  my $idx = 1;
  for my $c (@candidates) {
    my $exists_str = $c->{existing_domain_row}
      ? "Yes (seq #$c->{existing_domain_row}->{sequence}, comment: \"$c->{existing_domain_row}->{comment}\")"
      : 'No';
    push @report_lines, sprintf ("  [%d] Domain: %s (%d strikes)", $idx++, $c->{domain}, $c->{strike_count});
    push @report_lines, sprintf ("      Whole-Domain Entry Exists : %s", $exists_str);
    push @report_lines, sprintf ("      Proposed Domain Rule      : %s (pattern=NULL, domain='%s')", $c->{proposed_rule}, $c->{domain});
    push @report_lines, sprintf ("      Proposed Comment          : \"%s\"", $c->{proposed_comment});
    push @report_lines, sprintf ("      Individual Blacklisted Addresses (%d):", scalar (@{ $c->{indiv_rows} }));
    for my $r (@{ $c->{indiv_rows} }) {
      my $ts   = $r->{last_hit} // 'N/A';
      my $hits = defined $r->{hit_count} ? $r->{hit_count} : 0;
      my $comm = $r->{comment} // '';
      push @report_lines, sprintf (
        "        - %-36s | seq: %-4d | hits: %-3d | last_hit: %-19s | comment: \"%s\"",
        $r->{address}, $r->{sequence} // 0, $hits, $ts, $comm
      );
    }
    push @report_lines, '';
  }
}

push @report_lines, '-' x 80;
push @report_lines, '4. SKIPPED / FLAGGED EXCEPTIONS';
push @report_lines, '-' x 80;

push @report_lines, '  A. Skipped Public / Shared Email Providers:';
if (!@skipped_public) {
  push @report_lines, '     None found in recruiter blacklist entries.';
  push @report_lines, '     Active Exclusion Guardrail List (' . scalar (@FREE_DOMAINS) . ' providers):';
  push @report_lines, '       ' . join (', ', sort @FREE_DOMAINS);
} else {
  for my $p (@skipped_public) {
    push @report_lines, sprintf (
      "     - %-26s (%d strike(s)) — Protected public provider (%s)",
      $p->{domain}, $p->{strike_count}, $p->{free_match}
    );
    for my $r (@{ $p->{indiv_rows} }) {
      push @report_lines, sprintf (
        "         * %-34s | last_hit: %-19s | comment: \"%s\"",
        $r->{address}, $r->{last_hit} // 'N/A', $r->{comment} // ''
      );
    }
  }
}
push @report_lines, '';

push @report_lines, '  B. Flagged Whitelist Conflicts (Excluded due to Whitelist Precedence):';
if (!@whitelist_conflicts_threshold && !@whitelist_conflicts_below) {
  push @report_lines, '     None.';
} else {
  if (@whitelist_conflicts_threshold) {
    push @report_lines, sprintf ("     Multi-Strike Domains Blocked from Consolidation by Active Whitelist Rules (%d):", scalar (@whitelist_conflicts_threshold));
    for my $w (@whitelist_conflicts_threshold) {
      push @report_lines, sprintf (
        "     - %-26s (%d recruiter strikes on blacklist) — SKIPPED (CONFLICT)",
        $w->{domain}, $w->{strike_count}
      );
      push @report_lines, '         Conflicting Whitelist Entry(s): ' . join (', ', @{ $w->{whitelist_conflicts} });
      for my $r (@{ $w->{indiv_rows} }) {
        push @report_lines, sprintf (
          "         Blacklisted Recruiter: %-30s | seq: %-4d | last_hit: %-19s | comment: \"%s\"",
          $r->{address}, $r->{sequence} // 0, $r->{last_hit} // 'N/A', $r->{comment} // ''
        );
      }
    }
  } else {
    push @report_lines, '     Multi-Strike Domains (>= threshold) with Whitelist Conflicts: None.';
  }

  if (@whitelist_conflicts_below) {
    push @report_lines, '';
    push @report_lines, sprintf ("     Informational: Single/Sub-Threshold Domains with Whitelist Entries (%d):", scalar (@whitelist_conflicts_below));
    for my $w (@whitelist_conflicts_below) {
      push @report_lines, sprintf (
        "     - %-26s (%d individual blacklist strike(s)) — Whitelisted: %s",
        $w->{domain}, $w->{strike_count}, join (', ', @{ $w->{whitelist_conflicts} })
      );
    }
  }
}

if (@rejected_filter_domains) {
  push @report_lines, '';
  push @report_lines, '  C. Requested --domains Excluded by Guardrails:';
  for my $rej (@rejected_filter_domains) {
    push @report_lines, "     - $rej";
  }
}
push @report_lines, '';

#-------------------------------------------------------------------------------
# 4. Phase 2 Execution Mode (--execute)
#-------------------------------------------------------------------------------
if (!$dry_run) {
  push @report_lines, '-' x 80;
  push @report_lines, '5. EXECUTION LOG (--execute)';
  push @report_lines, '-' x 80;

  if (!@candidates) {
    push @report_lines, '  No eligible candidate domains to consolidate.';
  } else {
    my $orig_autocommit = $dbh->{AutoCommit};
    my @consolidated_log;

    eval {
      $dbh->{AutoCommit} = 0 if $orig_autocommit;

      my $seq_sth = $dbh->prepare (
        "SELECT COALESCE(MAX(sequence), 0) FROM list WHERE userid = ? AND type = 'black'"
      );
      $seq_sth->execute ($userid);
      my ($max_seq) = $seq_sth->fetchrow_array;
      $seq_sth->finish;
      $max_seq ||= 0;

      my $ins_sth = $dbh->prepare (
        "INSERT INTO list (userid, type, pattern, domain, comment, sequence, hit_count, last_hit, retention) "
        . "VALUES (?, 'black', NULL, ?, ?, ?, ?, ?, NULL)"
      );
      my $upd_sth = $dbh->prepare (
        "UPDATE list SET comment = ?, hit_count = ?, last_hit = ? "
        . "WHERE userid = ? AND type = 'black' AND sequence = ?"
      );
      my $del_sth = $dbh->prepare (
        "DELETE FROM list WHERE userid = ? AND type = 'black' AND LOWER(domain) = ? "
        . "AND pattern IS NOT NULL AND pattern != ''"
      );

      for my $c (@candidates) {
        my $dom     = $c->{domain};
        my $comm    = $c->{proposed_comment};
        my $hits    = $c->{total_hits} || 0;
        my $last_ts = $c->{latest_hit} || DateUtils::UnixDatetime2SQLDatetime (scalar (localtime));

        my @removed_addrs = map { $_->{address} } @{ $c->{indiv_rows} };

        if ($c->{existing_domain_row}) {
          $upd_sth->execute (
            $comm,
            $hits,
            $last_ts,
            $userid,
            $c->{existing_domain_row}->{sequence}
          );
        } else {
          $max_seq++;
          $ins_sth->execute (
            $userid,
            $dom,
            $comm,
            $max_seq,
            $hits,
            $last_ts
          );
        }

        my $deleted_rows = $del_sth->execute ($userid, $dom);

        push @consolidated_log, {
          domain          => $dom,
          strikes         => $c->{strike_count},
          comment         => $comm,
          deleted_count   => $deleted_rows + 0,
          removed_addrs   => \@removed_addrs,
          had_domain_rule => $c->{existing_domain_row} ? 1 : 0,
        };
      }

      $ins_sth->finish;
      $upd_sth->finish;
      $del_sth->finish;

      $dbh->commit () if $orig_autocommit;
    };
    my $tx_err = $@;
    if ($orig_autocommit) {
      eval { $dbh->rollback () } if $tx_err;
      $dbh->{AutoCommit} = 1;
    }

    if ($tx_err) {
      push @report_lines, "  [ERROR] Transaction rolled back due to database error: $tx_err";
      output_report (\@report_lines, $output_file);
      die "Database consolidation failed and was rolled back: $tx_err\n";
    }

    # Resequence blacklist after committing transaction
    ResequenceList (
      userid => $userid,
      type   => 'black',
    );

    # Trigger Postfix sender_access updates and log each domain to MAPS audit log
    for my $entry (@consolidated_log) {
      my $dom = $entry->{domain};

      DeleteEmail (
        userid => $userid,
        sender => "\@$dom",
      );

      my ($mta_rc, $mta_msg) = (0, 'Postfix update skipped (--no-postfix)');
      if ($do_postfix) {
        ($mta_rc, $mta_msg) = TriggerPostfixDomainBlock ($dom, 'REJECT Blacklisted recruiter domain');
      }

      my $addr_list_str = join (', ', @{ $entry->{removed_addrs} });
      Info (
        userid  => $userid,
        message => "Consolidated recruiter domain \@$dom ($entry->{strikes} strikes; removed: $addr_list_str)",
      );

      push @report_lines, sprintf (
        "  [CONSOLIDATED] \@%-25s | %d strikes | removed %d row(s): %s",
        $dom, $entry->{strikes}, $entry->{deleted_count}, $addr_list_str
      );
      push @report_lines, sprintf (
        "                 Postfix MTA: %s", $mta_msg
      );
    }
  }
  push @report_lines, '';
} else {
  push @report_lines, '=' x 80;
  push @report_lines, 'DRY-RUN COMPLETE: Zero database or Postfix changes were executed.';
  push @report_lines, 'To execute consolidation for approved domains, re-run with:';
  push @report_lines, '  bin/audit_recruiter_domains.pl --execute [--domains=domain1.com,domain2.com]';
  push @report_lines, '=' x 80;
}

output_report (\@report_lines, $output_file);
exit 0;

#-------------------------------------------------------------------------------
# Helper Subroutines
#-------------------------------------------------------------------------------
sub normalize_entry {
  my ($raw_pat, $raw_dom) = @_;
  $raw_pat //= '';
  $raw_dom //= '';
  $raw_pat =~ s/^\s+|\s+$//g;
  $raw_dom =~ s/^\s+|\s+$//g;

  my ($pat, $dom) = ('', '');

  if ($raw_dom =~ /^([^\@]*)\@([^\@]+)$/) {
    $pat = $raw_pat ne '' ? $raw_pat : $1;
    $dom = $2;
  } elsif ($raw_pat =~ /^([^\@]*)\@([^\@]+)$/) {
    $pat = $1;
    $dom = $raw_dom ne '' ? $raw_dom : $2;
  } else {
    $pat = $raw_pat;
    $dom = $raw_dom;
  }

  $pat = lc ($pat);
  $dom = lc ($dom);
  $dom =~ s/^[\.\@]+//;
  $dom =~ s/\s+//g;

  return ($pat, $dom);
}

sub output_report {
  my ($lines_ref, $out_path) = @_;
  my $text = join ("\n", @$lines_ref) . "\n";

  print $text;

  if (defined $out_path && $out_path ne '') {
    open my $fh, '>', $out_path
      or die "Error: Unable to write report to '$out_path': $!\n";
    print $fh $text;
    close $fh;
  }
  return;
}

sub usage {
  my ($exit_code) = @_;
  print <<"END_USAGE";
Usage: audit_recruiter_domains.pl [options]

Options:
  --dry-run, -n             Run read-only audit report without modifying DB or Postfix (Default)
  --execute, -e             Consolidate approved multi-strike recruiter domains and update Postfix
  --threshold=N, -t N       Minimum distinct blacklisted recruiter addresses per domain (Default: 2)
  --domains=d1.com,d2.com   Limit consolidation scope to specific comma-separated domain(s)
  --output=FILE, -o FILE    Also write the structured report to FILE
  --userid=USER, -u USER    MAPS userid to audit (Default: andrew)
  --no-postfix              Skip Postfix sender_access update during --execute
  --help, -h                Show this help message
END_USAGE
  exit ($exit_code // 0);
}
