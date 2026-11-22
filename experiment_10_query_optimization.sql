/* ============================================================
   Name    : Lakshya Singh
   Roll No : 25LBCS3141
   Subject : Database Management Systems (DBMS) - Practical File
   Experiment 10 : 10,000-Row Dataset, Slow Queries and Optimization
                   using Indexing and Query Rewriting
   ============================================================ */

/* AIM
   To generate a dataset of at least 10,000 rows, execute five slow queries,
   analyze them using EXPLAIN, optimize them through indexing and query
   rewriting, and compare execution before and after optimization. */

DROP DATABASE IF EXISTS DBMS_Exp10;
CREATE DATABASE DBMS_Exp10;
USE DBMS_Exp10;

-- ---------- Step 1: Create and populate the dataset ----------
CREATE TABLE EmployeeSales (
    SaleID       INT PRIMARY KEY,
    EmployeeID   INT NOT NULL,
    EmployeeName VARCHAR(60) NOT NULL,
    Department   VARCHAR(30) NOT NULL,
    City         VARCHAR(40) NOT NULL,
    SaleDate     DATE NOT NULL,
    Amount       DECIMAL(10,2) NOT NULL,
    SaleStatus   VARCHAR(15) NOT NULL,
    Email        VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

SET SESSION cte_max_recursion_depth = 11000;

INSERT INTO EmployeeSales
    (SaleID, EmployeeID, EmployeeName, Department, City,
     SaleDate, Amount, SaleStatus, Email)
WITH RECURSIVE seq AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 10000
)
SELECT
    n,
    MOD(n, 500) + 1,
    CONCAT('Employee_', MOD(n, 500) + 1),
    CASE MOD(n, 4)
        WHEN 0 THEN 'Sales'
        WHEN 1 THEN 'IT'
        WHEN 2 THEN 'HR'
        ELSE 'Finance'
    END,
    CASE MOD(n, 5)
        WHEN 0 THEN 'Delhi'
        WHEN 1 THEN 'Mumbai'
        WHEN 2 THEN 'Pune'
        WHEN 3 THEN 'Noida'
        ELSE 'Jaipur'
    END,
    DATE_ADD('2025-01-01', INTERVAL MOD(n, 365) DAY),
    500 + MOD(n * 37, 15000),
    CASE MOD(n, 3)
        WHEN 0 THEN 'Completed'
        WHEN 1 THEN 'Pending'
        ELSE 'Cancelled'
    END,
    CONCAT('employee', MOD(n, 500) + 1, '@example.com')
FROM seq;

SELECT COUNT(*) AS TotalRows FROM EmployeeSales;   -- expected 10000

-- ---------- Step 2: Five slow queries BEFORE optimization ----------
-- Slow Query 1: function applied to a date column
EXPLAIN SELECT * FROM EmployeeSales WHERE YEAR(SaleDate) = 2025;
SELECT * FROM EmployeeSales WHERE YEAR(SaleDate) = 2025;

-- Slow Query 2: leading-wildcard search
EXPLAIN SELECT * FROM EmployeeSales WHERE EmployeeName LIKE '%25%';
SELECT * FROM EmployeeSales WHERE EmployeeName LIKE '%25%';

-- Slow Query 3: function on the amount column
EXPLAIN SELECT * FROM EmployeeSales WHERE ROUND(Amount, 0) = 5000;
SELECT * FROM EmployeeSales WHERE ROUND(Amount, 0) = 5000;

-- Slow Query 4: filter and sort without a supporting index
EXPLAIN
SELECT * FROM EmployeeSales
WHERE Department = 'Sales'
ORDER BY SaleDate DESC;

SELECT * FROM EmployeeSales
WHERE Department = 'Sales'
ORDER BY SaleDate DESC;

-- Slow Query 5: OR across different columns
EXPLAIN SELECT * FROM EmployeeSales WHERE City = 'Delhi' OR SaleStatus = 'Pending';
SELECT * FROM EmployeeSales WHERE City = 'Delhi' OR SaleStatus = 'Pending';

