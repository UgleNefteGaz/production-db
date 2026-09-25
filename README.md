# Production DB

Учебный проект реляционной базы данных для учёта и контроля производственных процессов предприятия.

## Назначение

База данных моделирует производственный процесс и позволяет учитывать:

- продукцию и материалы;
- технологические спецификации;
- производственные заказы и партии;
- технологические операции и производственные линии;
- сотрудников и смены;
- фактический расход материалов;
- контроль качества и производственный брак.

## Технологии

- PostgreSQL 18;
- тестовая среда: PostgreSQL 18.6 в Docker;
- DBML для логической модели;
- Git для версионирования.

Для имён таблиц, полей, индексов, ограничений, функций и триггеров используется `lowercase snake_case`.

## Модель данных

В базе 15 основных таблиц:

1. `products`
2. `materials`
3. `specifications`
4. `specification_items`
5. `production_orders`
6. `production_batches`
7. `production_lines`
8. `operations`
9. `batch_operations`
10. `employees`
11. `shifts`
12. `material_usage`
13. `quality_checks`
14. `defect_types`
15. `defects`

Для состояний объектов используются 8 ENUM-типов.

## Типы данных

### Выбор типов данных

Типы данных подобраны в соответствии с назначением хранимой информации.

| Тип данных | Использование | Причина выбора |
|---|---|---|
| `bigint` | Первичные и внешние ключи | Большой диапазон значений и единый тип идентификаторов во всей модели |
| `integer` | Небольшие целые значения, например номер смены | Диапазона `integer` достаточно для подобных атрибутов |
| `numeric(18,3)` | Количество продукции | Позволяет хранить точные десятичные значения без погрешности типов с плавающей точкой |
| `numeric(18,6)` | Нормативный и фактический расход материалов | Требуется более высокая точность для небольших количеств материала |
| `numeric(5,2)` | Процент технологических потерь | Подходит для значений от 0 до 100 с двумя знаками после запятой |
| `varchar(n)` | Артикулы, коды, номера, названия | Используется для строк с известной разумной максимальной длиной |
| `text` | Описания и комментарии | Длина текста заранее не ограничена |
| `boolean` | Логические признаки, например `is_active` | Значение имеет два состояния: `true` и `false` |
| `date` | Календарные даты | Используется там, где время суток не требуется |
| `timestamp` | Дата и время производственных событий | Позволяет хранить точное время начала, окончания или регистрации события |
| `ENUM` | Статусы и фиксированные классификации | Ограничивает значение заранее определённым набором допустимых вариантов |
| `jsonb` | Дополнительные параметры контроля качества | Подходит для данных с переменной структурой |

По результатам анализа изменение существующих типов данных не требуется.

Для производственных количеств используется `numeric`, а не `real` или `double precision`, поскольку для учёта важна точная десятичная арифметика.

В проекте используется `timestamp without time zone`. Для текущей модели, предполагающей работу в единой производственной среде, этого достаточно. При необходимости работы с несколькими часовыми поясами может быть рассмотрен переход на `timestamptz`.

### Тип идентификаторов

Для первичных ключей используется:

```sql
bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY
```

PostgreSQL автоматически генерирует значение идентификатора при добавлении новой записи.

Внешние ключи используют обычный тип `bigint`:

```sql
product_id bigint NOT NULL
```

Таким образом, тип первичного и соответствующего внешнего ключа совпадает.

В проекте выбран `bigint`, поскольку он предоставляет большой диапазон идентификаторов и позволяет использовать единый подход для всех основных сущностей.

Использование `GENERATED ALWAYS AS IDENTITY` предпочтительнее ручного назначения ID и не требует вычисления значений вида:

```sql
MAX(id) + 1
```

UUID для текущей модели не требуется. База данных является централизованной, поэтому последовательные числовые идентификаторы проще для хранения, связей и ручной диагностики.

Итоговый подход:

```text
Primary Key: bigint GENERATED ALWAYS AS IDENTITY
Foreign Key: bigint
```

## JSON и JSONB

PostgreSQL поддерживает два основных типа для хранения JSON-документов:

- `json`
- `jsonb`

Тип `json` хранит исходное текстовое представление JSON.

Тип `jsonb` преобразует документ во внутреннее бинарное представление. Это упрощает фильтрацию, поиск по содержимому и индексирование.

Для проекта выбран `jsonb`, поскольку сохранение исходного форматирования JSON не требуется, а возможность выполнять запросы по отдельным элементам документа является полезной.

### Использование JSONB в проекте

JSONB добавлен в таблицу `quality_checks`:

```sql
measurements jsonb NOT NULL DEFAULT '{}'::jsonb
```

Поле предназначено для дополнительных измерений и параметров контроля качества.

Например, для шампуня могут храниться:

```json
{
  "ph": 5.6,
  "color": "colorless",
  "appearance": "transparent",
  "temperature_c": 22.6,
  "viscosity_mpa_s": 3200
}
```

