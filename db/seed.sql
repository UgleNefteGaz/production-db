BEGIN;

-- ============================================================
-- 1. PRODUCTS
-- ============================================================

INSERT INTO products
    (name, article, unit, description, is_active)
VALUES
    ('Шампунь 500 мл',      'SH500',   'шт', 'Шампунь во флаконе 500 мл', true),
    ('Шампунь 250 мл',      'SH250',   'шт', 'Шампунь во флаконе 250 мл', true),
    ('Маска для волос 400 мл', 'MASK400', 'шт', 'Маска для волос в банке 400 мл', true),
    ('Гель для душа 300 мл','GEL300',  'шт', 'Гель для душа 300 мл', true),
    ('Бальзам 250 мл',      'BALM250', 'шт', 'Бальзам для волос 250 мл', true),
    ('Крем 50 мл',          'CREAM50', 'шт', 'Продукт без спецификации и производственных заказов', true);


-- ============================================================
-- 2. MATERIALS
-- ============================================================

INSERT INTO materials
    (code, name, unit, description, is_active)
VALUES
    ('MAT001', 'Основа шампуня',          'кг', 'Базовая смесь для производства шампуня', true),
    ('MAT002', 'Флакон 500 мл',           'шт', 'Флакон для продукта объёмом 500 мл', true),
    ('MAT003', 'Крышка универсальная',     'шт', 'Крышка для флаконов', true),
    ('MAT004', 'Этикетка',                 'шт', 'Основная этикетка продукта', true),
    ('MAT005', 'Транспортный короб',       'шт', 'Гофрокороб для групповой упаковки', true),
    ('MAT006', 'Основа маски для волос',   'кг', 'Базовая смесь маски', true),
    ('MAT007', 'Банка 400 мл',             'шт', 'Банка для маски', true),
    ('MAT008', 'Крышка банки 400 мл',      'шт', 'Крышка для банки', true),
    ('MAT009', 'Основа геля для душа',     'кг', 'Базовая смесь геля', true),
    ('MAT010', 'Флакон 300 мл',            'шт', 'Флакон для геля', true),
    ('MAT011', 'Основа бальзама',          'кг', 'Базовая смесь бальзама', true),
    ('MAT012', 'Флакон 250 мл',            'шт', 'Флакон для продукта объёмом 250 мл', true);


-- ============================================================
-- 3. SPECIFICATIONS
-- ============================================================

INSERT INTO specifications
    (product_id, version, name, valid_from, valid_to, status)
SELECT
    p.product_id,
    v.version,
    v.spec_name,
    v.valid_from,
    v.valid_to,
    v.status::specification_status
FROM (
    VALUES
        ('SH500',   '1.0', 'SH500 базовая рецептура', DATE '2026-01-01', DATE '2026-06-30', 'Archived'),
        ('SH500',   '2.0', 'SH500 актуальная рецептура', DATE '2026-07-01', NULL::date, 'Active'),
        ('SH250',   '1.0', 'SH250 базовая рецептура', DATE '2026-01-01', NULL::date, 'Active'),
        ('MASK400', '1.0', 'MASK400 базовая рецептура', DATE '2026-02-01', NULL::date, 'Active'),
        ('MASK400', '1.1', 'MASK400 экспериментальная рецептура', NULL::date, NULL::date, 'Draft'),
        ('GEL300',  '1.0', 'GEL300 базовая рецептура', DATE '2026-03-01', NULL::date, 'Active'),
        ('BALM250', '1.0', 'BALM250 базовая рецептура', DATE '2026-05-01', NULL::date, 'Active')
) AS v(article, version, spec_name, valid_from, valid_to, status)
JOIN products p
    ON p.article = v.article;


-- ============================================================
-- 4. SPECIFICATION ITEMS
-- ============================================================

INSERT INTO specification_items
    (specification_id, material_id, quantity_per_unit, waste_percent)
SELECT
    s.specification_id,
    m.material_id,
    v.quantity_per_unit,
    v.waste_percent
