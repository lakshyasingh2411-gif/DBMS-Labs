/* ============================================================
   Name    : Lakshya Singh
   Roll No : 25LBCS3141
   Subject : Database Management Systems (DBMS) - Practical File
   Experiment 7 : Functional Dependencies and Normalization
                  (UNF -> 1NF -> 2NF -> 3NF -> BCNF)
   ============================================================ */

/* AIM
   To identify functional dependencies in a denormalized Sales table and
   normalize it step-by-step from UNF to 1NF, 2NF, 3NF and BCNF, and to
   verify lossless join and dependency preservation using SQL queries. */

/* FUNCTIONAL DEPENDENCIES
   Relation  : SALES_1NF(OrderID, ProductID, OrderDate, CustomerID,
               CustomerName, CustomerCity, SalespersonID, SalespersonName,
               ProductName, UnitPrice, Quantity)
   Candidate key : (OrderID, ProductID)

   OrderID                -> OrderDate, CustomerID, SalespersonID
   CustomerID             -> CustomerName, CustomerCity
   SalespersonID          -> SalespersonName
   ProductID              -> ProductName, UnitPrice
   (OrderID, ProductID)   -> Quantity                                */

DROP DATABASE IF EXISTS DBMS_Exp7;
CREATE DATABASE DBMS_Exp7;
USE DBMS_Exp7;

-- ---------- Step 1: UNF (ProductList holds multiple values in one field) ----------
CREATE TABLE Sales_UNF (
    OrderID         INT PRIMARY KEY,
    OrderDate       DATE,
    CustomerID      INT,
    CustomerName    VARCHAR(60),
    CustomerCity    VARCHAR(40),
    SalespersonID   INT,
    SalespersonName VARCHAR(60),
    ProductList     VARCHAR(255)
);

INSERT INTO Sales_UNF VALUES
(101, '2026-10-01', 1, 'Aman', 'Delhi',  11, 'Neha',  'P1:2, P2:1'),
(102, '2026-10-02', 2, 'Riya', 'Noida',  12, 'Karan', 'P1:1, P3:3');

SELECT * FROM Sales_UNF;

-- ---------- Step 2: 1NF (one atomic value per cell, one row per product line) ----------
CREATE TABLE Sales_1NF (
    OrderID         INT,
    ProductID       VARCHAR(10),
    OrderDate       DATE,
    CustomerID      INT,
    CustomerName    VARCHAR(60),
    CustomerCity    VARCHAR(40),
    SalespersonID   INT,
    SalespersonName VARCHAR(60),
    ProductName     VARCHAR(60),
    UnitPrice       DECIMAL(10,2),
    Quantity        INT,
    PRIMARY KEY (OrderID, ProductID)
);

INSERT INTO Sales_1NF VALUES
(101, 'P1', '2026-10-01', 1, 'Aman', 'Delhi', 11, 'Neha',  'Keyboard',  800, 2),
(101, 'P2', '2026-10-01', 1, 'Aman', 'Delhi', 11, 'Neha',  'Mouse',     400, 1),
(102, 'P1', '2026-10-02', 2, 'Riya', 'Noida', 12, 'Karan', 'Keyboard',  800, 1),
(102, 'P3', '2026-10-02', 2, 'Riya', 'Noida', 12, 'Karan', 'Monitor',  6500, 3);

SELECT * FROM Sales_1NF;

-- ---------- Step 3: 2NF / 3NF / BCNF decomposition ----------
CREATE TABLE Customers (
    CustomerID   INT PRIMARY KEY,
    CustomerName VARCHAR(60) NOT NULL,
    CustomerCity VARCHAR(40) NOT NULL
);

CREATE TABLE Salespersons (
    SalespersonID   INT PRIMARY KEY,
    SalespersonName VARCHAR(60) NOT NULL
);

CREATE TABLE Products (
    ProductID   VARCHAR(10) PRIMARY KEY,
    ProductName VARCHAR(60) NOT NULL,
    UnitPrice   DECIMAL(10,2) NOT NULL
);

