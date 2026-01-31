#!/usr/bin/env bash
set -euo pipefail

# Restrict admin/management ports to Tailscale only via DOCKER-USER.
# Adjust ADMIN_PORTS if you need to add/remove ports.
ADMIN_PORTS=(8080 8443)
TAILSCALE_CIDR="100.64.0.0/10"

# Ensure DOCKER-USER exists
iptables -N DOCKER-USER 2>/dev/null || true

# Allow established/related
iptables -C DOCKER-USER -m state --state ESTABLISHED,RELATED -j ACCEPT 2>/dev/null \
  || iptables -I DOCKER-USER 1 -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow admin ports from Tailscale
for port in "${ADMIN_PORTS[@]}"; do
  iptables -C DOCKER-USER -p tcp --dport "${port}" -s "${TAILSCALE_CIDR}" -j ACCEPT 2>/dev/null \
    || iptables -I DOCKER-USER 2 -p tcp --dport "${port}" -s "${TAILSCALE_CIDR}" -j ACCEPT
  # Drop non-Tailscale to admin ports
  iptables -C DOCKER-USER -p tcp --dport "${port}" -j DROP 2>/dev/null \
    || iptables -A DOCKER-USER -p tcp --dport "${port}" -j DROP
  done

# Return to docker for all else
iptables -C DOCKER-USER -j RETURN 2>/dev/null || iptables -A DOCKER-USER -j RETURN
