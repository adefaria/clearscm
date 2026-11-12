#!/usr/bin/env python3
"""
Fetch Google Tasks and convert them to RFC 5545 VTODO format for iCalendar / Rainlendar.
Uses only Python 3 standard library modules (no third-party pip dependencies required).
"""

import sys
import os
import json
import time
import subprocess
import re
import shutil
import urllib.request
import urllib.parse
import urllib.error
import http.server
import socketserver
import webbrowser
from datetime import datetime, timezone

TOKEN_PATH = os.path.expanduser("~/.config/google_tasks_token.json")
CREDENTIALS_PATH = os.path.expanduser("~/.config/google_tasks_client_secret.json")
BW_ITEM_DEFAULT = "Google OAuth"
AUTH_SCOPE = "https://www.googleapis.com/auth/tasks.readonly"
TOKEN_URL = "https://oauth2.googleapis.com/token"
AUTH_ENDPOINT = "https://accounts.google.com/o/oauth2/v2/auth"
API_BASE = "https://tasks.googleapis.com/tasks/v1"


def escape_ical_text(text: str) -> str:
    """Escape special characters according to RFC 5545."""
    if not text:
        return ""
    text = text.replace("\\", "\\\\")
    text = text.replace(";", "\\;")
    text = text.replace(",", "\\,")
    text = text.replace("\r\n", "\\n").replace("\r", "\\n").replace("\n", "\\n")
    return text


def get_bw_executable() -> str:
    """Locate the Bitwarden CLI executable, prioritizing /opt/bitwarden/bin/bw."""
    candidates = [
        "/opt/bitwarden/bin/bw",
        "/usr/local/bin/bw",
    ]
    for candidate in candidates:
        if os.path.isfile(candidate) and os.access(candidate, os.X_OK):
            return candidate

    return shutil.which("bw")


def get_credentials_from_bitwarden(item_name=BW_ITEM_DEFAULT):
    """
    Fetch credentials directly from Bitwarden CLI (bw) in memory without touching disk.
    Checks item fields first, then parses notes body.
    """
    bw_cmd = get_bw_executable()
    if not bw_cmd:
        return {}

    try:
        proc = subprocess.run(
            [bw_cmd, "get", "item", item_name],
            capture_output=True,
            text=True,
            check=False,
        )
        if proc.returncode != 0:
            if "Vault is locked" in proc.stderr:
                sys.stderr.write("Notice: Bitwarden vault is locked. Run 'export BW_SESSION=$(bw unlock --raw)'\n")
            return {}

        item_data = json.loads(proc.stdout)
    except Exception:
        return {}

    result = {}

    # 1. Custom fields
    for field in item_data.get("fields", []):
        name = (field.get("name") or "").lower().replace("-", "_").replace(" ", "_")
        val = field.get("value")
        if not val:
            continue
        if name in ("client_id", "google_client_id"):
            result["client_id"] = val.strip()
        elif name in ("client_secret", "google_client_secret"):
            result["client_secret"] = val.strip()
        elif name in ("refresh_token", "google_refresh_token"):
            result["refresh_token"] = val.strip()

    # 2. Parse notes body for matches if not found in custom fields
    notes = item_data.get("notes") or ""
    if not result.get("client_id"):
        m = re.search(r"(?i)(?:client[_\s-]?id)\s*[:=]\s*([^\r\n]+)", notes)
        if m:
            result["client_id"] = m.group(1).strip()

    if not result.get("client_secret"):
        m = re.search(r"(?i)(?:client[_\s-]?secret)\s*[:=]\s*([^\r\n]+)", notes)
        if m:
            result["client_secret"] = m.group(1).strip()

    if not result.get("refresh_token"):
        m = re.search(r"(?i)(?:refresh[_\s-]?token)\s*[:=]\s*([^\r\n]+)", notes)
        if m:
            result["refresh_token"] = m.group(1).strip()

    return result


