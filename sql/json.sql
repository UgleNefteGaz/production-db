-- ============================================================
-- JSONB EXAMPLES
-- ============================================================
--
-- В таблице quality_checks поле measurements используется
-- для хранения дополнительных параметров контроля качества,
-- структура которых может отличаться для разных продуктов.
--
-- Тип поля:
--
-- measurements jsonb NOT NULL DEFAULT '{}'::jsonb
--



-- ============================================================
-- 1. INSERT WITH JSONB
-- ============================================================

-- Пример добавления проверки качества с JSONB-данными.
-- ID партии и сотрудника получаются по бизнес-ключам,
-- поэтому запрос не зависит от конкретных значений identity.

INSERT INTO quality_checks (
    batch_id,
    employee_id,
    check_stage,
    checked_at,
    result,
    notes,
    measurements
)
SELECT
    pb.batch_id,
    e.employee_id,
    'Intermediate'::quality_check_stage,
    TIMESTAMP '2026-08-05 16:30',
    'Passed'::quality_check_result,
    'Дополнительная проверка параметров продукта',
    '{
        "ph": 5.5,
        "temperature_c": 22.4,
        "viscosity_mpa_s": 3250,
        "appearance": "transparent",
        "device": {
            "code": "QC-DEVICE-01",
            "calibrated": true
        }
    }'::jsonb
FROM production_batches pb
CROSS JOIN employees e
WHERE pb.batch_number = 'BATCH-004'
  AND e.personnel_number = 'EMP004'
  AND NOT EXISTS (
      SELECT 1
      FROM quality_checks qc
      WHERE qc.batch_id = pb.batch_id
        AND qc.employee_id = e.employee_id
        AND qc.checked_at = TIMESTAMP '2026-08-05 16:30'
  )
RETURNING
    quality_check_id,
    batch_id,
    employee_id,
    check_stage,
    checked_at,
    result,
    measurements;


-- ============================================================
-- 2. SELECT FULL JSONB OBJECT
-- ============================================================

SELECT
    quality_check_id,
    measurements
FROM quality_checks
WHERE measurements <> '{}'::jsonb
ORDER BY quality_check_id;


-- ============================================================
-- 3. EXTRACT VALUE WITH -> AND ->>
-- ============================================================

-- -> возвращает значение как jsonb.
-- ->> возвращает значение как text.

SELECT
    quality_check_id,
    measurements -> 'ph' AS ph_json,
    measurements ->> 'ph' AS ph_text
FROM quality_checks
WHERE measurements ? 'ph'
ORDER BY quality_check_id;


-- ============================================================
-- 4. CONVERT JSONB VALUE TO NUMERIC
-- ============================================================

SELECT
    quality_check_id,
    (measurements ->> 'ph')::numeric AS ph
FROM quality_checks
WHERE measurements ? 'ph'
ORDER BY quality_check_id;


-- ============================================================
-- 5. FILTER BY NUMERIC JSONB VALUE
-- ============================================================

SELECT
    quality_check_id,
    result,
    (measurements ->> 'ph')::numeric AS ph
FROM quality_checks
WHERE measurements ? 'ph'
  AND (measurements ->> 'ph')::numeric > 5.0
ORDER BY quality_check_id;


-- ============================================================
-- 6. FILTER BY TEXT VALUE
-- ============================================================

SELECT
    quality_check_id,
    measurements ->> 'appearance' AS appearance
FROM quality_checks
WHERE measurements ->> 'appearance' = 'transparent'
ORDER BY quality_check_id;


-- ============================================================
-- 7. JSONB CONTAINMENT WITH @>
-- ============================================================

SELECT
    quality_check_id,
    measurements
FROM quality_checks
WHERE measurements @> '{"appearance": "transparent"}'::jsonb
ORDER BY quality_check_id;


-- ============================================================
-- 8. CHECK KEY EXISTENCE WITH ?
-- ============================================================

SELECT
    quality_check_id,
    measurements
FROM quality_checks
WHERE measurements ? 'density_g_cm3'
ORDER BY quality_check_id;


-- ============================================================
-- 9. READ NESTED JSONB VALUE
-- ============================================================

SELECT
    quality_check_id,
    measurements #>> '{device,code}' AS device_code,
    measurements #>> '{device,calibrated}' AS calibrated
FROM quality_checks
WHERE measurements ? 'device'
ORDER BY quality_check_id;


-- ============================================================
-- 10. ADD OR UPDATE JSONB KEY
-- ============================================================

-- Если ключ отсутствует, jsonb_set добавит его.
-- Если ключ уже существует, его значение будет заменено.

UPDATE quality_checks qc
SET measurements = jsonb_set(
    qc.measurements,
    '{odor}',
    '"normal"'::jsonb
)
FROM production_batches pb
WHERE qc.batch_id = pb.batch_id
  AND pb.batch_number = 'BATCH-004'
  AND qc.checked_at = TIMESTAMP '2026-08-05 17:00';


-- ============================================================
-- 11. REMOVE JSONB KEY
-- ============================================================

UPDATE quality_checks qc
SET measurements = qc.measurements - 'odor'
FROM production_batches pb
WHERE qc.batch_id = pb.batch_id
  AND pb.batch_number = 'BATCH-004'
  AND qc.checked_at = TIMESTAMP '2026-08-05 17:00';
