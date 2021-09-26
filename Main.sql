/*
	Create Tables for Database  
*/

CREATE TABLE `S&P 500 stock`.`S&P_index` (
  `Name` VARCHAR(50) NOT NULL,
  `Symbol` VARCHAR(45) NOT NULL,
  `Sector` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`Name`, `Symbol`),
  UNIQUE INDEX `Name_UNIQUE` (`Name` ASC) VISIBLE);

SELECT * FROM `S&P_index`;

CREATE TABLE `S&P 500 stock`.`company_info` (
  `Symbol` VARCHAR(25) NOT NULL,
  `Founding Year` INT NULL,
  PRIMARY KEY (`Symbol`));
  
SELECT * FROM `company_info`;
  
CREATE TABLE `S&P 500 stock`.`company_headquarter` (
  `Symbol` VARCHAR(25) NOT NULL,
  `Headquarter` VARCHAR(45) NULL,
  PRIMARY KEY (`Symbol`));
  
  SELECT * FROM `company_headquarter`;
  
  CREATE TABLE `S&P 500 stock`.`company_financials` (
  `Symbol` VARCHAR(25) NOT NULL,
  `Profit` FLOAT NULL,
  `DY` FLOAT NULL,
  `PE` FLOAT NULL,
  `PS` FLOAT NULL,
  `PB` FLOAT NULL,
  `DE` FLOAT NULL,
  `FCF` FLOAT NULL,
  PRIMARY KEY (`Symbol`),
  UNIQUE INDEX `Symbol_UNIQUE` (`Symbol` ASC) VISIBLE);
  
  SELECT * FROM `company_financials`;
  
  CREATE TABLE `S&P 500 stock`.`company_employees` (
  `Symbol` VARCHAR(25) NOT NULL,
  `Employee` INT NULL,
  PRIMARY KEY (`Symbol`),
  UNIQUE INDEX `Symbol_UNIQUE` (`Symbol` ASC) VISIBLE);
  
  SELECT * FROM `company_employees`;
  
  CREATE TABLE `S&P 500 stock`.`stock_price` (
  `Symbol` VARCHAR(25) NOT NULL,
  `Price` FLOAT NULL,
  PRIMARY KEY (`Symbol`),
  UNIQUE INDEX `Symbol_UNIQUE` (`Symbol` ASC) VISIBLE);
  
  SELECT * FROM `stock_price`;
  
  CREATE TABLE `S&P 500 stock`.`company_weights` (
  `Name` VARCHAR(50) NOT NULL,
  `Weight` DECIMAL(4,2) NULL,
  PRIMARY KEY (`Name`),
  UNIQUE INDEX `Name_UNIQUE` (`Name` ASC) VISIBLE);
  
  SELECT * FROM `company_weights`;
  
  CREATE TABLE `S&P 500 stock`.`company_eps` (
  `Symbol` VARCHAR(25) NOT NULL,
  `EPS2021` FLOAT NULL,
  `EPS2020` FLOAT NULL,
  `EPS2019` FLOAT NULL,
  PRIMARY KEY (`Symbol`));
  
  SELECT * FROM `company_eps`;
  
  CREATE TABLE `S&P 500 stock`.`company_dividends` (
  `Symbol` VARCHAR(25) NOT NULL,
  `DIV2021` FLOAT NULL,
  `DIV2020` FLOAT NULL,
  `DIV2019` FLOAT NULL,
  PRIMARY KEY (`Symbol`));
  
  SELECT * FROM `company_dividends`;

/*
	Normalization 
*/

CREATE TABLE sector AS
	(SELECT *, 
	ROW_NUMBER() OVER(ORDER BY Sector) Sector_ID FROM
	(SELECT DISTINCT Sector FROM `S&P_index`) tmp);

SELECT * FROM sector;

CREATE TABLE company_index AS 
	(SELECT
    ROW_NUMBER() OVER(ORDER BY `Name`) AS ID,
    Symbol, 
	CASE 
		WHEN Sector = "Communication Services" THEN 1
		WHEN Sector = "Consumer Discretionary" THEN 2
		WHEN Sector = "Consumer Staples" THEN 3
		WHEN Sector = "Energy" THEN 4
		WHEN Sector = "Financials" THEN 5
		WHEN Sector = "Health Care" THEN 6
		WHEN Sector = "Industrials" THEN 7
		WHEN Sector = "Information Technology" THEN 8
		WHEN Sector = "Materials" THEN 9
		WHEN Sector = "Real Estate" THEN 10
		ELSE 11
	END AS Sector_ID	
	FROM `S&P_index`);

