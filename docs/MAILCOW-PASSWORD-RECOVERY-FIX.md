# Mailcow Password Recovery Fix

## Problem

Password recovery shows: "The password recovery is currently unavailable. Please contact your administrator."

**Root Cause:** The password reset notification email template is not configured in Mailcow. Mailcow requires:
1. A "From" email address (`PW_RESET_FROM`)
2. A subject line (`PW_RESET_SUBJ`)
3. Email templates (HTML and text)

## Solution

### Option 1: Configure via Mailcow Admin UI (Recommended)

1. **Log in to Mailcow Admin Panel:**
   - Go to: https://mail.inlock.ai
   - Log in as admin

2. **Navigate to Configuration:**
   - Go to: **Configuration** → **Notifications** (or **Settings** → **Notifications**)

3. **Configure Password Reset Notification:**
   - Find "Password Reset" notification template
   - Set **From Address**: e.g., `noreply@inlock.ai` or `admin@inlock.ai`
   - Set **Subject**: e.g., `Password Reset Request for {{username}}`
   - Configure email templates (HTML and text)
   - Save the configuration

4. **Verify User Has Recovery Email:**
   - Go to: **Configuration** → **Mailboxes**
   - Find user: `milorad.stevanovic@inlock.ai`
   - Edit the mailbox
   - Ensure "Password Recovery Email" is set to a valid external email address
   - Save

### Option 2: Configure via Redis (Direct)

If you need to set it directly via Redis:

```bash
# Set the "From" address
docker exec mailcowdockerized-redis-mailcow-1 redis-cli -a $(docker exec mailcowdockerized-redis-mailcow-1 cat /etc/redis/redis.conf | grep "^requirepass" | cut -d' ' -f2) SET PW_RESET_FROM "noreply@inlock.ai"

# Set the subject
docker exec mailcowdockerized-redis-mailcow-1 redis-cli -a $(docker exec mailcowdockerized-redis-mailcow-1 cat /etc/redis/redis.conf | grep "^requirepass" | cut -d' ' -f2) SET PW_RESET_SUBJ "Password Reset Request"

# Verify
docker exec mailcowdockerized-redis-mailcow-1 redis-cli -a $(docker exec mailcowdockerized-redis-mailcow-1 cat /etc/redis/redis.conf | grep "^requirepass" | cut -d' ' -f2) GET PW_RESET_FROM
docker exec mailcowdockerized-redis-mailcow-1 redis-cli -a $(docker exec mailcowdockerized-redis-mailcow-1 cat /etc/redis/redis.conf | grep "^requirepass" | cut -d' ' -f2) GET PW_RESET_SUBJ
```

**Note:** This method only sets basic values. The admin UI is recommended for full template configuration.

## Additional Requirements

### User Must Have Recovery Email Set

The user `milorad.stevanovic@inlock.ai` must have a recovery email address configured:

1. Log in to Mailcow Admin
2. Go to **Configuration** → **Mailboxes**
3. Edit `milorad.stevanovic@inlock.ai`
4. Set **Password Recovery Email** to a valid external email (not @inlock.ai)
5. Save

## Verification

After configuration:

1. Go to: https://mail.inlock.ai/reset-password
2. Enter: `milorad.stevanovic@inlock.ai`
3. Submit the form
4. Check the recovery email inbox for the password reset link

## Current Status

- **User exists:** ✅ `milorad.stevanovic@inlock.ai` exists and is active
- **Password reset notification:** ❌ Not configured (missing `PW_RESET_FROM` and `PW_RESET_SUBJ` in Redis)
- **Recovery email:** ⚠️ Needs verification (check if set in mailbox attributes)

## Next Steps

1. Configure password reset notification in Mailcow admin panel
2. Verify user has recovery email address set
3. Test password recovery functionality


