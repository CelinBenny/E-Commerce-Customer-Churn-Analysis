-- E-COMMERCE CUSTOMER CHURN ANALYSIS
-- =====================================================

-- =====================================================
-- DATABASE CREATION
-- =====================================================
DROP DATABASE IF EXISTS ecomm;
CREATE DATABASE ecomm;
USE ecomm;


-- TABLE CREATION
-- =====================================================
CREATE TABLE customer_churn(
    CustomerID                  INT PRIMARY KEY,
    Churn                       BIT,
    Tenure                      INT,
    PreferredLoginDevice        VARCHAR(20),
    CityTier                    INT,
    WarehouseToHome             INT,
    PreferredPaymentMode        VARCHAR(20),
    Gender                      ENUM('Male','Female'),
    HourSpendOnApp              INT,
    NumberOfDeviceRegistered    INT,
    PreferedOrderCat            VARCHAR(20),
    SatisfactionScore           INT,
    MaritalStatus               VARCHAR(10),
    NumberOfAddress             INT,
    Complain                    BIT,
    OrderAmountHikeFromlastYear INT,
    CouponUsed                  INT,
    OrderCount                  INT,
    DaySinceLastOrder           INT,
    CashbackAmount              INT
);

-- DATA CLEANING
-- =====================================================

-- Count Total Customers
SELECT COUNT(*) AS total_customers
FROM customer_churn;

-- CHECKING MISSING VALUES
-- -----------------------------------------------------

SELECT
    SUM(WarehouseToHome IS NULL) AS missing_WarehouseToHome,
    SUM(HourSpendOnApp IS NULL) AS missing_HourSpendOnApp,
    SUM(OrderAmountHikeFromlastYear IS NULL) AS missing_OrderAmountHike,
    SUM(DaySinceLastOrder IS NULL) AS missing_DaySinceLastOrder
FROM customer_churn;


SELECT
    SUM(Tenure IS NULL) AS missing_Tenure,
    SUM(CouponUsed IS NULL) AS missing_CouponUsed,
    SUM(OrderCount IS NULL) AS missing_OrderCount
FROM customer_churn;

-- IMPUTING MEAN VALUES
-- -----------------------------------------------------

UPDATE customer_churn
SET WarehouseToHome = (
    SELECT avg_val
    FROM (
        SELECT ROUND(AVG(WarehouseToHome)) AS avg_val
        FROM customer_churn
        WHERE WarehouseToHome IS NOT NULL
    ) AS temp
)
WHERE WarehouseToHome IS NULL;

UPDATE customer_churn
SET HourSpendOnApp = (
    SELECT avg_val
    FROM (
        SELECT ROUND(AVG(HourSpendOnApp)) AS avg_val
        FROM customer_churn
        WHERE HourSpendOnApp IS NOT NULL
    ) AS temp
)
WHERE HourSpendOnApp IS NULL;


UPDATE customer_churn
SET OrderAmountHikeFromlastYear = (
    SELECT avg_val
    FROM (
        SELECT ROUND(AVG(OrderAmountHikeFromlastYear)) AS avg_val
        FROM customer_churn
        WHERE OrderAmountHikeFromlastYear IS NOT NULL
    ) AS temp
)
WHERE OrderAmountHikeFromlastYear IS NULL;

UPDATE customer_churn
SET DaySinceLastOrder = (
    SELECT avg_val
    FROM (
        SELECT ROUND(AVG(DaySinceLastOrder)) AS avg_val
        FROM customer_churn
        WHERE DaySinceLastOrder IS NOT NULL
    ) AS temp
)
WHERE DaySinceLastOrder IS NULL;

-- FINDING MODE VALUES
-- -----------------------------------------------------

SELECT Tenure, COUNT(*) AS freq
FROM customer_churn
GROUP BY Tenure
ORDER BY freq DESC;


SELECT CouponUsed, COUNT(*) AS freq
FROM customer_churn
GROUP BY CouponUsed
ORDER BY freq DESC;


SELECT OrderCount, COUNT(*) AS freq
FROM customer_churn
GROUP BY OrderCount
ORDER BY freq DESC;

-- IMPUTING MODE VALUES
-- -----------------------------------------------------

UPDATE customer_churn
SET Tenure = (
    SELECT mode_val
    FROM (
        SELECT Tenure AS mode_val
        FROM customer_churn
        WHERE Tenure IS NOT NULL
        GROUP BY Tenure
        ORDER BY COUNT(*) DESC
        LIMIT 1
    ) AS temp
)
WHERE Tenure IS NULL;

UPDATE customer_churn
SET CouponUsed = (
    SELECT mode_val
    FROM (
        SELECT CouponUsed AS mode_val
        FROM customer_churn
        WHERE CouponUsed IS NOT NULL
        GROUP BY CouponUsed
        ORDER BY COUNT(*) DESC
        LIMIT 1
    ) AS temp
)
WHERE CouponUsed IS NULL;


UPDATE customer_churn
SET OrderCount = (
    SELECT mode_val
    FROM (
        SELECT OrderCount AS mode_val
        FROM customer_churn
        WHERE OrderCount IS NOT NULL
        GROUP BY OrderCount
        ORDER BY COUNT(*) DESC
        LIMIT 1
    ) AS temp
)
WHERE OrderCount IS NULL;

-- HANDLING OUTLIERS
-- -----------------------------------------------------

DELETE FROM customer_churn
WHERE WarehouseToHome > 100;

-- DATA STANDARDIZATION
-- -----------------------------------------------------

UPDATE customer_churn
SET PreferredLoginDevice = 'Mobile Phone'
WHERE PreferredLoginDevice = 'Phone';


