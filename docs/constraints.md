# Ограничения целостности базы данных

## 1. Общие правила

В базе данных используются следующие механизмы обеспечения целостности:

- PRIMARY KEY для идентификации записей;
- FOREIGN KEY для обеспечения ссылочной целостности;
- NOT NULL для обязательных атрибутов;
- UNIQUE для уникальных бизнес-идентификаторов;
- CHECK для проверки числовых значений и временных интервалов;
- ENUM для ограниченного набора состояний;
- DEFAULT для значений, устанавливаемых автоматически.

Удаление основных производственных данных должно быть ограничено.
Для справочных записей вместо удаления преимущественно используется признак `is_active`.

---

## 2. products

### Обязательные поля

- product_id
- name
- article
- unit
- description
- is_active

### Ограничения

- product_id - PRIMARY KEY;
- article - UNIQUE;
- is_active - DEFAULT true.

### Удаление

Удаление продукта запрещается, если существуют связанные спецификации.

`specifications.product_id -> products.product_id ON DELETE RESTRICT`

---

## 3. materials

### Обязательные поля

- material_id
- code
- name
- unit
- description
- is_active

### Ограничения

- material_id - PRIMARY KEY;
- code - UNIQUE;
- is_active - DEFAULT true.

### Удаление

Удаление материала запрещается, если он используется:

- в спецификациях;
- в фактическом расходе материалов.

`specification_items.material_id -> materials.material_id ON DELETE RESTRICT`

`material_usage.material_id -> materials.material_id ON DELETE RESTRICT`

---

## 4. specifications

### Обязательные поля

- specification_id
- product_id
- version
- name
- valid_from
- valid_to
- status
- created_at

### Ограничения

- specification_id - PRIMARY KEY;
- product_id - FOREIGN KEY;
- комбинация product_id + version - UNIQUE;
- valid_to не может быть меньше valid_from;
- created_at - DEFAULT CURRENT_TIMESTAMP.

### Дополнительное правило

Для одного продукта рекомендуется иметь не более одной активной спецификации одновременно.

### Удаление

Продукт:

`specifications.product_id -> products.product_id ON DELETE RESTRICT`

Строки состава спецификации:

`specification_items.specification_id -> specifications.specification_id ON DELETE CASCADE`

Если удаляется спецификация, ее состав удаляется автоматически.

Удаление спецификации запрещается, если на нее существуют производственные заказы:

`production_orders.specification_id -> specifications.specification_id ON DELETE RESTRICT`

---

## 5. specification_items

### Обязательные поля

- specification_item_id
- specification_id
- material_id
- quantity_per_unit
- waste_percent

### Ограничения

- specification_item_id - PRIMARY KEY;
- specification_id - FOREIGN KEY;
- material_id - FOREIGN KEY;
- specification_id + material_id - UNIQUE;
- quantity_per_unit > 0;
- waste_percent >= 0;
- waste_percent <= 100;
- waste_percent - DEFAULT 0.

### Удаление

Specification:

`specification_items.specification_id -> specifications.specification_id ON DELETE CASCADE`

Material:

`specification_items.material_id -> materials.material_id ON DELETE RESTRICT`

---

## 6. production_orders

### Обязательные поля

- production_order_id
- order_number
- specification_id
- planned_quantity
- planned_start_at
- planned_end_at
- status
- created_at

### Ограничения

- production_order_id - PRIMARY KEY;
- order_number - UNIQUE;
- specification_id - FOREIGN KEY;
- planned_quantity > 0;
- planned_end_at не может быть меньше planned_start_at;
- created_at - DEFAULT CURRENT_TIMESTAMP.

### Удаление

Specification:

`production_orders.specification_id -> specifications.specification_id ON DELETE RESTRICT`

Производственный заказ нельзя удалить, если существуют связанные партии:

`production_batches.production_order_id -> production_orders.production_order_id ON DELETE RESTRICT`

---

## 7. production_batches

### Обязательные поля

- batch_id
- production_order_id
- batch_number
- planned_quantity
- actual_quantity
- started_at
- completed_at
- status

### Ограничения

- batch_id - PRIMARY KEY;
- production_order_id - FOREIGN KEY;
- production_order_id + batch_number - UNIQUE;
- planned_quantity > 0;
- actual_quantity >= 0;
- completed_at не может быть меньше started_at.

### Удаление

ProductionOrder:

`production_batches.production_order_id -> production_orders.production_order_id ON DELETE RESTRICT`

Партию нельзя удалить, если существуют связанные:

- технологические операции;
- записи расхода материалов;
- проверки качества.

`batch_operations.batch_id -> production_batches.batch_id ON DELETE RESTRICT`

`material_usage.batch_id -> production_batches.batch_id ON DELETE RESTRICT`

`quality_checks.batch_id -> production_batches.batch_id ON DELETE RESTRICT`

---

## 8. production_lines

### Обязательные поля

- production_line_id
- code
- name
- location
- status
- description

### Ограничения

- production_line_id - PRIMARY KEY;
- code - UNIQUE;
- status - DEFAULT Active.

### Удаление

Производственную линию нельзя удалить, если она использовалась в технологических операциях.

`batch_operations.production_line_id -> production_lines.production_line_id ON DELETE RESTRICT`

---

## 9. operations

### Обязательные поля

- operation_id
- code
- name
- description

### Ограничения

- operation_id - PRIMARY KEY;
- code - UNIQUE.

### Удаление

Тип операции нельзя удалить, если существуют записи о ее выполнении.

`batch_operations.operation_id -> operations.operation_id ON DELETE RESTRICT`

---

## 10. employees

### Обязательные поля

- employee_id
- personnel_number
- full_name
- position
- is_active

### Ограничения

