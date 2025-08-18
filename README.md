# postgres-cluster

Docker based Postgres cluster with pgpool.

## Add new worker

If add any new worker - then add it to `scripts\init_workers.sh`:

```sql
SELECT citus_add_node('worker3', 5432);
SELECT citus_add_node('worker4', 5432);
```

Or execute inside running coordinator:

```bash
/usr/local/bin/register_worker.sh worker3 worker4
```

And also add new services as depends_on to the `coordinator` and `backup` services.

## Dokploy

On start  or deploy click (when container stopped) - the data is saved. So, if You need to start from scratch - the volumes should be removed.

If You modify any project variable - page should be reloaded.
