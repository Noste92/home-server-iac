# ESEMPIO DA MODIFICARE AD HOC far girare dalla root / non nella home

# if [ -f /home/noste/offsite-drive/BorgRepo ]
# then
#     echo "Rclone mount presente" 
# else
#     echo rclone mount offsite_drive:/ offsite-drive/ &
# fi

borg extract --list /home/noste/network-drive/BorgRepo::CHANGE_ME 

### Traefik ACME restore
docker cp /home/noste/traefik/acme.backup.json traefik-traefik-1:/acme.json

### Immich restore
cd /home/noste/immich
docker compose down -v  # CAUTION! Deletes all Immich data to start from scratch.
rm -rf /home/noste/immich/postgres # CAUTION! Deletes all Immich data to start from scratch.
mkdir /home/noste/immich/postgres
docker compose create   # Create Docker containers for Immich apps without running them.
docker start immich_postgres    # Start Postgres server
sleep 10 # Waite for Postgres to start
gunzip < "/home/noste/immich/dump.sql.gz" \
| sed "s/SELECT pg_catalog.set_config('search_path', '', false);/SELECT pg_catalog.set_config('search_path', 'public, pg_catalog', true);/g" \
| docker exec -i immich_postgres psql --username=postgres    # Restore Backup
docker compose up -d    