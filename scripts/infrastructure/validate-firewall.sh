#!/usr/bin/env bash
set -euo pipefail

echo "UFW status:"
ufw status verbose || true

echo "Listening sockets:"
ss -tulpen

