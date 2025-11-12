CREATE PROC Update_Status_Doc AS
    UPDATE Document
    SET status = 'expired'
    WHERE expiry_date < CAST(GETDATE() AS DATE);

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

    IF (Is_On_Leave(@empID, CAST(GETDATE() AS DATE), CAST(GETDATE() AS DATE)) = 1)
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

GO;

CREATE PROC Create_Holiday AS
    IF OBJECT_ID('Holiday', 'U') IS NULL
    BEGIN
    CREATE TABLE Holiday (
        holiday_id INT IDENTITY(1,1) PRIMARY KEY,
        holiday_name VARCHAR(50),
        from_date DATE,
        to_date DATE
    );
    END 
GO;

CREATE PROC Add_Holiday
    @holiday_name VARCHAR(50),
    @from_date DATE,
    @to_date DATE
AS
    INSERT INTO Holiday (holiday_name, from_date, to_date)
    VALUES (@holiday_name, @from_date, @to_date);

GO;

CREATE PROC Initiate_Attendance AS -- kan fee typo hena
    
    INSERT INTO Attendance (emp_ID, [date], status)
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

--  i fixed it but i kept the old comment just in case
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
        check_out_time = @check_out
    WHERE [date] = CAST(GETDATE() AS DATE)
      AND emp_ID = @emp_ID;

GO;

CREATE PROC Remove_Holiday AS       -- fixed DELETE statement was in mysql syntax
    DELETE FROM Attendance
    WHERE [date] IN (
        SELECT A.[date]
        FROM Attendance A
        JOIN Holiday H ON A.[date] BETWEEN H.from_date AND H.to_date
    );

GO;

            -- revise this again just incase TODO: not sure how to compare the dates correctly
CREATE PROC Remove_DayOff
    @emp_ID INT
AS
    DELETE FROM Attendance
    WHERE emp_ID = @emp_ID
      AND status = 'absent'
      AND MONTH([date]) = MONTH(GETDATE())
      AND YEAR([date]) = YEAR(GETDATE())
      AND DATENAME(WEEKDAY, [date]) = (           -- Compare weekday names 3ashan for example official_day_off is a VARCHAR(50) but we can also compare be turning days into numbers and comparing them
          SELECT official_day_off 
          FROM Employee 
          WHERE employee_ID = @emp_ID
      );

GO;

CREATE PROC Remove_Approved_Leaves
    @emp_ID INT
AS
    DELETE FROM Attendance
    WHERE emp_ID = @emp_ID
      AND [date] IN (
          SELECT A.[date]
          FROM Attendance A
          JOIN Leave_ L ON A.[date] BETWEEN L.start_date AND L.end_date
          WHERE L.emp_ID = @emp_ID
            AND L.final_approval_status = 'approved'
      );
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
