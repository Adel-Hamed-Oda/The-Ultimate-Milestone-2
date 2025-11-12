-- TODO: same as HR
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
      AND MONTH(A.date) = MONTH(GETDATE())
      AND YEAR(A.date) = YEAR(GETDATE())
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
      AND MONTH(payment_date) = MONTH(DATEADD(MONTH, -1, GETDATE()))
      AND YEAR(payment_date) = YEAR(DATEADD(MONTH, -1, GETDATE()))
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
    --  AND D.type = 'missing days' -- TODO: not sure if this is what I am supposed to check for
      AND D.type IN ('missing_hours', 'missing_days')  -- Both attendance related
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
        FROM Leave_ L
        WHERE L.request_ID IN (
            SELECT request_ID FROM Annual_Leave WHERE emp_ID = @employee_ID
            UNION
            SELECT request_ID FROM Accidental_Leave WHERE emp_ID = @employee_ID
            UNION
            SELECT request_ID FROM Medical_Leave WHERE emp_ID = @employee_ID
            UNION
            SELECT request_ID FROM Unpaid_Leave WHERE emp_ID = @employee_ID
            UNION
            SELECT request_ID FROM Compensation_Leave WHERE emp_ID = @employee_ID
        )
        AND (L.final_approval_status = 'approved' OR L.final_approval_status = 'pending')
        AND (
            @from_date BETWEEN L.start_date AND L.end_date
            OR @to_date BETWEEN L.start_date AND L.end_date
            OR (L.start_date BETWEEN @from_date AND @to_date)
            OR (L.end_date BETWEEN @from_date AND @to_date)
        )
    )
        SET @isOnLeave = 1;
    ELSE
        SET @isOnLeave = 0;

    RETURN @isOnLeave;
END;

/*      does employee ID exist in any leave table ?
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
        FROM Leave L --- change Leave to Leave_
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
*/
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
    FROM Leave_ L
    JOIN (
        SELECT emp_ID, request_ID FROM Annual_Leave
        UNION
        SELECT emp_ID, request_ID FROM Accidental_Leave
    ) AS StupidAh ON L.request_ID = StupidAh.request_ID
    WHERE StupidAh.emp_ID = @employee_ID
      AND MONTH(L.date_of_request) = MONTH(GETDATE())
      AND YEAR(L.date_of_request) = YEAR(GETDATE())
);

GO;

-- TODO: upper board approval part
-- TODO: apply for leaves
-- TODO: the dean/vice-dean functions and procedures




CREATE PROC Submit_annual
    @employee_ID INT,
    @replacement_emp INT,
    @start_date DATE,
    @end_date DATE
AS
BEGIN
    DECLARE @request_ID INT;
    DECLARE @dept_name VARCHAR(50);
    DECLARE @contract_type VARCHAR(50);
    DECLARE @dean_ID INT;
    DECLARE @vice_dean_ID INT;
    DECLARE @hr_rep_ID INT;

    -- Check if employee is part-time (not eligible for annual leave)
    SELECT @contract_type = type_of_contract, @dept_name = dept_name
    FROM Employee
    WHERE employee_ID = @employee_ID;

    IF @contract_type = 'part_time'
    BEGIN
        RETURN; -- Part-time employees are not eligible
    END

    -- Insert into Leave table
    INSERT INTO Leave_ (date_of_request, start_date, end_date, final_approval_status)
    VALUES (CAST(GETDATE() AS DATE), @start_date, @end_date, 'pending');

    SET @request_ID = SCOPE_IDENTITY();

    -- Insert into Annual_Leave table
    INSERT INTO Annual_Leave (request_ID, emp_ID, replacement_emp)
    VALUES (@request_ID, @employee_ID, @replacement_emp);

    -- Get Dean ID from the employee's department
    SELECT @dean_ID = E.employee_ID
    FROM Employee E
    JOIN Employee_Role ER ON E.employee_ID = ER.emp_ID
    JOIN Role R ON ER.role_name = R.role_name
    WHERE E.dept_name = @dept_name
      AND R.role_name LIKE 'Dean%'
      AND E.employment_status NOT IN ('resigned', 'notice_period');

    -- Get Vice-Dean ID from the employee's department
    SELECT @vice_dean_ID = E.employee_ID
    FROM Employee E
    JOIN Employee_Role ER ON E.employee_ID = ER.emp_ID
    JOIN Role R ON ER.role_name = R.role_name
    WHERE E.dept_name = @dept_name
      AND R.role_name LIKE 'Vice_Dean%'
      AND E.employment_status NOT IN ('resigned', 'notice_period');

    -- Get HR Representative ID for the department
    SELECT @hr_rep_ID = E.employee_ID
    FROM Employee E
    JOIN Employee_Role ER ON E.employee_ID = ER.emp_ID
    WHERE ER.role_name = 'HR_Representative_' + @dept_name
      AND E.employment_status NOT IN ('resigned', 'notice_period');

    -- Populate approval hierarchy
    -- If Dean is on leave, Vice-Dean approves; otherwise Dean approves
    IF EXISTS (
        SELECT 1 FROM Employee WHERE employee_ID = @dean_ID AND employment_status = 'onleave'
    )
    BEGIN
        -- Vice-Dean approves instead
        INSERT INTO Employee_Approve_Leave (emp1_ID, leave_ID, status)
        VALUES (@vice_dean_ID, @request_ID, 'pending');
    END
    ELSE
    BEGIN
        -- Dean approves
        INSERT INTO Employee_Approve_Leave (emp1_ID, leave_ID, status)
        VALUES (@dean_ID, @request_ID, 'pending');
    END

    -- HR Representative approval (final approval)
    INSERT INTO Employee_Approve_Leave (emp1_ID, leave_ID, status)
    VALUES (@hr_rep_ID, @request_ID, 'pending');