FROM (
    VALUES
        -- SH500 1.0
        ('SH500', '1.0', 'MAT001', 0.500000::numeric, 1.00::numeric),
        ('SH500', '1.0', 'MAT002', 1.000000, 1.00),
        ('SH500', '1.0', 'MAT003', 1.000000, 1.00),
        ('SH500', '1.0', 'MAT004', 1.000000, 1.00),
        ('SH500', '1.0', 'MAT005', 0.050000, 2.00),

        -- SH500 2.0
        ('SH500', '2.0', 'MAT001', 0.490000, 0.50),
        ('SH500', '2.0', 'MAT002', 1.000000, 1.00),
        ('SH500', '2.0', 'MAT003', 1.000000, 1.00),
        ('SH500', '2.0', 'MAT004', 1.000000, 1.00),
        ('SH500', '2.0', 'MAT005', 0.050000, 2.00),

        -- SH250
        ('SH250', '1.0', 'MAT001', 0.250000, 1.00),
        ('SH250', '1.0', 'MAT012', 1.000000, 1.00),
        ('SH250', '1.0', 'MAT003', 1.000000, 1.00),
        ('SH250', '1.0', 'MAT004', 1.000000, 1.00),
        ('SH250', '1.0', 'MAT005', 0.100000, 2.00),

        -- MASK400 1.0
        ('MASK400', '1.0', 'MAT006', 0.400000, 1.00),
        ('MASK400', '1.0', 'MAT007', 1.000000, 1.00),
        ('MASK400', '1.0', 'MAT008', 1.000000, 1.00),
        ('MASK400', '1.0', 'MAT004', 1.000000, 1.00),
        ('MASK400', '1.0', 'MAT005', 0.080000, 2.00),

        -- MASK400 1.1 Draft
        ('MASK400', '1.1', 'MAT006', 0.390000, 0.80),
        ('MASK400', '1.1', 'MAT007', 1.000000, 1.00),
        ('MASK400', '1.1', 'MAT008', 1.000000, 1.00),
        ('MASK400', '1.1', 'MAT004', 1.000000, 1.00),
        ('MASK400', '1.1', 'MAT005', 0.080000, 2.00),

        -- GEL300
        ('GEL300', '1.0', 'MAT009', 0.300000, 1.20),
        ('GEL300', '1.0', 'MAT010', 1.000000, 1.00),
        ('GEL300', '1.0', 'MAT003', 1.000000, 1.00),
        ('GEL300', '1.0', 'MAT004', 1.000000, 1.00),
        ('GEL300', '1.0', 'MAT005', 0.080000, 2.00),

        -- BALM250
        ('BALM250', '1.0', 'MAT011', 0.250000, 1.00),
        ('BALM250', '1.0', 'MAT012', 1.000000, 1.00),
        ('BALM250', '1.0', 'MAT003', 1.000000, 1.00),
        ('BALM250', '1.0', 'MAT004', 1.000000, 1.00),
        ('BALM250', '1.0', 'MAT005', 0.100000, 2.00)
) AS v(article, version, material_code, quantity_per_unit, waste_percent)
JOIN products p
    ON p.article = v.article
JOIN specifications s
    ON s.product_id = p.product_id
   AND s.version = v.version
JOIN materials m
    ON m.code = v.material_code;


-- ============================================================
-- 5. PRODUCTION LINES
-- ============================================================

INSERT INTO production_lines
    (code, name, location, status, description)
VALUES
    ('MIX01',  'Участок смешивания №1', 'Цех 1', 'Active', 'Приготовление продукта'),
    ('FILL01', 'Линия розлива №1',      'Цех 2', 'Active', 'Основная линия розлива'),
    ('FILL02', 'Линия розлива №2',      'Цех 2', 'Active', 'Дополнительная линия розлива'),
    ('PACK01', 'Линия упаковки №1',     'Цех 3', 'Active', 'Маркировка и упаковка'),
    ('PACK02', 'Линия упаковки №2',     'Цех 3', 'Maintenance', 'Резервная линия');


