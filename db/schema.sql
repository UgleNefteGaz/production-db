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

CREATE TABLE "Products" (
    "ProductId" bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "Name" varchar(200) NOT NULL,
    "Article" varchar(50) NOT NULL UNIQUE,
    "Unit" varchar(20) NOT NULL,
    "Description" text,
    "IsActive" boolean NOT NULL DEFAULT true
);


-- ============================================================
-- MATERIALS
-- ============================================================

CREATE TABLE "Materials" (
    "MaterialId" bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "Code" varchar(50) NOT NULL UNIQUE,
    "Name" varchar(200) NOT NULL,
    "Unit" varchar(20) NOT NULL,
    "Description" text,
    "IsActive" boolean NOT NULL DEFAULT true
);


-- ============================================================
-- SPECIFICATIONS
-- ============================================================

CREATE TABLE "Specifications" (
    "SpecificationId" bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "ProductId" bigint NOT NULL,
    "Version" varchar(20) NOT NULL,
    "Name" varchar(150) NOT NULL,
    "ValidFrom" date,
    "ValidTo" date,
    "Status" specification_status NOT NULL DEFAULT 'Draft',
    "CreatedAt" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "uq_specifications_product_version"
        UNIQUE ("ProductId", "Version"),

    CONSTRAINT "chk_specification_dates"
        CHECK ("ValidTo" >= "ValidFrom"),

    CONSTRAINT "fk_specifications_product"
        FOREIGN KEY ("ProductId")
        REFERENCES "Products" ("ProductId")
        ON DELETE RESTRICT
);


-- ============================================================
-- SPECIFICATION ITEMS
-- ============================================================

CREATE TABLE "SpecificationItems" (
    "SpecificationItemId" bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "SpecificationId" bigint NOT NULL,
    "MaterialId" bigint NOT NULL,
    "QuantityPerUnit" numeric(18,6) NOT NULL,
    "WastePercent" numeric(5,2) NOT NULL DEFAULT 0,

    CONSTRAINT "uq_specification_items_specification_material"
        UNIQUE ("SpecificationId", "MaterialId"),

    CONSTRAINT "chk_specification_item_quantity"
        CHECK ("QuantityPerUnit" > 0),

    CONSTRAINT "chk_waste_percent"
        CHECK ("WastePercent" >= 0 AND "WastePercent" <= 100),

    CONSTRAINT "fk_specification_items_specification"
        FOREIGN KEY ("SpecificationId")
        REFERENCES "Specifications" ("SpecificationId")
        ON DELETE CASCADE,

    CONSTRAINT "fk_specification_items_material"
        FOREIGN KEY ("MaterialId")
        REFERENCES "Materials" ("MaterialId")
        ON DELETE RESTRICT
);


-- ============================================================
-- PRODUCTION ORDERS
-- ============================================================

CREATE TABLE "ProductionOrders" (
    "ProductionOrderId" bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "OrderNumber" varchar(50) NOT NULL UNIQUE,
    "SpecificationId" bigint NOT NULL,
    "PlannedQuantity" numeric(18,3) NOT NULL,
    "PlannedStartAt" timestamp,
    "PlannedEndAt" timestamp,
    "Status" production_order_status NOT NULL DEFAULT 'Created',
    "CreatedAt" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "chk_order_planned_quantity"
        CHECK ("PlannedQuantity" > 0),

    CONSTRAINT "chk_order_dates"
        CHECK ("PlannedEndAt" >= "PlannedStartAt"),

    CONSTRAINT "fk_production_orders_specification"
        FOREIGN KEY ("SpecificationId")
        REFERENCES "Specifications" ("SpecificationId")
        ON DELETE RESTRICT
);


-- ============================================================
-- PRODUCTION BATCHES
-- ============================================================

