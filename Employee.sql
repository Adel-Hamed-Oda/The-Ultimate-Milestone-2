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