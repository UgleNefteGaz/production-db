# Базовые ограничения целостности

## 1. Назначение

Документ фиксирует ограничения, которые входят в основную физическую схему `db/schema.sql`.

Подробный состав полей и их типы приведены в `docs/data-dictionary.md`. Дополнительные бизнес-ограничения описаны в `docs/additional-constraints.md`, а межтабличные правила - в `docs/triggers.md`.

В основной схеме используются:

- `PRIMARY KEY`;
- `FOREIGN KEY`;
- `NOT NULL`;
- `UNIQUE`;
- `CHECK`;
- `DEFAULT`;
- ENUM-типы;
- `ON DELETE RESTRICT`;
- `ON DELETE CASCADE`.

## 2. Ограничения по таблицам

### products

- `product_id` - `PRIMARY KEY`;
- `article` - `UNIQUE`;
- `is_active` - `DEFAULT true`.

Связь:

```text
specifications.product_id
-> products.product_id
ON DELETE RESTRICT
```

### materials

- `material_id` - `PRIMARY KEY`;
- `code` - `UNIQUE`;
- `is_active` - `DEFAULT true`.

Связи:

```text
specification_items.material_id
-> materials.material_id
ON DELETE RESTRICT

material_usage.material_id
-> materials.material_id
ON DELETE RESTRICT
```

### specifications

- `specification_id` - `PRIMARY KEY`;
- `product_id` - `FOREIGN KEY`;
- `(product_id, version)` - `UNIQUE`;
- `CHECK (valid_to >= valid_from)`;
- `status` - `DEFAULT 'Draft'`;
- `created_at` - `DEFAULT CURRENT_TIMESTAMP`.

Связи:

```text
specifications.product_id
-> products.product_id
ON DELETE RESTRICT

specification_items.specification_id
-> specifications.specification_id
ON DELETE CASCADE

production_orders.specification_id
-> specifications.specification_id
ON DELETE RESTRICT
```

### specification_items

- `specification_item_id` - `PRIMARY KEY`;
- `specification_id` - `FOREIGN KEY`;
- `material_id` - `FOREIGN KEY`;
- `(specification_id, material_id)` - `UNIQUE`;
- `CHECK (quantity_per_unit > 0)`;
- `CHECK (waste_percent >= 0 AND waste_percent <= 100)`;
- `waste_percent` - `DEFAULT 0`.

Связи:

```text
specification_items.specification_id
-> specifications.specification_id
ON DELETE CASCADE

specification_items.material_id
-> materials.material_id
ON DELETE RESTRICT
```

### production_orders

- `production_order_id` - `PRIMARY KEY`;
- `order_number` - `UNIQUE`;
- `specification_id` - `FOREIGN KEY`;
- `CHECK (planned_quantity > 0)`;
- `CHECK (planned_end_at >= planned_start_at)`;
- `status` - `DEFAULT 'Created'`;
- `created_at` - `DEFAULT CURRENT_TIMESTAMP`.

Связи:

```text
production_orders.specification_id
-> specifications.specification_id
ON DELETE RESTRICT

production_batches.production_order_id
-> production_orders.production_order_id
ON DELETE RESTRICT
```

### production_batches

- `batch_id` - `PRIMARY KEY`;
- `production_order_id` - `FOREIGN KEY`;
- `(production_order_id, batch_number)` - `UNIQUE`;
- `CHECK (planned_quantity > 0)`;
- `CHECK (actual_quantity >= 0)`;
- `CHECK (completed_at >= started_at)`;
- `status` - `DEFAULT 'Planned'`.

Связи:

```text
production_batches.production_order_id
-> production_orders.production_order_id
ON DELETE RESTRICT

batch_operations.batch_id
-> production_batches.batch_id
ON DELETE RESTRICT

material_usage.batch_id
-> production_batches.batch_id
ON DELETE RESTRICT

quality_checks.batch_id
-> production_batches.batch_id
ON DELETE RESTRICT
```

### production_lines

- `production_line_id` - `PRIMARY KEY`;
- `code` - `UNIQUE`;
- `status` - `DEFAULT 'Active'`.

Связь:

```text
batch_operations.production_line_id
-> production_lines.production_line_id
ON DELETE RESTRICT
```

### operations

- `operation_id` - `PRIMARY KEY`;
- `code` - `UNIQUE`.

Связь:

```text
batch_operations.operation_id
-> operations.operation_id
ON DELETE RESTRICT
```

### employees

- `employee_id` - `PRIMARY KEY`;
- `personnel_number` - `UNIQUE`;
- `is_active` - `DEFAULT true`.

Связи:

