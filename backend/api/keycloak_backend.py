from django.contrib.auth import get_user_model
from django.conf import settings
from keycloak import KeycloakOpenID, KeycloakGetError
from rest_framework import authentication
from rest_framework.exceptions import AuthenticationFailed
from django.core.cache import cache
import hashlib
import logging
import jwt
import json
import requests
from urllib.parse import urljoin
from jwt.exceptions import InvalidTokenError, ExpiredSignatureError, DecodeError
from .constants import KeycloakTokenKeys, KeycloakRoles, KeycloakErrorMessages
from datetime import datetime, timedelta
from .services.keycloak_service import KeycloakService
from .token_manager import TokenManager

logger = logging.getLogger(__name__)

class KeycloakAuthentication(authentication.BaseAuthentication):
    def __init__(self):
        self.server_url = settings.KEYCLOAK_CONFIG['KEYCLOAK_SERVER_URL']
        self.client_id = settings.KEYCLOAK_CONFIG['KEYCLOAK_CLIENT_ID']
        self.realm_name = settings.KEYCLOAK_CONFIG['KEYCLOAK_REALM']
        self.client_secret = settings.KEYCLOAK_CONFIG['KEYCLOAK_CLIENT_SECRET']
        
        self.issuer = f"{self.server_url}/realms/{self.realm_name}"
        
        # Initialize Keycloak OpenID client
        try:
            self.keycloak_openid = KeycloakOpenID(
                server_url=self.server_url,
                client_id=self.client_id,
                realm_name=self.realm_name,
                client_secret_key=self.client_secret
            )
            self.keycloak_service = KeycloakService()
            
            # Initialize the token manager for token validation
            self.token_manager = TokenManager()
            
        except Exception as e:
            logger.error(f"Failed to initialize Keycloak client: {str(e)}")
            # Don't raise here, to allow app to start even if Keycloak is temporarily down
            # Authentication will fail at runtime if Keycloak remains unavailable

    def authenticate(self, request):
        auth_header = request.META.get('HTTP_AUTHORIZATION')
        if not auth_header:
            return None

        try:
            token_parts = auth_header.split(' ')
            if len(token_parts) != 2 or token_parts[0].lower() != 'bearer':
                logger.warning("Invalid authorization header format")
                raise AuthenticationFailed(KeycloakErrorMessages.INVALID_TOKEN)
                
            token = token_parts[1]
            
            # Log token length for debugging (don't log the actual token)
            logger.debug(f"Received token of length: {len(token)}")
            
            # Store the token in the request object for other components
            # This is essential for permission classes to access the token
            self.credentials = token
            
            # Hash the token for a safe cache key that won't exceed length limits
            token_hash = hashlib.md5(token.encode()).hexdigest()
            cache_key = f'keycloak_user_{token_hash}'
            
            # Check cache first
            cached_user = cache.get(cache_key)
            if cached_user:
                logger.debug("Using cached authentication result")
                return cached_user

            # First verify the token signature and claims using TokenManager
            try:
                # Verify token signature and basic claims
                logger.debug("Verifying token signature and claims")
                token_payload = self.token_manager.verify_token_signature(token)
                
                # Extract Keycloak user ID from token
                keycloak_id = token_payload.get('sub')
                if not keycloak_id:
                    logger.error("No subject claim in token")
                    raise AuthenticationFailed(KeycloakErrorMessages.INVALID_TOKEN)
                
                logger.debug(f"Token verified for subject: {keycloak_id}")
                    
            except ExpiredSignatureError:
                logger.warning("Token has expired")
                raise AuthenticationFailed(KeycloakErrorMessages.TOKEN_EXPIRED)
            except InvalidTokenError as e:
                logger.error(f"Invalid token: {str(e)}")
                raise AuthenticationFailed(KeycloakErrorMessages.INVALID_TOKEN)
            except Exception as e:
                logger.error(f"Token validation error: {str(e)}")
                raise AuthenticationFailed(KeycloakErrorMessages.INVALID_TOKEN)
                
            # Get additional user info
            userinfo = {}
            try:
                logger.debug("Attempting to get user info from Keycloak")
                userinfo = self.keycloak_openid.userinfo(token)
                logger.debug(f"Successfully retrieved user info: {userinfo.get('preferred_username')}")
            except KeycloakGetError as e:
                logger.warning(f"Failed to get user info from Keycloak: {str(e)}")
                
                # If userinfo endpoint fails but token verification passed,
                # extract basic info from token
                logger.debug("Extracting user info from token payload")
                userinfo = self.token_manager.extract_user_info(token_payload)
            except Exception as e:
                logger.error(f"Failed to get user info: {str(e)}")
                # Don't fail here - use the token payload info
                logger.debug("Using token payload for basic user info")
                userinfo = self.token_manager.extract_user_info(token_payload)
                
            # Get the realm roles from the token
            realm_roles = self.token_manager.extract_roles(token_payload)
            logger.debug(f"Extracted roles: {realm_roles}")
            
            # Map Keycloak roles to application roles
            is_admin = KeycloakRoles.is_admin(realm_roles)
            
            # Extract user info
            keycloak_user_info = {
                'keycloak_id': keycloak_id,
                'email': userinfo.get('email', f"{keycloak_id}@example.com"),  # Fallback for direct tokens
                'username': userinfo.get('preferred_username', keycloak_id),  # Fallback for direct tokens
                'first_name': userinfo.get('given_name', ''),
                'last_name': userinfo.get('family_name', ''),
                'is_superuser': is_admin,
                'is_staff': is_admin
            }
            
            logger.debug(f"Creating/fetching user with: {keycloak_user_info['username']}")
            
            # Use the keycloak service to get or create the user
            user, created = self.keycloak_service.get_or_create_django_user(keycloak_user_info)
            # Attach roles to the user object for permission checks
            user.roles = realm_roles
            if created:
                logger.info(f"Created new user: {user.user_name}")
            else:
                logger.debug(f"Using existing user: {user.user_name}")
            
            # Store token expiration in user session if available
            if hasattr(request, 'session') and 'exp' in token_payload:
                request.session[KeycloakTokenKeys.TOKEN_EXPIRY] = token_payload['exp']

            # Cache the result - use a shorter timeout than the token expiry
            token_expiry = token_payload.get('exp', 0)
            now = datetime.now().timestamp()
            cache_timeout = min(300, max(1, int(token_expiry - now - 30)))  # 30 seconds buffer, at least 1 second
            
            cache.set(cache_key, (user, token), timeout=cache_timeout)
            logger.debug(f"Authentication successful for user: {user.user_name}")

            return (user, token)

        except AuthenticationFailed:
            # Re-raise the already formatted authentication failure
            raise
        except Exception as e:
            logger.error(f"Authentication error: {str(e)}")
            raise AuthenticationFailed(KeycloakErrorMessages.INVALID_TOKEN)
            
    def refresh_token(self, refresh_token):
        """
        Refresh an access token using the refresh token
        """
        try:
            token_response = self.keycloak_openid.refresh_token(refresh_token)
            return token_response
        except KeycloakGetError as e:
            logger.error(f"Token refresh error from Keycloak: {str(e)}")
            if 'invalid_grant' in str(e).lower():
                raise AuthenticationFailed(KeycloakErrorMessages.SESSION_EXPIRED)
            return None
        except Exception as e:
            logger.error(f"Token refresh error: {str(e)}")
            return None

    def authenticate_header(self, request):
        return 'Bearer'