Для другого продукта набор параметров может отличаться:

```json
{
  "ph": 5.7,
  "appearance": "transparent",
  "density_g_cm3": 1.03,
  "temperature_c": 22.9,
  "viscosity_mpa_s": 5400
}
```

Таким образом, обязательные и стабильные бизнес-атрибуты остаются обычными реляционными колонками, а JSONB используется только для дополнительных параметров с переменной структурой.

Для поля также задано ограничение:

```sql
CHECK (jsonb_typeof(measurements) = 'object')
```

Оно запрещает хранить в `measurements` JSON-массив, строку или число вместо объекта.

### Пример добавления записи с JSONB

```sql
INSERT INTO quality_checks (
    batch_id,
    employee_id,
    check_stage,
    checked_at,
    result,
    notes,
    measurements
)
SELECT
    pb.batch_id,
    e.employee_id,
    'Intermediate'::quality_check_stage,
    TIMESTAMP '2026-08-05 16:30',
    'Passed'::quality_check_result,
    'Дополнительная проверка параметров продукта',
    '{
        "ph": 5.5,
        "temperature_c": 22.4,
        "viscosity_mpa_s": 3250,
        "appearance": "transparent",
        "device": {
            "code": "QC-DEVICE-01",
            "calibrated": true
        }
    }'::jsonb
FROM production_batches pb
CROSS JOIN employees e
WHERE pb.batch_number = 'BATCH-004'
  AND e.personnel_number = 'EMP004'
  AND NOT EXISTS (
     SELECT 1
     FROM quality_checks qc
     WHERE qc.batch_id = pb.batch_id
       AND qc.employee_id = e.employee_id
       AND qc.checked_at = TIMESTAMP '2026-08-05 16:30'
  );
```

### Примеры выборки JSONB

Получение всего объекта:

```sql
SELECT
    quality_check_id,
    measurements
FROM quality_checks
WHERE measurements <> '{}'::jsonb;
```

Получение отдельного значения:

```sql
SELECT
    quality_check_id,
    measurements ->> 'ph' AS ph
FROM quality_checks
WHERE measurements ? 'ph';
```

Оператор `->` возвращает значение как `jsonb`, а `->>` возвращает значение как `text`.

Для числовых сравнений значение можно привести к `numeric`:

```sql
SELECT
    quality_check_id,
    (measurements ->> 'ph')::numeric AS ph
FROM quality_checks
WHERE measurements ? 'ph'
  AND (measurements ->> 'ph')::numeric > 5.0;
```

Поиск по содержимому JSONB:

```sql
SELECT
    quality_check_id,
    measurements
FROM quality_checks
WHERE measurements @> '{"appearance": "transparent"}'::jsonb;
```

Оператор `@>` проверяет, содержит ли JSONB-объект указанный фрагмент.

Проверка наличия ключа:

```sql
SELECT
    quality_check_id,
    measurements
FROM quality_checks
WHERE measurements ? 'density_g_cm3';
```

Получение значения из вложенного объекта:

```sql
SELECT
    quality_check_id,
    measurements #>> '{device,code}' AS device_code
FROM quality_checks
WHERE measurements ? 'device';
```

Более полный набор примеров работы с JSONB находится в:

```text
sql/json.sql
```

## Структура проекта

```text
production-db/
├── README.md
├── db/
│   ├── schema.dbml
│   ├── schema.sql
│   └── seed.sql
├── docs/
│   ├── requirements.md
│   ├── constraints.md
│   ├── additional-constraints.md
│   ├── er-diagram.md
│   ├── data-dictionary.md
│   ├── business-tasks.md
│   ├── indexes-analysis.md
│   ├── triggers.md
│   ├── replication.md
│   └── worklog.md
├── sql/
│   ├── queries.sql
│   ├── views.sql
│   ├── functions.sql
│   ├── indexes.sql
│   ├── constraints.sql
│   ├── triggers.sql
│   ├── json.sql
│   └── replication/
│       ├── physical-primary.sql
│       ├── logical-publisher.sql
│       └── logical-subscriber.sql
└── images/
    └── .gitkeep
```

## Основные файлы

- `db/schema.dbml` - логическая модель базы данных.
- `db/schema.sql` - физическая схема PostgreSQL: 8 ENUM-типов, 15 таблиц и базовые ограничения.
- `db/seed.sql` - расширенный набор связанных тестовых данных.
- `sql/indexes.sql` - 14 дополнительных индексов, включая полнотекстовый GIN-индекс.
- `sql/constraints.sql` - 8 дополнительных `CHECK`-ограничений и 1 частичный уникальный индекс.
- `sql/triggers.sql` - 6 пользовательских триггеров для межтабличных бизнес-правил.
- `sql/queries.sql` - практические SQL-примеры.
- `sql/json.sql` - примеры добавления, выборки, фильтрации и изменения данных в формате JSONB.
- `sql/replication/` - SQL-команды и проверки для лабораторной работы по репликации.

