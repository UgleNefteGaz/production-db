BEGIN;

-- ============================================================
-- PRODUCTS
-- ============================================================

INSERT INTO "Products"
    ("Name", "Article", "Unit", "Description")
VALUES
    ('Шампунь 500 мл', 'SH500', 'шт',
     'Шампунь во флаконе объемом 500 мл');


-- ============================================================
-- MATERIALS
-- ============================================================

INSERT INTO "Materials"
    ("Code", "Name", "Unit", "Description")
VALUES
    ('MAT001', 'Основа шампуня', 'кг', 'Готовая смесь для розлива'),
    ('MAT002', 'Флакон 500 мл', 'шт', 'Пластиковый флакон'),
    ('MAT003', 'Крышка', 'шт', 'Крышка для флакона'),
    ('MAT004', 'Этикетка SH500', 'шт', 'Этикетка продукта'),
    ('MAT005', 'Транспортный короб', 'шт', 'Короб для упаковки готовой продукции');


-- ============================================================
-- SPECIFICATIONS
-- ============================================================

INSERT INTO "Specifications"
    (
        "ProductId",
        "Version",
        "Name",
        "ValidFrom",
        "Status"
    )
VALUES
    (
        (SELECT "ProductId"
         FROM "Products"
         WHERE "Article" = 'SH500'),
        '1.0',
        'Спецификация SH500',
        '2026-09-01',
        'Active'
    );


-- ============================================================
-- SPECIFICATION ITEMS
-- ============================================================

INSERT INTO "SpecificationItems"
    (
        "SpecificationId",
        "MaterialId",
        "QuantityPerUnit",
        "WastePercent"
    )
VALUES
    (
        (SELECT "SpecificationId"
         FROM "Specifications"
         WHERE "Name" = 'Спецификация SH500'
           AND "Version" = '1.0'),
        (SELECT "MaterialId"
         FROM "Materials"
         WHERE "Code" = 'MAT001'),
        0.500000,
        1.00
    ),
    (
        (SELECT "SpecificationId"
         FROM "Specifications"
         WHERE "Name" = 'Спецификация SH500'
           AND "Version" = '1.0'),
        (SELECT "MaterialId"
         FROM "Materials"
         WHERE "Code" = 'MAT002'),
        1.000000,
        1.00
    ),
    (
        (SELECT "SpecificationId"
         FROM "Specifications"
         WHERE "Name" = 'Спецификация SH500'
           AND "Version" = '1.0'),
        (SELECT "MaterialId"
         FROM "Materials"
         WHERE "Code" = 'MAT003'),
        1.000000,
        1.00
    ),
    (
        (SELECT "SpecificationId"
         FROM "Specifications"
         WHERE "Name" = 'Спецификация SH500'
           AND "Version" = '1.0'),
        (SELECT "MaterialId"
         FROM "Materials"
         WHERE "Code" = 'MAT004'),
        1.000000,
        1.00
    ),
    (
        (SELECT "SpecificationId"
         FROM "Specifications"
         WHERE "Name" = 'Спецификация SH500'
           AND "Version" = '1.0'),
        (SELECT "MaterialId"
         FROM "Materials"
         WHERE "Code" = 'MAT005'),
        0.050000,
        2.00
    );


-- ============================================================
-- PRODUCTION LINES
-- ============================================================

INSERT INTO "ProductionLines"
    ("Code", "Name", "Location", "Description")
VALUES
    ('MIX01', 'Линия приготовления смеси', 'Цех 1',
     'Приготовление продукта'),
    ('FILL01', 'Линия розлива', 'Цех 2',
     'Розлив и укупорка продукции'),
    ('PACK01', 'Линия упаковки', 'Цех 2',
     'Этикетирование и упаковка');


-- ============================================================
-- OPERATIONS
-- ============================================================

INSERT INTO "Operations"
    ("Code", "Name", "Description")
VALUES
    ('OP001', 'Приготовление смеси',
     'Подготовка продукта к розливу'),
    ('OP002', 'Розлив',
     'Розлив продукта во флаконы'),
    ('OP003', 'Этикетирование',
     'Нанесение этикетки'),
    ('OP004', 'Упаковка',
     'Укладка готовой продукции в транспортные короба');


