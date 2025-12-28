# Coolify Firewall Fix - Docker Network SSH Access

**Issue:** Coolify container cannot connect to SSH on `100.83.222.69` (Connection refused)

**Date:** 2025-12-28

---

## Problem

When Coolify connects from inside a Docker container to the Tailscale IP (`100.83.222.69`), the connection is blocked because:

1. The firewall only allows SSH from specific Tailscale IPs
2. The Docker container's source IP is a Docker network IP (e.g., `172.23.0.5`), not a Tailscale IP
3. The firewall sees the Docker network IP and blocks the connection

---

## Solution

Allow Docker networks (internal to the host) to connect to SSH port 22. This is secure because:

- Docker networks (`172.x.x.x`) are internal to the host
- External connections still require Tailscale IPs
- Only containers on the same host can use this access

---

## Fix: Add Firewall Rules

Run the firewall fix script:

```bash
sudo /home/comzis/projects/inlock-ai-mvp/scripts/troubleshooting/fix-coolify-ssh-firewall.sh
```

**Or manually add the rules:**

```bash
# Allow SSH from Docker mgmt network (where Coolify connects from)
sudo ufw allow from 172.18.0.0/16 to any port 22 proto tcp comment 'SSH - Docker mgmt network'

# Allow SSH from Docker coolify network
sudo ufw allow from 172.23.0.0/16 to any port 22 proto tcp comment 'SSH - Docker coolify network'

# Allow SSH from all Docker networks (catch-all)
sudo ufw allow from 172.16.0.0/12 to any port 22 proto tcp comment 'SSH - Docker networks (broad)'

# Reload firewall
sudo ufw reload
```

---

## Verification

After adding the rules, test from the Coolify container:

```bash
# Test SSH port connectivity
docker exec services-coolify-1 nc -zv 100.83.222.69 22

# Should output: "100.83.222.69 (100.83.222.69:22) open"
```

---

## Security Notes

### Why This Is Secure

1. **Internal Networks Only:** Docker networks (`172.x.x.x`) are internal to the host
2. **External Still Restricted:** External connections still require Tailscale IPs
3. **Container Isolation:** Only containers on the same host can connect
4. **Network Separation:** Docker networks are separate from public networks

### Current Firewall Rules

- ✅ SSH from Tailscale IPs: Allowed (e.g., `100.83.222.69/32`, `100.96.110.8/32`)
- ✅ SSH from Docker networks: Allowed (for Coolify)
- ✅ SSH from external/public IPs: Blocked (unless Tailscale)

---

## Coolify Configuration

After fixing the firewall, configure Coolify with:

- **User:** `comzis`
- **IP Address:** `100.83.222.69` (Tailscale IP)
- **Port:** `22`
- **SSH Key:** `deploy-inlock-ai-key`

---

## Related Documentation

- [Coolify Sudo Configuration](./COOLIFY-SUDO-CONFIGURATION.md)
- [Coolify Server Setup Guide](../guides/COOLIFY-SERVER-SETUP.md)

---

**Last Updated:** 2025-12-28

