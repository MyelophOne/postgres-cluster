#!/bin/sh
set -e

# Скрипт можно запускать только на master
if [ "${ROLE}" != "master" ]; then
    echo ">>> ERROR: Init workers script can only run on master!"
    exit 1
fi

# Wait until coordinator is ready
until pg_isready -h coordinator -U "$POSTGRES_USER" -d "$POSTGRES_DB"; do
  sleep 2
done

echo "Registering init workers..."
psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" <<EOF
SELECT citus_set_coordinator_host('coordinator');
SELECT citus_add_node('worker1', 5432);
SELECT citus_add_node('worker2', 5432);
EOF
