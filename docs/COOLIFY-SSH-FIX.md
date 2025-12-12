# Coolify SSH Connection Fix

## Problem
Coolify container cannot connect to SSH on `100.83.222.69` (Tailscale IP) because Docker bridge networks cannot access Tailscale's virtual network interface.

**Error:** `ssh: connect to host 100.83.222.69 port 22: Connection refused`

## Solution Options

### Option 1: Use Public IP (Recommended)

1. **In Coolify UI**, change the server IP from `100.83.222.69` to `156.67.29.52` (public IP)

2. **Allow UFW to accept SSH from Docker networks:**
   ```bash
   sudo ufw allow from 172.16.0.0/12 to any port 22 proto tcp comment "Docker networks SSH"
   ```

3. **Validate connection in Coolify UI**

### Option 2: Use localhost (If Coolify manages same server)

Since Coolify is managing the server it's running on:

1. **In Coolify UI**, use `localhost` or `127.0.0.1` as the IP
2. **Ensure SSH accepts localhost connections** (should work by default)
3. **Validate connection**

### Option 3: Use Host Network Mode (Advanced)

⚠️ **Warning:** This may break Traefik routing. Only use if other options don't work.

Modify `compose/coolify.yml`:
```yaml
coolify:
  network_mode: host
  # Remove networks section
```

Then restart Coolify.

## Recommended Configuration

**For Coolify Server Setup:**
- **IP Address**: `156.67.29.52` (public IP) OR `localhost` (if managing same server)
- **User**: `root`
- **Port**: `22`
- **Private Key**: `deploy-inlock-ai-key`
- **Wildcard Domain**: `*.inlock.ai`

## Verification

After applying the fix, test from Coolify container:
```bash
cd /home/comzis/inlock-infra
docker compose -f compose/coolify.yml --env-file .env exec coolify nc -zv <IP> 22
```

Replace `<IP>` with the IP you're using (public IP or localhost).

