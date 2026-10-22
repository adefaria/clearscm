# Reachout Program — Implementation Plan (ClearSCM Architecture)

## 1. Executive Summary & Architectural Decisions

The **Reachout Program** is an enterprise-grade, policy-driven communication engine that replaces and supersedes the legacy reminder script [`/opt/clearscm/bin/nag.pl`](file:///opt/clearscm/bin/nag.pl). 

### Key Architectural Relocation
* **Centralized Home in ClearSCM**: Rather than residing exclusively inside the [`/opt/rockready`](file:///opt/rockready) web root, the Reachout Program will be housed in **`/opt/clearscm/reachout/`**, with its primary executable exposed via **[`/opt/clearscm/bin/reachout`](file:///opt/clearscm/bin)**.
* **Retirement of `nag.pl`**: The legacy `nag.pl` script will be retired. `reachout` will provide a complete, feature-rich replacement capable of handling both legacy internal reminders and sophisticated external outreach campaigns.
* **Decoupled Rock Ready Integration**: While the core engine and general templates live in `/opt/clearscm`, the system includes a dedicated **Rock Ready adapter** that reads styling cues, high-resolution logos, performance photos, and dynamic live calendar data directly from [`/opt/rockready`](file:///opt/rockready) and the `rockready.band` WordPress REST API.
* **Multi-Domain Outreach**: Built out-of-the-box to handle:
  1. **Rock Ready Club Booking**: Contacting venue owners and booking managers for open gig dates.
  2. **Personal Career / Job Inquiries**: Professional consulting and employment inquiries for Andrew (`Andrew@DeFaria.com`).
  3. **Technical Vendor & Support Follow-ups**: Persistent, structured tracking for support tickets and vendor engagements.
* **Seamless MAPS Integration**: Because MAPS already lives in [`/opt/clearscm/maps`](file:///opt/clearscm/maps), locating `reachout` in `/opt/clearscm` enables tight, zero-latency integration: incoming replies automatically whitelist the contact and pause further reachout until Andrew reviews the email.

---

## 2. Directory Structure in `/opt/clearscm`

```
/opt/clearscm/
├── bin/
│   ├── reachout                   # Main CLI binary (symlink to ../reachout/bin/reachout)
│   └── nag.pl                     # Deprecation shim -> redirects to reachout --policy aggressive
├── lib/                           # Shared ClearSCM modules (Mail.pm, DateUtils.pm, Display.pm)
├── maps/                          # Mail Authorization & Permission System
│   └── bin/maps                   # Inbound mail filter (with Reachout reply intercept hook)
└── reachout/                      # Reachout subsystem root
    ├── bin/
    │   └── reachout               # Core executable
    ├── etc/
    │   ├── reachout.conf          # System configuration & default policy mapping
    │   └── policies.json          # Schedule policy definitions (passive, aggressive, etc.)
    ├── lib/
    │   ├── Config.pm              # Configuration loader
    │   ├── Engine.pm              # Schedule evaluator & dispatcher
    │   ├── Policy.pm              # Interval calculation & escalation logic
    │   ├── State.pm               # JSON/SQLite state manager with file locking
    │   ├── Template.pm            # HTML/Text MIME template compiler
    │   └── Adapters/
    │       └── RockReady.pm       # Ingests styling & calendar info from /opt/rockready
    ├── templates/                 # Reusable templates
    │   ├── rockready_club.html    # Rock Ready club booking (styled from /opt/rockready)
    │   ├── rockready_club.txt     # Plain-text companion
    │   ├── personal_job.html      # Professional career/consulting inquiry
    │   ├── personal_job.txt       # Plain-text companion
    │   ├── support_vendor.html    # Vendor/ticket follow-up
    │   └── support_vendor.txt     # Plain-text companion
    ├── data/
    │   ├── contacts.json          # Input targets
    │   ├── reachout_state.json    # Execution history, attempts, and next-run timestamps
    │   └── archive/               # Historical state backups
    └── logs/
        └── reachout.log           # Transaction & execution log
```

---

## 3. Integration with `/opt/rockready`

The Reachout Program accesses `/opt/rockready` to construct authentic, visually rich booking emails:

```
+-----------------------------------+        +----------------------------------------+
|       /opt/rockready              |        |   /opt/clearscm/reachout               |
+-----------------------------------+        +----------------------------------------+
| - RockReadyLogo.png (Brand asset) | -----> | - Inlined or CID-embedded in           |
| - RockReady.band.jpg (Live photo) | -----> |   templates/rockready_club.html        |
| - custom-fixes.css (Color cues)   | -----> | - Extracted theme palette:             |
| - table_tent.php (Calendar logic) |        |   #ff5500, #c62828, #111111            |
| - WP REST API:                    | -----> | - Live show list automatically         |
|   /wp-json/tribe/events/v1/events |        |   injected into email body             |
+-----------------------------------+        +----------------------------------------+
```

### Dynamic Assets & Data Sourced from `/opt/rockready`:
1. **Brand Assets & Imagery**:
   - Official band logo: [`/opt/rockready/RockReadyLogo.png`](file:///opt/rockready/RockReadyLogo.png)
   - Stage performance photo: [`/opt/rockready/RockReady.band.jpg`](file:///opt/rockready/RockReady.band.jpg)
   - Cartoon mascot: [`/opt/rockready/RockReady_Cartoon.jpg`](file:///opt/rockready/RockReady_Cartoon.jpg)
   - Hosted fallback URLs pointing to `https://rockready.band/...` for maximum email client compatibility.
2. **Visual Styling Tokens**:
   - Palette derived from [`table_tent.php`](file:///opt/rockready/table_tent.php) and [`custom-fixes.css`](file:///opt/rockready/custom-fixes.css):
     - Primary Red/Orange: `#ff5500` and `#c62828`
     - Backgrounds: High-contrast Dark Stage (`#121212` body, `#1e1e1e` cards)
     - Typography: Clean sans-serif (`-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial`)
3. **Live Gig Schedule Integration**:
   - The template adapter queries the live WordPress database or The Events Calendar REST API (`https://rockready.band/wp-json/tribe/events/v1/events?per_page=5`) to insert an **"Upcoming Shows"** block.
   - This provides immediate social proof to club managers that Rock Ready is an active, gigging band with a following.

### 3.1 Multi-Server & Database Interrogation Architecture (Staging vs. Production)

To ensure reliable operation across environments, `reachout` incorporates explicit environment awareness:

* **Staging Server (`earth`)**:
  - Primary development and staging workspace.
  - **Staging Web Root & URL**: Served via [`https://rockready.defariahome.com/`](https://rockready.defariahome.com/) backed by local `/opt/rockready` and local MySQL on `earth`.
  - **Rock Ready Gig Interrogation**: When running on `earth`, `reachout` can interrogate either:
    1. The **staging database/API** (`https://rockready.defariahome.com/wp-json/tribe/events/v1/events` or local MySQL) for isolated staging tests.
    2. The **production API** (`https://rockready.band/wp-json/tribe/events/v1/events`) when composing outreach emails or previews that require live, up-to-date gig listings.
  - **Mail Delivery Guardrails**: By default on `earth`, outbound emails are sandboxed (dry-run or routed strictly to `Andrew@DeFaria.com`) unless explicitly overridden with `--env production --force-live`.

* **Production Cloud Server (`defaria.com` / `cloud`)**:
  - Live deployment environment hosting `defaria.com` and [`https://rockready.band/`](https://rockready.band/).
  - **Local Direct Access**: On `defaria.com`, `reachout` accesses the production `/opt/rockready` web root and interacts with the local production MySQL database (`localhost`) or local REST endpoints with zero network latency.
  - **Live Dispatch**: Processes real outreach contacts according to the schedule policy.

* **Configuration & Environment Control (`etc/reachout.conf`)**:
  - Automatically identifies host environment via `Sys::Hostname` (mapping `earth` -> `staging`, `defaria.com`/`cloud` -> `production`).
  - Supports manual override via CLI: `reachout run --env [staging|production]`.
  - Configurable database connection profiles, base URLs, and API endpoints in `etc/reachout.conf`:
    ```ini
    [staging]
    site_url          = https://rockready.defariahome.com
    rockready_api_url = https://rockready.defariahome.com/wp-json/tribe/events/v1/events
    prod_api_url      = https://rockready.band/wp-json/tribe/events/v1/events
    pull_from_prod    = 1
    db_host           = localhost
    mail_sandbox      = 1
    test_recipient    = Andrew@DeFaria.com

    [production]
    site_url          = https://rockready.band
    rockready_api_url = https://rockready.band/wp-json/tribe/events/v1/events
    db_host           = localhost
    mail_sandbox      = 0
    ```

---

## 4. Policy Engine Specifications

The system supports two core policies out of the box and allows custom policies via [`etc/policies.json`](file:///opt/clearscm/reachout/etc/policies.json).

### 4.1 Passive Policy (Club Outreach Default)
Designed to be courteous and professional without irritating venue managers:
* **Attempt 1 (Day 0 / Ingestion)**: Initial inquiry detailing band lineup, setlist versatility, video links, and asking for open dates.
* **Attempt 2 (+7 Days / 1 Week)**: Brief follow-up inquiring if the recipient had a chance to review the previous note.
* **Attempt 3 (+14 Days / 2 Weeks after Attempt 2)**: Check-in highlighting upcoming schedule or open month availability.
* **Attempt 4 (+21 Days / 3 Weeks after Attempt 3)**: Final courtesy note asking to keep Rock Ready on file for cancellations or future bookings.
* **Abandonment Action**:
  - Outreach status changes to `abandoned`.
  - Sends a completion notice to `Andrew@DeFaria.com`:
    ```
    To: Andrew@DeFaria.com
    Subject: [Reachout Terminated] No response from Dave Higgins (The Catalyst Club)

    The passive outreach campaign for Dave Higgins <booking@thecatalystclub.com>
    at The Catalyst Club has concluded after 4 attempts over 6 weeks with no response.
    Scheduled follow-ups have been stopped.
    ```

### 4.2 Aggressive Policy (Successor to `nag.pl`)
Designed for urgent internal tasks, billing reminders, or critical follow-ups:
* **Attempt 1 (Day 0)**: Initial notification.
* **Attempt 2 (Day 7 / Week 1)**: Weekly reminder.
* **Attempt 3 (Day 14 / Week 2)**: Weekly reminder.
* **Attempt 4 (Day 21 / Week 3)**: Final weekly reminder warning of daily escalation.
* **Escalation**:
  - Automatically switches frequency from weekly to **Daily** after attempt 4.
  - Sends daily reminders until the recipient replies or the campaign is manually closed.

---

## 5. Contact Input Specification

Input targets are maintained in JSON format at [`/opt/clearscm/reachout/data/contacts.json`](file:///opt/clearscm/reachout/data/contacts.json) or supplied via CLI:

```json
[
  {
    "id": "rr-catalyst-01",
    "contact": "Dave Higgins",
    "email": "booking@thecatalystclub.com",
    "venue": "The Catalyst Club",
    "web": "https://catalystclub.com",
    "phone": "(831) 423-1338",
    "policy": "passive",
    "template": "rockready_club",
    "status": "active",
    "notes": "Met at music expo. Prefers Friday/Saturday cover slots."
  },
  {
    "id": "job-google-lead",
    "contact": "Marcus Vance",
    "email": "mvance@recruiting.example.com",
    "venue": "Cloud Infrastructure Group",
    "web": "https://cloud.example.com",
    "phone": "(650) 555-0123",
    "policy": "passive",
    "template": "personal_job",
    "status": "active",
    "notes": "Senior Release Engineering inquiry."
  }
]
```

### Field Definitions
* `contact`: Recipient name (e.g. "Dave Higgins"). Fallback to "Booking Manager" or "Hiring Team" if absent.
* `email`: Destination email address (**mandatory**).
* `venue`: Venue, company, or club name (optional).
* `web`: Recipient website (optional).
* `phone`: Recipient phone number (optional).
* `policy`: `passive` (default) or `aggressive` (optional).
* `template`: Template key in `templates/` (defaults to `rockready_club`).
* `status`: `active`, `paused`, `responded`, `abandoned`, or `completed`.

---

## 6. Template Engine & Presentation

Templates are stored in [`/opt/clearscm/reachout/templates/`](file:///opt/clearscm/reachout/templates/) as paired HTML and plain-text files.

### 6.1 `rockready_club.html` (Rock Ready Themed)
* **Design Aesthetic**:
  - Dark carbon header (`#111111`) with centered [RockReadyLogo.png](file:///opt/rockready/RockReadyLogo.png).
  - High-impact accent colors: Flame Orange (`#ff5500`) and Crimson (`#c62828`).
  - Fluid, mobile-responsive table layout rendering reliably in Gmail, Apple Mail, and Outlook.
* **Variable Substitutions**:
  - `{{Contact}}`: Contact person's first or full name.
  - `{{Venue}}`: Name of the club/venue.
  - `{{AttemptNumber}}`: Current outreach stage (1–4).
  - `{{UpcomingShows}}`: Sourced dynamically from WordPress/The Events Calendar.
  - `{{DemoLink}}`: Direct link to audio/video demos on `https://rockready.band`.
  - `{{SenderPhone}}` & `{{SenderEmail}}`: Andrew's booking contact info.
  - `{{OptOutLink}}`: Polite one-click opt-out.

### 6.2 Generic Templates
* **`personal_job.html`**: Clean, modern corporate template with resume link, ClearSCM consulting highlights, and technical expertise.
* **`support_vendor.html`**: Structured ticket follow-up with issue reference and escalation flags.

---

## 7. MAPS (Mail Authorization and Permission System) Integration

Because MAPS is located right next door in [`/opt/clearscm/maps`](file:///opt/clearscm/maps), integrating inbound responses is clean and fast.

### 7.1 Outbound Email Headers
When `reachout` sends an email via [`/opt/clearscm/lib/Mail.pm`](file:///opt/clearscm/lib/Mail.pm), it adds custom tracking headers:
* `X-Reachout-ID: <id>` (e.g., `rr-catalyst-01`)
* `X-Reachout-Policy: <policy>`
* `Message-ID: <rr-<id>-<attempt>@defaria.com>`
* `References` / `In-Reply-To` referencing previous attempt Message-IDs.

### 7.2 Inbound Hook in `/opt/clearscm/maps/bin/maps`
When an incoming email is processed by `maps`:
1. **Reply & Sender Check**:
   - MAPS checks if the incoming email sender or `In-Reply-To` header matches an active target in `/opt/clearscm/reachout/data/reachout_state.json`.
2. **Automated Whitelist**:
   - If a match is found, MAPS immediately whitelists the sender address in the MAPS database so all future communications bypass quarantine.
3. **Outreach Auto-Pause Callback**:
   - MAPS executes the reachout pause command:
     ```bash
     /opt/clearscm/bin/reachout pause --id "$target_id" --reason "Received reply via MAPS"
     ```
   - Target status updates from `active` to `responded`.
4. **Inbox Notification**:
   - MAPS tags the message with `X-MAPS-Reachout: Paused-Awaiting-Review` and delivers it straight to Andrew's inbox.
   - Andrew can subsequently run:
     - `reachout resume <id>` (if follow-up is still needed later)
     - `reachout close <id> --status booked` (if the gig was secured)

---

## 8. CLI Command Interface (`reachout`)

The executable [`/opt/clearscm/bin/reachout`](file:///opt/clearscm/bin/reachout) will provide a unified interface:

```bash
# Periodic execution (run via crontab)
reachout run [--dry-run] [--verbose]

# Target Management
reachout add --file /path/to/contacts.json
reachout add --email "booking@club.com" --venue "The Catalyst" --policy passive
reachout list [--status active|paused|abandoned|completed]
reachout status <id>

# Campaign Control
reachout pause <id> [--reason "text"]
reachout resume <id>
reachout close <id> [--status booked|declined|completed]

# Preview & Testing
reachout test-email --template rockready_club --to Andrew@DeFaria.com
```

### Legacy `nag.pl` Transition & Retirement
[`/opt/clearscm/bin/nag.pl`](file:///opt/clearscm/bin/nag.pl) will be replaced with a wrapper script:
```perl
#!/usr/bin/perl
# Backward compatibility shim for nag.pl -> reachout
exec '/opt/clearscm/bin/reachout', 'run', '--legacy-nag', @ARGV;
```
A one-time migration utility (`reachout migrate-nag`) will import any existing entries from `~/.nag/list` directly into `reachout_state.json`.

---

## 9. Phased Implementation Roadmap

### Phase 1: Directory Setup & Core Architecture
* [ ] Create directory structure under `/opt/clearscm/reachout/` (`bin/`, `etc/`, `lib/`, `templates/`, `data/`, `logs/`).
* [ ] Implement configuration loader (`reachout.conf`) and policy definitions (`policies.json`).
* [ ] Build state engine (`State.pm`) managing `reachout_state.json` with file locking.

### Phase 2: Template Engine & Rock Ready Theming
* [ ] Implement `Template.pm` supporting variable interpolation and HTML/text multipart dispatch.
* [ ] Create `templates/rockready_club.html` and `.txt`:
  - Pull brand assets and CSS styling from `/opt/rockready`.
  - Connect dynamic show schedule from WordPress REST API (`tribe/events/v1/events`).
* [ ] Create generic templates `personal_job.html` and `support_vendor.html`.

### Phase 3: Policy Engine & CLI
* [ ] Implement `Policy.pm`:
  - **Passive Policy**: Week 1, 2, 3 intervals + abandonment alert to `Andrew@DeFaria.com`.
  - **Aggressive Policy**: 3 weekly reminders + daily escalation (replacing `nag.pl`).
* [ ] Implement CLI utility `/opt/clearscm/reachout/bin/reachout` and symlink to `/opt/clearscm/bin/reachout`.
* [ ] Build `nag.pl` compatibility wrapper and migration utility for `~/.nag/list`.

### Phase 4: MAPS Interoperability
* [ ] Implement custom header generation in outbound mail via `Mail.pm`.
* [ ] Add reachout hook into [`/opt/clearscm/maps/bin/maps`](file:///opt/clearscm/maps/bin/maps):
  - Inbound reply detection.
  - Automatic sender whitelisting.
  - State update (`reachout pause`).

### Phase 5: Testing & Production Deployment
* [ ] Test end-to-end dry-run with simulated clock timestamps.
* [ ] Send test emails to `Andrew@DeFaria.com` to verify visual appeal on desktop and mobile.
* [ ] Configure production cron job in `crontab`:
  ```crontab
  # Process reachouts every morning at 9:00 AM (Mon-Fri)
  0 9 * * 1-5 /opt/clearscm/bin/reachout run >> /opt/clearscm/reachout/logs/reachout.log 2>&1
  ```
