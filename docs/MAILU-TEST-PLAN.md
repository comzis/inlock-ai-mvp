# Mailu Test Plan - Contact Form and SMTP Flow

**Purpose:** Verify mailu-front, mailu-admin, mailu-redis are healthy and contact form mail flow works.

---

## 📋 Pre-Test Checklist

Before testing, ensure:
- [ ] All services are healthy: `docker compose -f compose/mailu.yml ps`
- [ ] Admin service starts without permission errors
- [ ] Front service starts without nginx errors
- [ ] Redis service starts successfully
- [ ] Environment variables validated (see `MAILU-ENV-SECRETS-CHECKLIST.md`)
- [ ] Secrets accessible in containers

---

## 🏥 Health Check Tests

### Test 1: Service Health Status

```bash
cd /home/comzis/inlock-infra
docker compose -f compose/mailu.yml ps
```

**Expected Output:**
```
NAME                    STATUS
compose-mailu-admin-1   Up X seconds (healthy)
compose-mailu-front-1   Up X seconds (healthy)
compose-mailu-redis-1   Up X seconds (healthy)
compose-mailu-postgres-1 Up X seconds (healthy)
compose-mailu-postfix-1 Up X seconds (healthy)
compose-mailu-imap-1    Up X seconds (healthy)
compose-mailu-rspamd-1  Up X seconds (healthy)
```

**Success Criteria:**
- ✅ All services show "healthy" or "health: starting"
- ✅ No services in "Restarting" state
- ✅ No services in "Exited" state

---

### Test 2: Admin Service Logs

```bash
docker logs compose-mailu-admin-1 --tail 30
```

**Expected Output (Success):**
```
[No PermissionError messages]
[No "Operation not permitted" messages]
[Service starts successfully]
```

**Failure Indicators:**
- ❌ `PermissionError: [Errno 1] Operation not permitted`
- ❌ `os.setgroups([])` errors
- ❌ `chown: Operation not permitted`

---

### Test 3: Front Service Logs

```bash
docker logs compose-mailu-front-1 --tail 30
```

**Expected Output (Success):**
```
[No "could not open error log file" messages]
[No "dlopen() failed" messages]
[nginx starts successfully]
```

**Failure Indicators:**
- ❌ `could not open error log file: open() "/var/lib/nginx/logs/error.log" failed`
- ❌ `dlopen() "/var/lib/nginx/modules/ngx_mail_module.so" failed`
- ❌ nginx fails to start

---

### Test 4: Redis Service Logs

```bash
docker logs compose-mailu-redis-1 --tail 20
```

**Expected Output (Success):**
```
* Redis is starting oO0OoO0OoO0Oo
* Redis version=X.X.X, bits=64, commit=...
* Configuration loaded
* Server initialized
* Ready to accept connections tcp
```

**Failure Indicators:**
- ❌ `error: failed switching to "redis": operation not permitted`
- ❌ Redis fails to start

---

## 📧 SMTP Submission Tests

### Test 5: SMTP Connection Test (Port 25)

```bash
# Test SMTP connection
telnet localhost 25
# Or:
nc -zv localhost 25
```

**Expected Output:**
```
220 mail.inlock.ai ESMTP Mailu
```

**Success Criteria:**
- ✅ Connection accepted
- ✅ Banner shows correct hostname

---

### Test 6: SMTP Submission Test (Port 587)

```bash
# Test submission port
telnet localhost 587
# Or:
nc -zv localhost 587
```

**Expected Output:**
```
220 mail.inlock.ai ESMTP Mailu
```

**Success Criteria:**
- ✅ Connection accepted
- ✅ Banner shows correct hostname

---

### Test 7: Send Test Email via SMTP

```bash
# Install mailutils if needed: sudo apt-get install mailutils

# Send test email
echo "Test message body" | mail -s "Test Subject" -r "test@inlock.ai" admin@inlock.ai

# Check logs
docker logs compose-mailu-postfix-1 --tail 20
```

**Expected Output (Logs):**
```
[Successful message delivery logs]
[No rejection errors]
```

**Success Criteria:**
- ✅ Message accepted by postfix
- ✅ No rejection errors in logs

---

## 📝 Contact Form Flow Test

### Test 8: Web Interface Accessibility

```bash
# Test front web interface (if exposed via Traefik)
curl -I https://mail.inlock.ai
# Or direct:
curl -I http://localhost:80
```

**Expected Output:**
```
HTTP/1.1 200 OK
```

**Success Criteria:**
- ✅ HTTP 200 response
- ✅ Web interface accessible

---

