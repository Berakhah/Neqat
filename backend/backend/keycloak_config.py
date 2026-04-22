"""
Keycloak configuration module for Django settings.
This module loads Keycloak configuration from environment variables.
The values defined here are used throughout the application for consistent
Keycloak integration and token management.
"""

import os

# Keycloak token keys (matching the frontend implementation)
KEYCLOAK_TOKEN_KEYS = {
    'ACCESS_TOKEN': os.getenv('KEYCLOAK_ACCESS_TOKEN_KEY', 'access_token'),
    'REFRESH_TOKEN': os.getenv('KEYCLOAK_REFRESH_TOKEN_KEY', 'refresh_token'),
    'ID_TOKEN': os.getenv('KEYCLOAK_ID_TOKEN_KEY', 'id_token'),
    'TOKEN_EXPIRY': os.getenv('KEYCLOAK_TOKEN_EXPIRY_KEY', 'token_expiry'),
}

# Keycloak roles
# These roles should match exactly what's configured in your Keycloak realm
KEYCLOAK_ROLES = {
    # Custom application roles
    'ADMIN': os.getenv('KEYCLOAK_ROLE_ADMIN', 'admin'),
    'USER': os.getenv('KEYCLOAK_ROLE_USER', 'user'),
    
    # Default Keycloak roles that might be assigned
    'DEFAULT_ROLE': 'default-roles-neqat-realm',
    'OFFLINE_ACCESS': 'offline_access',
    'UMA_AUTHORIZATION': 'uma_authorization',
    
    # Account management roles
    'MANAGE_ACCOUNT': 'manage-account',
    'MANAGE_ACCOUNT_LINKS': 'manage-account-links',
    'VIEW_PROFILE': 'view-profile',
    
    # Realm administrator role
    'REALM_ADMIN': 'realm-admin'
}

# Keycloak server configuration
KEYCLOAK_CONFIG = {
    'KEYCLOAK_SERVER_URL': os.getenv('KEYCLOAK_SERVER_URL', 'https://localhost:8443'),
    'KEYCLOAK_PUBLIC_URL': os.getenv('KEYCLOAK_PUBLIC_URL', 'https://localhost:8443'),
    'KEYCLOAK_REALM': os.getenv('KEYCLOAK_REALM', 'neqat-realm'),
    'KEYCLOAK_CLIENT_ID': os.getenv('KEYCLOAK_CLIENT_ID', 'django-backend'),
    'KEYCLOAK_CLIENT_SECRET': os.getenv('KEYCLOAK_CLIENT_SECRET'),
    'KEYCLOAK_ADMIN_CLIENT_ID': os.getenv('KEYCLOAK_ADMIN_CLIENT_ID', 'admin-cli'),
    'KEYCLOAK_ADMIN_CLIENT_SECRET': os.getenv('KEYCLOAK_ADMIN_CLIENT_SECRET'),
    'KEYCLOAK_REDIRECT_URI': os.getenv('KEYCLOAK_REDIRECT_URI', 'http://localhost:8000/api/auth/callback/'),
}

def get_keycloak_config():
    """
    Returns the Keycloak configuration.
    This function is useful for importing the configuration in other modules.
    
    Returns:
        dict: A dictionary containing token keys, roles, and configuration settings
    """
    return {
        'TOKEN_KEYS': KEYCLOAK_TOKEN_KEYS,
        'ROLES': KEYCLOAK_ROLES,
        'CONFIG': KEYCLOAK_CONFIG,
    } 