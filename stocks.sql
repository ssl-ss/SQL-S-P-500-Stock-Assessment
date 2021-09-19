/*
Create, organize, and normalize (if necessary) tables 
*/
#Before normalization 
SELECT * FROM constituents;

#create the sector table in 3NF 
CREATE TABLE sector AS
	(SELECT *, 
	ROW_NUMBER() OVER(ORDER BY Sector) Sector_ID FROM
	(SELECT DISTINCT Sector FROM project.constituents) tmp);

SELECT * FROM sector;

#separate sector from the original table --> 3NF 
CREATE TABLE NF_constituents AS 
	(SELECT ID, Symbol, `Name`,
	CASE 
		WHEN Sector = "Consumer Discretionary" THEN 1
		WHEN Sector = "Consumer Staples" THEN 2
		WHEN Sector = "Energy" THEN 3
		WHEN Sector = "Financials" THEN 4
		WHEN Sector = "Health Care" THEN 5
		WHEN Sector = "Industrials" THEN 6
		WHEN Sector = "Information Technology" THEN 7
		WHEN Sector = "Materials" THEN 8
		WHEN Sector = "Real Estate" THEN 9
		WHEN Sector = "Telecommunication Services" THEN 10
		ELSE 11
	END AS Sector_ID	
	FROM constituents);

SELECT * FROM NF_constituents;

CREATE TABLE `project`.`constituents_financials` (
  `Symbol` VARCHAR(15) NOT NULL,
  `Price` DECIMAL(2) NULL,
  `Price/Earnings` DECIMAL(2) NULL,
  `Price/Book` DECIMAL(2) NULL,
  `Dividend Yield` DECIMAL(4) NULL,
  `Earnings/Share` DECIMAL(2) NULL,
  PRIMARY KEY (`Symbol`));

#Import data from local 
SELECT * FROM constituents_financials;
#TRUNCATE TABLE constituents_financials;

#Create the employee table 
CREATE TABLE `project`.`Employee` (
  `Symbol` VARCHAR(15) NOT NULL,
  `Employees` INT NULL,
  PRIMARY KEY (`Symbol`));

#Import Data from local 
SELECT * FROM Employee

CREATE TABLE `project`.`company_info`(
  `Symbol` VARCHAR(15) NOT NULL,
  `Headquarters` VARCHAR(50) NULL,
  `Date Added` DATETIME NULL,
  `Founding Year` INT NULL,
  PRIMARY KEY (`Symbol`));

#Import Data from local
SELECT * FROM company_info;

CREATE TABLE `project`.`company_weights` (
  `Symbol` VARCHAR(15) NOT NULL,
  `Rank` INT NULL,
  `Weight` DECIMAL(5,2) NULL,
  PRIMARY KEY (`Symbol`));

#Import Data from local
SELECT * FROM company_weights;

/*
Gather info about the companies 
*/

#Total number of companies included:  
SELECT COUNT(DISTINCT Symbol) FROM NF_constituents;
-- 505 

#How many companies are in each sector?
SELECT s.sector, tmp.num FROM 
sector s
JOIN 
(SELECT Sector_ID, COUNT(Sector_ID) AS num 
FROM NF_constituents c
GROUP BY 1) tmp
USING (Sector_ID); 

#Create number of companies by sector table 
CREATE TABLE company_by_sector AS 
(SELECT s.sector, tmp.num FROM 
sector s
JOIN 
(SELECT Sector_ID, COUNT(Sector_ID) AS num 
FROM NF_constituents c
GROUP BY 1) tmp
USING (Sector_ID));

#Which sector has the most number of companies?
SELECT s.sector, tmp.num FROM 
sector s
JOIN 
(SELECT Sector_ID, COUNT(Sector_ID) AS num 
FROM NF_constituents c
GROUP BY 1) tmp
USING (Sector_ID)
ORDER BY 2 DESC
LIMIT 1;
-- Consumer Discretionary 84

