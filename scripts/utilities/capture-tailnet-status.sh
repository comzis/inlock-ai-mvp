#!/usr/bin/env bash
set -euo pipefail

# Script to capture Tailnet posture and container status
# Run with: sudo ./scripts/capture-tailnet-status.sh

OUTPUT_DIR="${OUTPUT_DIR:-/tmp/inlock-audit}"
mkdir -p "$OUTPUT_DIR"
TIMESTAMP="$(date +%F-%H%M%S)"

echo "Capturing Tailnet and infrastructure status..."
echo "Output directory: $OUTPUT_DIR"

# Tailscale peer status
if command -v tailscale &> /dev/null; then
  echo "Capturing Tailscale status..."
  sudo tailscale status --json > "$OUTPUT_DIR/tailscale-status-${TIMESTAMP}.json" || echo "Failed to capture Tailscale status"
  sudo tailscale ip -4 > "$OUTPUT_DIR/tailscale-ip-${TIMESTAMP}.txt" || echo "Failed to capture Tailscale IP"
  
  # Extract peer IPs for allowlist
  if command -v jq &> /dev/null; then
    jq -r '.Peer[] | select(.Online == true) | .TailscaleIPs[0]' \
      "$OUTPUT_DIR/tailscale-status-${TIMESTAMP}.json" \
      > "$OUTPUT_DIR/tailscale-peer-ips-${TIMESTAMP}.txt" 2>/dev/null || true
    echo "Peer IPs extracted to: $OUTPUT_DIR/tailscale-peer-ips-${TIMESTAMP}.txt"
  fi
else
  echo "WARNING: tailscale command not found"
fi

# Container status
if command -v docker &> /dev/null; then
  echo "Capturing container status..."
  sudo docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}' \
    > "$OUTPUT_DIR/containers-${TIMESTAMP}.txt" || echo "Failed to capture container status"
  
  sudo docker ps --format '{{.Names}}' > "$OUTPUT_DIR/container-names-${TIMESTAMP}.txt" || true
else
  echo "WARNING: docker command not found"
fi

# Firewall status
if command -v ufw &> /dev/null; then
  echo "Capturing firewall status..."
  sudo ufw status verbose > "$OUTPUT_DIR/ufw-status-${TIMESTAMP}.txt" || echo "Failed to capture firewall status"
else
  echo "WARNING: ufw command not found"
fi

# Network interfaces
echo "Capturing network interfaces..."
ip addr show > "$OUTPUT_DIR/interfaces-${TIMESTAMP}.txt" 2>/dev/null || ifconfig > "$OUTPUT_DIR/interfaces-${TIMESTAMP}.txt" 2>/dev/null || true

# Docker networks
if command -v docker &> /dev/null; then
  echo "Capturing Docker networks..."
  sudo docker network ls > "$OUTPUT_DIR/docker-networks-${TIMESTAMP}.txt" || true
  sudo docker network inspect edge mgmt internal socket-proxy 2>/dev/null \
    > "$OUTPUT_DIR/docker-networks-detail-${TIMESTAMP}.json" || true
fi

echo ""
echo "✅ Status capture complete!"
echo "📁 Output directory: $OUTPUT_DIR"
echo ""
echo "Next steps:"
echo "1. Review tailscale-peer-ips-*.txt for allowlist updates"
echo "2. Update traefik/dynamic/middlewares.yml with real IPs"
echo "3. Verify firewall rules in ufw-status-*.txt"

