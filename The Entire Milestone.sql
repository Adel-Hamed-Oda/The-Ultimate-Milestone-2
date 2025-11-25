USE University_HR_ManagementSystem_Team_8;

GO

CREATE PROC createAllTables AS
    -- 1. Department
    CREATE TABLE Department (
        name VARCHAR(50),
        building_location VARCHAR(50),

        PRIMARY KEY (name)
    );

    -- 2. Employee
    CREATE TABLE Employee (
        employee_ID INT IDENTITY(1,1),
        first_name VARCHAR(50),
        last_name VARCHAR(50),
        email VARCHAR(50),
        [password] VARCHAR(50),
        [address] VARCHAR(50),
        gender CHAR(1),
        official_day_off VARCHAR(50),
        years_of_experience INT,
        national_ID CHAR(16),
        employment_status VARCHAR(50),
        type_of_contract VARCHAR(50),
        emergency_contact_name VARCHAR(50),
        emergency_contact_phone CHAR(11),
        annual_balance INT,
        accidental_balance INT,
        -- TODO: do something about the salary
        salary DECIMAL(10,2),
        hire_date DATE,
        last_working_date DATE,
        dept_name VARCHAR(50),
    
        PRIMARY KEY (employee_ID),
        FOREIGN KEY (dept_name) REFERENCES Department(name),

        CHECK (LOWER(type_of_contract) IN ('full_time', 'part_time')),
        CHECK (LOWER(employment_status) IN ('active', 'onleave', 'notice_period', 'resigned'))
    );

    -- 3. Employee_Phone
    CREATE TABLE Employee_Phone (
        emp_ID INT,
        phone_num CHAR(11),

        PRIMARY KEY (emp_ID, phone_num),
        FOREIGN KEY (emp_ID) REFERENCES Employee(employee_ID)
    );

    -- 4. Role
    CREATE TABLE Role (
        role_name VARCHAR(50),
        title VARCHAR(50),
        description VARCHAR(50),
        rank INT,
        base_salary DECIMAL(10,2),
        percentage_YOE DECIMAL(4,2),
        percentage_overtime DECIMAL(4,2),
        annual_balance INT,
        accidental_balance INT,

        PRIMARY KEY (role_name)
    );

    -- 5. Employee_Role
    CREATE TABLE Employee_Role (
        emp_ID INT,
        role_name VARCHAR(50),

        PRIMARY KEY (emp_ID, role_name),
        FOREIGN KEY (emp_ID) REFERENCES Employee(employee_ID),
        FOREIGN KEY (role_name) REFERENCES Role(role_name)
    );

    -- 6. Role_existsIn_Department
    CREATE TABLE Role_existsIn_Department (
        department_name VARCHAR(50),
        role_name VARCHAR(50),

        PRIMARY KEY (department_name, role_name),
        FOREIGN KEY (department_name) REFERENCES Department(name),  -- fixed wrong table name according to the schema
        FOREIGN KEY (role_name) REFERENCES Role(role_name),

        CHECK (
            department_name <> 'HR' 
            OR role_name LIKE 'HR_Representative_%' 
            OR role_name = 'HR Manager'
        )

    );

    -- 7. Leave
    CREATE TABLE Leave (
        request_ID INT IDENTITY(1,1),
        date_of_request DATE,
        start_date DATE,
        end_date DATE,
        num_days AS DATEDIFF(DAY, start_date, end_date) + 1,
        final_approval_status VARCHAR(50),

        PRIMARY KEY (request_ID)
    );

    -- 8. Annual_Leave
    CREATE TABLE Annual_Leave (
        request_ID INT,
        emp_ID INT,
        replacement_emp INT,

        PRIMARY KEY (request_ID),
        FOREIGN KEY (request_ID) REFERENCES Leave(request_ID),
        FOREIGN KEY (emp_ID) REFERENCES Employee(employee_ID),
        FOREIGN KEY (replacement_emp) REFERENCES Employee(employee_ID)
    );

    -- 9. Accidental_Leave
    CREATE TABLE Accidental_Leave (
        request_ID INT,
        emp_ID INT,

        PRIMARY KEY (request_ID),
        FOREIGN KEY (request_ID) REFERENCES Leave(request_ID),
        FOREIGN KEY (emp_ID) REFERENCES Employee(employee_ID)
    );

    -- 10. Medical_Leave
    CREATE TABLE Medical_Leave (
        request_ID INT,
        insurance_status BIT,
        disability_details VARCHAR(50),
        [type] VARCHAR(50),
        emp_ID INT,

        PRIMARY KEY (request_ID),
        FOREIGN KEY (request_ID) REFERENCES Leave(request_ID),
        FOREIGN KEY (emp_ID) REFERENCES Employee(employee_ID),

        CHECK (LOWER(type) IN ('sick', 'maternity'))
    );

    -- 11. Unpaid_Leave
    CREATE TABLE Unpaid_Leave (
        request_ID INT,
        emp_ID INT,

        PRIMARY KEY (request_ID),
        FOREIGN KEY (request_ID) REFERENCES Leave(request_ID),
        FOREIGN KEY (emp_ID) REFERENCES Employee(employee_ID)
    );

    -- 12. Compensation_Leave
    CREATE TABLE Compensation_Leave (
        request_ID INT,
        reason VARCHAR(50),
        date_of_original_workday DATE,
        emp_ID INT,
        replacement_emp INT,

        PRIMARY KEY (request_ID),
        FOREIGN KEY (request_ID) REFERENCES Leave(request_ID),
        FOREIGN KEY (emp_ID) REFERENCES Employee(employee_ID),
        FOREIGN KEY (replacement_emp) REFERENCES Employee(employee_ID)
    );

    -- 13. Document
    CREATE TABLE Document (
        document_ID INT IDENTITY(1,1),
        [type] VARCHAR(50),
        [description] VARCHAR(50),
        file_name VARCHAR(50),
        creation_date DATE,
        [expiry_date] DATE,
        [status] VARCHAR(50),
        emp_ID INT,
        medical_ID INT,
        unpaid_ID INT,

        PRIMARY KEY (document_ID),
        FOREIGN KEY (emp_ID) REFERENCES Employee(employee_ID),
        FOREIGN KEY (medical_ID) REFERENCES Medical_Leave(request_ID),
        FOREIGN KEY (unpaid_id) REFERENCES Unpaid_Leave(request_ID),

        CHECK (LOWER(status) IN ('valid', 'expired'))
    );

    -- 14. Payroll
    CREATE TABLE Payroll (
        ID INT IDENTITY(1,1),
        payment_date DATE,
        final_salary_amount DECIMAL(10,1),
        from_date DATE,
        to_date DATE,
        comments VARCHAR(150),
        bonus_amount DECIMAL(10,2),
        deductions_amount DECIMAL(10,2),
        emp_ID INT,

        PRIMARY KEY (ID),
        FOREIGN KEY (emp_ID) REFERENCES Employee(employee_id),
    );

    -- 15. Attendance
    CREATE TABLE Attendance (
        attendance_ID INT IDENTITY(1,1) ,
        [date] DATE,
        check_in_time TIME,
        check_out_time TIME,
        total_duration AS DATEDIFF(minute, check_in_time, check_out_time),--TODO: check
        [status] VARCHAR(50) DEFAULT 'absent',
        emp_ID INT,

        PRIMARY KEY (attendance_ID),
        FOREIGN KEY (emp_ID) REFERENCES Employee(employee_ID),

        CHECK (LOWER(status) IN ('absent', 'attended'))
    );

    -- 16. Deduction
    CREATE TABLE Deduction (
        deduction_ID INT IDENTITY(1,1),
        emp_ID INT,
        [date] DATE,
        amount DECIMAL(10,2),
        [type] VARCHAR(50),
        [status] VARCHAR(50) DEFAULT 'pending',
        unpaid_ID INT,
        attendance_ID INT,

        PRIMARY KEY (deduction_ID),
        FOREIGN KEY (emp_ID) REFERENCES Employee(employee_ID),
        FOREIGN KEY (unpaid_ID) REFERENCES Unpaid_Leave(request_ID),
        FOREIGN KEY (attendance_ID) REFERENCES Attendance(attendance_ID),

        CHECK (LOWER(type) IN ('unpaid', 'missing_hours', 'missing_days')),
        CHECK (LOWER(status) IN ('pending', 'finalized'))
    );

    -- 17. Performance
    CREATE TABLE Performance (
        performance_ID INT IDENTITY(1,1),
        rating INT,
        comments VARCHAR(50),
        semester CHAR(3),
        emp_ID INT,

        PRIMARY KEY (performance_ID),
        FOREIGN KEY (emp_ID) REFERENCES Employee(employee_ID),
        CHECK (rating BETWEEN 1 AND 5)
    );

    -- 18. Employee_Replace_Employee
    CREATE TABLE Employee_Replace_Employee (
        table_ID INT IDENTITY(1,1),
        emp1_ID INT,
        emp2_ID INT,
        from_date DATE,
        to_date DATE,

        PRIMARY KEY (table_ID, emp1_ID, emp2_ID),
        FOREIGN KEY (emp1_ID) REFERENCES Employee(employee_ID),
        FOREIGN KEY (emp2_ID) REFERENCES Employee(employee_ID)
    );

    -- 19. Employee_Approve_Leave
    CREATE TABLE Employee_Approve_Leave (
        emp1_ID INT,
        leave_ID INT,
        [status] VARCHAR(50) DEFAULT 'pending',

        PRIMARY KEY (emp1_ID, leave_ID),
        FOREIGN KEY (emp1_ID) REFERENCES Employee(employee_ID),
        FOREIGN KEY (leave_ID) REFERENCES Leave(request_ID),

        CHECK (LOWER(status) IN ('approved', 'rejected', 'pending'))
    );

