#!/bin/bash
#
# Script to add mail.inlock.ai email account to Mac Mail
# Email: milorad.stevanovic@inlock.ai
# Password: panbov-byxdir-tywgA1
#
# Usage: ./scripts/add_mail_account_mac.sh
#

set -e

# Account configuration
EMAIL="milorad.stevanovic@inlock.ai"
PASSWORD="panbov-byxdir-tywgA1"
FULL_NAME="Milorad Stevanovic"
IMAP_SERVER="mail.inlock.ai"
IMAP_PORT="993"
SMTP_SERVER="mail.inlock.ai"
SMTP_PORT="465"  # Alternative: 587 for STARTTLS

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "========================================="
echo "Add Mail Account: $EMAIL"
echo "Server: $IMAP_SERVER"
echo "========================================="
echo ""

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo -e "${RED}Error: This script is for macOS only${NC}"
    exit 1
fi

# Function to test connectivity
test_connectivity() {
    echo -e "${YELLOW}Testing connectivity to $IMAP_SERVER...${NC}"
    
    # Test DNS resolution
    if ! nslookup "$IMAP_SERVER" &>/dev/null; then
        echo -e "${RED}Error: Cannot resolve $IMAP_SERVER${NC}"
        return 1
    fi
    
    # Test IMAP port
    if ! nc -z -v -w 3 "$IMAP_SERVER" "$IMAP_PORT" 2>&1 | grep -q "succeeded"; then
        echo -e "${YELLOW}Warning: Cannot connect to $IMAP_SERVER:$IMAP_PORT${NC}"
        echo "  (This might be OK if you're not on the same network)"
    else
        echo -e "${GREEN}✓ IMAP port $IMAP_PORT is accessible${NC}"
    fi
    
    # Test SMTP port
    if ! nc -z -v -w 3 "$SMTP_SERVER" "$SMTP_PORT" 2>&1 | grep -q "succeeded"; then
        echo -e "${YELLOW}Warning: Cannot connect to $SMTP_SERVER:$SMTP_PORT${NC}"
    else
        echo -e "${GREEN}✓ SMTP port $SMTP_PORT is accessible${NC}"
    fi
    
    # Test SSL certificate
    echo -e "${YELLOW}Testing SSL certificate...${NC}"
    CERT_CHECK=$(echo | openssl s_client -connect "$IMAP_SERVER:$IMAP_PORT" -servername "$IMAP_SERVER" 2>&1 | grep -o "Verify return code: [0-9]*")
    if echo "$CERT_CHECK" | grep -q "Verify return code: 0"; then
        echo -e "${GREEN}✓ SSL certificate is valid${NC}"
    else
        echo -e "${YELLOW}Warning: SSL certificate verification: $CERT_CHECK${NC}"
    fi
    
    echo ""
}

# Function to check if account already exists
check_existing_account() {
    echo -e "${YELLOW}Checking if account already exists...${NC}"
    
    # Try to find account using defaults (Mac Mail stores accounts in plist files)
    if defaults read com.apple.mail 2>/dev/null | grep -q "$EMAIL"; then
        echo -e "${YELLOW}Warning: Account with email $EMAIL may already exist${NC}"
        echo "  You may want to remove it first or check Mail → Settings → Accounts"
        echo ""
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    else
        echo -e "${GREEN}✓ No existing account found${NC}"
        echo ""
    fi
}

# Function to create Python script for adding account
create_python_script() {
    cat > /tmp/add_mail_account.py <<'PYTHON_SCRIPT'
#!/usr/bin/env python3
"""
Script to add mail account to macOS Mail using Accounts framework
"""
import sys
import os

try:
    from Accounts import ACAccountTypeIdentifierIMAP, ACAccountTypeIdentifierSMTP
    from Accounts import ACAccountStore, ACAccountCredential
    from Cocoa import NSObject, NSURL
    from ScriptingBridge import SBApplication
except ImportError:
    print("Error: Required frameworks not available")
    print("This script requires macOS with Python and Objective-C bridges")
    print("Trying AppleScript alternative...")
    sys.exit(1)

def add_mail_account(email, password, full_name, imap_server, imap_port, smtp_server, smtp_port):
    """Add mail account using Accounts framework"""
    try:
        # This is a complex operation that requires proper Objective-C bridging
        # For now, we'll use AppleScript as it's more reliable
        print("Using AppleScript method...")
        return False
    except Exception as e:
        print(f"Error: {e}")
        return False

if __name__ == "__main__":
    # This script would need proper pyobjc installation
    # For now, we'll use AppleScript
    sys.exit(1)
PYTHON_SCRIPT
    chmod +x /tmp/add_mail_account.py
}

