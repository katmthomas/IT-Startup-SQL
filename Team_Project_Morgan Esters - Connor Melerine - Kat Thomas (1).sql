--Morgan Esters, Connor Melerine, Kat Thomas

--Project Template:
USE [IT_StartupLive]
SELECT * FROM sys.objects WHERE [type]='U'

--it is good idea to examine the tables first with a select query
SELECT * FROM Employee
SELECT * FROM Department

DELETE FROM Employee
WHERE Employee_ID = 1234

--FR1(Human Resources) (Hint: Review Module 3 sql file to refresh your knowledge)
--Add a third department, Operations, to the Department table
INSERT INTO Department
([Dept_ID], Dept_Name)
VALUES
(3, 'Operations')

--Add executives� data (three individuals including yourselves) into the Employee table
INSERT INTO Employee
(Employee_ID, FirstName, LastName, Gender, Position, Dept_ID, Salary)
VALUES
(3011, 'Morgan', 'Esters', 'F', 'Executive', 1, 100000)

INSERT INTO Employee
(Employee_ID, FirstName, LastName, Gender, Position, Dept_ID, Salary)
VALUES
(3012, 'Katlyn', 'Thomas', 'F', 'Executive', 2, 100000)

INSERT INTO Employee
(Employee_ID, FirstName, LastName, Gender, Position, Dept_ID, Salary)
VALUES
(3013, 'Conner', 'Melerine', 'M', 'Executive', 3, 100000)

--Add another column (called Head) to the Employee table
--assign each department to one executive through Dept_ID
--Hint: You can use UPDATE, SET and CASE construct (Review Module 3 sql file)

ALTER TABLE Employee
ADD [Head] NVARCHAR(20)

UPDATE Employee
SET [Head] = (CASE
				WHEN [Position] = 'Executive' THEN [Dept_ID]
				ELSE 0
				END );
GO

--CREATE TABLES Client, [View], Pricing, TypeClient, AgentRegion (a junction table to connect client and employee tables through regions)

CREATE TABLE Client(
     ClientID INT PRIMARY KEY,
     [Name] NVARCHAR(40),
     TypeID SMALLINT,
     City NVARCHAR(25),
     Region NVARCHAR(6),
     Pricing SMALLINT
);

CREATE TABLE [View](
     ViewID INT PRIMARY KEY,
     ViewDate DATETIME,
     ID INT,
     Device NVARCHAR(25),
     Browser NVARCHAR(30),
     Host VARCHAR(15)
);

CREATE TABLE Pricing (
	PlanNo SMALLINT PRIMARY KEY, 
	PlanName NVARCHAR(15),
	Monthly DECIMAL
);

CREATE TABLE TypeClient (
	TypeName NVARCHAR(50),
	TypeID SMALLINT PRIMARY KEY
);

CREATE TABLE AgentRegion (
	Region NVARCHAR(6) PRIMARY KEY,
	EmployeeID BIGINT
);

---BULK INSERT commands for Client and View and filling other tables with copy and paste
BULK INSERT Client
FROM 'C:\Users\ester\OneDrive\Desktop\Client.csv'
WITH (firstrow= 2, fieldterminator = ',', rowterminator = '\n');
GO

BULK INSERT [View]
FROM 'C:\Users\ester\OneDrive\Desktop\View.txt'
WITH (firstrow= 2, fieldterminator = '\t', rowterminator = '\n');
GO

Select c.ClientID
	, c.[Name]
	, COUNT(v.ID) [Number of Views]
FROM Client c
INNER JOIN [View] v 
	ON c.ClientID = v.ID
WHERE c.Region LIKE 'LA'
GROUP BY c.ClientID, c.[Name]
HAVING COUNT(v.ID) > 50
ORDER BY [Number of Views] DESC

SELECT * FROM Client
SELECT * FROM Pricing

SELECT c.TypeID
	, FORMAT(SUM(Monthly), 'C1') AS TotalFees
FROM Client c
INNER JOIN Pricing p
	ON c.Pricing = p.PlanNo
GROUP BY c.TypeID
ORDER BY SUM(Monthly) DESC

--FR3.Q1: Top ten Spas & Salons that have the highest views.
SELECT TOP 10 COUNT(v.ViewID) AS [Views]
	, c.[Name]
FROM [View] v
JOIN  Client c 
	ON v.ID = c.ClientID
JOIN TypeClient t
	ON t.TypeID = c.TypeID
WHERE t.TypeName LIKE 'Spas%'
GROUP BY c.[Name]
ORDER BY COUNT(v.ViewID) DESC

--FR3.Q2: All clients whose names start OR end with the term �Grill�, along with their cities, 
--subscription fees, and number of views.
SELECT c.[Name]
	, c.City
	, p.Monthly AS [Subscription Fee]
	, COUNT(v.ViewID) AS [Views]
FROM Client c
JOIN Pricing p
	ON c.Pricing = p.PlanNo
JOIN [View] v
	ON c.ClientID = v.ID
WHERE c.[Name] LIKE '%Grill%'
GROUP BY c.[Name], c.City, p.Monthly

--FR3.Q3: Count of client types (Arts & Entertainment, Bakery, Restaurant, etc.) with 
--their average views per client* and average subscription fees per client** sorted with 
--respect to average views per client in descending order.
--Hint: You can use Derived Table (i.e, subquery with an alias)
SELECT Counts.TypeName
	, AVG(Counts.Views) AvgViews
	, AVG(Counts.Monthly) AvgFee
