-- Physical replication: Primary-side preparation and checks.
-- Passwords are intentionally not stored in this file.

-- Create once if the role does not yet exist:
-- CREATE ROLE replicator WITH LOGIN REPLICATION;
-- Then set its password interactively:
-- \password replicator

-- Physical replication needs at least wal_level = replica.
-- This project also uses logical replication, so the final value is logical.
ALTER SYSTEM SET wal_level = 'logical';

SELECT pg_reload_conf();

SELECT
    name,
    setting,
    source,
    pending_restart
FROM pg_settings
WHERE name IN (
    'wal_level',
    'max_wal_senders',
    'max_replication_slots'
)
ORDER BY name;

-- The physical slot is created by pg_basebackup with:
-- --create-slot --slot=physical_replica_slot

SELECT
    slot_name,
    slot_type,
    active,
    active_pid,
    restart_lsn
FROM pg_replication_slots
WHERE slot_name = 'physical_replica_slot';

SELECT
    pid,
    usename,
    application_name,
    client_addr,
    state,
    sent_lsn,
    write_lsn,
    flush_lsn,
    replay_lsn,
    sync_state
FROM pg_stat_replication;