GO

-- Initialize the database by creating all tables so that the entire file is run at once
EXEC createAllTables;

GO

CREATE TRIGGER trg_InsertEmployeeRole
ON Role
INSTEAD OF INSERT
AS
BEGIN
    -- If any inserted HR_Representative_* has an invalid department suffix,
    -- skip inserting all of them
    IF EXISTS (
        SELECT *
        FROM inserted i
        WHERE i.role_name LIKE 'HR_Representative_%'
          AND SUBSTRING(i.role_name, 19, LEN(i.role_name) - 18)
              NOT IN (SELECT name FROM Department)
    )
    BEGIN
        -- error message for debugging we can delete it later 
        PRINT 'Invalid HR Representative role_name: does not exist.';
        RETURN;
    END;

    -- Otherwise insert 
    INSERT INTO Role (
        role_name,
        title,
        description,
        rank,
        base_salary,
        percentage_YOE,
        percentage_overtime,
        annual_balance,
        accidental_balance
    )
    SELECT
        role_name,
        title,
        description,
        rank,
        base_salary,
        percentage_YOE,
        percentage_overtime,
        annual_balance,
        accidental_balance
    FROM inserted;
END;

GO

-------------------------------------------------------
-------------------------------------------------------
--                      GENERAL
-------------------------------------------------------
-------------------------------------------------------

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
    DROP TABLE IF EXISTS [Role];
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
    DROP FUNCTION IF EXISTS checkingifreplacingsomeoneelse;
    DROP FUNCTION IF EXISTS GetMaxDate;
    DROP FUNCTION IF EXISTS GetMinDate;

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
    DROP PROCEDURE IF EXISTS Update_All_Salaries;
    DROP TRIGGER IF EXISTS trg_CalculateSalary;
    DROP TRIGGER IF EXISTS trg_EmployeeInsert;
    DROP TRIGGER IF EXISTS trg_InsertEmployeeRole;

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
    DELETE FROM [Role];
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
        [address],
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

CREATE VIEW allRejectedMedicals AS
    SELECT 
        -- Leave details
        L.request_ID,
        L.date_of_request,
        L.start_date,
        L.end_date,
        L.num_days,
        L.final_approval_status,

        -- Medical_Leave details
        M.emp_ID,
        M.insurance_status,
        M.disability_details,
        M.[type]
    FROM Medical_Leave M
    JOIN [Leave] L ON M.request_ID = L.request_ID
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
    JOIN [Role] R ON R.role_name = ER.role_name
    WHERE R.rank = (
        SELECT MIN(R2.rank)
        FROM Employee_Role ER2
        JOIN [Role] R2 ON ER2.role_name = R2.role_name
        WHERE ER2.emp_ID = E.employee_ID
    );

GO

CREATE TRIGGER trg_EmployeeInsert
ON Employee
AFTER INSERT, UPDATE
AS
BEGIN 
    EXEC Update_All_Salaries;
END

GO

-------------------------------------------------------
-------------------------------------------------------
--                      ADMIN
-------------------------------------------------------
-------------------------------------------------------

CREATE PROC Update_Status_Doc AS
    
    UPDATE Document
    SET [status] = 'expired'
    WHERE expiry_date <= CAST(GETDATE() AS DATE);

GO

CREATE PROC Remove_Deductions AS
    
    DELETE FROM Deduction
    WHERE emp_ID IN (
        SELECT employee_ID
        FROM Employee
        WHERE employment_status = 'resigned'
    );

GO

CREATE PROCEDURE Update_Employment_Status
    @empID INT
AS
    DECLARE @is_on_leave INT = 0;

    IF (dbo.Is_On_Leave(@empID, CAST(GETDATE() AS DATE), CAST(GETDATE() AS DATE)) = 1)
    BEGIN
        UPDATE Employee
        SET employment_status = 'onleave'
        WHERE employee_ID = @empID;
    END 
    ELSE 
    BEGIN
        UPDATE Employee
        SET employment_status = 'active'
        WHERE employee_ID = @empID;
    END;

GO

CREATE PROC Create_Holiday AS

    CREATE TABLE Holiday (
        holiday_id INT IDENTITY(1,1) PRIMARY KEY,
        holiday_name VARCHAR(50),
        from_date DATE,
        to_date DATE
    );

GO

CREATE PROC Add_Holiday
    @holiday_name VARCHAR(50),
    @from_date DATE,
    @to_date DATE
AS

    INSERT INTO Holiday (holiday_name, from_date, to_date)
    VALUES (@holiday_name, @from_date, @to_date);

GO

CREATE PROC Initiate_Attendance AS
    
    INSERT INTO Attendance (emp_ID, [date], [status])
    SELECT 
        employee_ID, 
        CAST(GETDATE() AS DATE), 
        'absent'
    FROM Employee
    WHERE employee_ID NOT IN (
        SELECT emp_ID 
        FROM Attendance 
        WHERE [date] = CAST(GETDATE() AS DATE)
    );

GO

CREATE PROC Update_Attendance
    @emp_ID INT,
    @check_in TIME,
    @check_out TIME
AS

    IF NOT EXISTS (
        SELECT * FROM Attendance 
        WHERE [date] = CAST(GETDATE() AS DATE)
          AND emp_ID = @emp_ID
    ) BEGIN
        INSERT INTO Attendance (emp_ID, [date], [status], check_in_time, check_out_time)
        VALUES (@emp_ID, CAST(GETDATE() AS DATE), 'attended', @check_in, @check_out);
        RETURN;
    END ELSE BEGIN
        UPDATE Attendance 
        SET [status] = 'attended',
            check_in_time = @check_in,
            check_out_time = @check_out
        WHERE [date] = CAST(GETDATE() AS DATE)
          AND emp_ID = @emp_ID;
    END;

GO

CREATE PROC Remove_Holiday AS
    
    DELETE FROM Attendance
    WHERE [date] IN (
        SELECT A.[date]
        FROM Attendance A
        JOIN Holiday H ON A.[date] BETWEEN H.from_date AND H.to_date
    );

GO

CREATE PROC Remove_DayOff
    @emp_ID INT
AS

    DELETE FROM Attendance
    WHERE emp_ID = @emp_ID
      AND [status] = 'absent'
      AND MONTH([date]) = MONTH(GETDATE())
      AND YEAR([date]) = YEAR(GETDATE())
      AND DATENAME(WEEKDAY, [date]) = (-- Compare weekday names 3ashan for example official_day_off is a VARCHAR(50) but we can also compare be turning days into numbers and comparing them
          SELECT official_day_off 
          FROM Employee 
          WHERE employee_ID = @emp_ID
      );

GO

CREATE PROC Remove_Approved_Leaves
    @emp_ID INT
AS
    DELETE FROM Attendance
    WHERE emp_ID = @emp_ID
      AND [date] IN (
          SELECT A.[date]
          FROM Attendance A 
          JOIN (Leave JOIN (SELECT emp_ID, request_ID FROM Annual_Leave
                UNION
                SELECT emp_ID, request_ID FROM Accidental_Leave
                UNION
                SELECT emp_ID, request_ID FROM Medical_Leave
                UNION
                SELECT emp_ID, request_ID FROM Unpaid_Leave
                UNION
                SELECT emp_ID, request_ID FROM Compensation_Leave) AS L ON Leave.request_ID = L.request_ID)
                    ON A.[date] BETWEEN Leave.start_date AND Leave.end_date
          WHERE L.emp_ID = @emp_ID
            AND Leave.final_approval_status = 'approved'
      );
GO

CREATE PROC Replace_Employee
    @Emp1_ID INT,
    @Emp2_ID INT,
    @from_date DATE,
    @to_date DATE
AS

    INSERT INTO Employee_Replace_Employee (Emp1_ID, Emp2_ID, from_date, to_date)
    VALUES (@Emp1_ID, @Emp2_ID, @from_date, @to_date);

GO

-------------------------------------------------------
-------------------------------------------------------
--                         HR
-------------------------------------------------------
-------------------------------------------------------

CREATE FUNCTION [HRLoginValidation] (@employee_ID INT, @password VARCHAR(50))
RETURNS BIT
AS
BEGIN
    DECLARE @b BIT

    IF (EXISTS (
        SELECT E.*
        FROM Employee E
        WHERE E.dept_name = 'HR'
          AND E.password = @password
          AND E.employee_id = @employee_ID
    ))
        SET @b = 1
    ELSE
        SET @b = 0

    RETURN @b;
END;

GO

CREATE PROCEDURE HR_approval_an_acc
    @request_ID INT,
    @HR_ID INT
