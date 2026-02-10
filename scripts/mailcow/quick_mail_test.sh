#!/bin/bash
# Quick Mail Server Test - Minimal Output

DOMAIN="mail.inlock.ai"

echo "Quick Mail Server Test - $DOMAIN"
echo "================================"
echo ""

# DNS
echo -n "DNS: "
dig +short $DOMAIN 2>&1 | head -1 || echo "FAIL"

# IMAP Port
echo -n "IMAP (993): "
timeout 3 nc -zv $DOMAIN 993 2>&1 | grep -q "succeeded" && echo "OK" || echo "FAIL"

# IMAP SSL
echo -n "IMAP SSL: "
timeout 3 openssl s_client -connect $DOMAIN:993 -servername $DOMAIN 2>&1 | grep -q "Verify return code: 0" && echo "OK" || echo "FAIL"

# SMTP Port 465
echo -n "SMTP (465): "
timeout 3 nc -zv $DOMAIN 465 2>&1 | grep -q "succeeded" && echo "OK" || echo "FAIL"

# SMTP SSL
echo -n "SMTP SSL: "
timeout 3 openssl s_client -connect $DOMAIN:465 -servername $DOMAIN 2>&1 | grep -q "Verify return code: 0" && echo "OK" || echo "FAIL"

# HTTPS
echo -n "HTTPS: "
timeout 3 curl -I -s https://$DOMAIN 2>&1 | head -1 | grep -q "HTTP" && echo "OK" || echo "FAIL"

echo ""
echo "Your IP: 31.10.147.220"
echo "Check if blocked: ssh comzis@100.83.222.69 'sudo iptables -L -n | grep 31.10.147.220'"
