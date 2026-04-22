from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, viewsets, filters, permissions
from rest_framework.permissions import IsAuthenticated, IsAdminUser, AllowAny
from rest_framework.decorators import action
from social_django.utils import load_strategy
from social_core.backends.google import GoogleOAuth2
from social_core.backends.facebook import FacebookOAuth2
from social_core.backends.apple import AppleIdAuth
from social_core.exceptions import AuthException
from django.core.exceptions import ObjectDoesNotExist
from django.core.mail import send_mail
from django.conf import settings
from django.db.models import Count, Q
from django.utils import timezone
from django.contrib.auth import authenticate
from datetime import timedelta
import json
from .models import (
    NeqatUser, PasswordResetToken, SystemLog, UserActivity, 
    AdminSettings, Notification, Post, Comment, ContentFlag, Tag, UserPreference, News, UserContentInteraction,
    TelegramMessage, ModerationHistory,
)
from .serializers import (
    NeqatUserSerializer, SocialLoginSerializer, ForgotPasswordSerializer, 
    ResetPasswordSerializer, SystemLogSerializer, UserActivitySerializer,
    AdminSettingsSerializer, NotificationSerializer, PostSerializer, 
    CommentSerializer, ContentFlagSerializer, AdminPostSerializer,
    AdminCommentSerializer, TagSerializer, UserPreferenceSerializer,
    UserPreferenceUpdateSerializer, NewsSerializer, UserContentInteractionSerializer,
    TelegramMessageSerializer, ModerationHistorySerializer,
)
from rest_framework import serializers
import uuid
from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticatedOrReadOnly, AllowAny
from django_ratelimit.decorators import ratelimit
from django.db import transaction
from keycloak import KeycloakOpenID
from .keycloak_backend import KeycloakAuthentication
from .services import KeycloakService
from .constants import KeycloakTokenKeys, KeycloakRoles, KeycloakErrorMessages
import logging
import time
from django.urls import reverse
from django.http import HttpResponseRedirect
from .token_manager import TokenManager
import jwt
import requests
from django.http import HttpResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from .permissions import IsAdmin, IsEditor, HasKeycloakRole, IsOwnerOrAdmin
from rest_framework.views import exception_handler
from api.utils import log_permission_denial, log_admin_action
from rest_framework.throttling import ScopedRateThrottle
from rest_framework import mixins
from django.forms.models import model_to_dict
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer

logger = logging.getLogger(__name__)

