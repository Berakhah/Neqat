#!/usr/bin/env pwsh
# This script runs the Flutter frontend with local environment variables

# Check if Flutter is installed
$flutter = Get-Command flutter -ErrorAction SilentlyContinue
if ($null -eq $flutter) {
    Write-Error "Flutter not found. Please install Flutter and add it to your PATH."
    exit 1
}

# Make sure we're in the frontend directory
if (-not (Test-Path "pubspec.yaml")) {
    Write-Error "This script must be run from the frontend directory."
    exit 1
}

# Check if api.local.env exists
if (-not (Test-Path "api.local.env")) {
    Write-Warning "api.local.env not found. Creating default environment file..."
    @"
API_URL=http://localhost:8000
KEYCLOAK_URL=http://localhost:8080
KEYCLOAK_REALM=neqat-realm
KEYCLOAK_CLIENT_ID=flutter-frontend
"@ | Out-File -FilePath "api.local.env" -Encoding UTF8
}

# Run Flutter app
Write-Host "Starting Flutter app with local environment..."
flutter run --dart-define-from-file=api.local.env 