# Auth0 + Mailcow SMTP Quick Reference

**Date:** December 29, 2025  
**Purpose:** Quick reference for Auth0 Mailcow SMTP configuration

---

## 🔗 Quick Links

- Auth0 Email Provider: https://manage.auth0.com/dashboard/us/comzis/emails/provider
- Mailcow Admin: https://mail.inlock.ai/admin
- Mailcow Webmail: https://mail.inlock.ai
- Full Guide: `docs/guides/AUTH0-MAILCOW-SMTP-CONFIGURATION.md`

---

## ⚙️ SMTP Settings for Auth0

```
Host: mail.inlock.ai
Port: 587 (STARTTLS) or 465 (SSL/TLS)
Username: admin@inlock.ai (or dedicated account)
Password: [Mailcow account password]
From Email: no-reply@inlock.ai
From Name: Inlock AI
Encryption: STARTTLS (port 587) or SSL/TLS (port 465)
Authentication: Required
```

---

## 📝 Configuration Steps (Quick)

1) Auth0 Dashboard → Branding → Email Provider  
2) Select “Custom SMTP”  
3) Enter SMTP settings above  
4) Send a test email → verify receipt  
5) Save

---

## 🧪 Test Script (optional)

```bash
# Test Mailcow SMTP before configuring Auth0
./scripts/auth/test-mailu-smtp-for-auth0.sh admin@inlock.ai 'your-password'
```
(Script name still present; use Mailcow credentials and host.)

---

## ✅ Verification

After configuration:
1. Test password reset: https://comzis.eu.auth0.com/u/reset-password  
2. Check inbox; verify From=`no-reply@inlock.ai`  
3. Verify SPF/DKIM/DMARC pass
4. Check Mailcow logs if needed

---

## 🔒 Security Notes

- Use a dedicated SMTP account (e.g., `auth@inlock.ai`)
- Store credentials securely
- Ensure ports 587/465 are accessible
- Keep SPF/DKIM/DMARC aligned with Mailcow

---

**Last Updated:** December 29, 2025