def load_credentials(creds_path=CREDENTIALS_PATH, token_path=TOKEN_PATH, bw_item=BW_ITEM_DEFAULT):
    """Load client_id and client_secret from Bitwarden, creds_path, or token_path."""
    # 1. Attempt retrieval from Bitwarden
    if bw_item:
        bw_data = get_credentials_from_bitwarden(bw_item)
        if bw_data.get("client_id") and bw_data.get("client_secret"):
            return bw_data.get("client_id"), bw_data.get("client_secret"), bw_data.get("refresh_token")

    # 2. Attempt retrieval from filesystem
    for path in [creds_path, token_path]:
        if os.path.exists(path):
            try:
                with open(path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                app_info = data.get("installed") or data.get("web") or data
                client_id = app_info.get("client_id")
                client_secret = app_info.get("client_secret")
                refresh_token = data.get("refresh_token")
                if client_id and client_secret:
                    return client_id, client_secret, refresh_token
            except Exception:
                continue

    return None, None, None


def authorize_interactive(client_id, client_secret, token_path=TOKEN_PATH):
    """Run interactive local OAuth 2.0 authorization code flow."""
    if not client_id or not client_secret:
        sys.stderr.write(
            f"Error: Missing client credentials to run authorization.\n"
            f"Please save client credentials to {CREDENTIALS_PATH} or {token_path}.\n"
        )
        sys.exit(1)

    auth_code = None

    class OAuthHandler(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            nonlocal auth_code
            parsed = urllib.parse.urlparse(self.path)
            query = urllib.parse.parse_qs(parsed.query)

            if "code" in query:
                auth_code = query["code"][0]
                self.send_response(200)
                self.send_header("Content-Type", "text/html; charset=utf-8")
                self.end_headers()
                self.wfile.write(
                    b"<html><body style='font-family:sans-serif;text-align:center;padding:50px;'>"
                    b"<h2>Google Tasks Authorization Successful</h2>"
                    b"<p>You may now close this window and return to your terminal.</p>"
                    b"</body></html>"
                )
            else:
                error = query.get("error", ["Unknown error"])[0]
                self.send_response(400)
                self.send_header("Content-Type", "text/html; charset=utf-8")
                self.end_headers()
                self.wfile.write(f"<html><body><h2>Authorization Failed</h2><p>{error}</p></body></html>".encode("utf-8"))

        def log_message(self, format, *args):
            pass

    with socketserver.TCPServer(("127.0.0.1", 0), OAuthHandler) as httpd:
        port = httpd.server_address[1]
        redirect_uri = f"http://127.0.0.1:{port}/"

        params = {
            "client_id": client_id,
            "redirect_uri": redirect_uri,
            "response_type": "code",
            "scope": AUTH_SCOPE,
            "access_type": "offline",
            "prompt": "consent",
        }
        auth_url = f"{AUTH_ENDPOINT}?{urllib.parse.urlencode(params)}"

        print("=" * 70)
        print("GOOGLE TASKS AUTHORIZATION REQUIRED")
        print("=" * 70)
        print("Opening your browser to authorize access to Google Tasks...")
        print(f"If the browser doesn't open automatically, visit this URL:\n\n{auth_url}\n")
        print("Waiting for authorization callback...")

        webbrowser.open(auth_url)
        httpd.handle_request()

    if not auth_code:
        sys.stderr.write("Failed to retrieve authorization code.\n")
        sys.exit(1)

    token_params = {
        "code": auth_code,
        "client_id": client_id,
        "client_secret": client_secret,
        "redirect_uri": redirect_uri,
        "grant_type": "authorization_code",
    }
    encoded_data = urllib.parse.urlencode(token_params).encode("utf-8")
    req = urllib.request.Request(TOKEN_URL, data=encoded_data, headers={"Content-Type": "application/x-www-form-urlencoded"})

    try:
        with urllib.request.urlopen(req) as resp:
            token_data = json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        sys.stderr.write(f"Error exchanging authorization code: {e.read().decode('utf-8')}\n")
        sys.exit(1)

    token_data["client_id"] = client_id
    token_data["client_secret"] = client_secret
    token_data["expires_at"] = time.time() + token_data.get("expires_in", 3600)

    os.makedirs(os.path.dirname(token_path), exist_ok=True)
    with open(token_path, "w", encoding="utf-8") as f:
        json.dump(token_data, f, indent=2)
    os.chmod(token_path, 0o600)

    print(f"\nAuthorization successful! Credentials saved to {token_path}")
    return token_data


def get_access_token(client_id, client_secret, initial_refresh_token=None, token_path=TOKEN_PATH):
    """Retrieve an active access token in memory, refreshing if necessary."""
    token_data = {}

    # Check filesystem token cache if it exists
    if os.path.exists(token_path):
        try:
            with open(token_path, "r", encoding="utf-8") as f:
                token_data = json.load(f)
        except Exception:
            token_data = {}

    # Prefer refresh_token from Bitwarden if passed, otherwise from token cache
    refresh_token = initial_refresh_token or token_data.get("refresh_token")

    # If active access token exists and not expired, use it
    expires_at = token_data.get("expires_at")
    if token_data.get("access_token") and (expires_at is None or expires_at > (time.time() + 60)):
        return token_data["access_token"]

    # If we have a refresh_token and client credentials, refresh token in memory
    if refresh_token and client_id and client_secret:
        params = {
            "client_id": client_id,
            "client_secret": client_secret,
            "refresh_token": refresh_token,
            "grant_type": "refresh_token",
        }
        encoded_data = urllib.parse.urlencode(params).encode("utf-8")
        req = urllib.request.Request(TOKEN_URL, data=encoded_data, headers={"Content-Type": "application/x-www-form-urlencoded"})

        try:
            with urllib.request.urlopen(req) as resp:
                new_data = json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError as e:
            err_msg = e.read().decode("utf-8")
            sys.stderr.write(f"Token refresh failed: {err_msg}. Re-authorizing...\n")
            return authorize_interactive(client_id, client_secret, token_path)["access_token"]

        token_data["access_token"] = new_data["access_token"]
        token_data["expires_at"] = time.time() + new_data.get("expires_in", 3600)
        token_data["refresh_token"] = refresh_token

        # Save cache to avoid hitting token endpoint on every single run
        try:
            os.makedirs(os.path.dirname(token_path), exist_ok=True)
            with open(token_path, "w", encoding="utf-8") as f:
                json.dump(token_data, f, indent=2)
            os.chmod(token_path, 0o600)
        except Exception:
            pass

        return token_data["access_token"]

    # If no refresh token exists, run interactive authorization
    if not client_id or not client_secret:
        sys.stderr.write(
            "Error: Client ID and Secret not found.\n"
            "Ensure Bitwarden is unlocked (BW_SESSION) with an item named 'Google OAuth',\n"
            f"or provide them in {CREDENTIALS_PATH}.\n"
        )
        sys.exit(1)

    return authorize_interactive(client_id, client_secret, token_path)["access_token"]


def api_get(endpoint: str, access_token: str):
    """Perform GET request against Google Tasks API."""
    url = f"{API_BASE}{endpoint}"
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {access_token}"})
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        sys.stderr.write(f"Google Tasks API error ({url}): {e.read().decode('utf-8')}\n")
        return None


def fetch_all_tasks(access_token, include_completed=False):
    """Retrieve all tasks across all task lists."""
    lists_resp = api_get("/users/@me/lists", access_token)
    if not lists_resp or "items" not in lists_resp:
        return []

    all_tasks = []
    for tlist in lists_resp.get("items", []):
        list_id = tlist.get("id")
        list_title = tlist.get("title", "Tasks")

        endpoint = f"/lists/{list_id}/tasks?showHidden=false"
        if not include_completed:
            endpoint += "&showCompleted=false"
        else:
            endpoint += "&showCompleted=true"

        tasks_resp = api_get(endpoint, access_token)
        if tasks_resp and "items" in tasks_resp:
            for task in tasks_resp["items"]:
                task["_list_title"] = list_title
                all_tasks.append(task)

    return all_tasks


def task_to_vtodo(task) -> str:
    """Format a single task dictionary into an RFC 5545 VTODO block."""
    uid = task.get("id", str(time.time())) + "@tasks.google.com"
    title = escape_ical_text(task.get("title", "Untitled Task"))
    notes = escape_ical_text(task.get("notes", ""))
    list_title = escape_ical_text(task.get("_list_title", ""))

    now_utc = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")

    lines = [
        "BEGIN:VTODO",
        f"UID:{uid}",
        f"DTSTAMP:{now_utc}",
        f"SUMMARY:{title}",
    ]

    if notes:
        lines.append(f"DESCRIPTION:{notes}")

    if list_title:
        lines.append(f"CATEGORIES:{list_title}")

    # Handle due date (Google Tasks format: '2026-11-15T00:00:00.000Z')
    due = task.get("due")
    if due:
        try:
            # Parse ISO date and output date-only or datetime
            dt = datetime.fromisoformat(due.replace("Z", "+00:00"))
            lines.append(f"DUE;VALUE=DATE:{dt.strftime('%Y%m%d')}")
        except Exception:
            clean_due = due.replace("-", "").replace(":", "").split(".")[0] + "Z"
            lines.append(f"DUE:{clean_due}")

    status = task.get("status")
    if status == "completed":
        lines.append("STATUS:COMPLETED")
        completed_at = task.get("completed")
        if completed_at:
            try:
                dt_comp = datetime.fromisoformat(completed_at.replace("Z", "+00:00"))
                lines.append(f"COMPLETED:{dt_comp.strftime('%Y%m%dT%H%M%SZ')}")
            except Exception:
                pass
    else:
        lines.append("STATUS:NEEDS-ACTION")

    lines.append("END:VTODO")
    return "\r\n".join(lines) + "\r\n"


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Fetch Google Tasks in RFC 5545 VTODO format.")
    parser.add_argument("--auth", action="store_true", help="Run interactive authorization flow and exit")
    parser.add_argument("--completed", action="store_true", help="Include completed tasks")
    parser.add_argument("--bw-item", default=BW_ITEM_DEFAULT, help=f"Bitwarden item name to load credentials from (default: '{BW_ITEM_DEFAULT}')")
    parser.add_argument("--credentials", default=CREDENTIALS_PATH, help=f"Path to credentials JSON (default: {CREDENTIALS_PATH})")
    parser.add_argument("--token", default=TOKEN_PATH, help=f"Path to token file (default: {TOKEN_PATH})")
    args = parser.parse_args()

    client_id, client_secret, refresh_token = load_credentials(args.credentials, args.token, args.bw_item)

    if args.auth:
        authorize_interactive(client_id, client_secret, args.token)
        return

    access_token = get_access_token(client_id, client_secret, refresh_token, args.token)
    tasks = fetch_all_tasks(access_token, include_completed=args.completed)

    for task in tasks:
        # Ignore empty/deleted items without a title
        if not task.get("title") and not task.get("notes"):
            continue
        sys.stdout.write(task_to_vtodo(task))


if __name__ == "__main__":
    main()