UPDATE customer_churn
SET PreferedOrderCat = 'Mobile Phone'
WHERE PreferedOrderCat = 'Mobile';


UPDATE customer_churn
SET PreferredPaymentMode = 'Cash on Delivery'
WHERE PreferredPaymentMode = 'COD';


UPDATE customer_churn
SET PreferredPaymentMode = 'Credit Card'
WHERE PreferredPaymentMode = 'CC';

-- =====================================================
-- DATA TRANSFORMATION
-- =====================================================

-- COLUMN RENAMING
-- -----------------------------------------------------

ALTER TABLE customer_churn
RENAME COLUMN PreferedOrderCat TO PreferredOrderCat;


ALTER TABLE customer_churn
RENAME COLUMN HourSpendOnApp TO HoursSpentOnApp;

-- CREATING NEW COLUMNS
-- -----------------------------------------------------

ALTER TABLE customer_churn
ADD COLUMN ComplaintReceived VARCHAR(3);


UPDATE customer_churn
SET ComplaintReceived =
    CASE
        WHEN Complain = 1 THEN 'Yes'
        ELSE 'No'
    END;

ALTER TABLE customer_churn
ADD COLUMN ChurnStatus VARCHAR(10);


UPDATE customer_churn
SET ChurnStatus =
    CASE
        WHEN Churn = 1 THEN 'Churned'
        ELSE 'Active'
    END;

-- DROPPING UNUSED COLUMNS
-- -----------------------------------------------------

ALTER TABLE customer_churn
DROP COLUMN Churn,
DROP COLUMN Complain;

-- DATA ANALYSIS
-- =====================================================

-- Count of Churned and Active Customers
SELECT 
    ChurnStatus,
    COUNT(*) AS CustomerCount
FROM customer_churn
GROUP BY ChurnStatus;

-- Average Tenure and Total Cashback of Churned Customers
SELECT
    ROUND(AVG(Tenure), 2) AS AvgTenure,
    SUM(CashbackAmount) AS TotalCashback
FROM customer_churn
WHERE ChurnStatus = 'Churned';

-- Percentage of Churned Customers Who Complained
SELECT
    ROUND(
        (COUNT(CASE WHEN ComplaintReceived = 'Yes' THEN 1 END) * 100.0) 
        / COUNT(*),
        2
    ) AS Percentage_Churned_Customers_Complained
FROM customer_churn
WHERE ChurnStatus = 'Churned';

-- City Tier with Highest Churn in Laptop & Accessory Category
SELECT
    CityTier,
    COUNT(*) AS ChurnedCustomerCount
FROM customer_churn
WHERE ChurnStatus = 'Churned'
  AND PreferredOrderCat = 'Laptop & Accessory'
GROUP BY CityTier
ORDER BY ChurnedCustomerCount DESC
LIMIT 1;

-- Most Preferred Payment Mode Among Active Customers
SELECT
    PreferredPaymentMode,
    COUNT(*) AS CustomerCount
FROM customer_churn
WHERE ChurnStatus = 'Active'
GROUP BY PreferredPaymentMode
ORDER BY CustomerCount DESC
LIMIT 1;

-- Total Order Amount Hike for Single Customers Using Mobile Phone
SELECT
    SUM(OrderAmountHikeFromlastYear) AS TotalOrderAmountHike
FROM customer_churn
WHERE MaritalStatus = 'Single'
  AND PreferredOrderCat = 'Mobile Phone';

-- Average Devices Registered for UPI Users
SELECT
    ROUND(AVG(NumberOfDeviceRegistered), 2) AS AvgDevicesRegistered
FROM customer_churn
WHERE PreferredPaymentMode = 'UPI';

-- City Tier with Highest Customers
SELECT
    CityTier,
    COUNT(*) AS CustomerCount
FROM customer_churn
GROUP BY CityTier
ORDER BY CustomerCount DESC
LIMIT 1;

-- Gender with Highest Coupon Usage
SELECT
    Gender,
    SUM(CouponUsed) AS TotalCouponsUsed
FROM customer_churn
GROUP BY Gender
ORDER BY TotalCouponsUsed DESC
LIMIT 1;

-- Maximum Hours Spent on App by Category
SELECT
    PreferredOrderCat,
    COUNT(*) AS CustomerCount,
    MAX(HoursSpentOnApp) AS MaxHoursSpent
FROM customer_churn
GROUP BY PreferredOrderCat;

-- Total Order Count for Credit Card Users with Highest Satisfaction
SELECT
    SUM(OrderCount) AS TotalOrderCount
FROM customer_churn
WHERE PreferredPaymentMode = 'Credit Card'
  AND SatisfactionScore = (
      SELECT MAX(SatisfactionScore)
      FROM customer_churn
  );

-- Average Satisfaction Score of Complained Customers
SELECT
    ROUND(AVG(SatisfactionScore), 2) AS AvgSatisfactionScore
FROM customer_churn
WHERE ComplaintReceived = 'Yes';

-- Preferred Categories Among Customers Using More Than 5 Coupons
SELECT
    PreferredOrderCat,
    COUNT(*) AS CustomerCount
FROM customer_churn
WHERE CouponUsed > 5
GROUP BY PreferredOrderCat
ORDER BY CustomerCount DESC;

-- Top 3 Categories with Highest Cashback
SELECT
    PreferredOrderCat,
    ROUND(AVG(CashbackAmount), 2) AS AvgCashback
FROM customer_churn
GROUP BY PreferredOrderCat
ORDER BY AvgCashback DESC
LIMIT 3;
