# Configuring Auth0 to Use Mailcow for Password Reset Emails

**Date:** December 29, 2025  
**Status:** Configuration Guide

---

## 🎯 Objective

Configure Auth0 to send password reset emails through the Mailcow SMTP server instead of Auth0's default email service.

---

## 📋 Prerequisites

- ✅ Mailcow is deployed and operational at `mail.inlock.ai`
- ✅ You have a Mailcow email account (e.g., `admin@inlock.ai`)
- ✅ Mailcow email account password is known

---

## 🔧 Step-by-Step Configuration

### Step 1: Verify Mailcow Email Account

**Option A: Use Existing Account**
- Email: `admin@inlock.ai`
- Password: [Your Mailcow account password]

**Option B: Create Dedicated Account (Recommended)**

1. Access Mailcow Admin: `https://mail.inlock.ai/admin`
2. Login with Mailcow admin credentials
3. Create a dedicated system account:
   - Email: `no-reply@inlock.ai` or `auth@inlock.ai`
   - Password: [Generate a strong password]
   - Quota: minimal (for system emails)
4. Save the account

### Step 2: Test Mailcow SMTP Connection

Before configuring Auth0, verify Mailcow SMTP is accessible:

```bash
# Test SMTP port 587 (STARTTLS)
openssl s_client -connect mail.inlock.ai:587 -starttls smtp

# Test SMTP port 465 (SSL/TLS)
openssl s_client -connect mail.inlock.ai:465
```

### Step 3: Configure Auth0 Custom SMTP

1. **Access Auth0 Dashboard:**
   - Go to: https://manage.auth0.com/
   - Select tenant: `comzis.eu.auth0.com`

2. **Navigate to Email Provider:**
   - Branding → Email Provider

3. **Select Custom SMTP:**
   - Switch from “Auth0 Email Service” to “Custom SMTP”

4. **Fill in SMTP Configuration:**

   **Connection Settings:**
   ```
   SMTP Host: mail.inlock.ai
   SMTP Port: 587
   ```

   **Authentication:**
   ```
   Username: admin@inlock.ai (or dedicated account)
   Password: [Mailcow account password]
   ```

   **Email Settings:**
   ```
   From Email Address: no-reply@inlock.ai
   From Name: Inlock AI
   ```

   **Security Settings:**
   - Requires Authentication: Yes
   - Requires TLS/SSL: Yes
   - Encryption: STARTTLS (port 587) or SSL/TLS (port 465)

5. **Test Connection:**
   - Use Auth0’s “Send test email”
   - Verify email is received

6. **Save Configuration**

---

## 🔍 Verification Steps

### 1. Test Password Reset Email
1. Request reset: https://comzis.eu.auth0.com/u/reset-password  
2. Enter your email (e.g., `admin@inlock.ai`)  
3. Check inbox for reset email (sender `no-reply@inlock.ai`)

### 2. Check Headers and Deliverability
- Verify SPF/DKIM/DMARC pass on the received message
- Confirm `Received:` path shows `mail.inlock.ai`

### 3. Check Mailcow Logs (optional)
```bash
# Inspect Mailcow mail logs (on server)
journalctl -u docker | grep mailcow
```

---

## 🔒 Security Best Practices

1. Use a dedicated SMTP account (e.g., `auth@inlock.ai`)
2. Store the SMTP password securely (vault/secret manager)
3. Enable STARTTLS (587) or SSL/TLS (465)
4. Keep DNS records aligned (MX/SPF/DKIM/DMARC)

---

## 📊 Mailcow SMTP Configuration Reference

```
Host: mail.inlock.ai
Port: 587 (STARTTLS) or 465 (SSL/TLS)
Security: STARTTLS or SSL/TLS
Authentication: Required
Username: [your-email]@inlock.ai
Password: [your-mailcow-password]
From: no-reply@inlock.ai
```

---

## 📝 Configuration Checklist

- [ ] Mailcow operational at `mail.inlock.ai`
- [ ] SMTP account exists and tested (587/465 reachable)
- [ ] Auth0 Email Provider set to Custom SMTP (Mailcow)
- [ ] Test email sent and received
- [ ] SPF/DKIM/DMARC passing

---

## 🔗 Quick Links

- Auth0 Email Provider: https://manage.auth0.com/dashboard/us/comzis/emails/provider
- Mailcow Admin: https://mail.inlock.ai/admin
- Mailcow Webmail: https://mail.inlock.ai
- Password Reset: https://comzis.eu.auth0.com/u/reset-password

---

**Last Updated:** December 29, 2025  
**Mail Stack:** Mailcow (`mail.inlock.ai`)