CREATE TABLE "ProductionBatches" (
    "BatchId" bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "ProductionOrderId" bigint NOT NULL,
    "BatchNumber" varchar(50) NOT NULL,
    "PlannedQuantity" numeric(18,3) NOT NULL,
    "ActualQuantity" numeric(18,3),
    "StartedAt" timestamp,
    "CompletedAt" timestamp,
    "Status" production_batch_status NOT NULL DEFAULT 'Planned',

    CONSTRAINT "uq_production_batches_order_batch"
        UNIQUE ("ProductionOrderId", "BatchNumber"),

    CONSTRAINT "chk_batch_planned_quantity"
        CHECK ("PlannedQuantity" > 0),

    CONSTRAINT "chk_batch_actual_quantity"
        CHECK ("ActualQuantity" >= 0),

    CONSTRAINT "chk_batch_dates"
        CHECK ("CompletedAt" >= "StartedAt"),

    CONSTRAINT "fk_production_batches_order"
        FOREIGN KEY ("ProductionOrderId")
        REFERENCES "ProductionOrders" ("ProductionOrderId")
        ON DELETE RESTRICT
);


-- ============================================================
-- PRODUCTION LINES
-- ============================================================

CREATE TABLE "ProductionLines" (
    "ProductionLineId" bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "Code" varchar(30) NOT NULL UNIQUE,
    "Name" varchar(100) NOT NULL,
    "Location" varchar(100),
    "Status" production_line_status NOT NULL DEFAULT 'Active',
    "Description" text
);


-- ============================================================
-- OPERATIONS
-- ============================================================

CREATE TABLE "Operations" (
    "OperationId" bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "Code" varchar(30) NOT NULL UNIQUE,
    "Name" varchar(100) NOT NULL,
    "Description" text
);


-- ============================================================
-- EMPLOYEES
-- ============================================================

CREATE TABLE "Employees" (
    "EmployeeId" bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "PersonnelNumber" varchar(30) NOT NULL UNIQUE,
    "FullName" varchar(150) NOT NULL,
    "Position" varchar(100) NOT NULL,
    "IsActive" boolean NOT NULL DEFAULT true
);


-- ============================================================
-- SHIFTS
-- ============================================================

CREATE TABLE "Shifts" (
    "ShiftId" bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "ShiftDate" date NOT NULL,
    "ShiftNumber" integer NOT NULL,
    "StartedAt" timestamp NOT NULL,
    "CompletedAt" timestamp NOT NULL,
    "SupervisorEmployeeId" bigint NOT NULL,

    CONSTRAINT "uq_shifts_date_number"
        UNIQUE ("ShiftDate", "ShiftNumber"),

    CONSTRAINT "chk_shift_number"
        CHECK ("ShiftNumber" > 0),

    CONSTRAINT "chk_shift_dates"
        CHECK ("CompletedAt" > "StartedAt"),

    CONSTRAINT "fk_shifts_supervisor"
        FOREIGN KEY ("SupervisorEmployeeId")
        REFERENCES "Employees" ("EmployeeId")
        ON DELETE RESTRICT
);


-- ============================================================
-- BATCH OPERATIONS
-- ============================================================

CREATE TABLE "BatchOperations" (
    "BatchOperationId" bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "BatchId" bigint NOT NULL,
    "OperationId" bigint NOT NULL,
    "ProductionLineId" bigint NOT NULL,
    "EmployeeId" bigint NOT NULL,
    "ShiftId" bigint NOT NULL,
    "SequenceNo" integer NOT NULL,
    "StartedAt" timestamp,
    "CompletedAt" timestamp,
    "ProcessedQuantity" numeric(18,3),
    "Status" batch_operation_status NOT NULL DEFAULT 'Planned',

    CONSTRAINT "uq_batch_operations_batch_sequence"
        UNIQUE ("BatchId", "SequenceNo"),

    CONSTRAINT "chk_operation_sequence"
        CHECK ("SequenceNo" > 0),

    CONSTRAINT "chk_processed_quantity"
        CHECK ("ProcessedQuantity" >= 0),

    CONSTRAINT "chk_batch_operation_dates"
        CHECK ("CompletedAt" >= "StartedAt"),

    CONSTRAINT "fk_batch_operations_batch"
        FOREIGN KEY ("BatchId")
        REFERENCES "ProductionBatches" ("BatchId")
        ON DELETE RESTRICT,

    CONSTRAINT "fk_batch_operations_operation"
        FOREIGN KEY ("OperationId")
        REFERENCES "Operations" ("OperationId")
        ON DELETE RESTRICT,

    CONSTRAINT "fk_batch_operations_line"
        FOREIGN KEY ("ProductionLineId")
        REFERENCES "ProductionLines" ("ProductionLineId")
        ON DELETE RESTRICT,

    CONSTRAINT "fk_batch_operations_employee"
        FOREIGN KEY ("EmployeeId")
        REFERENCES "Employees" ("EmployeeId")
        ON DELETE RESTRICT,

    CONSTRAINT "fk_batch_operations_shift"
        FOREIGN KEY ("ShiftId")
        REFERENCES "Shifts" ("ShiftId")
        ON DELETE RESTRICT
);