SELECT * FROM company_index;

/*
	Components of the S&P 500 
*/

# Companies by sector
WITH cte1 AS( 
SELECT s.Sector,tmp.Sector_ID, tmp.Num FROM 
sector s
JOIN 
(SELECT Sector_ID, COUNT(Sector_ID) AS num 
FROM company_index 
GROUP BY 1) tmp
USING (Sector_ID)
ORDER BY 2 DESC),
cte2 AS( 
SELECT Sector, tmp.Percentage FROM sector 
JOIN ( 
SELECT Sector_ID, 
ROUND(COUNT(Sector_ID) / (SELECT COUNT(Sector_ID) FROM company_index) * 100,2)
AS Percentage
FROM company_index
GROUP BY Sector_ID) tmp
USING(Sector_ID)
ORDER BY 2 DESC)

SELECT cte1.Sector_ID, cte1.Sector, cte1.Num, cte2.percentage 
FROM cte1, cte2
WHERE cte1.sector = cte2.Sector
ORDER BY 3 DESC;

# Create a table for company by sector 
CREATE TABLE company_by_sector AS(
WITH cte1 AS( 
SELECT s.Sector,tmp.Sector_ID, tmp.Num FROM 
sector s
JOIN 
(SELECT Sector_ID, COUNT(Sector_ID) AS num 
FROM company_index 
GROUP BY 1) tmp
USING (Sector_ID)
ORDER BY 2 DESC),
cte2 AS( 
SELECT Sector, tmp.Percentage FROM sector 
JOIN ( 
SELECT Sector_ID, 
ROUND(COUNT(Sector_ID) / (SELECT COUNT(Sector_ID) FROM company_index) * 100,2)
AS Percentage
FROM company_index
GROUP BY Sector_ID) tmp
USING(Sector_ID)
ORDER BY 2 DESC)

SELECT cte1.Sector_ID, cte1.Sector, cte1.Num, cte2.percentage 
FROM cte1, cte2
WHERE cte1.sector = cte2.Sector
ORDER BY 3 DESC);

SELECT * FROM company_by_sector;

WITH cte AS 
(SELECT i.Symbol, i.Sector_ID, p.Price,
ROW_NUMBER() OVER(PARTITION BY Sector_ID ORDER BY Price DESC) rk 
From company_index i 
JOIN stock_price p
USING(Symbol)
ORDER BY 2, 3 DESC)

SELECT i.Name, cte.Symbol, cte.Sector_ID, s.Sector, cte.Price FROM cte 
JOIN sector s
USING(Sector_ID)
JOIN `S&P_index` i
USING(Symbol)
WHERE rk BETWEEN 1 AND 3
ORDER BY Sector_ID; 

# Employee number 

-- company with highest number of employee
SELECT Symbol, Name, Employee
FROM `S&P_index`
JOIN company_employees
USING (Symbol)
WHERE Employee IN (SELECT MAX(Employee) FROM company_employees);
-- WMT Walmart Inc. 2300000

-- company with lowest number of employee
SELECT Symbol, Name, Employee
FROM `S&P_index`
JOIN company_employees
USING (Symbol)
WHERE Employee IN (SELECT MIN(Employee) FROM company_employees);
-- HST Host Hotels & Resorts Inc. 163

# Employees by sector 
SELECT Sector, SUM(Employee) AS total_employee FROM
(SELECT Symbol, Employee, Sector 
FROM company_index
JOIN company_employees
USING(Symbol)
JOIN sector 
USING (Sector_ID)) tmp 
GROUP BY 1
ORDER BY 2 DESC;

#Create a table for employee by sector 
CREATE TABLE employee_by_sector AS(
SELECT Sector, SUM(Employee) AS total_employee FROM
(SELECT Symbol, Employee, Sector 
FROM company_index
JOIN company_employees
USING(Symbol)
JOIN sector 
USING (Sector_ID)) tmp 
GROUP BY 1
ORDER BY 2 DESC);

SELECT * FROM employee_by_sector;

# Founding Year & Headquarters 

-- How many companies are founded after 2000?
SELECT COUNT(*) FROM company_info
WHERE `Founding Year` > 2000; 
-- 53

