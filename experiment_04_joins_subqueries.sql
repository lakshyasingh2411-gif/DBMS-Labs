/* ============================================================
   Name    : Lakshya Singh
   Roll No : 25LBCS3141
   Subject : Database Management Systems (DBMS) - Practical File
   Experiment 4 : Joins, Subqueries, EXISTS, INTERSECT/EXCEPT simulation, EXPLAIN
   ============================================================ */

/* AIM
   Write SQL queries using INNER JOIN, LEFT JOIN, self-join, 3-way join,
   correlated subquery, EXISTS, simulated INTERSECT and EXCEPT, and compare
   execution plans with EXPLAIN.
   (Run Experiment 3 first so that CompanyDB exists.) */

USE CompanyDB;

-- 1. INNER JOIN: employee with department name
SELECT e.emp_id, e.emp_name, e.salary, d.dept_name
FROM Employee e
INNER JOIN Department d ON e.dept_id = d.dept_id
ORDER BY e.emp_id;

-- 2. LEFT JOIN: every department, even if it has no employee.
--    A temporary empty department is added to show the NULL row.
INSERT INTO Department VALUES (6, 'Legal');

SELECT d.dept_id, d.dept_name, e.emp_name, e.salary
FROM Department d
LEFT JOIN Employee e ON d.dept_id = e.dept_id
ORDER BY d.dept_id, e.emp_id;

-- Departments that currently have NO employees (LEFT JOIN + IS NULL)
SELECT d.dept_name
FROM Department d
LEFT JOIN Employee e ON d.dept_id = e.dept_id
WHERE e.emp_id IS NULL;

-- Remove the temporary department so later experiments are unaffected
DELETE FROM Department WHERE dept_id = 6;

-- 3. SELF JOIN: pairs of colleagues in the same department and
--    how much more the first one earns than the second
SELECT e1.emp_name AS employee_1,
       e2.emp_name AS employee_2,
       e1.dept_id,
       e1.salary - e2.salary AS salary_difference
FROM Employee e1
JOIN Employee e2
  ON e1.dept_id = e2.dept_id
 AND e1.emp_id  < e2.emp_id      -- avoids duplicate and self pairs
ORDER BY e1.dept_id, e1.emp_id, e2.emp_id
LIMIT 10;

-- 4. THREE-WAY JOIN: Employee + Department + Project
SELECT e.emp_name, d.dept_name, p.project_name, p.budget
FROM Employee e
INNER JOIN Department d ON e.dept_id    = d.dept_id
INNER JOIN Project    p ON e.project_id = p.project_id
ORDER BY d.dept_name, e.emp_name;

-- 5. CORRELATED SUBQUERY: earns more than own department's average
SELECT e.emp_id, e.emp_name, e.salary, e.dept_id
FROM Employee e
WHERE e.salary > (SELECT AVG(x.salary)
                  FROM Employee x
                  WHERE x.dept_id = e.dept_id)
ORDER BY e.dept_id, e.salary DESC;

-- 6. EXISTS: departments having at least one employee earning above 80,000
SELECT d.dept_id, d.dept_name
FROM Department d
WHERE EXISTS (SELECT 1
              FROM Employee e
              WHERE e.dept_id = d.dept_id
                AND e.salary > 80000);

-- 7. Simulated INTERSECT: Engineering employees AND salary > 70,000
SELECT emp_id, emp_name, salary
FROM Employee
WHERE emp_id IN (SELECT emp_id FROM Employee WHERE dept_id = 1)
  AND emp_id IN (SELECT emp_id FROM Employee WHERE salary > 70000);

-- 8. Simulated EXCEPT: salary > 70,000 but NOT in Engineering
SELECT emp_id, emp_name, salary
FROM Employee
WHERE emp_id IN     (SELECT emp_id FROM Employee WHERE salary > 70000)
  AND emp_id NOT IN (SELECT emp_id FROM Employee WHERE dept_id = 1);

-- 9. EXPLAIN: compare execution plans
-- A. INNER JOIN
EXPLAIN
SELECT e.emp_name, d.dept_name
FROM Employee e
INNER JOIN Department d ON e.dept_id = d.dept_id
WHERE e.salary > 70000;

-- B. Correlated subquery
EXPLAIN
SELECT e.emp_name, e.salary
FROM Employee e
WHERE e.salary > (SELECT AVG(x.salary)
                  FROM Employee x
                  WHERE x.dept_id = e.dept_id);

-- C. EXISTS
EXPLAIN
SELECT d.dept_name
FROM Department d
WHERE EXISTS (SELECT 1
              FROM Employee e
              WHERE e.dept_id = d.dept_id
                AND e.salary > 80000);

/* Note for the write-up: copy the "type", "key", "rows" and "Extra"
   columns from YOUR EXPLAIN output and compare them. With only 30 rows
   MySQL may choose full table scans; the plans differ more on large tables. */
