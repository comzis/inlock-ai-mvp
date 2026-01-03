# Cursor SSH Access Setup Guide

## Problem

Cursor connects to the server via public IP (`84.115.235.126`), but the firewall is configured to only allow SSH from Tailscale subnet (`100.64.0.0/10`). This causes SSH access to be blocked when the firewall is enabled.

## Current Situation

- **Firewall**: Disabled (for emergency access)
- **Cursor Connection**: Via public IP `84.115.235.126`
- **Tailscale**: Available and working (MacBook IP: `100.96.110.8`)

## Solutions

### Option 1: Enable Firewall with Both Tailscale and Public IP (Quick Fix)

This allows you to keep the firewall enabled while maintaining Cursor access:

```bash
cd /home/comzis/inlock
sudo ./scripts/security/enable-firewall-with-ssh-access.sh
```

This script will:
- ✅ Enable UFW firewall
- ✅ Allow SSH from Tailscale subnet (100.64.0.0/10)
- ✅ Allow SSH from your public IP (for Cursor)
- ✅ Configure other required ports

**Note**: The public IP rule is marked as temporary. For better security, use Option 2.

### Option 2: Configure Cursor to Use Tailscale (Recommended)

This is the most secure solution and complies with `.cursorrules-security`:

#### Step 1: Install Tailscale on Your Machine (if not already installed)

**macOS:**
```bash
brew install tailscale
# Or download from: https://tailscale.com/download
```

**Windows:**
- Download from: https://tailscale.com/download

**Linux:**
```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

#### Step 2: Connect to Tailscale

```bash
sudo tailscale up
```

Follow the authentication flow in your browser.

#### Step 3: Configure Cursor to Use Tailscale

**Option A: Use Tailscale IP in SSH Config**

Edit `~/.ssh/config`:
```
Host inlock-server
    HostName 100.83.222.69
    User comzis
    IdentityFile ~/.ssh/your_key
```

Then connect with:
```bash
ssh inlock-server
```

**Option B: Configure Cursor Remote SSH**

In Cursor settings:
1. Go to Remote SSH settings
2. Add host: `comzis@100.83.222.69`
3. Use Tailscale IP instead of public IP

#### Step 4: Remove Public IP Rule

After confirming Cursor works via Tailscale:

```bash
sudo ufw delete allow from 84.115.235.126 to any port 22
```

### Option 3: Manual Firewall Configuration

If you prefer to configure manually:

```bash
# Enable firewall
sudo ufw --force enable

# Set default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow Tailscale subnet
sudo ufw allow from 100.64.0.0/10 to any port 22 proto tcp comment 'SSH via Tailscale'

# Allow public IP (temporary)
sudo ufw allow from 84.115.235.126 to any port 22 proto tcp comment 'SSH - Cursor (TEMP)'

# Allow other required ports
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'
sudo ufw allow 41641/udp comment 'Tailscale'
```

## Security Considerations

According to `.cursorrules-security`:
- **Port 22 → ONLY 100.64.0.0/10 (Tailscale)**

The public IP rule is a temporary workaround. For full compliance:
1. Configure Cursor to use Tailscale (Option 2)
2. Remove the public IP rule
3. Keep firewall enabled with Tailscale-only SSH access

## Verification

After enabling the firewall, test access:

```bash
# Test from Tailscale
ssh comzis@100.83.222.69

# Test from public IP (if rule added)
ssh comzis@156.67.29.52
```

## Troubleshooting

### Can't Connect After Enabling Firewall

1. Check firewall status:
   ```bash
   sudo ufw status numbered
   ```

2. Verify SSH rules:
   ```bash
   sudo ufw status numbered | grep -E "22|ssh"
   ```

3. Check if your IP is in the rules:
   ```bash
   # Your current public IP
   curl -s ifconfig.me
   
   # Check if it's in firewall rules
   sudo ufw status numbered | grep "$(curl -s ifconfig.me)"
   ```

### Tailscale Not Working

1. Check Tailscale status:
   ```bash
   tailscale status
   ```

2. Verify Tailscale IP:
   ```bash
   tailscale ip -4
   ```

3. Test Tailscale connectivity:
   ```bash
   ping 100.83.222.69
   ```

## Next Steps

1. **Immediate**: Run `enable-firewall-with-ssh-access.sh` to restore firewall with access
2. **Short-term**: Configure Cursor to use Tailscale (Option 2)
3. **Long-term**: Remove public IP rule and use Tailscale-only access

## Related Files

- `scripts/security/enable-firewall-with-ssh-access.sh` - Enable firewall with both access methods
- `scripts/security/fix-ssh-firewall-access.sh` - Fix firewall for Tailscale-only access
- `.cursorrules-security` - Security rules (requires Tailscale-only SSH)

