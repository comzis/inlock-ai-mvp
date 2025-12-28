# Enable Root Access for Coolify

**Date:** 2025-12-28  
**Status:** Recommended by Coolify

---

## Why Root?

Coolify is **designed for root access**. While non-root users are supported experimentally, they require `NOPASSWD: ALL` (full passwordless sudo) and users report issues. Root is the recommended and most reliable option.

---

## Security Measures

With root enabled, we maintain security through:

- ✅ **Key-only authentication** (no passwords)
- ✅ **Tailscale network** (internal access only)
- ✅ **Firewall restrictions** (SSH only from Docker networks)
- ✅ **SSH key required** (public key authentication)

---

## Enable Root Access

**Run this command:**

```bash
sudo /home/comzis/projects/inlock-ai-mvp/scripts/infrastructure/enable-root-for-coolify.sh
```

### What the Script Does

1. ✅ Enables `PermitRootLogin prohibit-password` (key-only)
2. ✅ Ensures password authentication is disabled
3. ✅ Creates `/root/.ssh/authorized_keys` with your SSH key
4. ✅ Validates SSH configuration
5. ✅ Restarts SSH service

---

## Coolify Configuration

After running the script, configure Coolify with:

| Field | Value |
|-------|-------|
| **Name** | `deploy-inlock-ai` |
| **IP Address/Domain** | `172.18.0.1` ⚠️ Docker gateway IP |
| **Port** | `22` |
| **User** | `root` |
| **Private Key** | `inlock-ai-infrastructure` (or `deploy-inlock-ai-key`) |
| **Use as build server** | ✓ Checked |

**Important:** Use `172.18.0.1` (Docker gateway), not Tailscale IP, when connecting from Coolify container.

---

## Verification

After enabling root, test SSH:

```bash
# Should work without password (key-only)
ssh -i ~/.ssh/keys/deploy-inlock-ai-key root@172.18.0.1 "echo 'Root access works'"
```

Then in Coolify UI, click "Validate & configure" - it should succeed! ✅

---

## Reverting (If Needed)

To disable root access later:

```bash
sudo /home/comzis/projects/inlock-ai-mvp/scripts/infrastructure/disable-root-access.sh
```

---

**Ready to proceed?** Run the enable script above! 🚀