## Реализованные механизмы

### Ограничения

Основная схема содержит:

- `PRIMARY KEY`;
- `FOREIGN KEY`;
- `NOT NULL`;
- `UNIQUE`;
- базовые `CHECK`;
- `DEFAULT`;
- правила `ON DELETE`.

Дополнительно реализованы 8 `CHECK`-ограничений и частичный уникальный индекс, разрешающий только одну активную спецификацию продукта.

Подробности: `docs/constraints.md` и `docs/additional-constraints.md`.

### Индексы

В `sql/indexes.sql` создано 14 дополнительных индексов:

- простые и составные B-tree индексы;
- полнотекстовый GIN-индекс `idx_products_fts`.

Отдельно в `sql/constraints.sql` создаётся частичный уникальный индекс `uq_specifications_one_active_per_product`.

Использование составного, полнотекстового и частичного индексов проверено через `EXPLAIN ANALYZE`.

Подробности: `docs/indexes-analysis.md`.

### Триггеры

Создано 6 пользовательских триггеров. Они контролируют:

- суммарное плановое количество партий относительно заказа;
- уменьшение планового количества заказа;
- согласованность `Passed` и зарегистрированных дефектов;
- соответствие времени проверки качества периоду партии.

В критичных местах используются блокировки `FOR UPDATE` для защиты от конкурентных изменений.

Подробности: `docs/triggers.md`.

### Практические SQL-запросы

В `sql/queries.sql` реализованы примеры:

- регулярных выражений;
- `INNER JOIN` и `LEFT JOIN`;
- `INSERT ... RETURNING`;
- `UPDATE ... FROM`;
- `DELETE ... USING`;
- `COPY`.

Изменяющие демонстрационные запросы выполняются в транзакциях с `ROLLBACK`, чтобы сохранять исходные тестовые данные.

### Репликация

В проекте реализованы два механизма PostgreSQL 18:

- физическая streaming replication через `physical_replica_slot`;
- hot standby с `recovery_min_apply_delay = '5min'`;
- логическая репликация через `demo_publication` и `demo_subscription`;
- одновременная работа physical и logical replication при `wal_level = logical`.

Архитектура лабораторного стенда:

```text
production-db-postgres  :5434  Primary / Publisher
production-db-physical  :5435  Physical Standby, delay 5 min
production-db-logical   :5436  Logical Subscriber
```

Подробности и результаты проверок: `docs/replication.md`.

## Тестовые данные

После загрузки `db/seed.sql` база содержит:

| Таблица | Строк |
|---|---:|
| `products` | 6 |
| `materials` | 12 |
| `specifications` | 7 |
| `specification_items` | 35 |
| `production_lines` | 5 |
| `operations` | 6 |
| `employees` | 9 |
| `defect_types` | 5 |
| `shifts` | 10 |
| `production_orders` | 12 |
| `production_batches` | 17 |
| `batch_operations` | 60 |
| `material_usage` | 60 |
| `quality_checks` | 17 |
| `defects` | 9 |

Набор специально содержит различные статусы заказов, партий и проверок качества, а также данные для демонстрации `LEFT JOIN`, регулярных выражений, `UPDATE ... FROM` и `DELETE ... USING`.

## Порядок развёртывания

Чистая база успешно разворачивается в следующем порядке:

```text
db/schema.sql
sql/constraints.sql
sql/indexes.sql
sql/triggers.sql
db/seed.sql
```

Расширенный `seed.sql` успешно загружается при уже включённых дополнительных ограничениях и триггерах.

## Документация

- `docs/requirements.md` - требования к системе.
- `docs/data-dictionary.md` - таблицы, поля и типы данных.
- `docs/er-diagram.md` - связи и кардинальности.
- `docs/constraints.md` - базовые ограничения физической схемы.
- `docs/additional-constraints.md` - дополнительные ограничения бизнес-логики.
- `docs/indexes-analysis.md` - проектирование и проверка индексов.
- `docs/triggers.md` - межтабличные бизнес-правила и триггеры.
- `docs/replication.md` - физическая и логическая репликация PostgreSQL.
- `docs/business-tasks.md` - бизнес-задачи базы данных.
- `docs/worklog.md` - хронология разработки.

## Текущее состояние

Завершены:

- логическая и физическая модели;
- базовые и дополнительные ограничения;
- расширенный тестовый набор;
- дополнительная индексация;
- полнотекстовый поиск;
- межтабличные бизнес-правила и триггеры;
- практические SQL-запросы;
- физическая и логическая репликация PostgreSQL;
- проверка полного развёртывания базы с нуля.

Следующие этапы:

- аналитические запросы;
- план-факт анализ;
- анализ расхода материалов;
- статистика брака и качества;
- представления `VIEW`;
- пользовательские функции.
