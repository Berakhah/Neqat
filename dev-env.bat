@echo off
REM Neqat Development Environment Helper
REM This batch file is a wrapper for environment management scripts

if "%1"=="" goto :help
if "%1"=="help" goto :help

REM Check for setup action
if "%1"=="setup" (
    echo Setting up local development environment...
    powershell -ExecutionPolicy Bypass -File backend\scripts\create_local_env.ps1
    goto :end
)

REM Check for backend action
if "%1"=="backend" (
    echo Starting backend with local environment...
    powershell -ExecutionPolicy Bypass -File backend\scripts\run_with_local_env.ps1
    goto :end
)

REM Check for frontend action
if "%1"=="frontend" (
    echo Starting frontend with local environment...
    cd frontend
    powershell -ExecutionPolicy Bypass -File run_local.ps1
    cd ..
    goto :end
)

REM Check for services action
if "%1"=="services" (
    echo Starting required services (DB and Keycloak) in Docker...
    docker-compose up -d db keycloak
    goto :end
)

REM Check for update action
if "%1"=="update-env" (
    echo Updating environment files...
    cd backend
    python scripts/generate_env.py --force
    cd ..
    goto :end
)

REM Check for fix-db action
if "%1"=="fix-db" (
    echo Fixing database connection settings...
    cd backend
    python scripts/generate_env.py --fix-db
    cd ..
    goto :end
)

REM If we get here, command not recognized
echo Unknown command: %1
goto :help

:help
echo.
echo Neqat Development Environment Helper
echo -----------------------------------
echo.
echo Commands:
echo   setup       Create/update environment files for local development
echo   backend     Start backend with local environment
echo   frontend    Start frontend with local environment
echo   services    Start required Docker services (DB and Keycloak)
echo   update-env  Update all environment files
echo   fix-db      Fix database connection settings
echo   help        Show this help message
echo.
echo Examples:
echo   dev-env.bat setup
echo   dev-env.bat backend
echo   dev-env.bat frontend
echo.

:end 