-- ============================================================
-- 6. OPERATIONS
-- ============================================================

INSERT INTO operations
    (code, name, description)
VALUES
    ('OP001', 'Приготовление смеси', 'Подготовка и смешивание компонентов'),
    ('OP002', 'Розлив',              'Розлив продукта в первичную упаковку'),
    ('OP003', 'Маркировка',          'Нанесение этикетки'),
    ('OP004', 'Упаковка',            'Формирование групповой упаковки'),
    ('OP005', 'Паллетирование',      'Размещение коробов на паллете'),
    ('OP006', 'Мойка оборудования',  'Технологическая мойка оборудования');


-- ============================================================
-- 7. EMPLOYEES
-- ============================================================

INSERT INTO employees
    (personnel_number, full_name, position, is_active)
VALUES
    ('EMP001', 'Иванов Алексей',   'Мастер смены', true),
    ('EMP002', 'Петров Илья',      'Оператор смешивания', true),
    ('EMP003', 'Смирнова Анна',    'Оператор линии розлива №1', true),
    ('EMP004', 'Волкова Мария',    'Контролёр качества', true),
    ('EMP005', 'Кузнецов Павел',   'Кладовщик', true),
    ('EMP006', 'Лебедев Сергей',   'Оператор линии розлива №2', true),
    ('EMP007', 'Соколова Елена',   'Оператор маркировки', true),
    ('EMP008', 'Морозов Андрей',   'Упаковщик', true),
    ('EMP009', 'Орлов Денис',      'Механик', true);


-- ============================================================
-- 8. DEFECT TYPES
-- ============================================================

INSERT INTO defect_types
    (code, name, severity, description)
VALUES
    ('DEF001', 'Недолив',              'Major',    'Объём продукта ниже установленного'),
    ('DEF002', 'Повреждение упаковки', 'Minor',    'Повреждена первичная или транспортная упаковка'),
    ('DEF003', 'Неверная этикетка',    'Major',    'Использована неверная или повреждённая этикетка'),
    ('DEF004', 'Загрязнение продукта', 'Critical', 'Обнаружено загрязнение продукта'),
    ('DEF005', 'Нарушение герметичности','Major',  'Упаковка не обеспечивает необходимую герметичность');


-- ============================================================
-- 9. SHIFTS
-- ============================================================

INSERT INTO shifts
    (shift_date, shift_number, started_at, completed_at, supervisor_employee_id)
SELECT
    v.shift_date,
    1,
    v.shift_date + TIME '08:00',
    v.shift_date + TIME '20:00',
    e.employee_id
FROM (
    VALUES
        (DATE '2026-07-15'),
        (DATE '2026-07-20'),
        (DATE '2026-08-05'),
        (DATE '2026-08-18'),
        (DATE '2026-09-01'),
        (DATE '2026-09-09'),
        (DATE '2026-09-10'),
        (DATE '2026-09-12'),
        (DATE '2026-09-13'),
        (DATE '2026-09-14')
) AS v(shift_date)
JOIN employees e
    ON e.personnel_number = 'EMP001';


-- ============================================================
-- 10. PRODUCTION ORDERS
-- ============================================================

INSERT INTO production_orders
    (order_number, specification_id, planned_quantity,
     planned_start_at, planned_end_at, status)
SELECT
    v.order_number,
    s.specification_id,
    v.planned_quantity,
    v.planned_start_at,
    v.planned_end_at,
    v.status::production_order_status
