CREATE FUNCTION [HRLoginValidation] (@employee_ID INT, @password VARCHAR(50))
RETURNS BIT
AS
BEGIN
    DECLARE @b BIT

    -- 
    IF (EXISTS (
        SELECT E.*
        FROM Employee E
        WHERE E.dept_name = 'HR'
          AND E.pass = @password
          AND E.employee_id = @employee_ID
    ))
        SET @b = 1
    ELSE
        SET @b = 0

    RETURN b
END;

GO

CREATE PROCEDURE HR_approval_an_acc
    @request_ID INT,
    @HR_ID INT
AS

    DECLARE @type VARCHAR(50),
            @myid INT,
            @parttimecheck BIT,
            @replacementemp INT,
            @availcheck BIT,
            @approvalcheck BIT,
            @balancecheck BIT,
            @balance INT,
            @maxonedaycheck INT,
            @subwithin48hourscheck BIT,
            @datesubmitted DATE,
            @startdate DATE

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

    -- Logic for Annual Leave
    IF (@type = 'annual')
    BEGIN
        SELECT @myid = A.emp_ID
        FROM Employee E, Annual_Leave A
        WHERE E.employee_id = A.emp_ID
            AND @request_ID = A.request_ID

        SET @parttimecheck = dbo.isNotPartTime(@myid)

        -- TODO: I think this is wrong
        -- because the Employee_replace_Employee table contains employees that
        -- are currently replacing each other (hence the dates) there should be some
        -- other ways to do it

        SELECT @replacementemp = E.Emp2_ID
        FROM Employee_Replace_Employee E, Leave L
        WHERE E.Emp1_ID = @myid
            AND L.request_ID = @request_ID

        IF (@replacementemp IS NOT NULL) -- Is there anyone to even replace me
            SET @availcheck = dbo.checkavail(@replacementemp, @request_ID) -- Yes? check if he is avail
        ELSE
            SET @availcheck = 0

        -- Checking for approvals
        IF (NOT EXISTS (
            SELECT *
            FROM Employee_Approve_Leave E
            WHERE E.Leave_ID = @request_ID
                -- TODO: in the milestone it says something about treating pending
                -- as approved, but this is probably for only one function, not sure 
                -- if it is for all of them
                AND (E.status = 'rejected' OR E.status = 'pending')
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
            SET @balancecheck = 0
        ELSE
            SET @balancecheck = 1

        -- Final Approval / Rejection for Annual
        IF (@balancecheck = 1 AND @approvalcheck = 1 AND @parttimecheck = 1 AND @availcheck = 1)
        BEGIN
            UPDATE Employee
            SET annual_balance = annual_balance - @totaldays
            WHERE employee_id = @myid

            UPDATE Leave
            SET final_approval_status = 'approved'
            WHERE @request_ID = request_ID

            INSERT INTO Employee_Approve_Leave VALUES (@HR_ID, @request_ID, 'approved')
        END
        ELSE
        BEGIN
            UPDATE Leave
            SET final_approval_status = 'rejected'
            WHERE @request_ID = request_ID

            INSERT INTO Employee_Approve_Leave VALUES (@HR_ID, @request_ID, 'rejected')
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

            INSERT INTO Employee_Approve_Leave VALUES (@HR_ID, @request_ID, 'approved')
        END
        ELSE
        BEGIN
            UPDATE Leave
            SET final_approval_status = 'rejected'
            WHERE @request_ID = request_ID

            INSERT INTO Employee_Approve_Leave VALUES (@HR_ID, @request_ID, 'rejected')
        END
    END

GO

CREATE PROCEDURE HR_approval_unpaid
    @request_ID INT,
    @HR_ID INT
AS
BEGIN
    DECLARE @myid INT,
            @myrank INT,
            @parttimecheck BIT,
            @year INT,
            @yearcheck BIT,
            @maxdurationcheck BIT,
            @approvalcheck BIT

    SET @myid = dbo.getIDrequesterUNPAID(@request_ID)

    -- If im part time i cant get unpaid leave
    SET @parttimecheck = dbo.isPartTime(@myid)

    -- Checks for max one approved unpaid leave per year
    SET @year = dbo.GetRequestYear(@request_ID)

    IF @year > ISNULL((
        SELECT MAX(YEAR(L.date_of_request)) AS latest_year
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

    -- TODO: same thing here with the 'accepted' vs 'pending' issue
    -- Checking if any approval was rejected
    IF (NOT EXISTS (
        SELECT *
        FROM Employee_Approve_Leave E
        WHERE E.Leave_ID = @request_ID
          AND (E.status = 'rejected' OR E.status = 'pending')
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

        INSERT INTO Employee_Approve_Leave VALUES (@HR_ID, @request_ID, 'approved')
    END
    ELSE
    BEGIN
        UPDATE Leave
        SET final_approval_status = 'rejected'
        WHERE request_ID = @request_ID

        INSERT INTO Employee_Approve_Leave VALUES (@HR_ID, @request_ID, 'rejected')
    END
END;

GO

-- TODO: not 100% sure about this one, but good enough
CREATE PROC HR_approval_compensation
    @request_ID INT,
    @HR_ID INT
AS

    DECLARE @emp_ID INT;
    DECLARE @time_spent INT = 0;
    DECLARE @same_month BIT;
    DECLARE @same_department BIT;

    SELECT @emp_ID = emp_ID
    FROM 
        Leave
        JOIN Compensation_Leave ON Leave.request_ID = Compensation_Leave.request_ID
    WHERE Leave.request_ID = @request_ID;

    SELECT @time_spent = total_duration
    FROM Attendance
    WHERE date = (
        SELECT date_of_original_work_day
        FROM Compensation_Leave
        WHERE request_ID = @request_ID
    );

    IF 
        EXISTS 
        (SELECT *
        FROM Leave
        WHERE request_ID = @request_ID AND
            YEAR(date_of_request) = YEAR(start_date) AND
            MONTH(date_of_request) = MONTH(start_date))
    BEGIN
        SET @same_month = 1;
    END ELSE BEGIN
        SET @same_month = 0;
    END;

    IF 
        EXISTS 
        (SELECT *
        FROM Employee E1, Employee E2
        WHERE E1.employee_ID = @emp_ID AND
            E2.employee_ID = @HR_ID AND
            E1.dept_name = E2.dept_name)
    BEGIN
        SET @same_department = 1;
    END ELSE BEGIN
        SET @same_department = 0;
    END;

    -- time spent is in minutes
    IF @time_spent < 480 OR @same_month = 0 OR @same_department = 0 BEGIN
        INSERT INTO Employee_Approve_Leave (emp1_ID, leave_ID, status)
        VALUES (@HR_ID, @request_ID, 'rejected');
    END ELSE BEGIN
        INSERT INTO Employee_Approve_Leave (emp1_ID, leave_ID, status)
        VALUES (@HR_ID, @request_ID, 'approved');
    END;

GO

CREATE PROC Deduction_hours
    @employee_ID INT
AS

    DECLARE @attendance_ID INT = -1;
    SELECT TOP (1) 
        @attendance_ID = attendance_ID
    FROM Attendance
    WHERE 
        @emp_ID = employee_ID
        AND YEAR([date]) = YEAR(GETDATE())
        AND MONTH([date]) = MONTH(GETDATE())
        AND total_duration < 480
    ORDER BY [date];

    IF @attendance_ID <> -1 BEGIN

        -- TODO: IDK what the amount is, neither the status
        INSERT INTO Deduction (emp_ID, [date], type, attendance_ID)
        VALUES (@employee_ID, CAST(GETDATE() AS DATE), 'missing hours', @attendance_ID);

    END;

GO

-- TODO: Deduction_days
-- TODO: Deduction_unpaid

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
        AND status = 'pending';        -- not yet reflected in payroll

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
    SET status = 'finalized'
    WHERE emp_ID = @employee_ID
      AND date BETWEEN @from_date AND @to_date
      AND status = 'pending'
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

-- there is a function in Employee called Is_On_Leave, sorry ya Nour :)
CREATE FUNCTION [Checkavail] (@employee_ID INT, @request_ID INT)
RETURNS BIT
AS
BEGIN
    DECLARE @b BIT,
            @s DATE,
            @e DATE;

    SELECT @s = L.start_date, @e = L.end_date
    FROM Leave L, Compensation_Leave C
    WHERE L.request_ID = C.request_ID
      AND L.request_ID = @request_ID;

    -- TODO: same thing here with 'approved' vs 'pending'
    -- Is there any leave for this employee who will replace me within the period?
    IF (EXISTS (
        SELECT *
        FROM Employee E, Leave L, Compensation_Leave C, Medical_Leave M, Unpaid_Leave U, Annual_Leave AN, Accidental_Leave AC
        WHERE (
                -- TODO: this is wrong, this only checks if the the employee being checked for is 
                -- unavailable for the entire period, not if there is any overlap

                -- for example:
                -- requested leave is from day 10 to day 20
                -- existing leave is from day 15 to day 25
                
                -- the function would consider the employee available even though they aren't for 5 days
                (C.emp_ID = @employee_ID AND L.request_ID = C.request_ID AND L.start_date <= @e AND L.end_date >= @s) OR
                (M.emp_ID = @employee_ID AND L.request_ID = M.request_ID AND L.start_date <= @e AND L.end_date >= @s) OR
                (U.emp_ID = @employee_ID AND L.request_ID = U.request_ID AND L.start_date <= @e AND L.end_date >= @s) OR
                (AN.emp_ID = @employee_ID AND L.request_ID = AN.request_ID AND L.start_date <= @e AND L.end_date >= @s) OR
                (AC.emp_ID = @employee_ID AND L.request_ID = AC.request_ID AND L.start_date <= @e AND L.end_date >= @s)
              )
          AND L.final_approval_status = 'approved'
    ))
        SET @b = 0
    ELSE
        SET @b = 1

    RETURN @b
END

GO

CREATE PROCEDURE HR_approval_comp
    @request_ID INT,
    @HR_ID INT
AS
BEGIN
    DECLARE @spentcheck BIT,
            @myid INT,
            @reason VARCHAR(50),
            @reasoncheck BIT,
            @replacementemp INT,
            @availcheck BIT,
            -- added these to check for availability
            @startdate DATE,
            @enddate DATE;

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

    -- Check valid reason...(not null or empty?)
    SELECT @reason = C.reason
    FROM Compensation_Leave C
    WHERE C.request_ID = @request_ID

    IF (@reason IS NULL OR @reason = '')
        SET @reasoncheck = 0
    ELSE
        SET @reasoncheck = 1

    -- TODO: like I said before this is wrong because this are employee currently replacing
    -- each other, not the actual request

    -- Another employee must replace them HERE IM NOT SURE IF MULTIPLE PEOPLE CAN REPLACE ME SO I NEED
    -- TO CHECK IF ANYYY PERSONNN IS AVAILABLE (this gets last row only)
    SELECT @replacementemp = E.Emp2_ID, @startdate = L.start_date, @enddate = L.end_date
    FROM Employee_Replace_Employee E, Leave L
    WHERE E.Emp1_ID = @myid
      AND L.request_ID = @request_ID

    IF (@replacementemp IS NOT NULL) -- Is there anyone to even replace me
        SET @availcheck = dbo.Is_On_Leave(@replacementemp, @startdate, @enddate) -- Yes? check if he is avail
    ELSE
        SET @availcheck = 0

    -- Final check
    IF (@availcheck = 1 AND @spentcheck = 1 AND @reasoncheck = 1)
    BEGIN
        UPDATE Leave
        SET final_approval_status = 'approved'
        WHERE request_ID = @request_ID

        INSERT INTO Employee_Approve_Leave VALUES (@HR_ID, @request_ID, 'approved')
    END
    ELSE
    BEGIN
        UPDATE Leave
        SET final_approval_status = 'rejected'
        WHERE request_ID = @request_ID

        INSERT INTO Employee_Approve_Leave VALUES (@HR_ID, @request_ID, 'rejected')
    END
END;

GO