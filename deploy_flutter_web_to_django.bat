@echo off
setlocal enabledelayedexpansion

REM Ensure script is run from project root
if not exist "frontend\build\web" (
    echo Please run this script from the project root, after building Flutter at least once.
    exit /b 1
)

REM Paths
set FLUTTER_BUILD_DIR=frontend\build\web
set DJANGO_STATIC_DIR=backend\static
set DJANGO_TEMPLATES_DIR=backend\templates

REM This script builds the Flutter web app using lib\app\main.dart as the entry point

echo Building Flutter web app...
cd frontend
flutter build web -t lib\app\main.dart
cd ..
if errorlevel 1 (
    echo Flutter build failed!
    exit /b 1
)

echo Copying Flutter web assets to Django static directory...
if not exist "%DJANGO_STATIC_DIR%" mkdir "%DJANGO_STATIC_DIR%"
xcopy /E /Y /I /C /Q "%FLUTTER_BUILD_DIR%\*" "%DJANGO_STATIC_DIR%\" >nul

echo Copying index.html to Django templates directory...
if not exist "%DJANGO_TEMPLATES_DIR%" mkdir "%DJANGO_TEMPLATES_DIR%"
copy /Y "%FLUTTER_BUILD_DIR%\index.html" "%DJANGO_TEMPLATES_DIR%\index.html" >nul

echo Fixing asset paths in index.html to use /static/...
REM Use PowerShell to replace asset paths in index.html
powershell -Command ^
    "$f='%DJANGO_TEMPLATES_DIR%\index.html';" ^
    "(Get-Content $f) -replace '\"(main|flutter|assets|favicon|manifest|icons|NOTICES|version)', '\"/static/$1' | Set-Content $f"

echo Done! Restart your Django server to apply changes.

endlocal
