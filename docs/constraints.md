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
Для справочных записей вместо удаления преимущественно используется признак `IsActive`.

---

## 2. Products

### Обязательные поля

- ProductId
- Name
- Article
- Unit
- Description
- IsActive

### Ограничения

- ProductId - PRIMARY KEY;
- Article - UNIQUE;
- IsActive - DEFAULT true.

### Удаление

Удаление продукта запрещается, если существуют связанные спецификации.

`Specifications.ProductId -> Products.ProductId ON DELETE RESTRICT`

---

## 3. Materials

### Обязательные поля

- MaterialId
- Code
- Name
- Unit
- Description
- IsActive

### Ограничения

- MaterialId - PRIMARY KEY;
- Code - UNIQUE;
- IsActive - DEFAULT true.

### Удаление

Удаление материала запрещается, если он используется:

- в спецификациях;
- в фактическом расходе материалов.

`SpecificationItems.MaterialId -> Materials.MaterialId ON DELETE RESTRICT`

`MaterialUsage.MaterialId -> Materials.MaterialId ON DELETE RESTRICT`

---

## 4. Specifications

### Обязательные поля

- SpecificationId
- ProductId
- Version
- Name
- ValidFrom
- ValidTo
- Status
- CreatedAt

### Ограничения

- SpecificationId - PRIMARY KEY;
- ProductId - FOREIGN KEY;
- комбинация ProductId + Version - UNIQUE;
- ValidTo не может быть меньше ValidFrom;
- CreatedAt - DEFAULT CURRENT_TIMESTAMP.

### Дополнительное правило

Для одного продукта рекомендуется иметь не более одной активной спецификации одновременно.

### Удаление

Продукт:

`Specifications.ProductId -> Products.ProductId ON DELETE RESTRICT`

Строки состава спецификации:

`SpecificationItems.SpecificationId -> Specifications.SpecificationId ON DELETE CASCADE`

Если удаляется спецификация, ее состав удаляется автоматически.

Удаление спецификации запрещается, если на нее существуют производственные заказы:

`ProductionOrders.SpecificationId -> Specifications.SpecificationId ON DELETE RESTRICT`

---

## 5. SpecificationItems

### Обязательные поля

- SpecificationItemId
- SpecificationId
- MaterialId
- QuantityPerUnit
- WastePercent

### Ограничения

- SpecificationItemId - PRIMARY KEY;
- SpecificationId - FOREIGN KEY;
- MaterialId - FOREIGN KEY;
- SpecificationId + MaterialId - UNIQUE;
- QuantityPerUnit > 0;
- WastePercent >= 0;
- WastePercent <= 100;
- WastePercent - DEFAULT 0.

### Удаление

Specification:

`SpecificationItems.SpecificationId -> Specifications.SpecificationId ON DELETE CASCADE`

Material:

`SpecificationItems.MaterialId -> Materials.MaterialId ON DELETE RESTRICT`

---

## 6. ProductionOrders

### Обязательные поля

- ProductionOrderId
- OrderNumber
- SpecificationId
- PlannedQuantity
- PlannedStartAt
- PlannedEndAt
- Status
- CreatedAt

### Ограничения

- ProductionOrderId - PRIMARY KEY;
- OrderNumber - UNIQUE;
- SpecificationId - FOREIGN KEY;
- PlannedQuantity > 0;
- PlannedEndAt не может быть меньше PlannedStartAt;
- CreatedAt - DEFAULT CURRENT_TIMESTAMP.

### Удаление

Specification:

`ProductionOrders.SpecificationId -> Specifications.SpecificationId ON DELETE RESTRICT`

Производственный заказ нельзя удалить, если существуют связанные партии:

`ProductionBatches.ProductionOrderId -> ProductionOrders.ProductionOrderId ON DELETE RESTRICT`

---

## 7. ProductionBatches

### Обязательные поля

