#!/bin/bash
set -e

# Ждем, пока PostgreSQL полностью запустится
until psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT 1" > /dev/null 2>&1; do
  echo "Waiting for PostgreSQL to start..."
  sleep 1
done

# Ждем доступности воркеров
for worker in $WORKER_1_HOST $WORKER_2_HOST; do
  until nc -z $worker 5432; do
    echo "Waiting for worker $worker to become available..."
    sleep 1
  done
done

# Регистрируем воркеры в Citus
psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" <<EOF
  CREATE EXTENSION IF NOT EXISTS citus;
  CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
  CREATE EXTENSION IF NOT EXISTS plpgsql;
  CREATE EXTENSION IF NOT EXISTS hstore;
  CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
  CREATE EXTENSION IF NOT EXISTS pgcrypto;
  CREATE EXTENSION IF NOT EXISTS postgis;
  CREATE EXTENSION IF NOT EXISTS btree_gist;
  
  SELECT master_add_node('$WORKER_1_HOST', 5432);
  SELECT master_add_node('$WORKER_2_HOST', 5432);
EOF

echo "Citus cluster initialized successfully"