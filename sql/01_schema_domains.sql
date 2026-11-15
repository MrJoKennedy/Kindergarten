-- Физическая модель БД «Дошкольный центр развития ребёнка»
-- СУБД: PostgreSQL 18 (скрипт совместим с PostgreSQL 15 и новее)
-- Кодировка базы данных: UTF8

-- CREATE DATABASE kindergarten_center ENCODING 'UTF8' TEMPLATE template0;

CREATE SCHEMA IF NOT EXISTS center;
SET search_path TO center;

-- ===== Домены =====
CREATE DOMAIN d_phone AS varchar(20)
    CONSTRAINT ck_d_phone CHECK (VALUE ~ '^[0-9+() -]{5,20}$');  -- телефон: цифры, «+», «-», пробел, скобки; 5–20 символов
CREATE DOMAIN d_age AS numeric(2,1)
    CONSTRAINT ck_d_age CHECK (VALUE BETWEEN 1.5 AND 7.0);  -- возраст в годах: от 1,5 до 7,0
CREATE DOMAIN d_gender AS char(1)
    CONSTRAINT ck_d_gender CHECK (VALUE IN ('М','Ж'));  -- пол: М или Ж
CREATE DOMAIN d_weekday AS smallint
    CONSTRAINT ck_d_weekday CHECK (VALUE BETWEEN 1 AND 7);  -- день недели: 1 (понедельник) … 7 (воскресенье)
CREATE DOMAIN d_relation AS varchar(20)
    CONSTRAINT ck_d_relation CHECK (VALUE IN ('мать','отец','бабушка','дедушка','опекун','другое'));  -- степень родства
CREATE DOMAIN d_count AS integer
    CONSTRAINT ck_d_count CHECK (VALUE > 0);  -- положительное целое число
CREATE DOMAIN d_years AS integer
    CONSTRAINT ck_d_years CHECK (VALUE >= 0);  -- неотрицательное целое число (стаж, лет)
CREATE DOMAIN d_money AS numeric(10,2)
    CONSTRAINT ck_d_money CHECK (VALUE >= 0);  -- денежная сумма, не меньше 0

