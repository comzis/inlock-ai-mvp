# Server Update Schedule

**Date:** December 11, 2025  
**Server:** deploy.inlock.ai

## ✅ Completed Updates

### libpng16-16
- **Status**: ✅ Updated
- **Date**: December 11, 2025
- **Reboot Required**: No
- **Impact**: Low (library update only)

---

## 📅 Scheduled Updates

### Kernel Updates (Requires Reboot)
**Packages:**
- `5.15.0-164.159`:
- `linux-headers-generic`
- `linux-headers-virtual`
- `linux-image-virtual`
- `linux-virtual`

**Status**: ⏳ Scheduled for maintenance window

**Recommended Action:**
1. Schedule during low-traffic period
2. Ensure backups are current
3. Have console access ready
4. Reboot required after update

**Current Kernel**: `5.15.0-163-generic`  
**Target Kernel**: `5.15.0-164-generic`

---

## 🔄 Update Process

### Option 1: Using Update Scripts (Recommended)

**Update libpng16-16 (no reboot):**
```bash
sudo ./scripts/update-libpng.sh
```

**Update kernel packages:**
```bash
# Dry run (see what would be updated)
sudo ./scripts/update-kernel-packages.sh --dry-run

# Update without auto-reboot
sudo ./scripts/update-kernel-packages.sh

# Update and reboot automatically
sudo ./scripts/update-kernel-packages.sh --reboot
```

### Option 2: Via Coolify UI
1. Go to Server → Server Patching
2. Click "Update All Packages" (for kernel packages)
3. Reboot server after kernel update completes

### Option 3: Manual Command Line
```bash
sudo apt update
sudo apt upgrade linux-headers-generic linux-headers-virtual linux-image-virtual linux-virtual
sudo reboot
```

---

## ⚠️ Important Notes

- Kernel updates require server reboot
- Plan for 15-30 minute maintenance window
- Ensure all services restart correctly after reboot
- Monitor system after reboot

---

**Last Updated:** December 11, 2025
