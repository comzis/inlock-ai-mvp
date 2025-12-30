#!/usr/bin/env bash
set -euo pipefail

# Interactive script to find and import PositiveSSL certificates

echo "=========================================="
echo "PositiveSSL Certificate Import Helper"
echo "=========================================="
echo ""

# Check if certificates are already installed
if [ -f "/home/comzis/apps/secrets-real/positive-ssl.crt" ] && [ -s "/home/comzis/apps/secrets-real/positive-ssl.crt" ]; then
  echo "⚠️  Found existing certificate file"
  openssl x509 -in /home/comzis/apps/secrets-real/positive-ssl.crt -noout -subject -dates 2>/dev/null || echo "  (File exists but may not be valid)"
  echo ""
fi

echo "Where are your downloaded certificate files?"
echo ""
echo "1. Files are already on this server (I'll help you find them)"
echo "2. I need to upload them via SCP/SFTP"
echo "3. Files are in a specific directory I'll tell you"
echo ""
read -p "Choose option (1-3): " choice

case $choice in
  1)
    echo ""
    echo "Searching for certificate files..."
    echo ""
    
    # Search common locations
    CERT_FILES=$(find ~/Downloads ~/Desktop /tmp ~/Documents ~ 2>/dev/null -type f \( -name "*.crt" -o -name "*.pem" -o -name "*.cer" -o -name "*certificate*" -o -name "*inlock*" \) 2>/dev/null | head -10)
    
    if [ -z "$CERT_FILES" ]; then
      echo "❌ No certificate files found in common locations"
      echo ""
      read -p "Enter the full path to your certificate file: " CERT_PATH
    else
      echo "Found potential certificate files:"
      echo "$CERT_FILES" | nl
      echo ""
      read -p "Enter the number or full path to your certificate file: " CERT_INPUT
      
      if [[ "$CERT_INPUT" =~ ^[0-9]+$ ]]; then
        CERT_PATH=$(echo "$CERT_FILES" | sed -n "${CERT_INPUT}p")
      else
        CERT_PATH="$CERT_INPUT"
      fi
    fi
    
    # Find key file
    echo ""
    KEY_FILES=$(find ~/Downloads ~/Desktop /tmp ~/Documents ~ 2>/dev/null -type f \( -name "*.key" -o -name "*private*" \) 2>/dev/null | head -10)
    
    if [ -z "$KEY_FILES" ]; then
      echo "❌ No key files found in common locations"
      read -p "Enter the full path to your private key file: " KEY_PATH
    else
      echo "Found potential key files:"
      echo "$KEY_FILES" | nl
      echo ""
      read -p "Enter the number or full path to your private key file: " KEY_INPUT
      
      if [[ "$KEY_INPUT" =~ ^[0-9]+$ ]]; then
        KEY_PATH=$(echo "$KEY_FILES" | sed -n "${KEY_INPUT}p")
      else
        KEY_PATH="$KEY_INPUT"
      fi
    fi
    
    # Check for intermediate
    echo ""
    read -p "Do you have an intermediate/chain certificate file? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      INT_FILES=$(find ~/Downloads ~/Desktop /tmp ~/Documents ~ 2>/dev/null -type f \( -name "*intermediate*" -o -name "*chain*" -o -name "*ca-bundle*" -o -name "*bundle*" \) 2>/dev/null | head -10)
      
      if [ -z "$INT_FILES" ]; then
        read -p "Enter the full path to your intermediate certificate file: " INT_PATH
      else
        echo "Found potential intermediate files:"
        echo "$INT_FILES" | nl
        read -p "Enter the number or full path: " INT_INPUT
        
        if [[ "$INT_INPUT" =~ ^[0-9]+$ ]]; then
          INT_PATH=$(echo "$INT_FILES" | sed -n "${INT_INPUT}p")
        else
          INT_PATH="$INT_INPUT"
        fi
      fi
    else
      INT_PATH=""
    fi
    
    # Install
    echo ""
    echo "Installing certificates..."
    if [ -n "$INT_PATH" ]; then
      "$(dirname "$0")/install-positive-ssl.sh" "$CERT_PATH" "$KEY_PATH" "$INT_PATH"
    else
      "$(dirname "$0")/install-positive-ssl.sh" "$CERT_PATH" "$KEY_PATH"
    fi
    ;;
    
  2)
    echo ""
    echo "To upload files via SCP, run these commands from your local machine:"
    echo ""
    echo "  scp /path/to/certificate.crt $(whoami)@$(hostname -f):/tmp/"
    echo "  scp /path/to/private.key $(whoami)@$(hostname -f):/tmp/"
    echo "  scp /path/to/intermediate.crt $(whoami)@$(hostname -f):/tmp/  # if you have it"
    echo ""
    echo "Then run this script again and choose option 1"
    ;;
    
  3)
    echo ""
    read -p "Enter the directory path where your certificate files are: " CERT_DIR
    
    if [ ! -d "$CERT_DIR" ]; then
      echo "❌ Directory not found: $CERT_DIR"
      exit 1
    fi
    
    echo ""
    echo "Files in $CERT_DIR:"
    ls -lh "$CERT_DIR" | grep -E "\.(crt|pem|key|cer)$|certificate|private|inlock|positive" || ls -lh "$CERT_DIR"
    echo ""
    
    read -p "Enter the certificate filename: " CERT_FILE
    read -p "Enter the private key filename: " KEY_FILE
    read -p "Enter the intermediate filename (or press Enter to skip): " INT_FILE
    
    CERT_PATH="$CERT_DIR/$CERT_FILE"
    KEY_PATH="$CERT_DIR/$KEY_FILE"
    
    if [ -n "$INT_FILE" ]; then
      INT_PATH="$CERT_DIR/$INT_FILE"
      "$(dirname "$0")/install-positive-ssl.sh" "$CERT_PATH" "$KEY_PATH" "$INT_PATH"
    else
      "$(dirname "$0")/install-positive-ssl.sh" "$CERT_PATH" "$KEY_PATH"
    fi
    ;;
    
  *)
    echo "Invalid option"
    exit 1
    ;;
esac

