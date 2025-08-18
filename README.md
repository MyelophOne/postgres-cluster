# postgres-cluster

Docker based Postgres cluster with pgpool.

## Add new worker

If add any new worker - then add it to `scripts\init_workers.sh`:

```sql
SELECT citus_add_node('worker3', 5432);
SELECT citus_add_node('worker4', 5432);
```

Or run inside coordinator:

```bash
/usr/local/bin/register_worker.sh worker3 worker4
```
