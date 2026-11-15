-- Дополнительные индексы
SET search_path TO center;

-- ===== Индексы (ключи и UNIQUE индексируются автоматически) =====
CREATE INDEX idx_program_name ON program (name);  -- поиск программы по названию
CREATE INDEX idx_program_direction_dir ON program_direction (direction_no);  -- программы направления (обратный поиск по связи M:N)
CREATE INDEX idx_employee_name ON employee (last_name, first_name);  -- поиск сотрудника по фамилии и имени
CREATE INDEX idx_employee_manager ON employee (manager_no);  -- подчинённые сотрудника
CREATE INDEX idx_teacher_direction_dir ON teacher_direction (direction_no);  -- педагоги направления
CREATE INDEX idx_study_group_program ON study_group (program_code);  -- группы программы, подсчёт спроса
CREATE INDEX idx_study_group_teacher ON study_group (teacher_no);  -- группы педагога
CREATE INDEX idx_lesson_date ON lesson (lesson_date);  -- занятия за период, отчёты руководства
CREATE INDEX idx_child_name ON child (last_name, first_name);  -- поиск ребёнка по фамилии и имени
CREATE INDEX idx_parent_name ON parent (last_name, first_name);  -- поиск родителя по фамилии и имени
CREATE INDEX idx_child_parent_parent ON child_parent (parent_no);  -- дети родителя
CREATE INDEX idx_enrollment_group ON enrollment (group_no);  -- состав группы, подсчёт занятых мест
CREATE INDEX idx_enrollment_active ON enrollment (card_no) WHERE leave_date IS NULL;  -- действующие зачисления ребёнка (частичный индекс для проверки лимита)
CREATE INDEX idx_payment_enrollment ON payment (enrollment_no);  -- сумма оплат по зачислению, задолженность
CREATE INDEX idx_payment_date ON payment (payment_date);  -- платежи за период
CREATE INDEX idx_attendance_lesson ON attendance (lesson_no);  -- отметки занятия