-- How many companies are founded before 1950?
SELECT COUNT(*) FROM company_info
WHERE `Founding Year` < 1950; 
-- 196

-- Company by founding year
CREATE TABLE company_by_year AS(
WITH cte1 AS( 
SELECT 
	CASE 
		WHEN Num = 0 THEN 1800
        WHEN Num = 1 THEN 1810
        WHEN Num = 2 THEN 1820
        WHEN Num = 3 THEN 1830
        WHEN Num = 4 THEN 1840
        WHEN Num = 5 THEN 1850
        WHEN Num = 6 THEN 1860
        WHEN Num = 7 THEN 1870
        WHEN Num = 8 THEN 1880
        WHEN Num = 9 THEN 1890
	END AS `Founding Year`,
SUM(Total) AS Total FROM
(SELECT `Founding Year`, LEFT(RIGHT(`Founding Year`,2),1) AS Num, COUNT(Symbol) AS TOTAL FROM company_info
WHERE `Founding Year` BETWEEN 1800 AND 1899
GROUP BY 1) tmp
GROUP BY Num),
cte2 AS( 
SELECT 
	CASE 
		WHEN Num = 0 THEN 1900
        WHEN Num = 1 THEN 1910
        WHEN Num = 2 THEN 1920
        WHEN Num = 3 THEN 1930
        WHEN Num = 4 THEN 1940
        WHEN Num = 5 THEN 1950
        WHEN Num = 6 THEN 1960
        WHEN Num = 7 THEN 1970
        WHEN Num = 8 THEN 1980
        WHEN Num = 9 THEN 1990
	END AS `Founding Year`,
SUM(Total) AS Total FROM
(SELECT `Founding Year`, LEFT(RIGHT(`Founding Year`,2),1) AS Num, COUNT(Symbol) AS TOTAL FROM company_info
WHERE `Founding Year` BETWEEN 1900 AND 1999
GROUP BY 1) tmp
GROUP BY Num),
cte3 AS( 
SELECT 
	CASE 
		WHEN Num = 0 THEN 2000
        WHEN Num = 1 THEN 2010
        WHEN Num = 2 THEN 2020
        WHEN Num = 3 THEN 2030
        WHEN Num = 4 THEN 2040
        WHEN Num = 5 THEN 2050
        WHEN Num = 6 THEN 2060
        WHEN Num = 7 THEN 2070
        WHEN Num = 8 THEN 2080
        WHEN Num = 9 THEN 2090
	END AS `Founding Year`,
SUM(Total) AS Total FROM
(SELECT `Founding Year`, LEFT(RIGHT(`Founding Year`,2),1) AS Num, COUNT(Symbol) AS TOTAL FROM company_info
WHERE `Founding Year` BETWEEN 2000 AND 2099
GROUP BY 1) tmp
GROUP BY Num)

SELECT * FROM cte1
UNION
SELECT * FROM cte2
UNION 
SELECT * FROM cte3
ORDER BY `Founding Year`);

-- How many companies have their headquarters located at Illinois, California or New York State?
SELECT COUNT(Headquarter) AS total 
FROM company_headquarter
WHERE Headquarter = " California" OR Headquarter = " New York"
OR Headquarter = " Illinois";
-- 164

-- Which companies were founded at Illinois?
SELECT s.Name FROM company_headquarter h
JOIN `S&P_index` s 
USING(Symbol)
WHERE h.Headquarter = " Illinois";

-- How many distinct headquarter locations are there?
SELECT COUNT(DISTINCT Headquarter) FROM company_headquarter;
-- 45

-- Create table companies by headquarter 
CREATE TABLE company_by_headquarter AS (
SELECT Headquarter, COUNT(Symbol) FROM company_headquarter
GROUP BY Headquarter);

SELECT * FROM company_by_headquarter;

-- What are the locations that have the most/least number of companies? 
(SELECT Headquarter, COUNT(Symbol) AS Count FROM company_headquarter
GROUP BY Headquarter
ORDER BY 2 DESC
LIMIT 1)
UNION
(SELECT Headquarter, COUNT(Symbol) AS Count FROM company_headquarter
GROUP BY 1
HAVING COUNT(Symbol) = 
(SELECT COUNT(Symbol) FROM company_headquarter
GROUP BY Headquarter
ORDER BY 1 ASC
LIMIT 1));