FROM (
    VALUES
        ('PO-2026-001', 'SH500',   '2.0', 1000.000::numeric, TIMESTAMP '2026-09-09 08:00', TIMESTAMP '2026-09-10 18:00', 'Completed'),
        ('PO-2026-002', 'SH500',   '2.0',  600.000, TIMESTAMP '2026-08-05 08:00', TIMESTAMP '2026-08-05 18:00', 'Completed'),
        ('PO-2026-003', 'SH250',   '1.0',  800.000, TIMESTAMP '2026-09-12 08:00', TIMESTAMP '2026-09-13 18:00', 'InProgress'),
        ('PO-2026-004', 'MASK400', '1.0',  500.000, TIMESTAMP '2026-10-01 08:00', TIMESTAMP '2026-10-02 18:00', 'Planned'),
        ('PO-2026-005', 'GEL300',  '1.0',  700.000, TIMESTAMP '2026-08-18 08:00', TIMESTAMP '2026-08-18 20:00', 'Cancelled'),
        ('PO-2026-006', 'MASK400', '1.0',  400.000, TIMESTAMP '2026-07-20 08:00', TIMESTAMP '2026-07-20 18:00', 'InProgress'),
        ('PO-2026-007', 'SH250',   '1.0',  300.000, TIMESTAMP '2026-07-15 08:00', TIMESTAMP '2026-07-15 18:00', 'Completed'),
        ('PO-2026-008', 'GEL300',  '1.0', 1000.000, TIMESTAMP '2026-09-01 08:00', TIMESTAMP '2026-09-01 18:00', 'Completed'),
        ('PO-2026-009', 'SH500',   '2.0', 1200.000, NULL::timestamp, NULL::timestamp, 'Created'),
        ('PO-2026-010', 'MASK400', '1.0',  600.000, TIMESTAMP '2026-09-20 08:00', TIMESTAMP '2026-09-21 18:00', 'Planned'),
        ('TEST-ORDER-01', 'SH250', '1.0',  100.000, TIMESTAMP '2026-09-14 08:00', TIMESTAMP '2026-09-14 13:00', 'Completed'),
        ('DEV-2026-001', 'GEL300', '1.0',  200.000, TIMESTAMP '2026-10-01 08:00', TIMESTAMP '2026-10-01 18:00', 'Planned')
) AS v(
    order_number,
    article,
    version,
    planned_quantity,
    planned_start_at,
    planned_end_at,
    status
)
JOIN products p
    ON p.article = v.article
JOIN specifications s
    ON s.product_id = p.product_id
   AND s.version = v.version;


-- ============================================================
-- 11. PRODUCTION BATCHES
-- ============================================================

INSERT INTO production_batches
    (production_order_id, batch_number, planned_quantity,
     actual_quantity, started_at, completed_at, status)
SELECT
    po.production_order_id,
    v.batch_number,
    v.planned_quantity,
    v.actual_quantity,
    v.started_at,
    v.completed_at,
    v.status::production_batch_status
