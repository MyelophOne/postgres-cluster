# postgres-cluster

Docker based Postgres cluster with pgpool.

## Add new worker

If add any new worker - then add it to `initdb.d/02-add-workers.sql`:

```sql
SELECT citus_add_node('worker3', 5432);
```
