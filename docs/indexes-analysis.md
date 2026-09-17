# Анализ и проверка индексов

## 1. Назначение документа

Документ описывает подход к индексированию базы данных `production_db`, созданные индексы, причины их выбора и результаты практической проверки через `EXPLAIN ANALYZE`.

Задачи работы:

- определить запросы, для которых индексы действительно полезны;
- учитывать кардинальность полей;
- создать простые и составные B-tree индексы;
- реализовать частичный индекс;
- реализовать полнотекстовый GIN-индекс;
- проверить использование индексов планировщиком PostgreSQL;
- добавить комментарии к индексам;
- зафиксировать проблемы и выводы.

---

## 2. Принципы выбора индексов

Индексы создавались для полей, которые предполагается часто использовать в:

- `WHERE`;
- `JOIN`;
- диапазонных условиях по дате и времени;
- аналитических запросах;
- полнотекстовом поиске.

Отдельные индексы не создавались для `PRIMARY KEY` и `UNIQUE`, поскольку PostgreSQL автоматически создаёт для таких ограничений уникальные B-tree индексы.

Кардинальность оценивалась следующим образом:

- высокая - большинство значений уникальны или редко повторяются;
- средняя - значения повторяются, но различных значений достаточно много;
- низкая - поле содержит небольшой набор часто повторяющихся значений.

Поля с низкой кардинальностью, например `status` и `result`, не индексировались отдельно. Для типовых запросов они объединялись с более селективными полями даты и времени.

---

## 3. Созданные индексы

В `sql/indexes.sql` создано 14 дополнительных индексов для ускорения доступа к данным.

В `sql/constraints.sql` дополнительно создан частичный уникальный индекс `uq_specifications_one_active_per_product`, который одновременно является механизмом бизнес-целостности.

### 3.1. Производственные заказы

```sql
CREATE INDEX idx_production_orders_specification
    ON production_orders (specification_id);
```

Назначение: ускорение поиска заказов по спецификации и соединения `production_orders` с `specifications`.

Кардинальность `specification_id`: средняя.

```sql
CREATE INDEX idx_production_orders_status_start
    ON production_orders (status, planned_start_at);
```

Назначение: поиск заказов определённого статуса по периоду планового запуска.

Кардинальность:

- `status` - низкая;
- `planned_start_at` - высокая.

Пример запроса:

```sql
SELECT *
FROM production_orders
WHERE status = 'Completed'
  AND planned_start_at >= '2026-07-01'
  AND planned_start_at < '2026-10-01';
```

### 3.2. Производственные партии

```sql
CREATE INDEX idx_production_batches_status_started
    ON production_batches (status, started_at);
```

Назначение: поиск партий определённого статуса, запуск которых произошёл в заданный период.

Кардинальность:

- `status` - низкая;
- `started_at` - высокая.

### 3.3. Состав спецификаций

```sql
CREATE INDEX idx_specification_items_material
    ON specification_items (material_id);
```

Назначение: поиск спецификаций, в которых используется конкретный материал.

Существующий уникальный индекс `(specification_id, material_id)` не заменяет этот индекс для запросов только по `material_id`, поскольку `material_id` находится во второй позиции составного индекса.

### 3.4. Производственные операции

```sql
CREATE INDEX idx_batch_operations_line_started
    ON batch_operations (production_line_id, started_at);
```

Назначение: поиск операций, начатых на конкретной производственной линии за период.

```sql
CREATE INDEX idx_batch_operations_employee_started
    ON batch_operations (employee_id, started_at);
```

Назначение: поиск операций, начатых конкретным сотрудником за период.

```sql
CREATE INDEX idx_batch_operations_shift
    ON batch_operations (shift_id);
```

Назначение: получение операций конкретной смены.

```sql
CREATE INDEX idx_batch_operations_operation
    ON batch_operations (operation_id);
```

Назначение: анализ выполнения конкретного типа технологической операции.

### 3.5. Расход материалов

```sql
CREATE INDEX idx_material_usage_batch_material
    ON material_usage (batch_id, material_id);
```

Назначение: расчёт расхода конкретного материала в рамках партии.

```sql
CREATE INDEX idx_material_usage_material_recorded
    ON material_usage (material_id, recorded_at);
```

Назначение: анализ зарегистрированного расхода материала за период.

### 3.6. Контроль качества

```sql
CREATE INDEX idx_quality_checks_batch_checked
    ON quality_checks (batch_id, checked_at);
```

Назначение: получение истории проверок качества конкретной партии в хронологическом порядке.

```sql
CREATE INDEX idx_quality_checks_result_checked
    ON quality_checks (result, checked_at);
```

Назначение: поиск проверок определённого результата за период.

Кардинальность:

- `result` - низкая;
- `checked_at` - высокая.

### 3.7. Дефекты

```sql
CREATE INDEX idx_defects_type
    ON defects (defect_type_id);
```

Назначение: поиск и анализ дефектов определённого типа.

