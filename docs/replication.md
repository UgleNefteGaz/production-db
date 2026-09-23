# Репликация PostgreSQL

## 1. Цель работы

В проекте реализованы и проверены два механизма репликации PostgreSQL 18:

1. физическая streaming replication между двумя кластерами PostgreSQL;
2. логическая репликация отдельной таблицы через `PUBLICATION` и `SUBSCRIPTION`.

Для физической репликации выполнены требования:

- используется отдельный physical replication slot;
- standby работает как hot standby;
- применение WAL на standby задерживается на 5 минут.

Для логической репликации выполнены требования:

- на Publisher создана отдельная база данных;
- создана и заполнена тестовая таблица;
- создана публикация;
- на отдельном PostgreSQL-кластере создана подписка;
- проверена первоначальная синхронизация существующих строк;
- проверена передача новых `INSERT` после создания подписки.

## 2. Архитектура стенда

Используются три независимых PostgreSQL-кластера в Docker.

```text
                         production-db-postgres
                         PostgreSQL 18.6
                         PRIMARY / PUBLISHER
                         host port 5434
                         container port 5432
                                  |
                    +-------------+-------------+
                    |                           |
                    | physical WAL              | logical replication
                    |                           |
                    v                           v
        production-db-physical       production-db-logical
        PostgreSQL 18.6              PostgreSQL 18.6
        PHYSICAL STANDBY             LOGICAL SUBSCRIBER
        host port 5435               host port 5436
        container port 5432          container port 5432
        delay = 5 min
```

Для обмена между контейнерами создана отдельная Docker-сеть:

```text
production-replication
172.31.0.0/16
```

Основной контейнер получил в этой сети адрес `172.31.0.2`.
Physical standby во время проверки использовал адрес `172.31.0.3`.

В конфигурации репликации используются имена контейнеров, а не фиксированные IP-адреса:

```text
production-db-postgres:5432
```

# 3. Физическая репликация

## 3.1. Исходная конфигурация Primary

Исходный кластер:

```text
container: production-db-postgres
PostgreSQL: 18.6
host port: 5434
container port: 5432
data_directory: /var/lib/postgresql/18/docker
```

До настройки логической репликации параметры были:

```text
wal_level = replica
max_wal_senders = 10
max_replication_slots = 10
listen_addresses = *
```

Для физической streaming replication этих параметров достаточно.

## 3.2. Пользователь физической репликации

На Primary создан отдельный пользователь:

```sql
CREATE ROLE replicator
WITH LOGIN REPLICATION;
```

Пароль задавался интерактивно:

```text
\password replicator
```

Проверка роли:

```sql
SELECT
    rolname,
    rolcanlogin,
    rolreplication
FROM pg_roles
WHERE rolname = 'replicator';
```

Получено:

```text
rolname = replicator
rolcanlogin = true
rolreplication = true
```

## 3.3. Доступ через pg_hba.conf

Для Docker-сети репликации добавлено правило:

```text
host replication replicator 172.31.0.0/16 scram-sha-256
```

После изменения выполнена перезагрузка конфигурации:

```sql
SELECT pg_reload_conf();
```

Активное правило проверялось через `pg_hba_file_rules`.

## 3.4. Подготовка Standby через pg_basebackup

Для physical standby создан отдельный Docker volume:

```bash
docker volume create production_db_physical_data
```

Базовая копия кластера создавалась через `pg_basebackup`.

Основные параметры:

```text
--format=plain
--wal-method=stream
--write-recovery-conf
--create-slot
--slot=physical_replica_slot
```

Схема команды:

```bash
pg_basebackup \
  -h production-db-postgres \
  -p 5432 \
  -U replicator \
  -D /var/lib/postgresql/18/docker \
  --format=plain \
  --wal-method=stream \
  --progress \
  --write-recovery-conf \
  --create-slot \
  --slot=physical_replica_slot
```

`--write-recovery-conf` подготовил standby-конфигурацию, включая:

```text
standby.signal
primary_conninfo
primary_slot_name
```

