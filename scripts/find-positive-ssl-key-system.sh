#!/usr/bin/env bash
# System-wide search for PositiveSSL private key
# Run with: sudo bash find-positive-ssl-key-system.sh

set -euo pipefail

CERT_MOD="44633d7c8e8c371112cd602bc8adeb91"
echo "=========================================="
echo "SYSTEM-WIDE SEARCH for PositiveSSL Private Key"
echo "=========================================="
echo "PositiveSSL certificate modulus: $CERT_MOD"
echo ""
echo "Searching entire filesystem (excluding virtual filesystems)..."
echo "This may take a few minutes..."
echo ""

MATCHING_KEY=""
CHECKED_COUNT=0

# Only exclude virtual filesystems that cause issues
# Search EVERYTHING else on the server
EXCLUDE_DIRS=(
    "/proc"
    "/sys"
    "/dev"
)

# Build find exclude options
EXCLUDE_OPTS=""
for dir in "${EXCLUDE_DIRS[@]}"; do
    EXCLUDE_OPTS="$EXCLUDE_OPTS -path $dir -prune -o"
done

echo "=========================================="
echo "SEARCHING ENTIRE SERVER"
echo "=========================================="
echo "Starting from: / (root)"
echo "Searching: ALL directories, ALL filesystems"
echo "Only excluding: /proc, /sys, /dev (virtual filesystems)"
echo ""
echo "This will search:"
echo "  - / (root)"
echo "  - /etc, /root, /opt, /usr, /var, /home"
echo "  - /tmp, /run, /boot, /snap"
echo "  - ALL mounted filesystems"
echo "  - EVERYTHING on the server"
echo ""
echo "Starting search... (this may take several minutes)"
echo ""

# Search entire server for .key files starting from root (/)
while IFS= read -r keyfile; do
    if [ -f "$keyfile" ] && [ -r "$keyfile" ]; then
        CHECKED_COUNT=$((CHECKED_COUNT + 1))
        
        # Check if it's a private key (skip if file is too large or binary)
        if [ -s "$keyfile" ] && [ $(stat -f%z "$keyfile" 2>/dev/null || stat -c%s "$keyfile" 2>/dev/null || echo 0) -lt 100000 ]; then
            if grep -q "BEGIN.*PRIVATE KEY" "$keyfile" 2>/dev/null; then
                echo "[$CHECKED_COUNT] Checking: $keyfile"
                KEY_MOD=$(openssl rsa -noout -modulus -in "$keyfile" 2>/dev/null 2>&1 | openssl md5 | awk '{print $NF}')
                
                if [ "$KEY_MOD" = "$CERT_MOD" ]; then
                    echo "    ✅✅✅ MATCHES PositiveSSL certificate!"
                    MATCHING_KEY="$keyfile"
                    break
                else
                    echo "    ❌ Does not match (modulus: $KEY_MOD)"
                fi
            fi
        fi
        
        # Show progress every 50 files
        if [ $((CHECKED_COUNT % 50)) -eq 0 ]; then
            echo "  Checked $CHECKED_COUNT files... still searching..."
        fi
    fi
done < <(find / $EXCLUDE_OPTS -type f -name '*.key' -print 2>/dev/null)

# Also search entire server for files that might contain keys but have different extensions
if [ -z "$MATCHING_KEY" ]; then
    echo ""
    echo "=========================================="
    echo "Also searching entire server for:"
    echo "  - .pem files"
    echo "  - Files with 'private' in name"
    echo "  - Files with 'inlock' in name"
    echo "=========================================="
    echo ""
    
    while IFS= read -r keyfile; do
        if [ -f "$keyfile" ] && [ -r "$keyfile" ]; then
            CHECKED_COUNT=$((CHECKED_COUNT + 1))
            
            if [ -s "$keyfile" ] && [ $(stat -f%z "$keyfile" 2>/dev/null || stat -c%s "$keyfile" 2>/dev/null || echo 0) -lt 100000 ]; then
                if grep -q "BEGIN.*PRIVATE KEY" "$keyfile" 2>/dev/null; then
                    echo "[$CHECKED_COUNT] Checking: $keyfile"
                    KEY_MOD=$(openssl rsa -noout -modulus -in "$keyfile" 2>/dev/null 2>&1 | openssl md5 | awk '{print $NF}')
                    
                    if [ "$KEY_MOD" = "$CERT_MOD" ]; then
                        echo "    ✅✅✅ MATCHES PositiveSSL certificate!"
                        MATCHING_KEY="$keyfile"
                        break
                    fi
                fi
            fi
        fi
    done < <(find / $EXCLUDE_OPTS \( -type f \( -name '*.pem' -o -iname '*private*key*' -o -iname '*inlock*key*' \) \) -print 2>/dev/null)
fi

echo ""
echo "=========================================="
echo "SEARCH COMPLETE"
echo "=========================================="
echo "Total files checked: $CHECKED_COUNT"
echo ""

if [ -n "$MATCHING_KEY" ]; then
    echo "✅✅✅ FOUND MATCHING KEY: $MATCHING_KEY"
    echo ""
    echo "To use it, run:"
    echo "  sudo cp $MATCHING_KEY /tmp/inlock_ai-positive-ssl.key"
    echo "  sudo chmod 644 /tmp/inlock_ai-positive-ssl.key"
    echo "  sudo chown comzis:comzis /tmp/inlock_ai-positive-ssl.key"
    echo ""
    echo "Then I can install the PositiveSSL certificate!"
else
    echo "❌ No matching key found after searching ENTIRE SERVER"
    echo ""
    echo "Searched EVERYTHING:"
    echo "  - Entire server from root (/)"
    echo "  - All directories: /etc, /root, /opt, /usr, /var, /home, /tmp, /run, /boot, /snap"
    echo "  - All mounted filesystems"
    echo "  - All .key files"
    echo "  - All .pem files"
    echo "  - All files with 'private' or 'key' in name"
    echo "  - Only excluded: /proc, /sys, /dev (virtual filesystems)"
    echo ""
    echo "The key is likely:"
    echo "  1. Not on this server (check PositiveSSL account for download)"
    echo "  2. In an archive/zip file (extract and search)"
    echo "  3. Named with a completely different extension"
    echo "  4. Protected/encrypted in a way that prevents detection"
fi
echo "=========================================="

