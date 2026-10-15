/* ============================================================
   Name    : Lakshya Singh
   Roll No : 25LBCS3141
   Subject : Database Management Systems (DBMS) - Practical File
   Experiment 6 : Stored Procedure, Triggers and Audit Log
   ============================================================ */

/* AIM
   Create the procedure transfer_employee(emp_id, new_dept_id) with validation
   and error handling, triggers for salary validation and audit logging, and
   test the edge cases.
   (Run Experiments 3 and 5 first.)
   TIP: In MySQL Workbench run the "expected to FAIL" statements one at a time,
   because an error stops a whole-script run. */

USE CompanyDB;

-- ---------- 1. Audit tables ----------
CREATE TABLE IF NOT EXISTS Employee_Salary_Audit (
    audit_id   INT AUTO_INCREMENT PRIMARY KEY,
    emp_id     INT NOT NULL,
    old_salary DECIMAL(10,2),
    new_salary DECIMAL(10,2),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    action     VARCHAR(30)
);

CREATE TABLE IF NOT EXISTS Employee_Transfer_Log (
    log_id       INT AUTO_INCREMENT PRIMARY KEY,
    emp_id       INT NOT NULL,
    from_dept_id INT,
    to_dept_id   INT,
    transferred_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ---------- 2. Salary validation triggers (30,000 to 1,50,000) ----------
DROP TRIGGER IF EXISTS trg_salary_check_insert;
DROP TRIGGER IF EXISTS trg_salary_check_update;
DROP TRIGGER IF EXISTS trg_salary_audit;

DELIMITER //

CREATE TRIGGER trg_salary_check_insert
BEFORE INSERT ON Employee
FOR EACH ROW
BEGIN
    IF NEW.salary < 30000 OR NEW.salary > 150000 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Salary must be between 30000 and 150000';
    END IF;
END//

CREATE TRIGGER trg_salary_check_update
BEFORE UPDATE ON Employee
FOR EACH ROW
BEGIN
    IF NEW.salary < 30000 OR NEW.salary > 150000 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Salary must be between 30000 and 150000';
    END IF;
END//

-- ---------- 3. Audit trigger: log every salary change ----------
CREATE TRIGGER trg_salary_audit
AFTER UPDATE ON Employee
FOR EACH ROW
BEGIN
    IF OLD.salary <> NEW.salary THEN
        INSERT INTO Employee_Salary_Audit (emp_id, old_salary, new_salary, action)
        VALUES (NEW.emp_id, OLD.salary, NEW.salary, 'SALARY UPDATE');
    END IF;
END//

-- ---------- 4. Stored procedure ----------
DROP PROCEDURE IF EXISTS transfer_employee//

CREATE PROCEDURE transfer_employee(
    IN p_emp_id      INT,
    IN p_new_dept_id INT
)
BEGIN
    DECLARE v_old_dept_id INT DEFAULT NULL;
    DECLARE v_emp_found   INT DEFAULT 0;
    DECLARE v_dept_found  INT DEFAULT 0;

    -- on any SQL error: undo everything and pass the error to the caller
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT COUNT(*), MAX(dept_id)
      INTO v_emp_found, v_old_dept_id
      FROM Employee
     WHERE emp_id = p_emp_id;

    IF v_emp_found = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Employee does not exist';
    END IF;

    SELECT COUNT(*) INTO v_dept_found
      FROM Department
     WHERE dept_id = p_new_dept_id;

    IF v_dept_found = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Department does not exist';
    END IF;

    IF v_old_dept_id = p_new_dept_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Employee is already in this department';
    END IF;

    UPDATE Employee SET dept_id = p_new_dept_id WHERE emp_id = p_emp_id;

    INSERT INTO Employee_Transfer_Log (emp_id, from_dept_id, to_dept_id)
    VALUES (p_emp_id, v_old_dept_id, p_new_dept_id);

    COMMIT;
END//

DELIMITER ;

-- ---------- 5. Test: successful transfer ----------
-- Employee 6 (Ritika Bansal) moves from Engineering (1) to Sales (4)
CALL transfer_employee(6, 4);

SELECT e.emp_id, e.emp_name, d.dept_name
FROM Employee e JOIN Department d ON e.dept_id = d.dept_id
WHERE e.emp_id = 6;

SELECT * FROM Employee_Transfer_Log;

-- ---------- 6. Test: edge cases (each expected to FAIL) ----------
CALL transfer_employee(99, 4);   -- Employee does not exist
CALL transfer_employee(6, 99);   -- Department does not exist
CALL transfer_employee(6, 4);    -- Employee is already in this department

-- ---------- 7. Test: salary validation ----------
-- Invalid update (expected to FAIL)
UPDATE Employee SET salary = 20000 WHERE emp_id = 6;
-- Invalid insert (expected to FAIL)
INSERT INTO Employee (emp_id, emp_name, salary, hire_date, dept_id, project_id)
VALUES (31, 'Test Employee', 200000, '2025-01-10', 4, 205);

-- Valid update (audit trigger fires)
UPDATE Employee SET salary = 58000 WHERE emp_id = 6;
-- Valid insert
INSERT INTO Employee (emp_id, emp_name, salary, hire_date, dept_id, project_id)
VALUES (31, 'Arnav Saxena', 52000, '2025-01-10', 4, 205);
-- Change the new employee's salary so the audit log records it
UPDATE Employee SET salary = 55000 WHERE emp_id = 31;

-- ---------- 8. Show the audit log ----------
SELECT audit_id, emp_id, old_salary, new_salary, changed_at, action
FROM Employee_Salary_Audit
ORDER BY audit_id;