#What are the companies within that sector? 
SELECT c.Name FROM NF_constituents c
JOIN sector s
WHERE  s.Sector = "Consumer Discretionary" 
AND s.Sector_ID = c.Sector_ID;

#Which one has the least? 
SELECT s.sector, tmp.num FROM 
sector s
JOIN 
(SELECT Sector_ID, COUNT(Sector_ID) AS num 
FROM NF_constituents c
GROUP BY 1) tmp
USING (Sector_ID)
ORDER BY 2 ASC
LIMIT 1;
-- Telecommunication Services 3

#What are the companies within that sector? 
SELECT c.Name FROM NF_constituents c
JOIN sector s
WHERE  s.Sector = "Telecommunication Services" 
AND s.Sector_ID = c.Sector_ID;

#How many companies have employee information? 
SELECT COUNT(*) FROM Employee
JOIN NF_constituents
USING(Symbol);
-- 428

    
#Show the first 5 companies that have most employees
SELECT * FROM NF_constituents c
JOIN Employee e 
USING (Symbol)
ORDER BY e.Employees DESC
LIMIT 5;

#Which company has the most / least number of employee?
SELECT Symbol, Name, Employees
FROM NF_constituents
JOIN Employee
USING (Symbol)
WHERE Employees IN (SELECT MAX(Employees) FROM Employee);
-- WMT Wal-Mart Stores 2200000

SELECT Symbol, Name, Employees
FROM NF_constituents
JOIN Employee
USING (Symbol)
WHERE Employees IN (SELECT MIN(Employees) FROM Employee);
-- HST Host Hotels & Resorts 175
  
#What is the mean, mode, and median number of employee for all companies?

SELECT ROUND(AVG(Employees),0) AS mean FROM 
(SELECT * FROM Employee
JOIN NF_constituents
USING(Symbol)) tmp ; 
-- mean: 61340


SELECT Employees AS mode, COUNT(Employees) as freq FROM 
(SELECT * FROM Employee
JOIN NF_constituents
USING(Symbol)) tmp 
GROUP BY Employees
ORDER BY 2 DESC
LIMIT 1; 
-- mode: 18000 with a frequency of 5

WITH cte AS 
(SELECT * FROM Employee
JOIN NF_constituents
USING(Symbol))

SELECT Employees AS median FROM 
(SELECT *,
ROW_NUMBER() OVER(ORDER BY Employees ASC, ID ASC) rk,
ROW_NUMBER() OVER(ORDER BY Employees DESC, ID DESC) rrk 
FROM cte) tmp
WHERE ABS(CAST(rk AS SIGNED) - CAST(rrk AS SIGNED)) BETWEEN 0 AND 1; 
-- median: 22000;21000

#What is the percentage of companies having a number of employee that is 
#euqal to or above average?
WITH cte AS 
(SELECT * FROM Employee
JOIN NF_constituents
USING(Symbol)),
cte2 AS 
(SELECT Symbol, 
CASE WHEN Employees >= 61340 THEN 1 ELSE 0 END AS above
FROM cte)

SELECT ROUND(SUM(above)/COUNT(*) * 100,2) AS Percentage FROM cte2;
-- 24.30 

#Which sector has the most employees?
SELECT Sector, SUM(Employees) AS total_employee FROM
(SELECT Symbol, Employees, Sector FROM NF_constituents 
JOIN Employee
USING(Symbol)
JOIN sector 
USING (Sector_ID)) tmp 
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;
-- Consumer Discretionary total_employee: 7235415


CREATE TABLE join_cons_info AS
	(SELECT * FROM company_info
	JOIN NF_constituents
	USING(Symbol));

#Ater joining company_info and NF_constituents 
#Only 422 companies are remained 
SELECT COUNT(*) FROM join_cons_info;