Был создан physical replication slot:

```text
physical_replica_slot
```

В `postgresql.auto.conf` подтверждено:

```text
primary_slot_name = 'physical_replica_slot'
```

В фактическом лабораторном стенде `pg_basebackup` также записал пароль подключения в `primary_conninfo`. В документации пароль намеренно не приводится. Для постоянной эксплуатации пароль следует хранить в защищённом passfile.

## 3.5. Задержка применения WAL на 5 минут

На standby добавлен параметр:

```conf
recovery_min_apply_delay = '5min'
```

Это не задерживает получение WAL по сети. Задерживается именно применение commit-записей на standby.

```text
Primary
  |
  | WAL передаётся практически сразу
  v
Standby WAL receiver
  |
  | WAL уже получен
  | recovery_min_apply_delay = 5min
  v
WAL replay выполняется с задержкой
```

## 3.6. Запуск physical standby

Standby запущен как отдельный контейнер:

```bash
docker run -d \
  --name production-db-physical \
  --network production-replication \
  -p 5435:5432 \
  -v production_db_physical_data:/var/lib/postgresql \
  postgres:18
```

В журнале PostgreSQL были получены ключевые сообщения:

```text
entering standby mode
database system is ready to accept read-only connections
started streaming WAL from primary
```

## 3.7. Проверка режима Standby

На physical replica выполнено:

```sql
SELECT pg_is_in_recovery();
SHOW primary_slot_name;
SHOW recovery_min_apply_delay;
```

Получено:

```text
pg_is_in_recovery() = true
primary_slot_name = physical_replica_slot
recovery_min_apply_delay = 5min
```

Это подтверждает режим standby, использование нужного replication slot и задержку replay на 5 минут.

## 3.8. Проверка Physical Replication Slot

На Primary:

```sql
SELECT
    slot_name,
    slot_type,
    active,
    active_pid,
    restart_lsn
FROM pg_replication_slots
WHERE slot_name = 'physical_replica_slot';
```

После запуска standby получено:

```text
slot_name = physical_replica_slot
slot_type = physical
active = true
```

## 3.9. Проверка streaming replication

На Primary:

```sql
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
```

Фактический результат:

```text
usename          = replicator
application_name = walreceiver
client_addr      = 172.31.0.3
state            = streaming
sync_state       = async
```

На standby:

```sql
SELECT
    status,
    sender_host,
    sender_port,
    slot_name,
    written_lsn,
    flushed_lsn,
    latest_end_lsn,
    latest_end_time
FROM pg_stat_wal_receiver;
```

Получено:

```text
status      = streaming
sender_host = production-db-postgres
sender_port = 5432
slot_name   = physical_replica_slot
```

## 3.10. Практическая проверка задержки

Для проверки на Primary создана отдельная таблица:

```sql
CREATE TABLE physical_replication_test (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    note text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT current_timestamp
);
```

Тестовая строка была добавлена на Primary:

```sql
INSERT INTO physical_replication_test (note)
VALUES ('Точный тест задержки 5 минут')
RETURNING id, note, created_at;
```

Время фиксации строки:

```text
2026-09-18 13:31:30.099638+00
```

Через несколько секунд после `INSERT` на standby был выполнен запрос к таблице.
В момент:

```text
2026-09-18 13:31:35.830783+00
```

новая строка с `id = 2` на standby ещё отсутствовала.

Позже, в:

```text
2026-09-18 13:36:53.914754+00
```

состояние WAL было:

```text
receive_lsn   = 0/5002660
replay_lsn    = 0/5002660
pending_bytes = 0
```

То есть примерно через 5 минут 24 секунды standby полностью применил полученный WAL.

Во время более ранней проверки также наблюдалось состояние:

```text
receive_lsn > replay_lsn
pending_bytes > 0
```

Это подтвердило требуемую механику: WAL уже поступил на standby, но ещё не был применён из-за `recovery_min_apply_delay`.

## 3.11. Результат физической репликации

Выполнены требования:

