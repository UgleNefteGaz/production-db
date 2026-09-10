BEGIN;

-- ============================================================
-- PRODUCTS
-- ============================================================

INSERT INTO products
    (name, article, unit, description)
VALUES
    ('Шампунь 500 мл', 'SH500', 'шт',
     'Шампунь во флаконе объемом 500 мл');


-- ============================================================
-- MATERIALS
-- ============================================================

INSERT INTO materials
    (code, name, unit, description)
VALUES
    ('MAT001', 'Основа шампуня', 'кг', 'Готовая смесь для розлива'),
    ('MAT002', 'Флакон 500 мл', 'шт', 'Пластиковый флакон'),
    ('MAT003', 'Крышка', 'шт', 'Крышка для флакона'),
    ('MAT004', 'Этикетка SH500', 'шт', 'Этикетка продукта'),
    ('MAT005', 'Транспортный короб', 'шт', 'Короб для упаковки готовой продукции');


-- ============================================================
-- SPECIFICATIONS
-- ============================================================

INSERT INTO specifications
    (
        product_id,
        version,
        name,
        valid_from,
        status
    )
VALUES
    (
        (SELECT product_id
         FROM products
         WHERE article = 'SH500'),
        '1.0',
        'Спецификация SH500',
        '2026-09-01',
        'Active'
    );


-- ============================================================
-- SPECIFICATION ITEMS
-- ============================================================

INSERT INTO specification_items
    (
        specification_id,
        material_id,
        quantity_per_unit,
        waste_percent
    )
VALUES
    (
        (SELECT specification_id
         FROM specifications
         WHERE name = 'Спецификация SH500'
           AND version = '1.0'),
        (SELECT material_id
         FROM materials
         WHERE code = 'MAT001'),
        0.500000,
        1.00
    ),
    (
        (SELECT specification_id
         FROM specifications
         WHERE name = 'Спецификация SH500'
           AND version = '1.0'),
        (SELECT material_id
         FROM materials
         WHERE code = 'MAT002'),
        1.000000,
        1.00
    ),
    (
        (SELECT specification_id
         FROM specifications
         WHERE name = 'Спецификация SH500'
           AND version = '1.0'),
        (SELECT material_id
         FROM materials
         WHERE code = 'MAT003'),
        1.000000,
        1.00
    ),
    (
        (SELECT specification_id
         FROM specifications
         WHERE name = 'Спецификация SH500'
           AND version = '1.0'),
        (SELECT material_id
         FROM materials
         WHERE code = 'MAT004'),
        1.000000,
        1.00
    ),
    (
        (SELECT specification_id
         FROM specifications
         WHERE name = 'Спецификация SH500'
           AND version = '1.0'),
        (SELECT material_id
         FROM materials
         WHERE code = 'MAT005'),
        0.050000,
        2.00
    );


-- ============================================================
-- PRODUCTION LINES
-- ============================================================

INSERT INTO production_lines
    (code, name, location, description)
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

INSERT INTO operations
    (code, name, description)
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

INSERT INTO employees
    (personnel_number, full_name, position)
VALUES
    ('EMP001', 'Иванов Иван Иванович', 'Мастер смены'),
    ('EMP002', 'Петров Петр Сергеевич', 'Оператор приготовления'),
    ('EMP003', 'Сидоров Алексей Викторович', 'Оператор линии'),
    ('EMP004', 'Смирнова Анна Олеговна', 'Контролер качества'),
    ('EMP005', 'Кузнецов Максим Андреевич', 'Кладовщик');


-- ============================================================
-- SHIFTS
-- ============================================================

INSERT INTO shifts
    (
        shift_date,
        shift_number,
        started_at,
        completed_at,
        supervisor_employee_id
    )
VALUES
    (
        '2026-09-09',
        1,
        '2026-09-09 08:00:00',
        '2026-09-09 20:00:00',
        (SELECT employee_id
         FROM employees
         WHERE personnel_number = 'EMP001')
    ),
    (
        '2026-09-10',
        1,
        '2026-09-10 08:00:00',
        '2026-09-10 20:00:00',
        (SELECT employee_id
         FROM employees
         WHERE personnel_number = 'EMP001')
    );


