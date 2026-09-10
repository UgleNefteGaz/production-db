-- Дополнительные ограничения бизнес-логики


-- ============================================================
-- SPECIFICATIONS
-- ============================================================

ALTER TABLE specifications
ADD CONSTRAINT chk_specification_valid_period
CHECK (
    valid_to IS NULL
    OR valid_from IS NOT NULL
);


-- Для одного продукта допускается только одна активная спецификация.

CREATE UNIQUE INDEX uq_specifications_one_active_per_product
    ON specifications (product_id)
    WHERE status = 'Active';


-- ============================================================
-- PRODUCTION ORDERS
-- ============================================================

ALTER TABLE production_orders
ADD CONSTRAINT chk_order_planned_period
CHECK (
    planned_end_at IS NULL
    OR planned_start_at IS NOT NULL
);


-- ============================================================
-- PRODUCTION BATCHES
-- ============================================================

ALTER TABLE production_batches
ADD CONSTRAINT chk_batch_completion_requires_start
CHECK (
    completed_at IS NULL
    OR started_at IS NOT NULL
);

ALTER TABLE production_batches
ADD CONSTRAINT chk_completed_batch_data
CHECK (
    status <> 'Completed'
    OR (
        started_at IS NOT NULL
        AND completed_at IS NOT NULL
        AND actual_quantity IS NOT NULL
    )
);


-- ============================================================
-- BATCH OPERATIONS
-- ============================================================

ALTER TABLE batch_operations
ADD CONSTRAINT chk_operation_completion_requires_start
CHECK (
    completed_at IS NULL
    OR started_at IS NOT NULL
);

ALTER TABLE batch_operations
ADD CONSTRAINT chk_completed_operation_data
CHECK (
    status <> 'Completed'
    OR (
        started_at IS NOT NULL
        AND completed_at IS NOT NULL
        AND processed_quantity IS NOT NULL
        AND processed_quantity > 0
    )
);


-- ============================================================
-- SHIFTS
-- ============================================================

ALTER TABLE shifts
ADD CONSTRAINT chk_shift_start_date
CHECK (
    started_at::date = shift_date
);


-- ============================================================
-- QUALITY CHECKS
-- ============================================================

ALTER TABLE quality_checks
ADD CONSTRAINT chk_quality_failure_notes
CHECK (
    result = 'Passed'
    OR NULLIF(BTRIM(notes), '') IS NOT NULL
);
