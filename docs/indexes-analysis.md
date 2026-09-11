# Анализ запросов и индексов

## 1. Назначение документа

Документ содержит анализ предполагаемых запросов к базе данных, оценку кардинальности используемых полей и обоснование дополнительных индексов.

Кардинальность оценивается относительно ожидаемого количества строк:

- высокая - большинство значений уникальны или редко повторяются;
- средняя - значения повторяются, но различных значений достаточно много;
- низкая - поле содержит небольшой набор часто повторяющихся значений.

---

## 2. Общие принципы выбора индексов

Индексы создаются для полей, которые предполагается часто использовать в:

- `WHERE`;
- `JOIN`;
- `ORDER BY`;
- выборках за период;
- аналитических отчётах.

Отдельные индексы не создаются для `PRIMARY KEY` и `UNIQUE`-полей, так как PostgreSQL автоматически создаёт для них уникальные B-tree индексы.

Поля с низкой кардинальностью, например `status` или `result`, обычно не индексируются отдельно. В данной модели они используются преимущественно в составных индексах совместно с полями даты и времени.

---

## 3. Производственные заказы

Таблица: `production_orders`

### Предполагаемые запросы

Поиск производственных заказов:

- по спецификации;
- по статусу;
- за определённый период;
- по статусу и периоду планового запуска.

Пример:

```sql
SELECT *
FROM production_orders
WHERE status = 'Completed'
  AND planned_start_at >= '2026-09-01'
  AND planned_start_at < '2026-10-01';
```

### Кардинальность

`specification_id`

Средняя кардинальность. Одна спецификация может использоваться во многих производственных заказах, но количество различных спецификаций может быть достаточно большим.

`status`

Низкая кардинальность. Поле содержит небольшой фиксированный набор значений ENUM.

`planned_start_at`

Высокая кардинальность. Дата и время начала производства обычно отличаются между заказами.

### Индексы

```sql
CREATE INDEX idx_production_orders_specification
    ON production_orders (specification_id);
```

Индекс ускоряет поиск производственных заказов по определённой спецификации и соединение `production_orders` с `specifications`.

```sql
CREATE INDEX idx_production_orders_status_start
    ON production_orders (status, planned_start_at);
```

Индекс предназначен для отчётов по заказам определённого статуса за заданный период.

## 4. Производственные партии

Таблица: `production_batches`

### Предполагаемые запросы

Основные варианты поиска:

- партии определённого статуса, запуск которых произошёл в заданный период;
- партии, запущенные за период;
- партии, находящиеся в производстве;
- завершённые партии за период.

Пример:

```sql
SELECT *
FROM production_batches
WHERE status = 'InProgress'
  AND started_at >= '2026-09-01'
  AND started_at < '2026-10-01';
```

### Кардинальность

`status`

Низкая кардинальность.

`started_at`

Высокая кардинальность.

### Индекс

```sql
CREATE INDEX idx_production_batches_status_started
    ON production_batches (status, started_at);
```

Индекс ускоряет выборку партий определённого статуса за заданный период.

Отдельный индекс только по `status` не создаётся из-за низкой кардинальности этого поля.

## 5. Состав спецификаций

Таблица: `specification_items`

### Предполагаемые запросы

Необходимо определять:

- в каких спецификациях используется конкретный материал;
- какие продукты зависят от определённого материала.

Пример:

```sql
SELECT *
FROM specification_items
WHERE material_id = 5;
```

### Кардинальность

`material_id`

Средняя кардинальность. Один материал может использоваться во множестве спецификаций.

### Индекс

```sql
CREATE INDEX idx_specification_items_material
    on specification_items (material_id);
```

Существующий уникальный индекс имеет структуру:

```text
(specification_id, material_id)
```

Он подходит для поиска по `specification_id`, но не оптимален для запросов только по `material_id`.

## 6. Производственные операции

Таблица: `batch_operations`

Эта таблица предполагается одной из наиболее активно используемых таблиц системы.

### 6.1. Операции, начатые на конкретной производственной линии за период

Пример:

```sql
SELECT *
FROM batch_operations
WHERE production_line_id = 2
  AND started_at >= '2026-09-01'
  AND started_at < '2026-10-01';
```

Кардинальность:

- `production_line_id` - низкая или средняя;
- `started_at` - высокая.

Индекс:

```sql
CREATE INDEX idx_batch_operations_line_started
    ON batch_operations (production_line_id, started_at);
```

Назначение: поиск операций, начатых на конкретной производственной линии за заданный период.

### 6.2. Операции, начатые сотрудником за период

Пример:

```sql
SELECT *
FROM batch_operations
WHERE employee_id = 10
  AND started_at >= '2026-09-01'
  AND started_at < '2026-10-01';
```

Кардинальность:

- `employee_id` - средняя;
- `started_at` - высокая.

Индекс:

```sql
CREATE INDEX idx_batch_operations_employee_started
    ON batch_operations (employee_id, started_at);
```

Назначение: поиск операций, начатых конкретным сотрудником за заданный период.

### 6.3. Операции смены

Пример:

```sql
SELECT *
FROM batch_operations
WHERE shift_id = 15;
```

`shift_id` имеет среднюю или высокую кардинальность по мере накопления истории.

Индекс:

```sql
CREATE INDEX idx_batch_operationc_shift
    ON batch_operations (shift_id);
```

Назначение: получение всех операций, выполненных в рамках конкретной смены.

### 6.4. Поиск по типу операции

Пример:

```sql
SELECT *
FROM batch_operations
WHERE operation_id = 3;
```

`operation_id` имеет низкую или среднюю кардинальность.

Индекс:

