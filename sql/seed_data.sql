-- Небольшой набор тестовых данных для демонстрации работы ограничений
-- Все вставки выполняются в одной транзакции: отложенные триггеры проверяют
-- наличие связей (родитель, направление) при COMMIT
SET search_path TO center;

BEGIN;

INSERT INTO direction (name) VALUES ('Развитие речи'), ('Математика'), ('Английский язык');

INSERT INTO program (program_code, name, description, min_age, max_age, lesson_minutes, lessons_count, price, max_children)
VALUES ('RR-01', 'Говорунчики', 'Занятия по развитию речи', 3.0, 5.0, 30, 24, 240.00, 8),
       ('MT-01', 'Весёлая математика', NULL, 4.0, 6.0, 30, 32, 320.00, 10);

INSERT INTO program_direction (program_code, direction_no)
SELECT 'RR-01', direction_no FROM direction WHERE name = 'Развитие речи';
INSERT INTO program_direction (program_code, direction_no)
SELECT 'MT-01', direction_no FROM direction WHERE name = 'Математика';

INSERT INTO employee (last_name, first_name, patronymic, phone)
VALUES ('Иванова', 'Мария', 'Петровна', '+375 29 111-22-33'),
       ('Сидорова', 'Анна', 'Ивановна', '+375 29 444-55-66');

INSERT INTO teacher (employee_no, education, experience_years)
SELECT employee_no, 'Высшее педагогическое', 7 FROM employee WHERE last_name = 'Иванова';

INSERT INTO administrator (employee_no, job_title)
SELECT employee_no, 'Менеджер по работе с клиентами' FROM employee WHERE last_name = 'Сидорова';

UPDATE employee
   SET manager_no = (SELECT employee_no FROM employee WHERE last_name = 'Сидорова')
 WHERE last_name = 'Иванова';

INSERT INTO teacher_direction (employee_no, direction_no)
SELECT t.employee_no, d.direction_no
  FROM teacher t CROSS JOIN direction d
 WHERE d.name IN ('Развитие речи', 'Математика');

INSERT INTO study_group (program_code, teacher_no, start_date, end_date, seats)
SELECT 'RR-01', employee_no, DATE '2026-09-01', DATE '2027-05-31', 8 FROM teacher;

INSERT INTO schedule (group_no, weekday, start_time, room_no)
SELECT group_no, 2, TIME '10:00', '101' FROM study_group;

INSERT INTO parent (last_name, first_name, patronymic, address, mobile_phone)
VALUES ('Петров', 'Олег', 'Иванович', 'г. Гродно, ул. Советская, 1', '+375 29 777-88-99');

INSERT INTO child (last_name, first_name, patronymic, birth_date, gender, admission_date)
VALUES ('Петров', 'Артём', 'Олегович', DATE '2022-03-15', 'М', DATE '2026-09-01');

INSERT INTO child_parent (card_no, parent_no, relation)
SELECT c.card_no, p.parent_no, 'отец' FROM child c CROSS JOIN parent p;

INSERT INTO health_record (card_no, allergies)
SELECT card_no, 'Аллергия на цитрусовые' FROM child;

INSERT INTO enrollment (card_no, group_no, enroll_date)
SELECT c.card_no, g.group_no, DATE '2026-09-01' FROM child c CROSS JOIN study_group g;

INSERT INTO payment (enrollment_no, amount, payment_date)
SELECT enrollment_no, 120.00, DATE '2026-09-01' FROM enrollment;

INSERT INTO lesson (group_no, lesson_date, start_time)
SELECT group_no, DATE '2026-09-08', TIME '10:00' FROM study_group;

INSERT INTO attendance (enrollment_no, lesson_no, is_present)
SELECT e.enrollment_no, l.lesson_no, true
  FROM enrollment e JOIN lesson l ON l.group_no = e.group_no;

COMMIT;

-- Проверка: должна быть 1 запись, занято 1 место, долг 120.00
SELECT * FROM v_group_load;
SELECT * FROM v_enrollment_balance;
