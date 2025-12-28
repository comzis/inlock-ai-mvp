#!/bin/bash
#
# Install Trivy vulnerability scanner
# Downloads and installs Trivy binary for container and filesystem scanning
#
# Usage: sudo ./scripts/security/install-trivy.sh

set -e

if [ "$EUID" -ne 0 ]; then 
   echo "ERROR: This script must be run as root (use sudo)"
   exit 1
fi

echo "=========================================="
echo "  Installing Trivy Vulnerability Scanner"
echo "=========================================="
echo ""

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) TRIVY_ARCH="64bit" ;;
    aarch64|arm64) TRIVY_ARCH="ARM64" ;;
    *)
        echo "ERROR: Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Detect OS
OS=$(uname -s)
if [ "$OS" != "Linux" ]; then
    echo "ERROR: This script is for Linux only"
    exit 1
fi

# Get latest version from GitHub API
echo "Fetching latest Trivy version..."
LATEST_VERSION=$(curl -s https://api.github.com/repos/aquasecurity/trivy/releases/latest | grep '"tag_name":' | head -1 | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')

if [ -z "$LATEST_VERSION" ] || [ "$LATEST_VERSION" = "" ]; then
    echo "ERROR: Failed to fetch latest version, using fallback version 0.68.2"
    LATEST_VERSION="0.68.2"
else
    echo "Latest version: $LATEST_VERSION"
fi

# Construct download URL - format: trivy_{VERSION}_Linux-64bit.tar.gz
TRIVY_URL="https://github.com/aquasecurity/trivy/releases/download/v${LATEST_VERSION}/trivy_${LATEST_VERSION}_${OS}-${TRIVY_ARCH}.tar.gz"
INSTALL_DIR="/usr/local/bin"
TEMP_DIR="/tmp/trivy-install-$$"

echo "Architecture: $ARCH -> $TRIVY_ARCH"
echo "OS: $OS"
echo "Install directory: $INSTALL_DIR"
echo "Download URL: $TRIVY_URL"
echo ""

# Create temporary directory
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Download Trivy
echo "Downloading Trivy..."
if command -v curl >/dev/null 2>&1; then
    curl -L -o trivy.tar.gz "$TRIVY_URL" || {
        echo "ERROR: Failed to download Trivy"
        exit 1
    }
elif command -v wget >/dev/null 2>&1; then
    wget -O trivy.tar.gz "$TRIVY_URL" || {
        echo "ERROR: Failed to download Trivy"
        exit 1
    }
else
    echo "ERROR: Neither curl nor wget is available"
    exit 1
fi

# Extract
echo "Extracting Trivy..."
tar -xzf trivy.tar.gz

# Install
echo "Installing Trivy to $INSTALL_DIR..."
if [ -f "trivy" ]; then
    cp trivy "$INSTALL_DIR/trivy"
    chmod +x "$INSTALL_DIR/trivy"
    chown root:root "$INSTALL_DIR/trivy"
    echo "✓ Trivy installed successfully"
else
    echo "ERROR: trivy binary not found in archive"
    exit 1
fi

# Cleanup
cd /
rm -rf "$TEMP_DIR"

# Verify installation
echo ""
echo "Verifying installation..."
if command -v trivy >/dev/null 2>&1; then
    TRIVY_VER=$(trivy --version 2>&1 | head -1)
    echo "✓ $TRIVY_VER"
else
    echo "ERROR: Trivy not found in PATH"
    exit 1
fi

# Initialize Trivy database
echo ""
echo "Initializing Trivy vulnerability database..."
trivy image --download-db-only || {
    echo "WARNING: Failed to download vulnerability database"
    echo "You may need to run 'trivy image --download-db-only' manually"
}

echo ""
echo "=========================================="
echo "  Installation Complete"
echo "=========================================="
echo ""
echo "Trivy is now available at: $INSTALL_DIR/trivy"
echo ""
echo "Test the installation:"
echo "  trivy --version"
echo "  trivy image alpine:latest"
echo ""
echo "Next steps:"
echo "  1. Run vulnerability scans using scripts/security/scan-*.sh"
echo "  2. Integrate into CI/CD pipeline"
echo "  3. Review docs/security/VULNERABILITY-SCANNING.md"