END;

GO;

-- ================================================================
-- 2.5.i - Upperboard Approve Annual Leave
-- ================================================================
CREATE PROC Upperboard_approve_annual
    @request_ID INT,
    @Upperboard_ID INT,
    @replacement_ID INT
AS
BEGIN
    DECLARE @dept_name VARCHAR(50);
    DECLARE @replacement_dept VARCHAR(50);
    DECLARE @is_replacement_on_leave BIT;
    DECLARE @start_date DATE;
    DECLARE @end_date DATE;

    -- Get leave details
    SELECT @start_date = start_date, @end_date = end_date
    FROM Leave_
    WHERE request_ID = @request_ID;

    -- Get employee's department
    SELECT @dept_name = E.dept_name
    FROM Annual_Leave AL
    JOIN Employee E ON AL.emp_ID = E.employee_ID
    WHERE AL.request_ID = @request_ID;

    -- Get replacement employee's department
    SELECT @replacement_dept = dept_name
    FROM Employee
    WHERE employee_ID = @replacement_ID;

    -- Check if replacement is on leave
    SET @is_replacement_on_leave = dbo.Is_On_Leave(@replacement_ID, @start_date, @end_date);

    -- Approve if replacement works in same department and is not on leave
    IF @dept_name = @replacement_dept AND @is_replacement_on_leave = 0
    BEGIN
        -- Update the approval status for this upperboard member
        UPDATE Employee_Approve_Leave
        SET status = 'approved'
        WHERE leave_ID = @request_ID
          AND emp1_ID = @Upperboard_ID;
    END
    ELSE
    BEGIN
        -- Reject the leave
        UPDATE Employee_Approve_Leave
        SET status = 'rejected'
        WHERE leave_ID = @request_ID
          AND emp1_ID = @Upperboard_ID;

        -- Update final status to rejected
        UPDATE Leave_
        SET final_approval_status = 'rejected'
        WHERE request_ID = @request_ID;
    END
END;

GO;

-- ================================================================
-- 2.5.j - Submit Accidental Leave
-- ================================================================
CREATE PROC Submit_accidental
    @employee_ID INT,
    @start_date DATE,
    @end_date DATE
