USE EmployeeManagement;


-- 1. Create Department Salary Summary View

CREATE VIEW Department_Salary_Summary AS
SELECT
    d.dept_id,
    d.dept_name,
    COUNT(e.emp_id) AS total_employees,
    SUM(e.salary) AS total_salary,
    AVG(e.salary) AS average_salary,
    MAX(e.salary) AS highest_salary,
    MIN(e.salary) AS lowest_salary
FROM Department d
LEFT JOIN Employee e
    ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name;

-- Display the department salary summary

SELECT *
FROM Department_Salary_Summary;


-- 2. Query the View
-- Find departments with an average salary greater than 75000

SELECT
    dept_name,
    average_salary
FROM Department_Salary_Summary
WHERE average_salary > 75000;


-- 3. Employee Hierarchy
-- Add a manager_id column to the Employee table

ALTER TABLE Employee
ADD manager_id INT NULL;

-- Create a self-referencing foreign key for managers

ALTER TABLE Employee
ADD CONSTRAINT fk_employee_manager
FOREIGN KEY (manager_id)
REFERENCES Employee(emp_id);


-- 4. Insert Employee Hierarchy
-- Set top-level managers to NULL

UPDATE Employee
SET manager_id = NULL
WHERE emp_id IN (105, 112, 114, 122, 125);

-- IT Department

UPDATE Employee
SET manager_id = 105
WHERE emp_id IN (103, 104);

UPDATE Employee
SET manager_id = 103
WHERE emp_id IN (101, 102);

UPDATE Employee
SET manager_id = 104
WHERE emp_id = 106;


-- HR Department
-- Manager assignments as provided in the experiment document

UPDATE Employee
SET manager_id = 105
WHERE emp_id IN (103, 104);

UPDATE Employee
SET manager_id = 103
WHERE emp_id IN (101, 102);

UPDATE Employee
SET manager_id = 104
WHERE emp_id = 106;


-- Finance Department

UPDATE Employee
SET manager_id = 112
WHERE emp_id IN (107, 108);

UPDATE Employee
SET manager_id = 107
WHERE emp_id = 109;

UPDATE Employee
SET manager_id = 108
WHERE emp_id IN (110, 111);


-- Marketing Department
-- Manager assignments as provided in the experiment document

UPDATE Employee
SET manager_id = 112
WHERE emp_id IN (107, 108);

UPDATE Employee
SET manager_id = 107
WHERE emp_id = 109;

UPDATE Employee
SET manager_id = 108
WHERE emp_id IN (110, 111);


-- Research Department

UPDATE Employee
SET manager_id = 125
WHERE emp_id IN (126, 127, 128);

UPDATE Employee
SET manager_id = 126
WHERE emp_id = 129;

UPDATE Employee
SET manager_id = 128
WHERE emp_id = 130;


-- 5. Create Employee Hierarchy View
-- Display employees alongside their manager names

CREATE VIEW Employee_Hierarchy AS
SELECT
    e.emp_id,
    e.emp_name AS employee_name,
    e.manager_id,
    m.emp_name AS manager_name,
    e.salary,
    e.dept_id
FROM Employee e
LEFT JOIN Employee m
    ON e.manager_id = m.emp_id;

-- Display the employee hierarchy

SELECT *
FROM Employee_Hierarchy;


-- 6. Test Updatability of a Single View
-- Create a simple view of employee details

CREATE VIEW Employee_Basic AS
SELECT
    emp_id,
    emp_name,
    salary,
    dept_id
FROM Employee;

-- Display details of employee 101

SELECT *
FROM Employee_Basic
WHERE emp_id = 101;


-- 7. Update Through the View
-- Change the salary of employee 101 to 78000

UPDATE Employee_Basic
SET salary = 78000
WHERE emp_id = 101;

-- Verify the change in the original Employee table

SELECT *
FROM Employee
WHERE emp_id = 101;


-- 8. Test Non-Updatability of Department Salary View
-- This update is expected to fail because the view
-- contains aggregate functions and GROUP BY

UPDATE Department_Salary_Summary
SET average_salary = 80000
WHERE dept_id = 1;


-- 9. Recursive CTE
-- Display employee reporting chains starting from top-level managers

WITH RECURSIVE EmployeeChain AS (
    -- Anchor member: employees without managers
    SELECT
        emp_id,
        emp_name,
        manager_id,
        0 AS level,
        CAST(emp_name AS CHAR(500)) AS reporting_chain
    FROM Employee
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive member: find employees reporting to each manager
    SELECT
        e.emp_id,
        e.emp_name,
        e.manager_id,
        ec.level + 1,
        CONCAT(ec.reporting_chain, ' -> ', e.emp_name)
    FROM Employee e
    INNER JOIN EmployeeChain ec
        ON e.manager_id = ec.emp_id
)

-- Display the complete reporting chains

SELECT
    emp_id,
    emp_name,
    manager_id,
    level,
    reporting_chain
FROM EmployeeChain
ORDER BY reporting_chain;


-- 10. Recursive CTE for One Employee
-- Display employee 101 and follow the chain upward to their managers

WITH RECURSIVE ReportingChain AS (
    -- Anchor member: start with employee 101
    SELECT
        emp_id,
        emp_name,
        manager_id,
        0 AS level
    FROM Employee
    WHERE emp_id = 101

    UNION ALL

    -- Recursive member: find the manager of the current employee
    SELECT
        e.emp_id,
        e.emp_name,
        e.manager_id,
        rc.level + 1
    FROM Employee e
    JOIN ReportingChain rc
        ON e.emp_id = rc.manager_id
)

-- Display the reporting chain

SELECT
    emp_id,
    emp_name,
    manager_id,
    level
FROM ReportingChain;
