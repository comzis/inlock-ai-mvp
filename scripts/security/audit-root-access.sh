#!/bin/bash
#
# Audit root access configuration
# Checks SSH configuration, authorized_keys, and sudo usage patterns
# Generates security compliance report
#
# Usage: sudo ./scripts/security/audit-root-access.sh [OPTIONS]
# Options:
#   --output-dir <dir>    Output directory (default: archive/docs/reports/security)
#   --format <text|json>  Report format (default: text)

set -e

if [ "$EUID" -ne 0 ]; then 
   echo "ERROR: This script must be run as root (use sudo)"
   exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-$SCRIPT_DIR/archive/docs/reports/security}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
REPORT_FILE="$OUTPUT_DIR/root-access-audit-$TIMESTAMP.md"
FORMAT="${FORMAT:-text}"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --format)
            FORMAT="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

mkdir -p "$OUTPUT_DIR"

echo "=========================================="
echo "  Root Access Security Audit"
echo "=========================================="
echo ""
echo "Report will be saved to: $REPORT_FILE"
echo ""

# Initialize report
cat > "$REPORT_FILE" << EOF
# Root Access Security Audit

**Generated:** $(date '+%Y-%m-%d %H:%M:%S')  
**Hostname:** $(hostname)  
**Auditor:** Root Access Audit Script

---

## Executive Summary

EOF

# Audit SSH Configuration
echo "Auditing SSH configuration..."
SSH_CONFIG="/etc/ssh/sshd_config"

PERMIT_ROOT_LOGIN=$(grep -E "^PermitRootLogin" "$SSH_CONFIG" | awk '{print $2}' || echo "not set")
PASSWORD_AUTH=$(grep -E "^PasswordAuthentication" "$SSH_CONFIG" | awk '{print $2}' || echo "not set")
PUBKEY_AUTH=$(grep -E "^PubkeyAuthentication" "$SSH_CONFIG" | awk '{print $2}' || echo "not set")

cat >> "$REPORT_FILE" << EOF
### SSH Configuration

| Setting | Value | Status |
|---------|-------|--------|
| PermitRootLogin | $PERMIT_ROOT_LOGIN | $(if [ "$PERMIT_ROOT_LOGIN" = "no" ]; then echo "✅ Secure"; elif [ "$PERMIT_ROOT_LOGIN" = "prohibit-password" ]; then echo "⚠️ Key-only"; else echo "❌ Insecure"; fi) |
| PasswordAuthentication | $PASSWORD_AUTH | $(if [ "$PASSWORD_AUTH" = "no" ]; then echo "✅ Secure"; else echo "❌ Insecure"; fi) |
| PubkeyAuthentication | $PUBKEY_AUTH | $(if [ "$PUBKEY_AUTH" = "yes" ] || [ "$PUBKEY_AUTH" = "" ]; then echo "✅ Enabled"; else echo "❌ Disabled"; fi) |

EOF

# Audit root's authorized_keys
echo "Auditing root's authorized_keys..."
ROOT_SSH_DIR="/root/.ssh"
ROOT_AUTH_KEYS="$ROOT_SSH_DIR/authorized_keys"

cat >> "$REPORT_FILE" << EOF
### Root SSH Authorized Keys

EOF

if [ -f "$ROOT_AUTH_KEYS" ]; then
    KEY_COUNT=$(wc -l < "$ROOT_AUTH_KEYS")
    KEY_PERMS=$(stat -c "%a" "$ROOT_AUTH_KEYS" 2>/dev/null || echo "unknown")
    
    cat >> "$REPORT_FILE" << EOF
- **File exists:** ✅ Yes
- **Key count:** $KEY_COUNT
- **Permissions:** $KEY_PERMS $(if [ "$KEY_PERMS" = "600" ]; then echo "✅ Correct"; else echo "❌ Should be 600"; fi)
- **Directory permissions:** $(stat -c "%a" "$ROOT_SSH_DIR" 2>/dev/null || echo "unknown") $(if [ "$(stat -c "%a" "$ROOT_SSH_DIR" 2>/dev/null)" = "700" ]; then echo "✅ Correct"; else echo "❌ Should be 700"; fi)

