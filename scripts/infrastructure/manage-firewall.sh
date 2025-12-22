#!/usr/bin/env bash
# Firewall Management Script
# Provides convenient commands for managing UFW firewall

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACTION="${1:-help}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
check_root() {
  if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script requires root privileges.${NC}"
    echo "Run with: sudo $0 $*"
    exit 1
  fi
}

# Show help
show_help() {
  cat << EOF
Firewall Management Script

Usage: sudo $0 <command> [options]

Commands:
  status          Show firewall status (verbose)
  list            List all rules (numbered)
  allow <port>    Allow a port (TCP)
  allow-udp <port> Allow a port (UDP)
  deny <port>     Remove allow rule for a port
  reload          Reload firewall rules
  enable          Enable firewall
  disable         Disable firewall (use with caution!)
  reset           Reset firewall to defaults (removes all rules)
  logs            Show recent firewall logs
  audit           Create audit backup of current rules

Examples:
  sudo $0 status
  sudo $0 allow 8080
  sudo $0 allow-udp 41641
  sudo $0 deny 8080
  sudo $0 list
  sudo $0 logs

EOF
}

# Show status
show_status() {
  check_root
  echo -e "${GREEN}=== Firewall Status ===${NC}"
  ufw status verbose
}

# List rules
list_rules() {
  check_root
  echo -e "${GREEN}=== Firewall Rules (Numbered) ===${NC}"
  ufw status numbered
}

# Allow port
allow_port() {
  check_root
  PORT="${2:-}"
  PROTO="${3:-tcp}"
  COMMENT="${4:-Service}"
  
  if [ -z "$PORT" ]; then
    echo -e "${RED}Error: Port number required${NC}"
    echo "Usage: sudo $0 allow <port> [protocol] [comment]"
    exit 1
  fi
  
  echo -e "${YELLOW}Allowing port $PORT/$PROTO...${NC}"
  ufw allow ${PORT}/${PROTO} comment "$COMMENT"
  echo -e "${GREEN}✓ Port $PORT/$PROTO allowed${NC}"
  echo ""
  echo "Current status:"
  ufw status | grep "$PORT"
}

# Allow UDP port
allow_udp_port() {
  check_root
  PORT="${2:-}"
  COMMENT="${3:-Service}"
  
  if [ -z "$PORT" ]; then
    echo -e "${RED}Error: Port number required${NC}"
    echo "Usage: sudo $0 allow-udp <port> [comment]"
    exit 1
  fi
  
  echo -e "${YELLOW}Allowing UDP port $PORT...${NC}"
  ufw allow ${PORT}/udp comment "$COMMENT"
  echo -e "${GREEN}✓ Port $PORT/udp allowed${NC}"
  echo ""
  echo "Current status:"
  ufw status | grep "$PORT"
}

# Deny port (remove allow rule)
deny_port() {
  check_root
  PORT="${2:-}"
  PROTO="${3:-tcp}"
  
  if [ -z "$PORT" ]; then
    echo -e "${RED}Error: Port number required${NC}"
    echo "Usage: sudo $0 deny <port> [protocol]"
    exit 1
  fi
  
  echo -e "${YELLOW}Removing allow rule for port $PORT/$PROTO...${NC}"
  
  # Try to delete by specification first
  if ufw delete allow ${PORT}/${PROTO} 2>/dev/null; then
    echo -e "${GREEN}✓ Rule removed${NC}"
  else
    echo -e "${YELLOW}Could not delete by specification. Showing numbered rules:${NC}"
    ufw status numbered | grep -E "($PORT|$PROTO)" || true
    echo ""
    echo "Please delete manually using: sudo ufw delete <number>"
  fi
}

# Reload firewall
reload_firewall() {
  check_root
  echo -e "${YELLOW}Reloading firewall...${NC}"
  ufw reload
  echo -e "${GREEN}✓ Firewall reloaded${NC}"
}

# Enable firewall
enable_firewall() {
  check_root
  echo -e "${YELLOW}Enabling firewall...${NC}"
  ufw --force enable
  echo -e "${GREEN}✓ Firewall enabled${NC}"
}

# Disable firewall
disable_firewall() {
  check_root
  echo -e "${RED}WARNING: This will disable the firewall!${NC}"
  read -p "Are you sure? (yes/no): " confirm
  if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 0
  fi
  echo -e "${YELLOW}Disabling firewall...${NC}"
  ufw disable
  echo -e "${RED}⚠ Firewall disabled${NC}"
}

# Reset firewall
reset_firewall() {
  check_root
  echo -e "${RED}WARNING: This will remove ALL firewall rules!${NC}"
  read -p "Are you sure? (yes/no): " confirm
  if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 0
  fi
  echo -e "${YELLOW}Resetting firewall...${NC}"
  ufw --force reset
  echo -e "${GREEN}✓ Firewall reset${NC}"
  echo ""
  echo "You should now reconfigure the firewall using:"
  echo "  sudo ./scripts/apply-firewall-manual.sh"
  echo "  or"
  echo "  ansible-playbook playbooks/hardening.yml"
}

# Show logs
show_logs() {
  check_root
  LINES="${2:-50}"
  echo -e "${GREEN}=== Recent Firewall Logs (last $LINES lines) ===${NC}"
  tail -n "$LINES" /var/log/ufw.log 2>/dev/null || echo "No firewall logs found"
}

# Audit firewall
audit_firewall() {
  check_root
  BACKUP_DIR="$SCRIPT_DIR/../backups"
  DATE=$(date +%Y%m%d-%H%M%S)
  BACKUP_FILE="$BACKUP_DIR/firewall-rules-$DATE.txt"
  
  mkdir -p "$BACKUP_DIR"
  
  echo -e "${YELLOW}Creating firewall audit backup...${NC}"
  ufw status numbered > "$BACKUP_FILE"
  echo -e "${GREEN}✓ Backup created: $BACKUP_FILE${NC}"
  
  # Compare with previous if exists
  PREVIOUS=$(ls -t "$BACKUP_DIR"/firewall-rules-*.txt 2>/dev/null | head -2 | tail -1)
  if [ -n "$PREVIOUS" ] && [ "$PREVIOUS" != "$BACKUP_FILE" ]; then
    echo ""
    echo "Comparing with previous backup:"
    diff "$PREVIOUS" "$BACKUP_FILE" || echo "No differences found"
  fi
}

# Main command handler
case "$ACTION" in
  help|--help|-h)
    show_help
    ;;
  status)
    show_status
    ;;
  list)
    list_rules
    ;;
  allow)
    allow_port "$@"
    ;;
  allow-udp)
    allow_udp_port "$@"
    ;;
  deny)
    deny_port "$@"
    ;;
  reload)
    reload_firewall
    ;;
  enable)
    enable_firewall
    ;;
  disable)
    disable_firewall
    ;;
  reset)
    reset_firewall
    ;;
  logs)
    show_logs "$@"
    ;;
  audit)
    audit_firewall
    ;;
  *)
    echo -e "${RED}Unknown command: $ACTION${NC}"
    echo ""
    show_help
    exit 1
    ;;
esac










