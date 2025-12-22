#!/bin/bash
set -euo pipefail
ENV_FILE="/home/comzis/projects/inlock-ai-mvp/.env"
source "$ENV_FILE"

ZONE_ID="8d7c44f4c4a25263d10b87f394bc9076" # From previous run logs

create_srv() {
    name=$1
    service=$2
    proto=$3
    port=$4
    target=$5
    priority=$6
    weight=$7
    
    echo "Processing SRV: $service.$proto.$name"
    # Construct SRV specific data
    data="{\"type\":\"SRV\",\"name\":\"$service.$proto.$name\",\"data\":{\"service\":\"$service\",\"proto\":\"$proto\",\"name\":\"$name\",\"priority\":$priority,\"weight\":$weight,\"port\":$port,\"target\":\"$target\"},\"ttl\":600}"
    
    curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records"         -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN"         -H "Content-Type: application/json"         -d "$data" | grep '"success":true' && echo "Success" || echo "Failed"
}

create_cname() {
    name=$1
    content=$2
    echo "Processing CNAME: $name"
    data="{\"type\":\"CNAME\",\"name\":\"$name\",\"content\":\"$content\",\"ttl\":600}"
    curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records"         -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN"         -H "Content-Type: application/json"         -d "$data" | grep '"success":true' && echo "Success" || echo "Failed"
}

# _imap._tcp.inlock.ai. 600 IN SRV 20 1 143 mail.inlock.ai.
create_srv "inlock.ai" "_imap" "_tcp" 143 "mail.inlock.ai" 20 1

# _pop3._tcp.inlock.ai. 600 IN SRV 20 1 110 mail.inlock.ai.
create_srv "inlock.ai" "_pop3" "_tcp" 110 "mail.inlock.ai" 20 1

# _submission._tcp.inlock.ai. 600 IN SRV 20 1 587 mail.inlock.ai.
create_srv "inlock.ai" "_submission" "_tcp" 587 "mail.inlock.ai" 20 1

# autoconfig.inlock.ai. 600 IN CNAME mail.inlock.ai.
create_cname "autoconfig.inlock.ai" "mail.inlock.ai"