-- ============================================================
-- PRODUCTION ORDER
-- ============================================================

INSERT INTO production_orders
    (
        order_number,
        specification_id,
        planned_quantity,
        planned_start_at,
        planned_end_at,
        status
    )
VALUES
    (
        'PO-2026-001',
        (SELECT specification_id
         FROM specifications
         WHERE name = 'Спецификация SH500'
           AND version = '1.0'),
        1000,
        '2026-09-09 08:00:00',
        '2026-09-10 18:00:00',
        'Completed'
    );


-- ============================================================
-- PRODUCTION BATCHES
-- ============================================================

INSERT INTO production_batches
    (
        production_order_id,
        batch_number,
        planned_quantity,
        actual_quantity,
        started_at,
        completed_at,
        status
    )
VALUES
    (
        (SELECT production_order_id
         FROM production_orders
         WHERE order_number = 'PO-2026-001'),
        'BATCH-001',
        500,
        500,
        '2026-09-09 08:15:00',
        '2026-09-09 17:30:00',
        'Completed'
    ),
    (
        (SELECT production_order_id
         FROM production_orders
         WHERE order_number = 'PO-2026-001'),
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

INSERT INTO batch_operations
    (
        batch_id,
        operation_id,
        production_line_id,
        employee_id,
        shift_id,
        sequence_no,
        started_at,
        completed_at,
        processed_quantity,
        status
    )
VALUES

-- BATCH-001

(
    (SELECT batch_id FROM production_batches
     WHERE batch_number = 'BATCH-001'),
    (SELECT operation_id FROM operations
     WHERE code = 'OP001'),
    (SELECT production_line_id FROM production_lines
     WHERE code = 'MIX01'),
    (SELECT employee_id FROM employees
     WHERE personnel_number = 'EMP002'),
    (SELECT shift_id FROM shifts
     WHERE shift_date = '2026-09-09'
       AND shift_number = 1),
    1,
    '2026-09-09 08:15:00',
    '2026-09-09 10:00:00',
    500,
    'Completed'
),
(
    (SELECT batch_id FROM production_batches
     WHERE batch_number = 'BATCH-001'),
    (SELECT operation_id FROM operations
     WHERE code = 'OP002'),
    (SELECT production_line_id FROM production_lines
     WHERE code = 'FILL01'),
    (SELECT employee_id FROM employees
     WHERE personnel_number = 'EMP003'),
    (SELECT shift_id FROM shifts
     WHERE shift_date = '2026-09-09'
       AND shift_number = 1),
    2,
    '2026-09-09 10:15:00',
    '2026-09-09 13:00:00',
    500,
    'Completed'
),
(
    (SELECT batch_id FROM production_batches
     WHERE batch_number = 'BATCH-001'),
    (SELECT operation_id FROM operations
     WHERE code = 'OP003'),
    (SELECT production_line_id FROM production_lines
     WHERE code = 'PACK01'),
    (SELECT employee_id FROM employees
     WHERE personnel_number = 'EMP003'),
    (SELECT shift_id FROM shifts
     WHERE shift_date = '2026-09-09'
       AND shift_number = 1),
    3,
    '2026-09-09 13:15:00',
    '2026-09-09 15:00:00',
    500,
    'Completed'
),
(
    (SELECT batch_id FROM production_batches
     WHERE batch_number = 'BATCH-001'),
    (SELECT operation_id FROM operations
     WHERE code = 'OP004'),
    (SELECT production_line_id FROM production_lines
     WHERE code = 'PACK01'),
    (SELECT employee_id FROM employees
     WHERE personnel_number = 'EMP003'),
    (SELECT shift_id FROM shifts
     WHERE shift_date = '2026-09-09'
       AND shift_number = 1),
    4,
    '2026-09-09 15:10:00',
    '2026-09-09 17:00:00',
    500,
    'Completed'
),

-- BATCH-002

(
    (SELECT batch_id FROM production_batches
     WHERE batch_number = 'BATCH-002'),
    (SELECT operation_id FROM operations
     WHERE code = 'OP001'),
    (SELECT production_line_id FROM production_lines
     WHERE code = 'MIX01'),
    (SELECT employee_id FROM employees
     WHERE personnel_number = 'EMP002'),
    (SELECT shift_id FROM shifts
     WHERE shift_date = '2026-09-10'
       AND shift_number = 1),
    1,
    '2026-09-10 08:10:00',
    '2026-09-10 10:00:00',
    500,
    'Completed'
),
(
    (SELECT batch_id FROM production_batches
     WHERE batch_number = 'BATCH-002'),
    (SELECT operation_id FROM operations
     WHERE code = 'OP002'),
    (SELECT production_line_id FROM production_lines
     WHERE code = 'FILL01'),
    (SELECT employee_id FROM employees
     WHERE personnel_number = 'EMP003'),
    (SELECT shift_id FROM shifts
     WHERE shift_date = '2026-09-10'
       AND shift_number = 1),
    2,
    '2026-09-10 10:15:00',
    '2026-09-10 13:10:00',
    500,
    'Completed'
),
(
    (SELECT batch_id FROM production_batches
     WHERE batch_number = 'BATCH-002'),
    (SELECT operation_id FROM operations
     WHERE code = 'OP003'),
    (SELECT production_line_id FROM production_lines
     WHERE code = 'PACK01'),
    (SELECT employee_id FROM employees
     WHERE personnel_number = 'EMP003'),
    (SELECT shift_id FROM shifts
     WHERE shift_date = '2026-09-10'
       AND shift_number = 1),
    3,
    '2026-09-10 13:20:00',
    '2026-09-10 15:15:00',
    500,
    'Completed'
),
(
    (SELECT batch_id FROM production_batches
     WHERE batch_number = 'BATCH-002'),
    (SELECT operation_id FROM operations
     WHERE code = 'OP004'),
    (SELECT production_line_id FROM production_lines
     WHERE code = 'PACK01'),
    (SELECT employee_id FROM employees
     WHERE personnel_number = 'EMP003'),
    (SELECT shift_id FROM shifts
     WHERE shift_date = '2026-09-10'
       AND shift_number = 1),
    4,
    '2026-09-10 15:25:00',
    '2026-09-10 17:15:00',
    500,
    'Completed'
);


-- ============================================================
-- MATERIAL USAGE
-- ============================================================

INSERT INTO material_usage
    (
        batch_id,
        material_id,
        employee_id,
        quantity_used,
        material_lot_number,
        recorded_at
    )
VALUES

-- BATCH-001

(
    (SELECT batch_id FROM production_batches
     WHERE batch_number = 'BATCH-001'),
    (SELECT material_id FROM materials
     WHERE code = 'MAT001'),
    (SELECT employee_id FROM employees
     WHERE personnel_number = 'EMP005'),
    252.000000,
    'LOT-BASE-001',
    '2026-09-09 08:10:00'
),
(
    (SELECT batch_id FROM production_batches
     WHERE batch_number = 'BATCH-001'),
    (SELECT material_id FROM materials
     WHERE code = 'MAT002'),
    (SELECT employee_id FROM employees
     WHERE personnel_number = 'EMP005'),
    503,
    'LOT-BOTTLE-001',
    '2026-09-09 10:05:00'
),
(
    (SELECT batch_id FROM production_batches
     WHERE batch_number = 'BATCH-001'),
    (SELECT material_id FROM materials
     WHERE code = 'MAT003'),
    (SELECT employee_id FROM employees
     WHERE personnel_number = 'EMP005'),
    501,
    'LOT-CAP-001',
    '2026-09-09 10:05:00'
),
(
    (SELECT batch_id FROM production_batches
     WHERE batch_number = 'BATCH-001'),
    (SELECT material_id FROM materials
     WHERE code = 'MAT004'),
    (SELECT employee_id FROM employees
     WHERE personnel_number = 'EMP005'),
    505,
    'LOT-LABEL-001',
    '2026-09-09 13:10:00'
),
(
    (SELECT batch_id FROM production_batches
     WHERE batch_number = 'BATCH-001'),
    (SELECT material_id FROM materials
     WHERE code = 'MAT005'),
    (SELECT employee_id FROM employees
     WHERE personnel_number = 'EMP005'),
    26,
    'LOT-BOX-001',
    '2026-09-09 15:05:00'
),

-- BATCH-002

(
    (SELECT batch_id FROM production_batches
     WHERE batch_number = 'BATCH-002'),
    (SELECT material_id FROM materials
     WHERE code = 'MAT001'),
    (SELECT employee_id FROM employees
     WHERE personnel_number = 'EMP005'),
    253.000000,
    'LOT-BASE-001',
    '2026-09-10 08:05:00'
),
(
    (SELECT batch_id FROM production_batches
     WHERE batch_number = 'BATCH-002'),
    (SELECT material_id FROM materials
     WHERE code = 'MAT002'),
    (SELECT employee_id FROM employees
     WHERE personnel_number = 'EMP005'),
    504,
    'LOT-BOTTLE-001',
    '2026-09-10 10:05:00'
),
(
    (SELECT batch_id FROM production_batches
     WHERE batch_number = 'BATCH-002'),
    (SELECT material_id FROM materials
     WHERE code = 'MAT003'),
    (SELECT employee_id FROM employees
     WHERE personnel_number = 'EMP005'),
    503,
    'LOT-CAP-001',
    '2026-09-10 10:05:00'
),
(
    (SELECT batch_id FROM production_batches
     WHERE batch_number = 'BATCH-002'),
    (SELECT material_id FROM materials
     WHERE code = 'MAT004'),
    (SELECT employee_id FROM employees
     WHERE personnel_number = 'EMP005'),
    506,
    'LOT-LABEL-001',
    '2026-09-10 13:15:00'
),
(
    (SELECT batch_id FROM production_batches
     WHERE batch_number = 'BATCH-002'),
    (SELECT material_id FROM materials
     WHERE code = 'MAT005'),
    (SELECT employee_id FROM employees
     WHERE personnel_number = 'EMP005'),
    26,
    'LOT-BOX-001',
    '2026-09-10 15:20:00'
);


-- ============================================================
-- QUALITY CHECKS
-- ============================================================

INSERT INTO quality_checks
    (
        batch_id,
        employee_id,
        check_stage,
        checked_at,
        result,
        notes
    )
VALUES
    (
        (SELECT batch_id
         FROM production_batches
         WHERE batch_number = 'BATCH-001'),
        (SELECT employee_id
         FROM employees
         WHERE personnel_number = 'EMP004'),
        'Final',
        '2026-09-09 17:20:00',
        'Passed',
        'Партия соответствует требованиям качества'
    ),
    (
        (SELECT batch_id
         FROM production_batches
         WHERE batch_number = 'BATCH-002'),
        (SELECT employee_id
         FROM employees
         WHERE personnel_number = 'EMP004'),
        'Final',
        '2026-09-10 17:30:00',
        'Conditional',
        'Обнаружено 7 единиц бракованной продукции'
    );


-- ============================================================
-- DEFECT TYPES
-- ============================================================

INSERT INTO defect_types
    (code, name, severity, description)
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

INSERT INTO defects
    (
        quality_check_id,
        defect_type_id,
        quantity,
        description
    )
VALUES
    (
        (
            SELECT qc.quality_check_id
            FROM quality_checks qc
            JOIN production_batches pb
              ON pb.batch_id = qc.batch_id
            WHERE pb.batch_number = 'BATCH-002'
              AND qc.check_stage = 'Final'
        ),
        (SELECT defect_type_id
         FROM defect_types
         WHERE code = 'DEF002'),
        4,
        'Обнаружены поврежденные флаконы'
    ),
    (
        (
            SELECT qc.quality_check_id
            FROM quality_checks qc
            JOIN production_batches pb
              ON pb.batch_id = qc.batch_id
            WHERE pb.batch_number = 'BATCH-002'
              AND qc.check_stage = 'Final'
        ),
        (SELECT defect_type_id
         FROM defect_types
         WHERE code = 'DEF003'),
        3,
        'Обнаружены дефекты этикетирования'
    );

COMMIT;