#How many companies are founded before 2000?
SELECT COUNT(*) FROM join_cons_info
WHERE `Founding Year` <= 2000; 
-- 388

#Which company(s) is the earliest company that was added to the list?
SELECT j.Symbol, c.Name, j.`Date Added` FROM join_cons_info j 
JOIN NF_constituents c
USING(Symbol)
WHERE j.`Date Added` IN
(SELECT MIN(STR_TO_DATE(`Date Added`,'%Y-%m-%d')) FROM join_cons_info);

#Which company(s) is the most recent one? 
SELECT j.Symbol, c.Name, j.`Date Added` FROM join_cons_info j 
JOIN NF_constituents c
USING(Symbol)
WHERE j.`Date Added` IN
(SELECT MAX(STR_TO_DATE(`Date Added`,'%Y-%m-%d')) FROM join_cons_info);

#Show the first 5 companies that carry the most stock weights
SELECT * FROM company_weights
ORDER BY `RANK` ASC
LIMIT 5; 

#JOIN company_weights table and NF_constituents table 
CREATE TABlE weight_cons AS
	(SELECT Symbol, `Rank`, Weight, `Name`, Sector_ID FROM company_weights
	JOIN NF_constituents
	USING(Symbol)); 

SELECT * FROM weight_cons;
#What are the weights by each sector? 
SELECT s.Sector, SUM(w.Weight) AS total_weight FROM weight_cons w
JOIN sector s
USING(Sector_ID)
GROUP BY 1
ORDER BY 2 DESC; 

#How many companies have their headquarters at California or New York? What are they? 
SELECT COUNT(Headquarter) AS total 
FROM company_info
WHERE Headquarter = " California" OR Headquarter = " New York";
-- 129

SELECT Symbol, `Name`, Headquarter 
FROM company_info
JOIN NF_constituents
USING(Symbol)
WHERE Headquarter = " California" OR Headquarter = " New York";

#How many distinct headquarter locations are there? What are they?
SELECT COUNT(DISTINCT Headquarter) FROM 
	(SELECT * FROM company_info
	JOIN NF_constituents 
	USING(Symbol))tmp; 
-- 44
SELECT DISTINCT Headquarter FROM 
	(SELECT * FROM company_info
	JOIN NF_constituents 
	USING(Symbol))tmp; 

#How many companies are at each distinct location? 
CREATE TABLE company_by_location AS 
(SELECT DISTINCT Headquarter, COUNT(Symbol) AS Total
FROM 
(SELECT * FROM company_info
 JOIN NF_constituents 
 USING(Symbol)) tmp
GROUP BY 1
ORDER BY 1); 

SELECT * FROM company_by_location;

#What are the locations that have the max/min number of companies? 
SELECT * FROM company_by_location
WHERE Total = (SELECT MAX(Total) FROM company_by_location)
UNION
SELECT * FROM company_by_location
WHERE Total = (SELECT MIN(Total) FROM company_by_location);

/*
	Stock information 
*/

# How many companies have financial info in the table? 
SELECT COUNT(*) FROM constituents_financials;
-- 495

#How many companies have a P/E ratio that is equal to or below 25?
SELECT COUNT(Symbol) AS total FROM constituents_financials
WHERE `Price/Earnings` <= 25;
-- 362

#What is the percentage? 
SELECT ROUND(SUM(CASE WHEN `Price/Earnings` <= 25 THEN 1 ELSE 0 END) / COUNT(*) * 100,2) AS percentage
FROM constituents_financials;
-- 73.13

#What are they? 
SELECT `Name` FROM constituents_financials
LEFT JOIN NF_constituents 
USING (Symbol)
WHERE `Price/Earnings` <= 25;


#How many companies have a P/B ratio that is below 3.0?
SELECT COUNT(Symbol) AS total FROM constituents_financials
WHERE `Price/Book` < 3;
-- 215

#How about below 1.0? 
SELECT COUNT(Symbol) AS total FROM constituents_financials
WHERE `Price/Book` < 1;
-- 18

