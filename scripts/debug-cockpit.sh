#!/bin/bash
# scripts/debug-cockpit.sh
# Diagnostic script to find why Cockpit login fails

echo "=========================================="
echo "🕵️  COCKPIT DEBUGGER"
echo "=========================================="

echo "[1] Checking Sudo Access..."
if ! sudo -n true 2>/dev/null; then
    echo "    (You might be asked for your sudo password now)"
fi
sudo echo "    OK."

echo ""
echo "[2] Checking User Account Status 'comzis'..."
# P = Usable Password, L = Locked, NP = No Password
STATUS=$(sudo passwd -S comzis | awk '{print $2}')
echo "    Status: $STATUS"
if [ "$STATUS" != "P" ]; then
    echo "    ⚠️  WARNING: Password status is '$STATUS'. It should be 'P'."
    echo "       (L=Locked, NP=No Password). If not P, reset it with: sudo passwd comzis"
else
    echo "    ✅ User has a valid password set."
fi

echo ""
echo "[3] Checking AppArmor Denials (Common Ubuntu Issue)..."
DENIALS=$(sudo dmesg | grep -i "audit" | grep -i "cockpit" | tail -n 5)
if [ -z "$DENIALS" ]; then
    echo "    ✅ No AppArmor denials found in kernel log."
else
    echo "    🚨 CRITICAL: Found AppArmor denials!"
    echo "$DENIALS"
    echo ""
    echo "    👉 FIX: Reinstall Cockpit to update profiles: sudo apt-get install --reinstall cockpit"
fi

echo ""
echo "[4] Checking Authentication Logs (Last 5 min)..."
sudo journalctl -u cockpit.service --since "5 minutes ago" --no-pager
echo "    --- /var/log/auth.log ---"
sudo grep -i "cockpit" /var/log/auth.log 2>/dev/null | tail -n 5 || echo "    (auth.log not found or empty)"

echo ""
echo "=========================================="
