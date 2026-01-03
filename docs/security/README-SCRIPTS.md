# Security Scripts Reference Guide

## SSH Firewall Scripts

### Primary Scripts (Use These)

#### 1. `fix-ssh-firewall-access.sh` ⭐ **RECOMMENDED**
**Purpose**: Comprehensive fix for Tailscale-only SSH access

**Features**:
- Enables UFW if inactive
- Removes all existing SSH rules (fixes loop bug)
- Adds Tailscale subnet rule (100.64.0.0/10)
- Verifies SSH configuration (public key auth)
- Verifies MacBook key access

**When to use**:
- Production deployment
- When you want Tailscale-only SSH (complies with `.cursorrules-security`)
- After configuring Cursor to use Tailscale

**Usage**:
```bash
sudo ./scripts/security/fix-ssh-firewall-access.sh
```

---

#### 2. `enable-firewall-with-ssh-access.sh` ⭐ **TEMPORARY SOLUTION**
**Purpose**: Enable firewall with both Tailscale and public IP access

**Features**:
- Enables UFW firewall
- Adds Tailscale subnet rule
- Auto-detects and adds public IP rule (for Cursor)
- Configures other required ports

**When to use**:
- Temporary solution when Cursor needs public IP access
- Before configuring Cursor to use Tailscale
- Emergency access restoration

**Usage**:
```bash
sudo ./scripts/security/enable-firewall-with-ssh-access.sh
```

**Note**: Public IP rule is marked as temporary. Remove after configuring Cursor.

---

### Alternative Scripts

#### 3. `fix-firewall-ssh-tailscale.sh`
**Purpose**: Simpler alternative to fix Tailscale SSH rules

**Features**:
- Updates SSH rules to use Tailscale subnet
- Simpler implementation (no SSH config verification)

**When to use**:
- Quick fix when you only need firewall rule update
- Alternative to `fix-ssh-firewall-access.sh`

**Usage**:
```bash
sudo ./scripts/security/fix-firewall-ssh-tailscale.sh
```

---

#### 4. `emergency-allow-ssh-public.sh`
**Purpose**: Emergency script to temporarily allow SSH from public IP

**Features**:
- Auto-detects public IP from current connections
- Adds temporary SSH rule
- Quick recovery when locked out

**When to use**:
- Emergency recovery when locked out
- Quick temporary access restoration

**Usage**:
```bash
sudo ./scripts/security/emergency-allow-ssh-public.sh
```

---

### Utility Scripts

#### 5. `enable-ufw-complete.sh`
**Purpose**: Complete UFW setup with all required rules

**Features**:
- Enables UFW
- Sets default policies
- Adds all required rules (SSH, HTTP, HTTPS, Tailscale)
- **Fixed**: Infinite loop bug in SSH rule removal

**When to use**:
- Initial firewall setup
- Complete firewall reconfiguration

**Usage**:
```bash
sudo ./scripts/security/enable-ufw-complete.sh
```

---

#### 6. `verify-ssh-restrictions.sh`
**Purpose**: Verify SSH security configuration

**Features**:
- Checks UFW status and SSH rules
- Verifies fail2ban SSH jail
- Checks SSH configuration
- Verifies Tailscale status

**When to use**:
- After making SSH/firewall changes
- Security audits
- Troubleshooting SSH access

**Usage**:
```bash
sudo ./scripts/security/verify-ssh-restrictions.sh
```

---

## Script Comparison

| Script | Complexity | SSH Config Check | MacBook Key Check | Public IP Support | Use Case |
|--------|-----------|------------------|------------------|-------------------|----------|
| `fix-ssh-firewall-access.sh` | High | ✅ | ✅ | ❌ | Production (Tailscale-only) |
| `enable-firewall-with-ssh-access.sh` | Medium | ❌ | ❌ | ✅ | Temporary (Both) |
| `fix-firewall-ssh-tailscale.sh` | Low | ❌ | ❌ | ❌ | Quick fix (Tailscale-only) |
| `emergency-allow-ssh-public.sh` | Low | ❌ | ❌ | ✅ | Emergency recovery |

## Recommended Workflow

### For Production (Tailscale-only)
```bash
# 1. Configure Cursor to use Tailscale (see CONFIGURE-CURSOR-TAILSCALE.md)
# 2. Fix firewall for Tailscale-only
sudo ./scripts/security/fix-ssh-firewall-access.sh
# 3. Verify
sudo ./scripts/security/verify-ssh-restrictions.sh
```

### For Temporary Access (Both Tailscale and Public IP)
```bash
# 1. Enable firewall with both access methods
sudo ./scripts/security/enable-firewall-with-ssh-access.sh
# 2. Later: Configure Cursor to use Tailscale
# 3. Then: Remove public IP rule and use fix-ssh-firewall-access.sh
```

### For Emergency Recovery
```bash
# 1. Emergency access
sudo ./scripts/security/emergency-allow-ssh-public.sh
# 2. Then: Use appropriate script above
```

## Related Documentation

- `docs/security/CONFIGURE-CURSOR-TAILSCALE.md` - Configure Cursor to use Tailscale
- `docs/security/CURSOR-SSH-ACCESS-SETUP.md` - General Cursor SSH setup
- `docs/security/SSH-FIREWALL-FIX-2026-01-03.md` - Today's fix details
- `docs/security/FIREWALL-SSH-TAILSCALE-FIX.md` - Tailscale subnet explanation
- `.cursorrules-security` - Security rules