- employee_id - PRIMARY KEY;
- personnel_number - UNIQUE;
- is_active - DEFAULT true.

### Удаление

Сотрудников, участвовавших в производственных процессах, физически удалять не следует.

Для уволенного сотрудника:

`is_active = false`

Связанные внешние ключи:

`shifts.supervisor_employee_id -> employees.employee_id ON DELETE RESTRICT`

`batch_operations.employee_id -> employees.employee_id ON DELETE RESTRICT`

`material_usage.employee_id -> employees.employee_id ON DELETE RESTRICT`

`quality_checks.employee_id -> employees.employee_id ON DELETE RESTRICT`

---

## 11. shifts

### Обязательные поля

- shift_id
- shift_date
- shift_number
- started_at
- completed_at
- supervisor_employee_id

### Ограничения

- shift_id - PRIMARY KEY;
- supervisor_employee_id - FOREIGN KEY;
- shift_date + shift_number - UNIQUE;
- shift_number > 0;
- completed_at > started_at.

shift_date обозначает производственный день и может отличаться от календарной даты завершения ночной смены.

### Удаление

Employee:

`shifts.supervisor_employee_id -> employees.employee_id ON DELETE RESTRICT`

Смена не удаляется, если существуют связанные производственные операции:

`batch_operations.shift_id -> shifts.shift_id ON DELETE RESTRICT`

---

## 12. batch_operations

### Обязательные поля

- batch_operation_id
- batch_id
- operation_id
- production_line_id
- employee_id
- shift_id
- sequence_no
- started_at
- completed_at
- processed_quantity
- status

### Ограничения

- batch_operation_id - PRIMARY KEY;
- все ссылки являются FOREIGN KEY;
- batch_id + sequence_no - UNIQUE;
- sequence_no > 0;
- processed_quantity >= 0;
- completed_at не может быть меньше started_at.

### Удаление

Для всех внешних ключей используется ON DELETE RESTRICT.

`batch_operations.batch_id -> production_batches.batch_id ON DELETE RESTRICT`

`batch_operations.operation_id -> operations.operation_id ON DELETE RESTRICT`

`batch_operations.production_line_id -> production_lines.production_line_id ON DELETE RESTRICT`

`batch_operations.employee_id -> employees.employee_id ON DELETE RESTRICT`

`batch_operations.shift_id -> shifts.shift_id ON DELETE RESTRICT`

История выполнения производственных операций должна сохраняться.

---

## 13. material_usage

### Обязательные поля

- material_usage_id
- batch_id
- material_id
- employee_id
- quantity_used
- material_lot_number
- recorded_at

### Ограничения

- material_usage_id - PRIMARY KEY;
- batch_id - FOREIGN KEY;
- material_id - FOREIGN KEY;
- employee_id - FOREIGN KEY;
- quantity_used > 0;
- recorded_at - DEFAULT CURRENT_TIMESTAMP.

Несколько записей расхода одного материала для одной партии разрешены.

### Удаление

Для внешних ключей используется ON DELETE RESTRICT.

`material_usage.batch_id -> production_batches.batch_id ON DELETE RESTRICT`

`material_usage.material_id -> materials.material_id ON DELETE RESTRICT`

`material_usage.employee_id -> employees.employee_id ON DELETE RESTRICT`

---

## 14. quality_checks

### Обязательные поля

- quality_check_id
- batch_id
- employee_id
- check_stage
- checked_at
- result
- notes

### Ограничения

- quality_check_id - PRIMARY KEY;
- batch_id - FOREIGN KEY;
- employee_id - FOREIGN KEY;
- checked_at - DEFAULT CURRENT_TIMESTAMP.

Для одной партии допускается несколько проверок одного этапа.

### Удаление

Batch:

`quality_checks.batch_id -> production_batches.batch_id ON DELETE RESTRICT`

Employee:

`quality_checks.employee_id -> employees.employee_id ON DELETE RESTRICT`

При удалении проверки качества связанные записи defects удаляются автоматически:

`defects.quality_check_id -> quality_checks.quality_check_id ON DELETE CASCADE`

---

## 15. defect_types

### Обязательные поля

- defect_type_id
- code
- name
- severity
- description
- is_active

### Ограничения

- defect_type_id - PRIMARY KEY;
- code - UNIQUE;
- is_active - DEFAULT true.

### Удаление

Тип дефекта нельзя удалить, если он использован в зарегистрированном браке.

`defects.defect_type_id -> defect_types.defect_type_id ON DELETE RESTRICT`

Вместо удаления используется:

`is_active = false`

---

## 16. defects

### Обязательные поля

- defect_id
- quality_check_id
- defect_type_id
- quantity
- description

### Ограничения

- defect_id - PRIMARY KEY;
- quality_check_id - FOREIGN KEY;
- defect_type_id - FOREIGN KEY;
- quantity > 0;
- quality_check_id + defect_type_id - UNIQUE.

Один тип дефекта в рамках одной проверки должен храниться одной записью с суммарным количеством.

### Удаление

QualityCheck:

`defects.quality_check_id -> quality_checks.quality_check_id ON DELETE CASCADE`

DefectType:

`defects.defect_type_id -> defect_types.defect_type_id ON DELETE RESTRICT`

---

## 17. Правила ENUM

### specification_status

- Draft
- Active
- Archived

### production_order_status

- Created
- Planned
- InProgress
- Completed
- Cancelled

### production_batch_status

- Planned
- InProgress
- Completed
- Rejected
- Cancelled

### production_line_status

- Active
- Maintenance
- Inactive

### batch_operation_status

- Planned
- InProgress
- Completed
- Cancelled

### quality_check_stage

- Intermediate
- Final

### quality_check_result

- Passed
- Failed
- Conditional

### defect_severity

- Minor
- Major
- Critical
