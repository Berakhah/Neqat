# Neqat Backend

A Django REST API backend for the Neqat application.

## Prerequisites

- Python 3.8+
- Docker (for SQL Server)
- Git

## Environment Configuration

The project uses environment variables for configuration. These can be defined in two files:

- `.env` - For local development
- `docker.env` - For Docker deployment

### Generating Environment Files

We provide a script to generate/update environment files with the required configuration:

```bash
# Update environment files
python backend/scripts/generate_env.py

# Force update of Keycloak settings
python backend/scripts/generate_env.py --force
```

For Windows users, we also provide a PowerShell script that updates the environment and starts the server:

```powershell
# Run the script
.\backend\scripts\run_with_updated_env.ps1

# Force update of Keycloak settings
.\backend\scripts\run_with_updated_env.ps1 --force
```

### Keycloak Configuration

The project uses Keycloak for authentication. The following environment variables are required:

```
KEYCLOAK_SERVER_URL=http://keycloak:8080
KEYCLOAK_REALM=neqat-realm
KEYCLOAK_CLIENT_ID=django-backend
KEYCLOAK_CLIENT_SECRET=your_client_secret
KEYCLOAK_ADMIN_CLIENT_ID=admin-cli
KEYCLOAK_ADMIN_CLIENT_SECRET=your_admin_client_secret

# Token keys (matching frontend implementation)
KEYCLOAK_ACCESS_TOKEN_KEY=access_token
KEYCLOAK_REFRESH_TOKEN_KEY=refresh_token
KEYCLOAK_ID_TOKEN_KEY=id_token
KEYCLOAK_TOKEN_EXPIRY_KEY=token_expiry
```

## Setup Instructions

### 1. Clone the Repository

```bash
git clone <repository-url>
cd NeqatBackend
```

### 2. Set Up Virtual Environment

```bash
python -m venv venv
.\venv\Scripts\Activate.ps1
source venv/bin/activate
```

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

### 4. Set Up SQL Server Database

The project uses Microsoft SQL Server. The easiest way to run it is using Docker:

```bash
docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=NEQ@T2025" \
   -p 1433:1433 --name sqlserver \
   -d mcr.microsoft.com/mssql/server:2022-latest
```

### 5. Initialize Database

Create the database and stored procedures:

```bash
# Connect to SQL Server container
docker exec -it sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "NEQ@T2025"
#What worked for me @Finhas by automatically trusting 
docker exec -it sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "NEQ@T2025" -C

# Run the SQL setup script (or copy-paste contents)
:r Create_Everything.sql
GO
#what worked for me @Finhas
docker cp C:\Users\hp\Desktop\Winter2025\Neqat\Neqat\backend\Create_Everything.sql sqlserver:/tmp/Create_Everything.sql

docker exec -it sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "NEQ@T2025" -C

:r /tmp/Create_Everything.sql
GO
```

### Extra Step

Install the microsoft 
### 6. Apply Django Migrations

```bash
python manage.py migrate
```

### 7. Create Superuser (Optional)

```bash
python manage.py createsuperuser
```

### 8. Run Development Server

```bash
python manage.py runserver
```

The server will start at http://127.0.0.1:8000/

## API Endpoints

### Authentication

- **Register**: `POST /api/register/`
  - Required fields: `user_name`, `email`, `password`
  - Optional fields: `first_name`, `last_name`, `profile_image`

- **Login**: `POST /api/login/`
  - Required fields: `email`, `password`

- **Social Login**: `POST /api/social-login/`
  - Required fields: `provider` (google, facebook, or apple), `access_token`

### User Management

- **Profile**: `GET /api/profile/`
  - Requires authentication

- **Forgot Password**: `POST /api/forgot-password/`
  - Required field: `email`

- **Reset Password**: `POST /api/reset-password/`
  - Required fields: `token`, `new_password`

## Telegram Scraper

The application includes a Telegram scraper feature that allows you to collect messages from Telegram channels for analysis and display.

### Setup

1. Register your Telegram application on https://my.telegram.org/auth to get API credentials
2. Set the following environment variables:
   ```
   TELEGRAM_API_ID=your_api_id
   TELEGRAM_API_HASH=your_api_hash
   ```

### Usage

You can use the management command to fetch messages from channels:

```bash
# Fetch the last 100 messages from a channel
python manage.py telegram_scraper --channel channel_name

# Fetch a specific number of messages
python manage.py telegram_scraper --channel channel_name --limit 50

# Listen for new messages (runs continuously)
python manage.py telegram_scraper --channel channel_name --listen
```

### API Endpoints

- `GET /api/telegram-messages/` - Retrieve all messages
- `GET /api/telegram-messages/?channel=channel_name` - Retrieve messages from a specific channel

### Frontend

The Telegram messages can be viewed in the application by navigating to the Telegram page in the main menu. You can filter messages by channel and view message details.

## Project Structure

- `NeqatBackend/`