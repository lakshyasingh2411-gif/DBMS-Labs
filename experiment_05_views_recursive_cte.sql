/* ============================================================
   Name    : Lakshya Singh
   Roll No : 25LBCS3141
   Subject : Database Management Systems (DBMS) - Practical File
   Experiment 5 : Views, View Updatability, Recursive CTE
   ============================================================ */

/* AIM
   Create views for department salary summary and employee hierarchy,
   test whether views are updatable, and use a recursive CTE to show
   reporting chains.
   (Run Experiment 3 first. Run this file once; re-running Experiment 3
   resets the database.) */

USE CompanyDB;

-- ---------- Add manager relationship ----------
ALTER TABLE Employee ADD COLUMN manager_id INT NULL;
ALTER TABLE Employee
    ADD CONSTRAINT fk_employee_manager
    FOREIGN KEY (manager_id) REFERENCES Employee(emp_id);

-- Department heads keep manager_id = NULL
UPDATE Employee SET manager_id = 1  WHERE emp_id IN (2, 3);
UPDATE Employee SET manager_id = 2  WHERE emp_id IN (4, 5);
UPDATE Employee SET manager_id = 3  WHERE emp_id IN (6, 7);
UPDATE Employee SET manager_id = 8  WHERE emp_id IN (9, 10);
UPDATE Employee SET manager_id = 9  WHERE emp_id IN (11, 12);
UPDATE Employee SET manager_id = 13 WHERE emp_id IN (14, 15);
UPDATE Employee SET manager_id = 14 WHERE emp_id IN (16, 17);
UPDATE Employee SET manager_id = 15 WHERE emp_id = 18;
UPDATE Employee SET manager_id = 19 WHERE emp_id IN (20, 21);
UPDATE Employee SET manager_id = 20 WHERE emp_id IN (22, 23);
UPDATE Employee SET manager_id = 21 WHERE emp_id = 24;
UPDATE Employee SET manager_id = 25 WHERE emp_id IN (26, 27);
UPDATE Employee SET manager_id = 26 WHERE emp_id IN (28, 29);
UPDATE Employee SET manager_id = 27 WHERE emp_id = 30;

-- ---------- 1. Department salary summary view ----------
CREATE OR REPLACE VIEW department_salary_summary AS
SELECT d.dept_id,
       d.dept_name,
       COUNT(e.emp_id) AS employee_count,
       AVG(e.salary)   AS average_salary,
       MIN(e.salary)   AS minimum_salary,
       MAX(e.salary)   AS maximum_salary,
       SUM(e.salary)   AS total_salary
FROM Department d
JOIN Employee e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name;

SELECT * FROM department_salary_summary;

-- ---------- 2. Employee hierarchy view ----------
CREATE OR REPLACE VIEW employee_hierarchy AS
SELECT e.emp_id,
       e.emp_name,
       d.dept_name,
       e.manager_id,
       m.emp_name AS manager_name,
       e.salary
FROM Employee e
JOIN Department d ON e.dept_id = d.dept_id
LEFT JOIN Employee m ON e.manager_id = m.emp_id;

SELECT * FROM employee_hierarchy ORDER BY emp_id;

-- ---------- 3. Updatability of views ----------
-- (a) A simple one-table view without aggregates IS updatable
CREATE OR REPLACE VIEW engineering_staff AS
SELECT emp_id, emp_name, salary, dept_id
FROM Employee
WHERE dept_id = 1
WITH CHECK OPTION;

UPDATE engineering_staff SET salary = salary + 1000 WHERE emp_id = 6;
SELECT emp_id, emp_name, salary FROM Employee WHERE emp_id = 6;   -- changed in base table

-- WITH CHECK OPTION blocks a change that would push the row out of the view
-- (expected to FAIL: Error 1369, CHECK OPTION failed)
UPDATE engineering_staff SET dept_id = 2 WHERE emp_id = 6;

-- (b) An aggregate / GROUP BY view is NOT updatable
-- (expected to FAIL: Error 1288, target table of UPDATE is not updatable)
UPDATE department_salary_summary SET average_salary = 70000 WHERE dept_id = 1;

-- Undo the test change
UPDATE Employee SET salary = 54000 WHERE emp_id = 6;

-- ---------- 4. Recursive CTE: reporting chain ----------
WITH RECURSIVE reporting_chain AS (
    -- anchor: department heads (no manager)
    SELECT emp_id,
           emp_name,
           manager_id,
           1 AS level,
           CAST(emp_name AS CHAR(500)) AS reporting_path
    FROM Employee
    WHERE manager_id IS NULL

    UNION ALL

    -- recursive step: employees reporting to someone already found
    SELECT e.emp_id,
           e.emp_name,
           e.manager_id,
           rc.level + 1,
           CONCAT(rc.reporting_path, ' -> ', e.emp_name)
    FROM Employee e
    JOIN reporting_chain rc ON e.manager_id = rc.emp_id
)
SELECT emp_id, emp_name, manager_id, level, reporting_path
FROM reporting_chain
ORDER BY reporting_path;

-- Extra: number of people in each level of the organisation
WITH RECURSIVE lvl AS (
    SELECT emp_id, 1 AS level FROM Employee WHERE manager_id IS NULL
    UNION ALL
    SELECT e.emp_id, lvl.level + 1
    FROM Employee e JOIN lvl ON e.manager_id = lvl.emp_id
)
SELECT level, COUNT(*) AS employees_at_level
FROM lvl
GROUP BY level
ORDER BY level;
