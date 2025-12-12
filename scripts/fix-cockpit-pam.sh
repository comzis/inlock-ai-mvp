#!/bin/bash
# Normalize Cockpit PAM configuration for Ubuntu hosts.
# Usage: sudo ./scripts/fix-cockpit-pam.sh

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root (use sudo)." >&2
  exit 1
fi

COCKPIT_PAM="/etc/pam.d/cockpit"
TIMESTAMP="$(date +%Y%m%d%H%M%S)"
BACKUP="${COCKPIT_PAM}.${TIMESTAMP}.bak"

echo "Backing up ${COCKPIT_PAM} to ${BACKUP}..."
cp "${COCKPIT_PAM}" "${BACKUP}"

cat <<'EOF' > "${COCKPIT_PAM}"
#%PAM-1.0
auth       include      common-auth
auth       optional     pam_ssh_add.so

account    required     pam_listfile.so item=user sense=deny file=/etc/cockpit/disallowed-users onerr=succeed
account    required     pam_nologin.so
account    include      common-account

password   include      common-password

session    required     pam_loginuid.so
session    optional     pam_keyinit.so force revoke
session    optional     pam_ssh_add.so
session    include      common-session
session    include      common-session-noninteractive
EOF

echo "Restarting Cockpit..."
systemctl restart cockpit.socket cockpit.service

echo "Cockpit status:"
systemctl status cockpit.socket --no-pager | sed -n '1,5p'
systemctl status cockpit.service --no-pager | sed -n '1,5p'

echo "Done. Try logging into Cockpit with your system credentials."