# Custom Keycloak token refresh view
class KeycloakTokenRefreshView(APIView):
    permission_classes = [AllowAny]
    
    def post(self, request):
        refresh_token = request.data.get('refresh_token')
        
        if not refresh_token:
            log_auth_event(request, 'TOKEN_REFRESH_FAILED', 'No refresh token provided')
            return Response({'error': 'Refresh token is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            # Use the Keycloak service to refresh the token
            keycloak_service = KeycloakService()
            new_tokens = keycloak_service.refresh_token(refresh_token)
            
            # Return response with consistent field naming to support both
            # frontend versions (using access/refresh or access_token/refresh_token)
            response_data = {
                # Support both field name formats
                'access': new_tokens.get('access_token', new_tokens.get('access', '')),
                'access_token': new_tokens.get('access_token', new_tokens.get('access', '')),
                'refresh': new_tokens.get('refresh_token', new_tokens.get('refresh', refresh_token)),
                'refresh_token': new_tokens.get('refresh_token', new_tokens.get('refresh', refresh_token)),
                'expires_in': new_tokens.get('expires_in', 300),
                'expires_at': int(time.time()) + new_tokens.get('expires_in', 300)
            }
            
            logger.info(f"Token refresh successful")
            log_admin_action(request, 'TOKEN_REFRESH', f"Token refresh successful for user: {getattr(request.user, 'user_name', None)}", outcome='success')
            return Response(response_data)
            
        except ValueError as e:
            logger.warning(f"Token refresh validation error: {str(e)}")
            log_auth_event(request, 'TOKEN_REFRESH_FAILED', f"Token refresh failed: {str(e)}")
            return Response({'error': str(e)}, status=status.HTTP_401_UNAUTHORIZED)
        except ConnectionError as e:
            logger.error(f"Token refresh connection error: {str(e)}")
            log_auth_event(request, 'TOKEN_REFRESH_FAILED', f"Token refresh connection error: {str(e)}")
            return Response({'error': str(e)}, status=status.HTTP_503_SERVICE_UNAVAILABLE)
        except Exception as e:
            logger.error(f"Token refresh failed: {str(e)}")
            log_auth_event(request, 'TOKEN_REFRESH_FAILED', f"Token refresh failed: {str(e)}")
            return Response({'error': 'Failed to refresh token'}, status=status.HTTP_401_UNAUTHORIZED)

# Registration View
class NeqatRegister(APIView):
    permission_classes = [AllowAny]
    def post(self, request):
        serializer = NeqatUserSerializer(data=request.data)
        if serializer.is_valid():
            # Extract user data from serializer
            user_data = {
                'user_name': serializer.validated_data['user_name'],
                'email': serializer.validated_data['email'],
                'password': serializer.validated_data['password'],
                'first_name': serializer.validated_data.get('first_name', ''),
                'last_name': serializer.validated_data.get('last_name', ''),
            }
            
            # Create user in Keycloak first
            keycloak_service = KeycloakService()
            
            try:
                # Initialize admin client explicitly
                try:
                    keycloak_service._init_admin_client()
                except Exception as e:
                    logger.error(f"Failed to initialize Keycloak admin client: {str(e)}")
                    return Response(
                        {'error': 'Registration service temporarily unavailable. Please try again later.'},
                        status=status.HTTP_503_SERVICE_UNAVAILABLE
                    )
                
                # Check if user already exists in Keycloak to provide better error messages
                existing_user = keycloak_service.find_user_by_email(user_data['email'])
                if existing_user:
                    return Response(
                        {'error': 'User with this email already exists'},
                        status=status.HTTP_400_BAD_REQUEST
                    )
                
                # Create user in Keycloak
                try:
                    keycloak_user_id = keycloak_service.create_user(
                        username=user_data['user_name'],
                        email=user_data['email'],
                        first_name=user_data['first_name'],
                        last_name=user_data['last_name'],
                        password=user_data['password'],
                        enabled=True
                    )
                    
                    # Send verification email
                    keycloak_service.send_verification_email(keycloak_user_id)
                    
                except ValueError as e:
                    # Handle specific value errors like existing user
                    return Response(
                        {'error': str(e)},
                        status=status.HTTP_400_BAD_REQUEST
                    )
                except TypeError as e:
                    if "string indices must be integers" in str(e):
                        logger.error(f"Type error during user creation: {str(e)}")
                        return Response(
                            {'error': 'Registration failed due to a server configuration issue. Please try again later.'},
                            status=status.HTTP_500_INTERNAL_SERVER_ERROR
                        )
                    else:
                        raise
                
                # Create corresponding Django user with Keycloak ID
                user = NeqatUser.objects.create_user(
                    user_name=user_data['user_name'],
                    email=user_data['email'],
                    keycloak_id=keycloak_user_id,
                    first_name=user_data['first_name'],
                    last_name=user_data['last_name'],
                    is_active=True,
                    profile_image=serializer.validated_data.get('profile_image')
                )
                
                # Log the action
                log_admin_action(request, 'REGISTRATION', f"User registered: {user.email}", outcome='success')
                
                # Get initial authentication token for the user
                # We implement a retry mechanism for auth with progressive backoff
                max_retries = 3
                retry_count = 0
                auth_delay = 1.0  # Initial delay in seconds
                
                while retry_count < max_retries:
                    try:
                        auth_data = keycloak_service.authenticate_user(
                            user_data['email'], 
                            user_data['password']
                        )
                        
                        return Response({
                            'message': 'User created successfully',
                            'user': NeqatUserSerializer(user).data,
                            'access': auth_data.get('access'),
                            'refresh': auth_data.get('refresh'),
                            'expires_at': auth_data.get('expires_at')
                        }, status=status.HTTP_201_CREATED)
                    except Exception as auth_error:
                        error_message = str(auth_error)
                        logger.warning(f"Authentication attempt {retry_count + 1} failed: {error_message}")
                        
                        if "Account is not fully set up" in error_message:
                            # This is the specific error we're trying to handle
                            # Update the user to clear any required actions
                            try:
                                # Find the user in Keycloak
                                keycloak_user = keycloak_service.find_user_by_email(user_data['email'])
                                if keycloak_user and 'id' in keycloak_user:
                                    # Update the user to clear required actions
                                    keycloak_service.keycloak_admin.update_user(keycloak_user['id'], {
                                        'requiredActions': [],
                                        'emailVerified': True
                                    })
                                    logger.info(f"Cleared required actions for user before retry")
                            except Exception as update_error:
                                logger.warning(f"Failed to update user required actions: {update_error}")
                        
                        # Wait before retrying with exponential backoff
                        if retry_count < max_retries - 1:
                            time.sleep(auth_delay)
                            auth_delay *= 2  # Double the delay for next retry
                            retry_count += 1
                        else:
                            # We've exhausted our retries, return success with user info only
                            break
                
                # If we get here, authentication failed after retries
                logger.warning(f"User created but authentication failed after {max_retries} retries")
                return Response({
                    'message': 'User created successfully, but automatic login failed. Please log in manually.',
                    'user': NeqatUserSerializer(user).data
                }, status=status.HTTP_201_CREATED)
                
            except Exception as e:
                logger.error(f"Registration failed: {str(e)}")
                
                # Handle different error cases
                error_message = str(e)
                if "already exists" in error_message.lower():
                    return Response({
                        'error': 'User with this email or username already exists'
                    }, status=status.HTTP_400_BAD_REQUEST)
                else:
                    return Response({
                        'error': error_message
                    }, status=status.HTTP_400_BAD_REQUEST)
        else:
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

# Login View
class NeqatLogin(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = 'login'
    def post(self, request):
        email = request.data.get('email')
        username = request.data.get('user_name') 
        password = request.data.get('password')
        
        # Use email for authentication if provided, otherwise username
        login_id = email or username
        
        if not login_id or not password:
            log_auth_event(request, 'LOGIN_FAILED', f"Missing credentials: login_id={login_id}")
            return Response({
                'error': 'Please provide both email/username and password'
            }, status=status.HTTP_400_BAD_REQUEST)
            
        try:
            # Use the Keycloak service for authentication
            keycloak_service = KeycloakService()
            
            try:
                # Initialize the admin client first in case we need it for error recovery
                keycloak_service._init_admin_client()
            except Exception as admin_init_error:
                logger.warning(f"Failed to initialize admin client during login: {admin_init_error}")
                # Continue with login attempt even if admin client init fails
            
            # Try authentication with Keycloak
            try:
                auth_result = keycloak_service.authenticate_user(login_id, password)
            except Exception as auth_error:
                error_message = str(auth_error)
                log_auth_event(request, 'LOGIN_FAILED', f"Login failed for {login_id}: {error_message}")
                
                # Check for specific "Account is not fully set up" error
                if "Account is not fully set up" in error_message:
                    logger.info(f"Login attempt failed due to account not fully set up: {login_id}")
                    
                    # Try to fix the account by clearing required actions
                    try:
                        # First, find the user in Keycloak
                        keycloak_user = keycloak_service.find_user_by_email(login_id)
                        if not keycloak_user and username:
                            # Try by username if email lookup fails
                            users = keycloak_service.keycloak_admin.get_users({'username': username})
                            if users and len(users) > 0:
                                keycloak_user = users[0]
                                
                        if keycloak_user and 'id' in keycloak_user:
                            # Update the user to clear required actions
                            logger.info(f"Clearing required actions for user {keycloak_user['id']} during login")
                            keycloak_service.keycloak_admin.update_user(keycloak_user['id'], {
                                'requiredActions': [],
                                'emailVerified': True
                            })
                            
                            # Try authentication again after clearing required actions
                            try:
                                auth_result = keycloak_service.authenticate_user(login_id, password)
                                logger.info(f"Authentication successful after clearing required actions: {login_id}")
                            except Exception as retry_error:
                                logger.error(f"Authentication failed even after clearing required actions: {retry_error}")
                                log_auth_event(request, 'LOGIN_FAILED', f"Login failed after clearing required actions for {login_id}: {retry_error}")
                                raise ValueError("Account setup issue resolved, please try logging in again.")
                        else:
                            logger.error(f"Could not find user to fix account setup: {login_id}")
                            log_auth_event(request, 'LOGIN_FAILED', f"Account setup issue for {login_id}: could not find user to fix.")
                            raise ValueError("Account setup issue detected but could not be automatically fixed. Please contact support.")
                    except Exception as fix_error:
                        logger.error(f"Failed to fix account setup: {fix_error}")
                        log_auth_event(request, 'LOGIN_FAILED', f"Failed to fix account setup for {login_id}: {fix_error}")
                        raise ValueError("Account not fully set up. Please try again later or contact support.")
                else:
                    log_auth_event(request, 'LOGIN_FAILED', f"Login failed for {login_id}: {error_message}")
                    raise auth_error
            
            # Validate the token using TokenManager
            if 'access' in auth_result:
                try:
                    # Initialize token manager
                    token_manager = TokenManager()
                    
                    # Verify token signature and claims
                    token_payload = token_manager.verify_token_signature(auth_result['access'])
                    
                    # Extra validation if needed
                    if not token_payload.get('sub'):
                        logger.error("Token missing subject claim")
                        raise Exception("Invalid token received from authentication service")
                        
                except Exception as e:
                    logger.error(f"Token validation failed during login: {str(e)}")
                    raise Exception("Authentication succeeded but token validation failed")
            
            # Use Keycloak as the source of truth to get or create Django user
            user, created = keycloak_service.get_or_create_django_user(auth_result['user'])
            
            # Log the successful login
            log_admin_action(request, 'LOGIN', f"User logged in: {user.email}", outcome='success')
            
            # Update user activity record
            activity, _ = UserActivity.objects.get_or_create(user=user)
            activity.login_count += 1
            activity.last_login = timezone.now()
            activity.save()
            
            # Return both access/refresh and access_token/refresh_token formats for compatibility
            response_data = {
                'access': auth_result['access'],
                'access_token': auth_result['access'],
                'refresh': auth_result['refresh'],
                'refresh_token': auth_result['refresh'],
                'user': NeqatUserSerializer(user).data,
                'expires_at': auth_result['expires_at']
            }
            
            return Response(response_data, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"Login failed: {str(e)}")
            log_auth_event(request, 'LOGIN_FAILED', f"Login failed for {login_id}: {str(e)}")
            
            # Provide a more user-friendly message
            error_message = "Invalid credentials. Please check your email/username and password."
            if "temporarily disabled" in str(e).lower():
                error_message = "Account is temporarily locked due to too many failed login attempts. Please try again later."
            elif "token validation failed" in str(e).lower():
                error_message = "Authentication system error. Please try again or contact support."
            elif "account not fully set up" in str(e).lower() or "account setup issue" in str(e).lower():
                error_message = str(e)
            
            return Response({
                'error': error_message
            }, status=status.HTTP_401_UNAUTHORIZED)

# Logout View
class NeqatLogout(APIView):
    authentication_classes = [KeycloakAuthentication]
    permission_classes = [AllowAny]
    
    def post(self, request):
        try:
            # Get refresh token from request
            refresh_token = request.data.get('refresh')
            
            if refresh_token:
                # Use the Keycloak service for logout
                keycloak_service = KeycloakService()
                logout_success = keycloak_service.logout(refresh_token)
                
                if not logout_success:
                    logger.warning("Keycloak logout failed, but proceeding with local logout")
                    log_auth_event(request, 'LOGOUT_FAILED', f"Logout failed for user: {getattr(request.user, 'user_name', None)} (refresh_token={refresh_token})")
            
            # Log the logout
            log_admin_action(request, 'LOGOUT', f"User logged out: {request.user.user_name}", outcome='success')
            
            return Response({"detail": "Successfully logged out."}, status=status.HTTP_200_OK)
        except Exception as e:
            logger.error(f"Logout error: {str(e)}")
            log_auth_event(request, 'LOGOUT_FAILED', f"Logout failed for user: {getattr(request.user, 'user_name', None)}: {str(e)}")
            return Response({"detail": f"Error logging out: {str(e)}"}, status=status.HTTP_400_BAD_REQUEST)

# User Profile View
class NeqatUserProfile(APIView):
    authentication_classes = [KeycloakAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        print(f"User profile requested for: {user.user_name}, is_superuser: {user.is_superuser}")
        serializer = NeqatUserSerializer(user)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def put(self, request):
        user = request.user
        before = model_to_dict(user)
        serializer = NeqatUserSerializer(user, data=request.data, partial=True)
        if serializer.is_valid():
            user = serializer.save()
            after = model_to_dict(user)
            log_admin_action(request, 'PROFILE_UPDATE', f"User updated profile: {user.email}", outcome='success', object_type='User', object_id=user.id, before=before, after=after)
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

# Social Login View for Android
class SocialLoginView(APIView):
    permission_classes = [AllowAny]
    
    def get(self, request, *args, **kwargs):
        logger.info(f"[SocialLoginView.get] args: {args}, kwargs: {kwargs}")
        provider = kwargs.get('provider')
        if not provider:
            # Try to get from request.resolver_match
            resolver_match = getattr(request, 'resolver_match', None)
            if resolver_match:
                provider = resolver_match.kwargs.get('provider')
        logger.info(f"[SocialLoginView.get] Final provider: {provider}")
        try:
            keycloak_service = KeycloakService()
            # SKIP: idps = keycloak_service.keycloak_admin.get_identity_providers()
            auth_url = keycloak_service.get_social_auth_url(provider)
            logger.info(f"[SocialLoginView.get] Generated auth_url: {auth_url}")
            return Response({'auth_url': auth_url, 'message': f'Redirect the user to this URL to authenticate with {provider}'})
        except Exception as e:
            logger.error(f"[SocialLoginView.get] Social login GET error: {str(e)}", exc_info=True)
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    def post(self, request, *args, **kwargs):
        provider = kwargs.get('provider')
        """
        Handle social login for various providers.
        This endpoint accepts tokens from social providers and exchanges them for Keycloak tokens.
        
        If no provider is specified in the URL, it expects a 'provider' field in the request body.
        """
        try:
            # Get the provider from URL path parameter
            
            # Get the token if provided (may not be when initiating OAuth flow)
            token = request.data.get('token')
            
            # Initialize Keycloak service and token manager
            keycloak_service = KeycloakService()
            token_manager = TokenManager()
            
            # If token is provided, exchange it for Keycloak token
            if token:
                try:
                    # Use Keycloak to exchange social token for Keycloak tokens
                    keycloak_result = keycloak_service.exchange_social_token(provider, token)
                    
                    # Validate the token using TokenManager
                    if 'access_token' in keycloak_result:
                        try:
                            # Verify token signature and claims
                            token_payload = token_manager.verify_token_signature(keycloak_result['access_token'])
                            
                            # Extract user info directly from the validated token payload
                            user_info = token_manager.extract_user_info(token_payload)
                            
                            # Supplement with additional info from Keycloak if available
                            try:
                                keycloak_user_info = keycloak_service.get_user_info(keycloak_result['access_token'])
                                if keycloak_user_info:
                                    # Merge the userinfo, preferring keycloak_user_info values
                                    user_info.update(keycloak_user_info)
                            except Exception as e:
                                logger.warning(f"Failed to get additional user info from Keycloak: {str(e)}")
                                # Continue with token payload info only
                            
                            # Check that we have minimum required user info
                            if not user_info.get('sub'):
                                logger.error("Missing sub claim in token and userinfo")
                                raise Exception("Invalid token: missing user identification")
                        except Exception as e:
                            logger.error(f"Social login token validation failed: {str(e)}")
                            raise Exception(f"Invalid token from provider {provider}")
                    else:
                        user_info = keycloak_service.get_user_info(keycloak_result['access_token'])
                    
                    # Get or create the Django user
                    user_data = {
                        'keycloak_id': user_info.get('sub'),
                        'email': user_info.get('email'),
                        'username': user_info.get('preferred_username'),
                        'first_name': user_info.get('given_name', ''),
                        'last_name': user_info.get('family_name', ''),
                    }
                    
                    user, created = keycloak_service.get_or_create_django_user(user_data)
                    
                    # Log the social login
                    log_admin_action(request, 'SOCIAL_LOGIN', f"User logged in via {provider}: {user.email}", outcome='success')
                    
                    # Return the tokens and user info
                    return Response({
                        'access': keycloak_result['access_token'],
                        'refresh': keycloak_result['refresh_token'],
                        'expires_at': keycloak_result.get('expires_in', 300) + int(time.time()),
                        'user': NeqatUserSerializer(user).data
                    })
                except Exception as e:
                    logger.error(f"Social token exchange failed: {str(e)}")
                    return Response(
                        {'error': f"Failed to authenticate with {provider}: {str(e)}"},
                        status=status.HTTP_400_BAD_REQUEST
                    )
            
            # Otherwise, initiate OAuth flow by redirecting to Keycloak
            else:
                # Get the authorization URL for the provider
                auth_url = keycloak_service.get_social_auth_url(provider)
                
                return Response({
                    'auth_url': auth_url,
                    'message': f'Redirect the user to this URL to authenticate with {provider}'
                })
                
        except Exception as e:
            logger.error(f"Social login error: {str(e)}")
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

# Forgot Password View
class ForgotPasswordView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = 'password_reset'
    def post(self, request):
        serializer = ForgotPasswordSerializer(data=request.data)
        if serializer.is_valid():
            email = serializer.validated_data['email']
            
            try:
                # Initialize the Keycloak service
                keycloak_service = KeycloakService()
                
                # Process the password reset request
                reset_result = keycloak_service.request_password_reset(email)
                
                # Log the password reset request (only if we have a Django user)
                try:
                    # Get the user by email
                    user = NeqatUser.objects.get(email=email)
                    
                    # Log the reset request
                    log_admin_action(request, 'PASSWORD_RESET_REQUEST', f"Password reset requested for: {email}", outcome='success')
                except NeqatUser.DoesNotExist:
                    logger.info(f"Reset requested for user not yet in Django: {email}")
                    log_auth_event(request, 'PASSWORD_RESET_FAILED', f"Password reset requested for non-existent user: {email}")
                
                # For security reasons, we don't confirm whether a user exists
                # We always return a success message
                return Response(
                    {'message': 'If an account exists with this email, a password reset link has been sent'},
                    status=status.HTTP_200_OK
                )
            except ValueError as e:
                logger.warning(f"Password reset validation error: {str(e)}")
                log_auth_event(request, 'PASSWORD_RESET_FAILED', f"Password reset failed for {email}: {str(e)}")
                return Response(
                    {'message': 'If an account exists with this email, a password reset link has been sent'},
                    status=status.HTTP_200_OK
                )
            except Exception as e:
                logger.error(f"Password reset request failed: {str(e)}")
                log_auth_event(request, 'PASSWORD_RESET_FAILED', f"Password reset failed for {email}: {str(e)}")
                return Response(
                    {'error': 'An error occurred while processing your request. Please try again later.'},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

# Reset Password View
class ResetPasswordView(APIView):
    permission_classes = [AllowAny]
    def post(self, request):
        serializer = ResetPasswordSerializer(data=request.data)
        
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
            
        token = serializer.validated_data.get('token')
        new_password = serializer.validated_data.get('new_password')
        
        try:
            # Verify the token exists and is valid
            try:
                reset_token = PasswordResetToken.objects.get(token=token, is_used=False)
                
                # Check if token is expired (1 hour window)
                if reset_token.is_expired():
                    reset_token.delete()  # Clean up expired token
                    return Response(
                        {'error': 'Password reset token has expired. Please request a new password reset.'},
                        status=status.HTTP_400_BAD_REQUEST
                    )
                    
                user = reset_token.user
                
            except PasswordResetToken.DoesNotExist:
                return Response(
                    {'error': 'Invalid or expired password reset token. Please request a new password reset.'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Validate password complexity if not already done by serializer
            try:
                from django.contrib.auth.password_validation import validate_password
                validate_password(new_password, user)
            except Exception as password_error:
                return Response(
                    {'error': f'Password validation failed: {str(password_error)}'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Initialize Keycloak service
            keycloak_service = KeycloakService()
            
            try:
                # Ensure the admin client is initialized
                keycloak_service._init_admin_client()
            except Exception as admin_init_error:
                logger.error(f"Failed to initialize admin client during password reset: {str(admin_init_error)}")
                return Response(
                    {'error': 'Password reset service is temporarily unavailable. Please try again later.'},
                    status=status.HTTP_503_SERVICE_UNAVAILABLE
                )
            
            # Find the user in Keycloak
            if user.keycloak_id:
                # If we already have the Keycloak ID, use it directly
                keycloak_user_id = user.keycloak_id
            else:
                # Otherwise find the user by email
                keycloak_user = keycloak_service.find_user_by_email(user.email)
                
                if not keycloak_user:
                    return Response(
                        {'error': 'User account configuration error. Please contact support.'},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR
                    )
                    
                # Update the Django user with the Keycloak ID
                keycloak_user_id = keycloak_user['id']
                user.keycloak_id = keycloak_user_id
                user.save(update_fields=['keycloak_id'])
            
            # Reset the password in Keycloak
            try:
                password_reset_success = keycloak_service.reset_password(
                    keycloak_user_id,
                    new_password,
                    temporary=False  # Set to false to avoid requiring a password change on login
                )
                
                if not password_reset_success:
                    return Response(
                        {'error': 'Failed to update password. Please try again later.'},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR
                    )
            except Exception as reset_error:
                logger.error(f"Failed to reset password in Keycloak: {str(reset_error)}")
                return Response(
                    {'error': 'Failed to update password. Please try again later.'},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
                
            # Mark the token as used
            reset_token.is_used = True
            reset_token.used_at = timezone.now()
            reset_token.save()
            
            # Log the password reset
            log_admin_action(request, 'PASSWORD_RESET', f"Password reset completed for user: {user.email}", outcome='success')
            
            # Try to authenticate the user with the new password
            try:
                auth_result = keycloak_service.authenticate_user(user.email, new_password)
                
                # If authentication succeeds, return tokens as well
                return Response({
                    'message': 'Password reset successful',
                    'access': auth_result.get('access'),
                    'refresh': auth_result.get('refresh'),
                    'expires_at': auth_result.get('expires_at'),
                    'user': NeqatUserSerializer(user).data
                }, status=status.HTTP_200_OK)
            except Exception as auth_error:
                # If authentication fails, still report success but without tokens
                logger.warning(f"User password reset successful but auto-login failed: {str(auth_error)}")
                return Response({
                    'message': 'Password reset successful. Please log in with your new password.'
                }, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"Password reset failed: {str(e)}")
            log_auth_event(request, 'PASSWORD_RESET_FAILED', f"Password reset failed for {email}: {str(e)}")
            return Response(
                {'error': 'Failed to reset password. Please try again later.'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

# Admin Panel Views

class AdminUserViewSet(viewsets.ModelViewSet):
    """
    API endpoint for admin users to manage all users
    """
    queryset = NeqatUser.objects.all().order_by('-date_joined')
    serializer_class = NeqatUserSerializer
    authentication_classes = [KeycloakAuthentication]
    permission_classes = [IsAuthenticated, IsAdmin]
    
    def get_queryset(self):
        queryset = super().get_queryset()
        
        # Filter by username, email or name if provided
        search_query = self.request.query_params.get('search', None)
        if search_query:
            queryset = queryset.filter(
                Q(user_name__icontains=search_query) |
                Q(email__icontains=search_query) |
                Q(first_name__icontains=search_query) |
                Q(last_name__icontains=search_query)
            )
            
        # Filter by active status
        is_active = self.request.query_params.get('is_active', None)
        if is_active is not None:
            is_active = is_active.lower() == 'true'
            queryset = queryset.filter(is_active=is_active)
            
        # Filter by staff status
        is_staff = self.request.query_params.get('is_staff', None)
        if is_staff is not None:
            is_staff = is_staff.lower() == 'true'
            queryset = queryset.filter(is_staff=is_staff)
            
        return queryset
    
    @action(detail=True, methods=['post'])
    def disable(self, request, pk=None):
        user = self.get_object()
        user.is_active = False
        user.save()
        
        # Log this admin action
        log_admin_action(request, 'ADMIN_ACTION', f"Admin disabled user: {user.email}", outcome='success')
        print(f"Admin {request.user.user_name} disabled user: {user.email}")
        
        return Response({'status': 'user disabled'})
    
    @action(detail=True, methods=['post'])
    def enable(self, request, pk=None):
        user = self.get_object()
        user.is_active = True
        user.save()
        
        # Log this admin action
        log_admin_action(request, 'ADMIN_ACTION', f"Admin enabled user: {user.email}", outcome='success')
        print(f"Admin {request.user.user_name} enabled user: {user.email}")
        
        return Response({'status': 'user enabled'})
    
    @action(detail=True, methods=['post'])
    def reset_password(self, request, pk=None):
        user = self.get_object()
        
        # We'll use one of two approaches depending on admin preference:
        # 1. Send a password reset link (default)
        # 2. Set a temporary password directly in Keycloak
        
        set_temp_password = request.data.get('set_temp_password', False)
        temp_password = request.data.get('temp_password', None)
        
        if set_temp_password and temp_password:
            # Approach 2: Set temporary password directly in Keycloak
            try:
                keycloak_service = KeycloakService()
                
                # Ensure we have the user's Keycloak ID
                keycloak_id = user.keycloak_id
                if not keycloak_id:
                    # Look up by email if we don't have the ID
                    keycloak_user = keycloak_service.find_user_by_email(user.email)
                    if not keycloak_user:
                        return Response(
                            {'error': 'User not found in Keycloak'},
                            status=status.HTTP_500_INTERNAL_SERVER_ERROR
                        )
                    keycloak_id = keycloak_user['id']
                    # Update user with Keycloak ID
                    user.keycloak_id = keycloak_id
                    user.save()
                
                # Set the temporary password in Keycloak
                # Note: set temporary=True to force user to change on next login
                success = keycloak_service.reset_password(keycloak_id, temp_password)
                
                if not success:
                    return Response(
                        {'error': 'Failed to set temporary password in Keycloak'},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR
                    )
                
                # Log this admin action
                log_admin_action(request, 'ADMIN_ACTION', f"Admin set temporary password for user: {user.email}", outcome='success')
                
                return Response({'status': 'temporary password set successfully'})
                
            except Exception as e:
                logger.error(f"Failed to set temporary password: {str(e)}")
                return Response(
                    {'error': f'Failed to set temporary password: {str(e)}'},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
        else:
            # Approach 1: Send password reset link
            # Create a password reset token
            token = PasswordResetToken(user=user)
            token.save()
            
            # Send email with reset link
            reset_link = f"http://localhost:8000/api/reset-password/?token={token.token}"
            subject = 'Password Reset Request for Neqat'
            message = f"""
            Hello {user.first_name or user.user_name},

            Your password has been reset by an administrator. Click the link below to set a new password:
            {reset_link}

            This link will expire in 1 hour.

            Best,
            The Neqat Team
            """
            
            try:
                send_mail(
                    subject,
                    message,
                    settings.DEFAULT_FROM_EMAIL,
                    [user.email],
                    fail_silently=False,
                )
            except Exception as e:
                return Response(
                    {'error': f'Failed to send email: {str(e)}'},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
                
            # Log this admin action
            log_admin_action(request, 'ADMIN_ACTION', f"Admin initiated password reset for user: {user.email}", outcome='success')
            
            return Response({'status': 'password reset link sent'})

    @action(detail=True, methods=['post'])
    def make_staff(self, request, pk=None):
        if not request.user.is_superuser:
            log_permission_denial(request, 'ADMIN_ACTION', 'Non-superuser attempted to promote user to staff')
            return Response({'error': 'Only superusers can promote users to staff'}, status=status.HTTP_403_FORBIDDEN)
        
        user = self.get_object()
        
        # Update the user's role and group in Keycloak
        try:
            keycloak_service = KeycloakService()
            
            # Ensure we have the user's Keycloak ID
            keycloak_id = user.keycloak_id
            if not keycloak_id:
                # Look up by email if we don't have the ID
                keycloak_user = keycloak_service.find_user_by_email(user.email)
                if not keycloak_user:
                    return Response(
                        {'error': 'User not found in Keycloak'},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR
                    )
                keycloak_id = keycloak_user['id']
                # Update user with Keycloak ID
                user.keycloak_id = keycloak_id
                user.save()
            
            # Assign admin role and add to Administrators group
            success = keycloak_service.assign_user_role_and_group(
                keycloak_id, 
                KeycloakRoles.ADMIN,
                'Administrators'
            )
            
            if not success:
                return Response(
                    {'error': 'Failed to assign admin role in Keycloak'},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
            
            # Update Django user
            user.is_staff = True
            user.is_superuser = True
            user.save()
            
            # Log this admin action
            log_admin_action(request, 'ADMIN_ACTION', f"Admin promoted user to staff: {user.email}", outcome='success')
            
            return Response({'status': 'user promoted to staff'})
            
        except Exception as e:
            logger.error(f"Failed to promote user to staff: {str(e)}")
            log_admin_action(request, 'ADMIN_ACTION', f'Failed to promote user to staff: {str(e)}', outcome='error')
            return Response(
                {'error': f'Failed to promote user to staff: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def perform_create(self, serializer):
        user = serializer.save()
        log_admin_action(self.request, 'USER_CREATE', f"Admin created user: {user.email}", outcome='success', object_type='User', object_id=user.id, after=model_to_dict(user))

    def perform_update(self, serializer):
        user = self.get_object()
        before = model_to_dict(user)
        user = serializer.save()
        after = model_to_dict(user)
        log_admin_action(self.request, 'USER_UPDATE', f"Admin updated user: {user.email}", outcome='success', object_type='User', object_id=user.id, before=before, after=after)

    def perform_destroy(self, instance):
        before = model_to_dict(instance)
        log_admin_action(self.request, 'USER_DELETE', f"Admin deleted user: {instance.email}", outcome='success', object_type='User', object_id=instance.id, before=before)
        instance.delete()

class SystemLogViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint for viewing system logs
    """
    queryset = SystemLog.objects.all().order_by('-timestamp')
    serializer_class = SystemLogSerializer
    authentication_classes = [KeycloakAuthentication]
    permission_classes = [IsAuthenticated, IsAdmin]
    
    def get_queryset(self):
        queryset = super().get_queryset()
        # Filter by action
        action = self.request.query_params.get('action', None)
        if action:
            queryset = queryset.filter(action=action)
        # Filter by username
        username = self.request.query_params.get('username', None)
        if username:
            queryset = queryset.filter(user__user_name__icontains=username)
        # Filter by date range
        start_date = self.request.query_params.get('start_date', None)
        if start_date:
            queryset = queryset.filter(timestamp__gte=start_date)
        end_date = self.request.query_params.get('end_date', None)
        if end_date:
            queryset = queryset.filter(timestamp__lte=end_date)
        return queryset

    @action(detail=False, methods=['get'], url_path='export')
    def export(self, request):
        """
        Export system logs as CSV or JSON, filtered by query params.
        """
        format = request.query_params.get('format', 'csv').lower()
        logs = self.get_queryset()
        serializer = SystemLogSerializer(logs, many=True)
        data = serializer.data
        if format == 'json':
            return Response(data, content_type='application/json')
        # CSV export
        import csv
        from io import StringIO
        response = HttpResponse(content_type='text/csv')
        response['Content-Disposition'] = 'attachment; filename="system_log.csv"'
        writer = csv.writer(response)
        # Write header
        writer.writerow(['ID', 'User', 'Action', 'Action Display', 'Details', 'Timestamp', 'IP Address', 'User Agent'])
        for item in data:
            user_name = item['user']['user_name'] if item['user'] else ''
            writer.writerow([
                item.get('id', ''),
                user_name,
                item.get('action', ''),
                item.get('action_display', ''),
                item.get('details', ''),
                item.get('timestamp', ''),
                item.get('ip_address', ''),
                item.get('user_agent', ''),
            ])
        return response

class UserActivityViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint for viewing user activity
    """
    queryset = UserActivity.objects.all().order_by('-last_active')
    serializer_class = UserActivitySerializer
    authentication_classes = [KeycloakAuthentication]
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=['get'], url_path='export')
    def export(self, request):
        """
        Export the requesting user's activity logs as CSV or JSON.
        """
        format = request.query_params.get('format', 'csv').lower()
        user = request.user
        logs = UserActivity.objects.filter(user=user).order_by('-last_active')
        serializer = UserActivitySerializer(logs, many=True)
        data = serializer.data
        if format == 'json':
            return Response(data, content_type='application/json')
        # CSV export
        import csv
        from io import StringIO
        response = HttpResponse(content_type='text/csv')
        response['Content-Disposition'] = 'attachment; filename="user_activity_log.csv"'
        writer = csv.writer(response)
        # Write header
        writer.writerow(['User', 'Last Active', 'Login Count', 'Session Duration'])
        for item in data:
            user_name = item['user']['user_name'] if item['user'] else ''
            writer.writerow([
                user_name,
                item['last_active'],
                item['login_count'],
                item['session_duration'],
            ])
        return response

class NotificationViewSet(viewsets.ModelViewSet):
    """
    API endpoint for managing notifications
    """
    queryset = Notification.objects.all().order_by('-created_at')
    serializer_class = NotificationSerializer
    authentication_classes = [KeycloakAuthentication]
    permission_classes = [IsAuthenticated, IsAdmin]
    
    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)
        log_admin_action(self.request, 'CREATE_NOTIFICATION', f'Notification created: {serializer.instance.title}', outcome='success')
    
    @action(detail=True, methods=['post'])
    def send(self, request, pk=None):
        notification = self.get_object()
        
        # Here you would implement the actual notification sending logic
        # For example, sending emails, push notifications, etc.
        
        # If the notification is global, send to all users
        if notification.is_global:
            users = NeqatUser.objects.filter(is_active=True)
        else:
            users = notification.target_users.filter(is_active=True)
        
        # For demonstration, we'll just log the notification sending
        subject = notification.title
        message = notification.message
        
        try:
            for user in users:
                # You can replace this with actual notification sending code
                # For example, using Firebase Cloud Messaging, email, etc.
                print(f"Sending notification to {user.email}: {notification.title}")
                
                # For now, we'll just send an email
                send_mail(
                    subject,
                    message,
                    settings.DEFAULT_FROM_EMAIL,
                    [user.email],
                    fail_silently=True,
                )
            log_admin_action(request, 'SEND_NOTIFICATION', f'Notification sent: {notification.title}', outcome='success')
            return Response({'status': 'notification sent'})
        except Exception as e:
            log_admin_action(request, 'SEND_NOTIFICATION', f'Failed to send notification: {str(e)}', outcome='error')
            return Response({'error': f'Failed to send notification: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class AdminDashboardView(APIView):
    """
    API endpoint for admin dashboard analytics
    """
    authentication_classes = [KeycloakAuthentication]
    permission_classes = [IsAuthenticated, IsAdmin]
    
    def get(self, request):
        try:
            # Get total users count
            total_users = NeqatUser.objects.count()
            
            # Get active users (users who logged in in the last 7 days)
            seven_days_ago = timezone.now() - timedelta(days=7)
            active_users = UserActivity.objects.filter(last_active__gte=seven_days_ago).count()
            
            # Get new users in the last 30 days
            thirty_days_ago = timezone.now() - timedelta(days=30)
            new_users = NeqatUser.objects.filter(date_joined__gte=thirty_days_ago).count()
            
            # Get user registration by day for the last 30 days - SQL Server compatible version
            try:
                from django.db import connection
                users_by_day = []
                
                # Use CAST/CONVERT to extract the date part in SQL Server
                if connection.vendor == 'microsoft':
                    with connection.cursor() as cursor:
                        cursor.execute("""
                            SELECT CONVERT(DATE, date_joined) as date, COUNT(*) as count
                            FROM neqat_neqatuser
                            WHERE date_joined >= %s
                            GROUP BY CONVERT(DATE, date_joined)
                            ORDER BY date
                        """, [thirty_days_ago])
                        users_by_day = [{'date': row[0], 'count': row[1]} for row in cursor.fetchall()]
                else:
                    # For other databases (SQLite, PostgreSQL, etc.) use the Django ORM
                    users_by_day = (
                        NeqatUser.objects.filter(date_joined__gte=thirty_days_ago)
                        .extra({'date': "date(date_joined)"})
                        .values('date')
                        .annotate(count=Count('id'))
                        .order_by('date')
                    )
                    users_by_day = [{'date': item['date'], 'count': item['count']} for item in users_by_day]
            except Exception as e:
                print(f"Error getting users by day: {str(e)}")
                users_by_day = []
            
            # Get recent system logs - handle in a try/except block
            try:
                recent_logs = SystemLog.objects.all().order_by('-timestamp')[:10]
                recent_logs_data = SystemLogSerializer(recent_logs, many=True).data
            except Exception as e:
                # Log the error but continue
                print(f"Error serializing system logs: {str(e)}")
                recent_logs_data = []
            
            return Response({
                'total_users': total_users,
                'active_users': active_users,
                'new_users_last_30_days': new_users,
                'users_by_day': users_by_day,
                'recent_logs': recent_logs_data,
            })
        except Exception as e:
            # Return a more graceful error response
            print(f"Error in admin dashboard: {str(e)}")
            return Response({
                'error': 'An error occurred while retrieving dashboard data',
                'detail': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# Content Moderation ViewSets

class PostViewSet(viewsets.ModelViewSet):
    """
    API endpoint for users to create and view posts
    """
    serializer_class = PostSerializer
    authentication_classes = [KeycloakAuthentication]
    permission_classes = [IsAuthenticated, IsOwnerOrAdmin]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['title', 'content']
    ordering_fields = ['created_at', 'updated_at', 'title']
    
    def get_queryset(self):
        # Regular users can only see approved posts or their own pending posts
        if not self.request.user.is_staff:
            return Post.objects.filter(
                Q(status='APPROVED') | 
                Q(created_by=self.request.user)
            ).order_by('-created_at')
        # Staff can see all posts
        return Post.objects.all().order_by('-created_at')
    
    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)
        
        # Log post creation
        log_admin_action(self.request, 'CONTENT', f"User created new post: {serializer.instance.title}", outcome='success')

class CommentViewSet(viewsets.ModelViewSet):
    """
    API endpoint for users to create and view comments
    """
    serializer_class = CommentSerializer
    authentication_classes = [KeycloakAuthentication]
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['content']
    ordering_fields = ['created_at']
    
    def get_queryset(self):
        # Get news_id from query parameters
        news_id = self.request.query_params.get('news_id')
        
        # Base queryset
        if not self.request.user.is_staff:
            queryset = Comment.objects.filter(
                Q(status='PENDING') | 
                Q(created_by=self.request.user)
            )
        else:
            queryset = Comment.objects.all()
        
        # Apply news_id filter if provided
        if news_id:
            queryset = queryset.filter(news_id=news_id)
        
        # Debug logging
        print(f"CommentViewSet: user={self.request.user}, news_id={news_id}, queryset_count={queryset.count()}")
        for comment in queryset:
            print(f"Comment: id={comment.id}, status={comment.status}, created_by={comment.created_by}, news_id={comment.news_id}")
        
        return queryset.order_by('-created_at')
    
    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)
        
        # Determine the content type and title for logging
        comment = serializer.instance
        if comment.post:
            content_type = 'Post'
            content_title = comment.post.title
        else:
            content_type = 'News'
            content_title = comment.news.title
        
        # Log comment creation
        log_admin_action(self.request, 'CONTENT', f"User added comment to {content_type}: {content_title}", outcome='success')

class CommentListCreateView(generics.ListCreateAPIView):
    serializer_class = CommentSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        news_id = self.request.query_params.get('news_id')
        # Base queryset: APPROVED comments or comments by the requesting user
        queryset = Comment.objects.filter(
            Q(status='PENDING') | 
            Q(created_by=self.request.user)
        )
        if news_id:
            return queryset.filter(news_id=news_id)
        return queryset

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)
        # Log the action
        log_details = f"User added comment to news: {serializer.instance.news.title}"
        log_admin_action(self.request, 'CREATE_COMMENT', log_details, outcome='success')
        
class ContentFlagViewSet(viewsets.ModelViewSet):
    """
    API endpoint for users to flag inappropriate content
    """
    serializer_class = ContentFlagSerializer
    authentication_classes = [KeycloakAuthentication]
    permission_classes = [IsAuthenticated, IsAdmin]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = 'flag_content'
    
    def get_queryset(self):
        # Regular users can only see their own flags
        if not self.request.user.is_staff:
            return ContentFlag.objects.filter(reported_by=self.request.user).order_by('-created_at')
        # Staff can see all flags
        return ContentFlag.objects.all().order_by('-created_at')
    
    def perform_create(self, serializer):
        serializer.save(reported_by=self.request.user)
        
        # Log flag creation and flag the related content for review
        content_type = serializer.validated_data.get('content_type')
        content_id = serializer.validated_data.get('content_id')
        reason = serializer.validated_data.get('reason')
        
        # Flag the content for review
        if content_type == 'POST':
            try:
                post = Post.objects.get(id=content_id)
                post.status = 'FLAGGED'
                post.save(update_fields=['status'])
            except Post.DoesNotExist:
                pass
        elif content_type == 'COMMENT':
            try:
                comment = Comment.objects.get(id=content_id)
                comment.status = 'FLAGGED'
                comment.save(update_fields=['status'])
            except Comment.DoesNotExist:
                pass
        
        # Log the flagging action, including object_type and object_id
        log_admin_action(
            self.request,
            'SECURITY',
            f"User flagged {content_type} content (ID: {content_id}) for reason: {reason}",
            outcome='success',
            object_type='ContentFlag',
            object_id=serializer.instance.id,
            after=model_to_dict(serializer.instance)
        )

# Admin Content Moderation ViewSets

class AdminPostViewSet(viewsets.ModelViewSet):
    """
    API endpoint for admins to moderate posts
    """
    queryset = Post.objects.all().order_by('-created_at')
    serializer_class = AdminPostSerializer
    authentication_classes = [KeycloakAuthentication]
    permission_classes = [IsAuthenticated, IsAdmin]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['title', 'content', 'created_by__user_name', 'created_by__email']
    ordering_fields = ['created_at', 'updated_at', 'status']
    
    def get_queryset(self):
        queryset = super().get_queryset()
        status_filter = self.request.query_params.get('status', None)
        
        if status_filter:
            queryset = queryset.filter(status=status_filter.upper())
        else:
            # Default to showing pending and flagged posts for moderation view
            queryset = queryset.filter(Q(status='PENDING') | Q(status='FLAGGED'))
            
        # Apply other filters from parent class if any (search, ordering)
        return queryset

    @action(detail=True, methods=['post'], permission_classes=[IsAdmin])
    def approve(self, request, pk=None):
        post = self.get_object()
        old_status = post.status
        post.status = 'APPROVED'
        post.moderated_at = timezone.now()
        post.moderated_by = request.user
        post.save()

        moderation_history = ModerationHistory.objects.create(
            moderator=request.user,
            object_type='Post',
            object_id=post.id,
            action_taken='approved',
            before_status=old_status,
            after_status=post.status,
            reason=request.data.get('reason', '')
        )

        # Broadcast the moderation action
        channel_layer = get_channel_layer()
        if channel_layer:
            async_to_sync(channel_layer.group_send)(
                "admin_logs",
                {
                    "type": "send_log_message",
                    "message": {
                        "type": "moderation_history",
                        "object_type": moderation_history.object_type,
                        "object_id": str(moderation_history.object_id),
                        "action_taken": moderation_history.action_taken,
                        "moderator": str(moderation_history.moderator),
                        "timestamp": str(moderation_history.timestamp),
                        "before_status": moderation_history.before_status,
                        "after_status": moderation_history.after_status,
                        "reason": moderation_history.reason,
                    },
                }
            )

        log_admin_action(request, 'Post Moderation', f'Approved Post ID: {post.id}', 'success')
        return Response({'status': 'post approved'}, status=status.HTTP_200_OK)

    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        post = self.get_object()
        old_status = post.status
        post.status = 'REJECTED'
        post.moderated_at = timezone.now()
        post.moderated_by = request.user
        post.save()

        moderation_history = ModerationHistory.objects.create(
            moderator=request.user,
            object_type='Post',
            object_id=post.id,
            action_taken='rejected',
            before_status=old_status,
            after_status=post.status,
            reason=request.data.get('reason', '')
        )

        # Broadcast the moderation action
        channel_layer = get_channel_layer()
        if channel_layer:
            async_to_sync(channel_layer.group_send)(
                "admin_logs",
                {
                    "type": "send_log_message",
                    "message": {
                        "type": "moderation_history",
                        "object_type": moderation_history.object_type,
                        "object_id": str(moderation_history.object_id),
                        "action_taken": moderation_history.action_taken,
                        "moderator": str(moderation_history.moderator),
                        "timestamp": str(moderation_history.timestamp),
                        "before_status": moderation_history.before_status,
                        "after_status": moderation_history.after_status,
                        "reason": moderation_history.reason,
                    },
                }
            )

        log_admin_action(request, 'Post Moderation', f'Rejected Post ID: {post.id}', 'success')
        return Response({'status': 'post rejected'}, status=status.HTTP_200_OK)

    @action(detail=False, methods=['get'])
    def pending(self, request):
        # Get all pending and flagged posts
        pending_posts = Post.objects.filter(Q(status='PENDING') | Q(status='FLAGGED')).order_by('-created_at')
        page = self.paginate_queryset(pending_posts)
        
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
            
        serializer = self.get_serializer(pending_posts, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['post'])
    def bulk_approve(self, request):
        try:
            ids = request.data.get('ids', [])
            posts = Post.objects.filter(id__in=ids, status='PENDING')
            count = 0
            for post in posts:
                before_state_for_log = model_to_dict(post) # Capture state before change
                post.status = 'APPROVED'
                post.moderated_by = request.user
                post.moderated_at = timezone.now()
                post.save()
                count += 1
                
                # Log each approved post with before and after states
                log_admin_action(
                    request,
                    'ADMIN_ACTION',
                    f"Bulk approved post: {post.title}",
                    outcome='success',
                    object_type='Post',
                    object_id=post.id,
                    before=before_state_for_log,
                    after=model_to_dict(post)
                )
            if count == 0:
                return Response({'error': 'No posts approved. Check if posts are already approved or not found.'}, status=status.HTTP_400_BAD_REQUEST)
            return Response({'approved': count}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    @action(detail=False, methods=['post'])
    def bulk_reject(self, request):
        try:
            ids = request.data.get('ids', [])
            notes = request.data.get('notes', '')
            posts = Post.objects.filter(id__in=ids, status='PENDING')
            count = 0
            for post in posts:
                before_state_for_log = model_to_dict(post) # Capture state before change
                post.status = 'REJECTED'
                post.moderation_notes = notes
                post.moderated_by = request.user
                post.moderated_at = timezone.now()
                post.save()
                count += 1
                
                # Log each rejected post with before and after states
                log_admin_action(
                    request,
                    'ADMIN_ACTION',
                    f"Bulk rejected post: {post.title}",
                    outcome='success',
                    object_type='Post',
                    object_id=post.id,
                    before=before_state_for_log,
                    after=model_to_dict(post)
                )
            if count == 0:
                return Response({'error': 'No posts rejected. Check if posts are already rejected or not found.'}, status=status.HTTP_400_BAD_REQUEST)
            return Response({'rejected': count}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class AdminCommentViewSet(viewsets.ModelViewSet):
    """
    API endpoint for admins to moderate comments
    """
    queryset = Comment.objects.all().order_by('-created_at')
    serializer_class = AdminCommentSerializer
    authentication_classes = [KeycloakAuthentication]
    permission_classes = [IsAuthenticated, IsAdmin]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['content', 'created_by__user_name', 'created_by__email']
    ordering_fields = ['created_at', 'updated_at', 'status']
    
    def get_queryset(self):
        queryset = super().get_queryset()
        status_filter = self.request.query_params.get('status', None)
        
        if status_filter:
            queryset = queryset.filter(status=status_filter.upper())
        else:
            # Default to showing pending and flagged comments for moderation view
            queryset = queryset.filter(Q(status='PENDING') | Q(status='FLAGGED'))
            
        # Apply other filters from parent class if any (search, ordering)
        return queryset
    
    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        comment = self.get_object()
        old_status = comment.status
        comment.status = Comment.CommentStatus.APPROVED
        comment.moderated_at = timezone.now()
        comment.moderated_by = request.user
        comment.save()

        moderation_history = ModerationHistory.objects.create(
            moderator=request.user,
            object_type='Comment',
            object_id=comment.id,
            action_taken='approved',
            before_status=old_status,
            after_status=comment.status,
            reason=request.data.get('reason', '')
        )

        # Broadcast the moderation action
        channel_layer = get_channel_layer()
        if channel_layer:
            async_to_sync(channel_layer.group_send)(
                "admin_logs",
                {
                    "type": "send_log_message",
                    "message": {
                        "type": "moderation_history",
                        "object_type": moderation_history.object_type,
                        "object_id": str(moderation_history.object_id),
                        "action_taken": moderation_history.action_taken,
                        "moderator": str(moderation_history.moderator),
                        "timestamp": str(moderation_history.timestamp),
                        "before_status": moderation_history.before_status,
                        "after_status": moderation_history.after_status,
                        "reason": moderation_history.reason,
                    },
                }
            )

        log_admin_action(request, 'Comment Moderation', f'Approved Comment ID: {comment.id}', 'success')
        return Response({'status': 'comment approved'}, status=status.HTTP_200_OK)

    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        comment = self.get_object()
        old_status = comment.status
        comment.status = Comment.CommentStatus.REJECTED
        comment.moderated_at = timezone.now()
        comment.moderated_by = request.user
        comment.save()

        moderation_history = ModerationHistory.objects.create(
            moderator=request.user,
            object_type='Comment',
            object_id=comment.id,
            action_taken='rejected',
            before_status=old_status,
            after_status=comment.status,
            reason=request.data.get('reason', '')
        )

        # Broadcast the moderation action
        channel_layer = get_channel_layer()
        if channel_layer:
            async_to_sync(channel_layer.group_send)(
                "admin_logs",
                {
                    "type": "send_log_message",
                    "message": {
                        "type": "moderation_history",
                        "object_type": moderation_history.object_type,
                        "object_id": str(moderation_history.object_id),
                        "action_taken": moderation_history.action_taken,
                        "moderator": str(moderation_history.moderator),
                        "timestamp": str(moderation_history.timestamp),
                        "before_status": moderation_history.before_status,
                        "after_status": moderation_history.after_status,
                        "reason": moderation_history.reason,
                    },
                }
            )

        log_admin_action(request, 'Comment Moderation', f'Rejected Comment ID: {comment.id}', 'success')
        return Response({'status': 'comment rejected'}, status=status.HTTP_200_OK)

    @action(detail=False, methods=['get'])
    def pending(self, request):
        # Get all pending and flagged comments
        pending_comments = Comment.objects.filter(Q(status='PENDING') | Q(status='FLAGGED')).order_by('-created_at')
        page = self.paginate_queryset(pending_comments)
        
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
            
        serializer = self.get_serializer(pending_comments, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['post'])
    def bulk_approve(self, request):
        try:
            ids = request.data.get('ids', [])
            comments = Comment.objects.filter(id__in=ids, status='PENDING')
            count = 0
            for comment in comments:
                before_state_for_log = model_to_dict(comment) # Capture state before change
                comment.status = 'APPROVED'
                comment.moderated_by = request.user
                comment.moderated_at = timezone.now()
                comment.save()
                count += 1
                
                # Log each approved comment with before and after states
                log_admin_action(
                    request,
                    'ADMIN_ACTION',
                    f"Bulk approved comment on post: {comment.post.title}",
                    outcome='success',
                    object_type='Comment',
                    object_id=comment.id,
                    before=before_state_for_log,
                    after=model_to_dict(comment)
                )
            if count == 0:
                return Response({'error': 'No comments approved. Check if comments are already approved or not found.'}, status=status.HTTP_400_BAD_REQUEST)
            return Response({'approved': count}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    @action(detail=False, methods=['post'])
    def bulk_reject(self, request):
        try:
            ids = request.data.get('ids', [])
            notes = request.data.get('notes', '')
            comments = Comment.objects.filter(id__in=ids, status='PENDING')
            count = 0
            for comment in comments:
                before_state_for_log = model_to_dict(comment) # Capture state before change
                comment.status = 'REJECTED'
                comment.moderation_notes = notes
                comment.moderated_by = request.user
                comment.moderated_at = timezone.now()
                comment.save()
                count += 1
                
                # Log each rejected comment with before and after states
                log_admin_action(
                    request,
                    'ADMIN_ACTION',
                    f"Bulk rejected comment on post: {comment.post.title}",
                    outcome='success',
                    object_type='Comment',
                    object_id=comment.id,
                    before=before_state_for_log,
                    after=model_to_dict(comment)
                )
            if count == 0:
                return Response({'error': 'No comments rejected. Check if comments are already rejected or not found.'}, status=status.HTTP_400_BAD_REQUEST)
            return Response({'rejected': count}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class AdminContentFlagViewSet(viewsets.ModelViewSet):
    """
    API endpoint for admins to handle content flags
    """
    queryset = ContentFlag.objects.all().order_by('-created_at')
    serializer_class = ContentFlagSerializer
    authentication_classes = [KeycloakAuthentication]
    permission_classes = [IsAuthenticated, IsAdmin | IsEditor]
    
    @action(detail=True, methods=['post'], permission_classes=[IsAdmin])
    def resolve(self, request, pk=None):
        content_flag = self.get_object()
        old_status = content_flag.status
        resolution_reason = request.data.get('resolution_reason', 'No reason provided')

        content_flag.status = ContentFlag.FlagStatus.RESOLVED
        content_flag.resolved_at = timezone.now()
        content_flag.resolved_by = request.user
        content_flag.resolution_reason = resolution_reason
        content_flag.save()

        moderation_history = ModerationHistory.objects.create(
            moderator=request.user,
            object_type='ContentFlag',
            object_id=content_flag.id,
            action_taken='resolved',
            before_status=old_status,
            after_status=content_flag.status,
            reason=resolution_reason
        )

        # Broadcast the moderation action
        channel_layer = get_channel_layer()
        if channel_layer:
            async_to_sync(channel_layer.group_send)(
                "admin_logs",
                {
                    "type": "send_log_message",
                    "message": {
                        "type": "moderation_history",
                        "object_type": moderation_history.object_type,
                        "object_id": str(moderation_history.object_id),
                        "action_taken": moderation_history.action_taken,
                        "moderator": str(moderation_history.moderator),
                        "timestamp": str(moderation_history.timestamp),
                        "before_status": moderation_history.before_status,
                        "after_status": moderation_history.after_status,
                        "reason": moderation_history.reason,
                    },
                }
            )

        log_admin_action(request, 'Content Flag Resolution', f'Resolved Content Flag ID: {content_flag.id}', 'success')
        return Response({'status': 'content flag resolved'}, status=status.HTTP_200_OK)

    @action(detail=False, methods=['get'])
    def unresolved(self, request):
        # Get all unresolved flags
        unresolved_flags = ContentFlag.objects.filter(resolved=False).order_by('-created_at')
        page = self.paginate_queryset(unresolved_flags)
        
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
            
        serializer = self.get_serializer(unresolved_flags, many=True)
        return Response(serializer.data)

# Tag API ViewSet
class TagViewSet(viewsets.ModelViewSet):
    """
    API endpoint for tags
    """
    queryset = Tag.objects.all()
    serializer_class = TagSerializer
    # authentication_classes = [KeycloakAuthentication]
    permission_classes = [AllowAny]

    # permission_classes = [IsAuthenticated]

    def get_permissions(self):
        # Allow anyone to view tags, but only admin to create/edit/delete
        if self.action == 'list' or self.action == 'retrieve':
            return [IsAuthenticated()]
        return [IsAuthenticated(), IsAdminOrSuperUser()]

# User Preferences API ViewSet
class UserPreferenceViewSet(viewsets.ModelViewSet):
    """
    API endpoint for user preferences
    """
    serializer_class = UserPreferenceSerializer
    authentication_classes = [KeycloakAuthentication]
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        # Users can only see their own preferences
        return UserPreference.objects.filter(user=self.request.user)
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=False, methods=['post'])
    def update_preferences(self, request):
        """
        Update multiple preferences at once
        
        Expected format:
        [
            {"tag_id": "uuid", "preference_level": 80},
            {"tag_id": "uuid", "preference_level": 50}
        ]
        """
        serializer = UserPreferenceUpdateSerializer(data=request.data, many=True)
        if serializer.is_valid():
            preferences_data = serializer.validated_data
            result = []
            
            for pref_data in preferences_data:
                tag_id = pref_data['tag_id']
                preference_level = pref_data['preference_level']
                
                try:
                    tag = Tag.objects.get(id=tag_id)
                    # Update or create preference
                    preference, created = UserPreference.objects.update_or_create(
                        user=request.user,
                        tag=tag,
                        defaults={'preference_level': preference_level}
                    )
                    result.append({
                        'id': preference.id,
                        'tag_id': tag_id,
                        'tag_name': tag.name,
                        'preference_level': preference_level,
                        'created': created
                    })
                except Tag.DoesNotExist:
                    return Response(
                        {'error': f'Tag with id {tag_id} does not exist'},
                        status=status.HTTP_400_BAD_REQUEST
                    )
            
            return Response(result, status=status.HTTP_200_OK)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

# User Content Interaction API ViewSet
class UserContentInteractionViewSet(viewsets.ModelViewSet):
    """
    API endpoint for tracking user interactions with content
    """
    serializer_class = UserContentInteractionSerializer
    authentication_classes = [KeycloakAuthentication]
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        # Users can only see their own interactions
        return UserContentInteraction.objects.filter(user=self.request.user)
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
        
    @action(detail=False, methods=['post'])
    def batch_record(self, request):
        """
        Record multiple interactions at once
        
        Expected format:
        [
            {"content_type": "NEWS", "content_id": "uuid", "interaction_type": "VIEW", "interaction_value": 1.0},
            {"content_type": "POST", "content_id": "uuid", "interaction_type": "LIKE", "interaction_value": 1.0}
        ]
        """
        serializer = UserContentInteractionSerializer(
            data=request.data, 
            many=True,
            context={'request': request}
        )
        
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

# News API ViewSet
class NewsViewSet(viewsets.ModelViewSet):
    """
    API endpoint for news articles
    """
    queryset = News.objects.all().order_by('-timestamp')
    serializer_class = NewsSerializer
    authentication_classes = [KeycloakAuthentication]
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['title', 'content', 'author', 'source']
    ordering_fields = ['timestamp', 'language']
    
    def get_permissions(self):
        # Allow anyone to view news, but only admin to create/edit/delete
        if self.action == 'list' or self.action == 'retrieve':
            return [IsAuthenticated()]
        return [IsAuthenticated(), IsAdminOrSuperUser()]
    
    @action(detail=False, methods=['get'])
    def personalized(self, request):
        """
        Get personalized news based on user preferences and interaction history
        """
        # Get user preferences
        user_preferences = UserPreference.objects.filter(user=request.user)
        
        # Get user interactions for additional scoring
        user_interactions = UserContentInteraction.objects.filter(
            user=request.user,
            content_type='NEWS',
            timestamp__gte=timezone.now() - timezone.timedelta(days=30)  # Last 30 days
        )
        
        if not user_preferences.exists() and not user_interactions.exists():
            # If user has no preferences or interactions, return most recent news
            news = News.objects.all().order_by('-timestamp')[:10]
            serializer = self.get_serializer(news, many=True)
            return Response(serializer.data)
        
        # Calculate a relevance score for each news article based on user preferences and interactions
        news_with_scores = []
        
        # Create a dictionary of tag preferences for faster lookup
        preference_dict = {str(pref.tag.id): pref.preference_level for pref in user_preferences}
        
        # Create a dictionary of content interactions for faster lookup
        interaction_dict = {}
        for interaction in user_interactions:
            if interaction.content_id not in interaction_dict:
                interaction_dict[interaction.content_id] = []
            interaction_dict[interaction.content_id].append(interaction)
        
        # Get all news articles
        all_news = News.objects.all()
        
        for news in all_news:
            # Initialize scores
            tag_score = 0
            tag_count = 0
            interaction_score = 0
            
            # 1. Calculate tag preference score
            for tag in news.tags.all():
                tag_count += 1
                if str(tag.id) in preference_dict:
                    # Add the preference level as a score component
                    tag_score += preference_dict[str(tag.id)]
            
            # Normalize tag score based on number of tags (if any)
            if tag_count > 0:
                tag_score = tag_score / tag_count
            
            # 2. Calculate interaction score
            if str(news.id) in interaction_dict:
                for interaction in interaction_dict[str(news.id)]:
                    # Weight different interaction types
                    if interaction.interaction_type == 'LIKE':
                        weight = 2.0
                    elif interaction.interaction_type == 'BOOKMARK':
                        weight = 3.0
                    elif interaction.interaction_type == 'SHARE':
                        weight = 2.5
                    elif interaction.interaction_type == 'TIME_SPENT':
                        weight = 1.5
                    else:  # VIEW or CLICK
                        weight = 1.0
                    
                    # Add to interaction score with time decay factor
                    days_old = (timezone.now() - interaction.timestamp).days
                    time_decay = max(0.5, 1.0 - (days_old / 30))  # Decay to 0.5 over 30 days
                    interaction_score += interaction.interaction_value * weight * time_decay
            
            # 3. Calculate time recency score
            time_delta = timezone.now() - news.timestamp
            time_score = max(0, 100 - (time_delta.days * 5))  # Decrease score by 5 per day, min 0
            
            # 4. Calculate final weighted score
            # 50% tag preferences, 30% interactions, 20% recency
            final_score = (tag_score * 0.5) + (interaction_score * 0.3) + (time_score * 0.2)
            
            news_with_scores.append((news, final_score))
        
        # Sort by relevance score (descending)
        news_with_scores.sort(key=lambda x: x[1], reverse=True)
        
        # Return top 20 most relevant articles
        top_news = [item[0] for item in news_with_scores[:20]]
        serializer = self.get_serializer(top_news, many=True)
        
        return Response(serializer.data)

class NewsBulkCreateView(APIView):
    # Restore original security settings
    authentication_classes = [KeycloakAuthentication]
    permission_classes = [IsAuthenticated, HasKeycloakRole]
    required_role = KeycloakRoles.EDITOR
    
    def post(self, request):
        articles = request.data
        created = []
        errors = []
        
        # Log the request details
        print(f"Bulk Create Request received with {len(articles)} articles")
        
        with transaction.atomic():
            for article_data in articles:
                try:
                    # Handle tag_names to tag_ids
                    tag_names = article_data.pop('tag_names', [])
                    tag_ids = []
                    for name in tag_names:
                        try:
                            tag = Tag.objects.get(name=name)
                            tag_ids.append(tag.id)
                        except Tag.DoesNotExist:
                            # Create the tag if it doesn't exist
                            tag = Tag.objects.create(name=name, description=f"{name} news category")
                            tag_ids.append(tag.id)
                            print(f"Created missing tag: {name}")
                    
                    article_data['tag_ids'] = tag_ids
                    
                    serializer = NewsSerializer(data=article_data)
                    if serializer.is_valid():
                        serializer.save()
                        created.append(serializer.data)
                    else:
                        print(f"Validation error for article: {article_data.get('title', 'Unknown')}")
                        print(f"Errors: {serializer.errors}")
                        errors.append({
                            'title': article_data.get('title', 'Unknown'),
                            'errors': serializer.errors
                        })
                except Tag.DoesNotExist as e:
                    errors.append({
                        'title': article_data.get('title', 'Unknown'),
                        'error': f"Tag not found: {str(e)}"
                    })
                except Exception as e:
                    print(f"Error processing article {article_data.get('title', 'Unknown')}: {str(e)}")
                    errors.append({
                        'title': article_data.get('title', 'Unknown'),
                        'error': str(e)
                    })
        
        # Log summary
        print(f"Bulk create completed: {len(created)} articles created, {len(errors)} errors")
        
        response_data = {
            'created': created,
            'errors': errors
        }
        return Response(response_data, status=status.HTTP_201_CREATED if created else status.HTTP_400_BAD_REQUEST)
    
class NewsListView(generics.ListAPIView):
    queryset = News.objects.all()
    serializer_class = NewsSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        queryset = super().get_queryset()
        # Optional filters (e.g., by language or tags)
        language = self.request.query_params.get('language')
        tag = self.request.query_params.get('tags')
        if language:
            queryset = queryset.filter(language=language)
        if tag:
            queryset = queryset.filter(tags__name=tag)
        return queryset.order_by('-timestamp')

class NewsSearchView(generics.ListAPIView):
    queryset = News.objects.all()
    serializer_class = NewsSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        query = self.request.query_params.get('search', '').strip()
        if query:
            return News.objects.filter(
                Q(title__icontains=query) |
                Q(content__icontains=query) |
                Q(tags__name__icontains=query)
            ).distinct().order_by('-timestamp')
        return News.objects.none()  # Return empty queryset for empty search

class TelegramMessageViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows Telegram messages to be viewed.
    """
    queryset = TelegramMessage.objects.all().order_by('-date')
    serializer_class = TelegramMessageSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        queryset = TelegramMessage.objects.all().order_by('-date')
        channel_name = self.request.query_params.get('channel', None)
        
        if channel_name:
            queryset = queryset.filter(channel_name=channel_name)
            
        return queryset
    
    @action(detail=False, methods=['get'])
    def top_channels(self, request):
        """
        Get top Telegram channels based on message count and recency
        """
        # Get limit parameter, default to 10
        limit = int(request.query_params.get('limit', 10))
        
        # Get all channels with their message counts
        from django.db.models import Count, Max
        channels_data = TelegramMessage.objects.values('channel_name')\
            .annotate(
                message_count=Count('id'),
                latest_message=Max('date')
            )\
            .order_by('-message_count')[:limit]
        
        # Get one sample message from each channel
        result = []
        for channel in channels_data:
            # Get the most recent message for this channel
            latest_message = TelegramMessage.objects.filter(
                channel_name=channel['channel_name']
            ).order_by('-date').first()
            
            if latest_message:
                result.append({
                    'channel_name': channel['channel_name'],
                    'message_count': channel['message_count'],
                    'latest_message_date': channel['latest_message'],
                    'latest_message': latest_message.message[:100] + '...' if len(latest_message.message) > 100 else latest_message.message,
                })
        
        return Response(result)

class SocialAuthCallbackView(APIView):
    permission_classes = [AllowAny]
    
    def get(self, request):
        """
        Handle the OAuth callback from Keycloak after social login.
        
        This endpoint processes the authorization code from the OAuth flow
        and exchanges it for tokens.
        """
        try:
            # Get the authorization code from the request
            code = request.GET.get('code')
            if not code:
                return Response(
                    {'error': 'Authorization code is missing from callback'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Get the redirect URI from settings
            redirect_uri = settings.KEYCLOAK_CONFIG['KEYCLOAK_REDIRECT_URI']
            
            # Initialize Keycloak service and token manager
            keycloak_service = KeycloakService()
            token_manager = TokenManager()
            
            # Exchange the code for tokens
            token_result = keycloak_service.process_auth_code(code, redirect_uri)
            
            # Validate the token using TokenManager
            if 'access_token' in token_result:
                try:
                    # Verify token signature and claims
                    token_payload = token_manager.verify_token_signature(token_result['access_token'])
                    
                    # Extract user info directly from the validated token payload
                    user_info = token_manager.extract_user_info(token_payload)
                    
                    # Supplement with additional info from Keycloak if available
                    try:
                        keycloak_user_info = keycloak_service.get_user_info(token_result['access_token'])
                        if keycloak_user_info:
                            # Merge the userinfo, preferring keycloak_user_info values
                            user_info.update(keycloak_user_info)
                    except Exception as e:
                        logger.warning(f"Failed to get additional user info from Keycloak: {str(e)}")
                        # Continue with token payload info only
                        
                    # Check that we have minimum required user info
                    if not user_info.get('sub'):
                        logger.error("Missing sub claim in token and userinfo")
                        raise Exception("Invalid token: missing user identification")
                except Exception as e:
                    logger.error(f"OAuth callback token validation failed: {str(e)}")
                    raise Exception(f"Invalid token received from authorization code exchange")
            else:
                # Get user info from token
                user_info = keycloak_service.get_user_info(token_result['access_token'])
            
            # Get or create the Django user
            user, created = keycloak_service.get_or_create_django_user({
                'keycloak_id': user_info.get('sub'),
                'email': user_info.get('email'),
                'username': user_info.get('preferred_username'),
                'first_name': user_info.get('given_name', ''),
                'last_name': user_info.get('family_name', ''),
            })
            
            # Log the successful OAuth login
            log_admin_action(request, 'OAUTH_LOGIN', f"User authenticated via OAuth: {user.email}", outcome='success')
            
            # Create a response with tokens in URL parameters
            # This allows the frontend to capture the tokens from the URL
            response_url = (
                f"{settings.FRONTEND_URL}/auth/callback?"
                f"access_token={token_result['access_token']}&"
                f"refresh_token={token_result['refresh_token']}&"
                f"expires_in={token_result['expires_in']}"
            )
            
            # Redirect to the frontend with tokens
            return HttpResponseRedirect(response_url)
            
        except Exception as e:
            logger.error(f"OAuth callback error: {str(e)}")
            
            # Redirect to frontend with error
            error_url = f"{settings.FRONTEND_URL}/auth/callback?error={str(e)}"
            return HttpResponseRedirect(error_url)

class EmailVerificationView(APIView):
    permission_classes = [AllowAny]
    
    def get(self, request):
        """
        Handle email verification callback from Keycloak
        Expects query parameters key and code from Keycloak
        """
        key = request.query_params.get('key')
        code = request.query_params.get('code')
        
        if not key or not code:
            # Redirect to frontend with error message
            error_url = f"{settings.FRONTEND_URL}/verify-email?error=invalid_link"
            return HttpResponseRedirect(error_url)
            
        try:
            # Initialize Keycloak service
            keycloak_service = KeycloakService()
            keycloak_service._init_admin_client()
            
            # Forward the verification to Keycloak
            # The Keycloak API doesn't have a direct method for this, so we need to construct a redirect
            verification_url = f"{settings.KEYCLOAK_CONFIG['KEYCLOAK_SERVER_URL']}/realms/{settings.KEYCLOAK_CONFIG['KEYCLOAK_REALM']}/login-actions/verify-email"
            verification_url += f"?key={key}&code={code}"
            
            # Instead of redirecting, which would expose Keycloak URL to the client,
            # we'll make a server-side request and check the result
            response = requests.get(verification_url, allow_redirects=False)
            
            if response.status_code == 302:  # Expected redirect response
                # Email verified successfully, redirect to frontend verification success page
                success_url = f"{settings.FRONTEND_URL}/verify-email?success=true"
                return HttpResponseRedirect(success_url)
            else:
                # Verification failed
                logger.error(f"Email verification failed with status {response.status_code}")
                error_url = f"{settings.FRONTEND_URL}/verify-email?error=expired_link"
                return HttpResponseRedirect(error_url)
                
        except Exception as e:
            logger.error(f"Email verification error: {str(e)}")
            error_url = f"{settings.FRONTEND_URL}/verify-email?error={str(e)}"
            return HttpResponseRedirect(error_url)

@api_view(['GET'])
@permission_classes([AllowAny])
def proxy_image(request):
    """
    Proxy for external images to bypass CORS restrictions.
    Usage: /api/proxy-image/?url=<encoded-image-url>
    """
    image_url = request.GET.get('url')
    if not image_url:
        return HttpResponse("No URL parameter provided", status=400)
    
    try:
        # Use headers to avoid some sites blocking requests
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36',
            'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
            'Referer': request.META.get('HTTP_REFERER', ''),
        }
        
        response = requests.get(image_url, stream=True, headers=headers, timeout=10)
        if response.status_code != 200:
            return HttpResponse(f"Failed to fetch image: {response.status_code}", status=response.status_code)
        
        content_type = response.headers.get('Content-Type', 'image/jpeg')
        
        # Create Django response
        django_response = HttpResponse(response.content, content_type=content_type)
        
        # Add CORS headers
        django_response["Access-Control-Allow-Origin"] = "*"
        django_response["Access-Control-Allow-Methods"] = "GET, OPTIONS"
        django_response["Access-Control-Allow-Headers"] = "Origin, Content-Type, Accept"
        
        # Add caching headers
        django_response["Cache-Control"] = "public, max-age=86400"  # Cache for 1 day
        
        return django_response
    except Exception as e:
        logger.error(f"Error proxying image from {image_url}: {str(e)}")
        return HttpResponse(f"Error fetching image: {str(e)}", status=500)

class UserPermissionsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        roles = getattr(user, 'roles', [])
        return Response({
            'roles': roles,
            'is_superuser': getattr(user, 'is_superuser', False),
            'username': getattr(user, 'user_name', ''),
            'email': getattr(user, 'email', ''),
        })

def custom_exception_handler(exc, context):
    response = exception_handler(exc, context)
    request = context.get('request')
    if response is not None and response.status_code == 403 and request is not None:
        log_permission_denial(
            request,
            action='PERMISSION_DENIED',
            details=f"Global: User denied access to {request.path}"
        )
    return response

# To enable global audit logging, add to your Django settings:
# REST_FRAMEWORK = {
#     'EXCEPTION_HANDLER': 'api.views.custom_exception_handler',
# }

class AdminSettingsViewSet(mixins.ListModelMixin,
                          mixins.RetrieveModelMixin,
                          mixins.UpdateModelMixin,
                          mixins.CreateModelMixin,
                          viewsets.GenericViewSet):
    """
    API endpoint for managing admin settings
    """
    queryset = AdminSettings.objects.all().order_by('-created_at')
    serializer_class = AdminSettingsSerializer
    authentication_classes = [KeycloakAuthentication]
    permission_classes = [IsAuthenticated, IsAdmin]

class ModerationHistoryViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint for viewing moderation history actions
    """
    queryset = ModerationHistory.objects.all().order_by('-timestamp')
    serializer_class = ModerationHistorySerializer
    authentication_classes = [KeycloakAuthentication]
    permission_classes = [IsAuthenticated, IsAdmin]

    def get_queryset(self):
        queryset = super().get_queryset()
        content_type = self.request.query_params.get('content_type')
        content_id = self.request.query_params.get('content_id')
        if content_type:
            queryset = queryset.filter(content_type=content_type)
        if content_id:
            queryset = queryset.filter(content_id=content_id)
        return queryset

def log_auth_event(request, action, details, outcome='failed'):
    from api.models import SystemLog
    import uuid
    user = getattr(request, 'user', None)
    SystemLog.objects.create(
        id=uuid.uuid4(),
        user=user if user and user.is_authenticated else None,
        action=action,
        details=details,
        outcome=outcome,
        ip_address=request.META.get('REMOTE_ADDR', ''),
        user_agent=request.META.get('HTTP_USER_AGENT', '')
    )