AS
BEGIN
    DECLARE @request_ID INT;
    DECLARE @dept_name VARCHAR(50);
    DECLARE @contract_type VARCHAR(50);
    DECLARE @dean_ID INT;
    DECLARE @vice_dean_ID INT;
    DECLARE @hr_rep_ID INT;
    DECLARE @num_days INT;

    -- Check if employee is part-time (not explicitly stated, but assuming same as annual)
    SELECT @contract_type = type_of_contract, @dept_name = dept_name
    FROM Employee
    WHERE employee_ID = @employee_ID;

    -- Calculate number of days
    SET @num_days = DATEDIFF(DAY, @start_date, @end_date);

    -- Accidental leave duration should be only 1 day
    IF @num_days <> 1
    BEGIN
        RETURN; -- Invalid duration
    END

    -- Insert into Leave table
    INSERT INTO Leave_ (date_of_request, start_date, end_date, final_approval_status)
    VALUES (CAST(GETDATE() AS DATE), @start_date, @end_date, 'pending');

    SET @request_ID = SCOPE_IDENTITY();

    -- Insert into Accidental_Leave table
    INSERT INTO Accidental_Leave (request_ID, emp_ID)
    VALUES (@request_ID, @employee_ID);

    -- Get Dean ID
    SELECT @dean_ID = E.employee_ID
    FROM Employee E
    JOIN Employee_Role ER ON E.employee_ID = ER.emp_ID
    JOIN Role R ON ER.role_name = R.role_name
    WHERE E.dept_name = @dept_name
      AND R.role_name LIKE 'Dean%'
      AND E.employment_status NOT IN ('resigned', 'notice_period');

    -- Get Vice-Dean ID
    SELECT @vice_dean_ID = E.employee_ID
    FROM Employee E
    JOIN Employee_Role ER ON E.employee_ID = ER.emp_ID
    JOIN Role R ON ER.role_name = R.role_name
    WHERE E.dept_name = @dept_name
      AND R.role_name LIKE 'Vice_Dean%'
      AND E.employment_status NOT IN ('resigned', 'notice_period');

    -- Get HR Representative ID
    SELECT @hr_rep_ID = E.employee_ID
    FROM Employee E
    JOIN Employee_Role ER ON E.employee_ID = ER.emp_ID
    WHERE ER.role_name = 'HR_Representative_' + @dept_name
      AND E.employment_status NOT IN ('resigned', 'notice_period');

    -- Populate approval hierarchy
    IF EXISTS (
        SELECT 1 FROM Employee WHERE employee_ID = @dean_ID AND employment_status = 'onleave'
    )
    BEGIN
        INSERT INTO Employee_Approve_Leave (emp1_ID, leave_ID, status)
        VALUES (@vice_dean_ID, @request_ID, 'pending');
    END
    ELSE
    BEGIN
        INSERT INTO Employee_Approve_Leave (emp1_ID, leave_ID, status)
        VALUES (@dean_ID, @request_ID, 'pending');
    END

    -- HR Representative approval (final)
    INSERT INTO Employee_Approve_Leave (emp1_ID, leave_ID, status)
    VALUES (@hr_rep_ID, @request_ID, 'pending');
END;

GO;

-- ================================================================
-- 2.5.k - Submit Medical Leave
-- ================================================================
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
    DECLARE @request_ID INT;
    DECLARE @document_ID INT;
    DECLARE @contract_type VARCHAR(50);
    DECLARE @medical_doctor_ID INT;
    DECLARE @hr_rep_ID INT;
    DECLARE @dept_name VARCHAR(50);

    -- Check if maternity leave is for part-time (not eligible)
    SELECT @contract_type = type_of_contract, @dept_name = dept_name
    FROM Employee
    WHERE employee_ID = @employee_ID;

    IF @type = 'maternity' AND @contract_type = 'part_time'
    BEGIN
        RETURN; -- Part-time not eligible for maternity leave
    END

    -- Insert into Leave table
    INSERT INTO Leave_ (date_of_request, start_date, end_date, final_approval_status)
    VALUES (CAST(GETDATE() AS DATE), @start_date, @end_date, 'pending');

    SET @request_ID = SCOPE_IDENTITY();

    -- Insert into Medical_Leave table
    INSERT INTO Medical_Leave (request_ID, insurance_status, disability_details, type, emp_ID)
    VALUES (@request_ID, @insurance_status, @disability_details, @type, @employee_ID);

    -- Insert document
    INSERT INTO Document (type, description, file_name, creation_date, expiry_date, status, emp_ID, medical_ID, unpaid_ID)
    VALUES ('medical', @document_description, @file_name, CAST(GETDATE() AS DATE), 
            DATEADD(YEAR, 1, CAST(GETDATE() AS DATE)), 'valid', @employee_ID, @request_ID, NULL);

    -- Get Medical Doctor ID
    SELECT TOP 1 @medical_doctor_ID = E.employee_ID
    FROM Employee E
    JOIN Employee_Role ER ON E.employee_ID = ER.emp_ID
    JOIN Role R ON ER.role_name = R.role_name
    WHERE R.role_name = 'Medical_Doctor'
      AND E.employment_status NOT IN ('resigned', 'notice_period');

    -- Get HR Representative ID
    SELECT @hr_rep_ID = E.employee_ID
    FROM Employee E
    JOIN Employee_Role ER ON E.employee_ID = ER.emp_ID
    WHERE ER.role_name = 'HR_Representative_' + @dept_name
      AND E.employment_status NOT IN ('resigned', 'notice_period');

    -- Populate approval hierarchy: Medical Doctor -> HR Representative
    INSERT INTO Employee_Approve_Leave (emp1_ID, leave_ID, status)
    VALUES (@medical_doctor_ID, @request_ID, 'pending');

    INSERT INTO Employee_Approve_Leave (emp1_ID, leave_ID, status)
    VALUES (@hr_rep_ID, @request_ID, 'pending');
