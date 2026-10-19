# MAPS Phishing Incident Automation & Postfix MTA Domain Blocking Specification

## 1. Executive Summary & Objective
The Mail Abuse Prevention System (MAPS) running on `defaria.com` currently allows manual reporting of incoming phishing messages through a web interface. The objective of this project is to enhance the **"Report Phishing"** workflow in MAPS so that upon execution, it:
1. **Parses the raw email payload** to accurately identify the true originating/spoofed envelope domain (not just the cosmetic display name).
2. **Dispatches comprehensive abuse reports** (with the intact RFC 822 `.eml` payload) to upstream ISP abuse desks, targeted brand security teams, and anti-phishing clearinghouses (APWG, IRS).
3. **Automates Postfix MTA-level blocking** by appending the offending domain to `/etc/postfix/sender_access` and rebuilding the hash database via `postmap`, without exposing unsecured `sudo` access to the web server process (`www-data`).
4. **Applies guardrails** to prevent accidental domain-wide MTA bans against shared ESPs, cloud relays, or major freemail providers (e.g., Google, SendGrid, Amazon SES, Outlook).

---

## 2. Technical Context & Baseline Architecture

### Server Environment
* **Host:** `defaria.com` (`DeFaria`)
* **MTA:** Postfix (with `hash:/etc/postfix/sender_access` evaluated in `smtpd_sender_restrictions`)
* **Intrusion Prevention:** Fail2ban running an `nftables` banaction (drops active offending IPs at the kernel level)
* **Application Stack:** MAPS (Perl / PHP / MariaDB on Nginx/Apache)
* **Database:** MariaDB storing MAPS tables (whitelists, blacklists, message spools, logs)

### Relevant Configuration Snippets Verified
* **`/etc/postfix/main.cf`**:
  ```text
  smtpd_sender_restrictions = permit_mynetworks, reject_non_fqdn_sender, check_sender_access hash:/etc/postfix/sender_access, permit
  parent_domain_matches_subdomains = debug_peer_list,fast_flush_domains,mynetworks,permit_mx_backup_networks,qmqpd_authorized_clients,relay_domains,smtpd_access_maps
  ```
* **`/etc/postfix/sender_access` format**:
  ```text
  sxjdms.com          REJECT Phishing / Spoofed domain
  .sxjdms.com         REJECT Phishing / Spoofed domain
  ```

---

## 3. Threat Model & Case Study (Tastytrade / W-9 Phish)
* **Attack Vector:** Spear-phishing lure claiming Form W-9 expiration and immediate account suspension.
* **Display From:** `Tastytrade Support <Noreply@mail.sxjdms.com>`
* **True Envelope Sender (`Return-Path`):** `Noreply@mail.sxjdms.com`
* **DKIM Signature:** `d=sxjdms.com`, selector `gammadyne` (Gammadyne Mailer bulk tool)
* **Connecting Host:** `185.230.124.201` (`mail.sxjdms.com`, PTR unresolvable)
* **Upstream Network:** M247 Europe SRL (`AS35592`, `abuse@m247.ro`, `ro-legal@m247.ro`)

---

## 4. Architecture & Security Considerations

### Challenge 1: Privilege Separation (`www-data` vs. `root`)
* **Risk:** The web application running under `www-data` cannot directly run `postmap /etc/postfix/sender_access` without root privileges. Giving `www-data` blanket `sudo` access is dangerous.
* **Resolution (Queue Pattern - Recommended):** 
  * The MAPS UI backend writes validated domain candidates into a MariaDB table: `postfix_sender_blocks`.
  * A lightweight root worker script (executed via systemd timer or root cron every 60s, or via a local Unix socket listener) fetches unapplied records, updates `/etc/postfix/sender_access`, executes `postmap`, and updates row status to `applied = 1`.
* **Resolution (Direct Sudo Pattern - Alternative):**
  * Create `/etc/sudoers.d/maps-postfix` permitting `www-data ALL=(root) NOPASSWD: /usr/local/sbin/block-domain *`.
  * The script `/usr/local/sbin/block-domain` strictly enforces regex input validation before any filesystem operations.

### Challenge 2: Accidental Collateral Damage (Guardrail Whitelist)
If an attacker sends a lure via Gmail, SendGrid, or Mailchimp, blocking the parent domain in `sender_access` will reject all legitimate email from that provider across the entire system.
* **Resolution:** An explicit `PROTECTED_DOMAINS` set must intercept domain extraction. If a domain matches the protected set, MTA-level rejection is aborted, and MAPS instead applies an envelope-exact or sender-address blacklist rule.

---

## 5. Database Schema Design