-- ============================================================
-- EMPLOYEES
-- ============================================================

INSERT INTO "Employees"
    ("PersonnelNumber", "FullName", "Position")
VALUES
    ('EMP001', 'Иванов Иван Иванович', 'Мастер смены'),
    ('EMP002', 'Петров Петр Сергеевич', 'Оператор приготовления'),
    ('EMP003', 'Сидоров Алексей Викторович', 'Оператор линии'),
    ('EMP004', 'Смирнова Анна Олеговна', 'Контролер качества'),
    ('EMP005', 'Кузнецов Максим Андреевич', 'Кладовщик');


-- ============================================================
-- SHIFTS
-- ============================================================

INSERT INTO "Shifts"
    (
        "ShiftDate",
        "ShiftNumber",
        "StartedAt",
        "CompletedAt",
        "SupervisorEmployeeId"
    )
VALUES
    (
        '2026-09-09',
        1,
        '2026-09-09 08:00:00',
        '2026-09-09 20:00:00',
        (SELECT "EmployeeId"
         FROM "Employees"
         WHERE "PersonnelNumber" = 'EMP001')
    ),
    (
        '2026-09-10',
        1,
        '2026-09-10 08:00:00',
        '2026-09-10 20:00:00',
        (SELECT "EmployeeId"
         FROM "Employees"
         WHERE "PersonnelNumber" = 'EMP001')
    );


-- ============================================================
-- PRODUCTION ORDER
-- ============================================================

INSERT INTO "ProductionOrders"
    (
        "OrderNumber",
        "SpecificationId",
        "PlannedQuantity",
        "PlannedStartAt",
        "PlannedEndAt",
        "Status"
    )
VALUES
    (
        'PO-2026-001',
        (SELECT "SpecificationId"
         FROM "Specifications"
         WHERE "Name" = 'Спецификация SH500'
           AND "Version" = '1.0'),
        1000,
        '2026-09-09 08:00:00',
        '2026-09-10 18:00:00',
        'Completed'
    );


-- ============================================================
-- PRODUCTION BATCHES
-- ============================================================

INSERT INTO "ProductionBatches"
    (
        "ProductionOrderId",
        "BatchNumber",
        "PlannedQuantity",
        "ActualQuantity",
        "StartedAt",
        "CompletedAt",
        "Status"
    )
VALUES
    (
        (SELECT "ProductionOrderId"
         FROM "ProductionOrders"
         WHERE "OrderNumber" = 'PO-2026-001'),
        'BATCH-001',
        500,
        500,
        '2026-09-09 08:15:00',
        '2026-09-09 17:30:00',
        'Completed'
    ),
    (
        (SELECT "ProductionOrderId"
         FROM "ProductionOrders"
         WHERE "OrderNumber" = 'PO-2026-001'),
        'BATCH-002',
        500,
        493,
        '2026-09-10 08:10:00',
        '2026-09-10 17:45:00',
        'Completed'
    );


-- ============================================================
-- BATCH OPERATIONS
-- ============================================================

INSERT INTO "BatchOperations"
    (
        "BatchId",
        "OperationId",
        "ProductionLineId",
        "EmployeeId",
        "ShiftId",
        "SequenceNo",
        "StartedAt",
        "CompletedAt",
        "ProcessedQuantity",
        "Status"
    )
VALUES

-- BATCH-001