```sql
CREATE INDEX idx_batch_operations_operation
    ON batch_operations (operation_id);
```

Назначение: анализ выполнения определённого типа технологической операции по различным партиям.

## 7. Расход материалов

Таблица: `material_usage`

### 7.1. Расход материала по партии

Пример:

```sql
SELECT SUM(quantity_used)
FROM material_usage
WHERE batch_id = 10
  AND material_id = 5;
```

Кардинальность:

- `batch_id` - высокая;
- `material_id` - средняя.

Индекс:

```sql
CREATE INDEX idx_material_usage_batch_material
    ON material_usage (batch_id, material_id);
```

Назначение: расчёт фактического расхода конкретного материала в рамках производственной партии.

### 7.2. Зарегистрированный расход материала за период

Пример:

```sql
SELECT SUM(quantity_used)
FROM material_usage
WHERE material_id = 5
  AND recorded_at >= '2026-09-01'
  AND recorded_at < '2026-10-01';
```

Кардинальность:

- `material_id` - средняя;
- `recorded_at` - высокая.

Индекс:

```sql
CREATE INDEX idx_material_usage_material_recorded
    ON material_usage (material_id, recorded_at);
```

Назначение: анализ расхода определённого материала за выбранный период.

## 8. Контроль качества

Таблица: `quality_checks`

### 8.1. История проверок партии

Пример:

```sql
SELECT *
FROM quality_checks
WHERE batch_id = 25
ORDER BY checked_at;
```

Кардинальность:

- `batch_id` - высокая;
- `checked_at` - высокая.

Индекс:

```sql
CREATE INDEX idx_quality_checks_batch_checked
    ON quality_checks (batch_id, checked_at);
```

Назначение: получение истории контроля качества производственной партии в хронологическом порядке.

### 8.2. Проблемные проверки за период

Пример:

```sql
SELECT *
FROM quality_checks
WHERE result = 'Failed'
  AND checked_at >= '2026-09-01'
  AND checked_at < '2026-10-01';
```

Кардинальность:

- `result` - низкая;
- `checked_at` - высокая.

Индекс:

```sql
CREATE INDEX idx_quality_checks_result_checked
    ON quality_checks (result, checked_at);
```

Назначение: поиск неуспешных и условно успешных проверок качества за определённый период.

Отдельный индекс только по `result` не создаётся по причине низкой кардинальности поля.

## 9. Дефекты

Таблица: `defects`

### Предполагаемые запросы:

Основные задачи:

- подсчёт дефектов определённого типа;
- определение наиболее распространённых причин брака;
- построение статистики по видам дефектов.

Пример:

```sql
SELECT *
FROM defects
WHERE defect_type_id = 3;
```

### Кардинальность

`defect_type_id`

Низкая или средняя кардинальность. Количество типов дефектов значительно меньше количества зарегистрированных случаев брака.

### Индекс

```sql
CREATE INDEX idx_defects_type
    ON defects (defect_type_id);
```

Существующий уникальный индекс:

```text
(quality_check_id, defect_type_id)
```

не заменяет этот индекс для запросов только по `defect_type_id`, поскольку `defect_type_id` является вторым полем составного индекса.

## 10. Сводная таблица дополнительных индексов

| Таблица | Поля индекса | Тип | Назначение |
|---|---|---|---|
| `production_orders` | `specification_id` | простой | Заказы по спецификации |
| `production_orders` | `status`, `planned_start_at` | композитный | Заказы по статусу за период |
| `production_batches` | `status`, `started_at` | композитный | Партии по статусу за период |
| `specification_items` | `material_id` | простой | Спецификации по материалу |
| `batch_operations` | `production_line_id`, `started_at` | композитный | Операции, начатые на линии за период |
| `batch_operations` | `employee_id`, `started_at` | композитный | Операции, начатые сотрудником за период |
| `batch_operations` | `shift_id` | простой | Операции смены |
| `batch_operations` | `operation_id` | простой | Статистика по операциям |
| `material_usage` | `batch_id`, `material_id` | композитный | Расход материала по партии |
| `material_usage` | `material_id`, `recorded_at` | композитный | Расход материала за период |
| `quality_checks` | `batch_id`, `checked_at` | композитный | История проверок партии |
| `quality_checks` | `result`, `checked_at` | композитный | Проверки по результату за период |
| `defects` | `defect_type_id` | простой | Анализ типов дефектов|

Всего создано 13 дополнительных индексов.

## 11. Индексы, которые не требуется создавать вручную

Отдельные индексы не создаются для первичных ключей, поскольку PostgreSQL автоматически индексирует `PRIMARY KEY` и `UNIQUE`.

Поэтому отдельные индексы не требуются для первичных ключей, например:

- `products.product_id`;
- `materials.material_id`;
- `production_orders.production_order_id`;
- `production_batches.batch_id`.

Также отдельные индексы не требуются для полей с ограничением `UNIQUE`, например:

- `products.article`;
- `materials.code`;
- `production_orders.order_number`;
- `production_lines.code`;
- `operations.code`;
- `employees.personnel_number`;
- `defect_types.code`.

## 12. Итог

Дополнительные индексы выбраны исходя из предполагаемых сценариев использования базы данных.

Основные направления оптимизации:

- поиск связанных объектов по внешним ключам;
- выборки за период;
- анализ производственных операций;
- анализ загрузки линий и сотрудников;
- учёт расхода материалов;
- контроль качества;
- анализ производственного брака.

Для полей с низкой кардинальностью преимущественно используются композитные индексы совместно с полями даты и времени.

Это позволяет ускорить наиболее вероятные запросы без избыточного индексирования всех полей базы данных.
