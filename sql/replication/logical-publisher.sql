-- Logical replication: Publisher.
-- Run CREATE DATABASE while connected to postgres.

CREATE DATABASE logical_replication_lab;

-- Reconnect before executing the remaining statements:
-- \connect logical_replication_lab

CREATE TABLE replication_demo (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    message text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT current_timestamp
);

INSERT INTO replication_demo (message)
VALUES
    ('Первая запись'),
    ('Вторая запись'),
    ('Третья запись');

-- Create once and set its password interactively:
-- CREATE ROLE logical_replicator WITH LOGIN REPLICATION;
-- \password logical_replicator

GRANT CONNECT
ON DATABASE logical_replication_lab
TO logical_replicator;

GRANT USAGE
ON SCHEMA public
TO logical_replicator;

GRANT SELECT
ON TABLE replication_demo
TO logical_replicator;

CREATE PUBLICATION demo_publication
FOR TABLE replication_demo;

SELECT
    pubname,
    pubinsert,
    pubupdate,
    pubdelete,
    pubtruncate
FROM pg_publication;

SELECT *
FROM pg_publication_tables;

SELECT
    slot_name,
    slot_type,
    plugin,
    database,
    active
FROM pg_replication_slots
ORDER BY slot_name;

-- Run after the subscription has been created.
INSERT INTO replication_demo (message)
VALUES
    ('Четвёртая запись после создания подписки'),
    ('Пятая запись после создания подписки')
RETURNING *;
