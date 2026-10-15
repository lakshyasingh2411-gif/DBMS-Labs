/* ============================================================
   Name    : Lakshya Singh
   Roll No : 25LBCS3141
   Subject : Database Management Systems (DBMS) - Practical File
   Experiment 3 : Selection, Projection, Aggregates, GROUP BY, HAVING, CASE, ORDER BY
   ============================================================ */

/* AIM
   Create an Employee-Department-Project database with 30 employees,
   5 departments and 8 projects, and demonstrate basic SQL queries. */

DROP DATABASE IF EXISTS CompanyDB;
CREATE DATABASE CompanyDB;
USE CompanyDB;

-- ---------- Tables ----------
CREATE TABLE Department (
    dept_id   INT PRIMARY KEY,
    dept_name VARCHAR(50) NOT NULL
);

CREATE TABLE Project (
    project_id   INT PRIMARY KEY,
    project_name VARCHAR(100) NOT NULL,
    budget       DECIMAL(12,2),
    dept_id      INT,
    FOREIGN KEY (dept_id) REFERENCES Department(dept_id)
);

CREATE TABLE Employee (
    emp_id     INT PRIMARY KEY,
    emp_name   VARCHAR(50) NOT NULL,
    salary     DECIMAL(10,2),
    hire_date  DATE,
    dept_id    INT,
    project_id INT,
    FOREIGN KEY (dept_id)    REFERENCES Department(dept_id),
    FOREIGN KEY (project_id) REFERENCES Project(project_id)
);

-- ---------- Data ----------
INSERT INTO Department VALUES
(1, 'Engineering'),
(2, 'Human Resources'),
(3, 'Accounts'),
(4, 'Sales'),
(5, 'Logistics');

INSERT INTO Project VALUES
(201, 'Customer Portal Revamp',     160000, 1),
(202, 'Machine Learning Pipeline',  220000, 1),
(203, 'Campus Hiring Drive',         70000, 2),
(204, 'Budget Forecasting Tool',    130000, 3),
(205, 'Festive Sales Campaign',     110000, 4),
(206, 'Warehouse Tracking System',  175000, 5),
(207, 'Android App Launch',         145000, 1),
(208, 'Staff Wellbeing Program',     55000, 2);

INSERT INTO Employee VALUES
( 1, 'Harsh Verma',        92000, '2019-07-01', 1, 201),
( 2, 'Neha Kapoor',        78000, '2020-02-14', 1, 201),
( 3, 'Sahil Mehra',       71000, '2021-05-23', 1, 202),
( 4, 'Pooja Nair',         66000, '2022-08-08', 1, 202),
( 5, 'Tanmay Joshi',       59000, '2023-01-16', 1, 207),
( 6, 'Ritika Bansal',      54000, '2023-09-04', 1, 207),
( 7, 'Aman Chauhan',       47000, '2024-06-10', 1, 201),
( 8, 'Sunita Rao',         74000, '2018-11-12', 2, 203),
( 9, 'Vikas Tiwari',      56000, '2020-10-05', 2, 203),
(10, 'Preeti Dubey',       51000, '2021-12-20', 2, 208),
(11, 'Gaurav Pandey',      45000, '2022-07-25', 2, 203),
(12, 'Shreya Mishra',      42000, '2024-02-12', 2, 208),
(13, 'Rajeev Agarwal',     98000, '2017-04-03', 3, 204),
(14, 'Komal Sharma',       82000, '2019-09-17', 3, 204),
(15, 'Devansh Gupta',      69000, '2021-03-29', 3, 204),
(16, 'Anjali Yadav',       61000, '2022-10-11', 3, 204),
(17, 'Mohit Rastogi',      55000, '2023-05-02', 3, 204),
(18, 'Isha Trivedi',       48000, '2024-04-15', 3, 204),
(19, 'Kunal Malhotra',     88000, '2018-06-28', 4, 205),
(20, 'Simran Kaur',        73000, '2020-08-19', 4, 205),
(21, 'Abhishek Srivastava',64000, '2021-11-08', 4, 205),
(22, 'Naina Khanna',       58000, '2022-04-30', 4, 205),
(23, 'Rahul Bhatt',        52000, '2023-07-13', 4, 205),
(24, 'Palak Jain',         44000, '2024-08-21', 4, 205),
(25, 'Deepak Chaturvedi',  85000, '2018-01-22', 5, 206),
(26, 'Suman Pathak',       70000, '2019-12-09', 5, 206),
(27, 'Harpreet Gill',      63000, '2021-06-14', 5, 206),
(28, 'Mayank Ahuja',       57000, '2022-09-26', 5, 206),
(29, 'Rashmi Kulkarni',    50000, '2023-11-03', 5, 206),
(30, 'Yogesh Rawat',       46000, '2024-05-27', 5, 206);

-- Quick check of row counts
SELECT (SELECT COUNT(*) FROM Department) AS departments,
       (SELECT COUNT(*) FROM Project)    AS projects,
       (SELECT COUNT(*) FROM Employee)   AS employees;

-- ---------- Queries ----------

-- 1. Selection: employees earning more than 70,000
SELECT * FROM Employee WHERE salary > 70000;

-- 2. Projection: only name and salary
SELECT emp_name, salary FROM Employee;

-- 3. Aggregate functions
SELECT COUNT(*)    AS total_employees,
       AVG(salary) AS average_salary,
       MAX(salary) AS highest_salary,
       MIN(salary) AS lowest_salary,
       SUM(salary) AS total_salary
FROM Employee;

-- 4. GROUP BY: head-count and average salary per department
SELECT d.dept_name,
       COUNT(e.emp_id) AS employee_count,
       AVG(e.salary)   AS average_salary
FROM Department d
JOIN Employee e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name;

-- 5. HAVING: departments whose average salary exceeds 65,000
SELECT d.dept_name,
       AVG(e.salary) AS average_salary
FROM Department d
JOIN Employee e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
HAVING AVG(e.salary) > 65000;

-- 6. CASE: salary bands
SELECT emp_name, salary,
       CASE
           WHEN salary >= 80000 THEN 'Senior Band'
           WHEN salary >= 55000 THEN 'Mid Band'
           ELSE 'Junior Band'
       END AS salary_band
FROM Employee;

-- 7. ORDER BY: highest paid first
SELECT emp_name, salary FROM Employee ORDER BY salary DESC;

-- 8. JOIN of Employee, Department and Project
SELECT e.emp_name, d.dept_name, p.project_name, e.salary
FROM Employee e
JOIN Department d ON e.dept_id    = d.dept_id
JOIN Project    p ON e.project_id = p.project_id
ORDER BY d.dept_name, e.emp_name;

-- 9. Extra: employees hired in 2022 or later whose name starts with 'S' or 'R'
SELECT emp_name, hire_date
FROM Employee
WHERE hire_date >= '2022-01-01'
  AND (emp_name LIKE 'S%' OR emp_name LIKE 'R%');

-- 10. Extra: project budget total per department
SELECT d.dept_name, SUM(p.budget) AS total_budget
FROM Department d
JOIN Project p ON p.dept_id = d.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY total_budget DESC;
