-- TESTING
USE test;

GO

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
    DROP TABLE IF EXISTS Leave;
    DROP TABLE IF EXISTS Role_existsIn_Department;
    DROP TABLE IF EXISTS Employee_Role;
    DROP TABLE IF EXISTS Role;
    DROP TABLE IF EXISTS Employee_Phone;
    DROP TABLE IF EXISTS Employee;
    DROP TABLE IF EXISTS Department;
    DROP TABLE IF EXISTS Holiday -- we consider this to be part of the database

GO

CREATE PROC dropAllProceduresFunctionsViews AS
    
    DROP FUNCTION IF EXISTS HRLoginValidation;
    DROP FUNCTION IF EXISTS EmployeeLoginValidation;
    DROP FUNCTION IF EXISTS MyPerformance;
    DROP FUNCTION IF EXISTS MyAttendance;
    DROP FUNCTION IF EXISTS Last_month_payroll;
    DROP FUNCTION IF EXISTS Deductions_Attendance;
    DROP FUNCTION IF EXISTS Is_On_Leave;
    DROP FUNCTION IF EXISTS Status_leaves;
    DROP FUNCTION IF EXISTS Check_DeanOR_Vice;
    DROP FUNCTION IF EXISTS CheckIfPartTime;
    DROP FUNCTION IF EXISTS ReplaceExist;
    DROP FUNCTION IF EXISTS CheckIfMale;
    DROP FUNCTION IF EXISTS Bonus_amount;
    DROP FUNCTION IF EXISTS GetRequestYear;
    DROP FUNCTION IF EXISTS isNotPartTime;
    DROP FUNCTION IF EXISTS getIDrequesterUNPAID;
    DROP FUNCTION IF EXISTS getIDrequesterCOMP;
    DROP FUNCTION IF EXISTS GetHighestRankEmployee;

    DROP VIEW IF EXISTS allEmployeeProfiles;
    DROP VIEW IF EXISTS NoEmployeeDept;
    DROP VIEW IF EXISTS allPerformance;
    DROP VIEW IF EXISTS allRejectedMedicals;
    DROP VIEW IF EXISTS allEmployeeAttendance;
   
    DROP PROCEDURE IF EXISTS Update_Status_Doc;
    DROP PROCEDURE IF EXISTS Remove_Deductions;
    DROP PROCEDURE IF EXISTS Update_Employment_Status;
    DROP PROCEDURE IF EXISTS Create_Holiday;
    DROP PROCEDURE IF EXISTS Add_Holiday;
    DROP PROCEDURE IF EXISTS Initiate_Attendance;
    DROP PROCEDURE IF EXISTS Update_Attendance;
    DROP PROCEDURE IF EXISTS Remove_Holiday;
    DROP PROCEDURE IF EXISTS Remove_DayOff;
    DROP PROCEDURE IF EXISTS Remove_Approved_Leaves;
    DROP PROCEDURE IF EXISTS Replace_Employee;

    DROP PROCEDURE IF EXISTS HR_approval_an_acc;
    DROP PROCEDURE IF EXISTS HR_approval_unpaid;
    DROP PROCEDURE IF EXISTS HR_approval_comp;
   
    DROP PROCEDURE IF EXISTS Deduction_hours;
    DROP PROCEDURE IF EXISTS Deduction_days;
    DROP PROCEDURE IF EXISTS Deduction_unpaid;
    DROP PROCEDURE IF EXISTS Add_Payroll;

    DROP PROCEDURE IF EXISTS Submit_annual;
    DROP PROCEDURE IF EXISTS Upperboard_approve_annual;
    DROP PROCEDURE IF EXISTS Submit_accidental;
    DROP PROCEDURE IF EXISTS Submit_medical;
    DROP PROCEDURE IF EXISTS Submit_unpaid;
    DROP PROCEDURE IF EXISTS Upperboard_approve_unpaids;
    DROP PROCEDURE IF EXISTS Submit_compensation;
    DROP PROCEDURE IF EXISTS Dean_andHR_Evaluation;

    DROP PROCEDURE IF EXISTS createAllTables;
    DROP PROCEDURE IF EXISTS dropAllTables;
    DROP PROCEDURE IF EXISTS clearAllTables;
    DROP PROCEDURE IF EXISTS Update_All_Salaries; -- TODO: probably going to delete this
    DROP PROCEDURE IF EXISTS Finalize_Deductions; -- TODO: probably going to delete this

    DROP PROCEDURE IF EXISTS dropAllProceduresFunctionsViews; -- the suicide line
    -- if the description was better we could've evaded this
    -- but we at GUC are VERY inclusive

GO

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
    DELETE FROM Leave;
    DELETE FROM Role_existsIn_Department;
    DELETE FROM Employee_Role;
    DELETE FROM Role;
    DELETE FROM Employee_Phone;
    DELETE FROM Employee;
    DELETE FROM Department;
    DELETE FROM Holiday; -- aref added this when checking cuz we drop it in dropAllTables but never clear it

GO

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

GO

CREATE VIEW NoEmployeeDept AS

    SELECT 
        dept_name AS department_name,
        COUNT(employee_ID) AS num_employees
    FROM Employee
    GROUP BY dept_name;

GO

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
    WHERE P.semester LIKE 'W%';

GO

-- TODO: should I add the main Leave table details too?
CREATE VIEW allRejectedMedicals AS

    SELECT 
        M.*
    FROM Medical_Leave M
    JOIN Leave L ON M.request_ID = L.request_ID
    JOIN Employee E ON M.emp_ID = E.employee_ID
    WHERE L.final_approval_status = 'rejected';

GO

CREATE VIEW allEmployeeAttendance AS

    SELECT 
        A.attendance_ID,
        A.emp_ID,
        E.first_name,
        E.last_name,
        A.[date],
        A.check_in_time,
        A.check_out_time,
        A.total_duration,
        A.status
    FROM Attendance A
    INNER JOIN Employee E ON A.emp_ID = E.employee_ID
    WHERE A.[date] = CAST(DATEADD(DAY, -1, GETDATE()) AS DATE);

GO

----------------------------------------------------------------
--                          EXTRA PROC
----------------------------------------------------------------

CREATE PROC Update_All_Salaries AS

    UPDATE E
    SET E.salary = R.base_salary + ((R.percentage_YOE / 100.0) * E.years_of_experience * R.base_salary)
    FROM Employee E
    JOIN Employee_Role ER ON ER.emp_ID = E.employee_ID
    JOIN Role R ON R.role_name = ER.role_name
    WHERE R.rank = (
        SELECT MIN(R2.rank)
        FROM Employee_Role ER2
        JOIN Role R2 ON ER2.role_name = R2.role_name
        WHERE ER2.emp_ID = E.employee_ID
    );

GO