(
    (SELECT "BatchId" FROM "ProductionBatches"
     WHERE "BatchNumber" = 'BATCH-001'),
    (SELECT "OperationId" FROM "Operations"
     WHERE "Code" = 'OP001'),
    (SELECT "ProductionLineId" FROM "ProductionLines"
     WHERE "Code" = 'MIX01'),
    (SELECT "EmployeeId" FROM "Employees"
     WHERE "PersonnelNumber" = 'EMP002'),
    (SELECT "ShiftId" FROM "Shifts"
     WHERE "ShiftDate" = '2026-09-09'
       AND "ShiftNumber" = 1),
    1,
    '2026-09-09 08:15:00',
    '2026-09-09 10:00:00',
    500,
    'Completed'
),
(
    (SELECT "BatchId" FROM "ProductionBatches"
     WHERE "BatchNumber" = 'BATCH-001'),
    (SELECT "OperationId" FROM "Operations"
     WHERE "Code" = 'OP002'),
    (SELECT "ProductionLineId" FROM "ProductionLines"
     WHERE "Code" = 'FILL01'),
    (SELECT "EmployeeId" FROM "Employees"
     WHERE "PersonnelNumber" = 'EMP003'),
    (SELECT "ShiftId" FROM "Shifts"
     WHERE "ShiftDate" = '2026-09-09'
       AND "ShiftNumber" = 1),
    2,
    '2026-09-09 10:15:00',
    '2026-09-09 13:00:00',
    500,
    'Completed'
),
(
    (SELECT "BatchId" FROM "ProductionBatches"
     WHERE "BatchNumber" = 'BATCH-001'),
    (SELECT "OperationId" FROM "Operations"
     WHERE "Code" = 'OP003'),
    (SELECT "ProductionLineId" FROM "ProductionLines"
     WHERE "Code" = 'PACK01'),
    (SELECT "EmployeeId" FROM "Employees"
     WHERE "PersonnelNumber" = 'EMP003'),
    (SELECT "ShiftId" FROM "Shifts"
     WHERE "ShiftDate" = '2026-09-09'
       AND "ShiftNumber" = 1),
    3,
    '2026-09-09 13:15:00',
    '2026-09-09 15:00:00',
    500,
    'Completed'
),
(
    (SELECT "BatchId" FROM "ProductionBatches"
     WHERE "BatchNumber" = 'BATCH-001'),
    (SELECT "OperationId" FROM "Operations"
     WHERE "Code" = 'OP004'),
    (SELECT "ProductionLineId" FROM "ProductionLines"
     WHERE "Code" = 'PACK01'),
    (SELECT "EmployeeId" FROM "Employees"
     WHERE "PersonnelNumber" = 'EMP003'),
    (SELECT "ShiftId" FROM "Shifts"
     WHERE "ShiftDate" = '2026-09-09'
       AND "ShiftNumber" = 1),
    4,
    '2026-09-09 15:10:00',
    '2026-09-09 17:00:00',
    500,
    'Completed'
),

-- BATCH-002

(
    (SELECT "BatchId" FROM "ProductionBatches"
     WHERE "BatchNumber" = 'BATCH-002'),
    (SELECT "OperationId" FROM "Operations"
     WHERE "Code" = 'OP001'),
    (SELECT "ProductionLineId" FROM "ProductionLines"
     WHERE "Code" = 'MIX01'),
    (SELECT "EmployeeId" FROM "Employees"
     WHERE "PersonnelNumber" = 'EMP002'),
    (SELECT "ShiftId" FROM "Shifts"
     WHERE "ShiftDate" = '2026-09-10'
       AND "ShiftNumber" = 1),
    1,
    '2026-09-10 08:10:00',
    '2026-09-10 10:00:00',
    500,
    'Completed'
),
(
    (SELECT "BatchId" FROM "ProductionBatches"
     WHERE "BatchNumber" = 'BATCH-002'),
    (SELECT "OperationId" FROM "Operations"
     WHERE "Code" = 'OP002'),
    (SELECT "ProductionLineId" FROM "ProductionLines"
     WHERE "Code" = 'FILL01'),
    (SELECT "EmployeeId" FROM "Employees"
     WHERE "PersonnelNumber" = 'EMP003'),
    (SELECT "ShiftId" FROM "Shifts"
     WHERE "ShiftDate" = '2026-09-10'
       AND "ShiftNumber" = 1),
    2,
    '2026-09-10 10:15:00',
    '2026-09-10 13:10:00',
    500,
    'Completed'
),
(
    (SELECT "BatchId" FROM "ProductionBatches"
     WHERE "BatchNumber" = 'BATCH-002'),
    (SELECT "OperationId" FROM "Operations"
     WHERE "Code" = 'OP003'),
    (SELECT "ProductionLineId" FROM "ProductionLines"
     WHERE "Code" = 'PACK01'),
    (SELECT "EmployeeId" FROM "Employees"
     WHERE "PersonnelNumber" = 'EMP003'),
    (SELECT "ShiftId" FROM "Shifts"
     WHERE "ShiftDate" = '2026-09-10'
       AND "ShiftNumber" = 1),
    3,
    '2026-09-10 13:20:00',
    '2026-09-10 15:15:00',
    500,
    'Completed'
),
(
    (SELECT "BatchId" FROM "ProductionBatches"
     WHERE "BatchNumber" = 'BATCH-002'),
    (SELECT "OperationId" FROM "Operations"
     WHERE "Code" = 'OP004'),
    (SELECT "ProductionLineId" FROM "ProductionLines"
     WHERE "Code" = 'PACK01'),
    (SELECT "EmployeeId" FROM "Employees"
     WHERE "PersonnelNumber" = 'EMP003'),
    (SELECT "ShiftId" FROM "Shifts"
     WHERE "ShiftDate" = '2026-09-10'
       AND "ShiftNumber" = 1),
    4,
    '2026-09-10 15:25:00',
    '2026-09-10 17:15:00',
    500,
    'Completed'
);


