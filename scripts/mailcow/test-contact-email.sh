#!/bin/bash
# Simple test script to send email to contact@inlock.ai
# This will test if forwarding to milorad.stevanovic@inlock.ai works

set -euo pipefail

SMTP_HOST="mail.inlock.ai"
SMTP_PORT="587"
SMTP_USER="contact@inlock.ai"
SMTP_PASSWORD="hssgZwbd7aeh2jsoio!dsUs"
TO_EMAIL="contact@inlock.ai"
FROM_EMAIL="contact@inlock.ai"

TEST_SUBJECT="Test Email - Contact Forwarding Verification $(date +%Y%m%d-%H%M%S)"
TEST_BODY="This is a test email to verify that emails sent to contact@inlock.ai are properly forwarded to milorad.stevanovic@inlock.ai.

Test Details:
- Sent at: $(date)
- From: $FROM_EMAIL
- To: $TO_EMAIL
- Expected forward: milorad.stevanovic@inlock.ai

If you receive this email at milorad.stevanovic@inlock.ai, the forwarding is working correctly!"

echo "========================================="
echo "Test Email Forwarding"
echo "========================================="
echo "Sending test email to: $TO_EMAIL"
echo "Expected forward to: milorad.stevanovic@inlock.ai"
echo ""

# Use curl to send email via SMTP
echo "Sending test email via SMTP..."
curl -v --url "smtp://${SMTP_HOST}:${SMTP_PORT}" \
    --mail-from "$FROM_EMAIL" \
    --mail-rcpt "$TO_EMAIL" \
    --user "${SMTP_USER}:${SMTP_PASSWORD}" \
    --ssl-reqd \
    -T <(echo -e "From: $FROM_EMAIL\nTo: $TO_EMAIL\nSubject: $TEST_SUBJECT\n\n$TEST_BODY") \
    2>&1 | grep -E "(250|354|550|Authentication|SSL|TLS|error|Error)" || true

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo ""
    echo "✅ Test email sent successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Check mailbox: milorad.stevanovic@inlock.ai"
    echo "2. Verify the test email was received"
    echo "3. Check spam folder if not in inbox"
    echo ""
    echo "To check Mailcow postfix logs:"
    echo "  docker logs mailcowdockerized-postfix-mailcow-1 --tail 50 | grep -i forward"
else
    echo ""
    echo "❌ Failed to send test email"
    echo ""
    echo "Troubleshooting:"
    echo "1. Check SMTP credentials are correct"
    echo "2. Verify contact@inlock.ai mailbox exists"
    echo "3. Check Mailcow postfix logs:"
    echo "   docker logs mailcowdockerized-postfix-mailcow-1 --tail 50"
fi

echo "========================================="
