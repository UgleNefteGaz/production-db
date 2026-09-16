-- ============================================================
-- ПРИМЕРЫ SQL-ЗАПРОСОВ
-- ============================================================


-- ============================================================
-- 1. ПОИСК С ИСПОЛЬЗОВАНИЕМ РЕГУЛЯРНОГО ВЫРАЖЕНИЯ
-- ============================================================

-- Задача:
-- Найти производственные заказы, номер которых строго
-- соответствует формату:
--
-- PO-YYYY-NNN
--
-- Например:
-- PO-2026-001
-- PO-2026-010
--
-- При этом номера TEST-ORDER-01 и DEV-2026-001
-- в результат попадать не должны.
--
-- Регулярное выражение:
--
-- ^          начало строки
-- PO-        обязательный префикс
-- [0-9]{4}  ровно четыре цифры
-- -          дефис
-- [0-9]{3}  ровно три цифры
-- $          конец строки

SELECT
    production_order_id,
    order_number,
    status,
    planned_quantity
FROM production_orders
WHERE order_number ~ '^PO-[0-9]{4}-[0-9]{3}$'
ORDER BY order_number;


-- ============================================================
-- 2. INNER JOIN И LEFT JOIN
-- ============================================================

-- В базе специально существуют:
--
-- CREAM50:
-- продукт без спецификации.
--
-- BALM250:
-- продукт со спецификацией, но без производственного заказа.
--
-- Также имеются отдельные версии спецификаций,
-- по которым производственные заказы не создавались.


-- ------------------------------------------------------------
-- 2.1. INNER JOIN -> LEFT JOIN
-- ------------------------------------------------------------

-- Сначала INNER JOIN оставляет только продукты,
-- для которых существует спецификация.
--
-- Поэтому CREAM50 исчезает.
--
-- Затем LEFT JOIN сохраняет спецификации даже тогда,
-- когда для них не существует производственного заказа.
--
-- Поэтому BALM250 и другие спецификации без заказов
-- остаются в результате, но поля production_orders
-- содержат NULL.

SELECT
    p.article,
    p.name AS product_name,
    s.version,
    po.order_number,
    po.status
FROM products AS p
INNER JOIN specifications AS s
    ON s.product_id = p.product_id
LEFT JOIN production_orders AS po
    ON po.specification_id = s.specification_id
ORDER BY
    p.article,
    s.version,
    po.order_number;


-- ------------------------------------------------------------
-- 2.2. LEFT JOIN -> INNER JOIN
-- ------------------------------------------------------------

-- LEFT JOIN сначала сохраняет даже продукты,
-- у которых нет спецификации.
--
-- Но следующий INNER JOIN требует существования
-- соответствующего производственного заказа.
--
-- Поэтому строки без заказа в конечном результате исчезают.
--
-- В результате не будет:
-- - CREAM50, у которого нет спецификации;
-- - BALM250, у которого нет заказа;
-- - отдельных версий спецификаций без заказов.
--
-- Порядок и сочетание INNER JOIN и LEFT JOIN влияет
-- на логический результат, потому что LEFT JOIN сохраняет
-- строки левой таблицы даже при отсутствии совпадения,
-- а INNER JOIN оставляет только совпавшие строки.

SELECT
    p.article,
    p.name AS product_name,
    s.version,
    po.order_number,
    po.status
FROM products AS p
LEFT JOIN specifications AS s
    ON s.product_id = p.product_id
INNER JOIN production_orders AS po
    ON po.specification_id = s.specification_id
ORDER BY
    p.article,
    s.version,
    po.order_number;


-- ============================================================
-- 3. INSERT С ВЫВОДОМ ДОБАВЛЕННОЙ СТРОКИ
-- ============================================================

-- PostgreSQL позволяет использовать RETURNING,
-- чтобы сразу получить данные добавленной строки.
--
-- Это особенно удобно для автоматически создаваемых
-- значений, например product_id.
--
-- Используется транзакция с ROLLBACK,
-- поэтому тестовая строка после выполнения не останется в БД.

BEGIN;

INSERT INTO products
(
    name,
    article,
    unit,
    description,
    is_active
)
VALUES
(
    'Демонстрационный продукт',
    'DEMO-PROD-001',
    'шт',
    'Продукт для демонстрации INSERT RETURNING',
    true
)
RETURNING
    product_id,
    article,
    name,
    unit,
    description,
    is_active;

