"""
Keycloak service for the backend.
This service handles token management and provides a unified interface
for interacting with Keycloak from Django.
"""
from django.conf import settings
from keycloak import KeycloakOpenID, KeycloakAdmin
from keycloak.exceptions import KeycloakError, KeycloakConnectionError
import logging
from ..constants import KeycloakTokenKeys, KeycloakRoles, KeycloakErrorMessages
from ..models import NeqatUser
from django.contrib.auth import get_user_model
from datetime import datetime, timedelta
import requests
import json
from django.utils import timezone
from django.core.mail import send_mail
from django.template.loader import render_to_string
import os

logger = logging.getLogger(__name__)

# Construct the absolute path to keycloak.crt
KEYCLOAK_CERT_PATH = "/app/certs/keycloak.crt"
print(f"Keycloak certificate path: {KEYCLOAK_CERT_PATH}")

class KeycloakService:
    """
    Service class to handle Keycloak operations.
    This service centralizes all interactions with Keycloak, providing a consistent
    interface for the rest of the application.
    """
    
    def __init__(self):
        """Initialize the Keycloak service with configuration from settings."""
        self.server_url = settings.KEYCLOAK_CONFIG['KEYCLOAK_SERVER_URL']
        self.realm_name = settings.KEYCLOAK_CONFIG['KEYCLOAK_REALM']
        self.client_id = settings.KEYCLOAK_CONFIG['KEYCLOAK_CLIENT_ID']
        self.client_secret = settings.KEYCLOAK_CONFIG['KEYCLOAK_CLIENT_SECRET']
        self.admin_client_id = settings.KEYCLOAK_CONFIG['KEYCLOAK_ADMIN_CLIENT_ID']
        self.admin_client_secret = settings.KEYCLOAK_CONFIG['KEYCLOAK_ADMIN_CLIENT_SECRET']
        
        # Initialize the OpenID client for authentication
        self.keycloak_openid = KeycloakOpenID(
            server_url=self.server_url,
            client_id=self.client_id,
            realm_name=self.realm_name,
            client_secret_key=self.client_secret,
            verify=False
        )
        
        # Admin client for user management is initialized on demand
        self.keycloak_admin = None
        self.admin_initialized = False
    
    def _init_admin_client(self):
        """Initialize the Keycloak admin client for user management operations."""
        if self.admin_initialized:
            return
        
        try:
            # Get admin token
            admin_token = self._get_admin_token()
            
            # Ensure admin_token is properly formatted before proceeding
            if not isinstance(admin_token, dict) or 'access_token' not in admin_token:
                logger.error(f"Invalid admin token format: {admin_token}")
                raise ValueError("Failed to obtain a valid admin token")
            
            # Initialize admin client with the admin token from master realm
            # but target operations to our application realm
            self.keycloak_admin = KeycloakAdmin(
                server_url=self.server_url,
                username='admin',
                password='ChangeMe_Dev123!',
                realm_name=self.realm_name,  # Target realm for operations
                user_realm_name='master',    # Realm for admin authentication
                verify=False
            )
            self.admin_initialized = True
            logger.info(f"Keycloak admin client initialized successfully for realm {self.realm_name}")
        except KeycloakConnectionError as e:
            logger.error(f"Failed to connect to Keycloak server: {e}")
            raise ConnectionError(f"Cannot connect to Keycloak server: {str(e)}")
        except Exception as e:
            logger.error(f"Failed to initialize Keycloak admin client: {e}")
            raise
    
    def _get_admin_token(self):
        """Get an admin token for Keycloak administration operations using admin credentials."""
        try:
            # Use direct admin authentication to the master realm
            token_endpoint = f"{self.server_url}/realms/master/protocol/openid-connect/token"
            
            headers = {
                'Content-Type': 'application/x-www-form-urlencoded',
            }
            
            # Use admin credentials instead of client credentials
            # This uses the admin/password provided when launching Keycloak
            payload = {
                'grant_type': 'password',
                'client_id': 'admin-cli',  # admin-cli client is always available in master realm
                'username': 'admin',       # Admin username from KEYCLOAK_ADMIN env variable
                'password': 'ChangeMe_Dev123!',   # Admin password from KEYCLOAK_ADMIN_PASSWORD env variable
            }
            
            logger.info(f"Requesting admin token from {token_endpoint} using admin credentials")
            
            response = requests.post(token_endpoint, headers=headers, data=payload, verify=False)
            
            if response.status_code == 200:
                token_data = response.json()
                
                # Validate the token structure before returning
                if not isinstance(token_data, dict):
                    logger.error(f"Invalid token response type: {type(token_data)}")
                    raise KeycloakError("Invalid token response format")
                
                # Check for required fields
                if 'access_token' not in token_data:
                    logger.error("Token response missing 'access_token'")
                    raise KeycloakError("Token response missing required fields")
                
                logger.info("Successfully obtained admin token")
                return token_data
            else:
                logger.error(f"Failed to get admin token: {response.status_code}: {response.content}")
                raise KeycloakError(f"{response.status_code}: {response.content}")
        except KeycloakConnectionError as e:
            logger.error(f"Failed to connect to Keycloak server: {e}")
            raise ConnectionError(f"Cannot connect to Keycloak server: {str(e)}")
        except Exception as e:
            logger.error(f"Failed to get admin token: {e}")
            raise
    
    def authenticate_user(self, username, password):
        """
        Authenticate a user with username and password.
        
        Args:
            username (str): Username or email
            password (str): User's password
            
        Returns:
            dict: Token response with user info
            
        Raises:
            AuthenticationError: If authentication fails
        """
        try:
            token_response = self.keycloak_openid.token(username, password)
            userinfo = self.keycloak_openid.userinfo(token_response['access_token'])
            token_info = self.keycloak_openid.introspect(token_response['access_token'])
            
            roles = token_info.get('realm_access', {}).get('roles', [])
            is_admin = KeycloakRoles.is_admin(roles)
            
            # Return with both naming conventions for compatibility
            return {
                'access': token_response['access_token'],
                'access_token': token_response['access_token'], 
                'refresh': token_response['refresh_token'],
                'refresh_token': token_response['refresh_token'],
                'user': {
                    'email': userinfo.get('email'),
                    'username': userinfo.get('preferred_username'),
                    'first_name': userinfo.get('given_name', ''),
                    'last_name': userinfo.get('family_name', ''),
                    'is_superuser': is_admin,
                    'keycloak_id': token_info.get('sub')  # Add Keycloak user ID
                },
                'expires_at': token_info.get('exp'),
                'expires_in': token_response.get('expires_in', 300),
            }
        except KeycloakConnectionError as e:
            logger.error(f"Authentication failed - connection error: {e}")
            raise ConnectionError("Unable to connect to authentication server. Please try again later.")
        except KeycloakError as e:
            error_message = str(e)
            logger.error(f"Keycloak authentication error: {error_message}")
            
            if "invalid_grant" in error_message and "Invalid user credentials" in error_message:
                raise ValueError(KeycloakErrorMessages.INVALID_CREDENTIALS)
            elif "user is disabled" in error_message.lower():
                raise ValueError(KeycloakErrorMessages.ACCOUNT_DISABLED)
            else:
                raise ValueError(f"Authentication failed: {error_message}")
        except Exception as e:
            logger.error(f"Authentication failed: {e}")
            raise ValueError("Authentication failed. Please try again.")
    
    def validate_token(self, token):
        """
        Validate a token and return the user info.
        
        Args:
            token (str): Access token to validate
            
        Returns:
            tuple: (userinfo, token_info) if valid, (None, None) if invalid
        """
        try:
            userinfo = self.keycloak_openid.userinfo(token)
            token_info = self.keycloak_openid.introspect(token)
            
            # Check if token is active
            if not token_info.get('active', False):
                logger.warning("Token is not active")
                return None, None
                
            return userinfo, token_info
        except KeycloakConnectionError as e:
            logger.error(f"Token validation failed - connection error: {e}")
            return None, None
        except Exception as e:
            logger.error(f"Token validation failed: {e}")
            return None, None
    
    def refresh_token(self, refresh_token):
        """
        Refresh a token using the refresh token.
        
        Args:
            refresh_token (str): The refresh token
            
        Returns:
            dict: New token response with consistent field names
            
        Raises:
            ValueError: If refresh token is invalid or expired
            ConnectionError: If can't connect to Keycloak
        """
        try:
            token_response = self.keycloak_openid.refresh_token(refresh_token)
            
            # Ensure we have a consistent response format regardless of Keycloak version
            normalized_response = {
                # Ensure both old (access/refresh) and new (access_token/refresh_token) formats
                'access': token_response.get('access_token', token_response.get('access', '')),
                'access_token': token_response.get('access_token', token_response.get('access', '')),
                'refresh': token_response.get('refresh_token', token_response.get('refresh', refresh_token)),
                'refresh_token': token_response.get('refresh_token', token_response.get('refresh', refresh_token)),
                'expires_in': token_response.get('expires_in', 300),
                'token_type': token_response.get('token_type', 'Bearer'),
                'id_token': token_response.get('id_token', ''),
                'session_state': token_response.get('session_state', ''),
                'scope': token_response.get('scope', 'openid')
            }
            
            return normalized_response
            
        except KeycloakConnectionError as e:
            logger.error(f"Token refresh failed - connection error: {e}")
            raise ConnectionError("Unable to connect to authentication server. Please try again later.")
        except KeycloakError as e:
            error_message = str(e)
            logger.error(f"Token refresh error: {error_message}")
            
            if "invalid_grant" in error_message:
                if "Invalid refresh token" in error_message:
                    raise ValueError(KeycloakErrorMessages.SESSION_EXPIRED)
                elif "Token is not active" in error_message:
                    raise ValueError(KeycloakErrorMessages.TOKEN_EXPIRED)
                elif "Refresh token expired" in error_message:
                    raise ValueError(KeycloakErrorMessages.SESSION_EXPIRED)
            
            raise ValueError(KeycloakErrorMessages.INVALID_TOKEN)
        except Exception as e:
            logger.error(f"Token refresh failed: {e}")
            raise ValueError("Failed to refresh your session. Please log in again.")
    
    def logout(self, refresh_token):
        """
        Log out a user by invalidating their refresh token.
        
        Args:
            refresh_token (str): The refresh token to invalidate
            
        Returns:
            bool: True if logout was successful, False otherwise
        """
        try:
            self.keycloak_openid.logout(refresh_token)
            return True
        except KeycloakConnectionError as e:
            logger.error(f"Logout failed - connection error: {e}")
            return False
        except Exception as e:
            logger.error(f"Logout failed: {e}")
            return False
    
    def get_roles_from_token(self, token_info):
        """
        Extract roles from token info.
        
        Args:
            token_info (dict): Token information from introspection
            
        Returns:
            list: List of roles
        """
        return token_info.get('realm_access', {}).get('roles', [])
    
    def get_or_create_django_user(self, user_info):
        """Get or create a Django user from Keycloak user info."""
        try:
            # Check if user exists by Keycloak ID
            keycloak_id = user_info.get('keycloak_id')
            if not keycloak_id:
                logger.error("No Keycloak ID provided in user_info")
                raise ValueError("No Keycloak ID provided in user_info")
            
            User = get_user_model()
            
            try:
                # Try to find by Keycloak ID first
                user = User.objects.get(keycloak_id=keycloak_id)
                created = False
                
                # Update user fields if needed
                user.email = user_info.get('email', user.email)
                user.user_name = user_info.get('username', user.user_name)
                user.first_name = user_info.get('first_name', user.first_name)
                user.last_name = user_info.get('last_name', user.last_name)
                user.is_superuser = user_info.get('is_superuser', user.is_superuser)
                user.is_staff = user_info.get('is_superuser', user.is_staff)
                user.is_active = True
                user.save()
                
            except User.DoesNotExist:
                # Try finding by email as a fallback
                email = user_info.get('email')
                if not email:
                    logger.error("No email provided in user_info")
                    raise ValueError("No email provided in user_info")
                
                try:
                    user = User.objects.get(email=email)
                    created = False
                    
                    # Update with Keycloak ID
                    user.keycloak_id = keycloak_id
                    user.user_name = user_info.get('username', user.user_name)
                    user.first_name = user_info.get('first_name', user.first_name)
                    user.last_name = user_info.get('last_name', user.last_name)
                    user.is_superuser = user_info.get('is_superuser', user.is_superuser)
                    user.is_staff = user_info.get('is_superuser', user.is_staff)
                    user.is_active = True
                    user.save()
                    
                except User.DoesNotExist:
                    # Create new user
                    user = User.objects.create(
                        keycloak_id=keycloak_id,
                        email=email,
                        user_name=user_info.get('username', email),
                        first_name=user_info.get('first_name', ''),
                        last_name=user_info.get('last_name', ''),
                        is_superuser=user_info.get('is_superuser', False),
                        is_staff=user_info.get('is_superuser', False),
                        is_active=True
                    )
                    created = True
            
            return user, created
            
        except Exception as e:
            logger.error(f"Error in get_or_create_django_user: {e}")
            raise e
    
    def create_user(self, username, email, first_name, last_name, password, enabled=True):
        """
        Create a new user in Keycloak with secure defaults.
        
        This method handles creating users with proper configuration to ensure they can
        authenticate securely while following Keycloak's requirements.
        """
        try:
            if not self.admin_initialized:
                logger.info("Initializing admin client before user creation")
                self._init_admin_client()
                
            # Check if user already exists
            existing_user = self.find_user_by_email(email)
            if existing_user:
                logger.warning(f"User with email {email} already exists")
                raise ValueError(f"User with email {email} already exists")
                
            # Create user data with proper string values
            # Set emailVerified=False to enable email verification flow
            user_data = {
                'username': str(username),
                'email': str(email),
                'firstName': str(first_name) if first_name else "",
                'lastName': str(last_name) if last_name else "",
                'enabled': enabled,
                'emailVerified': False,
                'credentials': [{
                    'type': 'password',
                    'value': str(password),
                    'temporary': False
                }],
                'requiredActions': ['VERIFY_EMAIL']  # Add email verification required action
            }
            
            logger.info(f"Creating user in Keycloak: {email}")
            
            # Create the user and handle potential errors
            try:
                # Capture the user ID response
                user_id = self.keycloak_admin.create_user(user_data)
                
                # Validate user_id to ensure it's a proper string
                if not user_id or not isinstance(user_id, str):
                    logger.error(f"Invalid user ID returned: {user_id}")
                    raise ValueError("User creation failed - invalid user ID returned")
                
                logger.info(f"User created successfully in Keycloak: {email} with ID: {user_id}")
                
                # Ensure user has the necessary roles and groups
                # This helps ensure proper access and permissions
                self._assign_default_roles_and_groups(user_id)
                
                # Update the user to clear any required actions that might have been added
                # by realm default policies
                try:
                    # Get the current user configuration 
                    user_info = self.keycloak_admin.get_user(user_id)
                    
                    # If there are required actions, clear them
                    if user_info.get('requiredActions') and len(user_info.get('requiredActions')) > 0:
                        logger.info(f"Clearing required actions for user: {user_id}")
                        self.keycloak_admin.update_user(user_id, {
                            'requiredActions': [],
                            'emailVerified': True
                        })
                except Exception as update_error:
                    logger.warning(f"Failed to update user required actions: {update_error}")
                    # Continue despite this error - the user was still created
                
                return user_id
            except TypeError as e:
                if "string indices must be integers" in str(e):
                    logger.error(f"TypeError during user creation (likely server config issue): {e}")
                    logger.error("This is often caused by invalid token or incorrect Keycloak configuration")
                    raise ValueError("Registration failed due to server configuration issue. Please try again later.")
                else:
                    raise
                    
        except Exception as e:
            logger.error(f"User creation failed: {e}")
            raise e
    
    def _assign_default_roles_and_groups(self, user_id):
        """
        Assign default roles and groups to a newly created user.
        
        Args:
            user_id (str): The ID of the user in Keycloak
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            # Assign the basic user role
            role_name = KeycloakRoles.USER
            group_name = 'Users'
            
            # Get realm role
            try:
                role = self.keycloak_admin.get_realm_role(role_name)
                if not role:
                    logger.warning(f"Role {role_name} not found, skipping role assignment")
                else:
                    # Assign role to user
                    self.keycloak_admin.assign_realm_roles(user_id, [role])
                    logger.info(f"Assigned role {role_name} to user {user_id}")
            except Exception as role_error:
                logger.error(f"Failed to assign role {role_name}: {role_error}")
                # Continue despite role assignment failure
            
            # Find group by name
            try:
                groups = self.keycloak_admin.get_groups()
                
                # Verify groups is a list before proceeding
                if not isinstance(groups, list):
                    logger.error(f"Unexpected groups response: {groups}")
                    return False
                    
                group = next((g for g in groups if g.get('name') == group_name), None)
                
                if not group:
                    logger.warning(f"Group {group_name} not found, skipping group assignment")
                else:
                    # Add user to group
                    self.keycloak_admin.group_user_add(user_id, group['id'])
                    logger.info(f"Added user {user_id} to group {group_name}")
            except Exception as group_error:
                logger.error(f"Failed to add user to group {group_name}: {group_error}")
                # Continue despite group assignment failure
            
            return True
        except Exception as e:
            logger.error(f"Role and group assignment failed: {e}")
            return False
    
    def reset_password(self, user_id, password, temporary=False):
        """Reset a user's password."""
        try:
            if not self.admin_initialized:
                self._init_admin_client()
                
            self.keycloak_admin.set_user_password(user_id, password, temporary=temporary)
            return True
        except Exception as e:
            logger.error(f"Password reset failed: {e}")
            return False
    
    def request_password_reset(self, email):
        """
        Requests a password reset for the given email using Keycloak's built-in functionality.
        This will send a password reset email through Keycloak's email service.
        """
        try:
            # Initialize admin client if not already done
            if not self.admin_initialized:
                self._init_admin_client()
                
            # Find the user in Keycloak by email
            keycloak_user = self.find_user_by_email(email)
            if not keycloak_user:
                # For security reasons, don't reveal if the user exists or not
                logger.info(f"Password reset requested for non-existent email: {email}")
                return True
            
            user_id = keycloak_user['id']
            
            # Use Keycloak's built-in password reset functionality
            # Use a redirect URI that's correctly registered in Keycloak
            redirect_uri = "http://localhost:8000/reset-password"
            client_id = self.client_id
            
            # Send the password reset email through Keycloak
            try:
                self.keycloak_admin.send_update_account(
                    user_id=user_id,
                    payload=["UPDATE_PASSWORD"],
                    client_id=client_id,
                    redirect_uri=redirect_uri
                )
                logger.info(f"Keycloak password reset email sent to: {email}")
                return True
            except Exception as e:
                logger.error(f"Failed to send Keycloak password reset email: {str(e)}")
                
                # Fallback to old method if Keycloak email fails
                logger.info(f"Falling back to custom password reset for: {email}")
                return self._legacy_password_reset(email)
                
        except Exception as e:
            logger.error(f"Failed to process password reset request: {str(e)}")
            raise Exception(f"Failed to process password reset request: {str(e)}")
    
    def _legacy_password_reset(self, email):
        """
        Legacy password reset method using our own token system.
        Only used as fallback when Keycloak's built-in reset fails.
        """
        try:
            from django.utils import timezone
            from datetime import timedelta
            from django.conf import settings
            from django.core.mail import send_mail
            from django.template.loader import render_to_string
            from ..models import NeqatUser, PasswordResetToken
            
            # Find the user by email
            try:
                user = NeqatUser.objects.get(email=email)
            except NeqatUser.DoesNotExist:
                # For security reasons, don't reveal if the user exists or not
                logger.info(f"Password reset requested for non-existent email: {email}")
                return True
                
            # Invalidate any existing tokens for this user
            PasswordResetToken.objects.filter(user=user).update(is_used=True, used_at=timezone.now())
                
            # Generate a new token
            token = PasswordResetToken.objects.create(
                user=user,
                expires_at=timezone.now() + timedelta(hours=1)
            )
            
            # Create a context for the email template
            context = {
                'reset_url': f"{settings.FRONTEND_URL}/reset-password?token={token.token}",
                'code': token.token,
                'user': user,
                'expiry_time': '1 hour'
            }
            
            # Send the email with the token
            subject = "Reset your Neqat password"
            html_message = render_to_string('reset_password_email.html', context)
            
            plain_message = f"""
            Hello {user.user_name},
            
            You've requested to reset your password. Please use the following code to reset your password:
            
            {token.token}
            
            This code will expire in 1 hour.
            
            If you didn't request this, please ignore this email.
            
            Regards,
            The Neqat Team
            """
            
            send_mail(
                subject=subject,
                message=plain_message,
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[user.email],
                html_message=html_message,
                fail_silently=False,
            )
            
            logger.info(f"Legacy password reset email sent to: {email}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to send legacy password reset email: {str(e)}")
            raise Exception(f"Failed to send legacy password reset email: {str(e)}")
    
    def find_user_by_email(self, email):
        """Find a user by email."""
        try:
            if not self.admin_initialized:
                self._init_admin_client()
            
            try:
                users = self.keycloak_admin.get_users({'email': email})
                return users[0] if users else None
            except (IndexError, TypeError) as e:
                # Handle the case where the response is not properly formatted
                logger.error(f"Error parsing user search results: {e}")
                return None
                
        except Exception as e:
            logger.error(f"User search failed: {e}")
            return None
    
    def get_user_by_id(self, user_id):
        """Get a user by ID."""
        try:
            if not self.admin_initialized:
                self._init_admin_client()
                
            return self.keycloak_admin.get_user(user_id)
        except Exception as e:
            logger.error(f"Get user failed: {e}")
            return None
    
    def update_user(self, user_id, user_data):
        """Update a user's information."""
        try:
            if not self.admin_initialized:
                self._init_admin_client()
                
            self.keycloak_admin.update_user(user_id, user_data)
            return True
        except Exception as e:
            logger.error(f"User update failed: {e}")
            return False
    
    def assign_user_role_and_group(self, user_id, role_name, group_name):
        """Assign a role to a user and add them to a group."""
        try:
            if not self.admin_initialized:
                self._init_admin_client()
            
            # Get realm role
            try:
                role = self.keycloak_admin.get_realm_role(role_name)
                if not role:
                    logger.warning(f"Role {role_name} not found, skipping role assignment")
                else:
                    # Assign role to user
                    self.keycloak_admin.assign_realm_roles(user_id, [role])
                    logger.info(f"Assigned role {role_name} to user {user_id}")
            except Exception as role_error:
                logger.error(f"Failed to assign role {role_name}: {role_error}")
                # Continue despite role assignment failure
            
            # Find group by name
            try:
                groups = self.keycloak_admin.get_groups()
                
                # Verify groups is a list before proceeding
                if not isinstance(groups, list):
                    logger.error(f"Unexpected groups response: {groups}")
                    raise ValueError("Invalid groups response from Keycloak")
                    
                group = next((g for g in groups if g.get('name') == group_name), None)
                
                if not group:
                    logger.warning(f"Group {group_name} not found, skipping group assignment")
                else:
                    # Add user to group
                    self.keycloak_admin.group_user_add(user_id, group['id'])
                    logger.info(f"Added user {user_id} to group {group_name}")
            except Exception as group_error:
                logger.error(f"Failed to add user to group {group_name}: {group_error}")
                # Continue despite group assignment failure
            
            return True
        except Exception as e:
            logger.error(f"Role and group assignment failed: {e}")
            # Don't raise the exception, just log it and return False
            return False
    
    def exchange_social_token(self, provider, token):
        """
        Exchange a social provider token for Keycloak tokens.
        Implements secure token exchange between social providers and Keycloak.
        
        Args:
            provider (str): The social provider name (google, facebook, github, etc.)
            token (str): The access token from the social provider
            
        Returns:
            dict: Keycloak token response containing access_token, refresh_token, etc.
            
        Raises:
            ValueError: If provider is not supported or token is invalid
            ConnectionError: If unable to connect to Keycloak
        """
        try:
            # Validate inputs
            if not token or len(token.strip()) == 0:
                logger.error("Empty token provided for social login")
                raise ValueError("Invalid social token: Token cannot be empty")
                
            if not provider or len(provider.strip()) == 0:
                logger.error("Empty provider name for social login")
                raise ValueError("Invalid provider: Provider name cannot be empty")
            
            # Normalize provider name
            provider = provider.lower().strip()
            
            # Verify the provider is supported
            supported_providers = ['google', 'facebook', 'apple', 'github', 'twitter']
            if provider not in supported_providers:
                logger.error(f"Unsupported provider: {provider}")
                raise ValueError(f"Unsupported social provider: {provider}")
                
            # Ensure admin client is initialized
            self._init_admin_client()
            
            # Get identity providers from Keycloak to verify the provider is configured
            try:
                idps = self.keycloak_admin.get_identity_providers()
                provider_exists = any(idp['providerId'].lower() == provider for idp in idps)
                
                if not provider_exists:
                    logger.error(f"Provider {provider} is not configured in Keycloak")
                    raise ValueError(f"Social provider {provider} is not configured")
            except Exception as e:
                logger.error(f"Error checking identity providers: {e}")
                # Continue anyway, as token exchange might still work
            
            # Perform token exchange with Keycloak
            try:
                token_response = self.keycloak_openid.token(
                    grant_type="urn:ietf:params:oauth:grant-type:token-exchange",
                    subject_token=token,
                    subject_issuer=provider,
                    client_id=self.client_id,
                    client_secret=self.client_secret,
                )
                
                logger.info(f"Successfully exchanged {provider} token for Keycloak token")
                return token_response
                
            except KeycloakConnectionError as e:
                logger.error(f"Failed to connect to Keycloak for token exchange: {e}")
                raise ConnectionError(f"Unable to connect to authentication server: {str(e)}")
                
            except KeycloakError as e:
                error_message = str(e)
                logger.error(f"Keycloak token exchange error: {error_message}")
                
                if "invalid_grant" in error_message:
                    raise ValueError(KeycloakErrorMessages.SOCIAL_LOGIN_FAILED)
                elif "invalid_client" in error_message:
                    raise ValueError("Invalid client configuration. Please contact support.")
                else:
                    raise ValueError(f"Social login failed: {error_message}")
                    
        except ConnectionError:
            # Re-raise connection errors 
            raise
        except ValueError:
            # Re-raise validation errors
            raise
        except Exception as e:
            logger.error(f"Failed to exchange social token: {e}")
            raise ValueError(KeycloakErrorMessages.SOCIAL_LOGIN_FAILED)
    
    def get_social_auth_url(self, provider):
        """
        Get the authorization URL for a social provider.
        Args:
            provider (str): The social provider name (google, facebook, github, etc.)
        Returns:
            str: The authorization URL to redirect the user to
        """
        try:
            provider_alias = provider.lower().strip()
            # Use the public URL for browser redirects
            public_url = settings.KEYCLOAK_CONFIG.get('KEYCLOAK_PUBLIC_URL', self.server_url)
            auth_base_url = f"{public_url}/realms/{self.realm_name}/protocol/openid-connect/auth"
            params = {
                'client_id': self.client_id,
                'redirect_uri': settings.KEYCLOAK_CONFIG['KEYCLOAK_REDIRECT_URI'],
                'response_type': 'code',
                'scope': 'openid email profile',
                'kc_idp_hint': provider_alias
            }
            auth_url = f"{auth_base_url}?{'&'.join([f'{k}={v}' for k, v in params.items()])}"
            logger.info(f"Generated social auth URL for provider {provider}")
            return auth_url
        except Exception as e:
            logger.error(f"Failed to get social auth URL: {e}")
            raise Exception(f"Failed to generate authorization URL for {provider}: {str(e)}")
    
    def get_user_info(self, access_token):
        """
        Get user information from Keycloak using an access token.
        
        Args:
            access_token (str): Keycloak access token
            
        Returns:
            dict: User information from Keycloak
        """
        try:
            userinfo = self.keycloak_openid.userinfo(access_token)
            return userinfo
        except Exception as e:
            logger.error(f"Failed to get user info: {e}")
            raise Exception(f"Failed to get user information: {str(e)}")
            
    def process_auth_code(self, code, redirect_uri):
        """
        Process an authorization code to obtain tokens.
        Used in the OAuth2 flow after social login redirect.
        
        Args:
            code (str): The authorization code from the callback
            redirect_uri (str): The redirect URI used in the initial request
            
        Returns:
            dict: Keycloak token response containing access_token, refresh_token, etc.
        """
        try:
            # Exchange the code for tokens
            token_response = self.keycloak_openid.token(
                grant_type='authorization_code',
                code=code,
                redirect_uri=redirect_uri
            )
            
            logger.info("Successfully exchanged authorization code for tokens")
            return token_response
        except Exception as e:
            logger.error(f"Failed to process authorization code: {e}")
            raise Exception(f"Failed to exchange authorization code: {str(e)}")
    
    def send_verification_email(self, user_id):
        """
        Sends an email verification to the user
        
        Args:
            user_id (str): The Keycloak user ID
            
        Returns:
            bool: True if the email was sent successfully, False otherwise
        """
        try:
            if not self.admin_initialized:
                self._init_admin_client()
                
            # Send verification email using Keycloak's built-in functionality
            self.keycloak_admin.send_verify_email(
                user_id=user_id,
                client_id=self.client_id,
                redirect_uri=f"{settings.FRONTEND_URL}/verify-email"
            )
            
            logger.info(f"Verification email sent to user {user_id}")
            return True
        except Exception as e:
            logger.error(f"Failed to send verification email: {e}")
            return False 