AS

    IF (EXISTS (
            SELECT *
            FROM Employee_Approve_Leave E
            WHERE E.Leave_ID = @request_ID
                AND E.status = 'pending'
        ))
    RETURN; -- If any previous pending just return

    DECLARE @type VARCHAR(50),
            @myid INT,
            @parttimecheck BIT,
            @replacementemp INT,
            @availcheck BIT,
            @avail2check BIT,
            @approvalcheck BIT,
            @balancecheck BIT,
            @balance INT,
            @maxonedaycheck INT,
            @subwithin48hourscheck BIT,
            @datesubmitted DATE,
            @startdate DATE,
            @enddate DATE,
            @totaldays INT

    -- Determine Leave Type
    IF (EXISTS (
        SELECT *
        FROM Leave L, Annual_Leave A
        WHERE L.request_ID = A.request_ID
            AND L.request_ID = @request_ID
    ))
        SET @type = 'annual'
    
    IF (EXISTS (
        SELECT *
        FROM Leave L, Accidental_Leave A
        WHERE L.request_ID = A.request_ID
            AND L.request_ID = @request_ID
    ))
        SET @type = 'accidental'

    SELECT @startdate = L.start_date, @enddate = L.end_date
    FROM Leave L
    WHERE L.request_ID = @request_ID
    IF (@startdate IS NULL OR CAST(GETDATE() AS DATE) >= @startdate)
        RETURN; -- If start date is null or current date is past start date, just return

    -- Logic for Annual Leave
    IF (@type = 'annual')
    BEGIN
        SELECT @myid = A.emp_ID
        FROM Employee E, Annual_Leave A
        WHERE E.employee_id = A.emp_ID
            AND @request_ID = A.request_ID

        SET @parttimecheck = dbo.isNotPartTime(@myid)

        SELECT @replacementemp = replacement_emp
        FROM Annual_Leave
        WHERE request_ID = @request_ID

        IF (@replacementemp IS NOT NULL) -- Is there anyone to even replace me
            SET @availcheck = dbo.Is_On_Leave(@replacementemp, @startdate, @enddate) -- Yes? check if he is avail
        ELSE
            SET @availcheck = 0

        -- An employee cannot replace multiple others at the same time
        SET @avail2check = 
            dbo.checkingifreplacingsomeoneelse(@replacementemp, @startdate, @enddate)

        -- Checking for approvals
        IF (NOT EXISTS (
            SELECT *
            FROM Employee_Approve_Leave E
            WHERE E.Leave_ID = @request_ID
                AND E.status = 'rejected'
        ))
            SET @approvalcheck = 1
        ELSE
            SET @approvalcheck = 0

        -- Checking for annual balance
        SELECT @balance = E.annual_balance
        FROM Employee E
        WHERE E.employee_ID = @myid

        SELECT @totaldays = L.num_days
        FROM Leave L
        WHERE L.request_ID = @request_ID

        IF (@totaldays > @balance)
            SET @balancecheck = 0;
        ELSE
            SET @balancecheck = 1;

        -- Final Approval / Rejection for Annual
        IF (@balancecheck = 1 AND @approvalcheck = 1 AND @parttimecheck = 1 AND @availcheck = 1 AND @avail2check = 1)
        BEGIN
            UPDATE Employee
            SET annual_balance = annual_balance - @totaldays
            WHERE employee_id = @myid

            UPDATE Leave
            SET final_approval_status = 'approved'
            WHERE @request_ID = request_ID

            UPDATE Employee_Approve_Leave
            SET [status] = 'approved'
            WHERE Emp1_ID = @HR_ID 
                AND leave_id = @request_id

            INSERT INTO Employee_Replace_Employee VALUES (@myid, @replacementemp, @startdate, @enddate);
        END
        ELSE
        BEGIN
            UPDATE Leave
            SET final_approval_status = 'rejected'
            WHERE @request_ID = request_ID

            UPDATE Employee_Approve_Leave
            SET [status] = 'rejected'
            WHERE Emp1_ID = @HR_ID 
                AND leave_id = @request_id
        END
    END
    ELSE -- Logic for Accidental Leave
    BEGIN
        SELECT @myid = A.emp_ID
        FROM Employee E, Accidental_Leave A
        WHERE E.employee_id = A.emp_ID
            AND @request_ID = A.request_ID

        SELECT @totaldays = L.num_days, @datesubmitted = L.date_of_request
        FROM Leave L
        WHERE L.request_ID = @request_ID

        SELECT @balance = E.accidental_balance
        FROM Employee E
        WHERE @myid = E.employee_id

        -- Number of days should be 1
        IF (@totaldays <> 1)
            SET @maxonedaycheck = 0
        ELSE
            SET @maxonedaycheck = 1

        IF (@balance > @totaldays)
            SET @balancecheck = 1
        ELSE
            SET @balancecheck = 0

        -- Leave submitted within 48 hours of start date
        IF DATEDIFF(HOUR, @datesubmitted, @startdate) BETWEEN 0 AND 48
            SET @subwithin48hourscheck = 1;
        ELSE
            SET @subwithin48hourscheck = 0;

        -- By the way we dont check the approvals here for example
        -- Because only the hr needs to approve this and we add this approval here in this procedure
        IF (@subwithin48hourscheck = 1 AND @balancecheck = 1 AND @maxonedaycheck = 1)
        BEGIN
            UPDATE Employee
            SET accidental_balance = accidental_balance - @totaldays
            WHERE employee_id = @myid

            UPDATE Leave
            SET final_approval_status = 'approved'
            WHERE @request_ID = request_ID

            UPDATE Employee_Approve_Leave
            SET [status] = 'approved'
            WHERE Emp1_ID = @HR_ID 
                AND leave_id = @request_id
        END
        ELSE
        BEGIN
            UPDATE Leave
            SET final_approval_status = 'rejected'
            WHERE @request_ID = request_ID

            UPDATE Employee_Approve_Leave
            SET [status] = 'rejected'
            WHERE Emp1_ID = @HR_ID 
                AND leave_id = @request_id
        END
    END

GO

CREATE PROCEDURE HR_approval_unpaid
    @request_ID INT,
    @HR_ID INT,
    @startdate DATE,
    @enddate DATE
AS
BEGIN

    IF (EXISTS (
            SELECT *
            FROM Employee_Approve_Leave E
            WHERE E.Leave_ID = @request_ID
                AND E.status = 'pending'
        ))
    RETURN; -- If any previous pending just return

    DECLARE @myid INT,
            @myrank INT,
            @parttimecheck BIT,
            @year INT,
            @yearcheck BIT,
            @maxdurationcheck BIT,
            @approvalcheck BIT
    
    SELECT @startdate = L.start_date, @enddate = L.end_date
    FROM Leave L
    WHERE L.request_ID = @request_ID;

    IF (@startdate IS NULL OR CAST(GETDATE() AS DATE) >= @startdate)
        RETURN;
    SET @myid = dbo.getIDrequesterUNPAID(@request_ID)

    -- If im part time i cant get unpaid leave
    SET @parttimecheck = dbo.isNotPartTime(@myid)

    -- Checks for max one approved unpaid leave per year
    SET @year = dbo.GetRequestYear(@request_ID)

    IF @year > ISNULL((
        SELECT MAX(YEAR(L.[start_date])) AS latest_year
        FROM Unpaid_Leave U, Leave L
        WHERE U.request_ID = L.request_ID
          AND L.final_approval_status = 'approved'
    ), -1)
        SET @yearcheck = 1
    ELSE
        SET @yearcheck = 0 -- The ISNULL here is needed because what if he never applied for a leave?

    -- Checking duration of leave max 30
    IF (SELECT L.num_days FROM Leave L WHERE L.request_ID = @request_ID) <= 30
        SET @maxdurationcheck = 1
    ELSE
        SET @maxdurationcheck = 0

    IF (NOT EXISTS (
        SELECT *
        FROM Employee_Approve_Leave E
        WHERE E.Leave_ID = @request_ID
          AND E.status = 'rejected'
    ))
        SET @approvalcheck = 1
    ELSE
        SET @approvalcheck = 0

    -- Last step setting final approval and adding it to the approval table
    IF (@parttimecheck = 1 AND @yearcheck = 1 AND @maxdurationcheck = 1 AND @approvalcheck = 1)
    BEGIN
        UPDATE Leave
        SET final_approval_status = 'approved'
        WHERE request_ID = @request_ID

        UPDATE Employee_Approve_Leave
        SET [status] = 'approved'
        WHERE Emp1_ID = @HR_ID 
            AND leave_id = @request_id
    END
    ELSE
    BEGIN
        UPDATE Leave
        SET final_approval_status = 'rejected'
        WHERE request_ID = @request_ID

        UPDATE Employee_Approve_Leave
        SET [status] = 'rejected'
        WHERE Emp1_ID = @HR_ID 
            AND leave_id = @request_id
    END
END;

GO

-- we are skipping any part-time employees, as YOU never mentioned any amount of time required
-- for part-time employees
CREATE PROC Deduction_hours
    @employee_ID INT
AS

    DECLARE @attendance_ID INT = -1;
    SELECT TOP (1) 
        @attendance_ID = attendance_ID
    FROM Attendance
    WHERE 
        emp_ID = @employee_ID
        AND YEAR([date]) = YEAR(GETDATE())
        AND MONTH([date]) = MONTH(GETDATE())
        AND total_duration < 480
        AND NOT EXISTS (SELECT 1 FROM Deduction D WHERE D.attendance_ID = Attendance.attendance_ID)
    ORDER BY [date];

    IF @attendance_ID <> -1 BEGIN

        DECLARE @number_of_deducted_minutes INT;
        SET @number_of_deducted_minutes = 
            480 - (
                SELECT total_duration
                FROM Attendance
                WHERE attendance_ID = @attendance_ID
            );

        DECLARE @salary DECIMAL(10,10),
                @rate_per_hour DECIMAL(10,10);
        SELECT @salary = salary
        FROM Employee
        WHERE employee_ID = @employee_ID;
        SET @rate_per_hour = (@salary / 22) / 8;
        
        DECLARE @deduction_amount DECIMAL(10,2);
        SET @deduction_amount = 
            (@rate_per_hour * (@number_of_deducted_minutes / 60.0));

        INSERT INTO Deduction (emp_ID, [date], amount, [type], [status], attendance_ID)
        VALUES (@employee_ID, CAST(GETDATE() AS DATE), @deduction_amount, 'missing hours', 'pending', @attendance_ID);

    END;

GO

CREATE PROCEDURE Deduction_days
    @employee_ID INT