END;

GO;

-- ================================================================
-- 2.5.l - Submit Unpaid Leave
-- ================================================================
CREATE PROC Submit_unpaid
    @employee_ID INT,
    @start_date DATE,
    @end_date DATE,
    @document_description VARCHAR(50),
    @file_name VARCHAR(50)
AS
BEGIN
    DECLARE @request_ID INT;
    DECLARE @dept_name VARCHAR(50);
    DECLARE @contract_type VARCHAR(50);
    DECLARE @dean_ID INT;
    DECLARE @vice_dean_ID INT;
    DECLARE @hr_rep_ID INT;

    -- Check if employee is part-time (not eligible for unpaid leave)
    SELECT @contract_type = type_of_contract, @dept_name = dept_name
    FROM Employee
    WHERE employee_ID = @employee_ID;

    IF @contract_type = 'part_time'
    BEGIN
        RETURN; -- Part-time employees are not eligible
    END

    -- Insert into Leave table
    INSERT INTO Leave_ (date_of_request, start_date, end_date, final_approval_status)
    VALUES (CAST(GETDATE() AS DATE), @start_date, @end_date, 'pending');

    SET @request_ID = SCOPE_IDENTITY();

    -- Insert into Unpaid_Leave table
    INSERT INTO Unpaid_Leave (request_ID, emp_ID)
    VALUES (@request_ID, @employee_ID);

    -- Insert memo document
    INSERT INTO Document (type, description, file_name, creation_date, expiry_date, status, emp_ID, medical_ID, unpaid_ID)
    VALUES ('memo', @document_description, @file_name, CAST(GETDATE() AS DATE), 
            DATEADD(YEAR, 1, CAST(GETDATE() AS DATE)), 'valid', @employee_ID, NULL, @request_ID);

    -- Get Dean ID
    SELECT @dean_ID = E.employee_ID
    FROM Employee E
    JOIN Employee_Role ER ON E.employee_ID = ER.emp_ID
    JOIN Role R ON ER.role_name = R.role_name
    WHERE E.dept_name = @dept_name
      AND R.role_name LIKE 'Dean%'
      AND E.employment_status NOT IN ('resigned', 'notice_period');

    -- Get Vice-Dean ID
    SELECT @vice_dean_ID = E.employee_ID
    FROM Employee E
    JOIN Employee_Role ER ON E.employee_ID = ER.emp_ID
    JOIN Role R ON ER.role_name = R.role_name
    WHERE E.dept_name = @dept_name
      AND R.role_name LIKE 'Vice_Dean%'
      AND E.employment_status NOT IN ('resigned', 'notice_period');

    -- Get HR Representative ID
    SELECT @hr_rep_ID = E.employee_ID
    FROM Employee E
    JOIN Employee_Role ER ON E.employee_ID = ER.emp_ID
    WHERE ER.role_name = 'HR_Representative_' + @dept_name
      AND E.employment_status NOT IN ('resigned', 'notice_period');

    -- Populate approval hierarchy
    IF EXISTS (
        SELECT 1 FROM Employee WHERE employee_ID = @dean_ID AND employment_status = 'onleave'
    )
    BEGIN
        INSERT INTO Employee_Approve_Leave (emp1_ID, leave_ID, status)
        VALUES (@vice_dean_ID, @request_ID, 'pending');
    END
    ELSE
    BEGIN
        INSERT INTO Employee_Approve_Leave (emp1_ID, leave_ID, status)
        VALUES (@dean_ID, @request_ID, 'pending');
    END

    -- HR Representative approval (final)
    INSERT INTO Employee_Approve_Leave (emp1_ID, leave_ID, status)
    VALUES (@hr_rep_ID, @request_ID, 'pending');
