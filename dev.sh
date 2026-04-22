#!/bin/bash

# Define text colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        echo -e "${RED}Error: Docker is not running. Please start Docker and try again.${NC}"
        exit 1
    fi
}

# Function to display help
show_help() {
    echo -e "${GREEN}Neqat Development Script${NC}"
    echo "Usage: ./dev.sh [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  up         Start all containers in detached mode"
    echo "  down       Stop all containers"
    echo "  rebuild    Rebuild and restart all containers"
    echo "  logs       Show logs from all containers"
    echo "  backend    Access the backend container shell"
    echo "  frontend   Access the frontend container shell"
    echo "  db         Access the database container shell"
    echo "  keycloak   Access the keycloak container shell"
    echo "  migrate    Run database migrations"
    echo "  reset-db   Reset the database and run migrations"
    echo "  fix-db     Fix database connection issues"
    echo "  check-db   Check database connection"
    echo "  help       Show this help message"
}

# Check if Docker is running
check_docker

# Process commands
case "$1" in
    up)
        echo -e "${GREEN}Starting Docker containers...${NC}"
        docker-compose up -d
        echo -e "${GREEN}Services are running at:${NC}"
        echo -e "  Frontend:  ${YELLOW}http://localhost:3000${NC}"
        echo -e "  Backend:   ${YELLOW}http://localhost:8000${NC}"
        echo -e "  Keycloak:  ${YELLOW}http://localhost:8080${NC} (admin/NEQ@T2025)"
        echo -e "  Database:  ${YELLOW}localhost:1433${NC} (SA/NEQ@T2025ComplexPass!)"
        ;;
    down)
        echo -e "${GREEN}Stopping Docker containers...${NC}"
        docker-compose down
        ;;
    rebuild)
        echo -e "${GREEN}Rebuilding and restarting Docker containers...${NC}"
        docker-compose down
        docker-compose build
        docker-compose up -d
        ;;
    logs)
        echo -e "${GREEN}Showing logs from all containers...${NC}"
        docker-compose logs -f
        ;;
    backend)
        echo -e "${GREEN}Accessing backend container shell...${NC}"
        docker-compose exec backend bash
        ;;
    frontend)
        echo -e "${GREEN}Accessing frontend container shell...${NC}"
        docker-compose exec frontend sh
        ;;
    db)
        echo -e "${GREEN}Accessing database container shell...${NC}"
        docker-compose exec db bash
        ;;
    keycloak)
        echo -e "${GREEN}Accessing keycloak container shell...${NC}"
        docker-compose exec keycloak bash
        ;;
    migrate)
        echo -e "${GREEN}Running database migrations...${NC}"
        docker-compose exec backend python manage.py migrate
        ;;
    reset-db)
        echo -e "${YELLOW}Warning: This will delete all data in the database.${NC}"
        read -p "Are you sure you want to continue? (y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${GREEN}Resetting database...${NC}"
            docker-compose down
            docker volume rm neqat_db_data
            docker-compose up -d
            echo -e "${GREEN}Waiting for database to initialize...${NC}"
            sleep 20
            echo -e "${GREEN}Running migrations...${NC}"
            docker-compose exec backend python manage.py migrate
        fi
        ;;
    fix-db)
        echo -e "${GREEN}Fixing database connection issues...${NC}"
        # Stop and remove the containers
        docker-compose down
        # Remove db volume
        docker volume rm neqat_db_data
        # Update the user in the docker-compose environment
        echo -e "${GREEN}Starting services again...${NC}"
        docker-compose up -d db
        echo -e "${GREEN}Waiting for database to initialize...${NC}"
        sleep 30
        # Check if db is up
        docker-compose exec db /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "NEQ@T2025ComplexPass!" -Q "SELECT @@version"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Database is up and running!${NC}"
            docker-compose up -d
            echo -e "${GREEN}Starting migrations...${NC}"
            sleep 10
            docker-compose exec backend python manage.py migrate
        else
            echo -e "${RED}Database is not ready yet. Try again later or check logs with: ./dev.sh logs${NC}"
        fi
        ;;
    check-db)
        echo -e "${GREEN}Checking database connection...${NC}"
        docker-compose exec db /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "NEQ@T2025ComplexPass!" -Q "SELECT @@version"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Database connection successful!${NC}"
            docker-compose exec db /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "NEQ@T2025ComplexPass!" -Q "SELECT name FROM sys.databases"
        else
            echo -e "${RED}Could not connect to database. Check logs with: ./dev.sh logs${NC}"
        fi
        ;;
    *)
        show_help
        ;;
esac 