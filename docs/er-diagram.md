# ER-диаграмма базы данных

## 1. Общая структура

База данных содержит 15 сущностей и описывает производственный процесс от выпускаемой продукции и технологических спецификаций до производственных партий, операций, расхода материалов и контроля качества.

Основная цепочка данных:

products
-> specifications
-> production_orders
-> production_batches
-> batch_operations / material_usage / quality_checks
-> defects

---

## 2. Связи между сущностями

### products -> specifications

Кардинальность:

`products 1:N specifications`

Один продукт может иметь несколько версий технологической спецификации.

Каждая спецификация относится только к одному продукту.

Связь:

`specifications.product_id -> products.product_id`

---

### specifications -> specification_items

Кардинальность:

`specifications 1:N specification_items`

Одна спецификация содержит несколько строк состава.

Каждая строка состава принадлежит одной спецификации.

Связь:

`specification_items.specification_id -> specifications.specification_id`

---

### materials -> specification_items

Кардинальность:

`materials 1:N specification_items`

Один материал может использоваться во многих спецификациях.

Каждая строка спецификации относится к одному материалу.

Связь:

`specification_items.material_id -> materials.material_id`

В совокупности specification_items реализует связь M:N между specifications и materials.

---

### specifications -> production_orders

Кардинальность:

`specifications 1:N production_orders`

Одна спецификация может использоваться во многих производственных заказах.

Каждый производственный заказ использует одну конкретную спецификацию.

Связь:

`production_orders.specification_id -> specifications.specification_id`

---

### production_orders -> production_batches

Кардинальность:

`production_orders 1:N production_batches`

Один производственный заказ может быть разделен на несколько производственных партий.

Каждая партия относится к одному производственному заказу.

Связь:

`production_batches.production_order_id -> production_orders.production_order_id`

---

### production_batches -> batch_operations

Кардинальность:

`production_batches 1:N batch_operations`

Одна производственная партия проходит несколько технологических операций.

Каждая запись batch_operations описывает выполнение одной операции над одной партией.

Связь:

`batch_operations.batch_id -> production_batches.batch_id`

---

### operations -> batch_operations

Кардинальность:

`operations 1:N batch_operations`

Один тип технологической операции может выполняться над многими производственными партиями.

Каждая запись batch_operations относится к одному типу операции.

Связь:

`batch_operations.operation_id -> operations.operation_id`

---

### production_lines -> batch_operations

Кардинальность:

`production_lines 1:N batch_operations`

Одна производственная линия может использоваться для выполнения многих операций.

Каждая запись batch_operations связана с одной производственной линией.

Связь:

`batch_operations.production_line_id -> production_lines.production_line_id`

---

### employees -> batch_operations

Кардинальность:

`employees 1:N batch_operations`

Один сотрудник может участвовать во многих производственных операциях.

Каждая запись batch_operations содержит одного ответственного сотрудника.

Связь:

`batch_operations.employee_id -> employees.employee_id`

---

### shifts -> batch_operations

Кардинальность:

`shifts 1:N batch_operations`

В рамках одной смены может выполняться множество производственных операций.

Каждая запись batch_operations относится к одной смене.

Связь:

`batch_operations.shift_id -> shifts.shift_id`

---

### employees -> shifts

Кардинальность:

`employees 1:N shifts`

Один сотрудник может быть руководителем многих смен.

У каждой смены указывается один ответственный руководитель.

Связь:

`shifts.supervisor_employee_id -> employees.employee_id`

---

### production_batches -> material_usage

Кардинальность:

`production_batches 1:N material_usage`

Для одной производственной партии может существовать несколько записей фактического расхода материалов.

Каждая запись расхода относится к одной партии.

Связь:

`material_usage.batch_id -> production_batches.batch_id`

---

### materials -> material_usage

Кардинальность:

`materials 1:N material_usage`

Один материал может расходоваться во многих производственных партиях.

Каждая запись material_usage относится к одному материалу.

Связь:

`material_usage.material_id -> materials.material_id`

---

### employees -> material_usage

Кардинальность:

`employees 1:N material_usage`

Один сотрудник может зарегистрировать множество операций расхода материала.

Каждая запись расхода содержит одного сотрудника, зарегистрировавшего расход.

Связь:

`material_usage.employee_id -> employees.employee_id`

---

### production_batches -> quality_checks

Кардинальность:

`production_batches 1:N quality_checks`

Одна производственная партия может проходить несколько проверок качества.

Каждая проверка относится к одной партии.

Связь:

`quality_checks.batch_id -> production_batches.batch_id`

---

### employees -> quality_checks

Кардинальность:

`employees 1:N quality_checks`

Один сотрудник может проводить множество проверок качества.

Каждая проверка выполняется одним сотрудником.

Связь:

`quality_checks.employee_id -> employees.employee_id`

---

### quality_checks -> defects

Кардинальность:

`quality_checks 1:N defects`

В рамках одной проверки качества может быть обнаружено несколько типов дефектов.

Каждая запись defects относится к одной проверке качества.

Связь:

`defects.quality_check_id -> quality_checks.quality_check_id`

---

### defect_types -> defects

Кардинальность:

`defect_types 1:N defects`

Один тип дефекта может встречаться во многих проверках качества.

Каждая запись defects относится к одному типу дефекта.

Связь:

`defects.defect_type_id -> defect_types.defect_type_id`

---

## 3. Связи M:N

В модели нет прямых связей M:N.

Они реализуются через промежуточные сущности.

### specifications <-> materials

Связь реализуется через:

`specification_items`

### production_batches <-> operations

Связь реализуется через:

`batch_operations`

---

## 4. Центральные сущности

Ключевыми сущностями производственного процесса являются:

- production_orders;
- production_batches;
- batch_operations;
- material_usage;
- quality_checks.

production_batches является центральной сущностью фактического производственного процесса, так как с ней связаны технологические операции, расход материалов и контроль качества.
