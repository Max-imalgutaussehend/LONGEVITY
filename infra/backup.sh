#!/bin/sh
# Daily backup — run via cron: 0 2 * * * /opt/longevity/infra/backup.sh
set -e

BACKUP_DIR="/opt/longevity/backups"
DATE=$(date +%Y%m%d_%H%M%S)
FILE="$BACKUP_DIR/longevity_$DATE.sql.gz"

mkdir -p "$BACKUP_DIR"

docker exec longevity-db-1 pg_dump -U longevity longevity | gzip > "$FILE"

# Retain last 7 days
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +7 -delete

echo "Backup written to $FILE"
