-- Дополнительные индексы производственной БД

CREATE INDEX idx_production_orders_specification
    ON production_orders (specification_id);

CREATE INDEX idx_production_orders_status_start
    ON production_orders (status, planned_start_at);

CREATE INDEX idx_production_batches_status_started
    ON production_batches (status, started_at);

CREATE INDEX idx_specification_items_material
    ON specification_items (material_id);

CREATE INDEX idx_batch_operations_line_started
    ON batch_operations (production_line_id, started_at);

CREATE INDEX idx_batch_operations_employee_started
    ON batch_operations (employee_id, started_at);

CREATE INDEX idx_batch_operations_shift
    ON batch_operations (shift_id);

CREATE INDEX idx_batch_operations_operation
    ON batch_operations (operation_id);

CREATE INDEX idx_material_usage_batch_material
    ON material_usage (batch_id, material_id);

CREATE INDEX idx_material_usage_material_recorded
    ON material_usage (material_id, recorded_at);

CREATE INDEX idx_quality_checks_batch_checked
    ON quality_checks (batch_id, checked_at);

CREATE INDEX idx_quality_checks_result_checked
    ON quality_checks (result, checked_at);

CREATE INDEX idx_defects_type
    ON defects (defect_type_id);
