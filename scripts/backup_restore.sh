#!/bin/sh
# /usr/local/bin/restore_runner.sh
# Запускать на контейнере с доступом к PostgreSQL/Citus

if [ "$ROLE" != "backup" ]; then
    echo "$(date) >>> ROLE is not backup, skipping backup runner."
    exit 0
fi

CONFIRM_PASS="${RESTORE_CONFIRM_PASS:-}"

if [ -z "$CONFIRM_PASS" ]; then
    echo ">>> ERROR: RESTORE_CONFIRM_PASS не задан!"
    exit 1
fi

# Получаем пароль: аргумент
if [ -n "$1" ]; then
    INPUT_PASS="$1"
else
	echo ">>> ERROR: No password provided. Backup restore canceled."
    exit 1
fi

# go further

if [ -z "$RESTORE_DB" ]; then
    echo "ERROR: RESTORE_DB variable not set"
    exit 1
fi

BACKUP_DIR=${BACKUP_DIR:-/backups}
BACKUP_FILE=$(ls -t "$BACKUP_DIR/${RESTORE_DB}_"*.sql.gz | head -n1)

if [ ! -f "$BACKUP_FILE" ]; then
    echo "ERROR: Backup file for $RESTORE_DB not found in $BACKUP_DIR"
    exit 1
fi

echo "$(date) >>> Restoring $RESTORE_DB from $BACKUP_FILE..."

# Удаляем базу, если существует
psql -h "$COORDINATOR_HOST" -U "$POSTGRES_USER" -d postgres -c "DROP DATABASE IF EXISTS \"$RESTORE_DB\" WITH (FORCE);"

# Создаём базу, если не существует
psql -h "$COORDINATOR_HOST" -U "$POSTGRES_USER" -d postgres -c "CREATE DATABASE $RESTORE_DB;" 2>/dev/null

# Восстановление
gunzip -c "$BACKUP_FILE" | psql -h "$COORDINATOR_HOST" -U "$POSTGRES_USER" -d "$RESTORE_DB"

SERVER_ID="${SERVER_ID:-na}"

if [ $? -eq 0 ]; then
    echo "$(date) >>> Restore of $RESTORE_DB finished successfully."

	if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
        curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
            -d chat_id="$TELEGRAM_CHAT_ID" \
            -d text="Restore of $RESTORE_DB finished successfully on server $SERVER_ID. $(date)"
    fi
else
    echo "$(date) >>> ERROR: Restore of $RESTORE_DB failed!"
	if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
        curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
            -d chat_id="$TELEGRAM_CHAT_ID" \
            -d text="ERROR: Restore of $RESTORE_DB failed on server $SERVER_ID! $(date)"
    fi
fi

#
# in container baackup - run:
# /usr/local/bin/backup_restore.sh pass
# pass here is RESTORE_CONFIRM_PASS from env
# 