CREATE TABLE Orders (
    OrderID       INT PRIMARY KEY,
    OrderDate     DATE NOT NULL,
    CustomerID    INT NOT NULL,
    SalespersonID INT NOT NULL,
    FOREIGN KEY (CustomerID)    REFERENCES Customers(CustomerID),
    FOREIGN KEY (SalespersonID) REFERENCES Salespersons(SalespersonID)
);

CREATE TABLE OrderDetails (
    OrderID   INT,
    ProductID VARCHAR(10),
    Quantity  INT NOT NULL,
    PRIMARY KEY (OrderID, ProductID),
    FOREIGN KEY (OrderID)   REFERENCES Orders(OrderID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

INSERT INTO Customers    VALUES (1, 'Aman', 'Delhi'), (2, 'Riya', 'Noida');
INSERT INTO Salespersons VALUES (11, 'Neha'), (12, 'Karan');
INSERT INTO Products     VALUES ('P1', 'Keyboard', 800),
                                ('P2', 'Mouse',    400),
                                ('P3', 'Monitor', 6500);
INSERT INTO Orders       VALUES (101, '2026-10-01', 1, 11),
                                (102, '2026-10-02', 2, 12);
INSERT INTO OrderDetails VALUES (101, 'P1', 2), (101, 'P2', 1),
                                (102, 'P1', 1), (102, 'P3', 3);

-- ---------- Verification 1: Lossless join ----------
SELECT o.OrderID, od.ProductID, o.OrderDate,
       c.CustomerID, c.CustomerName, c.CustomerCity,
       s.SalespersonID, s.SalespersonName,
       p.ProductName, p.UnitPrice, od.Quantity
FROM Orders o
JOIN Customers    c  ON c.CustomerID    = o.CustomerID
JOIN Salespersons s  ON s.SalespersonID = o.SalespersonID
JOIN OrderDetails od ON od.OrderID      = o.OrderID
JOIN Products     p  ON p.ProductID     = od.ProductID
ORDER BY o.OrderID, od.ProductID;

-- Row count comparison (expected: 4 and 4)
SELECT COUNT(*) AS OriginalRows FROM Sales_1NF;

SELECT COUNT(*) AS ReconstructedRows
FROM Orders o
JOIN OrderDetails od ON od.OrderID      = o.OrderID
JOIN Customers    c  ON c.CustomerID    = o.CustomerID
JOIN Salespersons s  ON s.SalespersonID = o.SalespersonID
JOIN Products     p  ON p.ProductID     = od.ProductID;

-- ---------- Verification 2: Dependency preservation (each should return an empty set) ----------
-- CustomerID -> CustomerName, CustomerCity
SELECT CustomerID FROM Customers
GROUP BY CustomerID
HAVING COUNT(DISTINCT CustomerName) > 1 OR COUNT(DISTINCT CustomerCity) > 1;

-- ProductID -> ProductName, UnitPrice
SELECT ProductID FROM Products
GROUP BY ProductID
HAVING COUNT(DISTINCT ProductName) > 1 OR COUNT(DISTINCT UnitPrice) > 1;

-- OrderID -> OrderDate, CustomerID, SalespersonID
SELECT OrderID FROM Orders
GROUP BY OrderID
HAVING COUNT(*) > 1;

-- SalespersonID -> SalespersonName
SELECT SalespersonID FROM Salespersons
GROUP BY SalespersonID
HAVING COUNT(*) > 1;

/* OBSERVATION
   1NF  : One row per order-product combination; no comma-separated list.
   2NF  : Order-level and product-level facts separated from the line item.
   3NF / BCNF : Customer, salesperson and product facts stored once; every
                determinant is a key.
   Lossless join : Original count = 4, reconstructed count = 4.
   Dependency preservation : Violation queries return empty sets; PK/FK
                constraints enforce the dependencies. */

/* RESULT
   The Sales relation was normalized from UNF to 1NF, 2NF, 3NF and BCNF.
   Lossless join and dependency preservation were verified using SQL. */
