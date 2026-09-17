-- ============================================================
-- Дополнительные индексы производственной БД
-- ============================================================


-- ============================================================
-- PRODUCTION ORDERS
-- ============================================================

CREATE INDEX idx_production_orders_specification
    ON production_orders (specification_id);

COMMENT ON INDEX idx_production_orders_specification IS
'Ускоряет поиск производственных заказов по спецификации';


CREATE INDEX idx_production_orders_status_start
    ON production_orders (status, planned_start_at);

COMMENT ON INDEX idx_production_orders_status_start IS
'Ускоряет поиск заказов определённого статуса по периоду планового запуска';


-- ============================================================
-- PRODUCTION BATCHES
-- ============================================================

CREATE INDEX idx_production_batches_status_started
    ON production_batches (status, started_at);

COMMENT ON INDEX idx_production_batches_status_started IS
'Ускоряет поиск производственных партий определённого статуса по времени запуска';


-- ============================================================
-- SPECIFICATION ITEMS
-- ============================================================

CREATE INDEX idx_specification_items_material
    ON specification_items (material_id);

COMMENT ON INDEX idx_specification_items_material IS
'Ускоряет поиск спецификаций, содержащих определённый материал';


-- ============================================================
-- BATCH OPERATIONS
-- ============================================================

CREATE INDEX idx_batch_operations_line_started
    ON batch_operations (production_line_id, started_at);

COMMENT ON INDEX idx_batch_operations_line_started IS
'Ускоряет поиск операций, начатых на конкретной производственной линии за период';


CREATE INDEX idx_batch_operations_employee_started
    ON batch_operations (employee_id, started_at);

COMMENT ON INDEX idx_batch_operations_employee_started IS
'Ускоряет поиск операций, начатых конкретным сотрудником за период';


CREATE INDEX idx_batch_operations_shift
    ON batch_operations (shift_id);

COMMENT ON INDEX idx_batch_operations_shift IS
'Ускоряет получение технологических операций конкретной смены';


CREATE INDEX idx_batch_operations_operation
    ON batch_operations (operation_id);

COMMENT ON INDEX idx_batch_operations_operation IS
'Ускоряет поиск выполнений определённого типа технологической операции';


-- ============================================================
-- MATERIAL USAGE
-- ============================================================

CREATE INDEX idx_material_usage_batch_material
    ON material_usage (batch_id, material_id);

COMMENT ON INDEX idx_material_usage_batch_material IS
'Ускоряет анализ расхода конкретного материала в производственной партии';


CREATE INDEX idx_material_usage_material_recorded
    ON material_usage (material_id, recorded_at);

COMMENT ON INDEX idx_material_usage_material_recorded IS
'Ускоряет анализ зарегистрированного расхода материала за период';


-- ============================================================
-- QUALITY CHECKS
-- ============================================================

CREATE INDEX idx_quality_checks_batch_checked
    ON quality_checks (batch_id, checked_at);

COMMENT ON INDEX idx_quality_checks_batch_checked IS
'Ускоряет получение истории проверок качества конкретной партии';


CREATE INDEX idx_quality_checks_result_checked
    ON quality_checks (result, checked_at);

COMMENT ON INDEX idx_quality_checks_result_checked IS
'Ускоряет поиск проверок определённого результата за период';


-- ============================================================
-- DEFECTS
-- ============================================================

CREATE INDEX idx_defects_type
    ON defects (defect_type_id);

COMMENT ON INDEX idx_defects_type IS
'Ускоряет поиск и анализ дефектов определённого типа';


-- ============================================================
-- FULL-TEXT SEARCH
-- ============================================================

CREATE INDEX idx_products_fts
    ON products
    USING GIN (
        to_tsvector(
            'russian',
            coalesce(name, '') || ' ' || coalesce(description, '')
        )
    );

COMMENT ON INDEX idx_products_fts IS
'GIN-индекс для полнотекстового поиска по названию и описанию продукции';
