# Production DB

Учебный проект реляционной базы данных для учета и контроля производственных процессов предприятия.

## Назначение проекта

База данных предназначена для моделирования производственного процесса предприятия и позволяет учитывать:

- выпускаемую продукцию;
- сырье и материалы;
- технологические спецификации;
- производственные заказы;
- производственные партии;
- технологические операции;
- производственные линии;
- сотрудников и производственные смены;
- фактический расход материалов;
- контроль качества;
- производственный брак.

## СУБД

PostgreSQL 18

## Модель данных

База данных содержит 15 основных сущностей:

1. products
2. materials
3. specifications
4. specification_items
5. production_orders
6. production_batches
7. production_lines
8. operations
9. batch_operations
10. employees
11. shifts
12. material_usage
13. quality_checks
14. defect_types
15. defects

ER-модель хранится в формате DBML и может быть визуализирована в dbdiagram.io.

## Структура проекта

```text
production-db/
├── README.md
├── db/
│   ├── schema.dbml
│   ├── schema.sql
│   └── seed.sql
├── docs/
│   ├── requirements.md
│   ├── constraints.md
│   ├── er-diagram.md
│   ├── data-dictionary.md
│   ├── business-tasks.md
│   └── worklog.md
├── sql/
│   ├── queries.sql
│   ├── views.sql
│   ├── functions.sql
│   └── triggers.sql
└── images/
