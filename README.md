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

1. Products
2. Materials
3. Specifications
4. SpecificationItems
5. ProductionOrders
6. ProductionBatches
7. ProductionLines
8. Operations
9. BatchOperations
10. Employees
11. Shifts
12. MaterialUsage
13. QualityChecks
14. DefectTypes
15. Defects

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
