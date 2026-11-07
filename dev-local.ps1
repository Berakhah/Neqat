# Neqat Local Development Script
# This script sets up a hybrid environment where:
# - Database and Keycloak use existing Docker containers
# - Backend runs locally
# - Frontend runs in your IDE

# Function to check if Docker is running
function Check-Docker {
    try {
        docker info > $null 2>&1
    }
    catch {
        Write-Host "Error: Docker is not running. Please start Docker and try again." -ForegroundColor Red
        exit 1
    }
}

# Function to display help
function Show-Help {
    Write-Host "Neqat Local Development Script" -ForegroundColor Green
    Write-Host "Usage: .\dev-local.ps1 [COMMAND]`n"
    Write-Host "Commands:"
    Write-Host "  setup       Install required Python dependencies and setup env"
    Write-Host "  backend     Start the backend server locally"
    Write-Host "  check-db    Check database connection"
    Write-Host "  help        Show this help message"
}

# Function to install backend dependencies
function Install-BackendDependencies {
    Write-Host "Installing Python dependencies..." -ForegroundColor Green
    Set-Location -Path ".\backend"
    
    # Check if virtual environment exists
    if (-not (Test-Path -Path ".\.venv")) {
        Write-Host "Creating virtual environment..." -ForegroundColor Yellow
        python -m venv .venv
    }
    
    # Activate virtual environment
    Write-Host "Activating virtual environment..." -ForegroundColor Yellow
    .\.venv\Scripts\Activate.ps1
    
    # Install dependencies
    Write-Host "Installing packages..." -ForegroundColor Yellow
    pip install -r requirements.txt
    
    # Install keycloak package (detected as missing from error)
    Write-Host "Installing keycloak package..." -ForegroundColor Yellow
    pip install python-keycloak
    
    Set-Location -Path ".."
    Write-Host "Dependencies installed successfully!" -ForegroundColor Green
}

# Function to setup local backend
function Setup-LocalBackend {
    Write-Host "Setting up local backend environment..." -ForegroundColor Green
    
    # Create backend/.env.local if it doesn't exist
    if (-not (Test-Path -Path ".\backend\.env.local")) {
        Write-Host "Creating backend/.env.local file..." -ForegroundColor Yellow
        @"
# Django Settings
DEBUG=True
DJANGO_SECRET_KEY=CHANGE_ME_DJANGO_SECRET_KEY
ALLOWED_HOSTS=localhost,127.0.0.1,backend
CSRF_TRUSTED_ORIGINS=http://localhost:8000,http://backend:8000
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://frontend:3000,http://localhost:8000,http://backend:8000

# Database Settings
DATABASE_ENGINE=mssql
DATABASE_NAME=NeqatDB
DATABASE_HOST=localhost
DATABASE_PORT=1433
DATABASE_USER=sa
DATABASE_PASSWORD=<set-locally>
DATABASE_OPTIONS=driver=ODBC Driver 18 for SQL Server;TrustServerCertificate=yes;Encrypt=no;

# Email Settings
EMAIL_BACKEND=django.core.mail.backends.console.EmailBackend
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-password
DEFAULT_FROM_EMAIL=noreply@neqat.com

# Security Settings
SECURE_SSL_REDIRECT=False
SESSION_COOKIE_SECURE=False
CSRF_COOKIE_SECURE=False
SECURE_BROWSER_XSS_FILTER=True
SECURE_CONTENT_TYPE_NOSNIFF=True
X_FRAME_OPTIONS=DENY

# Keycloak Settings
KEYCLOAK_SERVER_URL=http://localhost:8080
KEYCLOAK_REALM=neqat-realm
KEYCLOAK_CLIENT_ID=django-backend
KEYCLOAK_CLIENT_SECRET=<set-locally>
KEYCLOAK_ADMIN_USERNAME=admin
KEYCLOAK_ADMIN_PASSWORD=<set-locally>
"@ | Out-File -FilePath ".\backend\.env.local" -Encoding utf8
        Write-Host "Created backend/.env.local file." -ForegroundColor Green
    }
}