**Authorized Keys:**
\`\`\`
$(cat "$ROOT_AUTH_KEYS" | sed 's/^/  /')
\`\`\`

EOF
else
    cat >> "$REPORT_FILE" << EOF
- **File exists:** ❌ No
- **Status:** ✅ Secure (root SSH not configured)

EOF
fi

# Audit firewall rules
echo "Auditing firewall rules..."
cat >> "$REPORT_FILE" << EOF
### Firewall Rules (UFW)

**SSH Access Rules:**
\`\`\`
$(ufw status numbered | grep -E "22" | sed 's/^/  /')
\`\`\`

EOF

# Analyze allowed sources
SSH_RULES=$(ufw status numbered | grep "22" | grep -oE "from [0-9./]+" | awk '{print $2}' || echo "")
TAILSCALE_FOUND=false
DOCKER_GATEWAY_FOUND=false
BROAD_DOCKER_FOUND=false

for rule in $SSH_RULES; do
    if [[ "$rule" =~ ^100\. ]]; then
        TAILSCALE_FOUND=true
    elif [ "$rule" = "172.18.0.1/32" ]; then
        DOCKER_GATEWAY_FOUND=true
    elif [[ "$rule" =~ ^172\.(16|18|20|23)\. ]]; then
        BROAD_DOCKER_FOUND=true
    fi
done

cat >> "$REPORT_FILE" << EOF
**Allowed Sources Analysis:**

- Tailscale network: $(if [ "$TAILSCALE_FOUND" = "true" ]; then echo "✅ Allowed"; else echo "❌ Not configured"; fi)
- Docker gateway IP (172.18.0.1/32): $(if [ "$DOCKER_GATEWAY_FOUND" = "true" ]; then echo "✅ Allowed (specific)"; else echo "⚠️ Not configured"; fi)
- Broad Docker networks: $(if [ "$BROAD_DOCKER_FOUND" = "true" ]; then echo "❌ Allowed (too broad)"; else echo "✅ Restricted"; fi)

EOF

# Audit sudo usage (if possible)
echo "Auditing sudo configuration..."
cat >> "$REPORT_FILE" << EOF
### Sudo Configuration

EOF

if [ -f /etc/sudoers.d/coolify-comzis ]; then
    cat >> "$REPORT_FILE" << EOF
- **Coolify sudoers file exists:** ✅ Yes
- **Content:**
\`\`\`
$(cat /etc/sudoers.d/coolify-comzis | sed 's/^/  /')
\`\`\`

EOF
else
    cat >> "$REPORT_FILE" << EOF
- **Coolify sudoers file:** ❌ Not found
- **Status:** Using password-protected sudo (more secure)

EOF
fi

# Check for NOPASSWD entries
NOPASSWD_COUNT=$(grep -r "NOPASSWD" /etc/sudoers /etc/sudoers.d/* 2>/dev/null | grep -v "^#" | wc -l || echo "0")
cat >> "$REPORT_FILE" << EOF
- **NOPASSWD entries:** $NOPASSWD_COUNT $(if [ "$NOPASSWD_COUNT" -eq 0 ]; then echo "✅ None (most secure)"; else echo "⚠️ Found (documented exception)"; fi)

EOF

# Recent root access (last 7 days)
echo "Analyzing recent root access..."
cat >> "$REPORT_FILE" << EOF
### Recent Root Access (Last 7 Days)

EOF

if [ -r /var/log/auth.log ]; then
    RECENT_ROOT=$(grep "sshd.*root" /var/log/auth.log | grep "$(date -d '7 days ago' '+%b %d')" || true)
    
    if [ -n "$RECENT_ROOT" ]; then
        ACCEPTED=$(echo "$RECENT_ROOT" | grep -c "Accepted" || echo "0")
        FAILED=$(echo "$RECENT_ROOT" | grep -c "Failed\|Invalid" || echo "0")
        
        cat >> "$REPORT_FILE" << EOF
- **Accepted connections:** $ACCEPTED
- **Failed attempts:** $FAILED

**Recent connections:**
\`\`\`
$(echo "$RECENT_ROOT" | tail -20 | sed 's/^/  /')
\`\`\`

EOF
    else
        cat >> "$REPORT_FILE" << EOF
- **No root SSH access in last 7 days** ✅

EOF
    fi
else
    cat >> "$REPORT_FILE" << EOF
- **Cannot read auth.log** (run with proper permissions)

EOF
fi

# Security Recommendations
cat >> "$REPORT_FILE" << EOF
---

## Security Recommendations

EOF

ISSUES_FOUND=0

# Check recommendations
if [ "$PERMIT_ROOT_LOGIN" != "no" ]; then
    cat >> "$REPORT_FILE" << EOF
1. ⚠️ **Root login is enabled** ($PERMIT_ROOT_LOGIN)
   - **Recommendation:** Consider disabling if not needed
   - **Impact:** Security risk if key is compromised
   - **Status:** $(if [ "$PERMIT_ROOT_LOGIN" = "prohibit-password" ]; then echo "Acceptable (key-only)"; else echo "High risk"; fi)

EOF
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

if [ "$PASSWORD_AUTH" != "no" ]; then
    cat >> "$REPORT_FILE" << EOF
2. ❌ **Password authentication enabled**
   - **Recommendation:** Disable password authentication
   - **Fix:** Set \`PasswordAuthentication no\` in sshd_config

EOF
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

if [ "$BROAD_DOCKER_FOUND" = "true" ]; then
    cat >> "$REPORT_FILE" << EOF
3. ⚠️ **Broad Docker network SSH access**
   - **Recommendation:** Restrict to gateway IP only (172.18.0.1/32)
   - **Fix:** Run \`sudo ./scripts/infrastructure/restrict-root-ssh-docker.sh\`

EOF
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

if [ "$KEY_PERMS" != "600" ] && [ -f "$ROOT_AUTH_KEYS" ]; then
    cat >> "$REPORT_FILE" << EOF
4. ⚠️ **Incorrect authorized_keys permissions** ($KEY_PERMS)
   - **Recommendation:** Set permissions to 600
   - **Fix:** \`chmod 600 /root/.ssh/authorized_keys\`

EOF
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

if [ "$ISSUES_FOUND" -eq 0 ]; then
    cat >> "$REPORT_FILE" << EOF
✅ **No major security issues found**

Current configuration appears secure:
- Root login properly restricted (key-only or disabled)
- Password authentication disabled
- Firewall rules appropriately configured
- Authorized keys permissions correct

EOF
else
    cat >> "$REPORT_FILE" << EOF
**Total issues found:** $ISSUES_FOUND

Please review and address the recommendations above.

EOF
fi

# Compliance Summary
cat >> "$REPORT_FILE" << EOF
---

## Compliance Summary

| Check | Status | Notes |
|-------|--------|-------|
| Root login disabled/restricted | $(if [ "$PERMIT_ROOT_LOGIN" = "no" ]; then echo "✅ Pass"; elif [ "$PERMIT_ROOT_LOGIN" = "prohibit-password" ]; then echo "⚠️ Pass (key-only)"; else echo "❌ Fail"; fi) | $PERMIT_ROOT_LOGIN |
| Password auth disabled | $(if [ "$PASSWORD_AUTH" = "no" ]; then echo "✅ Pass"; else echo "❌ Fail"; fi) | $PASSWORD_AUTH |
| Key-based auth enabled | $(if [ "$PUBKEY_AUTH" = "yes" ] || [ "$PUBKEY_AUTH" = "" ]; then echo "✅ Pass"; else echo "❌ Fail"; fi) | $PUBKEY_AUTH |
| Firewall configured | $(if [ -n "$SSH_RULES" ]; then echo "✅ Pass"; else echo "❌ Fail"; fi) | $(echo "$SSH_RULES" | wc -w) rule(s) |
| Broad Docker access restricted | $(if [ "$BROAD_DOCKER_FOUND" = "false" ]; then echo "✅ Pass"; else echo "❌ Fail"; fi) | $(if [ "$BROAD_DOCKER_FOUND" = "true" ]; then echo "Too broad"; else echo "Restricted"; fi) |
| Authorized keys secure | $(if [ -f "$ROOT_AUTH_KEYS" ] && [ "$KEY_PERMS" = "600" ]; then echo "✅ Pass"; elif [ ! -f "$ROOT_AUTH_KEYS" ]; then echo "✅ Pass (not configured)"; else echo "⚠️ Warning"; fi) | Permissions: $KEY_PERMS |

---

## Next Steps

1. Review this audit report
2. Address any recommendations
3. Re-run audit after changes: \`sudo ./scripts/security/audit-root-access.sh\`
4. Schedule regular audits (quarterly recommended)

---

**Generated by:** \`scripts/security/audit-root-access.sh\`  
**Audit Type:** Root Access Security Compliance  
**See Also:** [Root Access Security Status](../../ROOT-ACCESS-SECURITY-STATUS.md)
EOF

echo "✓ Audit complete"
echo "Report saved to: $REPORT_FILE"
echo ""

# Display summary
echo "=========================================="
echo "  Audit Summary"
echo "=========================================="
echo ""
echo "SSH Configuration:"
echo "  PermitRootLogin: $PERMIT_ROOT_LOGIN"
echo "  PasswordAuthentication: $PASSWORD_AUTH"
echo ""
echo "Root SSH Keys:"
if [ -f "$ROOT_AUTH_KEYS" ]; then
    echo "  ✅ Configured ($KEY_COUNT key(s))"
else
    echo "  ❌ Not configured"
fi
echo ""
echo "Firewall:"
echo "  SSH rules: $(echo "$SSH_RULES" | wc -w)"
echo "  Tailscale: $TAILSCALE_FOUND"
echo "  Docker gateway: $DOCKER_GATEWAY_FOUND"
echo "  Broad Docker: $BROAD_DOCKER_FOUND"
echo ""
echo "Issues found: $ISSUES_FOUND"
echo ""
echo "Full report: $REPORT_FILE"




