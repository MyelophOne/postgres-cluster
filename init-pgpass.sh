#!/bin/sh

set -e

PGPASSFILE="/var/lib/postgresql/.pgpass"

if [ "$ROLE" = "master" ]; then
	echo "Configuring Citus master..."

	cat > "$PGPASSFILE" <<EOF
citus-worker-1:5432:${POSTGRES_DB}:*:${POSTGRES_PASSWORD}
citus-worker-2:5432:${POSTGRES_DB}:*:${POSTGRES_PASSWORD}
EOF
	chown postgres:postgres "$PGPASSFILE"
	chmod 600 "$PGPASSFILE"

	until pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"; do
		echo "Waiting for Postgres..."
		sleep 2
	done

	psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT citus_set_coordinator_host('citus-master');" || true

	psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT master_add_node('$WORKER_1_HOST', 5432);" || true
	psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT master_add_node('$WORKER_2_HOST', 5432);" || true

	echo "Citus Master configured."
fi