- BatchId
- ProductionOrderId
- BatchNumber
- PlannedQuantity
- ActualQuantity
- StartedAt
- CompletedAt
- Status

### Ограничения

- BatchId - PRIMARY KEY;
- ProductionOrderId - FOREIGN KEY;
- ProductionOrderId + BatchNumber - UNIQUE;
- PlannedQuantity > 0;
- ActualQuantity >= 0;
- CompletedAt не может быть меньше StartedAt.

### Удаление

ProductionOrder:

`ProductionBatches.ProductionOrderId -> ProductionOrders.ProductionOrderId ON DELETE RESTRICT`

Партию нельзя удалить, если существуют связанные:

- технологические операции;
- записи расхода материалов;
- проверки качества.

`BatchOperations.BatchId -> ProductionBatches.BatchId ON DELETE RESTRICT`

`MaterialUsage.BatchId -> ProductionBatches.BatchId ON DELETE RESTRICT`

`QualityChecks.BatchId -> ProductionBatches.BatchId ON DELETE RESTRICT`

---

## 8. ProductionLines

### Обязательные поля

- ProductionLineId
- Code
- Name
- Location
- Status
- Description

### Ограничения

- ProductionLineId - PRIMARY KEY;
- Code - UNIQUE;
- Status - DEFAULT Active.

### Удаление

Производственную линию нельзя удалить, если она использовалась в технологических операциях.

`BatchOperations.ProductionLineId -> ProductionLines.ProductionLineId ON DELETE RESTRICT`

---

## 9. Operations

### Обязательные поля

- OperationId
- Code
- Name
- Description

### Ограничения

- OperationId - PRIMARY KEY;
- Code - UNIQUE.

### Удаление

Тип операции нельзя удалить, если существуют записи о ее выполнении.

`BatchOperations.OperationId -> Operations.OperationId ON DELETE RESTRICT`

---

## 10. Employees

### Обязательные поля

- EmployeeId
- PersonnelNumber
- FullName
- Position
- IsActive

### Ограничения

- EmployeeId - PRIMARY KEY;
- PersonnelNumber - UNIQUE;
- IsActive - DEFAULT true.

### Удаление

Сотрудников, участвовавших в производственных процессах, физически удалять не следует.

Для уволенного сотрудника:

`IsActive = false`

Связанные внешние ключи:

`Shifts.SupervisorEmployeeId -> Employees.EmployeeId ON DELETE RESTRICT`

`BatchOperations.EmployeeId -> Employees.EmployeeId ON DELETE RESTRICT`

`MaterialUsage.EmployeeId -> Employees.EmployeeId ON DELETE RESTRICT`

`QualityChecks.EmployeeId -> Employees.EmployeeId ON DELETE RESTRICT`

---

## 11. Shifts

### Обязательные поля

- ShiftId
- ShiftDate
- ShiftNumber
- StartedAt
- CompletedAt
- SupervisorEmployeeId

### Ограничения

- ShiftId - PRIMARY KEY;
- SupervisorEmployeeId - FOREIGN KEY;
- ShiftDate + ShiftNumber - UNIQUE;
- ShiftNumber > 0;
- CompletedAt > StartedAt.

ShiftDate обозначает производственный день и может отличаться от календарной даты завершения ночной смены.

### Удаление

Employee:

`Shifts.SupervisorEmployeeId -> Employees.EmployeeId ON DELETE RESTRICT`

Смена не удаляется, если существуют связанные производственные операции:

`BatchOperations.ShiftId -> Shifts.ShiftId ON DELETE RESTRICT`

---

## 12. BatchOperations

### Обязательные поля

- BatchOperationId
- BatchId
- OperationId
- ProductionLineId
- EmployeeId
- ShiftId
- SequenceNo
- StartedAt
- CompletedAt
- ProcessedQuantity
- Status

### Ограничения

