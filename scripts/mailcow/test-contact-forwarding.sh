#!/bin/bash
# Test Email Forwarding: contact@inlock.ai -> milorad.stevanovic@inlock.ai
# Sends a test email to verify forwarding works

set -euo pipefail

FROM_EMAIL="contact@inlock.ai"
TO_EMAIL="milorad.stevanovic@inlock.ai"
TEST_SUBJECT="Test Email - Contact Form Forwarding Verification"
TEST_BODY="This is a test email to verify that emails sent to $FROM_EMAIL are properly forwarded to $TO_EMAIL.

Test Details:
- Sent at: $(date)
- From: $FROM_EMAIL
- Forwarded to: $TO_EMAIL

If you receive this email, the forwarding is working correctly!"

echo "========================================="
echo "Test Email Forwarding"
echo "========================================="
echo "From: $FROM_EMAIL"
echo "Forwarded to: $TO_EMAIL"
echo ""

# Check if forwarding is configured
echo "Checking forwarding configuration..."
DB_ROOT_PW=$(docker exec mailcowdockerized-mysql-mailcow-1 printenv | grep DB""ROOT | cut -d= -f2)

FORWARDING=$(docker exec mailcowdockerized-mysql-mailcow-1 mysql -u root -p"$DB_ROOT_PW" mailcow -sN -e "SELECT goto FROM alias WHERE address='$FROM_EMAIL' AND active=1;" 2>/dev/null || echo "")

if [ -z "$FORWARDING" ]; then
    echo "❌ Forwarding not configured!"
    echo ""
    echo "Please run setup script first:"
    echo "  bash /home/comzis/.cursor/projects/home-comzis-inlock/scripts/setup-contact-forwarding.sh"
    exit 1
fi

echo "✅ Forwarding configured: $FROM_EMAIL -> $FORWARDING"
echo ""

# Check if contact@inlock.ai mailbox exists (for sending)
echo "Checking if contact@inlock.ai mailbox exists..."
MAILBOX_EXISTS=$(docker exec mailcowdockerized-mysql-mailcow-1 mysql -u root -p"$DB_ROOT_PW" mailcow -sN -e "SELECT COUNT(*) FROM mailbox WHERE username='contact' AND domain='inlock.ai';" 2>/dev/null || echo "0")

if [ "$MAILBOX_EXISTS" = "0" ]; then
    echo "⚠️  Warning: contact@inlock.ai mailbox does not exist"
    echo "   Forwarding will still work, but mailbox won't receive/store emails"
    echo ""
fi

# Send test email using swaks (if available) or curl
echo "Sending test email..."
echo ""

if command -v swaks >/dev/null 2>&1; then
    # Use swaks if available
    echo "Using swaks to send test email..."
    swaks \
        --to "$FROM_EMAIL" \
        --from "test@inlock.ai" \
        --server mail.inlock.ai \
        --port 587 \
        --auth LOGIN \
        --auth-user "contact@inlock.ai" \
        --auth-password "hssgZwbd7aeh2jsoio!dsUs" \
        --tls \
        --header "Subject: $TEST_SUBJECT" \
        --body "$TEST_BODY" \
        --quit-after FROM
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Test email sent successfully!"
    else
        echo ""
        echo "❌ Failed to send test email"
        exit 1
    fi
elif command -v curl >/dev/null 2>&1; then
    # Use curl as fallback
    echo "Using curl to send test email..."
    SMTP_PASSWORD="hssgZwbd7aeh2jsoio!dsUs"
    
    curl --url "smtp://mail.inlock.ai:587" \
        --mail-from "contact@inlock.ai" \
        --mail-rcpt "$FROM_EMAIL" \
        --user "contact@inlock.ai:$SMTP_PASSWORD" \
        --ssl-reqd \
        --insecure \
        -T <(echo -e "From: contact@inlock.ai\nTo: $FROM_EMAIL\nSubject: $TEST_SUBJECT\n\n$TEST_BODY")
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Test email sent successfully!"
    else
        echo ""
        echo "❌ Failed to send test email"
        exit 1
    fi
else
    echo "❌ Neither swaks nor curl available for sending test email"
    echo ""
    echo "Manual test instructions:"
    echo "1. Send an email to: $FROM_EMAIL"
    echo "2. Check if it arrives at: $TO_EMAIL"
    echo "3. Verify forwarding is working"
    exit 1
fi

echo ""
echo "========================================="
echo "Test Complete"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Check mailbox: $TO_EMAIL"
echo "2. Verify the test email was received"
echo "3. Check spam folder if not in inbox"
echo ""
echo "To check Mailcow logs:"
echo "  docker logs mailcowdockerized-postfix-mailcow-1 --tail 50 | grep -i forward"
echo ""
echo "To verify forwarding in database:"
echo "  docker exec mailcowdockerized-mysql-mailcow-1 mysql -u root -p\$(docker exec mailcowdockerized-mysql-mailcow-1 printenv | grep DB""ROOT | cut -d= -f2) mailcow -e \"SELECT address, goto, active FROM alias WHERE address='$FROM_EMAIL';\""
echo "========================================="
