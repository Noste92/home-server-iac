#!/bin/sh

BOT_TOKEN=

# some helpers and error handling:
info() { printf "\n%s %s\n\n" "$( TZ='Europe/Rome' date )" "$*" >&2; }

info "Starting offsite backup"

if rclone sync network-drive/BorgRepo/ offsite_drive:/BorgRepo ; then
    MESSAGE="SUCCESS: Successfully sync the BorgRepo remotely"
else
    MESSAGE="FAILED: Failed to sync the BorgRepo remotely"
fi

info ${MESSAGE}

curl -X POST \
     -H 'Content-Type: application/json' \
     -d "{\"chat_id\": \"-4520644600\", \"text\": \"${MESSAGE}\"}" \
     https://api.telegram.org/${BOT_TOKEN}/sendMessage
