#!/bin/bash
# Setup Systemd Resource Limits Script
# Creates systemd slices for Docker service groups to apply system-level resource limits

set -e

echo "========================================="
echo "Systemd Resource Limits Setup"
echo "========================================="
echo ""
echo "This script creates systemd slices to limit resources for:"
echo "  - Docker service groups"
echo "  - Mailcow services"
echo "  - Monitoring services"
echo ""
echo "⚠️  Requires sudo privileges"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ This script must be run as root (use sudo)"
    exit 1
fi

SLICE_DIR="/etc/systemd/system"

# Docker slice
echo "Creating Docker slice..."
cat > "$SLICE_DIR/docker.slice" << 'EOF'
[Unit]
Description=Docker Service Group
Documentation=man:systemd.slice(5)

[Slice]
# Memory limit: 8GB (80% of 12GB system)
MemoryMax=8G
MemoryHigh=7G
# CPU limit: 4 cores (66% of 6 cores)
CPUQuota=400%
CPUWeight=100
EOF

# Mailcow slice
echo "Creating Mailcow slice..."
cat > "$SLICE_DIR/mailcow.slice" << 'EOF'
[Unit]
Description=Mailcow Service Group
Documentation=man:systemd.slice(5)

[Slice]
# Memory limit: 4GB
MemoryMax=4G
MemoryHigh=3.5G
# CPU limit: 2 cores
CPUQuota=200%
CPUWeight=50
EOF

# Monitoring slice
echo "Creating Monitoring slice..."
cat > "$SLICE_DIR/monitoring.slice" << 'EOF'
[Unit]
Description=Monitoring Service Group
Documentation=man:systemd.slice(5)

[Slice]
# Memory limit: 3GB
MemoryMax=3G
MemoryHigh=2.5G
# CPU limit: 2 cores
CPUQuota=200%
CPUWeight=30
EOF

# Reload systemd
echo ""
echo "Reloading systemd daemon..."
systemctl daemon-reload

echo ""
echo "✅ Systemd slices created successfully!"
echo ""
echo "Created slices:"
echo "  - docker.slice (8GB memory, 4 CPU cores)"
echo "  - mailcow.slice (4GB memory, 2 CPU cores)"
echo "  - monitoring.slice (3GB memory, 2 CPU cores)"
echo ""
echo "Note: These slices will be automatically applied to services"
echo "      running in their respective cgroups."
echo ""
echo "To verify slices:"
echo "  systemctl status docker.slice"
echo "  systemctl status mailcow.slice"
echo "  systemctl status monitoring.slice"
echo ""
