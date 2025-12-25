# Mobile Email Setup Guide - iPhone & Android

## 📧 Mail Server Information

### Outgoing Mail Server (SMTP)
- **Server:** `mail.inlock.ai`
- **Port:** `587` (STARTTLS) - **Recommended**
- **Alternative Port:** `465` (SSL/TLS)
- **Security:** STARTTLS (port 587) or SSL/TLS (port 465)
- **Authentication:** Required
- **Username:** Your full email address (e.g., `user@inlock.ai`)
- **Password:** Your email account password

### Incoming Mail Server (IMAP)
- **Server:** `mail.inlock.ai`
- **Port:** `993` (SSL/TLS) - **Recommended**
- **Alternative Port:** `143` (STARTTLS)
- **Security:** SSL/TLS (port 993) or STARTTLS (port 143)
- **Authentication:** Required
- **Username:** Your full email address (e.g., `user@inlock.ai`)
- **Password:** Your email account password

### Port Summary
- **IMAP (Incoming):** 993 (SSL/TLS) or 143 (STARTTLS)
- **SMTP (Outgoing):** 587 (STARTTLS) or 465 (SSL/TLS)

**Recommended Configuration:**
- **IMAP:** Port 993 with SSL/TLS
- **SMTP:** Port 587 with STARTTLS

---

## 📱 iPhone/iOS Setup Instructions

### Method 1: Automatic Setup (Recommended)

1. **Open Settings** on your iPhone/iPad
2. Go to **Mail** → **Accounts**
3. Tap **Add Account**
4. Select **Other** (at the bottom of the list)
5. Tap **Add Mail Account**
6. Enter your account information:
   - **Name:** Your display name
   - **Email:** `your-email@inlock.ai`
   - **Password:** Your email password
   - **Description:** (optional) e.g., "Inlock Mail"
7. Tap **Next**
8. Select **IMAP**
9. Enter the following settings:

   **Incoming Mail Server (IMAP):**
   - **Host Name:** `mail.inlock.ai`
   - **User Name:** `your-email@inlock.ai`
   - **Password:** Your email password

   **Outgoing Mail Server (SMTP):**
   - **Host Name:** `mail.inlock.ai`
   - **User Name:** `your-email@inlock.ai`
   - **Password:** Your email password

10. Tap **Next**
11. iOS will verify the settings. If prompted:
    - Ensure **Use SSL** is enabled for IMAP
    - Ensure **Use Authentication** is enabled for SMTP
12. Select which apps to sync (Mail, Contacts, Calendars, Notes)
13. Tap **Save**

### Method 2: Manual Advanced Setup

If automatic setup fails, use manual configuration:

1. **Settings** → **Mail** → **Accounts** → **Add Account** → **Other** → **Add Mail Account**
2. Enter basic info and tap **Next**
3. Select **IMAP**
4. Scroll down and tap **SMTP** under "Outgoing Mail Server"
5. Tap the primary server and configure:

   **IMAP Settings:**
   - **Host Name:** `mail.inlock.ai`
   - **User Name:** `your-email@inlock.ai`
   - **Password:** Your email password
   - **Use SSL:** ON
   - **Port:** `993`

   **SMTP Settings:**
   - **Host Name:** `mail.inlock.ai`
   - **User Name:** `your-email@inlock.ai`
   - **Password:** Your email password
   - **Use SSL:** ON (or OFF if using STARTTLS)
   - **Port:** `587` (or `465` for SSL)
   - **Authentication:** Password

6. Tap **Done** and **Save**

### Troubleshooting iPhone Setup

**If connection fails:**
- Verify you're using the full email address as username (e.g., `user@inlock.ai`, not just `user`)
- Check that SSL/TLS is enabled
- Try port 465 for SMTP if 587 doesn't work
- Ensure your device has internet connectivity
- Check that the firewall allows ports 587, 465, 993, and 143

---

## 🤖 Android Setup Instructions

### Method 1: Gmail App (Recommended)

1. **Open Gmail app** (or your preferred email app)
2. Tap the **menu icon** (three lines) → **Settings**
3. Tap **Add account** → **Other**
4. Enter your email address: `your-email@inlock.ai`
5. Tap **Next**
6. Select **Personal (IMAP)** or **Personal (POP3)** - **IMAP is recommended**
7. Enter your password and tap **Next**

8. **Configure Incoming Server Settings:**
   - **IMAP Server:** `mail.inlock.ai`
   - **Port:** `993`
   - **Security Type:** SSL/TLS (or STARTTLS)
   - **Username:** `your-email@inlock.ai`
   - **Password:** Your email password

9. Tap **Next**