-- ============================================================
-- MATERIAL USAGE
-- ============================================================

INSERT INTO "MaterialUsage"
    (
        "BatchId",
        "MaterialId",
        "EmployeeId",
        "QuantityUsed",
        "MaterialLotNumber",
        "RecordedAt"
    )
VALUES

-- BATCH-001

(
    (SELECT "BatchId" FROM "ProductionBatches"
     WHERE "BatchNumber" = 'BATCH-001'),
    (SELECT "MaterialId" FROM "Materials"
     WHERE "Code" = 'MAT001'),
    (SELECT "EmployeeId" FROM "Employees"
     WHERE "PersonnelNumber" = 'EMP005'),
    252.000000,
    'LOT-BASE-001',
    '2026-09-09 08:10:00'
),
(
    (SELECT "BatchId" FROM "ProductionBatches"
     WHERE "BatchNumber" = 'BATCH-001'),
    (SELECT "MaterialId" FROM "Materials"
     WHERE "Code" = 'MAT002'),
    (SELECT "EmployeeId" FROM "Employees"
     WHERE "PersonnelNumber" = 'EMP005'),
    503,
    'LOT-BOTTLE-001',
    '2026-09-09 10:05:00'
),
(
    (SELECT "BatchId" FROM "ProductionBatches"
     WHERE "BatchNumber" = 'BATCH-001'),
    (SELECT "MaterialId" FROM "Materials"
     WHERE "Code" = 'MAT003'),
    (SELECT "EmployeeId" FROM "Employees"
     WHERE "PersonnelNumber" = 'EMP005'),
    501,
    'LOT-CAP-001',
    '2026-09-09 10:05:00'
),
(
    (SELECT "BatchId" FROM "ProductionBatches"
     WHERE "BatchNumber" = 'BATCH-001'),
    (SELECT "MaterialId" FROM "Materials"
     WHERE "Code" = 'MAT004'),
    (SELECT "EmployeeId" FROM "Employees"
     WHERE "PersonnelNumber" = 'EMP005'),
    505,
    'LOT-LABEL-001',
    '2026-09-09 13:10:00'
),
(
    (SELECT "BatchId" FROM "ProductionBatches"
     WHERE "BatchNumber" = 'BATCH-001'),
    (SELECT "MaterialId" FROM "Materials"
     WHERE "Code" = 'MAT005'),
    (SELECT "EmployeeId" FROM "Employees"
     WHERE "PersonnelNumber" = 'EMP005'),
    26,
    'LOT-BOX-001',
    '2026-09-09 15:05:00'
),

-- BATCH-002