# Function to create AppleScript
create_applescript() {
    cat > /tmp/add_mail_account.applescript <<APPLESCRIPT
tell application "Mail"
    activate
end tell

-- Note: AppleScript cannot fully automate Mail account addition
-- due to security restrictions. We'll provide instructions instead.
-- The user needs to manually add the account through Mail's GUI.

tell application "System Events"
    tell process "Mail"
        -- Try to open Mail preferences
        keystroke "," using command down
        delay 1
        
        -- This is the best we can do - the user must complete the setup manually
    end tell
end tell
APPLESCRIPT
}

# Function to create instructions file
create_instructions() {
    cat > /tmp/add_mail_instructions.txt <<INSTRUCTIONS
=========================================
Instructions to Add Mail Account Manually
=========================================

Email: $EMAIL
Password: $PASSWORD
Full Name: $FULL_NAME

IMAP Settings (Incoming Mail):
  Server: $IMAP_SERVER
  Port: $IMAP_PORT
  Use SSL: Yes (ON)
  Authentication: Password
  Username: $EMAIL
  Password: $PASSWORD

SMTP Settings (Outgoing Mail):
  Server: $SMTP_SERVER
  Port: $SMTP_PORT (or 587 for STARTTLS)
  Use SSL: Yes (ON)
  Authentication: Password
  Username: $EMAIL
  Password: $PASSWORD

Steps:
1. Open Mail app
2. Mail → Settings (or Preferences, Cmd + ,)
3. Click "Accounts" tab
4. Click "+" button (bottom left) to add account
5. Select "Other Mail Account..." (not iCloud, Google, etc.)
6. Enter:
   - Full Name: $FULL_NAME
   - Email Address: $EMAIL
   - Password: $PASSWORD
7. Click "Sign In" or "Next"
8. If auto-detection fails, enter manual settings:
   - Incoming Mail Server: $IMAP_SERVER
   - Port: $IMAP_PORT
   - Use SSL: Yes
   - Username: $EMAIL
   - Password: $PASSWORD
   - Outgoing Mail Server: $SMTP_SERVER
   - Port: $SMTP_PORT
   - Use SSL: Yes
   - Username: $EMAIL
   - Password: $PASSWORD
9. Click "Sign In" or "Create"
10. If SSL certificate warning appears:
    - Click "Show Certificate"
    - Verify issuer is "Let's Encrypt"
    - Check "Always trust" checkbox
    - Click "Continue" or "Trust"
    - Enter your Mac password

Note: If you prefer STARTTLS for SMTP, use port 587 instead of 465.

Troubleshooting:
- If connection fails, check network connectivity
- If SSL error appears, trust the certificate (see step 10)
- Verify ports are not blocked by firewall
- Check server is running: ssh comzis@100.83.222.69 "docker ps --filter 'name=dovecot'"
INSTRUCTIONS
}

# Main execution
main() {
    # Test connectivity first
    test_connectivity
    
    # Check if account exists
    check_existing_account
    
    # Create instructions file
    create_instructions
    
    echo -e "${YELLOW}Note: macOS does not allow fully automated mail account addition${NC}"
    echo -e "${YELLOW}      due to security restrictions.${NC}"
    echo ""
    echo -e "${GREEN}Instructions have been saved to: /tmp/add_mail_instructions.txt${NC}"
    echo ""
    
    # Open Mail app and instructions
    read -p "Open Mail app and show instructions? (Y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        # Open Mail app
        open -a Mail 2>/dev/null || echo "Mail app not found"
        
        # Wait a bit for Mail to open
        sleep 2
        
        # Open instructions in default text editor
        open /tmp/add_mail_instructions.txt 2>/dev/null || cat /tmp/add_mail_instructions.txt
        
        echo ""
        echo -e "${GREEN}Mail app should be open now.${NC}"
        echo -e "${GREEN}Follow the instructions in the text file.${NC}"
        echo ""
        echo -e "${YELLOW}Quick reference:${NC}"
        echo "  Email: $EMAIL"
        echo "  IMAP Server: $IMAP_SERVER (port $IMAP_PORT, SSL ON)"
        echo "  SMTP Server: $SMTP_SERVER (port $SMTP_PORT, SSL ON)"
        echo ""
    else
        echo ""
        echo -e "${GREEN}Instructions saved to: /tmp/add_mail_instructions.txt${NC}"
        echo "You can view them with: cat /tmp/add_mail_instructions.txt"
        echo "Or open with: open /tmp/add_mail_instructions.txt"
    fi
}

# Run main function
main