- BatchOperationId - PRIMARY KEY;
- все ссылки являются FOREIGN KEY;
- BatchId + SequenceNo - UNIQUE;
- SequenceNo > 0;
- ProcessedQuantity >= 0;
- CompletedAt не может быть меньше StartedAt.

### Удаление

Для всех внешних ключей используется ON DELETE RESTRICT.

`BatchOperations.BatchId -> ProductionBatches.BatchId ON DELETE RESTRICT`

`BatchOperations.OperationId -> Operations.OperationId ON DELETE RESTRICT`

`BatchOperations.ProductionLineId -> ProductionLines.ProductionLineId ON DELETE RESTRICT`

`BatchOperations.EmployeeId -> Employees.EmployeeId ON DELETE RESTRICT`

`BatchOperations.ShiftId -> Shifts.ShiftId ON DELETE RESTRICT`

История выполнения производственных операций должна сохраняться.

---

## 13. MaterialUsage

### Обязательные поля

- MaterialUsageId
- BatchId
- MaterialId
- EmployeeId
- QuantityUsed
- MaterialLotNumber
- RecordedAt

### Ограничения

- MaterialUsageId - PRIMARY KEY;
- BatchId - FOREIGN KEY;
- MaterialId - FOREIGN KEY;
- EmployeeId - FOREIGN KEY;
- QuantityUsed > 0;
- RecordedAt - DEFAULT CURRENT_TIMESTAMP.

Несколько записей расхода одного материала для одной партии разрешены.

### Удаление

Для внешних ключей используется ON DELETE RESTRICT.

`MaterialUsage.BatchId -> ProductionBatches.BatchId ON DELETE RESTRICT`

`MaterialUsage.MaterialId -> Materials.MaterialId ON DELETE RESTRICT`

`MaterialUsage.EmployeeId -> Employees.EmployeeId ON DELETE RESTRICT`

---

## 14. QualityChecks

### Обязательные поля

- QualityCheckId
- BatchId
- EmployeeId
- CheckStage
- CheckedAt
- Result
- Notes

### Ограничения

- QualityCheckId - PRIMARY KEY;
- BatchId - FOREIGN KEY;
- EmployeeId - FOREIGN KEY;
- CheckedAt - DEFAULT CURRENT_TIMESTAMP.

Для одной партии допускается несколько проверок одного этапа.

### Удаление

Batch:

`QualityChecks.BatchId -> ProductionBatches.BatchId ON DELETE RESTRICT`

Employee:

`QualityChecks.EmployeeId -> Employees.EmployeeId ON DELETE RESTRICT`

При удалении проверки качества связанные записи Defects удаляются автоматически:

`Defects.QualityCheckId -> QualityChecks.QualityCheckId ON DELETE CASCADE`

---

## 15. DefectTypes

### Обязательные поля

- DefectTypeId
- Code
- Name
- Severity
- Description
- IsActive

### Ограничения

- DefectTypeId - PRIMARY KEY;
- Code - UNIQUE;
- IsActive - DEFAULT true.

### Удаление

Тип дефекта нельзя удалить, если он использован в зарегистрированном браке.

`Defects.DefectTypeId -> DefectTypes.DefectTypeId ON DELETE RESTRICT`

Вместо удаления используется:

`IsActive = false`

---

## 16. Defects

### Обязательные поля

- DefectId
- QualityCheckId
- DefectTypeId
- Quantity
- Description

### Ограничения

- DefectId - PRIMARY KEY;
- QualityCheckId - FOREIGN KEY;
- DefectTypeId - FOREIGN KEY;
- Quantity > 0;
- QualityCheckId + DefectTypeId - UNIQUE.

Один тип дефекта в рамках одной проверки должен храниться одной записью с суммарным количеством.

### Удаление

QualityCheck:

`Defects.QualityCheckId -> QualityChecks.QualityCheckId ON DELETE CASCADE`

DefectType:

`Defects.DefectTypeId -> DefectTypes.DefectTypeId ON DELETE RESTRICT`

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
