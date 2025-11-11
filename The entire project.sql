CREATE DATABASE University_HR_ManagementSystem_Team_8;

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
        password VARCHAR(50),
        address VARCHAR(50),
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
        salary DECIMAL(10,2),
        hire_date DATE,
        last_working_date DATE,
        dept_name VARCHAR(50),
    
        PRIMARY KEY (employee_ID),
        FOREIGN KEY (dept_name) REFERENCES Department(name),

        CHECK (type_of_contract IN ('full_time', 'part_time')),
        CHECK (employment_status IN ('active', 'onleave', 'notice_period', 'resigned'))
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
        FOREIGN KEY (department_name) REFERENCES Department(department_name),
        FOREIGN KEY (role_name) REFERENCES Role(role_name)
    );

    -- 7. Leave
    CREATE TABLE Leave (
        request_ID INT IDENTITY(1,1),
        date_of_request DATE,
        start_date DATE,
        end_date DATE,
        num_days AS end_date - start_date,
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
        type VARCHAR(50),
        emp_ID INT,

        PRIMARY KEY (request_ID),
        FOREIGN KEY (request_ID) REFERENCES Leave(request_ID),
        FOREIGN KEY (emp_ID) REFERENCES Employee(employee_ID),

        CHECK (type IN ('sick', 'maternity'))
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
        document_ID INT IDENTITY(1,1) PRIMARY KEY,
        type VARCHAR(50),
        description VARCHAR(50),
        file_name VARCHAR(50),
        creation_date DATE,
        expiry_date DATE,
        status VARCHAR(50),
        emp_ID INT,
        medical_ID INT,
        unpaid_ID INT,

        PRIMARY KEY (document_ID),
        FOREIGN KEY (emp_ID) REFERENCES Employee(employee_ID),
        FOREIGN KEY (medical_ID) REFERENCES Medical_Leave(request_ID),
        FOREIGN KEY (unpaid_id) REFERENCES Unpaid_Leave(request_ID),

        CHECK (status IN ('valid', 'expired'))
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
        date DATE,
        check_in_time TIME,
        check_out_time TIME,
        total_duration AS (check_out_time) - (check_in_time),
        status VARCHAR(50) DEFAULT 'absent',
        emp_ID INT,

        PRIMARY KEY (attendance_ID),
        FOREIGN KEY (emp_ID) REFERENCES Employee(employee_ID),

        CHECK (status IN ('absent', 'attended'))
    );

    -- 16. Deduction
    CREATE TABLE Deduction (
        deduction_ID INT IDENTITY(1,1),
        emp_ID INT,
        date DATE,
        amount DECIMAL(10,2),
        type VARCHAR(50),
        status VARCHAR(50) DEFAULT 'pending',
        unpaid_ID INT,
        attendance_ID INT,

        PRIMARY KEY (deduction_ID),
        FOREIGN KEY (emp_ID) REFERENCES Employee(employee_ID),
        FOREIGN KEY (unpaid_ID) REFERENCES Unpaid_Leave(request_ID),
        FOREIGN KEY (attendance_ID) REFERENCES Attendance(attendance_ID),

        CHECK (type IN ('unpaid', 'missing_hours', 'missing_days')),
        CHECK (status IN ('pending', 'finalized'))
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
        Emp1_ID INT,
        Emp2_ID INT,
        from_date DATE,
        to_date DATE,

        PRIMARY KEY (Emp1_ID, Emp2_ID),
        FOREIGN KEY (Emp1_ID) REFERENCES Employee(employee_ID),
        FOREIGN KEY (Emp2_ID) REFERENCES Employee(employee_ID)
    );

    -- 19. Employee_Approve_Leave
    CREATE TABLE Employee_Approve_Leave (
        Emp1_ID INT,
        Leave_ID INT,
        status VARCHAR(50) DEFAULT 'pending',

        PRIMARY KEY (Emp1_ID, Leave_ID),
        FOREIGN KEY (Emp1_ID) REFERENCES Employee(employee_ID),
        FOREIGN KEY (Leave_ID) REFERENCES Leave(request_ID),

        CHECK (status IN ('approved', 'rejected', 'pending'))
    );

    -- TODO: create assertions
    -- TODO: apply advanced checks

GO;

------------------------------------------------------------
--                      GENERAL PROCEDURES
------------------------------------------------------------

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

GO;

CREATE PROC dropAllProceduresFunctionsViews AS
    
    --TODO: finish this after finishing all the other functions adn procedures

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

-- fix the syntax errors in the creating views part

CREATE PROC allEmployeeProfiles AS
    
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

CREATE PROC noEmployeeDept AS

    CREATE VIEW noEmployeeDept AS
    SELECT 
        dept_name AS department_name,
        COUNT(employee_ID) AS num_employees
    FROM Employee
    GROUP BY dept_name;

GO;

CREATE PROC  allPerformance AS

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
    WHERE P.semester = 'WIN';

GO;

CREATE PROC allRejectedMedicals AS

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

CREATE PROC allEmployeeAttendance AS

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
    INNER JOIN Employee E ON A.emp_ID = E.employee_ID
    WHERE A.date = CURDATE() - 1;

GO;

---------------------------------------------------------------
--                           ADMIN
---------------------------------------------------------------

CREATE PROC Update_Status_Doc AS
    UPDATE Document
    SET status = 'expired'
    WHERE expiry_date < CURDATE();

GO;

CREATE PROC Remove_Deductions AS
    DELETE FROM Deduction
    WHERE emp_ID IN (
        SELECT employee_ID
        FROM Employee
        WHERE employment_status = 'resigned'
    );

