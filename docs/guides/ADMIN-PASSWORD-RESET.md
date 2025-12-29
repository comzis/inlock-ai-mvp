# Admin Password Reset Guide

**Date:** December 29, 2025  
**Status:** Active Guide

---

## 🔐 Overview

All admin services use **Auth0** for authentication. Password reset is handled through Auth0's password reset flow.

---

## 🚀 Quick Password Reset

### Method 1: Via Auth0 Password Reset Link (Recommended)

**Direct Password Reset URL:**
```
https://comzis.eu.auth0.com/u/reset-password
```

**Steps:**
1. Visit the password reset link above
2. Enter your admin email address (e.g., `admin@inlock.ai`)
3. Check your email for the password reset link
4. Click the link in the email
5. Enter your new password
6. Sign in with your new password

---

### Method 2: Via Application Login Page

**Frontend Application:**
1. Visit: `https://inlock.ai/auth/login`
2. Click "Forgot Password?" or "Reset Password" link
3. Enter your email address
4. Check your email for the reset link
5. Follow the email instructions

**Admin Services (Traefik, Grafana, Portainer, n8n):**
1. Visit any admin service (e.g., `https://grafana.inlock.ai`)
2. You'll be redirected to Auth0 login
3. Click "Forgot Password?" link on the Auth0 login page
4. Enter your email address
5. Check your email for the reset link
6. Follow the email instructions

---

## 📧 Admin Email Address

The admin email address used for authentication is typically:
- `admin@inlock.ai` (or your configured admin email in Auth0)

---

## 🔍 Verify Your Auth0 Account

**Check Your Auth0 Account:**
1. Go to: [Auth0 Dashboard](https://manage.auth0.com/)
2. Select tenant: `comzis.eu.auth0.com`
3. Navigate to: **User Management → Users**
4. Search for your email address
5. Verify account status and email is correct

---

## 🔄 Alternative: Admin Password Reset via Auth0 Dashboard

If you have access to the Auth0 Dashboard:

1. **Go to Auth0 Dashboard:**
   - URL: https://manage.auth0.com/
   - Select tenant: `comzis.eu.auth0.com`

2. **Navigate to User Management:**
   - Click **User Management** → **Users**
   - Search for the admin user email

3. **Change Password:**
   - Click on the user
   - Click **Change Password** tab
   - Enter new password
   - Click **Change Password**
   - User will be notified via email

4. **Or Send Password Reset Email:**
   - Click on the user
   - Click **Actions** → **Send Password Reset Email**
   - User will receive a password reset email

---

## 🛠️ Troubleshooting

### Issue: Not Receiving Password Reset Email

**Solutions:**
1. Check spam/junk folder
2. Verify email address is correct in Auth0
3. Check Auth0 email provider settings
   - Auth0 should be configured to use Mailcow SMTP
   - See: `docs/guides/AUTH0-MAILCOW-SMTP-CONFIGURATION.md` for configuration details
4. Try resending from Auth0 Dashboard
5. Check Auth0 Dashboard → Logs → Email for delivery status

### Issue: Password Reset Link Expired

**Solution:**
- Request a new password reset link (they typically expire after 24 hours)

### Issue: Can't Access Auth0 Dashboard

**Solution:**
- Use the direct password reset link: `https://comzis.eu.auth0.com/u/reset-password`

---

## 🔒 Service-Specific Password Resets

### Grafana Admin Password

If you need to reset Grafana's internal admin password (separate from Auth0):

```bash
docker exec -it compose-grafana-1 grafana-cli admin reset-admin-password NEW_PASSWORD
```

**Note:** Grafana uses Auth0 for authentication, so this is only needed if accessing Grafana directly without Auth0.

---

### Portainer Admin Password

Portainer uses Auth0 for authentication. Reset your password via Auth0 using the methods above.

---

### n8n User Password

n8n uses Auth0 for authentication. Reset your password via Auth0 using the methods above.

---

## 📚 Related Documentation

- **Auth0 Quick Reference:** `docs/reference/AUTH0-QUICK-REFERENCE.md`
- **Authentication Flow:** `docs/services/auth0/AUTH0-AUTHENTICATION-FLOW.md`
- **Credentials Recovery:** `docs/CREDENTIALS-RECOVERY.md`
 - **Configure Mailcow for Auth0 Emails:** `docs/guides/AUTH0-MAILCOW-SMTP-CONFIGURATION.md`

---

## 🔗 Quick Links

- **Password Reset:** https://comzis.eu.auth0.com/u/reset-password
- **Auth0 Dashboard:** https://manage.auth0.com/
- **Login Page:** https://inlock.ai/auth/login
- **Traefik Dashboard:** https://traefik.inlock.ai/dashboard/
- **Grafana:** https://grafana.inlock.ai
- **Portainer:** https://portainer.inlock.ai
- **n8n:** https://n8n.inlock.ai

---

**Last Updated:** December 29, 2025  
**Auth0 Tenant:** `comzis.eu.auth0.com`

