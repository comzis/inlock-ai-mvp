#!/bin/bash
set -euo pipefail
ENV_FILE="/home/comzis/projects/inlock-ai-mvp/.env"
source "$ENV_FILE"

ZONE_ID="8d7c44f4c4a25263d10b87f394bc9076"

create_txt() {
    name=$1
    content=$2
    echo "Processing TXT: $name"
    data="{\"type\":\"TXT\",\"name\":\"$name\",\"content\":\"$content\",\"ttl\":600}"
    
    # Try to create first
    response=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records"         -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN"         -H "Content-Type: application/json"         -d "$data")

    if echo "$response" | grep -q '"success":true'; then
        echo "Success (Created)"
    elif echo "$response" | grep -q 'Record already exists'; then
        echo "Record exists, finding ID to update..."
        rec_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=TXT&name=$name.$DOMAIN"             -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
        
        if [ -n "$rec_id" ]; then
             curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$rec_id"                 -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN"                 -H "Content-Type: application/json"                 -d "$data" | grep '"success":true' && echo "Success (Updated)" || echo "Update Failed"
        else
            # Try searching without domain suffix if name is just subdomain
            rec_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=TXT&name=$name"                 -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
             if [ -n "$rec_id" ]; then
                 curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$rec_id"                     -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN"                     -H "Content-Type: application/json"                     -d "$data" | grep '"success":true' && echo "Success (Updated)" || echo "Update Failed"
             else
                echo "Failed to find record ID for update"
             fi
        fi
    else
        echo "Failed: $response"
    fi
}

# DKIM Record
# Concatenated value from user paste
DKIM_VAL="v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAjXbTmnP2QzYN0nHFCa3Mt85N87e2gY+k2gZaZB/Q09O13AFXiJxoNwIzza+Y5dqIDgIfR6iteCEilY15WddvYybOgsZlQX53Nomtwn1qasghMNolTtTpqzDEzgfL+nn1O3SB3h5hgxbkx4q0g1p7m3Ee87qYYjRn0tfytZHiAucYmohKyHcqewRW6tWdv5txSkeBYsvOllyvFX/F8+Pl3pA/y9HnEqKba1Le3uvfxWGfhgGp7BIx6Lfx0U4G4l2NBTEolcnQJHWGdpoMfXN3SPS/NevAR3KY2BOuNUVXIPCDgjV3q9iYPtA7sn7/CeQ+9mrm37DjjlqMVvLdKGCtuQIDAQAB"

create_txt "dkim._domainkey" "$DKIM_VAL"

# DMARC Record (Update to reject)
DMARC_VAL="v=DMARC1; p=reject; adkim=s; aspf=s"
create_txt "_dmarc" "$DMARC_VAL"

# DMARC Report Record
# Name: inlock.ai._report._dmarc
create_txt "inlock.ai._report._dmarc" "v=DMARC1;"
