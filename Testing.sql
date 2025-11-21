-- Description: This script resets the test database by dropping all existing tables, procedures, functions, and views, and then recreates all tables.
-- It is useful for ensuring a clean state before running actual tests. Will not be added to final solution.

USE test;

GO

EXEC dropAllTables;
EXEC dropAllProceduresFunctionsViews;

EXEC createAllTables;