AS
BEGIN
    DECLARE @mymonth  INT,
            @myyear   INT,
            @d        DECIMAL(10, 2),
            @mysalary DECIMAL(10, 2)

    SET @mymonth = MONTH(CURRENT_TIMESTAMP)
    SET @myyear = YEAR(CURRENT_TIMESTAMP)

    SELECT @mysalary = E.salary
    FROM   Employee E
    WHERE  E.employee_ID = @employee_ID

    -- deduction is d per day
    SET @d = @mysalary / 22

    INSERT INTO Deduction
                (emp_id,
                 [date],
                 amount,
                 [type],
                 [status],
                 unpaid_ID,
                 attendance_ID)
    SELECT @employee_ID,
           CAST(CURRENT_TIMESTAMP AS DATE),
           @d,
           'missing_days',
           'pending',
           NULL,
           A.attendance_ID
    FROM   Attendance A
    WHERE  MONTH(A.date) = @mymonth
           AND YEAR(A.date) = @myyear
           AND A.status = 'absent'
           AND A.emp_ID = @employee_ID
           AND NOT EXISTS (
               SELECT *
               FROM   Unpaid_Leave U,
                      Leave L
               WHERE  U.request_ID = L.request_ID
                      AND U.emp_ID = @employee_ID
                      AND A.date BETWEEN L.start_date AND L.end_date
           )
END

GO

CREATE PROCEDURE Deduction_unpaid
    @employee_ID INT
AS
BEGIN
    DECLARE @salary DECIMAL(10, 2);
    SELECT @salary = salary
    FROM Employee 
    WHERE employee_ID = @employee_ID;

    -- e7tyati
    IF @salary IS NULL SET @salary = 0;

    -- I assume that 22 means 22 working days, fa salary per day = total/22
    DECLARE @daily_rate DECIMAL(10, 2);
    SET @daily_rate = @salary / 22.0;

    DECLARE @request_ID INT;
    DECLARE @start_date DATE;
    DECLARE @end_date DATE;

    SELECT @request_ID = L.request_ID, @start_date = L.start_date, @end_date = L.end_date
    FROM Leave L, Unpaid_Leave UL
    WHERE UL.request_ID = L.request_ID
        AND UL.emp_ID = @employee_ID
        AND L.final_approval_status = 'approved'
        -- TODO: if the deduction for this unpaid leave request already exists, skip it
        -- risky bas IDC
        AND NOT EXISTS (
            SELECT 1 
            FROM Deduction D
            WHERE MONTH(D.[date]) = MONTH(GETDATE())
        );

    IF @request_ID IS NULL
        RETURN; -- No approved unpaid leave found for this employee this month that haven't already been handled

    DECLARE @real_start_date DATE = 
    dbo.GetMinDate(
        @start_date,
        CAST(DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1) AS DATE)
    );
    DECLARE @real_end_date DATE =
    dbo.GetMaxDate(
        @end_date,
        CAST(EOMONTH(GETDATE()) AS DATE)
    );
    
    DECLARE @days INT;

    SET @days = DATEDIFF(DAY, @real_start_date, @real_end_date) + 1;
        
    INSERT INTO Deduction (emp_ID, [date], amount, [type], [status], unpaid_ID)
    VALUES (@employee_ID, @start_date, @days * @daily_rate, 'unpaid', 'pending', @request_ID);

END

GO

CREATE FUNCTION Bonus_amount (@employee_ID INT)
    RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @salary DECIMAL(10,10),
            @overtime_factor DECIMAL(10,10),
            @rate_per_hour DECIMAL(10,10),
            @bonus DECIMAL(10,2);

    -- Get employee salary
    SELECT @salary = salary
    FROM Employee
    WHERE employee_ID = @employee_ID;

    SELECT TOP 1 @overtime_factor = percentage_overtime
    FROM Employee_Role ER
    JOIN Role R ON ER.role_name = R.role_name
    WHERE emp_ID = @employee_ID
    ORDER BY R.rank;

    -- Rate per hour formula
    SET @rate_per_hour = (@salary / 22) / 8;

    -- Compute overtime across current month
    SELECT @bonus =
        SUM(
            @rate_per_hour *
            ((@overtime_factor *
              CASE 
                    WHEN total_duration > 480 THEN total_duration - 480
                    ELSE 0
              END) / 100.0)
        )
    FROM Attendance
    WHERE emp_ID = @employee_ID
      AND MONTH(date) = MONTH(GETDATE())
      AND YEAR(date) = YEAR(GETDATE());

    RETURN ISNULL(@bonus, 0);
END;

GO

CREATE PROCEDURE Add_Payroll
    @employee_ID INT,
    @from_date DATE,
    @to_date DATE
AS
BEGIN

    -- Check if payroll for this month already exists
    IF EXISTS (
        SELECT 1 
        FROM Payroll 
        WHERE emp_ID = @employee_ID 
            AND MONTH(from_date) = MONTH(@from_date) 
            AND YEAR(from_date) = YEAR(@from_date))
    RETURN;

    DECLARE @salary DECIMAL(10,10),
            @bonus DECIMAL(10,10),
            @deductions DECIMAL(10,10);

    SELECT @salary = salary
    FROM Employee
    WHERE employee_ID = @employee_ID;

    SELECT @bonus = dbo.Bonus_amount(@employee_ID);

    SELECT @deductions = SUM(amount)
    FROM Deduction
    WHERE emp_ID = @employee_ID
        AND date BETWEEN @from_date AND @to_date
        AND [status] = 'pending';        -- not yet reflected in payroll

    SET @deductions = ISNULL(@deductions, 0);

    -- Insert payroll row
    INSERT INTO Payroll(payment_date, final_salary_amount,
                        from_date, to_date, comments,
                        bonus_amount, deductions_amount, emp_ID)
    VALUES(
        GETDATE(),
        @salary + @bonus - @deductions,
        @from_date,
        @to_date,
        NULL, -- I don't know, add 'I have the ms2 description here'
        @bonus,
        @deductions,
        @employee_ID
    );

    -- Finalize deductions now that they are reflected
    UPDATE Deduction
    SET [status] = 'finalized'
    WHERE emp_ID = @employee_ID
      AND date BETWEEN @from_date AND @to_date
      AND [status] = 'pending'
END

GO

CREATE FUNCTION [GetRequestYear] (@request_ID INT)
RETURNS INT
AS
BEGIN
    DECLARE @year INT;

    SELECT @year = YEAR(L.date_of_request)
    FROM Leave L
    WHERE L.request_ID = @request_ID;

    RETURN @year;
END

GO

-- renamed it to isNotPartTime for convenience
CREATE FUNCTION isNotPartTime (@employee_id INT)
RETURNS BIT
AS
BEGIN
    DECLARE @b BIT;

    IF (EXISTS (
        SELECT *
        FROM EMPLOYEE E
        WHERE E.employee_ID = @employee_id
          AND E.type_of_contract = 'part_time'
    ))
        SET @b = 0; -- If he is part time the check is 0
    ELSE
        SET @b = 1;

    RETURN @b;
END

GO

CREATE FUNCTION [getIDrequesterUNPAID] (@request_id INT)
RETURNS INT
AS
BEGIN
    DECLARE @myid INT;

    SELECT @myid = L.Emp_ID
    FROM unpaid_leave L
    WHERE @request_id = L.request_ID;

    RETURN @myid;
END

GO

CREATE FUNCTION [getIDrequesterCOMP] (@request_ID INT)
RETURNS INT
AS
BEGIN
    DECLARE @myid INT;

    SELECT @myid = C.emp_ID
    FROM Compensation_Leave C
    WHERE @request_ID = C.request_ID;

    RETURN @myid;
END

GO

CREATE PROCEDURE HR_approval_comp
    @request_ID INT,
    @HR_ID INT
AS
BEGIN
    
    IF (EXISTS (
            SELECT *
            FROM Employee_Approve_Leave E
            WHERE E.Leave_ID = @request_ID
                AND E.status = 'pending'
        ))
    RETURN; -- If any previous pending just return

    DECLARE @spentcheck BIT,
            @myid INT,
            @reason VARCHAR(50),
            @reasoncheck BIT,
            @replacementemp INT,
            @availcheck BIT,
            @avail2check BIT,
            -- added these to check for availability
            @startdate DATE,
            @enddate DATE;


    SELECT @startdate = L.start_date, @enddate = L.end_date
    FROM dbo.Leave L
    WHERE L.request_ID = @request_ID;

    IF (@startdate IS NULL OR CAST(GETDATE() AS DATE) >= @startdate)
        RETURN;
    SET @myid = dbo.getIDrequesterCOMP(@request_ID)

    -- Checks spent at least 8 hours on HIS dayoff, and request sent within same month (and year)
    IF EXISTS (
        SELECT *
        FROM Attendance A, Compensation_Leave C, Employee E, Leave L
        WHERE C.request_ID = @request_ID
          AND C.date_of_original_workday = A.date
          AND A.emp_ID = @myid
          AND A.total_duration >= 480
          AND E.employee_ID = @myid
          AND DATENAME(WEEKDAY, C.date_of_original_workday) = E.official_day_off
          AND L.request_ID = C.request_ID
          AND YEAR(C.date_of_original_workday) = YEAR(L.date_of_request)
          AND MONTH(C.date_of_original_workday) = MONTH(L.date_of_request)
    )
        SET @spentcheck = 1
    ELSE
        SET @spentcheck = 0

    SELECT @startdate = L.start_date, @enddate = L.end_date
    FROM Leave L
    WHERE L.request_ID = @request_ID

    -- Check valid reason...(not null or empty?)
    SELECT @reason = C.reason
    FROM Compensation_Leave C
    WHERE C.request_ID = @request_ID

    IF (@reason IS NULL OR @reason = '')
        SET @reasoncheck = 0
    ELSE
        SET @reasoncheck = 1

    -- Another employee must replace them HERE IM NOT SURE IF MULTIPLE PEOPLE CAN REPLACE ME SO I NEED
    -- TO CHECK IF ANYYY PERSONNN IS AVAILABLE (this gets last row only)
    SELECT @replacementemp = replacement_emp
        FROM Compensation_Leave
        WHERE request_ID = @request_ID

    IF (@replacementemp IS NOT NULL) -- Is there anyone to even replace me
        SET @availcheck = dbo.Is_On_Leave(@replacementemp, @startdate, @enddate) -- Yes? check if he is avail
    ELSE
        SET @availcheck = 0

    SET @avail2check = 
        dbo.checkingifreplacingsomeoneelse(@replacementemp,@startdate,@enddate)

    -- Final check
    IF (@availcheck = 1 AND @avail2check = 1 AND @spentcheck = 1 AND @reasoncheck = 1)
    BEGIN
        UPDATE Leave
        SET final_approval_status = 'approved'
        WHERE request_ID = @request_ID

        UPDATE Employee_Approve_Leave
        SET [status] = 'approved'
        WHERE Emp1_ID = @HR_ID 
            AND leave_id = @request_id

        INSERT INTO Employee_Replace_Employee VALUES (@myid, @replacementemp, @startdate, @enddate);
    END
    ELSE
    BEGIN
        UPDATE Leave
        SET final_approval_status = 'rejected'
        WHERE request_ID = @request_ID

        UPDATE Employee_Approve_Leave
        SET [status] = 'rejected'
        WHERE Emp1_ID = @HR_ID 
            AND leave_id = @request_id
    END