Существующий уникальный индекс `(quality_check_id, defect_type_id)` не заменяет этот индекс для поиска только по `defect_type_id`.

### 3.8. Полнотекстовый поиск

```sql
CREATE INDEX idx_products_fts
    ON products
    USING GIN (
        to_tsvector(
            'russian',
            coalesce(name, '') || ' ' || coalesce(description, '')
        )
    );
```

Назначение: полнотекстовый поиск по названию и описанию продукции.

Для полнотекстового поиска используется GIN, поскольку индексируется набор нормализованных текстовых лексем, а не одно скалярное значение.

### 3.9. Частичный уникальный индекс

```sql
CREATE UNIQUE INDEX uq_specifications_one_active_per_product
    ON specifications (product_id)
    WHERE status = 'Active';
```

Назначение:

- индексировать только активные спецификации;
- гарантировать, что у одного продукта одновременно существует не более одной активной спецификации.

Строки со статусами `Draft` и `Archived` в этот индекс не входят.

---

## 4. Сводная таблица

| Индекс | Таблица | Тип | Назначение |
|---|---|---|---|
| `idx_production_orders_specification` | `production_orders` | B-tree | Заказы по спецификации |
| `idx_production_orders_status_start` | `production_orders` | составной B-tree | Заказы по статусу и периоду |
| `idx_production_batches_status_started` | `production_batches` | составной B-tree | Партии по статусу и периоду запуска |
| `idx_specification_items_material` | `specification_items` | B-tree | Спецификации по материалу |
| `idx_batch_operations_line_started` | `batch_operations` | составной B-tree | Операции линии за период |
| `idx_batch_operations_employee_started` | `batch_operations` | составной B-tree | Операции сотрудника за период |
| `idx_batch_operations_shift` | `batch_operations` | B-tree | Операции смены |
| `idx_batch_operations_operation` | `batch_operations` | B-tree | Операции определённого типа |
| `idx_material_usage_batch_material` | `material_usage` | составной B-tree | Расход материала по партии |
| `idx_material_usage_material_recorded` | `material_usage` | составной B-tree | Расход материала за период |
| `idx_quality_checks_batch_checked` | `quality_checks` | составной B-tree | История контроля партии |
| `idx_quality_checks_result_checked` | `quality_checks` | составной B-tree | Проверки по результату и периоду |
| `idx_defects_type` | `defects` | B-tree | Анализ типов дефектов |
| `idx_products_fts` | `products` | GIN | Полнотекстовый поиск |
| `uq_specifications_one_active_per_product` | `specifications` | частичный уникальный B-tree | Одна активная спецификация на продукт |

---

## 5. Проверка составного B-tree индекса через EXPLAIN ANALYZE

Для практической проверки выбран индекс:

```sql
CREATE INDEX idx_production_orders_status_start
    ON production_orders (status, planned_start_at);
```

Проверочный запрос:

```sql
EXPLAIN ANALYZE
SELECT
    production_order_id,
    order_number,
    status,
    planned_start_at
FROM production_orders
WHERE status = 'Completed'
  AND planned_start_at >= '2026-07-01'
  AND planned_start_at < '2026-10-01';
```

Результат:

```text
Index Scan using idx_production_orders_status_start on production_orders
(cost=0.15..8.17 rows=1 width=138)
(actual time=0.163..0.165 rows=6 loops=1)

Index Cond:
(
    (status = 'Completed'::production_order_status)
    AND
    (planned_start_at >= '2026-07-01 00:00:00'::timestamp without time zone)
    AND
    (planned_start_at < '2026-10-01 00:00:00'::timestamp without time zone)
)

Index Searches: 1
Buffers: shared hit=2
Planning Time: 0.121 ms
Execution Time: 2.993 ms
```

Вывод:

- PostgreSQL использовал `Index Scan`;
- в `Index Cond` задействованы оба поля индекса;
- планировщик ожидал 1 строку, фактически получено 6 строк;
- индекс соответствует предполагаемому сценарию поиска.

---

## 6. Проверка полнотекстового GIN-индекса

Поисковый запрос:

```sql
SELECT
    product_id,
    article,
    name,
    description
FROM products
WHERE to_tsvector(
          'russian',
          coalesce(name, '') || ' ' || coalesce(description, '')
      )
      @@ plainto_tsquery('russian', 'шампунь');
```

Результат поиска:

```text
SH500
SH250
```

При стандартных настройках `EXPLAIN ANALYZE` выбрал:

```text
Seq Scan on products
```

Причина: таблица `products` содержит очень мало строк, поэтому последовательное чтение дешевле обращения к индексу.

Для учебной проверки индекс был принудительно сделан предпочтительным:

```sql
SET enable_seqscan = off;
```

После этого план показал:

```text
Bitmap Heap Scan on products
  -> Bitmap Index Scan on idx_products_fts
```

Дополнительные показатели:

```text
Index Searches: 1
rows=2
Execution Time: 0.113 ms
```

После проверки настройка была восстановлена:

```sql
SET enable_seqscan = on;
```

