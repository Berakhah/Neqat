# Neqat Project

A professional full-stack application featuring a Django backend, Flutter web frontend, SQL Server database, and Keycloak authentication with integrated biometric security.

<div align="center">
  <img src="frontend/images/neqat_logo/logo-color.svg" alt="Neqat Logo" width="200">
</div>

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [System Architecture](#-system-architecture)
- [Prerequisites](#-prerequisites)
- [Getting Started](#-getting-started)
  - [Setup on Windows](#setup-on-windows)
  - [Setup on Linux/macOS](#setup-on-linuxmacos)
  - [Local Development Setup](#local-development-setup)
- [Development Workflow](#-development-workflow)
- [Docker Environment](#-docker-environment)
- [Directory Structure](#-directory-structure)
- [Authentication](#-authentication)
  - [Setting Up Keycloak](#setting-up-keycloak)
  - [Authentication Flow](#authentication-flow)
  - [Biometric Authentication](#biometric-authentication)
- [Password Reset & Email Verification](#-password-reset--email-verification)
- [Working with Frontend](#-working-with-frontend)
- [Working with Backend](#-working-with-backend)
- [Telegram Scraper](#-telegram-scraper)
- [Troubleshooting](#-troubleshooting)
- [Deployment](#-deployment)

## 🔍 Overview

Neqat is a modern web application designed to provide robust functionality with a secure authentication system. The application follows a micro-service architecture, combining multiple technologies into a cohesive development environment.

## ✨ Features

- **Multi-layer Authentication**: Secure login with Keycloak, including roles and permissions
- **Biometric Authentication**: Support for fingerprint and face recognition on compatible devices
- **Multi-language Support**: Localization for multiple languages including English and Amharic
- **News Aggregation**: Integrated news feeds from multiple sources
- **Telegram Integration**: Telegram scraper for channel monitoring
- **Modern UI**: Responsive Flutter-based frontend with dark mode support
- **Secure API**: RESTful API with token-based authentication
- **Social Login**: Google, Facebook, and other third-party authentication providers
- **Admin Dashboard**: Comprehensive admin tools for content moderation and user management

## 🏗️ System Architecture

The system consists of several microservices running in Docker containers:

1. **Backend** - Django REST API
2. **Frontend** - Flutter Web application
3. **Database** - Microsoft SQL Server instance
4. **Keycloak** - Authentication and authorization server

## 📋 Prerequisites

To run Neqat, you need:

- [Docker](https://www.docker.com/products/docker-desktop) (v20.10+)
- [Docker Compose](https://docs.docker.com/compose/install/) (v2.0+)
- [Git](https://git-scm.com/downloads) (v2.30+)
- [PowerShell](https://docs.microsoft.com/en-us/powershell/) v5.1+ (Windows users) or Bash (Linux/macOS)
- At least 8GB RAM and 10GB disk space

For local development, you'll also need:

- [Python](https://www.python.org/downloads/) (v3.8+)
- [Flutter](https://flutter.dev/docs/get-started/install) (latest stable)
- [Node.js](https://nodejs.org/) (v16+)
- [VSCode](https://code.visualstudio.com/) (recommended) with Flutter and Dart extensions

## 🚀 Getting Started

### Setup on Windows

1. **Clone the repository**

```bash
git clone https://github.com/yourusername/Neqat.git
cd Neqat
```

2. **Start the development environment**

```powershell
.\dev.ps1 up
```

This script handles:
- Starting all Docker containers
- Setting up the database
- Configuring Keycloak
- Building the frontend and backend
- Exposing all services on appropriate ports

3. **Access the application**

- Frontend: http://localhost:3000
- Backend API: http://localhost:8000
- Keycloak Admin: http://localhost:8080 (admin/AdminPassword123!)
- Database: localhost:1433 (SA/NEQ@T2025ComplexPass!)

### Setup on Linux/macOS

1. **Clone the repository**

```bash
git clone https://github.com/yourusername/Neqat.git
cd Neqat
```

2. **Start the development environment**

```bash
# Make the script executable
chmod +x ./dev.sh

# Start all services
./dev.sh up
```

3. **Access the application**

The access URLs are the same as in the Windows setup.

### Local Development Setup

If you prefer to run components locally without Docker:

1. **Backend Setup**

```bash
# Create and activate virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\Activate.ps1

# Install dependencies
pip install -r backend/requirements.txt

# Set up environment variables
# Copy backend/docker.env to backend/.env and modify as needed

# Run migrations and start server
cd backend
python manage.py migrate
python manage.py runserver
```

2. **Frontend Setup**

```bash
# Navigate to frontend directory
cd frontend

# Install Flutter dependencies
flutter pub get

# Copy environment file and modify as needed
cp api.env 

# Run the app in development mode
flutter run -d chrome
```

## 💻 Development Workflow

### Making Code Changes

When you modify the code in your local file system, these changes are automatically reflected in the Docker containers due to volume mapping:

1. **Backend changes**:
   - Edit Python files in the `backend/` directory
   - Django's development server will automatically reload
   - Add new dependencies to `requirements.txt` if needed

2. **Frontend changes**:
   - Edit Flutter files in the `frontend/` directory
   - For significant changes, run `.\dev.ps1 rebuild frontend` to rebuild the frontend container

### Common Development Tasks

#### Database Migrations

```bash
# Create new migrations
.\dev.ps1 backend
python manage.py makemigrations

# Apply migrations
.\dev.ps1 migrate
```

#### Access Container Shells

```bash
# Backend shell
.\dev.ps1 backend

# Frontend shell
.\dev.ps1 frontend

# Database shell
.\dev.ps1 db

# Keycloak shell
.\dev.ps1 keycloak
```

#### View Logs

```bash
.\dev.ps1 logs
```

#### Reset Database

```bash
.\dev.ps1 reset-db
```

#### Stop All Services

```bash
.\dev.ps1 down
```

#### Rebuild All Services

After major changes or when pulling updates from the repository:

```bash
.\dev.ps1 rebuild
```

## 🐳 Docker Environment

### Key Files

- `docker-compose.yml`: Defines all services and their relationships
- `backend/Dockerfile`: Builds the Django backend container
- `frontend/Dockerfile`: Builds the Flutter web frontend container
- `dev.ps1` / `dev.sh`: Script for managing the development environment

### Environment Variables

The project uses multiple environment files for different contexts:

#### Docker Environment Files
- `backend/docker.env`: Used by the backend container in Docker
- `frontend/api.env`: Used by the frontend container in Docker

#### Local Development Environment Files
- `frontend/api.local.env`: Used for local (non-Docker) frontend development

#### Important Environment Variables

| Variable | Used By | Purpose |
|----------|---------|---------|
| `KEYCLOAK_REALM` | Both | The Keycloak realm name (neqat-realm) |
| `KEYCLOAK_CLIENT_ID` | Both | Client ID for each service |
| `KEYCLOAK_CLIENT_SECRET` | Backend | Secret for secure server-to-server communication |
| `DATABASE_*` | Backend | Database connection parameters |
| `django_api` | Frontend | URL to connect to the backend API |

## 📁 Directory Structure

```
/
├── backend/                  # Django backend
│   ├── api/                  # Main API app
│   │   ├── migrations/       # Database migrations
│   │   ├── services/         # Business logic services
│   │   ├── telegram/         # Telegram integration
│   │   └── management/       # Django management commands
│   ├── backend/              # Project settings
│   ├── docker.env            # Environment variables
│   └── Dockerfile            # Backend container build
├── frontend/                 # Flutter frontend
│   ├── lib/                  # Frontend code
│   │   ├── app/              # App configuration
│   │   ├── core/             # Core utilities
│   │   │   ├── network/      # Network clients
│   │   │   └── presentation/ # Guards and session handlers
│   │   ├── features/         # Feature modules
│   │   │   ├── auth/         # Authentication (inc. biometric)
│   │   │   ├── admin/        # Admin dashboard 
│   │   │   └── ...
│   │   └── services/         # Services (inc. Keycloak)
│   ├── api.env               # API env variables
│   └── Dockerfile            # Frontend container build
├── docker-compose.yml        # Docker services configuration
├── dev.ps1                   # Windows development script
├── dev.sh                    # Linux/macOS development script
└── README.md                 # This file
```

## 🔐 Authentication

### Setting Up Keycloak

Keycloak provides authentication and user management. The initial setup is handled automatically when you run `dev.ps1 up`, but here's the manual setup process:

1. **Access the Admin Console**:
   - Navigate to http://localhost:8080
   - Login with admin/AdminPassword123!

2. **Create the Realm**:
   - Create a new realm named `neqat-realm`

3. **Configure the Backend Client**:
   - Create client `django-backend` (confidential client)
   - Set valid redirect URIs to `http://localhost:8000/*`
   - Enable client authentication
   - Note the client secret for backend configuration

4. **Configure the Frontend Client**:
   - Create client `flutter-client` (public client)
   - Set valid redirect URIs to `http://localhost:3000/*`
   - Set web origins to `http://localhost:3000`
   - Disable client authentication

5. **Configure User Roles**:
   - Create roles `app-user` and `app-admin`
   - Create test users and assign appropriate roles

### Authentication Flow

1. Users authenticate via the Flutter frontend with Keycloak
2. Keycloak issues a JWT token
3. The frontend includes this token in all API requests
4. The backend validates the token with Keycloak
5. Token refresh happens automatically when needed

### Biometric Authentication

The application supports biometric authentication on compatible devices:

1. **Setup**:
   - Enable in Settings section of the app
   - Requires device with biometric hardware (fingerprint/face)
   - Works with both Android and iOS devices

2. **Usage**:
   - Once enabled, login screen shows biometric option
   - Securely stores credentials for biometric access
   - Implements proper security validations

3. **Testing**:
   - Use the `/biometric-test` route to test functionality
   - Toggle biometric authentication on/off
   - View detailed status of biometric capabilities

## 🔑 Password Reset & Email Verification

The application supports two critical user flows:

### Password Reset Flow

1. **Request Reset**:
   - User requests password reset on the forgot-password page
   - Reset link is sent to user's email

2. **Password Reset**:
   - User clicks link in email which includes token/key + code
   - Frontend displays reset form with fields for new password
   - Password requirements are validated client-side

### Email Verification Flow

1. **Registration**:
   - Upon registration, verification email is sent
   - Email contains verification link with required parameters

2. **Verification**:
   - User clicks link in email
   - Backend processes verification and updates user status
   - User is redirected to frontend with success/error status

### Email Configuration

For email functionality to work, configure the following in your `.env` file:

```
# Email Settings
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-password
DEFAULT_FROM_EMAIL=noreply@neqat.com

# Frontend URL for email links
FRONTEND_URL=http://localhost:8000
```

## 🖥️ Working with Frontend

The frontend is built with Flutter and uses several key technologies:

- **State Management**: Riverpod
- **Routing**: go_router
- **HTTP Client**: Dio with interceptors
- **Storage**: flutter_secure_storage
- **Localization**: flutter_localizations

### Key Components

1. **Authentication**:
   - `KeycloakService`: Handles auth with Keycloak
   - `AuthGuard`: Protects routes requiring authentication
   - `SessionTimeoutHandler`: Manages user session timeouts
   - `BiometricService`: Manages biometric authentication

2. **Networking**:
   - `DioClient`: HTTP client with token management
   - Token refresh interceptors
   - Error handling

3. **UI**:
   - Responsive layouts
   - Dark/light theme support
   - Custom components

### Flutter Tips

```bash
# Run Flutter tests
cd frontend
flutter test

# Build for web
flutter build web

# Change pub dependencies
flutter pub add package_name
flutter pub remove package_name

# Generate localization files
flutter gen-l10n
```

## 🖧 Working with Backend

The backend is built with Django REST Framework and integrates with:

- **Database**: Microsoft SQL Server
- **Authentication**: Keycloak via Python client
- **External Services**: Telegram API

### Key Components

1. **API Structure**:
   - Core API endpoints in `api/views.py`
   - Authentication middleware in `api/auth.py`
   - Service layer for business logic

2. **Database**:
   - SQL Server with custom models
   - Django ORM for database operations
   - Migrations for schema changes

3. **External Integrations**:
   - Telegram scraper for channel data

### Django Tips

```bash
# Create a new app
python manage.py startapp app_name

# Make migrations after model changes
python manage.py makemigrations

# Apply migrations
python manage.py migrate

# Create a superuser
python manage.py createsuperuser

# Run Django shell
python manage.py shell
```

## 📱 Telegram Scraper

The application includes a Telegram scraper feature that allows collecting messages from Telegram channels:

### Setup

1. Register your Telegram application on https://my.telegram.org/auth to get API credentials
2. Set the following environment variables:
   ```
   TELEGRAM_API_ID=your_api_id
   TELEGRAM_API_HASH=your_api_hash
   ```

### Usage

```bash
# Fetch the last 100 messages from a channel
python manage.py telegram_scraper --channel channel_name

# Fetch a specific number of messages
python manage.py telegram_scraper --channel channel_name --limit 50

# Listen for new messages (runs continuously)
python manage.py telegram_scraper --channel channel_name --listen
```

## ❓ Troubleshooting

### Common Issues

1. **Docker connection error**
   - Ensure Docker Desktop is running
   - Restart Docker if necessary

2. **Database connection issues**
   - Run `.\dev.ps1 check-db` to verify database is running
   - If problems persist, try `.\dev.ps1 reset-db`

3. **Container build failures**
   - Check for errors in `docker-compose logs backend` (or other service)
   - Try rebuilding with `.\dev.ps1 rebuild`

4. **"Unhealthy" container status**
   - Check logs with `docker-compose logs [service_name]`
   - Restart the service with `docker-compose restart [service_name]`

5. **Authentication issues**
   - Verify Keycloak is running properly
   - Check client configuration
   - Ensure environment variables are set correctly

6. **Biometric authentication not working**
   - Verify device supports biometrics
   - Check proper permission handling
   - Use the test screen at `/biometric-test`

## 🌐 Deployment

For production deployment:

1. Update environment variables for production settings
2. Use a production-ready database configuration
3. Configure SSL for secure communication
4. Set up proper Keycloak realm and client for production
5. Consider using an orchestration service like Kubernetes for scaling

---

Created and maintained by the Neqat Team 