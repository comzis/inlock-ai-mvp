#!/usr/bin/env bash
set -euo pipefail

# Restrict admin/management ports to Tailscale only via DOCKER-USER.
# Adjust ADMIN_PORTS if you need to add/remove ports.
#
# NOTE (mail.inlock.ai):
# If a service is fronted by Traefik but still published on the host (e.g. Mailcow nginx on 8080/8443),
# Traefik will reach it from Docker bridge networks (not from Tailscale). Those internal networks must be
# allowed, otherwise Traefik requests will hang/time out and the public domain will appear "down".
ADMIN_PORTS=(8080 8443)
TAILSCALE_CIDR="100.64.0.0/10"
TRUSTED_DOCKER_CIDRS=("172.17.0.0/16" "172.18.0.0/16" "172.20.0.0/16")

# Ensure DOCKER-USER exists
iptables -N DOCKER-USER 2>/dev/null || true

# Allow established/related
iptables -C DOCKER-USER -m state --state ESTABLISHED,RELATED -j ACCEPT 2>/dev/null \
  || iptables -I DOCKER-USER 1 -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow admin ports from Tailscale
for port in "${ADMIN_PORTS[@]}"; do
  iptables -C DOCKER-USER -p tcp --dport "${port}" -s "${TAILSCALE_CIDR}" -j ACCEPT 2>/dev/null \
    || iptables -I DOCKER-USER 2 -p tcp --dport "${port}" -s "${TAILSCALE_CIDR}" -j ACCEPT

  # Allow from trusted internal Docker networks (e.g. Traefik)
  for cidr in "${TRUSTED_DOCKER_CIDRS[@]}"; do
    iptables -C DOCKER-USER -p tcp --dport "${port}" -s "${cidr}" -j ACCEPT 2>/dev/null \
      || iptables -I DOCKER-USER 2 -p tcp --dport "${port}" -s "${cidr}" -j ACCEPT
  done

  # Drop non-Tailscale to admin ports
  iptables -C DOCKER-USER -p tcp --dport "${port}" -j DROP 2>/dev/null \
    || iptables -A DOCKER-USER -p tcp --dport "${port}" -j DROP
  done

# Return to docker for all else
iptables -C DOCKER-USER -j RETURN 2>/dev/null || iptables -A DOCKER-USER -j RETURN
