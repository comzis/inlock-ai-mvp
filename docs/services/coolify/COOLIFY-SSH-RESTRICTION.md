# Coolify SSH Access Restriction

**Date:** 2025-12-28  
**Status:** Enhanced Security Configuration

---

## Overview

Root SSH access for Coolify has been restricted from all Docker networks (172.16.0.0/12) to only the specific Docker gateway IP (172.18.0.1/32). This improves security while maintaining Coolify functionality.

---

## Current Configuration

### SSH Access Rules

Root SSH access is now restricted to:

1. **Tailscale Network:** `100.64.0.0/10`
   - External access via VPN
   - Includes server and client Tailscale IPs

2. **Docker Gateway IP:** `172.18.0.1/32` (specific IP only)
   - Internal access for Coolify container
   - Only the gateway IP, not entire Docker network ranges

### What Changed

**Before:**
- Root SSH accessible from all Docker networks (172.16.0.0/12)
- Includes: 172.18.0.0/16, 172.23.0.0/16, 172.16.0.0/12 (broad range)

**After:**
- Root SSH accessible only from Docker gateway IP (172.18.0.1/32)
- Removed broad Docker network ranges
- More restrictive access control

---

## Why This Restriction

### Security Benefits

1. **Reduced Attack Surface:**
   - Fewer IP addresses can access root SSH
   - Only the gateway IP, not entire network ranges

2. **Better Access Control:**
   - More granular firewall rules
   - Easier to audit and monitor

3. **Defense in Depth:**
   - Additional security layer
   - Limits lateral movement if container is compromised

### Why It Still Works

Coolify connects from its container to the host using the Docker gateway IP (`172.18.0.1`), not a container IP. This means:

- ✅ Coolify's connection path is unchanged
- ✅ Only the specific gateway IP is needed
- ✅ No functionality impact

---

## Applying the Restriction

### Automatic (Recommended)

Run the restriction script:

```bash
sudo ./scripts/infrastructure/restrict-root-ssh-docker.sh
```

This script will:
1. Backup current UFW rules
2. Remove broad Docker network SSH rules
3. Add specific gateway IP rule
4. Preserve Tailscale access
5. Verify configuration

### Manual

If you prefer manual configuration:

```bash
# Backup current rules
sudo ufw status numbered > /root/ufw-backup-$(date +%Y%m%d).txt

# Remove broad Docker network rules
sudo ufw status numbered | grep "172" | grep "22" | awk '{print $1}' | sed 's/\[//;s/\]//' | sort -rn | while read num; do
    echo "y" | sudo ufw delete "$num"
done

# Add specific gateway IP rule
sudo ufw allow from 172.18.0.1/32 to any port 22 proto tcp comment 'SSH - Docker gateway (Coolify)'

# Reload firewall
sudo ufw reload
```

---

## Verification

### Check UFW Rules

```bash
sudo ufw status numbered | grep "22"
```

Should show:
- `100.64.0.0/10` (Tailscale network)
- `172.18.0.1/32` (Docker gateway - specific IP)
- Should NOT show: `172.16.0.0/12` or broad Docker network ranges

### Test Coolify Connection

1. **In Coolify UI:**
   - Go to Server configuration
   - Click "Validate Server"
   - Should succeed ✅

2. **From Container:**
   ```bash
   docker exec services-coolify-1 ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@172.18.0.1 "echo test"
   ```
   Should output: `test`

### Monitor SSH Access

```bash
# Watch for root SSH connections
sudo tail -f /var/log/auth.log | grep "root"
```

Only connections from:
- Tailscale IPs (100.x.x.x)
- Docker gateway (172.18.0.1)

---

## Troubleshooting

### Coolify Connection Fails

**Symptom:** "Server is not reachable" in Coolify UI

**Possible Causes:**
1. Gateway IP changed (Docker network recreated)
2. Firewall rule not applied correctly
3. Wrong IP configured in Coolify

**Fix:**
1. Check Docker gateway IP:
   ```bash
   docker network inspect mgmt | grep Gateway
   ```

2. Verify UFW rule:
   ```bash
   sudo ufw status | grep 172.18.0.1
   ```

3. Update Coolify server configuration with correct gateway IP

4. If gateway IP changed, update UFW rule:
   ```bash
   sudo ufw delete <old-rule-number>
   sudo ufw allow from <new-gateway-ip>/32 to any port 22 proto tcp comment 'SSH - Docker gateway (Coolify)'
   ```

### Connection from Container Fails

**Symptom:** Cannot SSH from container to host

**Fix:**
1. Ensure container is on the `mgmt` network (or network with gateway 172.18.0.1)
2. Use gateway IP, not container IP
3. Verify firewall rule exists:
   ```bash
   sudo ufw status | grep 172.18.0.1
   ```

### Too Restrictive

If you need to allow additional Docker networks:

```bash
# Add specific network (not recommended)
sudo ufw allow from 172.23.0.0/16 to any port 22 proto tcp comment 'SSH - Docker coolify network'

# Or restore from backup (if needed)
sudo ufw status numbered
# Review backup and restore manually
```

---

## Rollback

If you need to revert to broad Docker network access:

```bash
# Remove specific gateway rule
sudo ufw status numbered | grep "172.18.0.1" | awk '{print $1}' | sed 's/\[//;s/\]//' | sort -rn | while read num; do
    echo "y" | sudo ufw delete "$num"
done

# Add back broad Docker network rules
sudo ufw allow from 172.18.0.0/16 to any port 22 proto tcp comment 'SSH - Docker mgmt network'
sudo ufw allow from 172.23.0.0/16 to any port 22 proto tcp comment 'SSH - Docker coolify network'
sudo ufw allow from 172.16.0.0/12 to any port 22 proto tcp comment 'SSH - Docker networks (broad)'

# Reload
sudo ufw reload
```

**Note:** Rollback reduces security. Only use if necessary.

---

## Security Impact

### Before Restriction

| Access Source | Allowed | Security Risk |
|---------------|---------|---------------|
| Tailscale (100.64.0.0/10) | ✅ Yes | Low (VPN required) |
| Docker networks (172.16.0.0/12) | ⚠️ Yes | Medium (all Docker networks) |
| Internet | ❌ No | N/A (firewall blocks) |

### After Restriction

| Access Source | Allowed | Security Risk |
|---------------|---------|---------------|
| Tailscale (100.64.0.0/10) | ✅ Yes | Low (VPN required) |
| Docker gateway (172.18.0.1/32) | ✅ Yes | Low (specific IP only) |
| Other Docker networks | ❌ No | N/A (blocked) |
| Internet | ❌ No | N/A (firewall blocks) |

**Improvement:** Reduced from entire Docker network ranges to single gateway IP.

---

## Related Documentation

- [Root Access Security Status](../../../ROOT-ACCESS-SECURITY-STATUS.md)
- [Coolify IP Address Guide](./COOLIFY-IP-ADDRESS-GUIDE.md)
- [Coolify Firewall Fix](./COOLIFY-FIREWALL-FIX.md)
- [Firewall Configuration Guide](../../../security/FIREWALL-SECURITY-STATUS-2025-12-25.md)

---

**Last Updated:** 2025-12-28


