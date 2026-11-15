-- Проверка ограничений целостности.
-- Выполняйте запросы ПО ОДНОМУ после заполнения базы (fill_data.sql или seed_data.sql):
-- каждый из них должен завершиться ошибкой (указана ожидаемая причина).
SET search_path TO center;

-- 1. Доменная целостность: отрицательная сумма платежа (CHECK ck_payment_amount)
INSERT INTO payment (enrollment_no, amount)
VALUES ((SELECT min(enrollment_no) FROM enrollment), -5);

-- 2. Доменная целостность: недопустимый пол (домен d_gender)
UPDATE child SET gender = 'X' WHERE card_no = (SELECT min(card_no) FROM child);

-- 3. Сущностная целостность: повтор названия направления (UNIQUE uq_direction_name)
INSERT INTO direction (name) SELECT name FROM direction ORDER BY direction_no LIMIT 1;

-- 4. Сущностная / пользовательская целостность: тот же кабинет в то же время
--    (UNIQUE uq_schedule_room или триггер trg_schedule_overlap)
INSERT INTO study_group (program_code, teacher_no, start_date, end_date, seats)
SELECT 'MT-01', (SELECT min(employee_no) FROM teacher), DATE '2026-09-01', DATE '2027-05-31', 10;
INSERT INTO schedule (group_no, weekday, start_time, room_no)
SELECT (SELECT max(group_no) FROM study_group), weekday, start_time, room_no
  FROM schedule ORDER BY group_no LIMIT 1;

-- 5. Ссылочная целостность: удаление направления, на которое есть ссылки (RESTRICT)
DELETE FROM direction WHERE direction_no = (SELECT min(direction_no) FROM program_direction);

-- 6. Доменная целостность: возраст при зачислении в центр меньше 1,5 года (CHECK ck_child_age)
INSERT INTO child (last_name, first_name, patronymic, birth_date, gender, admission_date)
VALUES ('Сидоров', 'Иван', 'Петрович', DATE '2025-06-01', 'М', DATE '2026-09-01');

-- 7. Пользовательская целостность: удаление ребёнка с задолженностью (триггер trg_child_delete)
DELETE FROM child
 WHERE card_no = (SELECT card_no FROM v_enrollment_balance WHERE debt > 0 ORDER BY enrollment_no LIMIT 1);

-- 8. Пользовательская целостность: число мест больше предела программы (триггер trg_group_rules)
UPDATE study_group SET seats = 20 WHERE group_no = (SELECT min(group_no) FROM study_group);