-- ---------- Step 3: Create indexes ----------
CREATE INDEX idx_saledate ON EmployeeSales(SaleDate);
CREATE INDEX idx_amount   ON EmployeeSales(Amount);
CREATE INDEX idx_department_date ON EmployeeSales(Department, SaleDate);
CREATE INDEX idx_city     ON EmployeeSales(City);
CREATE INDEX idx_status   ON EmployeeSales(SaleStatus);
-- Needed for the prefix search in Optimized Query 2:
CREATE INDEX idx_employeename ON EmployeeSales(EmployeeName);

ANALYZE TABLE EmployeeSales;
SHOW INDEX FROM EmployeeSales;

-- ---------- Step 4: Optimized query versions ----------
-- Optimized Query 1: date range instead of YEAR()
-- (all generated dates are in 2025, so a scan may still be the cheapest plan)
EXPLAIN
SELECT * FROM EmployeeSales
WHERE SaleDate >= '2025-01-01' AND SaleDate < '2026-01-01';

SELECT * FROM EmployeeSales
WHERE SaleDate >= '2025-01-01' AND SaleDate < '2026-01-01';

-- Optimized Query 2: searchable prefix (not identical to "contains 25").
-- For a true contains-anywhere search consider FULLTEXT or a dedicated design.
EXPLAIN SELECT * FROM EmployeeSales WHERE EmployeeName LIKE 'Employee_25%';
SELECT * FROM EmployeeSales WHERE EmployeeName LIKE 'Employee_25%';

-- Optimized Query 3: range instead of ROUND(Amount, 0)
-- (verify boundary behavior for your exact requirement)
EXPLAIN SELECT * FROM EmployeeSales WHERE Amount >= 4999.5 AND Amount < 5000.5;
SELECT * FROM EmployeeSales WHERE Amount >= 4999.5 AND Amount < 5000.5;

-- Optimized Query 4: composite index and only the required columns
EXPLAIN
SELECT SaleID, EmployeeID, SaleDate, Amount
FROM EmployeeSales
WHERE Department = 'Sales'
ORDER BY SaleDate DESC;

SELECT SaleID, EmployeeID, SaleDate, Amount
FROM EmployeeSales
WHERE Department = 'Sales'
ORDER BY SaleDate DESC;

-- Optimized Query 5: OR rewritten as UNION (deduplicates, preserving OR semantics)
EXPLAIN
SELECT SaleID, EmployeeID, EmployeeName, Department, City,
       SaleDate, Amount, SaleStatus, Email
FROM EmployeeSales WHERE City = 'Delhi'
UNION
SELECT SaleID, EmployeeID, EmployeeName, Department, City,
       SaleDate, Amount, SaleStatus, Email
FROM EmployeeSales WHERE SaleStatus = 'Pending';

SELECT SaleID, EmployeeID, EmployeeName, Department, City,
       SaleDate, Amount, SaleStatus, Email
FROM EmployeeSales WHERE City = 'Delhi'
UNION
SELECT SaleID, EmployeeID, EmployeeName, Department, City,
       SaleDate, Amount, SaleStatus, Email
FROM EmployeeSales WHERE SaleStatus = 'Pending';

-- ---------- Step 5: Optional actual execution plan (MySQL 8.0.18+) ----------
EXPLAIN ANALYZE
SELECT SaleID, EmployeeID, SaleDate, Amount
FROM EmployeeSales
WHERE Department = 'Sales'
ORDER BY SaleDate DESC;

/* OBSERVATION  (fill in actual plan and time from your MySQL; do not copy assumed times)
   Query               | Before: plan / time | After: plan / time | Observation
   --------------------|---------------------|--------------------|---------------------------
   1. Date filter      |                     |                    | Function replaced by date range
   2. Name search      |                     |                    | Wildcard removed only if prefix search is acceptable
   3. Amount filter    |                     |                    | Function replaced by numeric range
   4. Department+sort  |                     |                    | Composite index may reduce sorting and rows scanned
   5. OR condition     |                     |                    | UNION allows separate index paths; dedup has a cost

   A suitable index may change access from ALL (full scan) to range/ref and
   reduce estimated rows, but MySQL can still choose a table scan when a
   condition returns a large fraction of the table. */

/* RESULT
   A dataset of 10,000 rows was generated. Five inefficient query patterns
   were analyzed using EXPLAIN and optimized using indexes and query rewriting.
   Before-and-after plans and timings were compared. */
