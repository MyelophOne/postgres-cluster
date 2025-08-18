SELECT citus_set_coordinator_host('coordinator');

SELECT citus_add_node('worker1', 5432);
SELECT citus_add_node('worker2', 5432);