# Check if Docker is running
Check-Docker

# Check if required containers are running
function Check-RequiredContainers {
    Write-Host "Checking if required Docker containers are running..." -ForegroundColor Green
    
    $requiredContainers = @("neqat-db-1", "neqat-keycloak-1")
    $allRunning = $true
    
    foreach ($container in $requiredContainers) {
        $containerStatus = docker ps --filter "name=$container" --format "{{.Status}}"
        
        if ($containerStatus -match "Up") {
            Write-Host "✅ Container $container is running." -ForegroundColor Green
        } else {
            $allRunning = $false
            Write-Host "❌ Container $container is not running!" -ForegroundColor Red
        }
    }
    
    if (-not $allRunning) {
        Write-Host "`nSome required containers are not running. Please start them using:" -ForegroundColor Yellow
        Write-Host "docker-compose up -d" -ForegroundColor Cyan
        return $false
    }
    
    return $true
}

# Process commands
$command = $args[0]

switch ($command) {
    "setup" {
        # Check if containers are running
        if (-not (Check-RequiredContainers)) {
            break
        }
        
        # Setup local environment
        Setup-LocalBackend
        Install-BackendDependencies
        
        Write-Host "`nSetup complete! You can now run the backend locally with:" -ForegroundColor Green
        Write-Host ".\dev-local.ps1 backend" -ForegroundColor Yellow
    }
    "backend" {
        # Check if containers are running
        if (-not (Check-RequiredContainers)) {
            break
        }
        
        # Start backend server locally
        Write-Host "Starting backend server locally..." -ForegroundColor Green
        Set-Location -Path ".\backend"
        .\.venv\Scripts\Activate.ps1
        
        # Check if .env.local exists, otherwise create it
        if (-not (Test-Path -Path ".\.env.local")) {
            Write-Host "Environment file not found. Run setup first:" -ForegroundColor Yellow
            Write-Host ".\dev-local.ps1 setup" -ForegroundColor Cyan
            Set-Location -Path ".."
            break
        }
        
        # Use .env.local file for running the server
        Copy-Item -Path ".\.env.local" -Destination ".\.env" -Force
        python manage.py runserver 0.0.0.0:8000
    }
    "check-db" {
        Write-Host "Checking database connection..." -ForegroundColor Green
        docker exec neqat-db-1 /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "ChangeMe_Dev123!" -Q "SELECT @@version"
        if ($?) {
            Write-Host "Database connection successful!" -ForegroundColor Green
            docker exec neqat-db-1 /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "ChangeMe_Dev123!" -Q "SELECT name FROM sys.databases"
        } else {
            Write-Host "Could not connect to database." -ForegroundColor Red
        }
    }
    default {
        Show-Help
    }
} 

Write-Host "Starting Neqat development environment..." -ForegroundColor Green

# Stop any existing containers to avoid port conflicts
docker-compose -f docker-compose.local.yml down

# Start the services
docker-compose -f docker-compose.local.yml up -d

Write-Host "Services are starting up..." -ForegroundColor Green
Write-Host "- Backend: http://192.168.134.132:8000" -ForegroundColor Cyan
Write-Host "- Keycloak: http://192.168.134.132:8080" -ForegroundColor Cyan
Write-Host "- Database: localhost:1433" -ForegroundColor Cyan
Write-Host ""
Write-Host "Backend logs can be viewed with:" -ForegroundColor Yellow
Write-Host "docker logs -f neqat_backend" -ForegroundColor DarkYellow
Write-Host ""
Write-Host "To run the Flutter app on a physical device:" -ForegroundColor Yellow
Write-Host "cd frontend && flutter run lib/app/main.dart" -ForegroundColor DarkYellow
Write-Host ""
Write-Host "Development environment is ready!" -ForegroundColor Green 