ROLLBACK;


-- ============================================================
-- 4. UPDATE ... FROM
-- ============================================================

-- Задача:
-- Перевести производственный заказ в статус Completed,
-- если все связанные с ним партии уже завершены.
--
-- В тестовых данных специально существует заказ
-- PO-2026-006:
--
-- сам заказ -> InProgress
-- BATCH-009 -> Completed
-- BATCH-010 -> Completed
--
-- Подзапрос completed_orders определяет заказы,
-- для которых все партии имеют статус Completed.
--
-- BOOL_AND возвращает TRUE только тогда,
-- когда выражение status = 'Completed'
-- истинно для всех строк группы.
--
-- UPDATE FROM использует результат подзапроса
-- для определения строк таблицы production_orders,
-- которые необходимо обновить.
--
-- ROLLBACK возвращает заказ в исходное состояние.

BEGIN;

UPDATE production_orders AS po
SET status = 'Completed'
FROM (
    SELECT
        production_order_id
    FROM production_batches
    GROUP BY production_order_id
    HAVING COUNT(*) > 0
       AND BOOL_AND(status = 'Completed')
) AS completed_orders
WHERE completed_orders.production_order_id = po.production_order_id
  AND po.status <> 'Completed'
RETURNING
    po.production_order_id,
    po.order_number,
    po.status;

ROLLBACK;


-- ============================================================
-- 5. DELETE ... USING
-- ============================================================

-- Задача:
-- Удалить дефекты, относящиеся к тестовым партиям.
--
-- Для определения нужных строк требуется пройти связь:
--
-- defects
--     -> quality_checks
--         -> production_batches
--
-- В PostgreSQL при DELETE дополнительные таблицы
-- можно подключить с помощью USING.
--
-- В seed.sql специально существует:
--
-- TEST-BATCH-001
--
-- с тестовым дефектом.
--
-- RETURNING показывает удалённые строки.
--
-- ROLLBACK восстанавливает удалённый дефект после теста.

BEGIN;

DELETE FROM defects AS d
USING
    quality_checks AS qc,
    production_batches AS pb
WHERE d.quality_check_id = qc.quality_check_id
  AND qc.batch_id = pb.batch_id
  AND pb.batch_number LIKE 'TEST-%'
RETURNING
    d.defect_id,
    d.quality_check_id,
    d.defect_type_id,
    d.quantity,
    d.description;

ROLLBACK;


-- ============================================================
-- 6. COPY
-- ============================================================

-- COPY позволяет быстро экспортировать или импортировать
-- большие объёмы данных.
--
-- В данном примере производственные заказы вместе
-- с информацией о продукте экспортируются в CSV.
--
-- PostgreSQL работает внутри Docker-контейнера,
-- поэтому файл /tmp/production_orders.csv
-- создаётся внутри контейнера PostgreSQL.

COPY (
    SELECT
        po.production_order_id,
        po.order_number,
        p.article,
        p.name AS product_name,
        po.planned_quantity,
        po.status
    FROM production_orders AS po
    INNER JOIN specifications AS s
        ON s.specification_id = po.specification_id
    INNER JOIN products AS p
        ON p.product_id = s.product_id
    ORDER BY po.order_number
)
TO '/tmp/production_orders.csv'
WITH (
    FORMAT CSV,
    HEADER,
    ENCODING 'UTF8'
);


-- Файл можно скопировать из Docker-контейнера
-- в текущую директорию WSL командой:
--
-- docker cp \
--   production-db-postgres:/tmp/production_orders.csv \
--   ./production_orders.csv
--
-- Проверить содержимое:
--
-- head production_orders.csv
--
-- В psql также существует команда \copy.
-- В отличие от серверной COPY, она работает
-- с файловой системой клиента, на котором запущен psql.
--
-- Пример:
--
-- \copy products TO './products.csv' CSV HEADER

-- Важно:
-- COPY TO не перезаписывает существующий файл.
-- Перед повторным выполнением необходимо удалить файл:
--
-- docker exec production-db-postgres \
--   rm -f /tmp/production_orders.csv
