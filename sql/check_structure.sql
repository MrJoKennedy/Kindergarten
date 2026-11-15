-- Проверка структуры созданной базы данных (схема center)
SET search_path TO center;

-- 1. Таблицы (ожидается 17)
SELECT table_name
  FROM information_schema.tables
 WHERE table_schema = 'center' AND table_type = 'BASE TABLE'
 ORDER BY table_name;

-- 2. Столбцы: тип, домен, допустимость NULL, значение по умолчанию, identity
SELECT table_name, ordinal_position AS n, column_name, data_type, domain_name,
       is_nullable, column_default, is_identity
  FROM information_schema.columns
 WHERE table_schema = 'center'
 ORDER BY table_name, ordinal_position;

-- 3. Домены (ожидается 8)
SELECT domain_name, data_type, character_maximum_length, numeric_precision, numeric_scale
  FROM information_schema.domains
 WHERE domain_schema = 'center'
 ORDER BY domain_name;

-- 4. Ограничения таблиц: p — PRIMARY KEY, f — FOREIGN KEY, u — UNIQUE, c — CHECK
SELECT conrelid::regclass AS table_name, conname, contype, pg_get_constraintdef(oid) AS definition
  FROM pg_constraint
 WHERE connamespace = 'center'::regnamespace AND conrelid <> 0 AND contype <> 'n'
 ORDER BY conrelid::regclass::text, contype, conname;

-- 5. Количество ограничений по видам (ожидается: c = 8, f = 19, p = 17, u = 6;
--    ограничения NOT NULL (contype = 'n', в PostgreSQL 18 хранятся в pg_constraint) исключены)
SELECT contype, count(*) AS total
  FROM pg_constraint
 WHERE connamespace = 'center'::regnamespace AND conrelid <> 0 AND contype <> 'n'
 GROUP BY contype
 ORDER BY contype;

-- 6. Индексы
SELECT tablename, indexname, indexdef
  FROM pg_indexes
 WHERE schemaname = 'center'
 ORDER BY tablename, indexname;

-- 7. Триггеры (включая отложенные ограничивающие триггеры)
SELECT tgrelid::regclass AS table_name, tgname AS trigger_name, tgdeferrable AS deferrable
  FROM pg_trigger
 WHERE NOT tgisinternal
   AND tgrelid IN (SELECT oid FROM pg_class WHERE relnamespace = 'center'::regnamespace)
 ORDER BY tgrelid::regclass::text, tgname;

-- 8. Представления (ожидается 3)
SELECT table_name AS view_name
  FROM information_schema.views
 WHERE table_schema = 'center'
 ORDER BY table_name;
