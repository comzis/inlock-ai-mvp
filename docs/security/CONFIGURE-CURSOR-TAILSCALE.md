# Configure Cursor to Use Tailscale

## Why Cursor is Not Using Tailscale

Cursor is currently connecting via **public IP** (`84.115.235.126` / `156.67.29.52`) instead of Tailscale because:

1. **Cursor Remote SSH is configured with the public IP** - When you set up the remote connection, you likely used the server's public IP address
2. **Cursor doesn't automatically detect Tailscale** - It uses whatever hostname/IP you configured
3. **SSH config may point to public IP** - Your `~/.ssh/config` might have the public IP configured

## Current Situation

- ✅ **Tailscale is working**: MacBook IP `100.96.110.8` is active
- ✅ **Server Tailscale IP**: `100.83.222.69`
- ❌ **Cursor is using**: Public IP `84.115.235.126` / `156.67.29.52`

## Solution: Configure Cursor to Use Tailscale

### Option 1: Update Cursor Remote SSH Settings (Recommended)

1. **Open Cursor Settings**:
   - Press `Cmd+,` (Mac) or `Ctrl+,` (Windows/Linux)
   - Search for "Remote SSH"

2. **Edit SSH Config**:
   - Click "Open SSH Configuration File"
   - Or manually edit: `~/.ssh/config`

3. **Add/Update Server Entry**:
   ```
   Host inlock-server
       HostName 100.83.222.69
       User comzis
       IdentityFile ~/.ssh/id_ed25519
       # Use Tailscale IP instead of public IP
   ```

4. **Update Cursor Connection**:
   - In Cursor, use: `inlock-server` or `comzis@100.83.222.69`
   - Instead of: `comzis@156.67.29.52`

### Option 2: Update Existing SSH Config Entry

If you already have an entry for the server:

1. **Find your SSH config**:
   ```bash
   cat ~/.ssh/config
   ```

2. **Update the HostName**:
   ```
   Host inlock-server
       HostName 100.83.222.69  # Change from 156.67.29.52 to Tailscale IP
       User comzis
       IdentityFile ~/.ssh/id_ed25519
   ```

3. **Reconnect in Cursor**:
   - Disconnect current session
   - Connect using the updated host

### Option 3: Use Tailscale MagicDNS (Easiest)

If Tailscale MagicDNS is enabled, you can use the hostname:

1. **Check MagicDNS**:
   ```bash
   tailscale status
   # Look for: vmi2953354-1 (server hostname)
   ```

2. **Use hostname in SSH config**:
   ```
   Host inlock-server
       HostName vmi2953354-1
       User comzis
       IdentityFile ~/.ssh/id_ed25519
   ```

## Step-by-Step: Configure Cursor Remote SSH

### Step 1: Verify Tailscale is Running on Your Machine

```bash
# Check Tailscale status
tailscale status

# Should show:
# 100.96.110.8   comzis    macOS    active
# 100.83.222.69  vmi2953354-1    linux    -
```

### Step 2: Test Tailscale Connection

Before configuring Cursor, test that Tailscale works:

```bash
# Test ping
ping 100.83.222.69

# Test SSH
ssh comzis@100.83.222.69
```

If this works, Tailscale is properly configured.

### Step 3: Update Cursor SSH Config

**On macOS/Linux:**
```bash
# Edit SSH config
nano ~/.ssh/config
# or
code ~/.ssh/config
```

**Add or update:**
```
Host inlock-server
    HostName 100.83.222.69
    User comzis
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

**On Windows:**
- Path: `C:\Users\YourUsername\.ssh\config`
- Use the same format as above

### Step 4: Reconnect in Cursor

1. **Disconnect current session** (if connected)
2. **Open Command Palette**: `Cmd+Shift+P` (Mac) or `Ctrl+Shift+P` (Windows/Linux)
3. **Type**: "Remote-SSH: Connect to Host"
4. **Select**: `inlock-server` (or `comzis@100.83.222.69`)

### Step 5: Verify Connection Uses Tailscale

After connecting, verify in the server:

```bash
# On the server, check current connections
who

# Should show Tailscale IP (100.96.110.8) instead of public IP
```

## Benefits of Using Tailscale

1. **Security**: SSH only accessible via Tailscale (no public IP exposure)
2. **Compliance**: Matches `.cursorrules-security` requirements
3. **Performance**: Direct peer-to-peer connection (often faster)
4. **Reliability**: Works even if public IP changes
5. **Firewall**: Can keep firewall enabled with Tailscale-only rules

## Troubleshooting

### Cursor Still Connects via Public IP

1. **Check SSH config**:
   ```bash
   cat ~/.ssh/config | grep -A 5 inlock
   ```

2. **Clear Cursor SSH cache**:
   - Command Palette → "Remote-SSH: Kill VS Code Server on Host"
   - Reconnect

3. **Check Cursor Remote SSH settings**:
   - Settings → Remote SSH → Config File
   - Ensure it points to `~/.ssh/config`

### Tailscale Connection Fails

1. **Verify Tailscale is running**:
   ```bash
   tailscale status
   ```

2. **Check Tailscale IP**:
   ```bash
   tailscale ip -4
   # Should show: 100.96.110.8 (or similar)
   ```

3. **Test connectivity**:
   ```bash
   ping 100.83.222.69
   ssh -vvv comzis@100.83.222.69
   ```

4. **Restart Tailscale**:
   ```bash
   sudo tailscale down
   sudo tailscale up
   ```

### Firewall Blocks Connection

If firewall is enabled and only allows Tailscale:

1. **Check firewall rules**:
   ```bash
   sudo ufw status numbered | grep 22
   ```

2. **Should show**:
   ```
   [ 4] 22/tcp  ALLOW IN  100.64.0.0/10  # SSH via Tailscale
   ```

3. **If missing**, run:
   ```bash
   sudo ./scripts/security/fix-ssh-firewall-access.sh
   ```

## Verification Checklist

After configuration, verify:

- [ ] Tailscale is running on your machine
- [ ] SSH config uses Tailscale IP (`100.83.222.69`)
- [ ] Can connect via terminal: `ssh comzis@100.83.222.69`
- [ ] Cursor connects using Tailscale IP
- [ ] Server shows Tailscale IP in `who` output
- [ ] Firewall is enabled with Tailscale-only SSH rule

## After Configuration

Once Cursor is using Tailscale:

1. **Remove public IP SSH rule** (if added temporarily):
   ```bash
   sudo ufw delete allow from 84.115.235.126 to any port 22
   ```

2. **Verify firewall is secure**:
   ```bash
   sudo ufw status numbered | grep 22
   # Should only show: 100.64.0.0/10
   ```

3. **Test access**:
   - Cursor should connect via Tailscale
   - Public IP SSH should be blocked (if rule removed)

## Related Files

- `docs/security/CURSOR-SSH-ACCESS-SETUP.md` - General Cursor SSH setup
- `scripts/security/fix-ssh-firewall-access.sh` - Configure firewall for Tailscale-only
- `.cursorrules-security` - Security rules (requires Tailscale-only SSH)

