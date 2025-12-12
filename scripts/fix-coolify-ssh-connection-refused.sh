#!/bin/bash
set -e
MGMT_SUBNET=$(docker network inspect mgmt --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}' 2>/dev/null || echo "172.18.0.0/16")
COOLIFY_SUBNET=$(docker network inspect coolify --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}' 2>/dev/null || echo "172.23.0.0/16")
echo "=== Fixing SSH Connection Refused ==="
if ! systemctl is-active --quiet sshd; then systemctl start sshd; sleep 2; fi
if ! ss -tlnp | grep -q ":22 "; then systemctl restart sshd; sleep 2; fi
echo "Removing old UFW rules..."
ufw --force delete allow from $MGMT_SUBNET to any port 22 2>/dev/null || true
ufw --force delete allow from $COOLIFY_SUBNET to any port 22 2>/dev/null || true
ufw --force delete allow from 172.16.0.0/12 to any port 22 2>/dev/null || true
echo "Adding new UFW rules..."
ufw allow from $MGMT_SUBNET to any port 22 proto tcp comment 'Coolify SSH'
ufw allow from $COOLIFY_SUBNET to any port 22 proto tcp comment 'Coolify SSH'
ufw allow from 172.16.0.0/12 to any port 22 proto tcp comment 'Docker networks'
ufw reload
echo "✓ Fix complete"
cd /home/comzis/inlock-infra
sleep 2
if docker compose -f compose/coolify.yml --env-file .env exec coolify nc -zv -w 5 156.67.29.52 22 2>&1 | grep -q "succeeded\|open"; then
    echo "✅ Connection test successful!"
else
    echo "⚠️  Still failing - check UFW: sudo ufw status verbose"
fi

