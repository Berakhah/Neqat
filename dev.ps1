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
    Write-Host "Neqat Development Script" -ForegroundColor Green
    Write-Host "Usage: .\dev.ps1 [COMMAND]`n"
    Write-Host "Commands:"
    Write-Host "  up         Start all containers in detached mode"
    Write-Host "  down       Stop all containers"
    Write-Host "  rebuild    Rebuild and restart all containers"
    Write-Host "  logs       Show logs from all containers"
    Write-Host "  backend    Access the backend container shell"
    Write-Host "  frontend   Access the frontend container shell"
    Write-Host "  db         Access the database container shell"
    Write-Host "  keycloak   Access the keycloak container shell"
    Write-Host "  migrate    Run database migrations"
    Write-Host "  reset-db   Reset the database and run migrations"
    Write-Host "  fix-db     Fix database connection issues"
    Write-Host "  check-db   Check database connection"
    Write-Host "  run-local  Run backend locally (accessible from other devices)"
    Write-Host "  help       Show this help message"
}

# Function to run command in two parts for PowerShell compatibility
function Run-Commands {
    param (
        [string]$FirstCommand,
        [string]$SecondCommand
    )
    
    # Execute the first command
    Invoke-Expression $FirstCommand
    
    # If the first command is successful, execute the second command
    if ($?) {
        Invoke-Expression $SecondCommand
    }
}

# Check if Docker is running
Check-Docker

# Process commands
$command = $args[0]

