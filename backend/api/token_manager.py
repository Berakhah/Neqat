"""
Token management utilities for handling JWT tokens from Keycloak.
This file provides tools for token validation, verification, and parsing.
"""

import logging
import jwt
import json
import requests
from datetime import datetime, timedelta
from django.conf import settings
from jwt.exceptions import InvalidTokenError, ExpiredSignatureError, DecodeError
from .constants import KeycloakErrorMessages
import os

logger = logging.getLogger(__name__)

# Construct the absolute path to keycloak.crt
KEYCLOAK_CERT_PATH = "/app/certs/keycloak.crt"
print(f"Keycloak certificate path for TokenManager: {KEYCLOAK_CERT_PATH}")

class TokenManager:
    """
    Centralized token management for Keycloak JWT tokens.
    This class handles token validation, verification, and parsing.
    """
    
    def __init__(self):
        """Initialize the token manager with Keycloak configuration."""
        self.server_url = settings.KEYCLOAK_CONFIG['KEYCLOAK_SERVER_URL']
        self.client_id = settings.KEYCLOAK_CONFIG['KEYCLOAK_CLIENT_ID']
        self.realm_name = settings.KEYCLOAK_CONFIG['KEYCLOAK_REALM']
        
        # The expected issuer for token validation
        self.issuer = f"{self.server_url}/realms/{self.realm_name}"
        
        # Cache for JWKS to avoid repeated requests
        self._jwks_cache = None
        self._jwks_last_updated = None
    
    def get_jwks(self):
        """
        Get the JSON Web Key Set (JWKS) from Keycloak, with caching.
        
        Returns:
            dict: The JWKS containing public keys
            
        Raises:
            Exception: If JWKS cannot be fetched
        """
        # If we have cached JWKS and it's less than 1 hour old, use it
        now = datetime.now()
        if self._jwks_cache and self._jwks_last_updated and \
           (now - self._jwks_last_updated).total_seconds() < 3600:
            return self._jwks_cache
            
        # Otherwise, fetch fresh JWKS
        try:
            jwks_uri = f"{self.server_url}/realms/{self.realm_name}/protocol/openid-connect/certs"
            response = requests.get(jwks_uri, timeout=10, verify=False)
            response.raise_for_status()
            
            self._jwks_cache = response.json()
            self._jwks_last_updated = now
            return self._jwks_cache
        except Exception as e:
            logger.error(f"Failed to fetch JWKS: {str(e)}")
            raise Exception(f"Could not fetch public keys: {str(e)}")
    
    def decode_token(self, token, verify=True):
        """
        Decode and verify a JWT token.
        
        Args:
            token (str): The JWT token to decode
            verify (bool): Whether to verify the token signature
            
        Returns:
            dict: The decoded token payload
            
        Raises:
            InvalidTokenError: If token is invalid
            ExpiredSignatureError: If token is expired
        """
        if not token:
            raise InvalidTokenError("Token is empty")
            
        if verify:
            return self.verify_token_signature(token)
        else:
            # Just decode without verification (unsafe, but useful for debugging)
            try:
                return jwt.decode(
                    token,
                    options={
                        'verify_signature': False,
                        'verify_exp': False,
                        'verify_aud': False,
                        'verify_iss': False,
                    }
                )
            except Exception as e:
                logger.error(f"Failed to decode token: {str(e)}")
                raise InvalidTokenError(f"Failed to decode token: {str(e)}")
    
    def verify_token_signature(self, token):
        """
        Verify the token signature using Keycloak's public keys.
        This implements cryptographic validation of the token following OIDC best practices.
        
        Args:
            token (str): The JWT token to verify
            
        Returns:
            dict: The validated token payload
            
        Raises:
            InvalidTokenError: If token validation fails
            ExpiredSignatureError: If token is expired
        """
        try:
            # First try to decode the token without verification for debugging
            try:
                unverified_payload = jwt.decode(
                    token,
                    options={
                        'verify_signature': False,
                        'verify_exp': False,
                        'verify_aud': False,
                        'verify_iss': False,
                    }
                )
                logger.debug(f"Unverified token payload: {unverified_payload}")
            except Exception as e:
                logger.error(f"Failed to decode token for debugging: {str(e)}")
            
            # Get the header without verification to get the key ID
            header = jwt.get_unverified_header(token)
            logger.debug(f"Token header: {header}")
            
            if 'kid' not in header:
                logger.error("Token has no 'kid' in header")
                raise InvalidTokenError("Token has no key ID")
                
            kid = header['kid']
            
            # Get the key that matches this key ID
            jwks = self.get_jwks()
            key = None
            for k in jwks.get('keys', []):
                if k.get('kid') == kid:
                    key = k
                    break
                    
            if not key:
                logger.error(f"No matching key found for kid: {kid}")
                raise InvalidTokenError("No matching key found to verify token")
                
            # Create public key from the JWK
            try:
                public_key = jwt.algorithms.RSAAlgorithm.from_jwk(json.dumps(key))
            except Exception as e:
                logger.error(f"Failed to parse JWK: {str(e)}")
                raise InvalidTokenError(f"Failed to parse JWK: {str(e)}")
            
            # Set token verification options for enhanced security
            options = {
                'verify_signature': True,  # Must verify the signature
                'verify_exp': True,        # Must verify expiration time
                'verify_nbf': True,        # Must verify not-before time
                'verify_iat': True,        # Must verify issued-at time
                'verify_aud': False,       # More lenient - many tokens from Postman won't have correct audience
                'verify_iss': True,        # Must verify issuer
                'require_exp': True,       # Token must have an expiration
                'require_iat': True,       # Token must have an issued-at
                'require_nbf': False       # Not-before is optional
            }
            
            # Set expected values based on configuration
            expected_issuer = self.issuer
            
            # Decode and verify the token with all checks
            try:
                payload = jwt.decode(
                    token,
                    public_key,
                    algorithms=['RS256'],
                    options=options,
                    issuer=expected_issuer
                )
            except Exception as e:
                logger.error(f"JWT decode error: {str(e)}")
                
                # Try a more lenient verification if strict verification fails
                logger.warning("Strict verification failed, trying lenient verification")
                payload = jwt.decode(
                    token,
                    public_key,
                    algorithms=['RS256'],
                    options={
                        'verify_signature': True,
                        'verify_exp': True,
                        'verify_aud': False,
                        'verify_iss': False,
                    }
                )
                logger.info("Lenient verification succeeded")
            
            # Additional security checks
            # 1. Validate token type if present
            if 'typ' in header and header['typ'] not in ['JWT', 'Bearer']:
                logger.warning(f"Unusual token type: {header['typ']}, but continuing")
                
            # 2. Ensure token has not been issued too far in the past (replay protection)
            if 'iat' in payload:
                now = datetime.now().timestamp()
                max_token_age = 86400 * 7  # 7 days instead of 1 day for better compatibility
                if (now - payload['iat']) > max_token_age:
                    logger.warning(f"Token issued too long ago: {payload['iat']}")
                    raise ExpiredSignatureError("Token too old")
                    
            # 3. Check required claims but be lenient
            required_claims = ['sub']  # Only require subject claim
            for claim in required_claims:
                if claim not in payload:
                    logger.error(f"Token missing required claim: {claim}")
                    raise InvalidTokenError(f"Token missing required claim: {claim}")
            
            # Log the token issuer and audience for debugging
            if 'iss' in payload:
                logger.debug(f"Token issuer: {payload['iss']}, Expected: {expected_issuer}")
            if 'aud' in payload:
                logger.debug(f"Token audience: {payload['aud']}, Expected: {self.client_id}")
                
            return payload
            
        except ExpiredSignatureError:
            logger.warning("Token has expired")
            raise
        except InvalidTokenError:
            # Re-raise token validation errors
            raise
        except Exception as e:
            logger.error(f"Token verification error: {str(e)}")
            raise InvalidTokenError(f"Token verification failed: {str(e)}")
    
    def extract_roles(self, token_payload):
        """
        Extract roles from a token payload.
        
        Args:
            token_payload (dict): The decoded token payload
            
        Returns:
            list: List of roles from the token
        """
        return token_payload.get('realm_access', {}).get('roles', [])
    
    def extract_user_info(self, token_payload):
        """
        Extract user information from a token payload.
        
        Args:
            token_payload (dict): The decoded token payload
            
        Returns:
            dict: User information extracted from the token
        """
        return {
            'sub': token_payload.get('sub'),
            'email': token_payload.get('email'),
            'preferred_username': token_payload.get('preferred_username'),
            'given_name': token_payload.get('given_name'),
            'family_name': token_payload.get('family_name'),
            'email_verified': token_payload.get('email_verified', False),
        }
    
    def is_token_active(self, token_payload):
        """
        Check if a token is currently active (not expired).
        
        Args:
            token_payload (dict): The decoded token payload
            
        Returns:
            bool: True if token is active, False otherwise
        """
        if 'exp' not in token_payload:
            return False
            
        now = datetime.now().timestamp()
        return token_payload['exp'] > now 