END;

GO;

-- ================================================================
-- 2.5.m - Upperboard Approve Unpaid Leave
-- ================================================================
CREATE PROC Upperboard_approve_unpaids
    @request_ID INT,
    @Upperboard_ID INT
AS
BEGIN
    DECLARE @document_ID INT;
    DECLARE @document_type VARCHAR(50);
    DECLARE @has_valid_memo BIT = 0;

    -- Check if there's a valid memo document
    SELECT @document_ID = document_ID, @document_type = type
    FROM Document
    WHERE unpaid_ID = @request_ID
      AND type = 'memo'
      AND status = 'valid';

    IF @document_ID IS NOT NULL
    BEGIN
        SET @has_valid_memo = 1;
    END

    -- Approve if valid memo exists
    IF @has_valid_memo = 1
    BEGIN
        UPDATE Employee_Approve_Leave
        SET status = 'approved'
        WHERE leave_ID = @request_ID
          AND emp1_ID = @Upperboard_ID;
    END
    ELSE
    BEGIN
        -- Reject the leave
        UPDATE Employee_Approve_Leave
        SET status = 'rejected'
        WHERE leave_ID = @request_ID
          AND emp1_ID = @Upperboard_ID;

        -- Update final status to rejected
        UPDATE Leave_
        SET final_approval_status = 'rejected'
        WHERE request_ID = @request_ID;
    END
END;

GO;

-- ================================================================
-- 2.5.n - Submit Compensation Leave
-- ================================================================
CREATE PROC Submit_compensation
    @employee_ID INT,
    @compensation_date DATE,
    @reason VARCHAR(50),
    @date_of_original_workday DATE,
    @replacement_emp INT
AS
BEGIN
    DECLARE @request_ID INT;
    DECLARE @dept_name VARCHAR(50);
    DECLARE @hr_rep_ID INT;

    -- Get employee's department
    SELECT @dept_name = dept_name
    FROM Employee
    WHERE employee_ID = @employee_ID;

    -- Insert into Leave table
    INSERT INTO Leave_ (date_of_request, start_date, end_date, final_approval_status)
    VALUES (CAST(GETDATE() AS DATE), @compensation_date, @compensation_date, 'pending');

    SET @request_ID = SCOPE_IDENTITY();

    -- Insert into Compensation_Leave table
    INSERT INTO Compensation_Leave (request_ID, reason, date_of_original_workday, emp_ID, replacement_emp)
    VALUES (@request_ID, @reason, @date_of_original_workday, @employee_ID, @replacement_emp);

    -- Get HR Representative ID
    SELECT @hr_rep_ID = E.employee_ID
    FROM Employee E
    JOIN Employee_Role ER ON E.employee_ID = ER.emp_ID
    WHERE ER.role_name = 'HR_Representative_' + @dept_name
      AND E.employment_status NOT IN ('resigned', 'notice_period');

    -- Only HR Representative approves compensation leaves
    INSERT INTO Employee_Approve_Leave (emp1_ID, leave_ID, status)
    VALUES (@hr_rep_ID, @request_ID, 'pending');
END;

GO;

-- ================================================================
-- 2.5.o - Dean and HR Evaluation
-- ================================================================
CREATE PROC Dean_andHR_Evaluation
    @employee_ID INT,
    @rating INT,
    @comment VARCHAR(50),
    @semester CHAR(3)
AS
BEGIN
    -- Insert performance evaluation
    INSERT INTO Performance (rating, comments, semester, emp_ID)
    VALUES (@rating, @comment, @semester, @employee_ID);
END;

GO;
