/* ============================================================
   Name    : Lakshya Singh
   Roll No : 25LBCS3141
   Subject : Database Management Systems (DBMS) - Practical File
   Experiment 9 : Railway Booking Table, Indexing and Query
                  Performance Comparison using EXPLAIN
   ============================================================ */

/* AIM
   To create a Railway Booking table with at least 5,000 records, benchmark
   query performance before and after creating single-column and composite
   indexes, and compare execution plans using EXPLAIN. */

DROP DATABASE IF EXISTS DBMS_Exp9;
CREATE DATABASE DBMS_Exp9;
USE DBMS_Exp9;

-- ---------- Step 1: Table ----------
CREATE TABLE RailwayBookings (
    BookingID          INT PRIMARY KEY,
    PassengerName      VARCHAR(60) NOT NULL,
    TrainNo            INT NOT NULL,
    SourceStation      VARCHAR(40) NOT NULL,
    DestinationStation VARCHAR(40) NOT NULL,
    JourneyDate        DATE NOT NULL,
    BookingStatus      VARCHAR(15) NOT NULL,
    SeatNo             VARCHAR(10),
    Fare               DECIMAL(8,2) NOT NULL,
    BookingTime        DATETIME NOT NULL
) ENGINE=InnoDB;

-- ---------- Step 2: Generate 5,000 records (MySQL 8.0 recursive CTE) ----------
SET SESSION cte_max_recursion_depth = 6000;

INSERT INTO RailwayBookings
    (BookingID, PassengerName, TrainNo, SourceStation, DestinationStation,
     JourneyDate, BookingStatus, SeatNo, Fare, BookingTime)
WITH RECURSIVE seq AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 5000
)
SELECT
    n,
    CONCAT('Passenger_', n),
    12000 + MOD(n, 50),
    CASE MOD(n, 5)
        WHEN 0 THEN 'Delhi'
        WHEN 1 THEN 'Mumbai'
        WHEN 2 THEN 'Chennai'
        WHEN 3 THEN 'Kolkata'
        ELSE 'Bhopal'
    END,
    CASE MOD(n, 5)
        WHEN 0 THEN 'Jaipur'
        WHEN 1 THEN 'Pune'
        WHEN 2 THEN 'Bengaluru'
        WHEN 3 THEN 'Patna'
        ELSE 'Indore'
    END,
    DATE_ADD('2026-11-01', INTERVAL MOD(n, 90) DAY),
    CASE MOD(n, 4)
        WHEN 0 THEN 'Confirmed'
        WHEN 1 THEN 'Waiting'
        WHEN 2 THEN 'Cancelled'
        ELSE 'Confirmed'
    END,
    CONCAT('S', MOD(n, 72) + 1),
    250 + MOD(n * 17, 2000),
    DATE_ADD('2026-10-01 08:00:00', INTERVAL n MINUTE)
FROM seq;

SELECT COUNT(*) AS TotalBookings FROM RailwayBookings;   -- expected 5000

-- ---------- Step 3: Queries BEFORE indexing ----------
-- Query 1: bookings for a particular train
EXPLAIN
SELECT * FROM RailwayBookings
WHERE TrainNo = 12025;

-- Query 2: bookings for a date and status
EXPLAIN
SELECT * FROM RailwayBookings
WHERE JourneyDate = '2026-11-15'
  AND BookingStatus = 'Confirmed';

-- Query 3: confirmed bookings for one train on one date
EXPLAIN
SELECT BookingID, PassengerName, Fare
FROM RailwayBookings
WHERE TrainNo = 12025
  AND JourneyDate = '2026-11-15'
  AND BookingStatus = 'Confirmed';

-- Query 4: bookings for one passenger
EXPLAIN
SELECT * FROM RailwayBookings
WHERE PassengerName = 'Passenger_2500';

-- ---------- Step 4: Single-column and composite indexes ----------
CREATE INDEX idx_train       ON RailwayBookings(TrainNo);
CREATE INDEX idx_journey_date ON RailwayBookings(JourneyDate);
CREATE INDEX idx_passenger   ON RailwayBookings(PassengerName);
CREATE INDEX idx_train_date_status
    ON RailwayBookings(TrainNo, JourneyDate, BookingStatus);

ANALYZE TABLE RailwayBookings;
SHOW INDEX FROM RailwayBookings;

-- ---------- Step 5: Same queries AFTER indexing ----------
EXPLAIN
SELECT * FROM RailwayBookings
WHERE TrainNo = 12025;

EXPLAIN
SELECT * FROM RailwayBookings
WHERE JourneyDate = '2026-11-15'
  AND BookingStatus = 'Confirmed';

EXPLAIN
SELECT BookingID, PassengerName, Fare
FROM RailwayBookings
WHERE TrainNo = 12025
  AND JourneyDate = '2026-11-15'
  AND BookingStatus = 'Confirmed';

EXPLAIN
SELECT * FROM RailwayBookings
WHERE PassengerName = 'Passenger_2500';

-- ---------- Optional: actual execution time (MySQL 8.0.18+) ----------
EXPLAIN ANALYZE
SELECT BookingID, PassengerName, Fare
FROM RailwayBookings
WHERE TrainNo = 12025
  AND JourneyDate = '2026-11-15'
  AND BookingStatus = 'Confirmed';

/* OBSERVATION  (fill in from EXPLAIN on your own system; do not invent timings)
   Query                    | Before: type/key/rows | After: type/key/rows | Time before/after
   -------------------------|-----------------------|----------------------|------------------
   TrainNo filter           |                       |                      |
   Date + status            |                       |                      |
   Train + date + status    |                       |                      |
   Passenger name           |                       |                      |

   Note: with only 5,000 rows MySQL may still choose a table scan if many rows
   match or if scanning is estimated to be cheaper. This does not mean the
   index is incorrect. EXPLAIN ANALYZE executes the query and reports actual
   timing and row counts. */

/* RESULT
   A RailwayBookings table with 5,000 records was created. Single-column and
   composite indexes were added, and EXPLAIN / EXPLAIN ANALYZE were used to
   compare query plans and performance before and after indexing. */