FROM (
    VALUES
        ('PO-2026-001', 'BATCH-001',      500.000::numeric, 500.000::numeric, TIMESTAMP '2026-09-09 08:15', TIMESTAMP '2026-09-09 17:30', 'Completed'),
        ('PO-2026-001', 'BATCH-002',      500.000, 493.000, TIMESTAMP '2026-09-10 08:10', TIMESTAMP '2026-09-10 17:45', 'Completed'),

        ('PO-2026-002', 'BATCH-003',      300.000, 298.000, TIMESTAMP '2026-08-05 08:05', TIMESTAMP '2026-08-05 17:00', 'Completed'),
        ('PO-2026-002', 'BATCH-004',      300.000, 300.000, TIMESTAMP '2026-08-05 08:15', TIMESTAMP '2026-08-05 17:20', 'Completed'),

        ('PO-2026-003', 'BATCH-005',      400.000, 395.000, TIMESTAMP '2026-09-12 08:20', TIMESTAMP '2026-09-12 17:10', 'Completed'),
        ('PO-2026-003', 'BATCH-006',      400.000, 250.000, TIMESTAMP '2026-09-13 08:15', NULL::timestamp, 'InProgress'),

        ('PO-2026-004', 'BATCH-007',      500.000, NULL::numeric, NULL::timestamp, NULL::timestamp, 'Planned'),

        ('PO-2026-005', 'BATCH-008-R',    350.000,   0.000, TIMESTAMP '2026-08-18 08:20', TIMESTAMP '2026-08-18 12:00', 'Rejected'),
        ('PO-2026-005', 'BATCH-008-C',    350.000, NULL::numeric, NULL::timestamp, NULL::timestamp, 'Cancelled'),

        ('PO-2026-006', 'BATCH-009',      200.000, 200.000, TIMESTAMP '2026-07-20 08:10', TIMESTAMP '2026-07-20 16:50', 'Completed'),
        ('PO-2026-006', 'BATCH-010',      200.000, 197.000, TIMESTAMP '2026-07-20 08:20', TIMESTAMP '2026-07-20 17:20', 'Completed'),

        ('PO-2026-007', 'BATCH-011',      300.000, 300.000, TIMESTAMP '2026-07-15 08:05', TIMESTAMP '2026-07-15 16:40', 'Completed'),

        ('PO-2026-008', 'BATCH-012',      500.000, 490.000, TIMESTAMP '2026-09-01 08:10', TIMESTAMP '2026-09-01 17:00', 'Completed'),
        ('PO-2026-008', 'BATCH-013',      500.000, 500.000, TIMESTAMP '2026-09-01 08:20', TIMESTAMP '2026-09-01 17:30', 'Completed'),

        ('PO-2026-010', 'BATCH-014',      300.000, NULL::numeric, NULL::timestamp, NULL::timestamp, 'Planned'),

        ('TEST-ORDER-01', 'TEST-BATCH-001', 100.000, 98.000, TIMESTAMP '2026-09-14 08:10', TIMESTAMP '2026-09-14 12:30', 'Completed'),

        ('DEV-2026-001', 'BATCH-DEV-001', 200.000, NULL::numeric, NULL::timestamp, NULL::timestamp, 'Planned')
) AS v(
    order_number,
    batch_number,
    planned_quantity,
    actual_quantity,
    started_at,
    completed_at,
    status
)
JOIN production_orders po
    ON po.order_number = v.order_number;


-- ============================================================
-- 12. BATCH OPERATIONS FOR COMPLETED BATCHES
-- ============================================================

WITH operation_map AS (
    SELECT *
    FROM (
        VALUES
            (1, 'OP001', 'MIX01',  'EMP002', INTERVAL '15 minutes',  INTERVAL '1 hour 45 minutes'),
            (2, 'OP002', 'FILL01', 'EMP003', INTERVAL '2 hours',     INTERVAL '4 hours'),
            (3, 'OP003', 'PACK01', 'EMP007', INTERVAL '4 hours 15 minutes', INTERVAL '5 hours 30 minutes'),
            (4, 'OP004', 'PACK01', 'EMP008', INTERVAL '5 hours 45 minutes', INTERVAL '7 hours 15 minutes'),
            (5, 'OP005', 'PACK01', 'EMP008', INTERVAL '7 hours 30 minutes', INTERVAL '8 hours')
    ) AS x(sequence_no, operation_code, default_line_code, personnel_number, start_offset, end_offset)
)
INSERT INTO batch_operations
    (batch_id, operation_id, production_line_id, employee_id, shift_id,
     sequence_no, started_at, completed_at, processed_quantity, status)
SELECT
    pb.batch_id,
    o.operation_id,
    pl.production_line_id,
    e.employee_id,
    sh.shift_id,
    om.sequence_no,
    pb.started_at + om.start_offset,
    pb.started_at + om.end_offset,
    CASE
        WHEN om.sequence_no >= 4 THEN pb.actual_quantity
        ELSE pb.planned_quantity
    END,
    'Completed'
FROM production_batches pb
CROSS JOIN operation_map om
JOIN operations o
    ON o.code = om.operation_code
JOIN production_lines pl
    ON pl.code =
       CASE
           WHEN om.operation_code = 'OP002'
                AND MOD(pb.batch_id, 2) = 0
               THEN 'FILL02'
           ELSE om.default_line_code
       END
JOIN employees e
    ON e.personnel_number =
       CASE
           WHEN om.operation_code = 'OP002'
                AND MOD(pb.batch_id, 2) = 0
               THEN 'EMP006'
           ELSE om.personnel_number
       END
JOIN shifts sh
    ON sh.shift_date = pb.started_at::date
   AND sh.shift_number = 1
