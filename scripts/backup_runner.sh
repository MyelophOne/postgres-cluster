#!/bin/sh
# /usr/local/bin/backup_runner.sh
# Запускать только на контейнере с ROLE=backup

if [ "$ROLE" != "backup" ]; then
    echo "$(date) >>> ROLE is not backup, skipping backup runner."
    exit 0
fi

BACKUP_DIR="/backups"
LOG_FILE="$BACKUP_DIR/citus_backup.log"
INTERVAL_MIN=${BACKUP_INTERVAL_MIN:-60}
INTERVAL_SEC=$((INTERVAL_MIN * 60))
LOG_MAX_LINES=${LOG_MAX_LINES:-1000}        # Максимум строк лога
BACKUP_RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-7} # Сколько дней хранить бэкапы
MAX_BACKUPS_PER_DB=${MAX_BACKUPS_PER_DB:-3} # Максимальное число бэкапов на базу

# Экспорт пароля для psql и pg_dump
export PGPASSWORD="$POSTGRES_PASSWORD"

mkdir -p "$BACKUP_DIR"

echo "$(date) >>> Citus backup runner started (interval $INTERVAL_MIN min)..." >> "$LOG_FILE"

while true; do
    echo "$(date) >>> Starting Citus backup cycle..." >> "$LOG_FILE"

    # Ждём готовности координатора
    until pg_isready -h "$COORDINATOR_HOST" -p 5432 -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null 2>&1; do
        echo "$(date) >>> Waiting for coordinator $COORDINATOR_HOST..." >> "$LOG_FILE"
        sleep 2
    done

    # Получаем список всех баз данных
    DBS=$(psql -h "$COORDINATOR_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT datname FROM pg_database WHERE datistemplate = false;" | awk '{$1=$1};1')

    for db in $DBS; do
        FILENAME="${db}_$(date +%F_%H-%M-%S).sql.gz"
        echo "$(date) >>> Backing up $db to $FILENAME..." >> "$LOG_FILE"
        pg_dump -h "$COORDINATOR_HOST" -U "$POSTGRES_USER" -d "$db" | gzip > "$BACKUP_DIR/$FILENAME"
        if [ $? -eq 0 ]; then
            echo "$(date) >>> Backup of $db finished." >> "$LOG_FILE"
        else
            echo "$(date) >>> ERROR: Backup of $db failed!" >> "$LOG_FILE"

			SERVER_ID="${SERVER_ID:-na}"

			if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
				curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
					-d chat_id="$TELEGRAM_CHAT_ID" \
					-d text="ERROR: Backup of $db failed on server $SERVER_ID!"
			fi
        fi

        # Ограничиваем число бэкапов на базу
        BACKUPS_FOR_DB=$(ls -1t "$BACKUP_DIR/${db}_"*.sql.gz 2>/dev/null)
        COUNT=$(echo "$BACKUPS_FOR_DB" | wc -l)
        if [ "$COUNT" -gt "$MAX_BACKUPS_PER_DB" ]; then
            TO_DELETE=$(echo "$BACKUPS_FOR_DB" | tail -n $((COUNT - MAX_BACKUPS_PER_DB)))
            for f in $TO_DELETE; do
                rm -f "$f"
                echo "$(date) >>> Deleted old backup $f (max $MAX_BACKUPS_PER_DB per DB)" >> "$LOG_FILE"
            done
        fi
    done

    # Удаляем старые бэкапы по времени
    find "$BACKUP_DIR" -name "*.sql.gz" -type f -mtime +$BACKUP_RETENTION_DAYS -exec rm -f {} \;
    echo "$(date) >>> Old backups older than $BACKUP_RETENTION_DAYS days removed." >> "$LOG_FILE"

    # Ограничиваем лог по количеству строк
    tail -n "$LOG_MAX_LINES" "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"

    echo "$(date) >>> Backup cycle finished, sleeping $INTERVAL_MIN minutes..." >> "$LOG_FILE"
    sleep "$INTERVAL_SEC"
done