END;

GO

CREATE FUNCTION [checkingifreplacingsomeoneelse]
(
    @employee_id INT,
    @enddate     DATE,
    @startdate   DATE
)
RETURNS BIT
AS
BEGIN
    IF @employee_id IS NULL
        RETURN 0

    DECLARE @check BIT

    IF EXISTS (
        SELECT *
        FROM   Employee_Replace_Employee E
        WHERE  E.emp2_ID = @employee_id
               AND (
                   (E.from_date BETWEEN @startdate AND @enddate)
                   OR (E.to_date BETWEEN @startdate AND @enddate)
                   OR (@startdate BETWEEN E.from_date AND E.to_date)
                   OR (@enddate BETWEEN E.from_date AND E.to_date)
               )
    )
        SET @check = 0
    ELSE
        SET @check = 1

    RETURN @check
END

GO

-- Function to return the latest (maximum) of two given dates.
CREATE FUNCTION GetMaxDate
(
    @Date1 DATE,
    @Date2 DATE
)
RETURNS DATE
AS
BEGIN
    DECLARE @ResultDate DATE;

    -- Use a CASE expression to compare the two dates.
    SET @ResultDate = CASE
        -- If Date1 is later than Date2, return Date1.
        WHEN @Date1 >= @Date2 THEN @Date1
        -- Otherwise, return Date2.
        ELSE @Date2
    END;

    RETURN @ResultDate;
END

GO

-- Function to return the earliest (minimum) of two given dates.
CREATE FUNCTION GetMinDate
(
    @Date1 DATE,
    @Date2 DATE
)
RETURNS DATE
AS
BEGIN
    DECLARE @ResultDate DATE;

    -- Use a CASE expression to compare the two dates.
    SET @ResultDate = CASE
        -- If Date1 is later than Date2, return Date1.
        WHEN @Date1 <= @Date2 THEN @Date1
        -- Otherwise, return Date2.
        ELSE @Date2
    END;

    RETURN @ResultDate;
END

GO

-------------------------------------------------------
-------------------------------------------------------
--                      EMPLOYEE
-------------------------------------------------------
-------------------------------------------------------


CREATE FUNCTION EmployeeLoginValidation
(
    @employee_ID INT,
    @password VARCHAR(50)
)
RETURNS BIT
AS

BEGIN
    DECLARE @isValid BIT;

    IF EXISTS (
        SELECT 1
        FROM Employee
        WHERE employee_ID = @employee_ID
          AND password = @password
    )
        SET @isValid = 1;  -- Success
    ELSE
        SET @isValid = 0;  -- Failure

    RETURN @isValid;
END;

GO

CREATE FUNCTION MyPerformance
(
    @employee_ID INT,
    @semester CHAR(3)
)
RETURNS TABLE
AS

RETURN
(
    SELECT 
        P.performance_ID,
        P.emp_ID,
        E.first_name,
        E.last_name,
        P.rating,
        P.comments,
        P.semester
    FROM Performance P
    JOIN Employee E ON E.employee_ID = P.emp_ID
    WHERE P.emp_ID = @employee_ID
      AND P.semester = @semester
);

GO

CREATE FUNCTION MyAttendance
(
    @employee_ID INT
)
RETURNS TABLE
AS

RETURN
(
    SELECT 
        A.attendance_ID,
        A.date,
        A.check_in_time,
        A.check_out_time,
        A.total_duration,
        A.status
    FROM Attendance A
    JOIN Employee E ON E.employee_ID = A.emp_ID
    WHERE A.emp_ID = @employee_ID
      AND MONTH(A.date) = MONTH(CAST (GETDATE() AS DATE))
      AND YEAR(A.date) = YEAR(CAST (GETDATE() AS DATE))
      AND NOT (
          A.status = 'absent' 
          AND DATENAME(WEEKDAY, A.date) = E.official_day_off
      )
);

GO

CREATE FUNCTION Last_month_payroll
(
    @employee_ID INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        ID,
        emp_ID,
        payment_date,
        final_salary_amount,
        from_date,
        to_date,
        comments,
        bonus_amount,
        deductions_amount
    FROM Payroll
    WHERE emp_ID = @employee_ID
      AND MONTH(payment_date) = MONTH(DATEADD(MONTH, -1, CAST (GETDATE() AS DATE)))
      AND YEAR(payment_date) = YEAR(DATEADD(MONTH, -1, CAST (GETDATE() AS DATE)))
);

GO

CREATE FUNCTION Deductions_Attendance
(
    @employee_ID INT,
    @month INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        D.deduction_ID,
        D.emp_ID,
        D.date,
        D.amount,
        D.type,
        D.status,
        D.attendance_ID
    FROM Deduction D
    JOIN Attendance A ON D.attendance_ID = A.attendance_ID
    WHERE D.emp_ID = @employee_ID
      AND MONTH(D.date) = @month
      AND D.type = 'missing days' OR D.type = 'missing hours' 
);

GO

CREATE FUNCTION Is_On_Leave
(
    @employee_ID INT,
    @from_date DATE,
    @to_date DATE
)
RETURNS BIT
AS
BEGIN
    DECLARE @isOnLeave BIT;

    IF EXISTS (
        SELECT 1
       FROM
            (SELECT emp_ID, request_ID FROM Annual_Leave
            UNION
            SELECT emp_ID, request_ID FROM Accidental_Leave
            UNION
            SELECT emp_ID, request_ID FROM Medical_Leave
            UNION
            SELECT emp_ID, request_ID FROM Unpaid_Leave
            UNION
            SELECT emp_ID, request_ID FROM Compensation_Leave)  AS L INNER JOIN Leave ON Leave.request_ID = L.request_ID 
        WHERE L.emp_ID = @employee_ID
          AND (
              Leave.final_approval_status = 'approved'
              OR Leave.final_approval_status = 'pending'
          )
          AND (
              (@from_date BETWEEN Leave.start_date AND Leave.end_date)
              OR (@to_date BETWEEN Leave.start_date AND Leave.end_date)
              OR (Leave.start_date BETWEEN @from_date AND @to_date)
              OR (Leave.end_date BETWEEN @from_date AND @to_date)
          )
    ) BEGIN
        SET @isOnLeave = 1;
    END ELSE BEGIN
        SET @isOnLeave = 0;
    END

    RETURN @isOnLeave;
END;

GO
--Adel's function
CREATE FUNCTION Status_leaves
(
    @employee_ID INT
)
RETURNS TABLE
AS
RETURN
    
    (SELECT 
        L.request_ID,
        L.date_of_request,
        L.final_approval_status AS status
    FROM Leave L
    JOIN (
        SELECT emp_ID, request_ID FROM Annual_Leave
        UNION
        SELECT emp_ID, request_ID FROM Accidental_Leave
    ) AS StupidAh ON L.request_ID = StupidAh.request_ID
    WHERE StupidAh.emp_ID = @employee_ID
      AND MONTH(L.date_of_request) = MONTH(GETDATE())
      AND YEAR(L.date_of_request) = YEAR(GETDATE())
    );

GO

--Salma's stuff

--leaves
---------------------------------------------------------
-- Submit_annual
---------------------------------------------------------
---------------------------------------------------------
-- Submit_annual
---------------------------------------------------------
CREATE PROC Submit_annual
    @employee_id INT, 
    @replacement_emp INT, 
    @start_date DATE, 
    @end_date DATE 