# Company weights by sector 
CREATE TABLE weights_by_sector AS(
SELECT Sector, SUM(Weight) AS Weight
FROM company_weights
JOIN `S&P_index`
USING(Name)
GROUP BY 1
ORDER BY 2 DESC);

SELECT * FROM weights_by_sector;

/* 
	Stock Prices 
*/

-- Max Stock Price
SELECT Symbol, Name, Price FROM stock_price
JOIN `S&P_index`
USING(Symbol)
WHERE Price = (SELECT MAX(Price) FROM stock_price);
-- NVR NVR Inc. 5031.4

-- Min Stock Price
SELECT Symbol, Name, Price FROM stock_price
JOIN `S&P_index`
USING(Symbol)
WHERE Price = (SELECT MIN(Price) FROM stock_price);
-- AMCR Amcor PLC 11.74

-- Price Range 
SELECT ROUND(MAX(Price) - MIN(Price),2) AS `Range` FROM stock_price;
-- 5019.66

-- Mean 
SELECT ROUND(AVG(PRICE),2) AS Mean FROM stock_price;
-- 203.1

-- Median
SELECT Price AS Median FROM 
(SELECT *,
ROW_NUMBER() OVER(ORDER BY Price ASC, Symbol ASC) rk,
ROW_NUMBER() OVER(ORDER BY price DESC, Symbol DESC) rrk
FROM stock_price) tmp
WHERE ABS(CAST(rk AS SIGNED) - CAST(rrk AS SIGNED)) BETWEEN 0 AND 1;
-- 114.45

-- what percentage of companies have a price that is equal to or above the average?
SELECT ROUND(COUNT(Symbol) / (SELECT COUNT(Symbol) FROM stock_price) * 100,2) AS Percentage
FROM stock_price
WHERE Price >= 203.1;
-- 26.93 

-- Average Price by Sector
CREATE TABLE avg_price_by_sector AS(
SELECT Sector, ROUND(AVG(Price),2) AS Average FROM stock_price
JOIN `S&P_index`
USING(Symbol)
GROUP BY 1
ORDER BY 2 DESC);

SELECT * FROM avg_price_by_sector;

/*
	EPS
*/

SELECT COUNT(*) FROM company_eps
WHERE EPS2019 < EPS2020 AND EPS2020 < EPS2021; 
-- 53

CREATE TABLE eps_satisfied AS(
SELECT * FROM company_eps
WHERE EPS2019 < EPS2020 AND EPS2020 < EPS2021);

SELECT * FROM eps_satisfied;

/*
	P/E
*/

SELECT COUNT(*) FROM company_financials
WHERE PE <= 20;
-- 196

CREATE TABLE pe_satisfied AS(
SELECT Symbol, PE FROM company_financials
WHERE PE <= 20);

SELECT * FROM pe_satisfied;

/*
	P/B
*/

CREATE TABLE pb_satisfied AS(
WITH cte AS(
SELECT ROUND(AVG(PB),2) AS avg, Sector_ID FROM company_financials
JOIN company_index
USING(Symbol)
GROUP BY Sector_ID),
cte1 AS(
SELECT Symbol, PB, Sector_ID FROM company_financials
JOIN company_index
USING (Symbol)) 

SELECT cte1.Symbol, cte1.PB, cte1.Sector_ID FROM cte1, cte
WHERE cte1.PB < cte.avg AND cte1.Sector_ID = cte.Sector_ID);

SELECT COUNT(*) FROM pb_satisfied;
-- 373

/*
	P/S
*/

CREATE TABLE ps_satisfied AS(
WITH cte AS(
SELECT ROUND(AVG(PS),2) AS avg, Sector_ID FROM company_financials
JOIN company_index
USING(Symbol)
GROUP BY Sector_ID),
cte1 AS(
SELECT Symbol, PS, Sector_ID FROM company_financials
JOIN company_index
USING (Symbol)) 

SELECT cte1.Symbol, cte1.PS, cte1.Sector_ID FROM cte1, cte
WHERE cte1.PS < cte.avg AND cte1.Sector_ID = cte.Sector_ID);

SELECT COUNT(*) FROM ps_satisfied;
-- 340

CREATE TABLE dy_satisfied AS(
SELECT Symbol, DY FROM company_financials
WHERE DY > (SELECT ROUND(AVG(DY),2) FROM company_financials));

