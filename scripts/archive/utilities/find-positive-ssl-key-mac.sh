#!/usr/bin/env bash
# Run this script on your MacBook Pro to find the PositiveSSL private key
# Usage: Copy this script to your Mac and run: bash find-positive-ssl-key-mac.sh

echo "=========================================="
echo "Searching for PositiveSSL Private Key"
echo "=========================================="
echo ""

# PositiveSSL certificate modulus (what we're looking for)
POSITIVE_SSL_MODULUS="44633d7c8e8c371112cd602bc8adeb91"

echo "Looking for key files..."
echo ""

# Find all .key files
KEY_FILES=$(find ~/Downloads ~/Desktop ~/Documents -type f -name '*.key' 2>/dev/null)

if [ -z "$KEY_FILES" ]; then
  echo "❌ No .key files found in Downloads, Desktop, or Documents"
  echo ""
  echo "Try searching more broadly:"
  echo "  find ~ -type f -name '*.key' 2>/dev/null | grep -v Library"
else
  echo "Found key files:"
  echo "$KEY_FILES" | nl
  echo ""
  echo "Checking which ones match PositiveSSL certificate..."
  echo ""
  
  MATCH_FOUND=false
  
  for keyfile in $KEY_FILES; do
    if [ -f "$keyfile" ]; then
      # Check if file contains a private key
      if grep -q "BEGIN.*PRIVATE KEY" "$keyfile" 2>/dev/null; then
        echo "Checking: $keyfile"
        KEY_MOD=$(openssl rsa -noout -modulus -in "$keyfile" 2>/dev/null | openssl md5 2>&1)
        
        if echo "$KEY_MOD" | grep -q "$POSITIVE_SSL_MODULUS"; then
          echo "  ✅✅✅ MATCHES PositiveSSL certificate!"
          echo "  This is the key you need!"
          echo ""
          echo "Transfer it to the server with:"
          echo "  scp $keyfile comzis@your-server:/tmp/inlock_ai-positive-ssl.key"
          MATCH_FOUND=true
        else
          echo "  ❌ Does not match (modulus: $KEY_MOD)"
        fi
        echo ""
      fi
    fi
  done
  
  if [ "$MATCH_FOUND" = false ]; then
    echo "❌ No matching key found"
    echo ""
    echo "The PositiveSSL certificate modulus is: $POSITIVE_SSL_MODULUS"
    echo "None of the found keys match this certificate."
  fi
fi

echo ""
echo "=========================================="
echo "Also check your PositiveSSL account:"
echo "1. Log into PositiveSSL/Sectigo"
echo "2. Look for 'Private Key' or 'Key Pair' download"
echo "3. Some providers generate a new key pair"
echo "=========================================="










