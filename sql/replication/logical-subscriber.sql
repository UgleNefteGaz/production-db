-- Logical replication: Subscriber.
-- Run CREATE DATABASE while connected to postgres.

CREATE DATABASE logical_replication_lab;

-- Reconnect before executing the remaining statements:
-- \connect logical_replication_lab

-- Logical replication does not copy DDL.
CREATE TABLE replication_demo (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    message text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT current_timestamp
);

SELECT *
FROM replication_demo
ORDER BY id;

-- /var/lib/postgresql/.pgpass must already exist and have mode 0600.
-- Expected entry:
-- production-db-postgres:5432:logical_replication_lab:logical_replicator:<PASSWORD>

CREATE SUBSCRIPTION demo_subscription
CONNECTION 'host=production-db-postgres
            port=5432
            dbname=logical_replication_lab
            user=logical_replicator
            passfile=/var/lib/postgresql/.pgpass'
PUBLICATION demo_publication
WITH (
    copy_data = true,
    create_slot = true,
    enabled = true
);

SELECT
    subname,
    pid,
    relid::regclass,
    received_lsn,
    latest_end_lsn,
    latest_end_time
FROM pg_stat_subscription;

SELECT *
FROM replication_demo
ORDER BY id;
