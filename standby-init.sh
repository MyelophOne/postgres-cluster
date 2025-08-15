#!/bin/bash
set -e

MASTER_HOST="${MASTER_HOST:-citus-master}"
REPLICATION_USER="${REPLICATION_USER:-replicator}"
PGDATA="${PGDATA:-/var/lib/postgresql/data}"

if [ "$ROLE" != "standby" ]; then
    echo "standby-init.sh: skipping, this is not a standby"
    exit 0
fi

echo "Starting standby-init.sh..."

if [ -f "$PGDATA/PG_VERSION" ]; then
    echo "PGDATA exists, checking standby.signal..."
    if [ ! -f "$PGDATA/standby.signal" ]; then
        echo "Creating standby.signal to enable standby mode"
        touch "$PGDATA/standby.signal"
    fi
    exit 0
fi

echo "Cleaning old postgres PID files..."
rm -f $PGDATA/postmaster.pid
rm -rf $PGDATA/*

echo "Waiting for master ($MASTER_HOST) to be reachable..."
until nc -z "$MASTER_HOST" 5432; do
    echo "Waiting for master..."
    sleep 2
done

echo "Master is reachable. Starting pg_basebackup..."
pg_basebackup -h "$MASTER_HOST" -D "$PGDATA" -U "$REPLICATION_USER" -v -P --wal-method=stream

touch "$PGDATA/standby.signal"

echo "Standby initialization completed."
