-- Примеры DDL-команд (изменение структуры). Выполняются в схеме center.
-- Каждый блок сопровождается командой отмены, чтобы базу можно было вернуть в исходное состояние.
SET search_path TO center;

-- 1. Добавить столбец и ограничение к существующей таблице
ALTER TABLE child ADD COLUMN email varchar(100);
ALTER TABLE child ADD CONSTRAINT ck_child_email CHECK (email LIKE '%@%');
-- отмена
ALTER TABLE child DROP CONSTRAINT ck_child_email;
ALTER TABLE child DROP COLUMN email;

-- 2. Изменить значение по умолчанию и тип столбца
ALTER TABLE payment ALTER COLUMN payment_date SET DEFAULT CURRENT_DATE;
ALTER TABLE payment ALTER COLUMN payment_date DROP DEFAULT;
ALTER TABLE payment ALTER COLUMN payment_date SET DEFAULT CURRENT_DATE;
ALTER TABLE parent ALTER COLUMN address TYPE varchar(300);
-- отмена
ALTER TABLE parent ALTER COLUMN address TYPE varchar(200);

-- 3. Запретить или разрешить NULL
ALTER TABLE program ALTER COLUMN description SET NOT NULL;
-- отмена
ALTER TABLE program ALTER COLUMN description DROP NOT NULL;

-- 4. Переименовать столбец и таблицу
ALTER TABLE direction RENAME COLUMN name TO title;
ALTER TABLE direction RENAME COLUMN title TO name;

-- 5. Добавить и удалить внешний ключ с каскадным правилом
ALTER TABLE payment DROP CONSTRAINT fk_payment_enrollment;
ALTER TABLE payment
    ADD CONSTRAINT fk_payment_enrollment FOREIGN KEY (enrollment_no)
    REFERENCES enrollment (enrollment_no) ON DELETE CASCADE;

-- 6. Создать и удалить индекс
CREATE INDEX idx_child_birth_date ON child (birth_date);
DROP INDEX idx_child_birth_date;

-- 7. Изменить домен
ALTER DOMAIN d_phone DROP CONSTRAINT ck_d_phone;
ALTER DOMAIN d_phone ADD CONSTRAINT ck_d_phone CHECK (VALUE ~ '^[0-9+() -]{5,20}$');

-- 8. Временная таблица и её удаление; очистка таблицы
CREATE TEMP TABLE tmp_payment AS SELECT * FROM payment;
TRUNCATE TABLE tmp_payment;
DROP TABLE tmp_payment;
