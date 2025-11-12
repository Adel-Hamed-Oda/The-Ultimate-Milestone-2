CREATE PROC dropAllTables AS

    DROP TABLE IF EXISTS Employee_Approve_Leave;
    DROP TABLE IF EXISTS Employee_Replace_Employee;
    DROP TABLE IF EXISTS Performance;
    DROP TABLE IF EXISTS Deduction;
    DROP TABLE IF EXISTS Attendance;
    DROP TABLE IF EXISTS Payroll;
    DROP TABLE IF EXISTS Document;
    DROP TABLE IF EXISTS Compensation_Leave;
    DROP TABLE IF EXISTS Unpaid_Leave;
    DROP TABLE IF EXISTS Medical_Leave;
    DROP TABLE IF EXISTS Accidental_Leave;
    DROP TABLE IF EXISTS Annual_Leave;
    DROP TABLE IF EXISTS Leave_; -- changed from Leave to Leave_ to avoid conflict with SQL keyword
    DROP TABLE IF EXISTS Role_existsIn_Department;
    DROP TABLE IF EXISTS Employee_Role;
    DROP TABLE IF EXISTS Role;
    DROP TABLE IF EXISTS Employee_Phone;
    DROP TABLE IF EXISTS Employee;
    DROP TABLE IF EXISTS Department;

GO;

CREATE PROC dropAllProceduresFunctionsViews AS
    
    --TODO: finish this after finishing all the other functions adn procedures
    -- TODO update check and make sure everything is covered
    --also revise code this is from copilot so im not sure about it

BEGIN
    DECLARE @sql NVARCHAR(MAX) = '';
    
    -- Drop all user defined functions
    SELECT @sql = @sql + 'DROP FUNCTION IF EXISTS ' + QUOTENAME(SCHEMA_NAME(schema_id)) + '.' + QUOTENAME(name) + '; '
    FROM sys.objects
    WHERE type IN ('FN', 'IF', 'TF')  -- Scalar, Inline Table-Valued, Table-Valued
      AND is_ms_shipped = 0;
    
    -- Drop all user-defined views
    SELECT @sql = @sql + 'DROP VIEW IF EXISTS ' + QUOTENAME(SCHEMA_NAME(schema_id)) + '.' + QUOTENAME(name) + '; '
    FROM sys.objects
    WHERE type = 'V'  -- Views
      AND is_ms_shipped = 0;
    
    -- Drop all user-defined procedures EXCEPT this one
    SELECT @sql = @sql + 'DROP PROCEDURE IF EXISTS ' + QUOTENAME(SCHEMA_NAME(schema_id)) + '.' + QUOTENAME(name) + '; '
    FROM sys.objects
    WHERE type = 'P'  -- Stored Procedures
      AND is_ms_shipped = 0
      AND name <> 'dropAllProceduresFunctionsViews';  -- Don't drop itself
    
    -- Execute all DROP statements
    IF LEN(@sql) > 0
        EXEC sp_executesql @sql;
END;
GO;





GO;

CREATE PROC clearAllTables AS
    
    DELETE FROM Employee_Approve_Leave;
    DELETE FROM Employee_Replace_Employee;
    DELETE FROM Performance;
    DELETE FROM Deduction;
    DELETE FROM Attendance;
    DELETE FROM Payroll;
    DELETE FROM Document;
    DELETE FROM Compensation_Leave;
    DELETE FROM Unpaid_Leave;
    DELETE FROM Medical_Leave;
    DELETE FROM Accidental_Leave;
    DELETE FROM Annual_Leave;
    DELETE FROM Leave_;
    DELETE FROM Role_existsIn_Department;
    DELETE FROM Employee_Role;
    DELETE FROM Role;
    DELETE FROM Employee_Phone;
    DELETE FROM Employee;
    DELETE FROM Department;

GO;

-- TODO: looks sus, check with TA

CREATE VIEW allEmployeeProfiles AS
SELECT
    employee_ID,
    first_name,
    last_name,
    gender,
    email,
    address,
    years_of_experience,
    official_day_off,
    type_of_contract,
    employment_status,
    annual_balance,
    accidental_balance
FROM Employee;

GO;

CREATE VIEW NoEmployeeDept AS
SELECT 
    dept_name AS department_name,
    COUNT(employee_ID) AS num_employees
FROM Employee
GROUP BY dept_name;

GO;

CREATE VIEW allPerformance AS
SELECT 
    P.performance_ID,
    P.emp_ID,
    E.first_name,
    E.last_name,
    P.rating,
    P.comments,
    P.semester
FROM Performance P
JOIN Employee E ON P.emp_ID = E.employee_ID
WHERE P.semester LIKE 'W%'; -- not WIN because winter semesters might be W25 etc

GO;

CREATE VIEW allRejectedMedicals AS
SELECT 
    M.request_ID,
    M.emp_ID,
    E.first_name,
    E.last_name,
    M.insurance_status,
    M.disability_details,
    M.type,
    L.final_approval_status
FROM Medical_Leave M
JOIN Leave_ L ON M.request_ID = L.request_ID
JOIN Employee E ON M.emp_ID = E.employee_ID
WHERE L.final_approval_status = 'Rejected';

GO;

CREATE VIEW allEmployeeAttendance AS
SELECT 
    A.attendance_ID,
    A.emp_ID,
    E.first_name,
    E.last_name,
    A.date,
    A.check_in_time,
    A.check_out_time,
    A.total_duration,
    A.status
FROM Attendance A
-- TODO: not sure if this is how dates work
INNER JOIN Employee E ON A.emp_ID = E.employee_ID
WHERE A.date = CAST(DATEADD(DAY, -1, GETDATE()) AS DATE);

GO;

----------------------------------------------------------------
--                          EXTRA PROC
----------------------------------------------------------------

-- TODO: probably going delete this
CREATE PROC Update_All_Salaries AS

    UPDATE E
    SET E.salary = R.base_salary + ((R.percentage_YOE / 100.0) * E.years_of_experience * R.base_salary)
    FROM Employee E
    JOIN Employee_Role ER ON ER.emp_ID = E.employee_ID
    JOIN Role R ON R.role_name = ER.role_name;

GO;