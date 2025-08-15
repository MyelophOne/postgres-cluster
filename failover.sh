#!/bin/sh
set -e

FAILED_NODE_ID="$1"
FAILED_NODE_HOST="$2"
FAILED_NODE_PORT="$3"

: "${PGPOOL_PCP_PORT:?Need PGPOOL_PCP_PORT}"
: "${PGPOOL_PCP_USER:?Need PGPOOL_PCP_USER}"
: "${PGPOOL_PCP_PASSWORD:?Need PGPOOL_PCP_PASSWORD}"
: "${NEW_MASTER_NODE_ID:?Need NEW_MASTER_NODE_ID}"

echo "[FAILOVER] Detected failure of node $FAILED_NODE_ID ($FAILED_NODE_HOST:$FAILED_NODE_PORT)"

if [ "$FAILED_NODE_ID" = "0" ]; then
    echo "[FAILOVER] Master node is down. Promoting standby node $NEW_MASTER_NODE_ID..."

    pcp_promote_node \
        -h localhost \
        -p "$PGPOOL_PCP_PORT" \
        -U "$PGPOOL_PCP_USER" \
        -w \
        "$NEW_MASTER_NODE_ID"

    echo "[FAILOVER] Standby node $NEW_MASTER_NODE_ID promoted to master."
else
    echo "[FAILOVER] Non-master node $FAILED_NODE_ID failed. No promotion needed."
fi
