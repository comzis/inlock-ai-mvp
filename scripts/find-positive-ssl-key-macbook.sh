#!/usr/bin/env bash
# Search MacBook Pro for PositiveSSL private key
# Run with: bash find-positive-ssl-key-macbook.sh

set -euo pipefail

CERT_MOD="44633d7c8e8c371112cd602bc8adeb91"
echo "=========================================="
echo "SEARCHING MACBOOK PRO for PositiveSSL Private Key"
echo "=========================================="
echo "PositiveSSL certificate modulus: $CERT_MOD"
echo ""
echo "Searching entire MacBook Pro..."
echo "Starting from: ~ (home directory)"
echo ""
echo "This will search:"
echo "  - ~/Downloads, ~/Desktop, ~/Documents"
echo "  - ~/Library"
echo "  - All subdirectories"
echo ""
echo "Starting search... (this may take a few minutes)"
echo ""

MATCHING_KEY=""
CHECKED_COUNT=0

# Search home directory and common locations
SEARCH_DIRS=(
    "$HOME"
    "$HOME/Downloads"
    "$HOME/Desktop"
    "$HOME/Documents"
    "$HOME/Library"
)

# Exclude some system directories
EXCLUDE_DIRS=(
    "/System"
    "/private"
    "/Volumes"
)

# Build find exclude options
EXCLUDE_OPTS=""
for dir in "${EXCLUDE_DIRS[@]}"; do
    EXCLUDE_OPTS="$EXCLUDE_OPTS -path $dir -prune -o"
done

echo "Searching for .key files..."
echo ""

# Search for .key files
for search_dir in "${SEARCH_DIRS[@]}"; do
    if [ -d "$search_dir" ]; then
        echo "Searching: $search_dir"
        
        while IFS= read -r keyfile; do
            if [ -f "$keyfile" ] && [ -r "$keyfile" ]; then
                CHECKED_COUNT=$((CHECKED_COUNT + 1))
                
                # Check if it's a private key (skip if file is too large)
                FILE_SIZE=$(stat -f%z "$keyfile" 2>/dev/null || echo 0)
                if [ "$FILE_SIZE" -lt 100000 ] && [ "$FILE_SIZE" -gt 0 ]; then
                    if grep -q "BEGIN.*PRIVATE KEY" "$keyfile" 2>/dev/null; then
                        echo "[$CHECKED_COUNT] Checking: $keyfile"
                        KEY_MOD=$(openssl rsa -noout -modulus -in "$keyfile" 2>/dev/null 2>&1 | openssl md5 | awk '{print $NF}')
                        
                        if [ "$KEY_MOD" = "$CERT_MOD" ]; then
                            echo "    ✅✅✅ MATCHES PositiveSSL certificate!"
                            MATCHING_KEY="$keyfile"
                            break 2
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
        done < <(find "$search_dir" $EXCLUDE_OPTS -type f -name '*.key' -print 2>/dev/null)
    fi
done

# Also search for .pem files and files with 'private' in name
if [ -z "$MATCHING_KEY" ]; then
    echo ""
    echo "=========================================="
    echo "Also searching for:"
    echo "  - .pem files"
    echo "  - Files with 'private' in name"
    echo "  - Files with 'inlock' in name"
    echo "=========================================="
    echo ""
    
    for search_dir in "${SEARCH_DIRS[@]}"; do
        if [ -d "$search_dir" ]; then
            while IFS= read -r keyfile; do
                if [ -f "$keyfile" ] && [ -r "$keyfile" ]; then
                    CHECKED_COUNT=$((CHECKED_COUNT + 1))
                    
                    FILE_SIZE=$(stat -f%z "$keyfile" 2>/dev/null || echo 0)
                    if [ "$FILE_SIZE" -lt 100000 ] && [ "$FILE_SIZE" -gt 0 ]; then
                        if grep -q "BEGIN.*PRIVATE KEY" "$keyfile" 2>/dev/null; then
                            echo "[$CHECKED_COUNT] Checking: $keyfile"
                            KEY_MOD=$(openssl rsa -noout -modulus -in "$keyfile" 2>/dev/null 2>&1 | openssl md5 | awk '{print $NF}')
                            
                            if [ "$KEY_MOD" = "$CERT_MOD" ]; then
                                echo "    ✅✅✅ MATCHES PositiveSSL certificate!"
                                MATCHING_KEY="$keyfile"
                                break 2
                            fi
                        fi
                    fi
                fi
            done < <(find "$search_dir" $EXCLUDE_OPTS \( -type f \( -name '*.pem' -o -iname '*private*key*' -o -iname '*inlock*key*' \) \) -print 2>/dev/null)
        fi
    done
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
    echo "To transfer it to the server, run:"
    echo "  scp $MATCHING_KEY comzis@your-server:/tmp/inlock_ai-positive-ssl.key"
    echo ""
    echo "Or paste the key content here:"
    echo "  cat $MATCHING_KEY"
    echo ""
    echo "Then I can install the PositiveSSL certificate!"
else
    echo "❌ No matching key found"
    echo ""
    echo "Searched:"
    echo "  - ~/Downloads, ~/Desktop, ~/Documents"
    echo "  - ~/Library"
    echo "  - All subdirectories"
    echo ""
    echo "The key may be:"
    echo "  1. In a zip/archive file (extract and search)"
    echo "  2. In your PositiveSSL account (download it)"
    echo "  3. Named differently"
fi
echo "=========================================="










