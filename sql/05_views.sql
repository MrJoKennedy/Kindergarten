-- Представления для производных данных
SET search_path TO center;


-- Возраст ребёнка
CREATE VIEW v_child_age AS
SELECT card_no, last_name, first_name, patronymic, birth_date,
       EXTRACT(YEAR FROM age(CURRENT_DATE, birth_date))::integer AS age_years
  FROM child;

-- Занятые и свободные места в группах
CREATE VIEW v_group_load AS
SELECT g.group_no, g.program_code, g.seats,
       count(e.enrollment_no) AS occupied,
       g.seats - count(e.enrollment_no) AS free_seats
  FROM study_group g
  LEFT JOIN enrollment e ON e.group_no = g.group_no AND e.leave_date IS NULL
 GROUP BY g.group_no;

-- Оплаты и задолженность по зачислениям
CREATE VIEW v_enrollment_balance AS
SELECT e.enrollment_no, e.card_no, e.group_no, p.price,
       COALESCE(sum(pay.amount), 0) AS paid,
       p.price - COALESCE(sum(pay.amount), 0) AS debt
  FROM enrollment e
  JOIN study_group g ON g.group_no = e.group_no
  JOIN program p ON p.program_code = g.program_code
  LEFT JOIN payment pay ON pay.enrollment_no = e.enrollment_no
 GROUP BY e.enrollment_no, p.price;