```text
shifts.supervisor_employee_id
-> employees.employee_id
ON DELETE RESTRICT

batch_operations.employee_id
-> employees.employee_id
ON DELETE RESTRICT

material_usage.employee_id
-> employees.employee_id
ON DELETE RESTRICT

quality_checks.employee_id
-> employees.employee_id
ON DELETE RESTRICT
```

Для деактивации сотрудника используется `is_active = false` вместо удаления исторических данных.

### shifts

- `shift_id` - `PRIMARY KEY`;
- `supervisor_employee_id` - `FOREIGN KEY`;
- `(shift_date, shift_number)` - `UNIQUE`;
- `CHECK (shift_number > 0)`;
- `CHECK (completed_at > started_at)`.

Связи:

```text
shifts.supervisor_employee_id
-> employees.employee_id
ON DELETE RESTRICT

batch_operations.shift_id
-> shifts.shift_id
ON DELETE RESTRICT
```

### batch_operations

- `batch_operation_id` - `PRIMARY KEY`;
- `batch_id`, `operation_id`, `production_line_id`, `employee_id`, `shift_id` - `FOREIGN KEY`;
- `(batch_id, sequence_no)` - `UNIQUE`;
- `CHECK (sequence_no > 0)`;
- `CHECK (processed_quantity >= 0)`;
- `CHECK (completed_at >= started_at)`;
- `status` - `DEFAULT 'Planned'`.

Все внешние ключи используют `ON DELETE RESTRICT`.

### material_usage

- `material_usage_id` - `PRIMARY KEY`;
- `batch_id`, `material_id`, `employee_id` - `FOREIGN KEY`;
- `CHECK (quantity_used > 0)`;
- `recorded_at` - `DEFAULT CURRENT_TIMESTAMP`.

Связи:

```text
material_usage.batch_id
-> production_batches.batch_id
ON DELETE RESTRICT

material_usage.material_id
-> materials.material_id
ON DELETE RESTRICT

material_usage.employee_id
-> employees.employee_id
ON DELETE RESTRICT
```

Несколько записей расхода одного материала для одной партии разрешены.

### quality_checks

- `quality_check_id` - `PRIMARY KEY`;
- `batch_id`, `employee_id` - `FOREIGN KEY`;
- `checked_at` - `DEFAULT CURRENT_TIMESTAMP`.

Связи:

```text
quality_checks.batch_id
-> production_batches.batch_id
ON DELETE RESTRICT

quality_checks.employee_id
-> employees.employee_id
ON DELETE RESTRICT

defects.quality_check_id
-> quality_checks.quality_check_id
ON DELETE CASCADE
```

Для одной партии допускается несколько проверок одного этапа.

### defect_types

- `defect_type_id` - `PRIMARY KEY`;
- `code` - `UNIQUE`;
- `is_active` - `DEFAULT true`.

Связь:

```text
defects.defect_type_id
-> defect_types.defect_type_id
ON DELETE RESTRICT
```

Для вывода типа дефекта из использования применяется `is_active = false`.

### defects

- `defect_id` - `PRIMARY KEY`;
- `quality_check_id`, `defect_type_id` - `FOREIGN KEY`;
- `(quality_check_id, defect_type_id)` - `UNIQUE`;
- `CHECK (quantity > 0)`.

Связи:

```text
defects.quality_check_id
-> quality_checks.quality_check_id
ON DELETE CASCADE

defects.defect_type_id
-> defect_types.defect_type_id
ON DELETE RESTRICT
```

Один тип дефекта в рамках одной проверки хранится одной строкой с суммарным количеством.

## 3. Политика удаления

Основной принцип - сохранять производственную историю.

`ON DELETE CASCADE` используется только там, где дочерняя запись теряет смысл без родительской:

```text
specifications
-> specification_items

quality_checks
-> defects
```

Для остальных производственных связей используется `ON DELETE RESTRICT`.

## 4. ENUM-типы

### specification_status

```text
Draft
Active
Archived
```

### production_order_status

```text
Created
Planned
InProgress
Completed
Cancelled
```

### production_batch_status

```text
Planned
InProgress
Completed
Rejected
Cancelled
```

### production_line_status

```text
Active
Maintenance
Inactive
```

### batch_operation_status

```text
Planned
InProgress
Completed
Cancelled
```

### quality_check_stage

```text
Intermediate
Final
```

### quality_check_result

```text
Passed
Failed
Conditional
```

### defect_severity

```text
Minor
Major
Critical
```

## 5. Граница ответственности

Этот документ описывает только ограничения основной схемы.

Дополнительные проверки одной строки находятся в `docs/additional-constraints.md`.

Правила, требующие чтения других строк или таблиц, находятся в `docs/triggers.md`.