- настроены два независимых PostgreSQL-кластера;
- используется streaming replication;
- создан и используется `physical_replica_slot`;
- physical standby работает в read-only recovery;
- репликация асинхронная;
- применение WAL задерживается на 5 минут;
- задержка подтверждена практическим тестом.

# 4. Логическая репликация

## 4.1. Изменение wal_level

Для logical replication Primary был переключён с:

```text
wal_level = replica
```

на:

```text
wal_level = logical
```

Команда:

```sql
ALTER SYSTEM SET wal_level = 'logical';
```

После `pg_reload_conf()` `pg_settings` показал `pending_restart = true`.
После перезапуска Primary получено:

```text
setting = logical
source = configuration file
pending_restart = false
```

При этом физическая репликация продолжила работать:

```text
state = streaming
sync_state = async
```

## 4.2. База и таблица Publisher

На Primary создана отдельная база:

```sql
CREATE DATABASE logical_replication_lab;
```

В ней создана таблица:

```sql
CREATE TABLE replication_demo (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    message text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT current_timestamp
);
```

Начальные данные:

```sql
INSERT INTO replication_demo (message)
VALUES
    ('Первая запись'),
    ('Вторая запись'),
    ('Третья запись');
```

До создания подписки Publisher содержал три строки.

## 4.3. Пользователь логической репликации

Создан отдельный пользователь:

```sql
CREATE ROLE logical_replicator
WITH LOGIN REPLICATION;
```

Выданы необходимые права:

```sql
GRANT CONNECT
ON DATABASE logical_replication_lab
TO logical_replicator;

GRANT USAGE
ON SCHEMA public
TO logical_replicator;

GRANT SELECT
ON TABLE replication_demo
TO logical_replicator;
```

## 4.4. Публикация

На Publisher:

```sql
CREATE PUBLICATION demo_publication
FOR TABLE replication_demo;
```

Проверка `pg_publication` показала:

```text
INSERT   = true
UPDATE   = true
DELETE   = true
TRUNCATE = true
```

`pg_publication_tables` подтвердил публикацию таблицы `public.replication_demo`.

## 4.5. Подготовка Logical Subscriber

Создан отдельный volume:

```bash
docker volume create production_db_logical_data
```

Запущен отдельный PostgreSQL-кластер:

```bash
docker run -d \
  --name production-db-logical \
  --network production-replication \
  -p 5436:5432 \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD="<ADMIN_PASSWORD>" \
  -v production_db_logical_data:/var/lib/postgresql \
  postgres:18
```

На Subscriber создана база:

```sql
CREATE DATABASE logical_replication_lab;
```

Таблица создавалась заранее, потому что logical replication не переносит DDL:

```sql
CREATE TABLE replication_demo (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    message text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT current_timestamp
);
```

До создания подписки таблица была пустой.

## 4.6. Хранение пароля Publisher на Subscriber

На Subscriber создан файл:

```text
/var/lib/postgresql/.pgpass
```

Права:

```text
-rw-------
```

Запись имеет формат:

```text
production-db-postgres:5432:logical_replication_lab:logical_replicator:<PASSWORD>
```

Пароль в репозиторий не помещается.

Перед созданием подписки соединение было проверено. Получено:

```text
current_database = logical_replication_lab
current_user     = logical_replicator
```

## 4.7. Создание Subscription

На Subscriber:

```sql
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
```

PostgreSQL сообщил:

```text
NOTICE: created replication slot "demo_subscription" on publisher
CREATE SUBSCRIPTION
```

## 4.8. Проверка состояния Subscription

На Subscriber:

```sql
SELECT
    subname,
    pid,
    relid::regclass,
    received_lsn,
    latest_end_lsn,
    latest_end_time
FROM pg_stat_subscription;
```

Фактический результат:

```text
subname        = demo_subscription
pid            = 167
received_lsn   = 0/5459A28
latest_end_lsn = 0/5459A28
```

## 4.9. Первоначальная синхронизация

После создания подписки на Subscriber:

