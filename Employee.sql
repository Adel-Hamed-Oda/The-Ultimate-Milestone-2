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
      AND MONTH(A.date) = MONTH(CAST (GETDATE() AS DATE))
      AND YEAR(A.date) = YEAR(CAST (GETDATE() AS DATE))
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
      AND MONTH(payment_date) = MONTH(DATEADD(MONTH, -1, CAST (GETDATE() AS DATE)))
      AND YEAR(payment_date) = YEAR(DATEADD(MONTH, -1, CAST (GETDATE() AS DATE)))
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
    --I think this works because having to check for check_in and check_out being missing as per milestone 1 would still 
    --need us  to account for off-days. as long as there are checks on entries in the decuctions table we should be fine 
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
        --I get it but I do think 2 checks (in either format) are enough
          )
    )
        SET @isOnLeave = 1;
    ELSE
        SET @isOnLeave = 0;

    RETURN @isOnLeave;
END;

GO;

--Salma's edits start from here
CREATE PROC Submit_annual
    @employee_id INT, 
    @replacement_emp INT, 
    @start_date DATE,
    @end_date DATE
    AS 
    BEGIN
    --idk if this insert style is redundant because this just ensures everything goes 
    --into the correct column if any chnages to columns are made but supposedly there shouldn't be
    INSERT INTO Leave(date_of_request, start_date, end_date, final_approval_status)
    VALUES(CAST(GETDATE() AS DATE), @start_date, @end_date, 'pending');
--This thing gets the last value inserted into an "identity column", in this case our employee_id
    DECLARE @request_id INT = SCOPE_IDENTITY();
    INSERT INTO Annual_Leave(@request_id, @employee_id, @replacement_emp)
    END 
    GO;
        
        
        

    
--Adel's function
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
      AND MONTH(L.date_of_request) = MONTH(CAST (GETDATE() AS DATE))
      AND YEAR(L.date_of_request) = YEAR(CAST (GETDATE() AS DATE))
);

GO;

--More of Salma's tuff (pls correct me if I made a mistakeee)
CREATE PROC Submit_accidental
@employee_ID INT, 
@start_date DATE, 
@end_date DATE
AS
BEGIN 
INSERT INTO Leave VALUES(CAST (GETDATE() AS DATE), @start_date, @end_date, 'pending')
DECLARE @request_id INT = SCOPE_IDENTITY();
INSERT INTO Accidental_Leave VALUES(@request_id, @employee_ID)
END 
GO;
--For medical and unpaid we have file_name and doc_desc which go into document. an insertion doesn't make sense 
--bec we don't have any details abt the doc except these two. 
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
INSERT INTO Leave VALUES(CAST (GETDATE() AS DATE, @start_date, @end_date, 'pending')
DECLARE @request_id INT = SCOPE_IDENTITY();
INSERT INTO Medical_Leave VALUES(@request_id, @insurance_status, @disability_details,@employee_ID)
-- Idk da sa7 wala la2
UPDATE Document 
SET medical_ID = @request_id 
WHERE  description = @document_description AND file_name = @file_name
END 
GO; 

CREATE PROC Submit_unpaid
@employee_ID INT, 
@start_date DATE, 
@end_date DATE, 
@document_description VARCHAR(50), 
@file_name VARCHAR(50)
AS
BEGIN 
INSERT INTO Leave VALUES(CAST (GETDATE() AS DATE), @start_date, @end_date, 'pending')
DECLARE @request_id INT = SCOPE_IDENTITY();
INSERT INTO Unpaid_Leave VALUES (@request_id, @employee_ID)
--also can't tell if it works or not
UPDATE Document 
SET unpaid_ID = @request_id 
WHERE  description = @document_description AND file_name = @file_name
END 
GO;

CREATE PROC Upperboard_approve_annual
    @request_ID INT,
    @Upperboard_ID INT,
    @replacement_ID INT
AS
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

    IF (Is_On_Leave(@replacement_ID, CAST(GETDATE() AS DATE), CAST(GETDATE() AS DATE)) = 0
        AND @replacee_dept = @replacer_dept)
    BEGIN
        INSERT INTO Employee_Approve_Leave
        VALUES(@Upperboard_ID, @request_ID, 'approved');
        -- TODO: final approval status conditions still need to be done
    END
    ELSE
    BEGIN
        INSERT INTO Employee_Approve_Leave
        VALUES(@Upperboard_ID, @request_ID, 'rejected');
    END
END
GO;
--note: idk wth a "valid reason" is
CREATE PROC Upperboard_approve_unpaids
@request_ID INT,
@Upperboard_ID INT
AS
BEGIN
IF EXISTS(SELECT 1 
    FROM Document D 
    WHERE unpaid_ID = @request_ID) 
BEGIN 
 INSERT INTO Employee_Approve_Leave
        VALUES(@Upperboard_ID, @request_ID, 'approved');
END 
ELSE 
BEGIN 
INSERT INTO Employee_Approve_Leave
        VALUES(@Upperboard_ID, @request_ID, 'rejected');
END 
END 
GO;
--TODO: verify that the ID actually belongs to an upper board member through a view or IF-condition
CREATE PROC Dean_andHR_Evaluation
@employee_ID INT,
@rating INT,
@comment VARCHAR(50), 
@semester CHAR(3)
AS 
BEGIN 
INSERT INTO Performance VALUES(@rating, @comment, @semester, @employee_ID)
END 
GO; 