```sql
CREATE TABLE IF NOT EXISTS postfix_sender_blocks (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    domain VARCHAR(255) NOT NULL,
    subdomain_wildcard TINYINT(1) NOT NULL DEFAULT 1,
    action_directive VARCHAR(64) NOT NULL DEFAULT 'REJECT Phishing / Spoofed domain',
    reason VARCHAR(255) NOT NULL,
    source_message_id VARCHAR(255) NULL,
    originating_ip VARCHAR(45) NULL,
    reported_by VARCHAR(64) NOT NULL DEFAULT 'maps-web',
    applied TINYINT(1) NOT NULL DEFAULT 0,
    applied_at DATETIME NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_domain (domain),
    INDEX idx_applied (applied)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 6. Parsing & Domain Extraction Logic

### Extraction Hierarchy
1. **Primary: `Return-Path:`** Parse envelope sender address from headers.
2. **Secondary: `Authentication-Results:` / `DKIM-Signature:`** Extract `header.d=` or `d=`.
3. **Tertiary: `From:`** Extract domain from standard `From:` address if envelope is unavailable or bounced.
4. **Hostname extraction:** If `Received: from <host> (<ip>)` provides a hostname, extract the second-level domain (SLD) if verifiable.

### Protected / Never-Block Infrastructure Set
```perl
my @PROTECTED_DOMAINS = qw(
    gmail.com google.com yahoo.com ymail.com outlook.com hotmail.com live.com
    msn.com icloud.com me.com aol.com comcast.net sbcglobal.net att.net
    verizon.net mailgun.org sendgrid.net amazonses.com mailchimp.com
    constantcontact.com postmarkapp.com sparkpostmail.com defaria.com
);
my %IS_PROTECTED = map { lc($_) => 1 } @PROTECTED_DOMAINS;
```

---

## 7. Component Implementation Blueprint

### A. Root Worker Daemon / Script (`/usr/local/sbin/maps-postfix-worker.pl`)
```perl
#!/usr/bin/env perl
use strict;
use warnings;
use DBI;

my $DB_NAME = 'maps';
my $DB_USER = 'maps_user';
my $DB_PASS = 'MAPS_SECRET_PASSWORD';
my $ACCESS_FILE = '/etc/postfix/sender_access';

my $dbh = DBI->connect("DBI:mysql:database=$DB_NAME;host=localhost", $DB_USER, $DB_PASS, {
    RaiseError => 1,
    AutoCommit => 1,
});

my $sth = $dbh->prepare("SELECT id, domain, subdomain_wildcard, action_directive FROM postfix_sender_blocks WHERE applied = 0 FOR UPDATE");
$sth->execute();

my @rows = @{$sth->fetchall_arrayref({})};
exit 0 unless @rows;

open my $fh, '>>', $ACCESS_FILE or die "Cannot open $ACCESS_FILE: $!";

my @updated_ids;
for my $row (@rows) {
    my $dom = lc($row->{domain});
    $dom =~ s/^\.//;
    my $directive = $row->{action_directive};

    # Append base domain and dot-prefixed wildcard
    print $fh "$dom\t\t$directive\n";
    if ($row->{subdomain_wildcard}) {
        print $fh ".$dom\t\t$directive\n";
    }
    push @updated_ids, $row->{id};
}
close $fh;

# Recompile hash map
system('/usr/sbin/postmap', $ACCESS_FILE) == 0
    or die "postmap failed: $?";

# Mark rows as applied
if (@updated_ids) {
    my $id_list = join(',', map { int($_) } @updated_ids);
    $dbh->do("UPDATE postfix_sender_blocks SET applied = 1, applied_at = NOW() WHERE id IN ($id_list)");
}

$dbh->disconnect();
exit 0;
```

### B. Systemd Timer Unit (Runs Every Minute)
* **`/etc/systemd/system/maps-postfix-worker.service`**:
  ```ini
  [Unit]
  Description=MAPS Postfix Sender Access Worker
  After=network.target mysql.service

  [Service]
  Type=oneshot
  ExecStart=/usr/local/sbin/maps-postfix-worker.pl
  User=root
  ```

* **`/etc/systemd/system/maps-postfix-worker.timer`**:
  ```ini
  [Unit]
  Description=Run MAPS Postfix Sender Access Worker every minute

  [Timer]
  OnBootSec=1min
  OnUnitActiveSec=1min
  Unit=maps-postfix-worker.service

  [Install]
  WantedBy=timers.target
  ```

---

## 8. Abuse Reporting Generation Format

When **Report Phishing** is clicked, MAPS generates and dispatches an RFC 822 compliant multipart email:
* **Headers:**
  * `To:` Target ISP abuse desks (`abuse@<host-org>`, e.g., `abuse@m247.ro`)
  * `CC:` `reportphishing@apwg.org`, `phishing@irs.gov`, and brand abuse inbox (e.g., `support@tastytrade.com`)
  * `Subject:` `Phishing Incident Report: Brand Impersonation ([Brand]) from [IP] ([Envelope Domain])`
* **MIME Body:**
  * Part 1 (`text/plain`): Human-readable incident summary, timestamps, source IPs, envelope domain, and analysis.
  * Part 2 (`message/rfc822`): Raw, unmodified `.eml` payload preserving all DKIM headers, boundary markers, and quoted-printable data.

---

## 9. Verification & Testing Checklist

1. **Unit Test Extraction:** Run test emails through the parser verifying `Return-Path` and `DKIM-Signature` precedence.
2. **Protected Domain Test:** Feed an email originating from `*@gmail.com` into the parser; confirm it aborts MTA block and records an audit log.
3. **Queue Ingestion Test:** Trigger report via UI; verify insertion into `postfix_sender_blocks` with `applied = 0`.
4. **Worker Execution:** Trigger `maps-postfix-worker.service`; verify:
   * `/etc/postfix/sender_access` contains new entries.
   * `postmap -q "testdomain.com" hash:/etc/postfix/sender_access` returns `REJECT ...`.
   * Row state updates to `applied = 1`.
5. **Live Rejection Test:** Use `nc` or `swaks` to simulate external delivery from the domain; verify Postfix logs `554 5.7.1 Sender address rejected`.