AS
BEGIN
    -- Part-time check
    IF dbo.CheckIfPartTime(@employee_id) <> 0
    BEGIN
        PRINT 'Error! Part-time employees cannot apply for annual leave';
        RETURN;
    END

    -- Get department name
    DECLARE @dept_name VARCHAR(50);
    SELECT @dept_name = dept_name
    FROM dbo.Employee
    WHERE employee_ID = @employee_id;

    IF @dept_name IS NULL
    BEGIN
        PRINT 'Error! Employee department not found.';
        RETURN;
    END

    ----------------------------------------------------------------
    -- Case 1: HR department -> approval from HR Manager
    ----------------------------------------------------------------
    IF @dept_name = 'HR'
    BEGIN
        DECLARE @hr_manager INT;
        SELECT @hr_manager = E.emp_ID
        FROM Employee_Role E
        INNER JOIN Role_existsIn_Department R ON E.role_name = R.role_name
        WHERE R.role_name = 'HR Manager'
          AND dbo.Is_On_Leave(E.emp_ID, CAST(GETDATE() AS DATE), CAST(GETDATE() AS DATE)) = 0;

        IF @hr_manager IS NULL
        BEGIN
            PRINT 'Error! No HR manager available to approve you!';
            RETURN;
        END

        INSERT INTO Leave(date_of_request, start_date, end_date, final_approval_status)
        VALUES (CAST(GETDATE() AS DATE), @start_date, @end_date, 'pending');

        DECLARE @request_id INT;
        SELECT @request_id = SCOPE_IDENTITY();

        INSERT INTO Annual_Leave
        VALUES (@request_id, @employee_id, @replacement_emp);

        INSERT INTO Employee_Approve_Leave 
        VALUES (@hr_manager, @request_id, 'pending');

        RETURN;
    END

    ----------------------------------------------------------------
    -- Case 2: Other departments
    ----------------------------------------------------------------

    -- Find HR representative for this department
    DECLARE @hr_rep INT;
    SELECT @hr_rep = E.emp_ID
    FROM dbo.Employee_Role E
    INNER JOIN dbo.Role_existsIn_Department R ON E.role_name = R.role_name
    WHERE E.role_name LIKE 'HR_Representative%'
      AND SUBSTRING(E.role_name,
                    CHARINDEX('_', E.role_name, CHARINDEX('_', E.role_name) + 1) + 1,
                    LEN(E.role_name)) = @dept_name
      AND dbo.Is_On_Leave(E.emp_ID, CAST(GETDATE() AS DATE), CAST(GETDATE() AS DATE)) = 0;

    IF @hr_rep IS NULL
    BEGIN
        PRINT 'Error! HR representative for your department is on leave or not found';
        RETURN;
    END

    -- If the employee is a Dean or Vice -> President + HR rep
    IF dbo.Check_DeanOR_Vice(@employee_id) = 1
    BEGIN
        DECLARE @president_ID INT;
        SELECT @president_ID = emp_ID
        FROM dbo.Employee_Role
        WHERE LOWER(role_name) = 'President'
          AND dbo.Is_On_Leave(emp_ID, CAST(GETDATE() AS DATE), CAST(GETDATE() AS DATE)) = 0;

        IF @president_ID IS NULL
        BEGIN
            PRINT 'Error! President is on leave or not found';
            RETURN;
        END

        INSERT INTO Leave(date_of_request, start_date, end_date, final_approval_status)
        VALUES (CAST(GETDATE() AS DATE), @start_date, @end_date, 'pending');

        DECLARE @leave_id INT;
        SELECT @leave_id = SCOPE_IDENTITY();

        INSERT INTO Annual_Leave
        VALUES (@leave_id, @employee_id, @replacement_emp);

        INSERT INTO Employee_Approve_Leave 
        VALUES (@president_ID, @leave_id, 'pending'),
               (@hr_rep, @leave_id, 'pending');

        RETURN;
    END

    -- Regular employee -> Dean or Vice Dean + HR rep
    DECLARE @dean_ID INT;
    SELECT @dean_ID = E.emp_ID
    FROM dbo.Employee_Role E
    INNER JOIN dbo.Role_existsIn_Department R ON E.role_name = R.role_name
    WHERE R.department_name = @dept_name
      AND E.role_name = 'Dean'
      AND dbo.Is_On_Leave(E.emp_ID, CAST(GETDATE() AS DATE), CAST(GETDATE() AS DATE)) = 0;

    DECLARE @approver1 INT;

    IF @dean_ID IS NOT NULL
        SET @approver1 = @dean_ID;
    ELSE
    BEGIN
        DECLARE @vice_dean_ID INT;
        SELECT @vice_dean_ID = E.emp_ID
        FROM dbo.Employee_Role E
        INNER JOIN dbo.Role_existsIn_Department R ON E.role_name = R.role_name
        WHERE R.department_name = @dept_name
          AND E.role_name = 'Vice Dean'
          AND dbo.Is_On_Leave(E.emp_ID, CAST(GETDATE() AS DATE), CAST(GETDATE() AS DATE)) = 0;

        IF @vice_dean_ID IS NULL
        BEGIN
            PRINT 'Error! No Dean or Vice Dean available to approve your leave.';
            RETURN;
        END
        SET @approver1 = @vice_dean_ID;
    END

    -- Insert leave + approvers
    INSERT INTO Leave(date_of_request, start_date, end_date, final_approval_status)
    VALUES (CAST(GETDATE() AS DATE), @start_date, @end_date, 'pending');

    DECLARE @req_id INT;
    SELECT @req_id = SCOPE_IDENTITY();

    INSERT INTO Annual_Leave
    VALUES (@req_id, @employee_id, @replacement_emp);

    INSERT INTO Employee_Approve_Leave 
    VALUES (@approver1, @req_id, 'pending'),
           (@hr_rep, @req_id, 'pending');

END
GO


---------------------------------------------------------
-- Submit_accidental
---------------------------------------------------------
CREATE PROC Submit_accidental
    @employee_ID INT, 
    @start_date DATE, 
    @end_date DATE
AS
BEGIN
    -- Check if accidental leave is 1 day only
    IF @start_date <> @end_date
    BEGIN
        PRINT 'Error! Accidental leave must be for 1 day only';
        RETURN;
    END

    DECLARE @dept_name VARCHAR(50); 
    SELECT @dept_name = dept_name
    FROM dbo.Employee 
    WHERE employee_ID = @employee_ID;

    IF @dept_name IS NULL
    BEGIN
        PRINT 'Error! Employee not found.';
        RETURN;
    END

    ----------------------------------------------------------------
    -- Case 1: HR department -> HR Manager approval
    ----------------------------------------------------------------
    IF @dept_name = 'HR'
    BEGIN
        DECLARE @HR_manager INT;
        SELECT @HR_manager = E.emp_ID
        FROM Employee_Role E
        INNER JOIN Role_existsIn_Department R ON E.role_name = R.role_name
        WHERE R.role_name = 'HR Manager'
          AND dbo.Is_On_Leave(E.emp_ID, CAST(GETDATE() AS DATE), CAST(GETDATE() AS DATE)) = 0;

        IF @HR_manager IS NULL
        BEGIN
            PRINT 'Error! No HR manager is available to approve you!';
            RETURN;
        END

        INSERT INTO Leave(date_of_request, start_date, end_date, final_approval_status)
        VALUES (CAST(GETDATE() AS DATE), @start_date, @end_date, 'pending');

        DECLARE @request_id INT;
        SELECT @request_id = SCOPE_IDENTITY();

        INSERT INTO Accidental_Leave(request_ID, emp_ID)
        VALUES (@request_id, @employee_ID);

        INSERT INTO Employee_Approve_Leave
        VALUES (@HR_manager, @request_id, 'pending');

        RETURN;
    END

    ----------------------------------------------------------------
    -- Case 2: Regular employees -> HR representative of their department
    ----------------------------------------------------------------
    DECLARE @hr_rep INT;
    SELECT @hr_rep = E.emp_ID
    FROM dbo.Employee_Role E
    INNER JOIN dbo.Role_existsIn_Department R ON E.role_name = R.role_name
    WHERE E.role_name LIKE 'HR_Representative%' 
      AND SUBSTRING(
            E.role_name,
            CHARINDEX('_', E.role_name, CHARINDEX('_', E.role_name) + 1) + 1,
            LEN(E.role_name)
          ) = @dept_name;

    IF @hr_rep IS NULL OR dbo.Is_On_Leave(@hr_rep, CAST(GETDATE() AS DATE), CAST(GETDATE() AS DATE)) = 1
    BEGIN
        PRINT 'Error! HR representative for your department is on leave or not found.';
        RETURN;
    END

    INSERT INTO Leave(date_of_request, start_date, end_date, final_approval_status)
    VALUES (CAST(GETDATE() AS DATE), @start_date, @end_date, 'pending');

    DECLARE @leave_id INT;
    SELECT @leave_id = SCOPE_IDENTITY();

    INSERT INTO Accidental_Leave(request_ID, emp_ID)
    VALUES (@leave_id, @employee_ID);

    INSERT INTO Employee_Approve_Leave
    VALUES (@hr_rep, @leave_id, 'pending');

END
GO


---------------------------------------------------------
-- Submit_medical
---------------------------------------------------------
CREATE PROC Submit_medical
    @employee_ID INT, 
    @start_date DATE, 
    @end_date DATE, 
    @type VARCHAR(50), 
    @insurance_status BIT, 
    @disability_details VARCHAR(50), 
    @document_description VARCHAR(50), 
    @file_name VARCHAR(50)
