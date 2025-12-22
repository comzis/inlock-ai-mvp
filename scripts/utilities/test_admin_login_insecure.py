import imaplib
import ssl

username = "admin@inlock.ai"
password = "2HhPB7Tp/fmIbeoR9DbC4YlPxFsv9w7tMdH2lWsjbMQ="
host = "mail.inlock.ai"
port = 993

print(f"Connecting to {host}:{port}...")
try:
    context = ssl.create_default_context()
    context.check_hostname = False
    context.verify_mode = ssl.CERT_NONE
    
    server = imaplib.IMAP4_SSL(host, port, ssl_context=context)
    print("Connected. Logging in...")
    server.login(username, password)
    print("SUCCESS: Login successful!")
    server.logout()
except Exception as e:
    print(f"FAILED: {e}")
