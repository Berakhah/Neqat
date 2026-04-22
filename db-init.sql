-- Check if NeqatDB database exists, if not create it
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'NeqatDB')
BEGIN
  CREATE DATABASE NeqatDB;
END
GO

USE NeqatDB;
GO

-- Grant permissions to the SA user
IF DATABASE_PRINCIPAL_ID('SA') IS NULL
BEGIN
    CREATE USER [SA] FOR LOGIN [SA];
END
GO

-- Grant database role membership
ALTER ROLE [db_owner] ADD MEMBER [SA];
GO

-- Check if Migrations table exists, if not create it
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'django_migrations')
BEGIN
    PRINT 'Django migrations table does not exist yet. Will be created by Django migrate command.';
END
GO

PRINT 'Database initialization completed successfully';
GO 