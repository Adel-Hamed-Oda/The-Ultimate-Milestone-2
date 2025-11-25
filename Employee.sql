-- TESTING
use test;

GO


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
        WHERE LOWER(role_name) = 'president'
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
        VALUES (@president_ID, @request_id, 'pending'),
               (@hr_rep, @request_id, 'pending');

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
    SELECT @request_id = SCOPE_IDENTITY();

    INSERT INTO Annual_Leave
    VALUES (@req_id, @employee_id, @replacement_emp);

    INSERT INTO Employee_Approve_Leave 
    VALUES (@approver1, @req_id, 'pending'),
           (@hr_rep, @request_id, 'pending');

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
    VALUES (@hr_rep, @request_id, 'pending');

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

   /* IF @dept_name IS NULL
    BEGIN
        PRINT 'Error! Employee not found.';
        RETURN;
    END*/ --idek if we need this so i made it a comment

    ----------------------------------------------------------------
    -- Case 1: HR employees -> any Medical employee + HR Manager approval
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
        SET medical_ID = @request_id, description = @document_description, file_name = @file_name
        WHERE emp_ID = @employee_ID;

        RETURN;
    END


    ----------------------------------------------------------------
    -- Case 2: Regular employees -> any Medical staff + HR representative of their department
    ----------------------------------------------------------------
    DECLARE @medical_doctor INT;
    DECLARE @hr_rep INT;

    -- Any Medical employee
    SELECT TOP 1 @Medical_Employee = E.emp_ID
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

    IF @Medical_Employee IS NULL OR @hr_rep IS NULL 
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

    INSERT INTO Employee_Approve_Leave
    VALUES (@medical_doctor, @request_id, 'pending'),
           (@hr_rep, @request_id, 'pending');

    UPDATE Document 
    SET medical_ID = @leave_id, description = @document_description, file_name = @file_name
    WHERE emp_ID = @employee_ID;

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
    DECLARE @num_days INT = DATEDIFF(DAY, @start_date, @end_date) + 1;
        IF @num_days > 30
            RETURN;   -- duration too long, silently stop

        DECLARE @req_year INT = YEAR(@start_date);

        IF EXISTS (
            SELECT 1
            FROM Unpaid_Leave U
            JOIN [Leave] L ON U.request_ID = L.request_ID
            WHERE U.emp_ID = @employee_ID
              AND L.final_approval_status = 'approved'
              AND YEAR(L.date_of_request) = @req_year
        )
            RETURN;   -- already has an approved unpaid leave this year

        INSERT INTO Leave(date_of_request, start_date, end_date, final_approval_status)
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

        --dont handle medical doctors
        IF EXISTS (
            SELECT 1
            FROM Employee_Role ER
            WHERE ER.emp_ID   = @employee_ID
              AND ER.role_name = 'Medical Doctor'
        )
        BEGIN
            -- Undo what we just inserted (no printing, just silent rollback)
            DELETE FROM Employee_Approve_Leave WHERE leave_ID = @request_id;
            DELETE FROM Unpaid_Leave           WHERE request_ID = @request_id;
            DELETE FROM [Leave]                WHERE request_ID = @request_id;
            RETURN;
        END

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

    
        INSERT INTO Leave  (date_of_request, start_date, end_date, final_approval_status)
        VALUES (CAST(GETDATE() AS DATE), @compensation_date, @compensation_date, 'pending');

        DECLARE @request_ID INT;
        SELECT @request_ID = SCOPE_IDENTITY();

        INSERT INTO Compensation_Leave
        VALUES (@request_ID, @reason, @date_of_original_workday, @emp_ID, @replacement_emp);

        INSERT INTO Employee_Approve_Leave
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
  SET status = 'approved' 
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

GO

SELECT E.first_name 
FROM Employee E
WHERE E.employee_id = dbo.GetHighestRankEmployee(NULL, 'President');

--TODO: Handle unpaid leave submission and unpaid leave approval as I have a lot of questions about how they work 
