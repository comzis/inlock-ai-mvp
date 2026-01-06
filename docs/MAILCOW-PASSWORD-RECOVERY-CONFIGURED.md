# Mailcow Password Recovery - Configured

## Date: 2026-01-04

## Issue
Password recovery was unavailable with error: "The password recovery is currently unavailable. Please contact your administrator."

## Root Cause
The password reset notification email template was not configured in Mailcow Redis:
- Missing `PW_RESET_FROM` (sender email address)
- Missing `PW_RESET_SUBJ` (email subject line)

## Fix Applied

### Configuration Set in Redis:
```bash
PW_RESET_FROM: noreply@inlock.ai
PW_RESET_SUBJ: Password Reset Request
```

### Method Used:
Direct Redis configuration via PHP CLI in the mailcowdockerized-php-fpm-mailcow-1 container.

## Verification

To verify the configuration is active:

```bash
docker exec mailcowdockerized-php-fpm-mailcow-1 php -r "
\$redis = new Redis();
\$redis->connect('redis-mailcow', 6379);
\$redis->auth('REDISPASS_FROM_ENV');
\$redis->setOption(Redis::OPT_SERIALIZER, Redis::SERIALIZER_PHP);
echo 'PW_RESET_FROM: ' . (\$redis->get('PW_RESET_FROM') ?: 'NOT SET') . PHP_EOL;
echo 'PW_RESET_SUBJ: ' . (\$redis->get('PW_RESET_SUBJ') ?: 'NOT SET') . PHP_EOL;
"
```

## Current Status

✅ **Password reset notification configured**
✅ **Users can now request password recovery**

## Additional Requirements

For password recovery to work for a specific user:

1. **User must have a recovery email address set:**
   - Log in to Mailcow Admin: https://mail.inlock.ai
   - Go to: **Configuration** → **Mailboxes**
   - Edit the user mailbox
   - Set "Password Recovery Email" to a valid external email address (not @inlock.ai)
   - Save

2. **Recovery email must be different from the mailbox email:**
   - If user is `milorad.stevanovic@inlock.ai`
   - Recovery email should be a different address (e.g., personal Gmail, etc.)

## Testing

To test password recovery:

1. Go to: https://mail.inlock.ai/reset-password
2. Enter the user's email address: `milorad.stevanovic@inlock.ai`
3. Submit the form
4. Check the recovery email inbox for the password reset link

## Notes

- Password reset tokens have a lifetime limit (configured in Mailcow)
- There's a limit on the number of tokens that can be generated per user
- The notification email will be sent from: `noreply@inlock.ai`
- Ensure `noreply@inlock.ai` exists as a mailbox or alias if you want bounce handling

## Related Files

- `/home/comzis/inlock/docs/MAILCOW-PASSWORD-RECOVERY-FIX.md` - Original troubleshooting guide
- Mailcow Redis container: `mailcowdockerized-redis-mailcow-1`
- Mailcow PHP-FPM container: `mailcowdockerized-php-fpm-mailcow-1`