-- ============================================================
-- MATERIAL USAGE
-- ============================================================

CREATE TABLE "MaterialUsage" (
    "MaterialUsageId" bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "BatchId" bigint NOT NULL,
    "MaterialId" bigint NOT NULL,
    "EmployeeId" bigint NOT NULL,
    "QuantityUsed" numeric(18,6) NOT NULL,
    "MaterialLotNumber" varchar(50),
    "RecordedAt" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "chk_material_usage_quantity"
        CHECK ("QuantityUsed" > 0),

    CONSTRAINT "fk_material_usage_batch"
        FOREIGN KEY ("BatchId")
        REFERENCES "ProductionBatches" ("BatchId")
        ON DELETE RESTRICT,

    CONSTRAINT "fk_material_usage_material"
        FOREIGN KEY ("MaterialId")
        REFERENCES "Materials" ("MaterialId")
        ON DELETE RESTRICT,

    CONSTRAINT "fk_material_usage_employee"
        FOREIGN KEY ("EmployeeId")
        REFERENCES "Employees" ("EmployeeId")
        ON DELETE RESTRICT
);


-- ============================================================
-- QUALITY CHECKS
-- ============================================================

CREATE TABLE "QualityChecks" (
    "QualityCheckId" bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "BatchId" bigint NOT NULL,
    "EmployeeId" bigint NOT NULL,
    "CheckStage" quality_check_stage NOT NULL,
    "CheckedAt" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "Result" quality_check_result NOT NULL,
    "Notes" text,

    CONSTRAINT "fk_quality_checks_batch"
        FOREIGN KEY ("BatchId")
        REFERENCES "ProductionBatches" ("BatchId")
        ON DELETE RESTRICT,

    CONSTRAINT "fk_quality_checks_employee"
        FOREIGN KEY ("EmployeeId")
        REFERENCES "Employees" ("EmployeeId")
        ON DELETE RESTRICT
);


-- ============================================================
-- DEFECT TYPES
-- ============================================================

CREATE TABLE "DefectTypes" (
    "DefectTypeId" bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "Code" varchar(30) NOT NULL UNIQUE,
    "Name" varchar(100) NOT NULL,
    "Severity" defect_severity NOT NULL,
    "Description" text,
    "IsActive" boolean NOT NULL DEFAULT true
);


-- ============================================================
-- DEFECTS
-- ============================================================

CREATE TABLE "Defects" (
    "DefectId" bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "QualityCheckId" bigint NOT NULL,
    "DefectTypeId" bigint NOT NULL,
    "Quantity" numeric(18,3) NOT NULL,
    "Description" text,

    CONSTRAINT "uq_defects_check_type"
        UNIQUE ("QualityCheckId", "DefectTypeId"),

    CONSTRAINT "chk_defect_quantity"
        CHECK ("Quantity" > 0),

    CONSTRAINT "fk_defects_quality_check"
        FOREIGN KEY ("QualityCheckId")
        REFERENCES "QualityChecks" ("QualityCheckId")
        ON DELETE CASCADE,

    CONSTRAINT "fk_defects_type"
        FOREIGN KEY ("DefectTypeId")
        REFERENCES "DefectTypes" ("DefectTypeId")
        ON DELETE RESTRICT
);

COMMIT;