AS
BEGIN
    -- Maternity checks
    IF (@type = 'maternity' AND dbo.CheckIfMale(@employee_ID) = 1) 
       OR (@type = 'maternity' AND dbo.CheckIfPartTime(@employee_ID) = 1)
    BEGIN
        PRINT 'Error! Male and part-time employees are not authorised to apply for maternity leaves';
        RETURN;
    END

    -- Get department name
    DECLARE @dept_name VARCHAR(50);
    SELECT @dept_name = dept_name
    FROM dbo.Employee
    WHERE employee_ID = @employee_ID;

    ----------------------------------------------------------------
    -- Case 1: HR employees -> Medical employee + HR Manager
    ----------------------------------------------------------------
    IF @dept_name = 'HR'
    BEGIN
        DECLARE @Medical_Employee INT;
        DECLARE @HR_Manager INT;

        -- Any Medical staff
        SELECT TOP 1 @Medical_Employee = E.emp_ID
        FROM Employee_Role E
        INNER JOIN Role_existsIn_Department R ON E.role_name = R.role_name
        WHERE R.department_name = 'Medical'
          AND dbo.Is_On_Leave(E.emp_ID, CAST(GETDATE() AS DATE), CAST(GETDATE() AS DATE)) = 0;

        -- HR Manager
        SELECT @HR_Manager = E.emp_ID
        FROM Employee_Role E
        INNER JOIN Role_existsIn_Department R ON E.role_name = R.role_name
        WHERE R.role_name = 'HR Manager'
          AND dbo.Is_On_Leave(E.emp_ID, CAST(GETDATE() AS DATE), CAST(GETDATE() AS DATE)) = 0;

        IF @Medical_Employee IS NULL OR @HR_Manager IS NULL
        BEGIN
            PRINT 'Error! No approvers available (Medical staff or HR Manager).';
            RETURN;
        END

        INSERT INTO Leave(date_of_request, start_date, end_date, final_approval_status)
        VALUES (CAST(GETDATE() AS DATE), @start_date, @end_date, 'pending');

        DECLARE @request_id INT;
        SELECT @request_id = SCOPE_IDENTITY();

        INSERT INTO Medical_Leave(request_ID, insurance_status, disability_details, type, emp_ID)
        VALUES (@request_id, @insurance_status, @disability_details, @type, @employee_ID);

        INSERT INTO Employee_Approve_Leave
        VALUES (@Medical_Employee, @request_id, 'pending'),
               (@HR_Manager, @request_id, 'pending');

        UPDATE Document 
        SET medical_ID = @request_id, description = @document_description
        WHERE file_name = @file_name;

        RETURN;
    END

    ----------------------------------------------------------------
    -- Case 2: Regular employees -> Medical staff + HR representative
    ----------------------------------------------------------------
    DECLARE @medical_doctor INT;
    DECLARE @hr_rep INT;

    -- Any Medical employee
    SELECT TOP 1 @medical_doctor = E.emp_ID
    FROM Employee_Role E
    INNER JOIN Role_existsIn_Department R ON E.role_name = R.role_name
    WHERE R.department_name = 'Medical'
      AND dbo.Is_On_Leave(E.emp_ID, CAST(GETDATE() AS DATE), CAST(GETDATE() AS DATE)) = 0;

    -- HR representative for employee's department
    SELECT @hr_rep = E.emp_ID
    FROM dbo.Employee_Role E
    INNER JOIN dbo.Role_existsIn_Department R ON E.role_name = R.role_name
    WHERE E.role_name LIKE 'HR_Representative%' 
      AND SUBSTRING(E.role_name,
                    CHARINDEX('_', E.role_name, CHARINDEX('_', E.role_name) + 1) + 1,
                    LEN(E.role_name)) = @dept_name;

    IF @medical_doctor IS NULL OR @hr_rep IS NULL 
       OR dbo.Is_On_Leave(@hr_rep, CAST(GETDATE() AS DATE), CAST(GETDATE() AS DATE)) = 1
    BEGIN
        PRINT 'Error! No approvers available (Medical staff or HR representative).';
        RETURN;
    END

    INSERT INTO Leave(date_of_request, start_date, end_date, final_approval_status)
    VALUES (CAST(GETDATE() AS DATE), @start_date, @end_date, 'pending');

    DECLARE @leave_id INT;
    SELECT @leave_id = SCOPE_IDENTITY();

    INSERT INTO Medical_Leave
    VALUES (@leave_id, @insurance_status, @disability_details, @type, @employee_ID);

    -- 🔥 FIXED: replaced @request_id with @leave_id
    INSERT INTO Employee_Approve_Leave
    VALUES (@medical_doctor, @leave_id, 'pending'),
           (@hr_rep, @leave_id, 'pending');

    UPDATE Document 
    SET medical_ID = @leave_id, description = @document_description
    WHERE file_name = @file_name;
END
GO

---------------------------------------------------------
-- Submit_unpaid
---------------------------------------------------------
CREATE PROC Submit_unpaid
@employee_ID INT, 
@start_date DATE, 
@end_date DATE, 
@document_description VARCHAR(50), 
@file_name VARCHAR(50)
AS
BEGIN
IF dbo.CheckIfPartTime(@employee_ID) = 0
BEGIN

        INSERT INTO Leave(date_of_request, [start_date], end_date, final_approval_status)
        VALUES (CAST(GETDATE() AS DATE), @start_date, @end_date, 'pending');

        DECLARE @request_id INT = SCOPE_IDENTITY();

        INSERT INTO Unpaid_Leave(request_ID, emp_ID)
        VALUES (@request_id, @employee_ID);

        UPDATE Document
        SET unpaid_ID = @request_id
        WHERE description = @document_description
          AND file_name  = @file_name
          AND emp_ID     = @employee_ID;


        DECLARE @dept_name VARCHAR(50);
        SELECT @dept_name = dept_name
        FROM Employee 
        WHERE employee_ID = @employee_ID;

        DECLARE @president_ID INT;
        SELECT @president_ID = ER.emp_ID
        FROM Employee_Role ER
        WHERE LOWER(ER.role_name) = 'president'
          AND dbo.Is_On_Leave(ER.emp_ID, CAST(GETDATE() AS DATE), CAST(GETDATE() AS DATE)) = 0;

        DECLARE @vice_president_ID INT;
        SELECT @vice_president_ID = ER.emp_ID
        FROM Employee_Role ER
        WHERE LOWER(ER.role_name) = 'vice president'
        AND dbo.Is_On_Leave(ER.emp_ID, CAST(GETDATE() AS DATE), CAST(GETDATE() AS DATE)) = 0;

        DECLARE @hr_manager INT;
        SELECT @hr_manager = ER.emp_ID
        FROM Employee_Role ER
        WHERE ER.role_name = 'HR Manager'
          AND dbo.Is_On_Leave(ER.emp_ID, CAST(GETDATE() AS DATE), CAST(GETDATE() AS DATE)) = 0;

  

        DECLARE @dean_ID INT = NULL;
        DECLARE @vice_dean_ID INT = NULL;
        DECLARE @approver_dean INT = NULL;

        SELECT @dean_ID = ER.emp_ID
        FROM Employee_Role ER
        JOIN Role_existsIn_Department RD ON ER.role_name = RD.role_name
        WHERE RD.department_name = @dept_name
          AND ER.role_name = 'Dean'
          AND dbo.Is_On_Leave(ER.emp_ID, CAST(GETDATE() AS DATE), CAST(GETDATE() AS DATE)) = 0;

        IF @dean_ID IS NOT NULL
            SET @approver_dean = @dean_ID;
        ELSE
        BEGIN
            SELECT @vice_dean_ID = ER.emp_ID
            FROM Employee_Role ER
            JOIN Role_existsIn_Department RD ON ER.role_name = RD.role_name
            WHERE RD.department_name = @dept_name
              AND ER.role_name = 'Vice Dean'
              AND dbo.Is_On_Leave(ER.emp_ID, CAST(GETDATE() AS DATE), CAST(GETDATE() AS DATE)) = 0;

            SET @approver_dean = @vice_dean_ID;
        END

     
        DECLARE @hr_rep INT;
        SELECT @hr_rep = ER.emp_ID
        FROM Employee_Role ER
        JOIN Role_existsIn_Department RD ON ER.role_name = RD.role_name
        WHERE ER.role_name LIKE 'HR_Representative_%'
          AND SUBSTRING(
                ER.role_name,
                CHARINDEX('_', ER.role_name, CHARINDEX('_', ER.role_name) + 1) + 1,
                LEN(ER.role_name)
              ) = @dept_name
          AND dbo.Is_On_Leave(ER.emp_ID, CAST(GETDATE() AS DATE), CAST(GETDATE() AS DATE)) = 0;

        -- Case 1: HR employee submits unpaid leave
        IF @dept_name = 'HR'
        BEGIN
            IF @hr_manager IS NULL OR (@president_ID IS NULL AND @vice_president_ID IS NULL)
                RETURN;

            DECLARE @upperboard_hr INT;
            SET @upperboard_hr = ISNULL(@president_ID, @vice_president_ID);

            INSERT INTO Employee_Approve_Leave(emp1_ID, leave_ID, status)
            VALUES (@upperboard_hr, @request_id, 'pending'),
                   (@hr_manager,   @request_id, 'pending');
        END
            -- Case 2: Employee is Dean or Vice Dean
      ELSE IF dbo.Check_DeanOR_Vice(@employee_ID) = 1
        BEGIN
            IF @hr_rep IS NULL OR (@president_ID IS NULL AND @vice_president_ID IS NULL)
                RETURN;

            DECLARE @upperboard_dean INT;
            SET @upperboard_dean = ISNULL(@president_ID, @vice_president_ID);

            INSERT INTO Employee_Approve_Leave(emp1_ID, leave_ID, status)
            VALUES (@upperboard_dean, @request_id, 'pending'),
                   (@hr_rep,         @request_id, 'pending');
        END
        ELSE
        BEGIN
            IF @approver_dean IS NULL OR @hr_rep IS NULL 
               OR (@president_ID IS NULL AND @vice_president_ID IS NULL)
                RETURN;

            DECLARE @upperboard_regular INT;
            SET @upperboard_regular = ISNULL(@president_ID, @vice_president_ID);

            INSERT INTO Employee_Approve_Leave(emp1_ID, leave_ID, status)
            VALUES (@approver_dean,       @request_id, 'pending'),  -- higher rank in dept
                   (@upperboard_regular,  @request_id, 'pending'),  -- President or VP
                   (@hr_rep,              @request_id, 'pending');  -- HR rep
        END
    END
    ELSE
    BEGIN
        -- Part-time employee so do nothing 
        RETURN;
    END
