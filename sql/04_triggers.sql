-- Триггерные функции и триггеры (пользовательская целостность)
SET search_path TO center;


-- Зачисление: возраст по программе, не более 4 действующих групп,
-- одна действующая группа на программу, число мест
CREATE FUNCTION fn_enrollment_rules() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    v_birth   date;
    v_program varchar(20);
    v_seats   integer;
    v_min     numeric;
    v_max     numeric;
    v_months  integer;
BEGIN
    SELECT birth_date INTO v_birth FROM child WHERE card_no = NEW.card_no;
    SELECT g.program_code, g.seats, p.min_age, p.max_age
      INTO v_program, v_seats, v_min, v_max
      FROM study_group g
      JOIN program p ON p.program_code = g.program_code
     WHERE g.group_no = NEW.group_no;

    v_months := (EXTRACT(YEAR FROM age(NEW.enroll_date, v_birth)) * 12
               + EXTRACT(MONTH FROM age(NEW.enroll_date, v_birth)))::integer;
    IF v_months < round(v_min * 12) OR v_months > round(v_max * 12) THEN
        RAISE EXCEPTION 'Возраст ребёнка (% мес.) не подходит для программы группы %', v_months, NEW.group_no
            USING ERRCODE = '23514';
    END IF;

    IF NEW.leave_date IS NULL THEN
        IF (SELECT count(*) FROM enrollment
             WHERE card_no = NEW.card_no AND leave_date IS NULL
               AND enrollment_no IS DISTINCT FROM NEW.enrollment_no) >= 4 THEN
            RAISE EXCEPTION 'Ребёнок уже занимается в 4 группах' USING ERRCODE = '23514';
        END IF;
        IF EXISTS (SELECT 1 FROM enrollment e
                     JOIN study_group g ON g.group_no = e.group_no
                    WHERE e.card_no = NEW.card_no AND e.leave_date IS NULL
                      AND g.program_code = v_program
                      AND e.enrollment_no IS DISTINCT FROM NEW.enrollment_no) THEN
            RAISE EXCEPTION 'Ребёнок уже занимается по программе %', v_program USING ERRCODE = '23514';
        END IF;
        IF (SELECT count(*) FROM enrollment
             WHERE group_no = NEW.group_no AND leave_date IS NULL
               AND enrollment_no IS DISTINCT FROM NEW.enrollment_no) >= v_seats THEN
            RAISE EXCEPTION 'В группе % нет свободных мест', NEW.group_no USING ERRCODE = '23514';
        END IF;
    END IF;
    RETURN NEW;
END $$;

CREATE TRIGGER trg_enrollment_rules
    BEFORE INSERT OR UPDATE ON enrollment
    FOR EACH ROW EXECUTE FUNCTION fn_enrollment_rules();

-- Группа: число мест не больше предела программы и не меньше числа занятых мест
CREATE FUNCTION fn_group_rules() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    v_max integer;
BEGIN
    SELECT max_children INTO v_max FROM program WHERE program_code = NEW.program_code;
    IF NEW.seats > v_max THEN
        RAISE EXCEPTION 'Число мест (%) больше предела программы (%)', NEW.seats, v_max USING ERRCODE = '23514';
    END IF;
    IF TG_OP = 'UPDATE' AND
       (SELECT count(*) FROM enrollment WHERE group_no = NEW.group_no AND leave_date IS NULL) > NEW.seats THEN
        RAISE EXCEPTION 'Число мест меньше числа занятых мест' USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END $$;

CREATE TRIGGER trg_group_rules
    BEFORE INSERT OR UPDATE ON study_group
    FOR EACH ROW EXECUTE FUNCTION fn_group_rules();

-- Посещаемость: зачисление и занятие должны относиться к одной группе
CREATE FUNCTION fn_attendance_rules() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF (SELECT group_no FROM enrollment WHERE enrollment_no = NEW.enrollment_no)
       IS DISTINCT FROM (SELECT group_no FROM lesson WHERE lesson_no = NEW.lesson_no) THEN
        RAISE EXCEPTION 'Зачисление и занятие относятся к разным группам' USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END $$;

CREATE TRIGGER trg_attendance_rules
    BEFORE INSERT OR UPDATE ON attendance
    FOR EACH ROW EXECUTE FUNCTION fn_attendance_rules();

-- Подклассы сотрудника не пересекаются: педагог не может быть администратором и наоборот
CREATE FUNCTION fn_teacher_exclusive() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM administrator WHERE employee_no = NEW.employee_no) THEN
        RAISE EXCEPTION 'Сотрудник % уже является администратором', NEW.employee_no USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END $$;

