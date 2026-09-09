# ER-диаграмма базы данных

## 1. Общая структура

База данных содержит 15 сущностей и описывает производственный процесс от выпускаемой продукции и технологических спецификаций до производственных партий, операций, расхода материалов и контроля качества.

Основная цепочка данных:

Products
-> Specifications
-> ProductionOrders
-> ProductionBatches
-> BatchOperations / MaterialUsage / QualityChecks
-> Defects

---

## 2. Связи между сущностями

### Products -> Specifications

Кардинальность:

`Products 1:N Specifications`

Один продукт может иметь несколько версий технологической спецификации.

Каждая спецификация относится только к одному продукту.

Связь:

`Specifications.ProductId -> Products.ProductId`

---

### Specifications -> SpecificationItems

Кардинальность:

`Specifications 1:N SpecificationItems`

Одна спецификация содержит несколько строк состава.

Каждая строка состава принадлежит одной спецификации.

Связь:

`SpecificationItems.SpecificationId -> Specifications.SpecificationId`

---

### Materials -> SpecificationItems

Кардинальность:

`Materials 1:N SpecificationItems`

Один материал может использоваться во многих спецификациях.

Каждая строка спецификации относится к одному материалу.

Связь:

`SpecificationItems.MaterialId -> Materials.MaterialId`

В совокупности SpecificationItems реализует связь M:N между Specifications и Materials.

---

### Specifications -> ProductionOrders

Кардинальность:

`Specifications 1:N ProductionOrders`

Одна спецификация может использоваться во многих производственных заказах.

Каждый производственный заказ использует одну конкретную спецификацию.

Связь:

`ProductionOrders.SpecificationId -> Specifications.SpecificationId`

---

### ProductionOrders -> ProductionBatches

Кардинальность:

`ProductionOrders 1:N ProductionBatches`

Один производственный заказ может быть разделен на несколько производственных партий.

Каждая партия относится к одному производственному заказу.

Связь:

`ProductionBatches.ProductionOrderId -> ProductionOrders.ProductionOrderId`

---

### ProductionBatches -> BatchOperations

Кардинальность:

`ProductionBatches 1:N BatchOperations`

Одна производственная партия проходит несколько технологических операций.

Каждая запись BatchOperations описывает выполнение одной операции над одной партией.

Связь:

`BatchOperations.BatchId -> ProductionBatches.BatchId`

---

### Operations -> BatchOperations

Кардинальность:

`Operations 1:N BatchOperations`

Один тип технологической операции может выполняться над многими производственными партиями.

Каждая запись BatchOperations относится к одному типу операции.

Связь:

`BatchOperations.OperationId -> Operations.OperationId`

---

### ProductionLines -> BatchOperations

Кардинальность:

`ProductionLines 1:N BatchOperations`

Одна производственная линия может использоваться для выполнения многих операций.

Каждая запись BatchOperations связана с одной производственной линией.

Связь:

`BatchOperations.ProductionLineId -> ProductionLines.ProductionLineId`

---

### Employees -> BatchOperations

Кардинальность:

`Employees 1:N BatchOperations`

Один сотрудник может участвовать во многих производственных операциях.

Каждая запись BatchOperations содержит одного ответственного сотрудника.

Связь:

`BatchOperations.EmployeeId -> Employees.EmployeeId`

---

### Shifts -> BatchOperations

Кардинальность:

`Shifts 1:N BatchOperations`

В рамках одной смены может выполняться множество производственных операций.

Каждая запись BatchOperations относится к одной смене.

Связь:

`BatchOperations.ShiftId -> Shifts.ShiftId`

---

### Employees -> Shifts

Кардинальность:

`Employees 1:N Shifts`

Один сотрудник может быть руководителем многих смен.

У каждой смены указывается один ответственный руководитель.

Связь:

`Shifts.SupervisorEmployeeId -> Employees.EmployeeId`

---

### ProductionBatches -> MaterialUsage

Кардинальность:

`ProductionBatches 1:N MaterialUsage`

Для одной производственной партии может существовать несколько записей фактического расхода материалов.

Каждая запись расхода относится к одной партии.

Связь:

`MaterialUsage.BatchId -> ProductionBatches.BatchId`

---

### Materials -> MaterialUsage

Кардинальность:

`Materials 1:N MaterialUsage`

Один материал может расходоваться во многих производственных партиях.

Каждая запись MaterialUsage относится к одному материалу.

Связь:

`MaterialUsage.MaterialId -> Materials.MaterialId`

---

### Employees -> MaterialUsage

Кардинальность:

`Employees 1:N MaterialUsage`

Один сотрудник может зарегистрировать множество операций расхода материала.

Каждая запись расхода содержит одного сотрудника, зарегистрировавшего расход.

Связь:

`MaterialUsage.EmployeeId -> Employees.EmployeeId`

---

### ProductionBatches -> QualityChecks

Кардинальность:

`ProductionBatches 1:N QualityChecks`

Одна производственная партия может проходить несколько проверок качества.

Каждая проверка относится к одной партии.

Связь:

`QualityChecks.BatchId -> ProductionBatches.BatchId`

---

### Employees -> QualityChecks

Кардинальность:

`Employees 1:N QualityChecks`

Один сотрудник может проводить множество проверок качества.

Каждая проверка выполняется одним сотрудником.

Связь:

`QualityChecks.EmployeeId -> Employees.EmployeeId`

---

### QualityChecks -> Defects

Кардинальность:

`QualityChecks 1:N Defects`

В рамках одной проверки качества может быть обнаружено несколько типов дефектов.

Каждая запись Defects относится к одной проверке качества.

Связь:

`Defects.QualityCheckId -> QualityChecks.QualityCheckId`

---

### DefectTypes -> Defects

Кардинальность:

`DefectTypes 1:N Defects`

Один тип дефекта может встречаться во многих проверках качества.

Каждая запись Defects относится к одному типу дефекта.

Связь:

`Defects.DefectTypeId -> DefectTypes.DefectTypeId`

---

## 3. Связи M:N

В модели нет прямых связей M:N.

Они реализуются через промежуточные сущности.

### Specifications <-> Materials

Связь реализуется через:

`SpecificationItems`

### ProductionBatches <-> Operations

Связь реализуется через:

`BatchOperations`

---

## 4. Центральные сущности

Ключевыми сущностями производственного процесса являются:

- ProductionOrders;
- ProductionBatches;
- BatchOperations;
- MaterialUsage;
- QualityChecks.

ProductionBatches является центральной сущностью фактического производственного процесса, так как с ней связаны технологические операции, расход материалов и контроль качества.