### Test 9: Admin Interface Accessibility

```bash
# Test admin interface
curl -I https://mail.inlock.ai/admin
# Or:
curl -I http://localhost:80/admin
```

**Expected Output:**
```
HTTP/1.1 200 OK
# Or HTTP/1.1 302 Found (redirect to login)
```

**Success Criteria:**
- ✅ Interface accessible (may require authentication)
- ✅ No 500/502/503 errors

---

### Test 10: Contact Form Email Submission

**Manual Test Steps:**

1. **Access contact form:**
   - Navigate to: `https://mail.inlock.ai` (or appropriate URL)
   - Find contact form on website

2. **Submit test message:**
   - Fill in form fields (name, email, message)
   - Submit form

3. **Monitor postfix logs:**
   ```bash
   docker logs compose-mailu-postfix-1 -f
   ```

4. **Verify email received:**
   - Check recipient inbox
   - Verify message content matches form submission

**Expected Log Output:**
```
[Message accepted]
[Message queued for delivery]
[Delivery successful]
```

**Success Criteria:**
- ✅ Form submission accepted
- ✅ Message appears in postfix logs
- ✅ Email delivered to recipient
- ✅ Message content correct

---

## 🔍 Detailed SMTP Flow Verification

### Test 11: End-to-End SMTP Flow

```bash
# Step 1: Connect to SMTP
telnet localhost 25

# Step 2: Follow SMTP conversation
# (Type these commands in telnet session)
EHLO test.example.com
MAIL FROM:<test@example.com>
RCPT TO:<admin@inlock.ai>
DATA
Subject: Test Message

This is a test message body.
.
QUIT
```

**Expected SMTP Conversation:**
```
220 mail.inlock.ai ESMTP Mailu
EHLO test.example.com
250-mail.inlock.ai
250-SIZE 52428800
250-8BITMIME
250-AUTH PLAIN LOGIN
250-STARTTLS
250 OK
MAIL FROM:<test@example.com>
250 OK
RCPT TO:<admin@inlock.ai>
250 OK
DATA
354 End data with <CR><LF>.<CR><LF>
[Message content]
.
250 OK: queued as [message-id]
QUIT
221 Bye
```

**Success Criteria:**
- ✅ All commands return 2xx success codes
- ✅ Message queued successfully
- ✅ No rejection errors

---

## 📊 Test Results Template

```
=== Mailu Test Results ===
Date: [YYYY-MM-DD HH:MM]
Tester: [Name]

Health Checks:
- [ ] Test 1: Service Health Status
  Result: ✅ PASS / ❌ FAIL
  Notes: [Any issues]

- [ ] Test 2: Admin Service Logs
  Result: ✅ PASS / ❌ FAIL
  Notes: [Any errors]

- [ ] Test 3: Front Service Logs
  Result: ✅ PASS / ❌ FAIL
  Notes: [Any errors]

- [ ] Test 4: Redis Service Logs
  Result: ✅ PASS / ❌ FAIL
  Notes: [Any errors]

SMTP Tests:
- [ ] Test 5: SMTP Connection (Port 25)
  Result: ✅ PASS / ❌ FAIL
  Notes: [Connection status]

- [ ] Test 6: SMTP Submission (Port 587)
  Result: ✅ PASS / ❌ FAIL
  Notes: [Connection status]

- [ ] Test 7: Send Test Email
  Result: ✅ PASS / ❌ FAIL
  Notes: [Delivery status]

Contact Form Tests:
- [ ] Test 8: Web Interface
  Result: ✅ PASS / ❌ FAIL
  Notes: [Accessibility]

- [ ] Test 9: Admin Interface
  Result: ✅ PASS / ❌ FAIL
  Notes: [Accessibility]

- [ ] Test 10: Contact Form Submission
  Result: ✅ PASS / ❌ FAIL
  Notes: [Delivery verification]

Overall: ✅ PASS / ❌ FAIL

Issues Found:
[List any issues encountered]
```

---

## 🚨 Troubleshooting

### Issue: Services not healthy

**Check:**
- Container logs for errors
- Resource limits (memory/CPU)
- Network connectivity between services
- Database/Redis accessibility

### Issue: SMTP connection refused

**Check:**
- Port bindings in compose file
- Firewall rules
- Service health status
- Network configuration

### Issue: Email not delivered

**Check:**
- Postfix logs: `docker logs compose-mailu-postfix-1`
- DNS/MX records
- Spam filtering (rspamd logs)
- Recipient email configuration

---

**Next:** See `MAILU-ROLLBACK.md` for rollback procedures if issues occur.

