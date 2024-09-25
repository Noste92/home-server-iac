#!/bin/sh

BOT_TOKEN=

# Setting this, so the repo does not need to be given on the commandline:
export BORG_REPO=/home/noste/network-drive/BorgRepo # TODO: sarebbe da parametrizzare

# See the section "Passphrase notes" for more infos.
# export BORG_PASSPHRASE='XYZl0ngandsecurepa_55_phrasea&&123' non necessaria

# some helpers and error handling:
info() { printf "\n%s %s\n\n" "$( TZ='Europe/Rome' date )" "$*" >&2; }
trap 'echo $( TZ="Europe/Rome" date ) Backup interrupted >&2; exit 2' INT TERM

info "Starting backup"

info "Creating DBs DUMP"
docker exec -t immich_postgres pg_dumpall --clean --if-exists --username=postgres | gzip > "/home/noste/immich/dump.sql.gz"

info "Copy Traefik files from container"
docker cp traefik-traefik-1:/acme.json /home/noste/traefik/acme.backup.json
# Backup the most important directories into an archive named after
# the machine this script is currently running on:
# Sarebbero da parametrizzare le folder

borg create                         \
    --info                       \
    --filter AME                    \
    --stats                         \
    --show-rc                       \
    --compression lz4               \
    ::'{hostname}-{now:%Y-%m-%d}'            \
    /home/noste/traefik/acme.backup.json \
    /home/noste/immich/library/upload/ \
    /home/noste/immich/library/upload/ \
    /home/noste/immich/dump.sql.gz \

backup_exit=$?

info "Pruning repository"

# Use the `prune` subcommand to maintain 7 daily, 4 weekly and 6 monthly
# archives of THIS machine. The '{hostname}-*' matching is very important to
# limit prune's operation to this machine's archives and not apply to
# other machines' archives also:

borg prune                          \
    --list                          \
    --glob-archives '{hostname}-*'  \
    --show-rc                       \
    --keep-daily    7               \
    --keep-weekly   4               \
    --keep-monthly  6

prune_exit=$?

# actually free repo disk space by compacting segments

info "Compacting repository"

borg compact

compact_exit=$?

# use highest exit code as global exit code
global_exit=$(( backup_exit > prune_exit ? backup_exit : prune_exit ))
global_exit=$(( compact_exit > global_exit ? compact_exit : global_exit ))

if [ ${global_exit} -eq 0 ]; then
    MESSAGE="SUCCESS: Backup, Prune, and Compact finished successfully"
elif [ ${global_exit} -eq 1 ]; then
    MESSAGE="OK: Backup, Prune, and/or Compact finished with warnings"
else
    MESSAGE="ERROR: Backup, Prune, and/or Compact finished with errors"
fi
info ${MESSAGE}

curl -X POST \
     -H 'Content-Type: application/json' \
     -d "{\"chat_id\": \"-4520644600\", \"text\": \"${MESSAGE}\"}" \
     https://api.telegram.org/${BOT_TOKEN}/sendMessage

exit ${global_exit}