FROM
	(SELECT t.TypeName [TypeName]
		, c.ClientID
		, Count(v.ViewID) [Views]
		, p. Monthly
	FROM Client c 
		JOIN [View] v ON c.ClientID = v.ID
		JOIN Pricing p ON c.Pricing = p.PlanNo
		JOIN TypeClient	 t ON t.TypeID = c.TypeID
	GROUP BY c.ClientID, p.Monthly, t.TypeName) AS Counts 
GROUP BY Counts.TypeName


--FR3.Q4: Cities (along with their regions) for which total number of views 
--for non-restaurant clients are more than 15
--(sorted in a descending order of total number of views).
SELECT c.City + ', ' + c.Region AS [City and Region]
	, COUNT(v.ViewID) AS [Total Views]
FROM Client c
JOIN [View] v
	ON c.ClientID = v.ID
WHERE c. TypeID != 13
GROUP BY c.City, c.Region
HAVING COUNT(v.ViewID) > 15
ORDER BY Count(v.ViewID) DESC

--FR3.Q5: Number of clients and average views per client* with respect to the hosts 
--in a descending order of average views.
SELECT v.Host 
	, COUNT(c.ClientID) AS [Number of Clients]
	, AVG(Counts.[Views]) AS [Average Views]
FROM 
	(SELECT c.ClientID
			, COUNT(v.ViewID) AS [Views]
		FROM Client c 
		JOIN [View] v ON c.ClientID = v.ID
		GROUP BY c.ClientID) AS Counts
JOIN [View] v ON Counts.[Views] = v.ViewID
JOIN Client c ON c.ClientID = v.ID
GROUP BY v.Host
ORDER BY AVG(Counts.[Views]) DESC


--FR3.Q6: Number of clients, their total fees**, total views, and average fees per view** 
--w.r.to regions, sorted in descending order of average fees per views.
--Hint: You can use Derived Table (i.e, subquery with an alias)
SELECT COUNT(c.ClientID) AS [Number of Clients]
	, SUM(p.Monthly) AS [Total Fees]
	, COUNT(v.ViewID) AS [Total Views]
	, AVG(counts.[Fees per View]) AS [Avg Fees Per View]
FROM ( SELECT c.ClientID
			, CAST(SUM(p.Monthly)/COUNT(v.ViewID) AS INT) AS [Fees Per View]
	   FROM Client c JOIN [View] v ON c.ClientID = v.ID
					 JOIN Pricing p ON c.Pricing = p.PlanNo
	   GROUP BY ClientID
	 ) AS counts
JOIN Client c ON counts.ClientID = c.ClientID
JOIN [View] v ON c.ClientID = v.ID
JOIN Pricing p ON c.Pricing = p.PlanNo
GROUP BY c.Region
ORDER BY AVG(counts.[Fees per View]) DESC


--FR3.Q7: All views (all columns) that took place after October 15th, by Kindle devices, hosted by 
--Yelp from cities where there are more than 10 clients. Also add the name of the client 
--(as a first column) and city of the client (as a second column) for each view.
SELECT c.[Name]
	, c.City
	, v.ViewID
	, v.ViewDate
	, v.ID
	, v.Device
	, v.Browser
	, v.Host
FROM [View] v
	JOIN Client c ON c.ClientID = v.ID
WHERE v.Device LIKE '%Kindle%' 
	AND v.Host LIKE '%Yelp%' 
	AND v.ViewDate >= '2019-10-16'
	AND EXISTS (SELECT c.City 
				, COUNT(DISTINCT c.ClientID) AS [Number of Clients]
				FROM Client c
				GROUP BY c.City
				HAVING COUNT(DISTINCT c.ClientID) > 10
			   );
GO

--FR3.Q8: All non-executive employee full names in the first column, number of their regions, 
--number of their clients, and number of views for those clients in columns 2,3,4,respectively. 
SELECT e.FirstName + ' ' + e.LastName AS [Employee Name]
	, COUNT(DISTINCT ar.Region) AS [Number of Regions]
	, COUNT(DISTINCT c.ClientID) AS [Number of Clients]
	, COUNT(v.ViewID) AS [Number of Views]
FROM Employee e JOIN AgentRegion ar ON e.Employee_ID = ar.EmployeeID
				JOIN Client c ON ar.Region = c.Region
				JOIN [View] v ON c.ClientID = v.ID
WHERE e.Head = 0
GROUP BY e.FirstName, e.LastName

--FR4 (Business Intelligence): 
--Query for FR4.BI1
--Is there a correlation between price paid and number of views for clients? Comment in Excel.
SELECT c.ClientID
	, SUM(p.Monthly) AS [Total Price]
	, COUNT(v.ViewID) AS [Total Number of Views]
FROM Client c JOIN [View] v ON c.ClientID = v.ID
		 JOIN Pricing p ON c.Pricing = p.PlanNo
GROUP BY c.ClientID, p.Monthly


--Query for FR4.BI2: 
--Create a chart with average number of views per day(during the month of October)in the 
--vertical and hours of the day (0 to 23) in the horizontal axis

SELECT DAY(v.ViewDate) AS [ViewDay]
	, DATEPART(HOUR, v.ViewDate) AS [Hours of the Day]
	, AVG(CountViews.[NumViews]) AS [Average Views Per Day]
FROM (SELECT COUNT(ViewID) AS [NumViews]
	       , ViewDate
	  FROM [View] 
	  GROUP BY ViewDate) AS CountViews
JOIN [View] v ON v.ViewDate = CountViews.ViewDate
WHERE MONTH(v.ViewDate) = '10'
GROUP BY DAY(v.ViewDate), DATEPART(HOUR, v.ViewDate)

