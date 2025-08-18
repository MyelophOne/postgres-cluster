#!/bin/sh
# /usr/local/bin/register_worker.sh
# Запускать только на контейнере с ROLE=master
# /usr/local/bin/register_worker.sh worker3
set -e

# Скрипт можно запускать только на master
if [ "${ROLE}" != "master" ]; then
    echo ">>> ERROR: This script can only run on master!"
    exit 1
fi

# Список воркеров передан как аргументы
if [ "$#" -lt 1 ]; then
    echo ">>> ERROR: No workers specified. Usage: $0 worker1 [worker2 ...]"
    exit 1
fi

WORKERS="$*"

echo ">>> [${SERVER_ID:-na}] Registering workers: $WORKERS ..."

for WORKER in $WORKERS; do
    echo ">>> Processing worker '$WORKER'..."

    # Проверка подключения к координатору
    PGPASSWORD="$POSTGRES_PASSWORD" psql -h coordinator -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\q" 2>/dev/null || {
        echo ">>> ERROR: Cannot connect to coordinator!"
        continue
    }

    # Проверяем, есть ли воркер уже в pg_dist_node
    EXISTS=$(PGPASSWORD="$POSTGRES_PASSWORD" psql -h coordinator -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c \
        "SELECT 1 FROM pg_dist_node WHERE nodename = '$WORKER';" | tr -d '[:space:]')

    if [ "$EXISTS" = "1" ]; then
        echo ">>> Worker '$WORKER' already registered, skipping."
        continue
    fi

    # Добавляем воркер
    PGPASSWORD="$POSTGRES_PASSWORD" psql -h coordinator -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT master_add_node('$WORKER', 5432);" 2>/dev/null && \
        echo ">>> Worker '$WORKER' added successfully." || \
        echo ">>> ERROR: Failed to add worker '$WORKER'."
done

# Telegram уведомление
if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d text="[$SERVER_ID] Registered workers: $WORKERS at $(date)"
fi

echo ">>> Worker registration finished."