#What is the percentage for each? 
SELECT ROUND(SUM(CASE WHEN `Price/Book` < 3 THEN 1 ELSE 0 END) / COUNT(*) * 100,2) AS percentage
FROM constituents_financials;
-- 43.43 for under 3.0

SELECT ROUND(SUM(CASE WHEN `Price/Book` < 1 THEN 1 ELSE 0 END) / COUNT(*) * 100,2) AS percentage
FROM constituents_financials;
-- 3.64 for under 1.0

#What are the companies under each category? 
-- under 3.0 
SELECT `Name` FROM constituents_financials
LEFT JOIN NF_constituents 
USING (Symbol)
WHERE `Price/Book` < 3;

-- under 1.0
SELECT `Name` FROM constituents_financials
LEFT JOIN NF_constituents 
USING (Symbol)
WHERE `Price/Book` < 1;

#How many companies have a dividend yield that is between 2% and 6% ?
SELECT COUNT(Symbol) AS total FROM constituents_financials
WHERE `Dividend Yield` BETWEEN 2 AND 6;
-- 199

#What is the percentage? 
SELECT ROUND(SUM(CASE WHEN `Dividend Yield` BETWEEN 2 AND 6 THEN 1 ELSE 0 END) / COUNT(*) * 100,2) AS percentage
FROM constituents_financials;
-- 40.20

#What are the companies? 
SELECT `Name` FROM constituents_financials
LEFT JOIN NF_constituents 
USING (Symbol)
WHERE `Dividend Yield` BETWEEN 2 AND 6;

#Find companies and their sectors that satisfy all 3 criterion (i.e. P/E, P/B, Dividend yield) with P/B < 3 
SELECT `Name`, Sector FROM NF_constituents
RIGHT JOIN constituents_financials
USING (Symbol)
JOIN sector
USING(Sector_ID)
WHERE (`Price/Earnings` <= 25) AND (`Price/Book` < 3) AND (`Dividend Yield` BETWEEN 2 AND 6)
ORDER BY Sector;

#Create a table named 
SELECT * FROM satisfy_criterion_company;

#GROUP BY the number of companies that satisfies all 3 criterion within each sector 
SELECT Sector, COUNT(Name) AS freq FROM NF_constituents
RIGHT JOIN constituents_financials
USING (Symbol)
JOIN sector
USING(Sector_ID)
WHERE (`Price/Earnings` <= 25) AND (`Price/Book` < 3) AND (`Dividend Yield` BETWEEN 2 AND 6)
GROUP BY 1
ORDER BY 2 DESC;
-- seems like utilities stocks are safe to buy 

#Find the top 10 companies in each sector that have the largest EPS.  
WITH cte AS
(SELECT * FROM NF_constituents 
JOIN constituents_financials f
USING(Symbol)
JOIN sector s 
USING(Sector_ID)),
cte2 AS 
(SELECT Sector, `Name`, `Earnings/Share`,
RANK() OVER(PARTITION BY Sector ORDER BY `Earnings/Share`DESC) rk 
FROM cte
ORDER BY 1 ASC, 3 DESC, 2)

SELECT * FROM cte2 
WHERE rk BETWEEN 1 AND 10;

#create a table for the top 10 EPS companies by sector named "top 10 eps by sector"
SELECT * FROM `top 10 eps by sector`;

#Find companies that are in both 'satisfy_criterion_company' table and 'top 10 eps by sector table'
SELECT * FROM satisfy_criterion_company
JOIN `top 10 eps by sector`
USING (Name);
-- good candidates to buy 

#create a table 
CREATE TABLE good_candidates AS 
(SELECT t.Sector, t.Name, t.`Earnings/Share`, t.rk FROM satisfy_criterion_company s
JOIN `top 10 eps by sector` t
USING (Name));

SELECT * FROM good_candidates;
