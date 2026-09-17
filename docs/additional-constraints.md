# Дополнительные ограничения бизнес-логики

## 1. Назначение

Дополнительные ограничения реализованы в `sql/constraints.sql` поверх базовой схемы `db/schema.sql`.

Они предотвращают логически некорректные состояния, которые формально удовлетворяют базовым типам, ключам и простым проверкам.

Реализовано:

- 8 дополнительных `CHECK`;
- 1 частичный уникальный индекс.

## 2. Сводная таблица

| Объект | Имя | Правило |
|---|---|---|
| `specifications` | `chk_specification_valid_period` | `valid_to` нельзя задавать без `valid_from` |
| `specifications` | `uq_specifications_one_active_per_product` | у продукта может быть только одна активная спецификация |
| `production_orders` | `chk_order_planned_period` | `planned_end_at` нельзя задавать без `planned_start_at` |
| `production_batches` | `chk_batch_completion_requires_start` | `completed_at` требует `started_at` |
| `production_batches` | `chk_completed_batch_data` | завершённая партия должна иметь времена и `actual_quantity` |
| `batch_operations` | `chk_operation_completion_requires_start` | `completed_at` требует `started_at` |
| `batch_operations` | `chk_completed_operation_data` | завершённая операция должна иметь времена и `processed_quantity > 0` |
| `shifts` | `chk_shift_start_date` | дата начала смены должна совпадать с `shift_date` |
| `quality_checks` | `chk_quality_failure_notes` | `Failed` и `Conditional` требуют непустой `notes` |

## 3. CHECK-ограничения

### Период действия спецификации

```sql
ALTER TABLE specifications
ADD CONSTRAINT chk_specification_valid_period
CHECK (valid_to IS NULL OR valid_from IS NOT NULL);
```

Если задан `valid_to`, должно быть задано и `valid_from`.

### Плановый период заказа

```sql
ALTER TABLE production_orders
ADD CONSTRAINT chk_order_planned_period
CHECK (planned_end_at IS NULL OR planned_start_at IS NOT NULL);
```

Если задано плановое окончание, должно быть задано плановое начало.

### Фактический период партии

```sql
ALTER TABLE production_batches
ADD CONSTRAINT chk_batch_completion_requires_start
CHECK (completed_at IS NULL OR started_at IS NOT NULL);
```

Партия не может иметь фактическое завершение без фактического начала.

### Обязательные данные завершённой партии

```sql
ALTER TABLE production_batches
ADD CONSTRAINT chk_completed_batch_data
CHECK (
    status <> 'Completed'
    OR (
        started_at IS NOT NULL
        AND completed_at IS NOT NULL
        AND actual_quantity IS NOT NULL
    )
);
```

Для `Completed` обязательны `started_at`, `completed_at` и `actual_quantity`.

### Фактический период операции

```sql
ALTER TABLE batch_operations
ADD CONSTRAINT chk_operation_completion_requires_start
CHECK (completed_at IS NULL OR started_at IS NOT NULL);
```

Операция не может завершиться без зарегистрированного начала.

### Обязательные данные завершённой операции

```sql
ALTER TABLE batch_operations
ADD CONSTRAINT chk_completed_operation_data
CHECK (
    status <> 'Completed'
    OR (
        started_at IS NOT NULL
        AND completed_at IS NOT NULL
        AND processed_quantity IS NOT NULL
        AND processed_quantity > 0
    )
);
```

Для `Completed` обязательны времена выполнения и положительное `processed_quantity`.

### Дата начала смены

```sql
ALTER TABLE shifts
ADD CONSTRAINT chk_shift_start_date
CHECK (started_at::date = shift_date);
```

`shift_date` должна совпадать с календарной датой `started_at`. Завершение смены может происходить на следующие сутки.

### Комментарий при проблемном результате контроля качества

```sql
ALTER TABLE quality_checks
ADD CONSTRAINT chk_quality_failure_notes
CHECK (
    result = 'Passed'
    OR NULLIF(BTRIM(notes), '') IS NOT NULL
);
```

Для `Failed` и `Conditional` поле `notes` должно содержать непустое пояснение.

## 4. Частичный уникальный индекс

```sql
CREATE UNIQUE INDEX uq_specifications_one_active_per_product
    ON specifications (product_id)
    WHERE status = 'Active';
```

Обычное `UNIQUE (product_id, status)` не подходит, потому что запретило бы несколько `Draft` или `Archived`.

Частичный индекс контролирует только строки `status = 'Active'` и одновременно реализует правило: у одного продукта не более одной активной спецификации.

Практическая проверка использования этого индекса через `EXPLAIN ANALYZE` приведена в `docs/indexes-analysis.md`.

## 5. Проверка ограничений

Дополнительные ограничения проверялись отрицательными тестами.

Проверены попытки:

- задать `valid_to` без `valid_from`;
- создать вторую активную спецификацию продукта;
- задать `planned_end_at` без `planned_start_at`;
- завершить партию без начала;
- установить партии `Completed` без обязательных фактических данных;
- завершить операцию без начала;
- установить операции `Completed` без `processed_quantity`;
- создать смену с несогласованной датой начала;
- создать `Failed`-проверку без `notes`.

Для нарушений `CHECK` PostgreSQL возвращал SQLSTATE `23514`.

Для нарушения частичной уникальности PostgreSQL возвращал SQLSTATE `23505`.

## 6. Межтабличные правила

Правила, которым необходимо читать другие строки или таблицы, не реализуются через `CHECK`.

Уже реализованы триггерами:

- сумма плановых количеств партий не превышает план заказа;
- план заказа нельзя уменьшить ниже суммы партий;
- `Passed` несовместим с зарегистрированными дефектами;
- проверка качества должна находиться внутри периода партии.

Их описание находится в `docs/triggers.md`.

Отложено правило согласования количества дефектов с объёмом продукции, прошедшей контроль качества. В текущей модели отсутствует отдельный однозначный показатель количества продукции, предъявленной на контроль.

## 7. Итог

`sql/constraints.sql` дополняет базовую схему правилами, которые относятся к состоянию одной строки либо могут быть обеспечены частичной уникальностью.

Межтабличные правила вынесены в триггеры и не дублируются в этом документе.
