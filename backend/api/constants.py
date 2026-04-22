"""
Constants related to authentication and Keycloak integration.
This module provides application-wide constants for Keycloak authentication
including token storage keys, role mappings, and user-friendly error messages.
"""

from backend.keycloak_config import KEYCLOAK_TOKEN_KEYS, KEYCLOAK_ROLES

class KeycloakTokenKeys:
    """
    Token storage keys that match the frontend implementation for consistency.
    Uses values from environment variables via keycloak_config.
    """
    ACCESS_TOKEN = KEYCLOAK_TOKEN_KEYS['ACCESS_TOKEN']
    REFRESH_TOKEN = KEYCLOAK_TOKEN_KEYS['REFRESH_TOKEN']
    ID_TOKEN = KEYCLOAK_TOKEN_KEYS['ID_TOKEN']
    TOKEN_EXPIRY = KEYCLOAK_TOKEN_KEYS['TOKEN_EXPIRY']

class KeycloakRoles:
    """
    Standard role definitions used in the application.
    Uses values from environment variables via keycloak_config.
    
    These roles are used for permission checks throughout the application.
    The names should exactly match those defined in Keycloak.
    """
    # Custom application roles 
    ADMIN = KEYCLOAK_ROLES['ADMIN']
    USER = KEYCLOAK_ROLES['USER']
    EDITOR = KEYCLOAK_ROLES['ADMIN']
    
    # Default Keycloak roles
    DEFAULT_ROLE = KEYCLOAK_ROLES['DEFAULT_ROLE']
    OFFLINE_ACCESS = KEYCLOAK_ROLES['OFFLINE_ACCESS']
    UMA_AUTHORIZATION = KEYCLOAK_ROLES['UMA_AUTHORIZATION']
    
    # Account management roles
    MANAGE_ACCOUNT = KEYCLOAK_ROLES['MANAGE_ACCOUNT']
    MANAGE_ACCOUNT_LINKS = KEYCLOAK_ROLES['MANAGE_ACCOUNT_LINKS']
    VIEW_PROFILE = KEYCLOAK_ROLES['VIEW_PROFILE']
    
    # Realm administrator role
    REALM_ADMIN = KEYCLOAK_ROLES['REALM_ADMIN']
    
    @classmethod
    def is_admin(cls, roles):
        """
        Check if the given roles include any admin roles.
        
        Args:
            roles (list): List of roles from the token
            
        Returns:
            bool: True if any admin role is present
        """
        admin_roles = [cls.ADMIN, cls.REALM_ADMIN]
        return any(role in roles for role in admin_roles)
    
    @classmethod
    def is_editor(cls, roles):
        """
        Check if the given roles include editor privileges (now mapped to admin).
        """
        return cls.EDITOR in roles

class KeycloakErrorMessages:
    """
    User-friendly error messages for Keycloak authentication failures.
    These messages are used to provide clear feedback to users.
    """
    # Authentication errors
    INVALID_CREDENTIALS = "Invalid username or password. Please try again."
    ACCOUNT_DISABLED = "Your account has been disabled. Please contact support."
    SESSION_EXPIRED = "Your session has expired. Please log in again."
    
    # Token errors
    TOKEN_EXPIRED = "Your authentication session has expired. Please log in again."
    INVALID_TOKEN = "Invalid authentication token. Please log in again."
    MISSING_TOKEN = "Authentication token is missing. Please log in."
    
    # Permission errors
    INSUFFICIENT_PERMISSIONS = "You don't have permission to access this resource."
    ADMIN_REQUIRED = "This action requires administrator privileges."
    
    # Registration errors
    EMAIL_EXISTS = "An account with this email already exists."
    USERNAME_EXISTS = "This username is already taken. Please choose another."
    WEAK_PASSWORD = "Please use a stronger password. It should be at least 8 characters with mixed case, numbers and symbols."
    
    # Social login errors
    SOCIAL_LOGIN_FAILED = "Social login failed. Please try again or use another method."
    PROVIDER_NOT_CONFIGURED = "This login provider is not configured. Please use another method." 