GO;

CREATE PROCEDURE Update_Employment_Status
    @empID INT
AS

    DECLARE @is_on_leave INT = 0;

    SELECT COUNT(*)
    INTO is_on_leave
    FROM Leave
    WHERE Leave.emp_ID = empID
        AND CURDATE() BETWEEN L.start_date AND L.end_date
        AND Leave.final_approval_status = 'approved';

    IF @is_on_leave > 0
        UPDATE Employee
        SET employment_status = 'onleave'
        WHERE employee_ID = @empID;
    ELSE
        UPDATE Employee
        SET employment_status = 'active'
        WHERE employee_ID = @empID;

GO;

CREATE PROC Create_Holiday AS
    
    CREATE TABLE Holiday (
        holiday_id INT IDENTITY(1,1) PRIMARY KEY,
        holiday_name VARCHAR(50),
        from_date DATE,
        to_date DATE
    );

GO;

CREATE PROC Add_Holiday
    @holiday_name VARCHAR(50),
    @from_date DATE,
    @to_date DATE
AS
    
    INSERT INTO Holiday (holiday_name, from_date, to_date)
    VALUES (@holiday_name, @from_date, @to_date);

GO;

CREATE PROC Intitiate_Attendance AS
    
    INSERT INTO Attendance (emp_ID, date)
    SELECT 
        employee_ID, 
        CURDATE()
    FROM Employee

    -- TODO: Not sure if I should add this

    /*WHERE employee_ID NOT IN (
        SELECT emp_ID 
        FROM Attendance 
        WHERE date = CURDATE()
    );*/

GO;

-- TODO: should I be sure on non-existent dates (for example, new record)
-- TODO: should I set it to 'attended' all the time
CREATE PROC Update_Attendance
    @emp_ID INT,
    @check_in TIME,
    @check_out TIME
AS

    UPDATE Attendance 
    SET status = 'attended',
    check_in_time = @check_in,
    check_out_tie = @check_out
    WHERE date = CURDATE()
        AND emp_ID = @emp_ID;

GO;

CREATE PROC Remove_Holiday AS
    
    DELETE A
    FROM Attendance A
    JOIN Holiday H
      ON A.date BETWEEN H.from_date AND H.to_date;

GO;

-- TODO: not sure how to compare the dates correctly
CREATE PROC Remove_DayOff
    @emp_ID INT
AS
    
    DELETE FROM Attendance
    WHERE emp_ID = @emp_ID
      AND status = 'absent'
      AND MONTH(date) = MONTH(CURDATE())
      AND YEAR(date) = YEAR(CURDATE())
      AND date = (
          SELECT official_day_off 
          FROM Employee 
          WHERE employee_ID = @emp_ID
      );

GO;

CREATE PROC Remove_Approved_Leaves
    @emp_ID INT
AS
    DELETE A
    FROM Attendance
    JOIN Leave ON Attendance.date BETWEEN Leave.start_date AND Leave.end_date
    WHERE Leave.emp_ID = @emp_ID
      AND L.final_approval_status = 'approved';

GO;

CREATE PROC Replace_Employee
    @Emp1_ID INT,
    @Emp2_ID INT,
    @from_date DATE,
    @to_date DATE
AS

    INSERT INTO Employee_Replace_Employee (Emp1_ID, Emp2_ID, from_date, to_date)
    VALUES (@Emp1_ID, @Emp2_ID, @from_date, @to_date);

GO;

----------------------------------------------------------
--                        HR
----------------------------------------------------------

-- TODO: still not sure how to check for passwords
CREATE FUNCTION HRLoginValidation
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

GO;

-- TODO: complete rest of HR

----------------------------------------------------------
--                         EMPLOYEE
----------------------------------------------------------

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

GO;

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

GO;

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
      AND MONTH(A.date) = MONTH(CURDATE())
      AND YEAR(A.date) = YEAR(CURDATE())
      AND NOT (
          A.status = 'absent' 
          AND DATENAME(WEEKDAY, A.date) = E.official_day_off
      )
);

GO;

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
      AND MONTH(payment_date) = MONTH(DATEADD(MONTH, -1, CURDATE()))
      AND YEAR(payment_date) = YEAR(DATEADD(MONTH, -1, CURDATE()))
);

GO;

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
      AND D.type = 'missing days' -- TODO: not sure if this is what I am supposed to check for
);

GO;

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
        FROM Leave L
        WHERE L.emp_ID = @employee_ID
          AND (
              L.final_approval_status = 'approved'
              OR L.final_approval_status = 'pending'
          )
          AND (
              @from_date BETWEEN L.start_date AND L.end_date
              OR @to_date BETWEEN L.start_date AND L.end_date
              OR (L.start_date BETWEEN @from_date AND @to_date)
              OR (L.end_date BETWEEN @from_date AND @to_date)
              -- not sure if one of these is useless, but I added all for good measure
          )
    )
        SET @isOnLeave = 1;
    ELSE
        SET @isOnLeave = 0;

    RETURN @isOnLeave;
END;

GO;

-- TODO: the submit annual question

CREATE FUNCTION Status_leaves
(
    @employee_ID INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
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
      AND MONTH(L.date_of_request) = MONTH(CURDATE())
      AND YEAR(L.date_of_request) = YEAR(CURDATE())
);

GO;

-- TODO: upper board approval part
-- TODO: apply for leaves
-- TODO: the dean/vice-dean functions and procedures