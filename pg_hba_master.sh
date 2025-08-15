#!/bin/sh
set -e

PGDATA=/var/lib/postgresql/data

echo "host replication ${POSTGRES_USER} 0.0.0.0/0 md5" >> $PGDATA/pg_hba.conf
echo "host all all 0.0.0.0/0 md5" >> $PGDATA/pg_hba.conf
