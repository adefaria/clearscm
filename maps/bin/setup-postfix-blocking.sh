#!/usr/bin/env bash
#-------------------------------------------------------------------------------
# setup-postfix-blocking.sh
#
# Configures Postfix MTA sender access blocking and sudoers permissions for MAPS.
# Run this script with root/sudo privileges on defaria.com (or local server).
#-------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAPS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKER_SRC="${MAPS_DIR}/postfix-worker.pl"
SUDOERS_FILE="/etc/sudoers.d/maps-postfix"
ACCESS_FILE="/etc/postfix/sender_access"

echo "=== MAPS Postfix Sender Access Deployment ==="

if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root (or with sudo)." >&2
   exit 1
fi

if [[ ! -f "${WORKER_SRC}" ]]; then
    echo "Error: Worker source not found at ${WORKER_SRC}" >&2
    exit 1
fi

chmod +x "${WORKER_SRC}"

# 1. Symlinks in /usr/local/sbin
echo "[1/5] Symlinking worker to /usr/local/sbin..."
ln -sf "${WORKER_SRC}" /usr/local/sbin/postfix-worker.pl
ln -sf "${WORKER_SRC}" /usr/local/sbin/maps-postfix-worker.pl
echo "      Symlinks created successfully."

# 2. Configure Sudoers for www-data
echo "[2/5] Installing sudoers configuration..."
cat << 'EOF' > "${SUDOERS_FILE}"
# Allow www-data (MAPS web server process) to run postfix worker with domain arguments
www-data ALL=(root) NOPASSWD: /usr/local/sbin/postfix-worker.pl, /usr/local/sbin/postfix-worker.pl *, /usr/local/sbin/maps-postfix-worker.pl, /usr/local/sbin/maps-postfix-worker.pl *
EOF
chmod 0440 "${SUDOERS_FILE}"
visudo -c -f "${SUDOERS_FILE}"
echo "      Sudoers rule validated."

# 3. Initialize sender_access map
echo "[3/5] Initializing ${ACCESS_FILE}..."
if [[ ! -f "${ACCESS_FILE}" ]]; then
    cat << 'EOF' > "${ACCESS_FILE}"
# /etc/postfix/sender_access
# Postfix sender access table for MAPS Phishing blocks
# Format: domain.com    REJECT ...
EOF
    chmod 0644 "${ACCESS_FILE}"
fi
postmap "${ACCESS_FILE}"
echo "      Access map compiled with postmap."

# 4. Configure Postfix main.cf
echo "[4/5] Updating Postfix configuration..."
postconf -e "smtpd_sender_restrictions = permit_mynetworks, reject_non_fqdn_sender, check_sender_access hash:${ACCESS_FILE}, permit"
postconf -e "parent_domain_matches_subdomains = debug_peer_list,fast_flush_domains,mynetworks,permit_mx_backup_networks,qmqpd_authorized_clients,relay_domains,smtpd_access_maps"

postfix check
postfix reload
echo "      Postfix reloaded successfully."

# 5. Verification
echo "[5/5] Testing execution permissions for www-data..."
sudo -u www-data sudo /usr/local/sbin/postfix-worker.pl --help >/dev/null
echo "      www-data sudo execution confirmed."

echo "=== Deployment Complete! ==="