CREATE FUNCTION fn_administrator_exclusive() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM teacher WHERE employee_no = NEW.employee_no) THEN
        RAISE EXCEPTION 'Сотрудник % уже является педагогом', NEW.employee_no USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END $$;

CREATE TRIGGER trg_teacher_exclusive BEFORE INSERT OR UPDATE ON teacher
    FOR EACH ROW EXECUTE FUNCTION fn_teacher_exclusive();
CREATE TRIGGER trg_administrator_exclusive BEFORE INSERT OR UPDATE ON administrator
    FOR EACH ROW EXECUTE FUNCTION fn_administrator_exclusive();

-- Расписание: педагог не ведёт два занятия одновременно
CREATE FUNCTION fn_schedule_overlap() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    v_teacher integer;
BEGIN
    SELECT teacher_no INTO v_teacher FROM study_group WHERE group_no = NEW.group_no;
    IF EXISTS (SELECT 1 FROM schedule s
                 JOIN study_group g ON g.group_no = s.group_no
                WHERE g.teacher_no = v_teacher
                  AND s.weekday = NEW.weekday
                  AND s.start_time = NEW.start_time
                  AND s.group_no <> NEW.group_no) THEN
        RAISE EXCEPTION 'Педагог уже ведёт занятие в это время' USING ERRCODE = '23505';
    END IF;
    RETURN NEW;
END $$;

CREATE TRIGGER trg_schedule_overlap
    BEFORE INSERT OR UPDATE ON schedule
    FOR EACH ROW EXECUTE FUNCTION fn_schedule_overlap();

-- Удаление карточки ребёнка допустимо только без задолженности
CREATE FUNCTION fn_child_delete() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (SELECT 1
                 FROM enrollment e
                 JOIN study_group g ON g.group_no = e.group_no
                 JOIN program p ON p.program_code = g.program_code
                WHERE e.card_no = OLD.card_no
                  AND p.price > COALESCE((SELECT sum(amount) FROM payment WHERE enrollment_no = e.enrollment_no), 0)) THEN
        RAISE EXCEPTION 'У ребёнка % есть задолженность, карточку удалять нельзя', OLD.card_no USING ERRCODE = '23503';
    END IF;
    RETURN OLD;
END $$;

CREATE TRIGGER trg_child_delete
    BEFORE DELETE ON child
    FOR EACH ROW EXECUTE FUNCTION fn_child_delete();

-- Родитель, у которого не осталось детей, удаляется
CREATE FUNCTION fn_cleanup_parent() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM parent
     WHERE parent_no = OLD.parent_no
       AND NOT EXISTS (SELECT 1 FROM child_parent WHERE parent_no = OLD.parent_no);
    RETURN NULL;
END $$;

CREATE TRIGGER trg_cleanup_parent
    AFTER DELETE ON child_parent
    FOR EACH ROW EXECUTE FUNCTION fn_cleanup_parent();

-- Отложенные проверки «минимум одна связь» (выполняются при COMMIT, поэтому
-- ребёнка и его родителя нужно добавлять в одной транзакции)
CREATE FUNCTION fn_child_has_parent() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM child WHERE card_no = NEW.card_no)
       AND NOT EXISTS (SELECT 1 FROM child_parent WHERE card_no = NEW.card_no) THEN
        RAISE EXCEPTION 'У ребёнка % не указан ни один родитель', NEW.card_no USING ERRCODE = '23514';
    END IF;
    RETURN NULL;
END $$;

CREATE FUNCTION fn_program_has_direction() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM program WHERE program_code = NEW.program_code)
       AND NOT EXISTS (SELECT 1 FROM program_direction WHERE program_code = NEW.program_code) THEN
        RAISE EXCEPTION 'Программа % не отнесена ни к одному направлению', NEW.program_code USING ERRCODE = '23514';
    END IF;
    RETURN NULL;
END $$;

CREATE FUNCTION fn_teacher_has_direction() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM teacher WHERE employee_no = NEW.employee_no)
       AND NOT EXISTS (SELECT 1 FROM teacher_direction WHERE employee_no = NEW.employee_no) THEN
        RAISE EXCEPTION 'У педагога % не указано ни одно направление', NEW.employee_no USING ERRCODE = '23514';
    END IF;
    RETURN NULL;
END $$;

CREATE CONSTRAINT TRIGGER trg_child_has_parent AFTER INSERT ON child
    DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION fn_child_has_parent();
CREATE CONSTRAINT TRIGGER trg_program_has_direction AFTER INSERT ON program
    DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION fn_program_has_direction();
CREATE CONSTRAINT TRIGGER trg_teacher_has_direction AFTER INSERT ON teacher
    DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION fn_teacher_has_direction();