10. **Configure Outgoing Server Settings:**
    - **SMTP Server:** `mail.inlock.ai`
    - **Port:** `587`
    - **Security Type:** STARTTLS (or SSL/TLS for port 465)
    - **Username:** `your-email@inlock.ai`
    - **Password:** Your email password
    - **Require sign-in:** Yes

11. Tap **Next**
12. Configure account options (sync frequency, notifications)
13. Tap **Next** → **Done**

### Method 2: Android Email App (Stock)

1. **Open Email app** (or **Settings** → **Accounts** → **Add Account**)
2. Select **Other** or **Manual Setup**
3. Enter your email address and password
4. Select **IMAP** account type
5. Configure settings:

   **Incoming Server:**
   - **IMAP Server:** `mail.inlock.ai`
   - **Port:** `993`
   - **Security Type:** SSL/TLS
   - **Username:** `your-email@inlock.ai`
   - **Password:** Your email password

   **Outgoing Server:**
   - **SMTP Server:** `mail.inlock.ai`
   - **Port:** `587`
   - **Security Type:** STARTTLS
   - **Username:** `your-email@inlock.ai`
   - **Password:** Your email password
   - **Require Authentication:** Yes

6. Tap **Next** or **Sign In**
7. Configure sync settings and notifications
8. Tap **Done** or **Finish**

### Method 3: Third-Party Apps (Outlook, K-9 Mail, etc.)

**For Outlook App:**
1. Open Outlook app
2. Tap **Get Started** or **Add Account**
3. Enter email: `your-email@inlock.ai`
4. Tap **Add Account**
5. Enter password
6. If automatic setup fails, tap **Advanced** or **Manual Setup**
7. Select **IMAP**
8. Enter server settings as above

**For K-9 Mail:**
1. Open K-9 Mail
2. Tap **Add Account**
3. Enter email and password
4. Tap **Manual Setup**
5. Select **IMAP**
6. Configure:
   - **IMAP Server:** `mail.inlock.ai`
   - **IMAP Port:** `993`
   - **Security:** SSL/TLS
   - **SMTP Server:** `mail.inlock.ai`
   - **SMTP Port:** `587`
   - **Security:** STARTTLS
   - **Username:** Full email address
   - **Password:** Your password

### Troubleshooting Android Setup

**If connection fails:**
- Ensure you're using the full email address as username
- Verify SSL/TLS settings match the port (993 = SSL, 587 = STARTTLS)
- Try alternative ports (465 for SMTP, 143 for IMAP)
- Check device internet connectivity
- Clear app cache and retry
- Some Android versions require "Less secure app access" - this shouldn't be needed with proper SSL/TLS

---

## ✅ Verification Checklist

After setup, verify the following:

- [ ] Can receive emails (incoming mail works)
- [ ] Can send emails (outgoing mail works)
- [ ] SSL/TLS is properly configured (no security warnings)
- [ ] Push notifications work (if enabled)
- [ ] Email syncs automatically
- [ ] Folders are visible and accessible

---

## 🔒 Security Notes

1. **Always use SSL/TLS** for email connections to protect your credentials
2. **Use full email address** as username (e.g., `user@inlock.ai`, not just `user`)
3. **Port 587 with STARTTLS** is recommended for SMTP (better compatibility)
4. **Port 993 with SSL/TLS** is recommended for IMAP (secure and reliable)
5. **Avoid using port 25** for SMTP from mobile devices (often blocked by ISPs)

---

## 📞 Quick Reference Card

```
┌─────────────────────────────────────────┐
│  Inlock Mail Server Settings            │
├─────────────────────────────────────────┤
│  Server: mail.inlock.ai                 │
│                                         │
│  IMAP (Incoming):                       │
│    Port: 993 (SSL/TLS)                 │
│    Alt:  143 (STARTTLS)                │
│                                         │
│  SMTP (Outgoing):                       │
│    Port: 587 (STARTTLS) ← Recommended  │
│    Alt:  465 (SSL/TLS)                 │
│                                         │
│  Username: your-email@inlock.ai        │
│  Password: [your password]             │
│  Auth: Required                        │
└─────────────────────────────────────────┘
```

---

## 🆘 Need Help?

If you encounter issues:

1. **Check service status:**
   ```bash
   cd /home/comzis/mailcow
   docker compose ps
   ```

2. **Verify firewall rules:**
   - Ports 587, 465, 993, 143 should be open

3. **Check Mailcow logs:**
   ```bash
   cd /home/comzis/mailcow
   docker compose logs nginx-mailcow dovecot-mailcow
   ```

4. **Test connectivity:**
   - Use a mail client on desktop first to verify settings
   - Check DNS resolution: `nslookup mail.inlock.ai`

---

*Last Updated: 2025-12-25*
