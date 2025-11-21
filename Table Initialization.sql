USE placeholder;
DROP DATABASE IF EXISTS test;
CREATE DATABASE test;

USE test;

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

        PRIMARY KEY (role_name),
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
        FOREIGN KEY (role_name) REFERENCES Role(role_name)

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
        type VARCHAR(50),
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
        date DATE,
        check_in_time TIME,
        check_out_time TIME,
        total_duration AS DATEDIFF(minute, check_in_time, check_out_time),--TODO: check
        status VARCHAR(50) DEFAULT 'absent',
        emp_ID INT,

        PRIMARY KEY (attendance_ID),
        FOREIGN KEY (emp_ID) REFERENCES Employee(employee_ID),

        CHECK (LOWER(status) IN ('absent', 'attended'))
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
        emp1_ID INT,
        emp2_ID INT,
        from_date DATE,
        to_date DATE,

        PRIMARY KEY (emp1_ID, emp2_ID),
        FOREIGN KEY (emp1_ID) REFERENCES Employee(employee_ID),
        FOREIGN KEY (emp2_ID) REFERENCES Employee(employee_ID)
    );

    -- 19. Employee_Approve_Leave
    CREATE TABLE Employee_Approve_Leave (
        emp1_ID INT,
        leave_ID INT,
        status VARCHAR(50) DEFAULT 'pending',

        PRIMARY KEY (emp1_ID, leave_ID),
        FOREIGN KEY (emp1_ID) REFERENCES Employee(employee_ID),
        FOREIGN KEY (leave_ID) REFERENCES Leave(request_ID),

        CHECK (LOWER(status) IN ('approved', 'rejected', 'pending'))
    );

go

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
          AND SUBSTRING(i.role_name, 18, LEN(i.role_name) - 17)
              NOT IN (SELECT name FROM Department)
    )
    BEGIN
        -- error message for debugging we can delete it later 
        PRINT 'Invalid HR Representative role_name: department does not exist.';
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
