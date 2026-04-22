# Neqat Project

A full-stack application featuring a Django backend, Flutter web frontend, SQL Server database, and Keycloak authentication.

## 📋 Table of Contents

- [Overview](#overview)
- [System Architecture](#system-architecture)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Docker Environment](#docker-environment)
- [Directory Structure](#directory-structure)
- [User Authentication](#user-authentication)
- [Password Reset & Email Verification](#password-reset--email-verification)
- [Frontend-Backend Connection Points](#frontend-backend-connection-points)
- [Troubleshooting](#troubleshooting)
- [Deployment](#deployment)
- [Token Testing](#token-testing)

## 🔍 Overview

Neqat is a modern web application designed to provide robust functionality with a secure authentication system. The application uses:

- **Backend**: Django REST Framework
- **Frontend**: Flutter Web
- **Database**: Microsoft SQL Server
- **Authentication**: Keycloak

## 🏗️ System Architecture

The system is composed of several microservices running in Docker containers:

1. **Backend** - Django REST API
2. **Frontend** - Flutter Web application
3. **Database** - SQL Server instance
4. **Keycloak** - Authentication and authorization server

## 📋 Prerequisites

- [Docker](https://www.docker.com/products/docker-desktop)
- [Docker Compose](https://docs.docker.com/compose/install/)
- [PowerShell](https://docs.microsoft.com/en-us/powershell/) (for Windows users)
- Git

## 🚀 Getting Started

1. **Clone the repository**

```bash
git clone https://github.com/yourusername/Neqat.git
cd Neqat
```

2. **Start the development environment**

```bash
.\dev.ps1 up
```

This will start all services in detached mode. The first run might take longer as it needs to build all images.

3. **Access the application**

- Frontend: http://localhost:3000
- Backend API: http://localhost:8000
- Keycloak Admin: http://localhost:8080 (admin/AdminPassword123!)
- Database: localhost:1433 (SA/ChangeMe_Dev123!)

## 💻 Development Workflow

### Making Code Changes

When you modify the code in your local file system, these changes are automatically reflected in the Docker containers due to the volume mapping:

1. **Backend changes**:
   - Edit Python files in the `backend/` directory
   - Django's development server will automatically reload
   - Add new dependencies to `requirements.txt` if needed

2. **Frontend changes**:
   - Edit Flutter files in the `frontend/` directory
   - For significant changes, run `.\dev.ps1 rebuild` to rebuild the frontend container

### Common Development Tasks

#### Database Migrations

Create new migrations:
```bash
docker-compose exec backend python manage.py makemigrations
```

Apply migrations:
```bash
.\dev.ps1 migrate
```

#### Access Container Shell

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
- `dev.ps1`: PowerShell script for managing the development environment

### Environment Variables

The project uses multiple environment files for different contexts:

#### Docker Environment Files
- `backend/docker.env`: Used by the backend container in Docker
- `frontend/api.env`: Used by the frontend container in Docker

#### Local Development Environment Files
- `frontend/api.local.env`: Used for local (non-Docker) frontend development

#### How Environment Variables Are Loaded

1. **Backend**:
   - In Docker: Variables from `backend/docker.env` are loaded via the `env_file` directive in `docker-compose.yml`
   - Additional environment variables are directly set in the `environment` section of `docker-compose.yml`
   - The Django application loads these using `python-dotenv` at startup in `settings.py`

2. **Frontend**:
   - In Docker: Variables from `frontend/api.env` are loaded via the `env_file` directive in `docker-compose.yml`
   - The Flutter application loads these using `flutter_dotenv` at startup in `main.dart`
   - Values are accessed through the `ApiConstants` class which provides fallback values if not found

3. **Precedence**:
   - Environment variables defined directly in `docker-compose.yml` override those in the env files
   - For local development, copy and modify the appropriate .env file

#### Important Environment Variables

| Variable | Used By | Purpose |
|----------|---------|---------|
| `KEYCLOAK_REALM` | Both | The Keycloak realm name (neqat-realm) |
| `KEYCLOAK_CLIENT_ID` | Both | Client ID for each service (django-backend/flutter-client) |
| `KEYCLOAK_CLIENT_SECRET` | Backend | Secret for secure server-to-server communication |
| `DATABASE_*` | Backend | Database connection parameters |
| `django_api` | Frontend | URL to connect to the backend API |

### Volumes

- `db_data`: Persistent database storage
- `static_volume`: Django static files
- `media_volume`: User uploaded media files

## 📁 Directory Structure

```
/
├── backend/                  # Django backend
│   ├── api/                  # Main app
│   ├── backend/              # Project settings
│   ├── docker.env            # Environment variables
│   └── Dockerfile            # Backend container build
├── frontend/                 # Flutter frontend
│   ├── lib/                  # Frontend code
│   ├── api.env               # API env variables
│   └── Dockerfile            # Frontend container build
├── docker-compose.yml        # Docker services configuration
├── dev.ps1                   # Development management script
└── README.md                 # This file
```

## 🔐 User Authentication

### Keycloak Setup

Keycloak provides authentication and user management:

- Admin console: http://localhost:8080
- Credentials: admin/AdminPassword123!
- Realm: neqat-realm
- Client ID: django-backend (for backend) and flutter-client (for frontend)

#### Keycloak Configuration Status

✅ **Configuration Complete!** The Keycloak server has been configured with:

1. **Realm**: `neqat-realm` has been created
2. **Clients**:
   - `django-backend` (confidential client for backend) with secret in docker.env
   - `flutter-client` (public client for frontend)
3. **Test Users**:
   - Username: `admin`
   - Email: `admin@gmail.com`
   - Password: `ChangeMe_Dev123!`
   - Temporary password: `OFF`
4. **User Roles**:
   - `app-user`: Basic application access
   - `app-admin`: Administrative privileges

If you need to modify or recreate this configuration, follow the detailed steps below.

#### Complete Keycloak Configuration Steps

To recreate or modify the Keycloak configuration:

1. **Access the Admin Console**:
   - Navigate to http://localhost:8080
   - Login with admin/AdminPassword123!

2. **Create the Realm**:
   - Click on the dropdown in the top-left corner (shows "master" by default)
   - Click "Create Realm"
   - Name: `neqat-realm`
   - Click "Create"

3. **Configure the Backend Client**:
   - Go to "Clients" in the left sidebar
   - Click "Create client"
   - Client ID: `django-backend`
   - Client type: `OpenID Connect`
   - Click "Next"
   - Enable client authentication: ON
   - Authorization: ON
   - Click "Next", then "Save"
   - In the Settings tab, set:
     - Access type: `confidential`
     - Valid redirect URIs: `http://localhost:8000/*`
     - Web origins: `http://localhost:8000` (or `+` to allow all origins)
   - Click "Save"
   - Go to the "Credentials" tab and note the client secret
   - Update the secret in `backend/docker.env` (currently set to `jOjIj1K1ULe9pOSSA3hP4s61EhCESe1j`)

4. **Configure the Frontend Client**:
   - Go to "Clients" in the left sidebar
   - Click "Create client"
   - Client ID: `flutter-client`
   - Client type: `OpenID Connect`
   - Click "Next"
   - Enable client authentication: OFF
   - Authorization: OFF
   - Click "Next", then "Save"
   - In the Settings tab, set:
     - Access type: `public`
     - Valid redirect URIs: `http://localhost:3000/*`
     - Web origins: `http://localhost:3000`
   - Click "Save"

5. **Create Test Users**:
   - Go to "Users" in the left sidebar
   - Click "Add user"
   - Username: `admin`
   - Email: `admin@gmail.com`
   - Click "Create"
   - Go to the "Credentials" tab
   - Set password to `ChangeMe_Dev123!` and disable "Temporary"
   - Click "Set Password"

6. **Configure User Roles**:
   - Go to "Realm roles" in the left sidebar
   - Click "Create role"
   - Role name: `app-user`
   - Click "Save"
   - Create another role named `app-admin`
   - Go to "Users" and select your admin user
   - Go to "Role mappings" tab
   - Assign the `app-admin` role

7. **Environment Variables**:
   - Verify that `backend/docker.env` contains:
     ```
     KEYCLOAK_SERVER_URL=http://keycloak:8080
     KEYCLOAK_REALM=neqat-realm
     KEYCLOAK_CLIENT_ID=django-backend
     KEYCLOAK_CLIENT_SECRET=jOjIj1K1ULe9pOSSA3hP4s61EhCESe1j
     ```
   - Verify that `frontend/api.env` contains:
     ```
     KEYCLOAK_URL=http://keycloak:8080
     KEYCLOAK_REALM=neqat-realm
     KEYCLOAK_CLIENT_ID=flutter-client
     ```

### Authentication Flow

1. Users authenticate via the Flutter frontend with Keycloak
2. Keycloak issues a JWT token
3. The frontend includes this token in all API requests
4. The Django backend validates the token with Keycloak

## 🔑 Password Reset & Email Verification

The application supports two critical user flows:

### Password Reset Flow

1. **Request Reset**:
   - User requests password reset on the forgot-password page
   - Backend attempts to send reset through Keycloak's built-in method
   - If Keycloak method fails, falls back to custom implementation
   - Reset link is sent to user's email

2. **Password Reset**:
   - User clicks link in email which includes token/key + code
   - Frontend displays reset form with fields for new password
   - Password requirements are validated client-side
   - Backend validates token and updates password
   - User is redirected to login

### Email Verification Flow

1. **Registration**:
   - Upon registration, verification email is sent through Keycloak
   - Email contains verification link with required parameters

2. **Verification**:
   - User clicks link in email
   - Backend processes verification and updates user status
   - User is redirected to frontend with success/error status
   - Frontend displays appropriate message based on status

### Implementation Notes

- The system supports both Keycloak's native email functionality and a custom fallback method
- URL formats use consistent hyphenation (e.g., `/reset-password` instead of `/resetpassword`)
- Frontend screens handle both formats for backward compatibility
- All text is fully localized in both English and Amharic

### Configuration

For email functionality to work, configure the following in your `.env` file:

```
# Email Settings (for password reset and verification)
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

Additionally, Keycloak must be configured with SMTP settings through the admin console to use its built-in email functionality.

## 🔄 Frontend-Backend Connection Points

### Authentication Flow

1. **Authentication Setup**:
    - The project uses Keycloak for identity management and authentication
    - Keycloak is running on `http://localhost:8080`
    - The realm is `neqat-realm`
    - Frontend uses client ID `flutter-client`
    - Backend uses client ID `django-backend`
2. **Login Process**:
    - Frontend makes a request to `http://localhost:8000/api/login/` with user credentials
    - Backend authenticates with Keycloak and returns access/refresh tokens
    - Tokens are stored in the secure storage on the client side
3. **API Authentication**:
    - Frontend adds Bearer token to all requests in the Authorization header
    - Backend validates tokens using `KeycloakAuthentication` backend
    - Token refresh happens automatically when tokens expire

### API Communication

1. **HTTP Clients**:
    - Frontend has two HTTP clients:
        1. `ApiClient` - Uses http package for general API requests
        2. `DioClient` - Uses dio package with interceptors for token management
2. **API Endpoints**:
    - All API endpoints are prefixed with `/api/`
    - Main resource endpoints:
        - `/api/posts/` - Post management
        - `/api/comments/` - Comment management
        - `/api/news/` - News retrieval
        - `/api/content-flags/` - Content flagging
    - Admin endpoints:
        - `/api/admin/dashboard/` - Admin dashboard metrics
        - `/api/admin/users/` - User management
        - `/api/admin/posts/` - Post moderation
        - `/api/admin/comments/` - Comment moderation
3. **Database Connection**:
    - Backend uses MS SQL Server with ODBC Driver 18
    - Database name is `NeqatDB`
    - Authentication uses SQL Server authentication

### Configuration Management

1. **Environment Variables**:
    - Frontend loads environment variables from `api.env`
    - Backend loads environment variables from `docker.env` file
    - Key variables include:
        - API endpoints
        - Keycloak configuration
        - Database credentials
2. **API Constants**:
    - Frontend defines all API endpoints in `ApiConstants` class
    - Backend defines URL patterns in `urls.py`

### Security Considerations

1. **Token Management**:
    - Access tokens stored in secure storage
    - Automatic token refresh when expired
    - CORS configured for proper access control
2. **Error Handling**:
    - Both backend and frontend have robust error handling for HTTP requests
    - Backend logs authentication failures and security events

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

## 🌐 Deployment

For production deployment:

1. Update environment variables for production settings
2. Use a production-ready database configuration
3. Configure SSL for secure communication
4. Set up proper Keycloak realm and client for production
5. Consider using an orchestration service like Kubernetes for scaling

## Token Testing

For testing Keycloak authentication and token validation, see [TOKEN_TESTING.md](TOKEN_TESTING.md). 

This document provides detailed instructions for:
- Testing backend authentication with direct Keycloak tokens
- Using the Python test script to verify all authentication endpoints
- Testing the Flutter frontend with the token test screen
- Troubleshooting common token validation issues

**Note: We've discovered an authentication architecture issue where the login endpoint itself requires authentication. See the TOKEN_TESTING.md file for details and recommendations on fixing this circular dependency.**

---

Created and maintained by the Neqat Team 