SELECT COUNT(*) FROM dy_satisfied;
-- 213

/*
	Gross Profit Margin
*/

CREATE TABLE profit_satisfied AS(
WITH cte AS(
SELECT ROUND(AVG(gross_profit_margincol),2) AS avg, Sector_ID FROM gross_profit_margin
JOIN company_index
USING(Symbol)
GROUP BY Sector_ID),
cte1 AS(
SELECT Symbol, gross_profit_margincol, Sector_ID FROM gross_profit_margin
JOIN company_index
USING (Symbol)) 

SELECT cte1.Symbol, cte1.gross_profit_margincol, cte1.Sector_ID FROM cte1, cte
WHERE cte1.gross_profit_margincol < cte.avg AND cte1.Sector_ID = cte.Sector_ID);

SELECT COUNT(*) FROM profit_satisfied;
-- 230

/*
	Dividends
*/

CREATE TABLE div_satisfied AS(
SELECT * FROM company_dividends
WHERE DIV2019 < DIV2020 AND DIV2020 < DIV2021);

SELECT COUNT(*) FROM div_satisfied;
-- 43

CREATE TABLE fcf_satisfied AS(
WITH cte AS(
SELECT ROUND(AVG(FCF),2) AS avg, Sector_ID FROM company_financials
JOIN company_index
USING(Symbol)
GROUP BY Sector_ID),
cte1 AS(
SELECT Symbol, FCF, Sector_ID FROM company_financials
JOIN company_index
USING (Symbol)) 

SELECT cte1.Symbol, cte1.FCF, cte1.Sector_ID FROM cte1, cte
WHERE cte1.FCF > cte.avg AND cte1.Sector_ID = cte.Sector_ID);

SELECT COUNT(*) FROM fcf_satisfied;
-- 206

/*
	D/E 
*/

CREATE TABLE de_satisfied AS(
WITH cte AS(
SELECT ROUND(AVG(DE),2) AS avg, Sector_ID FROM company_financials
JOIN company_index
USING(Symbol)
GROUP BY Sector_ID),
cte1 AS(
SELECT Symbol, DE, Sector_ID FROM company_financials
JOIN company_index
USING (Symbol)) 

SELECT cte1.Symbol, cte1.DE, cte1.Sector_ID FROM cte1, cte
WHERE cte1.DE > cte.avg AND cte1.Sector_ID = cte.Sector_ID);

SELECT COUNT(*) FROM de_satisfied;
-- 94

/*
	Stock Candidates 
*/

With cte AS (
SELECT Symbol FROM eps_satisfied
JOIN pe_satisfied
USING(Symbol)),
cte1 AS (
SELECT * FROM cte
JOIN pb_satisfied
USING(Symbol)),
cte3 AS (
SELECT Symbol FROM cte1
JOIN ps_satisfied
USING(Symbol)),
cte4 AS (
SELECT Symbol FROM cte3
JOIN dy_satisfied
USING(Symbol)),
cte5 AS (
SELECT Symbol FROM cte4
JOIN profit_satisfied
USING(Symbol)),
cte6 AS (
SELECT Symbol FROM cte5
JOIN div_satisfied
USING(Symbol)),
cte7 AS (
SELECT Symbol FROM cte6
JOIN fcf_satisfied
USING(Symbol)),
cte8 AS (
SELECT Symbol FROM cte7
JOIN de_satisfied
USING(Symbol))

SELECT * FROM cte8;
-- No stock left 

-- with only 8 indicators 
With cte AS (
SELECT Symbol FROM eps_satisfied
JOIN pe_satisfied
USING(Symbol)),
cte1 AS (
SELECT * FROM cte
JOIN pb_satisfied
USING(Symbol)),
cte3 AS (
SELECT Symbol FROM cte1
JOIN ps_satisfied
USING(Symbol)),
cte4 AS (
SELECT Symbol FROM cte3
JOIN dy_satisfied
USING(Symbol)),
cte5 AS (
SELECT Symbol FROM cte4
JOIN profit_satisfied
USING(Symbol)),
cte6 AS (
SELECT Symbol FROM cte5
JOIN div_satisfied
USING(Symbol)),
cte7 AS (
SELECT Symbol FROM cte6
JOIN fcf_satisfied
USING(Symbol))

SELECT * FROM cte7
JOIN `S&P_index`
USING(Symbol)
JOIN stock_price
USING(Symbol); 

