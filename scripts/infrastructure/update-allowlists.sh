#!/usr/bin/env bash
set -euo pipefail

# Script to update Traefik allowlists with Tailscale peer IPs
# Usage: ./scripts/update-allowlists.sh [peer-ips-file]

MIDDLEWARES_FILE="traefik/dynamic/middlewares.yml"
PEER_IPS_FILE="${1:-/tmp/inlock-audit/tailscale-peer-ips-*.txt}"

if [ ! -f "$MIDDLEWARES_FILE" ]; then
  echo "ERROR: $MIDDLEWARES_FILE not found"
  exit 1
fi

# Find most recent peer IPs file if glob pattern
if [[ "$PEER_IPS_FILE" == *"*"* ]]; then
  PEER_IPS_FILE=$(ls -t $PEER_IPS_FILE 2>/dev/null | head -1)
fi

if [ ! -f "$PEER_IPS_FILE" ]; then
  echo "ERROR: Peer IPs file not found: $PEER_IPS_FILE"
  echo "Run: sudo ./scripts/capture-tailnet-status.sh first"
  exit 1
fi

echo "Reading peer IPs from: $PEER_IPS_FILE"
PEER_IPS=()
while IFS= read -r ip; do
  if [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    PEER_IPS+=("$ip/32")
  fi
done < "$PEER_IPS_FILE"

if [ ${#PEER_IPS[@]} -eq 0 ]; then
  echo "WARNING: No valid IPs found in $PEER_IPS_FILE"
  echo "Please manually update $MIDDLEWARES_FILE"
  exit 1
fi

echo "Found ${#PEER_IPS[@]} peer IPs:"
printf '  - %s\n' "${PEER_IPS[@]}"

# Create backup
BACKUP_FILE="${MIDDLEWARES_FILE}.backup-$(date +%F-%H%M%S)"
cp "$MIDDLEWARES_FILE" "$BACKUP_FILE"
echo "Backup created: $BACKUP_FILE"

# Generate new allowlist section
cat > /tmp/new-allowlist.yml <<EOF
    allowed-admins:
      ipAllowList:
        sourceRange:
EOF

for ip in "${PEER_IPS[@]}"; do
  echo "          - $ip" >> /tmp/new-allowlist.yml
done

# Update middlewares file (replace allowed-admins section)
# This is a simple sed-based replacement - may need manual review
awk '
  /allowed-admins:/ { 
    in_section=1
    print
    next
  }
  in_section && /^[[:space:]]*[a-z]/ {
    in_section=0
  }
  in_section && /sourceRange:/ {
    print
    # Read and skip old IPs until we hit a non-indented line or end
    while ((getline line) > 0) {
      if (line ~ /^[[:space:]]*- [0-9]/) {
        # Skip old IP lines
        continue
      } else if (line ~ /^[[:space:]]*[a-z]/ || line == "") {
        # Hit next section or empty line
        break
      }
    }
    # Insert new IPs
    system("cat /tmp/new-allowlist.yml | grep -A 100 sourceRange:")
    print line
    next
  }
  !in_section {
    print
  }
' "$MIDDLEWARES_FILE" > "${MIDDLEWARES_FILE}.new"

mv "${MIDDLEWARES_FILE}.new" "$MIDDLEWARES_FILE"

echo ""
echo "✅ Allowlist updated in $MIDDLEWARES_FILE"
echo ""
echo "⚠️  Please review the changes:"
echo "   diff $BACKUP_FILE $MIDDLEWARES_FILE"
echo ""
echo "Next steps:"
echo "1. Review the updated allowlist"
echo "2. Commit changes: git diff $MIDDLEWARES_FILE"
echo "3. Redeploy: ansible-playbook -i inventories/hosts.yml playbooks/deploy.yml"
echo "4. Test access from unauthorized IP (should return 403)"