WHERE pb.status = 'Completed';


-- ============================================================
-- 13. OPERATIONS FOR IN-PROGRESS BATCH
-- ============================================================

WITH operation_map AS (
    SELECT *
    FROM (
        VALUES
            (1, 'OP001', 'MIX01',  'EMP002', INTERVAL '15 minutes',  INTERVAL '1 hour 45 minutes'),
            (2, 'OP002', 'FILL01', 'EMP003', INTERVAL '2 hours',     INTERVAL '4 hours'),
            (3, 'OP003', 'PACK01', 'EMP007', INTERVAL '4 hours 15 minutes', INTERVAL '5 hours 30 minutes'),
            (4, 'OP004', 'PACK01', 'EMP008', INTERVAL '5 hours 45 minutes', INTERVAL '7 hours'),
            (5, 'OP005', 'PACK01', 'EMP008', INTERVAL '7 hours 15 minutes', NULL::interval)
    ) AS x(sequence_no, operation_code, line_code, personnel_number, start_offset, end_offset)
)
INSERT INTO batch_operations
    (batch_id, operation_id, production_line_id, employee_id, shift_id,
     sequence_no, started_at, completed_at, processed_quantity, status)
SELECT
    pb.batch_id,
    o.operation_id,
    pl.production_line_id,
    e.employee_id,
    sh.shift_id,
    om.sequence_no,
    pb.started_at + om.start_offset,
    CASE
        WHEN om.sequence_no = 5 THEN NULL
        ELSE pb.started_at + om.end_offset
    END,
    CASE
        WHEN om.sequence_no = 5 THEN 250.000
        ELSE pb.planned_quantity
    END,
    CASE
        WHEN om.sequence_no = 5 THEN 'InProgress'::batch_operation_status
        ELSE 'Completed'::batch_operation_status
    END
FROM production_batches pb
CROSS JOIN operation_map om
JOIN operations o
    ON o.code = om.operation_code
JOIN production_lines pl
    ON pl.code = om.line_code
JOIN employees e
    ON e.personnel_number = om.personnel_number
JOIN shifts sh
    ON sh.shift_date = pb.started_at::date
   AND sh.shift_number = 1
WHERE pb.batch_number = 'BATCH-006';


-- ============================================================
-- 14. MATERIAL USAGE
-- ============================================================

INSERT INTO material_usage
    (batch_id, material_id, employee_id,
     quantity_used, material_lot_number, recorded_at)
SELECT
    pb.batch_id,
    si.material_id,
    e.employee_id,
    ROUND(
        (
            pb.planned_quantity
            * si.quantity_per_unit
            * (1 + si.waste_percent / 100.0)
        )::numeric,
        6
    ),
    'LOT-' || m.code || '-' || LPAD(pb.batch_id::text, 3, '0'),
    pb.started_at + INTERVAL '45 minutes'
FROM production_batches pb
JOIN production_orders po
    ON po.production_order_id = pb.production_order_id
JOIN specification_items si
    ON si.specification_id = po.specification_id
JOIN materials m
    ON m.material_id = si.material_id
JOIN employees e
    ON e.personnel_number = 'EMP005'
WHERE pb.status IN ('Completed', 'InProgress');


-- ============================================================
-- 15. QUALITY CHECKS
-- ============================================================

INSERT INTO quality_checks
    (batch_id, employee_id, check_stage, checked_at, result, notes)
SELECT
    pb.batch_id,
    e.employee_id,
    v.check_stage::quality_check_stage,
    v.checked_at,
    v.result::quality_check_result,
    v.notes
