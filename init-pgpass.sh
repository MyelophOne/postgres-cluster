#!/bin/bash
set -e

PGPASSFILE="/var/lib/postgresql/.pgpass"

echo "citus-worker-1:5432:${POSTGRES_DB}:${POSTGRES_USER}:${POSTGRES_PASSWORD}" > "$PGPASSFILE"
echo "citus-worker-2:5432:${POSTGRES_DB}:${POSTGRES_USER}:${POSTGRES_PASSWORD}" >> "$PGPASSFILE"

chown postgres:postgres "$PGPASSFILE"
chmod 600 "$PGPASSFILE"
