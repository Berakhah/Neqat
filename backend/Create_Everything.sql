-- Database Creation
CREATE DATABASE NeqatDB
GO
USE NeqatDB
GO

-- User Information Retrieval Stored Procedure
CREATE PROCEDURE sp_retrieveNeqatUserInfo
    @UserId NVARCHAR(100)
AS
BEGIN
    SELECT 
        user_name,
        first_name,
        last_name,
        email,
        date_joined,
        profile_image
    FROM 
        dbo.neqat_neqatuser
    WHERE 
        id = @UserId
END
GO

-- User Authentication Stored Procedure
CREATE PROCEDURE sp_authenticateNeqatUser
    @Email NVARCHAR(254),
    @Password NVARCHAR(128)
AS
BEGIN
    SELECT 
        id,
        user_name,
        email,
        first_name,
        last_name,
        profile_image
    FROM 
        dbo.neqat_neqatuser
    WHERE 
        email = @Email
END
GO

-- Update User Profile Stored Procedure
CREATE PROCEDURE sp_updateNeqatUserProfile
    @UserId NVARCHAR(100),
    @FirstName NVARCHAR(150),
    @LastName NVARCHAR(150),
    @ProfileImage NVARCHAR(max)
AS
BEGIN
    UPDATE dbo.neqat_neqatuser
    SET 
        first_name = @FirstName,
        last_name = @LastName,
        profile_image = CASE 
                           WHEN @ProfileImage IS NOT NULL AND LEN(@ProfileImage) > 0 
                           THEN @ProfileImage 
                           ELSE profile_image 
                        END
    WHERE 
        id = @UserId;

    -- Return updated user info
    SELECT 
        user_name,
        first_name,
        last_name,
        email,
        profile_image
    FROM 
        dbo.neqat_neqatuser
    WHERE 
        id = @UserId;
END
GO

-- Note: The actual tables are created by Django migrations.
-- The stored procedures above are meant to be used for optimized database operations.
-- You can run this script after running the Django migrations.