Отключение `Seq Scan` использовалось только для демонстрации. В рабочей системе выбор плана должен оставаться за оптимизатором PostgreSQL.

---

## 7. Проверка частичного индекса

Проверяемый индекс:

```sql
CREATE UNIQUE INDEX uq_specifications_one_active_per_product
    ON specifications (product_id)
    WHERE status = 'Active';
```

В тестовых данных условию `status = 'Active'` соответствуют 5 строк.

Проверочный запрос:

```sql
EXPLAIN ANALYZE
SELECT
    specification_id,
    product_id,
    version,
    status
FROM specifications
WHERE product_id = 1
  AND status = 'Active';
```

Результат:

```text
Index Scan using uq_specifications_one_active_per_product on specifications
Index Cond: (product_id = 1)
Index Searches: 1
Planning Time: 0.093 ms
Execution Time: 0.031 ms
```

PostgreSQL самостоятельно выбрал частичный индекс без дополнительных настроек.

---

## 8. Комментарии к индексам

Назначение индексов хранится не только в этом документе, но и непосредственно в PostgreSQL через:

```sql
COMMENT ON INDEX
```

Пример:

```sql
COMMENT ON INDEX idx_production_orders_status_start IS
'Ускоряет поиск заказов определённого статуса по периоду планового запуска';
```

Проверка комментариев:

```sql
SELECT
    c.relname AS index_name,
    obj_description(c.oid, 'pg_class') AS comment
FROM pg_class AS c
JOIN pg_namespace AS n
    ON n.oid = c.relnamespace
WHERE c.relkind = 'i'
  AND n.nspname = 'public'
  AND obj_description(c.oid, 'pg_class') IS NOT NULL
ORDER BY c.relname;
```

Комментарии добавлены для простых, составных, полнотекстового и частичного индексов.

---

## 9. Проблемы и выводы

### 9.1. Маленький объём данных

На маленьких таблицах PostgreSQL часто предпочитает `Seq Scan`, даже если подходящий индекс существует.

Это не означает, что индекс создан неправильно. Оптимизатор выбирает наиболее дешёвый план для текущего объёма данных.

Такое поведение было получено при проверке полнотекстового GIN-индекса.

### 9.2. EXPLAIN и EXPLAIN ANALYZE

`EXPLAIN` показывает предполагаемый план.

`EXPLAIN ANALYZE` реально выполняет запрос и дополнительно показывает:

- фактическое количество строк;
- время выполнения;
- количество поисков по индексу;
- использование буферов.

Поэтому для практической проверки использовался прежде всего `EXPLAIN ANALYZE`.

### 9.3. Оценки планировщика не всегда совпадают с фактическими данными

Для `idx_production_orders_status_start` PostgreSQL ожидал:

```text
rows=1
```

Фактически было получено:

```text
rows=6
```

Это нормальная ситуация: планировщик принимает решение на основании статистики и оценок селективности.

### 9.4. Порядок полей составного индекса важен

Индекс:

```text
(status, planned_start_at)
```

хорошо соответствует запросам:

```sql
WHERE status = ...
  AND planned_start_at >= ...
  AND planned_start_at < ...
```

Он также может использоваться при фильтрации только по `status`.

Для запроса только по `planned_start_at` такой индекс значительно менее удобен, поскольку `planned_start_at` не является первым полем индекса.

### 9.5. Низкая кардинальность не исключает использование поля в индексе

Поле `status` само по себе имеет низкую кардинальность и отдельный индекс по нему часто малоэффективен.

В составном индексе:

```text
(status, planned_start_at)
```

оно становится полезным в сочетании с более селективным полем времени.

### 9.6. FOREIGN KEY не создаёт индекс автоматически

PostgreSQL автоматически создаёт индексы для `PRIMARY KEY` и `UNIQUE`.

Для `FOREIGN KEY` индекс автоматически не создаётся. Поэтому некоторые индексы на внешние ключи были добавлены вручную под реальные `JOIN` и поисковые запросы.

### 9.7. Индексы имеют стоимость

Индексы ускоряют чтение, но:

- занимают место;
- обновляются при `INSERT`;
- обновляются при `UPDATE`;
- обновляются при `DELETE`.

Поэтому индексировать каждый столбец без конкретного сценария использования нецелесообразно.

---

## 10. Итог

В рамках работы выполнено:

1. Проанализированы предполагаемые запросы и кардинальность полей.
2. Созданы простые и составные B-tree индексы.
3. Создан полнотекстовый GIN-индекс.
4. Использован частичный уникальный индекс.
5. Проверено фактическое использование индексов через `EXPLAIN ANALYZE`.
6. Для индексов добавлены комментарии в PostgreSQL.
7. Зафиксированы особенности планировщика, ограничения и выявленные проблемы.

Итого в проекте используются:

- 14 дополнительных индексов в `sql/indexes.sql`;
- 1 частичный уникальный индекс в `sql/constraints.sql`;
- автоматически созданные индексы для `PRIMARY KEY` и `UNIQUE`.
