BEGIN;

-- ============================================================
-- ENUM
-- ============================================================

CREATE TYPE specification_status AS ENUM (
    'Draft',
    'Active',
    'Archived'
);

CREATE TYPE production_order_status AS ENUM (
    'Created',
    'Planned',
    'InProgress',
    'Completed',
    'Cancelled'
);

CREATE TYPE production_batch_status AS ENUM (
    'Planned',
    'InProgress',
    'Completed',
    'Rejected',
    'Cancelled'
);

CREATE TYPE production_line_status AS ENUM (
    'Active',
    'Maintenance',
    'Inactive'
);

CREATE TYPE batch_operation_status AS ENUM (
    'Planned',
    'InProgress',
    'Completed',
    'Cancelled'
);

CREATE TYPE quality_check_stage AS ENUM (
    'Intermediate',
    'Final'
);

CREATE TYPE quality_check_result AS ENUM (
    'Passed',
    'Failed',
    'Conditional'
);

CREATE TYPE defect_severity AS ENUM (
    'Minor',
    'Major',
    'Critical'
);


-- ============================================================
-- PRODUCTS
-- ============================================================

CREATE TABLE products (
    product_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name varchar(200) NOT NULL,
    article varchar(50) NOT NULL UNIQUE,
    unit varchar(20) NOT NULL,
    description text,
    is_active boolean NOT NULL DEFAULT true
);


-- ============================================================
-- MATERIALS
-- ============================================================

CREATE TABLE materials (
    material_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code varchar(50) NOT NULL UNIQUE,
    name varchar(200) NOT NULL,
    unit varchar(20) NOT NULL,
    description text,
    is_active boolean NOT NULL DEFAULT true
);


-- ============================================================
-- SPECIFICATIONS
-- ============================================================

CREATE TABLE specifications (
    specification_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id bigint NOT NULL,
    version varchar(20) NOT NULL,
    name varchar(150) NOT NULL,
    valid_from date,
    valid_to date,
    status specification_status NOT NULL DEFAULT 'Draft',
    created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_specifications_product_version
        UNIQUE (product_id, version),

    CONSTRAINT chk_specification_dates
        CHECK (valid_to >= valid_from),

    CONSTRAINT fk_specifications_product
        FOREIGN KEY (product_id)
        REFERENCES products (product_id)
        ON DELETE RESTRICT
);


-- ============================================================
-- SPECIFICATION ITEMS
-- ============================================================