```sql
SELECT *
FROM replication_demo
ORDER BY id;
```

вернул три исходные строки:

```text
1 | Первая запись
2 | Вторая запись
3 | Третья запись
```

Это подтверждает первоначальное копирование существующих данных.

## 4.10. Logical Replication Slot

На Publisher:

```sql
SELECT
    slot_name,
    slot_type,
    plugin,
    database,
    active
FROM pg_replication_slots
ORDER BY slot_name;
```

Получено:

```text
demo_subscription     | logical  | pgoutput | logical_replication_lab | true
physical_replica_slot | physical |          |                         | true
```

Одновременно работают physical и logical replication slots.

## 4.11. Проверка новых INSERT

После создания подписки на Publisher выполнено:

```sql
INSERT INTO replication_demo (message)
VALUES
    ('Четвёртая запись после создания подписки'),
    ('Пятая запись после создания подписки')
RETURNING *;
```

На Publisher были созданы строки `id = 4` и `id = 5`.

После этого на Subscriber запрос:

```sql
SELECT *
FROM replication_demo
ORDER BY id;
```

вернул уже пять строк:

```text
1 | Первая запись
2 | Вторая запись
3 | Третья запись
4 | Четвёртая запись после создания подписки
5 | Пятая запись после создания подписки
```

Это подтверждает передачу новых изменений после первоначальной синхронизации.

## 4.12. Особенность IDENTITY и sequence

Колонка:

```sql
id bigint GENERATED ALWAYS AS IDENTITY
```

реплицируется как значение строки.

При этом состояние sequence логической репликацией автоматически не синхронизируется.

В текущем учебном стенде это не создаёт проблему, потому что новые строки добавляются только на Publisher.

# 5. Сравнение физической и логической репликации

| Характеристика | Физическая | Логическая |
|---|---|---|
| Единица репликации | весь PostgreSQL-кластер | выбранные таблицы |
| Источник | WAL | логически декодированные изменения WAL |
| Схема таблиц | копируется физически | должна существовать на Subscriber |
| Replication slot | physical | logical |
| Slot проекта | `physical_replica_slot` | `demo_subscription` |
| Output plugin | не используется | `pgoutput` |
| Standby read-only | да | Subscriber является обычной БД |
| Отложенное применение | `recovery_min_apply_delay` | в работе не использовалось |
| Использованный host port | 5435 | 5436 |
| Основной сценарий | standby и recovery | выборочная передача данных |

# 6. Практические выводы

## 6.1. Replication slot удерживает WAL

Если standby или subscriber недоступен, Primary может удерживать WAL, необходимый этому слоту.

Состояние слотов контролируется через:

```sql
SELECT *
FROM pg_replication_slots;
```

## 6.2. Physical delay означает задержку replay

`recovery_min_apply_delay = '5min'` не означает, что WAL пять минут не передаётся по сети. WAL receiver может получить данные почти сразу, а replay будет ждать требуемое время.

## 6.3. Logical replication не переносит DDL

Команды вида `CREATE TABLE`, `ALTER TABLE` и `CREATE INDEX` автоматически на Subscriber не копируются. Поэтому таблица `replication_demo` была предварительно создана вручную.

## 6.4. wal_level = logical совместим с physical standby

После перехода Primary на `wal_level = logical` существующая физическая streaming replication продолжила работать.

## 6.5. Пароли не должны храниться в репозитории

Файлы проекта не должны содержать реальные пароли `replicator`, `logical_replicator` и `admin`. В документации используются placeholders и `passfile`.

# 7. Итог

Физическая репликация:

```text
production-db-postgres
        |
        | physical_replica_slot
        | streaming WAL
        v
production-db-physical
        |
        | recovery_min_apply_delay
        v
      5 минут
```

Логическая репликация:

```text
logical_replication_lab
replication_demo
        |
        | demo_publication
        | logical slot: demo_subscription
        v
production-db-logical
        |
        v
replication_demo
```

Обе схемы работают одновременно на одном Primary/Publisher и проверены практическими изменениями данных.