FROM (
    VALUES
        ('BATCH-001', TIMESTAMP '2026-09-09 12:00', 'Intermediate', 'Passed',      NULL::text),
        ('BATCH-001', TIMESTAMP '2026-09-09 17:20', 'Final',        'Passed',      NULL),

        ('BATCH-002', TIMESTAMP '2026-09-10 12:30', 'Intermediate', 'Passed',      NULL),
        ('BATCH-002', TIMESTAMP '2026-09-10 17:30', 'Final',        'Conditional', 'Обнаружено 7 дефектных единиц'),

        ('BATCH-003', TIMESTAMP '2026-08-05 16:50', 'Final',        'Conditional', 'Зафиксирован недолив'),

        ('BATCH-004', TIMESTAMP '2026-08-05 17:00', 'Final',        'Passed',      NULL),

        ('BATCH-005', TIMESTAMP '2026-09-12 12:00', 'Intermediate', 'Passed',      NULL),
        ('BATCH-005', TIMESTAMP '2026-09-12 17:00', 'Final',        'Conditional', 'Обнаружено нарушение герметичности'),

        ('BATCH-006', TIMESTAMP '2026-09-13 13:30', 'Intermediate', 'Passed',      NULL),

        ('BATCH-008-R', TIMESTAMP '2026-08-18 11:45', 'Final', 'Failed', 'Обнаружено загрязнение продукта'),

        ('BATCH-009', TIMESTAMP '2026-07-20 16:40', 'Final', 'Passed', NULL),

        ('BATCH-010', TIMESTAMP '2026-07-20 17:10', 'Final', 'Failed', 'Критический дефект качества'),

        ('BATCH-011', TIMESTAMP '2026-07-15 16:30', 'Final', 'Passed', NULL),

        ('BATCH-012', TIMESTAMP '2026-09-01 12:00', 'Intermediate', 'Passed', NULL),
        ('BATCH-012', TIMESTAMP '2026-09-01 16:50', 'Final', 'Conditional', 'Обнаружено 10 дефектных единиц'),

        ('BATCH-013', TIMESTAMP '2026-09-01 17:20', 'Final', 'Passed', NULL),

        ('TEST-BATCH-001', TIMESTAMP '2026-09-14 12:20', 'Final', 'Conditional', 'Тестовый дефект упаковки')
) AS v(batch_number, checked_at, check_stage, result, notes)
JOIN production_batches pb
    ON pb.batch_number = v.batch_number
JOIN employees e
    ON e.personnel_number = 'EMP004';


-- ============================================================
-- 16. DEFECTS
-- ============================================================

INSERT INTO defects
    (quality_check_id, defect_type_id, quantity, description)
SELECT
    qc.quality_check_id,
    dt.defect_type_id,
    v.quantity,
    v.description
FROM (
    VALUES
        ('BATCH-002', TIMESTAMP '2026-09-10 17:30', 'DEF002', 4.000::numeric, 'Повреждение упаковки'),
        ('BATCH-002', TIMESTAMP '2026-09-10 17:30', 'DEF003', 3.000, 'Неверная этикетка'),

        ('BATCH-003', TIMESTAMP '2026-08-05 16:50', 'DEF001', 2.000, 'Недолив'),

        ('BATCH-005', TIMESTAMP '2026-09-12 17:00', 'DEF005', 5.000, 'Нарушение герметичности'),

        ('BATCH-008-R', TIMESTAMP '2026-08-18 11:45', 'DEF004', 20.000, 'Загрязнение продукта'),

        ('BATCH-010', TIMESTAMP '2026-07-20 17:10', 'DEF004', 3.000, 'Критическое загрязнение'),

        ('BATCH-012', TIMESTAMP '2026-09-01 16:50', 'DEF002', 6.000, 'Повреждение упаковки'),
        ('BATCH-012', TIMESTAMP '2026-09-01 16:50', 'DEF003', 4.000, 'Неверная этикетка'),

        ('TEST-BATCH-001', TIMESTAMP '2026-09-14 12:20', 'DEF002', 2.000, 'Тестовая запись для DELETE USING')
) AS v(batch_number, checked_at, defect_code, quantity, description)
JOIN production_batches pb
    ON pb.batch_number = v.batch_number
JOIN quality_checks qc
    ON qc.batch_id = pb.batch_id
   AND qc.checked_at = v.checked_at
JOIN defect_types dt
    ON dt.code = v.defect_code;


COMMIT;