switch ($command) {
    "up" {
        Write-Host "Starting Docker containers..." -ForegroundColor Green
        docker-compose up -d
        Write-Host "Services are running at:" -ForegroundColor Green
        Write-Host "  Frontend:  http://localhost:3000" -ForegroundColor Yellow
        Write-Host "  Backend:   http://localhost:8000" -ForegroundColor Yellow
        Write-Host "  Keycloak:  http://localhost:8080 (admin/AdminPassword123!)" -ForegroundColor Yellow
        Write-Host "  Database:  localhost:1433 (SA/ChangeMe_Dev123!)" -ForegroundColor Yellow
        Write-Host "`nFor access from other devices (e.g., physical phone):" -ForegroundColor Green
        Write-Host "  Backend:   http://192.168.64.132:8000" -ForegroundColor Cyan
        Write-Host "  Keycloak:  http://192.168.64.132:8080" -ForegroundColor Cyan
    }
    "down" {
        Write-Host "Stopping Docker containers..." -ForegroundColor Green
        docker-compose down
    }
    "rebuild" {
        Write-Host "Rebuilding and restarting Docker containers..." -ForegroundColor Green
        
        # Ask what to rebuild
        Write-Host "What would you like to rebuild?" -ForegroundColor Cyan
        Write-Host "1. All services (full rebuild)"
        Write-Host "2. Frontend only"
        Write-Host "3. Backend only"
        Write-Host "4. Custom (specify services)"
        Write-Host "q. Cancel rebuild"
        $rebuildChoice = Read-Host "Enter your choice (default: 1)"
        
        if ($rebuildChoice -eq "q") {
            Write-Host "Rebuild canceled." -ForegroundColor Yellow
            exit 0
        }
        
        # Default to full rebuild
        $rebuildAll = $true
        $services = @()
        
        switch ($rebuildChoice) {
            "2" {
                $rebuildAll = $false
                $services = @("frontend")
                Write-Host "Rebuilding frontend only..." -ForegroundColor Green
            }
            "3" {
                $rebuildAll = $false
                $services = @("backend")
                Write-Host "Rebuilding backend only..." -ForegroundColor Green
            }
            "4" {
                $rebuildAll = $false
                $availableServices = docker-compose config --services
                Write-Host "Available services: $availableServices" -ForegroundColor Yellow
                $serviceInput = Read-Host "Enter services to rebuild (space-separated)"
                $services = $serviceInput -split ' '
                Write-Host "Rebuilding custom services: $services" -ForegroundColor Green
            }
            default {
                Write-Host "Performing full rebuild of all services..." -ForegroundColor Green
            }
        }
        
        # Stop containers
        if ($rebuildAll) {
            Write-Host "Stopping all containers..." -ForegroundColor Green
            docker-compose down
            
            # Remove dangling images and containers
            Write-Host "Cleaning up Docker environment..." -ForegroundColor Green
            docker system prune -f
            
            # Remove previously built images for this project
            Write-Host "Removing previously built project images..." -ForegroundColor Green
            $projectImages = docker images --filter "reference=neqat_*" -q
            if ($projectImages) {
                docker rmi $projectImages -f
            }
            
            # Build with no cache
            Write-Host "Building fresh images for all services..." -ForegroundColor Green
            docker-compose build --no-cache
        }
        else {
            # Build only specified services
            Write-Host "Building only specified services: $services" -ForegroundColor Green
            foreach ($service in $services) {
                Write-Host "Rebuilding $service..." -ForegroundColor Cyan
                docker-compose build --no-cache $service
                if (-not $?) {
                    Write-Host "Failed to build $service. Aborting rebuild." -ForegroundColor Red
                    exit 1
                }
            }
        }
        
        # Check for build success
        if ($?) {
            Write-Host "Build completed successfully. Starting containers..." -ForegroundColor Green
            if ($rebuildAll) {
                docker-compose up -d
            }
            else {
                # Restart only specified services
                foreach ($service in $services) {
                    Write-Host "Restarting $service..." -ForegroundColor Cyan
                    docker-compose up -d --no-deps $service
                }
            }
            
            # Wait for services to start
            Write-Host "Waiting for services to initialize..." -ForegroundColor Green
            $waitTime = 5
            Write-Host "Waiting $waitTime seconds for containers to start..." -ForegroundColor Yellow
            Start-Sleep -Seconds $waitTime
            
            # Check if containers are running
            if ($rebuildAll) {
                $containers = docker-compose ps --services | ForEach-Object { docker-compose ps -q $_ }
            }
            else {
                $containers = $services | ForEach-Object { docker-compose ps -q $_ }
            }
            
            $allRunning = $true
            foreach ($container in $containers) {
                if ($container) {
                    $status = docker inspect --format='{{.State.Status}}' $container
                    $name = docker inspect --format='{{.Name}}' $container
                    if ($status -ne "running") {
                        $allRunning = $false
                        Write-Host "Container $name is not running. Status: $status" -ForegroundColor Red
                    }
                    else {
                        Write-Host "Container $name is running!" -ForegroundColor Green
                    }
                }
            }
            
            if ($allRunning) {
                Write-Host "All requested services are up and running!" -ForegroundColor Green
                Write-Host "Services are available at:" -ForegroundColor Green
                # Write-Host "  Frontend:  http://localhost:3000" -ForegroundColor Yellow
                Write-Host "  Backend:   https://localhost:8000" -ForegroundColor Yellow
                Write-Host "  Keycloak:  https://localhost:8443 (admin/ChangeMe_Dev123!)" -ForegroundColor Yellow
                Write-Host "  Database:  localhost:1433 (SA/ChangeMe_Dev123!)" -ForegroundColor Yellow
                Write-Host "`nFor access from other devices (e.g., physical phone):" -ForegroundColor Green
                Write-Host "  Backend:   https://192.168.64.132:8000" -ForegroundColor Cyan
                Write-Host "  Keycloak:  https://192.168.64.132:8443" -ForegroundColor Cyan
            } else {
                Write-Host "Some containers failed to start. Check logs with: .\dev.ps1 logs" -ForegroundColor Red
            }
        } else {
            Write-Host "Build failed. Check the error messages above." -ForegroundColor Red
        }
    }
    "logs" {
        Write-Host "Showing logs from all containers..." -ForegroundColor Green
        docker-compose logs -f
    }
    "backend" {
        Write-Host "Accessing backend container shell..." -ForegroundColor Green
        docker-compose exec backend bash
    }
    "frontend" {
        Write-Host "Accessing frontend container shell..." -ForegroundColor Green
        docker-compose exec frontend sh
    }
    "db" {
        Write-Host "Accessing database container shell..." -ForegroundColor Green
        docker-compose exec db bash
    }
    "keycloak" {
        Write-Host "Accessing keycloak container shell..." -ForegroundColor Green
        docker-compose exec keycloak bash
    }
    "migrate" {
        Write-Host "Running database migrations..." -ForegroundColor Green
        docker-compose exec backend python manage.py migrate
    }
    "reset-db" {
        Write-Host "Warning: This will delete all data in the database." -ForegroundColor Yellow
        $confirmation = Read-Host "Are you sure you want to continue? (y/n)"
        if ($confirmation -eq 'y') {
            Write-Host "Resetting database..." -ForegroundColor Green
            docker-compose down
            docker volume rm neqat_db_data
            docker-compose up -d
            Write-Host "Waiting for database to initialize..." -ForegroundColor Green
            Start-Sleep -Seconds 20
            Write-Host "Running migrations..." -ForegroundColor Green
            docker-compose exec backend python manage.py migrate
        }
    }
    "fix-db" {
        Write-Host "Fixing database connection issues..." -ForegroundColor Green
        # Stop and remove the containers
        docker-compose down
        # Remove db volume
        docker volume rm neqat_db_data
        # Update the user in the docker-compose environment
        Write-Host "Starting services again..." -ForegroundColor Green
        docker-compose up -d db
        Write-Host "Waiting for database to initialize..." -ForegroundColor Green
        Start-Sleep -Seconds 30
        # Check if db is up
        docker-compose exec db /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "ChangeMe_Dev123!" -Q "SELECT @@version"
        if ($?) {
            Write-Host "Database is up and running!" -ForegroundColor Green
            docker-compose up -d
            Write-Host "Starting migrations..." -ForegroundColor Green
            Start-Sleep -Seconds 10
            docker-compose exec backend python manage.py migrate
        } else {
            Write-Host "Database is not ready yet. Try again later or check logs with: .\dev.ps1 logs" -ForegroundColor Red
        }
    }
    "check-db" {
        Write-Host "Checking database connection..." -ForegroundColor Green
        docker-compose exec db /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "ChangeMe_Dev123!" -Q "SELECT @@version"
    }
    "run-local" {
        Write-Host "Running Django backend locally (accessible from other devices)..." -ForegroundColor Green
        
        # First change directory to backend
        Set-Location -Path .\backend
        
        # Then run the Django server on 0.0.0.0
        Write-Host "Starting Django server on all interfaces (0.0.0.0:8000)..." -ForegroundColor Cyan
        python manage.py runserver 0.0.0.0:8000
        
        # Return to original directory when done
        Set-Location -Path ..
    }
    default {
        Show-Help
    }
} 