(
    (SELECT "BatchId" FROM "ProductionBatches"
     WHERE "BatchNumber" = 'BATCH-002'),
    (SELECT "MaterialId" FROM "Materials"
     WHERE "Code" = 'MAT001'),
    (SELECT "EmployeeId" FROM "Employees"
     WHERE "PersonnelNumber" = 'EMP005'),
    253.000000,
    'LOT-BASE-001',
    '2026-09-10 08:05:00'
),
(
    (SELECT "BatchId" FROM "ProductionBatches"
     WHERE "BatchNumber" = 'BATCH-002'),
    (SELECT "MaterialId" FROM "Materials"
     WHERE "Code" = 'MAT002'),
    (SELECT "EmployeeId" FROM "Employees"
     WHERE "PersonnelNumber" = 'EMP005'),
    504,
    'LOT-BOTTLE-001',
    '2026-09-10 10:05:00'
),
(
    (SELECT "BatchId" FROM "ProductionBatches"
     WHERE "BatchNumber" = 'BATCH-002'),
    (SELECT "MaterialId" FROM "Materials"
     WHERE "Code" = 'MAT003'),
    (SELECT "EmployeeId" FROM "Employees"
     WHERE "PersonnelNumber" = 'EMP005'),
    503,
    'LOT-CAP-001',
    '2026-09-10 10:05:00'
),
(
    (SELECT "BatchId" FROM "ProductionBatches"
     WHERE "BatchNumber" = 'BATCH-002'),
    (SELECT "MaterialId" FROM "Materials"
     WHERE "Code" = 'MAT004'),
    (SELECT "EmployeeId" FROM "Employees"
     WHERE "PersonnelNumber" = 'EMP005'),
    506,
    'LOT-LABEL-001',
    '2026-09-10 13:15:00'
),
(
    (SELECT "BatchId" FROM "ProductionBatches"
     WHERE "BatchNumber" = 'BATCH-002'),
    (SELECT "MaterialId" FROM "Materials"
     WHERE "Code" = 'MAT005'),
    (SELECT "EmployeeId" FROM "Employees"
     WHERE "PersonnelNumber" = 'EMP005'),
    26,
    'LOT-BOX-001',
    '2026-09-10 15:20:00'
);


-- ============================================================
-- QUALITY CHECKS
-- ============================================================

INSERT INTO "QualityChecks"
    (
        "BatchId",
        "EmployeeId",
        "CheckStage",
        "CheckedAt",
        "Result",
        "Notes"
    )
VALUES
    (
        (SELECT "BatchId"
         FROM "ProductionBatches"
         WHERE "BatchNumber" = 'BATCH-001'),
        (SELECT "EmployeeId"
         FROM "Employees"
         WHERE "PersonnelNumber" = 'EMP004'),
        'Final',
        '2026-09-09 17:20:00',
        'Passed',
        'Партия соответствует требованиям качества'
    ),
    (
        (SELECT "BatchId"
         FROM "ProductionBatches"
         WHERE "BatchNumber" = 'BATCH-002'),
        (SELECT "EmployeeId"
         FROM "Employees"
         WHERE "PersonnelNumber" = 'EMP004'),
        'Final',
        '2026-09-10 17:30:00',
        'Conditional',
        'Обнаружено 7 единиц бракованной продукции'
    );


-- ============================================================
-- DEFECT TYPES
-- ============================================================

INSERT INTO "DefectTypes"
    ("Code", "Name", "Severity", "Description")
VALUES
    ('DEF001', 'Недолив', 'Major',
     'Объем продукта ниже установленного значения'),
    ('DEF002', 'Повреждение упаковки', 'Minor',
     'Механическое повреждение флакона или упаковки'),
    ('DEF003', 'Неверная этикетка', 'Major',
     'Ошибка или повреждение этикетки');


-- ============================================================
-- DEFECTS
-- ============================================================

INSERT INTO "Defects"
    (
        "QualityCheckId",
        "DefectTypeId",
        "Quantity",
        "Description"
    )
VALUES
    (
        (
            SELECT qc."QualityCheckId"
            FROM "QualityChecks" qc
            JOIN "ProductionBatches" pb
              ON pb."BatchId" = qc."BatchId"
            WHERE pb."BatchNumber" = 'BATCH-002'
              AND qc."CheckStage" = 'Final'
        ),
        (SELECT "DefectTypeId"
         FROM "DefectTypes"
         WHERE "Code" = 'DEF002'),
        4,
        'Обнаружены поврежденные флаконы'
    ),
    (
        (
            SELECT qc."QualityCheckId"
            FROM "QualityChecks" qc
            JOIN "ProductionBatches" pb
              ON pb."BatchId" = qc."BatchId"
            WHERE pb."BatchNumber" = 'BATCH-002'
              AND qc."CheckStage" = 'Final'
        ),
        (SELECT "DefectTypeId"
         FROM "DefectTypes"
         WHERE "Code" = 'DEF003'),
        3,
        'Обнаружены дефекты этикетирования'
    );

COMMIT;