END
GO


---------------------------------------------------------
-- Submit_compensation
---------------------------------------------------------
CREATE PROC Submit_compensation
    @reason VARCHAR(50),
    @compensation_date DATE,
    @date_of_original_workday DATE,
    @emp_ID INT,
    @replacement_emp INT
AS
BEGIN
    DECLARE @dept_name VARCHAR(50);
    SELECT @dept_name = dept_name
    FROM dbo.Employee
    WHERE employee_ID = @emp_ID;

    ----------------------------------------------------------------
    -- Case 1: HR employees -> HR Manager approval
    ----------------------------------------------------------------
    IF @dept_name = 'HR'
    BEGIN
        DECLARE @HR_manager INT;
        SELECT @HR_manager = E.emp_ID
        FROM Employee_Role E
        INNER JOIN Role_existsIn_Department R ON E.role_name = R.role_name
        WHERE LOWER(E.role_name) = 'hr manager';

        IF @HR_manager IS NULL OR dbo.Is_On_Leave(@HR_manager, CAST(GETDATE() AS DATE), CAST(GETDATE() AS DATE)) = 1
        BEGIN
            PRINT 'Error! HR Manager is unavailable.';
            RETURN;
        END

    
        INSERT INTO Leave (date_of_request, start_date, end_date, final_approval_status)
        VALUES (CAST(GETDATE() AS DATE), @compensation_date, @compensation_date, 'pending');

        DECLARE @request_ID INT;
        SELECT @request_ID = SCOPE_IDENTITY();

        INSERT INTO Compensation_Leave (request_ID, reason, date_of_original_workday, emp_ID, replacement_emp)
        VALUES (@request_ID, @reason, @date_of_original_workday, @emp_ID, @replacement_emp);

        INSERT INTO Employee_Approve_Leave (emp1_ID, leave_ID, status)
        VALUES (@HR_manager, @request_ID, 'pending');

        RETURN;
    END

  

    ----------------------------------------------------------------
    -- Case 2: Regular employees -> HR Representative for their department
    ----------------------------------------------------------------
    DECLARE @hr_rep INT;
    SELECT @hr_rep = E.emp_ID
    FROM dbo.Employee_Role E
    INNER JOIN dbo.Role_existsIn_Department R ON E.role_name = R.role_name
    WHERE E.role_name LIKE 'HR_Representative%' 
      AND SUBSTRING(E.role_name,
                    CHARINDEX('_', E.role_name, CHARINDEX('_', E.role_name) + 1) + 1,
                    LEN(E.role_name)) = @dept_name;

    IF @hr_rep IS NULL OR dbo.Is_On_Leave(@hr_rep, CAST(GETDATE() AS DATE), CAST(GETDATE() AS DATE)) = 1
    BEGIN
        PRINT 'Error! Your HR representative is unavailable.';
        RETURN;
    END

    INSERT INTO Leave(date_of_request, start_date, end_date, final_approval_status)
    VALUES (CAST(GETDATE() AS DATE), @compensation_date, @compensation_date, 'pending');

    DECLARE @leave_ID INT;
    SELECT @leave_ID = SCOPE_IDENTITY();

    INSERT INTO Compensation_Leave(request_ID, reason, date_of_original_workday, emp_ID, replacement_emp)
    VALUES (@leave_ID, @reason, @date_of_original_workday, @emp_ID, @replacement_emp);

    INSERT INTO Employee_Approve_Leave
    VALUES (@hr_rep,  @leave_ID, 'pending');

END
GO


--Upperboard approvals
CREATE PROC Upperboard_approve_annual
    @request_ID INT,
    @Upperboard_ID INT,
    @replacement_ID INT
AS
BEGIN
    IF EXISTS (SELECT 1 
    FROM Employee_Approve_Leave
    WHERE emp1_ID = @Upperboard_ID) 
    BEGIN
    DECLARE @emp_ID INT; 
    SELECT @emp_ID = emp_ID
    FROM Annual_Leave 
    WHERE request_ID = @request_ID;

    DECLARE @replacee_role VARCHAR(50);
    SELECT @replacee_role = role_name
    FROM Employee_Role 
    WHERE emp_ID = @emp_ID;

    DECLARE @replacer_role VARCHAR(50);
    SELECT @replacer_role = role_name
    FROM Employee_Role
    WHERE emp_ID = @replacement_ID;

    DECLARE @replacee_dept VARCHAR(50);
    SELECT @replacee_dept = department_name
    FROM Role_existsIn_Department
    WHERE role_name = @replacee_role;

    DECLARE @replacer_dept VARCHAR(50);
    SELECT @replacer_dept = department_name
    FROM Role_existsIn_Department
    WHERE role_name = @replacer_role;

    DECLARE @start_date DATE 
    SELECT @start_date = L.start_date 
    FROM Leave L 
    WHERE request_ID = @request_ID

    DECLARE @end_date DATE 
    SELECT @end_date =  L.end_date 
    FROM Leave L 
    WHERE request_ID = @request_ID


    IF (dbo.Is_On_Leave(@replacement_ID,  @start_date, @end_date) = 0
        AND @replacee_dept = @replacer_dept) 
    BEGIN
  UPDATE Employee_Approve_Leave
  SET status = 'approved' 
  WHERE emp1_ID = @Upperboard_ID AND leave_ID = @request_ID 
    END
    ELSE
    BEGIN
         UPDATE Employee_Approve_Leave
  SET status = 'rejected' 
  WHERE emp1_ID = @Upperboard_ID AND leave_ID = @request_ID 
    END
    END 
    ELSE 
    BEGIN 
    PRINT 'Error! You are not authorised to approve/reject this leave'
    END
END
GO


--i think this is done but someone pls check 
CREATE PROC Upperboard_approve_unpaids
@request_ID INT,
@Upperboard_ID INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Unpaid_Leave WHERE request_ID = @request_ID)
        RETURN;

    IF NOT EXISTS (
        SELECT 1
        FROM Employee_Role
        WHERE emp_ID = @Upperboard_ID
          AND role_name IN ('Dean','Vice Dean','President')
    )
        RETURN;

    IF EXISTS (
  
        SELECT 1
        FROM Document D
        WHERE D.unpaid_ID = @request_ID          
          AND LOWER(D.type) = 'memo'             
          AND D.status = 'valid'                 
          AND ISNULL(D.description,'') <> ''     
    )
    BEGIN
 
        UPDATE Employee_Approve_Leave
        SET status = 'approved'
        WHERE emp1_ID  = @Upperboard_ID
          AND leave_ID = @request_ID
          AND status   = 'pending';
    END
    ELSE
    BEGIN
        UPDATE Employee_Approve_Leave
        SET status = 'rejected'
        WHERE emp1_ID  = @Upperboard_ID
          AND leave_ID = @request_ID
          AND status   = 'pending';
    END
END;
GO



CREATE PROC Dean_andHR_Evaluation
@employee_ID INT,
@rating INT,
@comment VARCHAR(50), 
@semester CHAR(3)
AS 
BEGIN 
INSERT INTO Performance VALUES(@rating, @comment, @semester, @employee_ID)
END 
GO

--**helper functions**
CREATE FUNCTION CheckIfMale(@employee_ID INT)
RETURNS BIT
AS
BEGIN
    DECLARE @male BIT = 0;
    DECLARE @gender CHAR(1);

    SELECT @gender = gender
    FROM Employee
    WHERE employee_ID = @employee_ID;

    IF @gender = 'M'
        SET @male = 1;

    RETURN @male;
END;
GO


CREATE FUNCTION Check_DeanOR_Vice(@employee_ID INT)
RETURNS BIT
AS
BEGIN
    DECLARE @X BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM Employee_Role
        WHERE  emp_ID = @employee_ID
        AND (role_name = 'Dean' OR role_name = 'Vice Dean')
    )
        SET @X = 1;

    RETURN @X;
END;
GO


CREATE FUNCTION CheckIfPartTime (@employee_ID INT)
RETURNS BIT
AS
BEGIN
    DECLARE @Y BIT = 0;
    DECLARE @contract_type VARCHAR(50);

    SELECT @contract_type = type_of_contract
    FROM Employee
    WHERE employee_ID = @employee_ID;

    IF @contract_type = 'part_time'
        SET @Y = 1;

    RETURN @Y;
END;

GO

CREATE FUNCTION GetHighestRankEmployee
(
    @department_name VARCHAR(50),
    @role_name VARCHAR(50)
)
RETURNS INT
AS
BEGIN
    DECLARE @employee_ID INT;

    SELECT TOP 1 @employee_ID = E.employee_ID
    FROM Employee AS E
    INNER JOIN Employee_Role AS ER ON E.employee_ID = ER.emp_ID
    INNER JOIN Role AS R ON ER.role_name = R.role_name
    WHERE
        (@department_name IS NULL OR E.dept_name = @department_name)
        AND (@role_name IS NULL OR ER.role_name = @role_name)
        AND dbo.Is_On_Leave(E.employee_ID, CAST(GETDATE() AS DATE), CAST(GETDATE() AS DATE)) = 0
    ORDER BY R.rank ASC;

    RETURN @employee_ID;
END;
