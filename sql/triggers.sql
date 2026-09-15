-- ============================================================
-- 1. Контроль суммарного планового количества партий заказа
-- ============================================================

CREATE OR REPLACE FUNCTION check_batch_planned_quantity()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    order_planned_quantity numeric(18,3);
    other_batches_quantity numeric(18,3);
BEGIN
    -- Получаем плановое количество заказа.
    -- FOR UPDATE блокирует строку заказа на время проверки,
    -- чтобы параллельные операции не нарушили правило.
    SELECT planned_quantity
    INTO order_planned_quantity
    FROM production_orders
    WHERE production_order_id = NEW.production_order_id
    FOR UPDATE;

    -- При INSERT считаем все уже существующие партии заказа.
    IF TG_OP = 'INSERT' THEN
        SELECT COALESCE(SUM(planned_quantity), 0)
        INTO other_batches_quantity
        FROM production_batches
        WHERE production_order_id = NEW.production_order_id;

    -- При UPDATE исключаем из суммы изменяемую партию,
    -- так как её новое значение будет добавлено отдельно.
    ELSE
        SELECT COALESCE(SUM(planned_quantity), 0)
        INTO other_batches_quantity
        FROM production_batches
        WHERE production_order_id = NEW.production_order_id
          AND batch_id <> OLD.batch_id;
    END IF;

    IF other_batches_quantity + NEW.planned_quantity
       > order_planned_quantity THEN

        RAISE EXCEPTION
            'Суммарное плановое количество партий (%) превышает плановое количество заказа (%)',
            other_batches_quantity + NEW.planned_quantity,
            order_planned_quantity
            USING ERRCODE = '23514';
    END IF;

    RETURN NEW;
END;
$$;


CREATE TRIGGER trg_check_batch_planned_quantity
BEFORE INSERT OR UPDATE OF production_order_id, planned_quantity
ON production_batches
FOR EACH ROW
EXECUTE FUNCTION check_batch_planned_quantity();


-- ============================================================
-- 2. Запрет уменьшения заказа ниже суммы его партий
-- ============================================================

CREATE OR REPLACE FUNCTION check_order_planned_quantity()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    batches_quantity numeric(18,3);
BEGIN
    SELECT COALESCE(SUM(planned_quantity), 0)
    INTO batches_quantity
    FROM production_batches
    WHERE production_order_id = NEW.production_order_id;

    IF NEW.planned_quantity < batches_quantity THEN

        RAISE EXCEPTION
            'Плановое количество заказа (%) меньше суммарного количества его партий (%)',
            NEW.planned_quantity,
            batches_quantity
            USING ERRCODE = '23514';
    END IF;

    RETURN NEW;
END;
$$;


CREATE TRIGGER trg_check_order_planned_quantity
BEFORE UPDATE OF planned_quantity
ON production_orders
FOR EACH ROW
EXECUTE FUNCTION check_order_planned_quantity();

-- ============================================================
-- 3. Запрет дефектов для успешной проверки качества
-- ============================================================

CREATE OR REPLACE FUNCTION check_defect_quality_result()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    quality_result quality_check_result;
BEGIN
    SELECT result
    INTO quality_result
    FROM quality_checks
    WHERE quality_check_id = NEW.quality_check_id
    FOR UPDATE;

    IF quality_result = 'Passed' THEN
        RAISE EXCEPTION
            'Нельзя зарегистрировать дефект для проверки качества со статусом Passed'
            USING ERRCODE = '23514';
    END IF;

    RETURN NEW;
END;
$$;


CREATE TRIGGER trg_check_defect_quality_result
BEFORE INSERT OR UPDATE OF quality_check_id
ON defects
FOR EACH ROW
EXECUTE FUNCTION check_defect_quality_result();


-- ============================================================
-- 4. Запрет Passed при наличии дефектов
-- ============================================================

CREATE OR REPLACE FUNCTION check_quality_passed_without_defects()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.result = 'Passed'
       AND EXISTS (
           SELECT 1
           FROM defects
           WHERE quality_check_id = NEW.quality_check_id
       )
    THEN
        RAISE EXCEPTION
            'Нельзя установить Passed: у проверки качества зарегистрированы дефекты'
            USING ERRCODE = '23514';
    END IF;

    RETURN NEW;
END;
$$;


CREATE TRIGGER trg_check_quality_passed_without_defects
BEFORE UPDATE OF result
ON quality_checks
FOR EACH ROW
EXECUTE FUNCTION check_quality_passed_without_defects();


-- ============================================================
-- 5. Проверка времени контроля качества относительно партии
-- ============================================================

CREATE OR REPLACE FUNCTION check_quality_check_batch_period()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    batch_started_at timestamp;
    batch_completed_at timestamp;
BEGIN
    SELECT started_at, completed_at
    INTO batch_started_at, batch_completed_at
    FROM production_batches
    WHERE batch_id = NEW.batch_id
    FOR UPDATE;

    IF batch_started_at IS NULL THEN
        RAISE EXCEPTION
            'Нельзя зарегистрировать проверку качества: производственная партия ещё не запущена'
            USING ERRCODE = '23514';
    END IF;

    IF NEW.checked_at < batch_started_at THEN
        RAISE EXCEPTION
            'Время проверки качества (%) раньше времени запуска партии (%)',
            NEW.checked_at,
            batch_started_at
            USING ERRCODE = '23514';
    END IF;

    IF batch_completed_at IS NOT NULL
       AND NEW.checked_at > batch_completed_at THEN
        RAISE EXCEPTION
            'Время проверки качества (%) позже времени завершения партии (%)',
            NEW.checked_at,
            batch_completed_at
            USING ERRCODE = '23514';
    END IF;

    RETURN NEW;
END;
$$;


CREATE TRIGGER trg_check_quality_check_batch_period
BEFORE INSERT OR UPDATE OF batch_id, checked_at
ON quality_checks
FOR EACH ROW
EXECUTE FUNCTION check_quality_check_batch_period();


-- ============================================================
-- 6. Контроль периода партии при наличии проверок качества
-- ============================================================

CREATE OR REPLACE FUNCTION check_batch_quality_check_period()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.started_at IS NULL
       AND EXISTS (
           SELECT 1
           FROM quality_checks
           WHERE batch_id = NEW.batch_id
       )
    THEN
        RAISE EXCEPTION
            'Нельзя удалить время запуска партии: для неё уже существуют проверки качества'
            USING ERRCODE = '23514';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM quality_checks
        WHERE batch_id = NEW.batch_id
          AND checked_at < NEW.started_at
    )
    THEN
        RAISE EXCEPTION
            'Нельзя изменить время запуска партии: существуют более ранние проверки качества'
            USING ERRCODE = '23514';
    END IF;

    IF NEW.completed_at IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM quality_checks
           WHERE batch_id = NEW.batch_id
             AND checked_at > NEW.completed_at
       )
    THEN
        RAISE EXCEPTION
            'Нельзя изменить время завершения партии: существуют более поздние проверки качества'
            USING ERRCODE = '23514';
    END IF;

    RETURN NEW;
END;
$$;


CREATE TRIGGER trg_check_batch_quality_check_period
BEFORE UPDATE OF started_at, completed_at
ON production_batches
FOR EACH ROW
EXECUTE FUNCTION check_batch_quality_check_period();

