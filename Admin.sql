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