CREATE TABLE specification_items (
    specification_item_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    specification_id bigint NOT NULL,
    material_id bigint NOT NULL,
    quantity_per_unit numeric(18,6) NOT NULL,
    waste_percent numeric(5,2) NOT NULL DEFAULT 0,

    CONSTRAINT uq_specification_items_specification_material
        UNIQUE (specification_id, material_id),

    CONSTRAINT chk_specification_item_quantity
        CHECK (quantity_per_unit > 0),

    CONSTRAINT chk_waste_percent
        CHECK (waste_percent >= 0 AND waste_percent <= 100),

    CONSTRAINT fk_specification_items_specification
        FOREIGN KEY (specification_id)
        REFERENCES specifications (specification_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_specification_items_material
        FOREIGN KEY (material_id)
        REFERENCES materials (material_id)
        ON DELETE RESTRICT
);


-- ============================================================
-- PRODUCTION ORDERS
-- ============================================================

CREATE TABLE production_orders (
    production_order_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_number varchar(50) NOT NULL UNIQUE,
    specification_id bigint NOT NULL,
    planned_quantity numeric(18,3) NOT NULL,
    planned_start_at timestamp,
    planned_end_at timestamp,
    status production_order_status NOT NULL DEFAULT 'Created',
    created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_order_planned_quantity
        CHECK (planned_quantity > 0),

    CONSTRAINT chk_order_dates
        CHECK (planned_end_at >= planned_start_at),

    CONSTRAINT fk_production_orders_specification
        FOREIGN KEY (specification_id)
        REFERENCES specifications (specification_id)
        ON DELETE RESTRICT
);


-- ============================================================
-- PRODUCTION BATCHES
-- ============================================================

CREATE TABLE production_batches (
    batch_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    production_order_id bigint NOT NULL,
    batch_number varchar(50) NOT NULL,
    planned_quantity numeric(18,3) NOT NULL,
    actual_quantity numeric(18,3),
    started_at timestamp,
    completed_at timestamp,
    status production_batch_status NOT NULL DEFAULT 'Planned',

    CONSTRAINT uq_production_batches_order_batch
        UNIQUE (production_order_id, batch_number),

    CONSTRAINT chk_batch_planned_quantity
        CHECK (planned_quantity > 0),

    CONSTRAINT chk_batch_actual_quantity
        CHECK (actual_quantity >= 0),

    CONSTRAINT chk_batch_dates
        CHECK (completed_at >= started_at),

    CONSTRAINT fk_production_batches_order
        FOREIGN KEY (production_order_id)
        REFERENCES production_orders (production_order_id)
        ON DELETE RESTRICT
);


-- ============================================================
-- PRODUCTION LINES
-- ============================================================

CREATE TABLE production_lines (
    production_line_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code varchar(30) NOT NULL UNIQUE,
    name varchar(100) NOT NULL,
    location varchar(100),
    status production_line_status NOT NULL DEFAULT 'Active',
    description text
);


-- ============================================================
-- OPERATIONS
-- ============================================================

CREATE TABLE operations (
    operation_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code varchar(30) NOT NULL UNIQUE,
    name varchar(100) NOT NULL,
    description text
);


-- ============================================================
-- EMPLOYEES
-- ============================================================

CREATE TABLE employees (
    employee_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    personnel_number varchar(30) NOT NULL UNIQUE,
    full_name varchar(150) NOT NULL,
    position varchar(100) NOT NULL,
    is_active boolean NOT NULL DEFAULT true
);


-- ============================================================
-- SHIFTS
-- ============================================================

CREATE TABLE shifts (
    shift_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    shift_date date NOT NULL,
    shift_number integer NOT NULL,
    started_at timestamp NOT NULL,
    completed_at timestamp NOT NULL,
    supervisor_employee_id bigint NOT NULL,

    CONSTRAINT uq_shifts_date_number
        UNIQUE (shift_date, shift_number),

    CONSTRAINT chk_shift_number
        CHECK (shift_number > 0),

    CONSTRAINT chk_shift_dates
        CHECK (completed_at > started_at),

    CONSTRAINT fk_shifts_supervisor
        FOREIGN KEY (supervisor_employee_id)
        REFERENCES employees (employee_id)
        ON DELETE RESTRICT
);


-- ============================================================
-- BATCH OPERATIONS
-- ============================================================

CREATE TABLE batch_operations (
    batch_operation_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    batch_id bigint NOT NULL,
    operation_id bigint NOT NULL,
    production_line_id bigint NOT NULL,
    employee_id bigint NOT NULL,
    shift_id bigint NOT NULL,
    sequence_no integer NOT NULL,
    started_at timestamp,
    completed_at timestamp,
    processed_quantity numeric(18,3),
    status batch_operation_status NOT NULL DEFAULT 'Planned',

    CONSTRAINT uq_batch_operations_batch_sequence
        UNIQUE (batch_id, sequence_no),

    CONSTRAINT chk_operation_sequence
        CHECK (sequence_no > 0),

    CONSTRAINT chk_processed_quantity
        CHECK (processed_quantity >= 0),

    CONSTRAINT chk_batch_operation_dates
        CHECK (completed_at >= started_at),

    CONSTRAINT fk_batch_operations_batch
        FOREIGN KEY (batch_id)
        REFERENCES production_batches (batch_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_batch_operations_operation
        FOREIGN KEY (operation_id)
        REFERENCES operations (operation_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_batch_operations_line
        FOREIGN KEY (production_line_id)
        REFERENCES production_lines (production_line_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_batch_operations_employee
        FOREIGN KEY (employee_id)
        REFERENCES employees (employee_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_batch_operations_shift
        FOREIGN KEY (shift_id)
        REFERENCES shifts (shift_id)
        ON DELETE RESTRICT
);


-- ============================================================
-- MATERIAL USAGE
-- ============================================================

CREATE TABLE material_usage (
    material_usage_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    batch_id bigint NOT NULL,
    material_id bigint NOT NULL,
    employee_id bigint NOT NULL,
    quantity_used numeric(18,6) NOT NULL,
    material_lot_number varchar(50),
    recorded_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_material_usage_quantity
        CHECK (quantity_used > 0),

    CONSTRAINT fk_material_usage_batch
        FOREIGN KEY (batch_id)
        REFERENCES production_batches (batch_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_material_usage_material
        FOREIGN KEY (material_id)
        REFERENCES materials (material_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_material_usage_employee
        FOREIGN KEY (employee_id)
        REFERENCES employees (employee_id)
        ON DELETE RESTRICT
);


-- ============================================================
-- QUALITY CHECKS
-- ============================================================

CREATE TABLE quality_checks (
    quality_check_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    batch_id bigint NOT NULL,
    employee_id bigint NOT NULL,
    check_stage quality_check_stage NOT NULL,
    checked_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    result quality_check_result NOT NULL,
    notes text,

    CONSTRAINT fk_quality_checks_batch
        FOREIGN KEY (batch_id)
        REFERENCES production_batches (batch_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_quality_checks_employee
        FOREIGN KEY (employee_id)
        REFERENCES employees (employee_id)
        ON DELETE RESTRICT
);


-- ============================================================
-- DEFECT TYPES
-- ============================================================

CREATE TABLE defect_types (
    defect_type_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code varchar(30) NOT NULL UNIQUE,
    name varchar(100) NOT NULL,
    severity defect_severity NOT NULL,
    description text,
    is_active boolean NOT NULL DEFAULT true
);


-- ============================================================
-- DEFECTS
-- ============================================================

CREATE TABLE defects (
    defect_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    quality_check_id bigint NOT NULL,
    defect_type_id bigint NOT NULL,
    quantity numeric(18,3) NOT NULL,
    description text,

    CONSTRAINT uq_defects_check_type
        UNIQUE (quality_check_id, defect_type_id),

    CONSTRAINT chk_defect_quantity
        CHECK (quantity > 0),

    CONSTRAINT fk_defects_quality_check
        FOREIGN KEY (quality_check_id)
        REFERENCES quality_checks (quality_check_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_defects_type
        FOREIGN KEY (defect_type_id)
        REFERENCES defect_types (defect_type_id)
        ON DELETE RESTRICT
);

COMMIT;
