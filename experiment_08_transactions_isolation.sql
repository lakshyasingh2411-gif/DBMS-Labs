/* ============================================================
   Name    : Lakshya Singh
   Roll No : 25LBCS3141
   Subject : Database Management Systems (DBMS) - Practical File
   Experiment 8 : Transactions, Savepoints, Rollback, Isolation Levels
                  and Concurrency Anomalies
   ============================================================ */

/* AIM
   To implement banking transactions using START TRANSACTION, COMMIT,
   ROLLBACK and SAVEPOINT, simulate partial failures, and demonstrate
   isolation levels and concurrency anomalies using two sessions. */

DROP DATABASE IF EXISTS DBMS_Exp8;
CREATE DATABASE DBMS_Exp8;
USE DBMS_Exp8;

-- ---------- Setup ----------
CREATE TABLE BankAccounts (
    AccountID  INT PRIMARY KEY,
    HolderName VARCHAR(60) NOT NULL,
    Balance    DECIMAL(12,2) NOT NULL,
    CHECK (Balance >= 0)
) ENGINE=InnoDB;

INSERT INTO BankAccounts VALUES
(1, 'Aarav', 10000.00),
(2, 'Diya',   7000.00),
(3, 'Kabir',  5000.00);

SELECT * FROM BankAccounts;

-- ---------- 1. Successful transfer using COMMIT ----------
START TRANSACTION;

UPDATE BankAccounts
SET Balance = Balance - 1000
WHERE AccountID = 1 AND Balance >= 1000;

UPDATE BankAccounts
SET Balance = Balance + 1000
WHERE AccountID = 2;

COMMIT;

SELECT * FROM BankAccounts;
SELECT SUM(Balance) AS TotalBalance FROM BankAccounts;   -- expected 22000
-- In an application, check that the debit UPDATE affected exactly one row
-- before crediting and committing.

-- ---------- 2. Partial failure using SAVEPOINT ----------
START TRANSACTION;

UPDATE BankAccounts
SET Balance = Balance - 500
WHERE AccountID = 1;

SAVEPOINT after_debit;

UPDATE BankAccounts
SET Balance = Balance + 500
WHERE AccountID = 2;

-- Suppose a later step fails: undo only the credit.
ROLLBACK TO SAVEPOINT after_debit;
-- The debit is still pending; cancel it too for this demonstration.
ROLLBACK;

SELECT * FROM BankAccounts;   -- balances back to pre-transaction values

-- ---------- 3. Complete rollback ----------
START TRANSACTION;

UPDATE BankAccounts
SET Balance = Balance - 200
WHERE AccountID = 1;

UPDATE BankAccounts
SET Balance = Balance + 200
WHERE AccountID = 3;

ROLLBACK;

SELECT * FROM BankAccounts;   -- neither update remains

/* ============================================================
   TWO-SESSION CONCURRENCY DEMONSTRATIONS
   Open two MySQL query windows connected to DBMS_Exp8 and run the
   commands in the exact order shown. They are commented out so this
   file can run top-to-bottom without blocking.
   Note: after the committed transfer above, Account 1 = 9000.
   ============================================================ */

/* ---- A. Dirty read (READ UNCOMMITTED) ----
-- Session 1:
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
START TRANSACTION;
UPDATE BankAccounts SET Balance = 7500 WHERE AccountID = 1;
-- Do not commit yet.

-- Session 2:
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
START TRANSACTION;
SELECT Balance FROM BankAccounts WHERE AccountID = 1;   -- sees 7500 (dirty read)
COMMIT;

-- Session 1 cleanup:
ROLLBACK;
*/

/* ---- B. Non-repeatable read (READ COMMITTED) ----
-- Session 1:
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
START TRANSACTION;
SELECT Balance FROM BankAccounts WHERE AccountID = 1;   -- first read

-- Session 2:
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
START TRANSACTION;
UPDATE BankAccounts SET Balance = Balance + 300 WHERE AccountID = 1;
COMMIT;

-- Session 1 (repeat the same SELECT):
SELECT Balance FROM BankAccounts WHERE AccountID = 1;   -- 300 higher
COMMIT;
*/

/* ---- C. Phantom read (READ COMMITTED) ----
-- Session 1:
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
START TRANSACTION;
SELECT AccountID, Balance FROM BankAccounts WHERE Balance >= 5000;

-- Session 2:
START TRANSACTION;
INSERT INTO BankAccounts VALUES (4, 'Meera', 6000.00);
COMMIT;

-- Session 1 (repeat the range query):
SELECT AccountID, Balance FROM BankAccounts WHERE Balance >= 5000;  -- account 4 appears
COMMIT;

-- Cleanup after both sessions finish:
DELETE FROM BankAccounts WHERE AccountID = 4;
*/

/* ISOLATION LEVEL COMPARISON
   READ UNCOMMITTED : Dirty reads may occur.
   READ COMMITTED   : Dirty reads prevented; non-repeatable and phantom reads may occur.
   REPEATABLE READ  : Consistent reads use a snapshot; InnoDB range locking can
                      prevent many phantom inserts for locking reads.
   SERIALIZABLE     : Strongest isolation; conflicting operations may wait or fail.

   MySQL InnoDB defaults to REPEATABLE READ. Exact observations depend on whether
   ordinary consistent SELECTs or locking reads (SELECT ... FOR UPDATE /
   LOCK IN SHARE MODE) are used. Record the actual result from your sessions. */

/* OBSERVATION
   Successful transfer + COMMIT : Debit and credit both persist; total unchanged.
   ROLLBACK                     : All uncommitted changes are cancelled.
   SAVEPOINT rollback           : Only changes after the savepoint are undone.
   READ UNCOMMITTED test        : Session 2 sees Session 1's uncommitted value.
   READ COMMITTED test          : Repeated read shows the updated committed value.
   Phantom test                 : Repeated range query includes the new row. */

/* RESULT
   Banking transactions were implemented using START TRANSACTION, COMMIT,
   ROLLBACK and SAVEPOINT. Dirty, non-repeatable and phantom reads were
   demonstrated and the role of isolation levels was studied. */
