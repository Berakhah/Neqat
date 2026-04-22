from asyncio.log import logger
import re
import urllib
import numpy as np
from sklearn.metrics.pairwise import linear_kernel
from api.news.porter_stemmer import load_index, porter_analyzer
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, viewsets, filters, permissions
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from rest_framework_simplejwt.tokens import RefreshToken
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
from django.db.models import Case, When, IntegerField
from rest_framework import viewsets, permissions
from rest_framework.response import Response
from .models import TelegramMessage
from .serializers import TelegramMessageSerializer
from api.telegram.amh_ir import search, stem_word
from datetime import timedelta
from .models import (
    NeqatUser, PasswordResetToken, SystemLog, UserActivity, 
    AdminSettings, Notification, Post, Comment, ContentFlag, Tag, UserPreference, News, UserContentInteraction,
    TelegramMessage, Translation
)
from .serializers import (
    NeqatUserSerializer, SocialLoginSerializer, ForgotPasswordSerializer, 
    ResetPasswordSerializer, SystemLogSerializer, UserActivitySerializer,
    AdminSettingsSerializer, NotificationSerializer, PostSerializer, 
    CommentSerializer, ContentFlagSerializer, AdminPostSerializer,
    AdminCommentSerializer, TagSerializer, UserPreferenceSerializer,
    UserPreferenceUpdateSerializer, NewsSerializer, UserContentInteractionSerializer,
    TelegramMessageSerializer,TranslationSerializer
)
from rest_framework import serializers
import uuid
from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticatedOrReadOnly, AllowAny
from django.db import transaction
from django.db.models import Case, When, IntegerField
from rest_framework import viewsets, permissions
from rest_framework.response import Response
from .models import TelegramMessage
from .serializers import TelegramMessageSerializer
from api.telegram.amh_ir import search
from google.cloud import translate_v3 as translate
import os 
from dotenv import load_dotenv

load_dotenv()
print(os.getenv("GOOGLE_APPLICATION_CREDENTIALS"))
print(os.getenv("GOOGLE_PROJECT_ID"))

_news_index = None
def get_news_index():
    global _news_index
    if _news_index is None:
        _news_index = load_index()
        _news_index = load_index()      # loads {'ids','vec','mat'} from disk
    return _news_index

# Registration View
class NeqatRegister(APIView):
    def post(self, request):
        serializer = NeqatUserSerializer(data=request.data)
        if serializer.is_valid():
            user = NeqatUser.objects.create_user(
                user_name=serializer.validated_data['user_name'],
                email=serializer.validated_data['email'],
                password=serializer.validated_data['password'],
                first_name=serializer.validated_data.get('first_name', ''),
                last_name=serializer.validated_data.get('last_name', ''),
                profile_image=serializer.validated_data.get('profile_image')
            )
            # Generate JWT tokens for immediate login
            refresh = RefreshToken.for_user(user)
            return Response({
                'message': 'User created successfully',
                'refresh': str(refresh),
                'access': str(refresh.access_token),
                'user': NeqatUserSerializer(user).data
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
 
# Custom JWT Login Serializer
class NeqatTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['user_name'] = user.user_name
        token['is_superuser'] = user.is_superuser
        return token

    def validate(self, attrs):
        # Extract credentials
        username = attrs.get(self.username_field)
        password = attrs.get('password')
        
        # Enforce case-sensitive username comparison
        try:
            # Get the exact user with the exact case-sensitive username
            user = NeqatUser.objects.get(user_name=username)
            
            # Verify password manually
            if not user.check_password(password):
                # Log failed password attempt
                SystemLog.objects.create(
                    id=uuid.uuid4(),
                    action='SECURITY',
                    details=f"Failed login attempt (incorrect password) for username: {username}",
                    ip_address=self.context['request'].META.get('REMOTE_ADDR', ''),
                    user_agent=self.context['request'].META.get('HTTP_USER_AGENT', '')
                )
                print(f"Failed login attempt (incorrect password) for username: {username}")
                raise serializers.ValidationError({"error": "No active account found with the given credentials"})
                
            # Check if user is active
            if not user.is_active:
                SystemLog.objects.create(
                    id=uuid.uuid4(),
                    action='SECURITY',
                    details=f"Login attempt for disabled account: {username}",
                    ip_address=self.context['request'].META.get('REMOTE_ADDR', ''),
                    user_agent=self.context['request'].META.get('HTTP_USER_AGENT', '')
                )
                print(f"Login attempt for disabled account: {username}")
                raise serializers.ValidationError({"error": "This account has been disabled"})
            
            # Set the user for token generation
            self.user = user
            
            # Generate the token using the parent class
            data = {}
            refresh = self.get_token(self.user)
            data['refresh'] = str(refresh)
            data['access'] = str(refresh.access_token)
            data['user'] = NeqatUserSerializer(self.user).data
            
            # Log successful login
            SystemLog.objects.create(
                id=uuid.uuid4(),
                user=user,
                action='LOGIN',
                details=f"User logged in successfully: {username}",
                ip_address=self.context['request'].META.get('REMOTE_ADDR', ''),
                user_agent=self.context['request'].META.get('HTTP_USER_AGENT', '')
            )
            print(f"User logged in successfully: {username}")
            
            return data
            
        except NeqatUser.DoesNotExist:
            # Log the failed attempt
            SystemLog.objects.create(
                id=uuid.uuid4(),
                action='SECURITY',
                details=f"Failed login attempt for non-existent username: {username}",
                ip_address=self.context['request'].META.get('REMOTE_ADDR', ''),
                user_agent=self.context['request'].META.get('HTTP_USER_AGENT', '')
            )
            print(f"Failed login attempt for non-existent username: {username}")
            raise serializers.ValidationError({"error": "No active account found with the given credentials"})
        except serializers.ValidationError:
            # Re-raise validation errors
            raise
        except Exception as e:
            # Log other failures
            SystemLog.objects.create(
                id=uuid.uuid4(),
                action='SECURITY',
                details=f"Failed login attempt for username: {username} - Error: {str(e)}",
                ip_address=self.context['request'].META.get('REMOTE_ADDR', ''),
                user_agent=self.context['request'].META.get('HTTP_USER_AGENT', '')
            )
            print(f"Failed login attempt for username: {username} - Error: {str(e)}")
            raise serializers.ValidationError({"error": "No active account found with the given credentials"})

# Login View
class NeqatLogin(TokenObtainPairView):
    serializer_class = NeqatTokenObtainPairSerializer

# Logout View
class NeqatLogout(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        try:
            # Get the refresh token
            refresh_token = request.data.get('refresh')
            
            # Create a token object
            token = RefreshToken(refresh_token)
            
            # Blacklist the refresh token
            token.blacklist()
            
            # Log the logout
            SystemLog.objects.create(
                id=uuid.uuid4(),
                user=request.user,
                action='LOGOUT',
                details=f"User logged out: {request.user.user_name}",
                ip_address=request.META.get('REMOTE_ADDR', ''),
                user_agent=request.META.get('HTTP_USER_AGENT', '')
            )
            
            return Response({"detail": "Successfully logged out."}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"detail": f"Error logging out: {str(e)}"}, status=status.HTTP_400_BAD_REQUEST)

# User Profile View
class NeqatUserProfile(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        try:
            user = request.user
            serializer = NeqatUserSerializer(user)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except NeqatUser.DoesNotExist:
            return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)
        
    def patch(self, request):
        try:
            user = request.user
            print("Request data:", request.data)
            print("Request FILES:", request.FILES)
            
            serializer = NeqatUserSerializer(user, data=request.data, partial=True, context={'request': request})
            
            if serializer.is_valid():
                print("Validated data:", serializer.validated_data)
                updated_user = serializer.save()
                print("Updated user profile_photo:", updated_user.profile_image)
                print("Serializer data after save:", serializer.data)
                
                return Response({
                    'message': 'User updated successfully',
                    'user': serializer.data
                }, status=status.HTTP_200_OK)
            
            print("Serializer errors:", serializer.errors)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            print("Exception:", str(e))
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    # def patch(self, request):
    #     try:
    #         user = request.user
    #         serializer = NeqatUserSerializer(user, data=request.data, partial=True, context={'request': request})
    #         if serializer.is_valid():
    #             serializer.save()
    #             print(serializer.data, "neqat userr")
    #             return Response({
    #                 'message': 'User updated successfully',
    #                 'user': serializer.data
    #             }, status=status.HTTP_200_OK)
    #         return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    #     except NeqatUser.DoesNotExist:
    #         return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

# Social Login View for Android
class SocialLoginView(APIView):
    def post(self, request):
        serializer = SocialLoginSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        provider = serializer.validated_data['provider']
        access_token = serializer.validated_data['access_token']

        # Map provider to backend
        backends = {
            'google': GoogleOAuth2,
            'facebook': FacebookOAuth2,
            'apple': AppleIdAuth,
        }
        if provider not in backends:
            return Response({'error': 'Invalid provider'}, status=status.HTTP_400_BAD_REQUEST)

        # Load social auth strategy
        try:
            strategy = load_strategy(request)
            backend = backends[provider](strategy=strategy)

            # Authenticate with the access token
            user = backend.auth_complete(access_token=access_token)
            if not user:
                return Response({'error': 'Authentication failed'}, status=status.HTTP_401_UNAUTHORIZED)

            # Check if user exists, or create a new one
            try:
                neqat_user = NeqatUser.objects.get(email=user.email)
            except ObjectDoesNotExist:
                # Create a new user if they don't exist
                username = user.username or user.email.split('@')[0]
                # Ensure username is unique
                base_username = username
                counter = 1
                while NeqatUser.objects.filter(user_name=username).exists():
                    username = f"{base_username}{counter}"
                    counter += 1
                neqat_user = NeqatUser.objects.create_user(
                    user_name=username,
                    email=user.email,
                    first_name=user.first_name or '',
                    last_name=user.last_name or '',
                )

            # Generate JWT tokens
            refresh = RefreshToken.for_user(neqat_user)
            return Response({
                'refresh': str(refresh),
                'access': str(refresh.access_token),
                'user': NeqatUserSerializer(neqat_user).data
            }, status=status.HTTP_200_OK)

        except AuthException as e:
            return Response({'error': f'Authentication error: {str(e)}'}, status=status.HTTP_401_UNAUTHORIZED)
        except Exception as e:
            return Response({'error': f'Unexpected error: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# Forgot Password View
class ForgotPasswordView(APIView):
    def post(self, request):
        serializer = ForgotPasswordSerializer(data=request.data)
        if serializer.is_valid():
            email = serializer.validated_data['email']
            try:
                user = NeqatUser.objects.get(email=email)
            except NeqatUser.DoesNotExist:
                return Response(
                    {'error': 'User with this email does not exist'},
                    status=status.HTTP_404_NOT_FOUND
                )

            # Create a password reset token
            token = PasswordResetToken(user=user)
            token.save()

            # Send email with reset link
            reset_link = f"http://localhost:8000/api/reset-password/?token={token.token}"
            subject = 'Password Reset Request for Neqat'
            message = f"""
            Hello {user.first_name or user.user_name},

            You requested a password reset for your Neqat account. Click the link below to reset your password:
            {reset_link}

            This link will expire in 1 hour.

            If you did not request this, please ignore this email.

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

            return Response(
                {'message': 'Password reset link sent to your email'},
                status=status.HTTP_200_OK
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

# Reset Password View
class ResetPasswordView(APIView):
    def post(self, request):
        serializer = ResetPasswordSerializer(data=request.data)
        if serializer.is_valid():
            token = serializer.validated_data['token']
            new_password = serializer.validated_data['new_password']

            try:
                reset_token = PasswordResetToken.objects.get(token=token)
            except PasswordResetToken.DoesNotExist:
                return Response(
                    {'error': 'Invalid or expired token'},
                    status=status.HTTP_400_BAD_REQUEST
                )

            if reset_token.is_expired():
                reset_token.delete()
                return Response(
                    {'error': 'Token has expired'},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # Update the user's password
            user = reset_token.user
            user.set_password(new_password)
            user.save()

            # Delete the token after use
            reset_token.delete()

            return Response(
                {'message': 'Password reset successfully'},
                status=status.HTTP_200_OK
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

# Admin Panel Views
class IsAdminOrSuperUser(IsAdminUser):
    """
    Custom permission to only allow access to superusers.
    """
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_superuser)

class AdminUserViewSet(viewsets.ModelViewSet):
    """
    API endpoint for admin users to manage all users
    """
    queryset = NeqatUser.objects.all().order_by('-date_joined')
    serializer_class = NeqatUserSerializer
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated, IsAdminOrSuperUser]
    
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
        SystemLog.objects.create(
            id=uuid.uuid4(),
            user=request.user,
            action='ADMIN_ACTION',
            details=f"Admin disabled user: {user.email}",
            ip_address=request.META.get('REMOTE_ADDR', ''),
            user_agent=request.META.get('HTTP_USER_AGENT', '')
        )
        print(f"Admin {request.user.user_name} disabled user: {user.email}")
        
        return Response({'status': 'user disabled'})
    
    @action(detail=True, methods=['post'])
    def enable(self, request, pk=None):
        user = self.get_object()
        user.is_active = True
        user.save()
        
        # Log this admin action
        SystemLog.objects.create(
            id=uuid.uuid4(),
            user=request.user,
            action='ADMIN_ACTION',
            details=f"Admin enabled user: {user.email}",
            ip_address=request.META.get('REMOTE_ADDR', ''),
            user_agent=request.META.get('HTTP_USER_AGENT', '')
        )
        print(f"Admin {request.user.user_name} enabled user: {user.email}")
        
        return Response({'status': 'user enabled'})
    
    @action(detail=True, methods=['post'])
    def reset_password(self, request, pk=None):
        user = self.get_object()
        
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
        SystemLog.objects.create(
            id=uuid.uuid4(),
            user=request.user,
            action='ADMIN_ACTION',
            details=f"Admin initiated password reset for user: {user.email}",
            ip_address=request.META.get('REMOTE_ADDR', ''),
            user_agent=request.META.get('HTTP_USER_AGENT', '')
        )
        print(f"Admin {request.user.user_name} initiated password reset for user: {user.email}")
        
        return Response({'status': 'password reset email sent'})
    
    @action(detail=True, methods=['post'])
    def make_staff(self, request, pk=None):
        if not request.user.is_superuser:
            return Response({'error': 'Only superusers can promote users to staff'}, 
                           status=status.HTTP_403_FORBIDDEN)
                           
        user = self.get_object()
        user.is_staff = True
        user.save()
        
        # Log this admin action
        SystemLog.objects.create(
            id=uuid.uuid4(),
            user=request.user,
            action='ADMIN_ACTION',
            details=f"Admin promoted user to staff: {user.email}",
            ip_address=request.META.get('REMOTE_ADDR', ''),
            user_agent=request.META.get('HTTP_USER_AGENT', '')
        )
        print(f"Admin {request.user.user_name} promoted user to staff: {user.email}")
        
        return Response({'status': 'user promoted to staff'})

class SystemLogViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint for viewing system logs
    """
    queryset = SystemLog.objects.all().order_by('-timestamp')
    serializer_class = SystemLogSerializer
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated, IsAdminOrSuperUser]
    
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

class UserActivityViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint for viewing user activity
    """
    queryset = UserActivity.objects.all().order_by('-last_active')
    serializer_class = UserActivitySerializer
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated, IsAdminOrSuperUser]

class NotificationViewSet(viewsets.ModelViewSet):
    """
    API endpoint for managing notifications
    """
    queryset = Notification.objects.all().order_by('-created_at')
    serializer_class = NotificationSerializer
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated, IsAdminOrSuperUser]
    
    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)
    
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
        except Exception as e:
            return Response(
                {'error': f'Failed to send notification: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        
        return Response({'status': 'notification sent'})

class AdminDashboardView(APIView):
    """
    API endpoint for admin dashboard analytics
    """
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated, IsAdminOrSuperUser]
    
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
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
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
        SystemLog.objects.create(
            id=uuid.uuid4(),
            user=self.request.user,
            action='CONTENT',
            details=f"User created new post: {serializer.instance.title}",
            ip_address=self.request.META.get('REMOTE_ADDR', ''),
            user_agent=self.request.META.get('HTTP_USER_AGENT', '')
        )

class CommentViewSet(viewsets.ModelViewSet):
    serializer_class = CommentSerializer
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['content']
    ordering_fields = ['created_at']

    def get_queryset(self):
        news_id = self.request.query_params.get('news_id')
        telegram_message_id = self.request.query_params.get('telegram_message_id')

        if not self.request.user.is_staff:
            queryset = Comment.objects.filter(
                Q(status='APPROVED') |
                Q(created_by=self.request.user)
            )
        else:
            queryset = Comment.objects.all()

        if news_id:
            queryset = queryset.filter(news_id=news_id, parent_comment__isnull=True)
        if telegram_message_id:
            queryset = queryset.filter(telegram_message_id=telegram_message_id, parent_comment__isnull=True)

        print(f"CommentViewSet: user={self.request.user}, news_id={news_id}, telegram_message_id={telegram_message_id}, queryset_count={queryset.count()}")
        for comment in queryset:
            print(f"Comment: id={comment.id}, status={comment.status}, created_by={comment.created_by}, news_id={comment.news_id}, telegram_message_id={comment.telegram_message_id}")

        return queryset.order_by('-created_at')

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

        comment = serializer.instance
        content_type = 'Post' if comment.post else 'News' if comment.news else 'TelegramMessage'
        content_title = (
            comment.post.title if comment.post
            else comment.news.title if comment.news
            else comment.telegram_message.message[:50]
        )
        action = 'REPLY' if comment.parent_comment else 'COMMENT'

        SystemLog.objects.create(
            id=uuid.uuid4(),
            user=self.request.user,
            action='CONTENT',
            details=f"User added {action.lower()} to {content_type}: {content_title}",
            ip_address=self.request.META.get('REMOTE_ADDR', ''),
            user_agent=self.request.META.get('HTTP_USER_AGENT', '')
        )

    @action(detail=False, methods=['get'])
    def view_count(self, request):
        news_id = request.query_params.get('news_id')
        telegram_message_id = request.query_params.get('telegram_message_id')

        if not (news_id or telegram_message_id):
            return Response({'error': 'news_id or telegram_message_id parameter is required'}, status=status.HTTP_400_BAD_REQUEST)

        if news_id:
            view_count = UserContentInteraction.objects.filter(
                content_type='NEWS',
                content_id=news_id,
                interaction_type='VIEW'
            ).count()
        else:
            view_count = UserContentInteraction.objects.filter(
                content_type='TELEGRAM',
                content_id=telegram_message_id,
                interaction_type='VIEW'
            ).count()

        return Response({'view_count': view_count}, status=status.HTTP_200_OK)
class CommentListCreateView(generics.ListCreateAPIView):
    serializer_class = CommentSerializer
    permission_classes = [IsAuthenticated]
    authentication_classes = [JWTAuthentication]

    def get_queryset(self):
        news_id = self.request.query_params.get('news_id')
        telegram_message_id = self.request.query_params.get('telegram_message_id')

        queryset = Comment.objects.filter(
            Q(status='APPROVED') |
            Q(created_by=self.request.user)
        )

        if news_id:
            queryset = queryset.filter(news_id=news_id, parent_comment__isnull=True)
        if telegram_message_id:
            queryset = queryset.filter(telegram_message_id=telegram_message_id, parent_comment__isnull=True)

        return queryset.order_by('-created_at')

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)
        comment = serializer.instance
        content_type = 'Post' if comment.post else 'News' if comment.news else 'TelegramMessage'
        content_title = (
            comment.post.title if comment.post
            else comment.news.title if comment.news
            else comment.telegram_message.message[:50]
        )
        action = 'REPLY' if comment.parent_comment else 'COMMENT'

        SystemLog.objects.create(
            id=uuid.uuid4(),
            user=self.request.user,
            action='CREATE_COMMENT',
            details=f"User added {action.lower()} to {content_type}: {content_title}",
            ip_address=self.request.META.get('REMOTE_ADDR', ''),
            user_agent=self.request.META.get('HTTP_USER_AGENT', '')
        )
class ContentFlagViewSet(viewsets.ModelViewSet):
    """
    API endpoint for users to flag inappropriate content
    """
    serializer_class = ContentFlagSerializer
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    
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
        
        # Log the flagging action
        SystemLog.objects.create(
            id=uuid.uuid4(),
            user=self.request.user,
            action='SECURITY',
            details=f"User flagged {content_type} content for reason: {reason}",
            ip_address=self.request.META.get('REMOTE_ADDR', ''),
            user_agent=self.request.META.get('HTTP_USER_AGENT', '')
        )

# Admin Content Moderation ViewSets

class AdminPostViewSet(viewsets.ModelViewSet):
    """
    API endpoint for admins to moderate posts
    """
    queryset = Post.objects.all().order_by('-created_at')
    serializer_class = AdminPostSerializer
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated, IsAdminOrSuperUser]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['title', 'content', 'created_by__user_name', 'created_by__email']
    ordering_fields = ['created_at', 'updated_at', 'status']
    
    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        post = self.get_object()
        post.status = 'APPROVED'
        post.moderated_by = request.user
        post.moderated_at = timezone.now()
        post.save()
        
        # Log this admin action
        SystemLog.objects.create(
            id=uuid.uuid4(),
            user=request.user,
            action='ADMIN_ACTION',
            details=f"Admin approved post: {post.title}",
            ip_address=request.META.get('REMOTE_ADDR', ''),
            user_agent=request.META.get('HTTP_USER_AGENT', '')
        )
        
        return Response({'status': 'post approved'})
    
    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        post = self.get_object()
        notes = request.data.get('notes', '')
        
        post.status = 'REJECTED'
        post.moderation_notes = notes
        post.moderated_by = request.user
        post.moderated_at = timezone.now()
        post.save()
        
        # Log this admin action
        SystemLog.objects.create(
            id=uuid.uuid4(),
            user=request.user,
            action='ADMIN_ACTION',
            details=f"Admin rejected post: {post.title}",
            ip_address=request.META.get('REMOTE_ADDR', ''),
            user_agent=request.META.get('HTTP_USER_AGENT', '')
        )
        
        return Response({'status': 'post rejected'})
    
    @action(detail=True, methods=['get'])
    def pending(self, request):
        # Get all pending and flagged posts
        pending_posts = Post.objects.filter(Q(status='PENDING') | Q(status='FLAGGED')).order_by('-created_at')
        page = self.paginate_queryset(pending_posts)
        
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
            
        serializer = self.get_serializer(pending_posts, many=True)
        return Response(serializer.data)

class AdminCommentViewSet(viewsets.ModelViewSet):
    """
    API endpoint for admins to moderate comments
    """
    queryset = Comment.objects.all().order_by('-created_at')
    serializer_class = AdminCommentSerializer
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated, IsAdminOrSuperUser]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['content', 'created_by__user_name', 'created_by__email']
    ordering_fields = ['created_at', 'updated_at', 'status']
    
    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        comment = self.get_object()
        comment.status = 'APPROVED'
        comment.moderated_by = request.user
        comment.moderated_at = timezone.now()
        comment.save()
        
        # Log this admin action
        SystemLog.objects.create(
            id=uuid.uuid4(),
            user=request.user,
            action='ADMIN_ACTION',
            details=f"Admin approved comment on post: {comment.post.title}",
            ip_address=request.META.get('REMOTE_ADDR', ''),
            user_agent=request.META.get('HTTP_USER_AGENT', '')
        )
        
        return Response({'status': 'comment approved'})
    
    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        comment = self.get_object()
        notes = request.data.get('notes', '')
        
        comment.status = 'REJECTED'
        comment.moderation_notes = notes
        comment.moderated_by = request.user
        comment.moderated_at = timezone.now()
        comment.save()
        
        # Log this admin action
        SystemLog.objects.create(
            id=uuid.uuid4(),
            user=request.user,
            action='ADMIN_ACTION',
            details=f"Admin rejected comment on post: {comment.post.title}",
            ip_address=request.META.get('REMOTE_ADDR', ''),
            user_agent=request.META.get('HTTP_USER_AGENT', '')
        )
        
        return Response({'status': 'comment rejected'})
    
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

class AdminContentFlagViewSet(viewsets.ModelViewSet):
    """
    API endpoint for admins to handle content flags
    """
    queryset = ContentFlag.objects.all().order_by('-created_at')
    serializer_class = ContentFlagSerializer
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated, IsAdminOrSuperUser]
    
    @action(detail=True, methods=['post'])
    def resolve(self, request, pk=None):
        flag = self.get_object()
        notes = request.data.get('notes', '')
        
        flag.resolved = True
        flag.resolved_by = request.user
        flag.resolved_at = timezone.now()
        flag.resolution_notes = notes
        flag.save()
        
        # Log this admin action
        SystemLog.objects.create(
            id=uuid.uuid4(),
            user=request.user,
            action='ADMIN_ACTION',
            details=f"Admin resolved flag for {flag.content_type} content",
            ip_address=request.META.get('REMOTE_ADDR', ''),
            user_agent=request.META.get('HTTP_USER_AGENT', '')
        )
        
        return Response({'status': 'flag resolved'})
    
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
    # authentication_classes = [JWTAuthentication]
    # permission_classes = [AllowAny]

    # # permission_classes = [IsAuthenticated]

    # def get_permissions(self):
    #     # Allow anyone to view tags, but only admin to create/edit/delete
    #     if self.action == 'list' or self.action == 'retrieve':
    #         return [IsAuthenticated()]
    #     return [IsAuthenticated(), IsAdminOrSuperUser()]
    
    @action(detail=False, methods=['post'])
    def bulk_create(self, request):
        """
        Create multiple tags at once, skipping duplicates
        
        Expected format:
        [
            {"name": "tag1"},
            {"name": "tag2"}
        ]
        """
        serializer = TagSerializer(data=request.data, many=True)
        if serializer.is_valid():
            # Get all validated tag names
            tag_names = [item['name'] for item in serializer.validated_data]
            
            # Find existing tags with these names
            existing_tags = self.get_queryset().filter(name__in=tag_names)
            existing_names = set(tag.name for tag in existing_tags)
            
            # Filter out the data for tags that already exist
            new_data = [item for item in serializer.validated_data if item['name'] not in existing_names]
            
            # Create only the new tags
            created_tags = []
            for item in new_data:
                tag = self.get_serializer().Meta.model(**item)
                tag.save()
                created_tags.append(tag)
            
            # Serialize both existing and newly created tags for the response
            result = {
                "created": self.get_serializer(created_tags, many=True).data,
                "existing": self.get_serializer(existing_tags, many=True).data,
                "skipped": list(existing_names)
            }
            
            return Response(result, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

# User Preferences API ViewSet
class UserPreferenceViewSet(viewsets.ModelViewSet):
    """
    API endpoint for user preferences
    """
    serializer_class = UserPreferenceSerializer
    authentication_classes = [JWTAuthentication]
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
# ... other imports ...
import logging

logger = logging.getLogger(__name__)

class UserContentInteractionViewSet(viewsets.ModelViewSet):
    serializer_class = UserContentInteractionSerializer
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        logger.info(f"get_queryset called for user: {self.request.user} (ID: {self.request.user.id})")
        if not self.request.user.is_authenticated:
            logger.error("User is not authenticated")
            return UserContentInteraction.objects.none()
        return UserContentInteraction.objects.filter(user=self.request.user)

    def list(self, request, *args, **kwargs):
        logger.info(f"Listing interactions for user: {request.user} (ID: {request.user.id})")
        queryset = self.get_queryset()
        content_type = request.query_params.get('content_type')
        content_id = request.query_params.get('content_id')
        interaction_type = request.query_params.get('interaction_type')

        if content_type:
            queryset = queryset.filter(content_type=content_type)
        if content_id:
            queryset = queryset.filter(content_id=content_id)
        if interaction_type:
            queryset = queryset.filter(interaction_type=interaction_type)

        logger.info(f"Filtered queryset count: {queryset.count()} for content_id: {content_id}")
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

    def perform_create(self, serializer):
        logger.info(f"Creating interaction for user: {self.request.user} (ID: {self.request.user.id})")
        serializer.save(user=self.request.user)

    @action(detail=False, methods=['delete'])
    def delete_interaction(self, request):
        logger.info(f"delete_interaction called for user: {request.user} (ID: {request.user.id})")
        content_type = request.query_params.get('content_type')
        content_id = request.query_params.get('content_id')
        interaction_type = request.query_params.get('interaction_type')

        if not all([content_type, content_id, interaction_type]):
            logger.error("Missing required query parameters")
            return Response(
                {'error': 'content_type, content_id, and interaction_type are required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            interaction = UserContentInteraction.objects.filter(
                user=request.user,
                content_type=content_type,
                content_id=content_id,
                interaction_type=interaction_type
            ).first()

            if not interaction:
                logger.info(f"No interaction found for user: {request.user}, content_id: {content_id}")
                return Response(
                    {'error': 'Interaction not found'},
                    status=status.HTTP_404_NOT_FOUND
                )

            interaction.delete()
            logger.info(f"Deleted interaction for user: {request.user}, content_id: {content_id}")
            return Response(status=status.HTTP_204_NO_CONTENT)
        except Exception as e:
            logger.error(f"Error in delete_interaction: {str(e)}")
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['post'])
    def batch_record(self, request):
        logger.info(f"Batch recording interactions for user: {request.user}")
        serializer = UserContentInteractionSerializer(
            data=request.data,
            many=True,
            context={'request': request}
        )
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        logger.error(f"Batch record failed: {serializer.errors}")
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST) 
class NewsViewSet(viewsets.ModelViewSet):
    queryset               = News.objects.all().order_by('-timestamp')
    serializer_class       = NewsSerializer
    authentication_classes = [JWTAuthentication]
    permission_classes     = [permissions.IsAuthenticated]
    filter_backends        = []
    ordering_fields        = ['timestamp', 'language']

    def get_queryset(self):
        qs = super().get_queryset()
        tags = self.request.query_params.get('tags')
        if tags:
            # split comma-list, strip whitespace
            wanted = [t.strip() for t in tags.split(',') if t.strip()]
            # filter any article having *any* of those tags
            qs = qs.filter(tags__name__in=wanted).distinct()
        return qs

    def list(self, request, *args, **kwargs):
        # If no `search` and no `url` query param, defer to DRF's default .list()
        if 'search' not in request.query_params and 'url' not in request.query_params:
            return super().list(request, *args, **kwargs)

        # Otherwise we have either a search or a url filter; grab and stem `search`
        original = request.query_params.get('search', '').strip()
        if re.search(r'[A-Za-z]', original):
            stems = porter_analyzer(original)
        else:
            stems = stem_word(original)

        # --- Custom full-text “search” path ---
        if original:
            ids, vec, mat = get_news_index().values()
            q_vec  = vec.transform([original])
            scores = linear_kernel(q_vec, mat).flatten()

            # rank by descending score, drop non-positive
            ranked  = np.argsort(scores)[::-1]
            ordered = [ids[i] for i in ranked if scores[i] > 0]
            total_count = len(ordered)

            if not ordered:
                return Response({
                    'original_query': original,
                    'stemmed_query': stems,
                    'count': 0,
                    'results': []
                })

            preserved = Case(
                *[When(id=pk, then=pos) for pos, pk in enumerate(ordered)],
                output_field=IntegerField()
            )
            qs = News.objects.filter(id__in=ordered).annotate(rank=preserved).order_by('rank')

            page       = self.paginate_queryset(qs)
            serializer = self.get_serializer(page or qs, many=True)
            return Response({
                'original_query': original,
                'stemmed_query': stems,
                'count': total_count,
                'results': serializer.data
            })

        # --- Custom URL-filter path ---
        url = request.query_params.get('url')
        if url:
            try:
                decoded  = urllib.parse.unquote(url)
                logger.info(f"NewsViewSet: Filtering by url={decoded}")
                filtered = self.queryset.filter(url=decoded)
                serializer = self.get_serializer(filtered, many=True)
                return Response({
                    'original_query': original,
                    'stemmed_query': stems,
                    'count': filtered.count(),
                    'results': serializer.data
                }, status=status.HTTP_200_OK)
            except Exception:
                return Response({
                    'original_query': original,
                    'stemmed_query': stems,
                    'count': 0,
                    'results': []
                }, status=status.HTTP_200_OK)

        # Fallback (should never hit this)
        return super().list(request, *args, **kwargs)



    def get_permissions(self):
        if self.action in ('list', 'retrieve'):
            return [AllowAny()]
        return [permissions.IsAuthenticated(), permissions.IsAdminUser()]

    @action(detail=False, methods=['get'])
    def personalized(self, request):
        prefs = UserPreference.objects.filter(user=request.user)
        inter = UserContentInteraction.objects.filter(
            user=request.user,
            content_type='NEWS',
            timestamp__gte=timezone.now() - timezone.timedelta(days=30)
        )

        if not prefs.exists() and not inter.exists():
            recent = News.objects.all().order_by('-timestamp')[:10]
            return Response(self.get_serializer(recent, many=True).data)

        pref_dict = {str(p.tag.id): p.preference_level for p in prefs}
        interact  = {}
        for ix in inter:
            interact.setdefault(ix.content_id, []).append(ix)

        scored = []
        for article in News.objects.all():
            tags = list(article.tags.all())
            tag_score = sum(pref_dict.get(str(t.id), 0) for t in tags) / (len(tags) or 1)
            i_score = 0
            for ix in interact.get(str(article.id), []):
                w = {'LIKE':2, 'BOOKMARK':3, 'SHARE':2.5, 'TIME_SPENT':1.5}.get(ix.interaction_type, 1)
                days = (timezone.now() - ix.timestamp).days
                decay = max(0.5, 1 - days/30)
                i_score += ix.interaction_value * w * decay
            age = (timezone.now() - article.timestamp).days
            time_score = max(0, 100 - age*5)
            final = (tag_score*0.5) + (i_score*0.3) + (time_score*0.2)
            scored.append((article, final))

        top = [a for a,_ in sorted(scored, key=lambda x: x[1], reverse=True)[:20]]
        return Response(self.get_serializer(top, many=True).data)
    
class NewsBulkCreateView(generics.CreateAPIView):
    authentication_classes = []  # Remove authentication
    permission_classes = [AllowAny]  # Allow unauthenticated access
    serializer_class = NewsSerializer  # Add serializer class
    
    def create(self, request, *args, **kwargs):
        articles = request.data
        created_articles = []
        errors = []
        
        with transaction.atomic():
            for article_data in articles:
                try:
                    # Handle tag_names to tag_ids
                    tag_names = article_data.pop('tag_names', [])
                    tag_ids = []
                    
                    # Create tags if they don't exist
                    for name in tag_names:
                        tag, _ = Tag.objects.get_or_create(
                            name=name,
                            defaults={'description': f'News category: {name}'}
                        )
                        tag_ids.append(str(tag.id))
                    
                    article_data['tag_ids'] = tag_ids
                    
                    # Ensure content is not blank
                    if not article_data.get('content'):
                        article_data['content'] = article_data.get('description', '')
                    
                    serializer = self.get_serializer(data=article_data)
                    if serializer.is_valid():
                        serializer.save()
                        created_articles.append(serializer.data)
                    else:
                        errors.append({
                            'title': article_data.get('title', 'Unknown'),
                            'errors': serializer.errors
                        })
                except Exception as e:
                    errors.append({
                        'title': article_data.get('title', 'Unknown'),
                        'error': str(e)
                    })
        
        response_data = {
            'created': created_articles,
            'errors': errors
        }
        return Response(response_data, status=status.HTTP_201_CREATED if created_articles else status.HTTP_400_BAD_REQUEST)
    
class NewsListView(generics.ListAPIView):
    """
    GET /api/news/
    Supports:
      • ?tags=top_headlines          → only articles tagged “top_headlines”
      • ?tags=world,science         → articles tagged either “world” OR “science”
      • if no tags=… supplied, returns everything
    Returns:
      {
        "original_query": "",
        "stemmed_query": [],
        "count": <total_articles>,
        "results": [ … ]
      }
    """
    serializer_class = NewsSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        qs = News.objects.all()
        tags = self.request.query_params.get('tags')
        if tags:
            # split on commas and strip whitespace
            wanted = [t.strip() for t in tags.split(',') if t.strip()]
            # filter any article having any of those tags
            qs = qs.filter(tags__name__in=wanted).distinct()
        return qs

    def list(self, request, *args, **kwargs):
        # apply tag filtering + ordering
        qs = self.get_queryset().order_by('-timestamp')

        # standard ListAPIView pagination
        page = self.paginate_queryset(qs)
        serializer = self.get_serializer(page or qs, many=True)

        return Response({
            'original_query': '',
            'stemmed_query': [],
            'count': qs.count(),
            'results': serializer.data
        }, status=status.HTTP_200_OK)
class NewsSearchView(generics.ListAPIView):
    """
    GET /api/news/search/?search=<q>
    Returns:
      {
        "original_query": <string>,
        "stemmed_query":  <string>,   # empty string if no query
        "results":       [ … ]
      }
    """
    serializer_class = NewsSerializer
    permission_classes = [AllowAny]

    def list(self, request, *args, **kwargs):
        original_query = request.query_params.get('search', '').strip()

        # stem the query into a list, then join to a single string
        stems = stem_word(original_query) if original_query else []
        stemmed_query = ' '.join(stems) if stems else ''

        # build the queryset
        if original_query:
            qs = News.objects.filter(
                Q(title__icontains=original_query) |
                Q(content__icontains=original_query) |
                Q(tags__name__icontains=original_query)
            ).distinct().order_by('-timestamp')
        else:
            qs = News.objects.none()

        # pagination
        page = self.paginate_queryset(qs)
        serializer = self.get_serializer(page or qs, many=True)

        return Response({
            'original_query': original_query,
            'stemmed_query': stemmed_query,
            'results': serializer.data
        }, status=status.HTTP_200_OK)
    

# TelegramMessageViewSet with conditional stemming
class TelegramMessageViewSet(viewsets.ModelViewSet):
    """
    GET /api/telegram-messages
      ?search=<term>
      &model=<tfidf|bm25|qlm>
      &method=<default|translate>
      &top_k=<N>
    """
    serializer_class       = TelegramMessageSerializer
    authentication_classes = [JWTAuthentication]
    permission_classes     = [permissions.IsAuthenticated]

    def get_queryset(self):
        qs      = TelegramMessage.objects.all().order_by('-date')
        term    = self.request.query_params.get('search')
        model   = self.request.query_params.get('model',  'tfidf').lower()
        method  = self.request.query_params.get('method', 'default').lower()
        top_k   = int(self.request.query_params.get('top_k', 50))

        if not term:
            return qs

        # 1) Detect if the user typed any Latin letters
        has_latin = bool(re.search(r'[A-Za-z]', term))

        # 2) Should we search the English index?
        use_english_index = has_latin or (method == 'translate')

        # 3) Only actually call Google Translate when they explicitly ask AND it's Amharic
        do_translate = (method == 'translate') and not has_latin

        # 4) Build the query string to feed into search()
        q = term
        if do_translate:
            client = translate.TranslationServiceClient()
            proj   = os.getenv("GOOGLE_PROJECT_ID")
            parent = f"projects/{proj}/locations/global"
            resp   = client.translate_text(
                request={
                    "parent":                parent,
                    "contents":             [term],
                    "mime_type":            "text/plain",
                    "source_language_code": "am",
                    "target_language_code": "en",
                }
            )
            q = resp.translations[0].translated_text

        # 5) Run the IR search against the correct index
        hits = search(
            q,
            top_k=top_k,
            model=model,
            translate_=use_english_index
        )
        if not hits:
            return qs.none()

        # 6) Preserve the hit ordering
        ids, _scores = zip(*hits)
        ordering = [When(id=_id, then=pos) for pos, _id in enumerate(ids)]

        return (
            qs
            .filter(id__in=ids)
            .annotate(rank=Case(*ordering, output_field=IntegerField()))
            .order_by('rank')
        )

    def list(self, request, *args, **kwargs):
        original = request.query_params.get('search', '').strip()
        model    = request.query_params.get('model',  'tfidf').lower()
        method   = request.query_params.get('method', 'default').lower()

        has_latin        = bool(re.search(r'[A-Za-z]', original))
        use_english_index = has_latin or (method == 'translate')
        do_translate     = (method == 'translate') and not has_latin

        # Prepare stemmed_query and optionally capture the translated text
        if do_translate and original:
            client = translate.TranslationServiceClient()
            proj   = os.getenv("GOOGLE_PROJECT_ID")
            parent = f"projects/{proj}/locations/global"
            resp   = client.translate_text(
                request={
                    "parent":                parent,
                    "contents":             [original],
                    "mime_type":            "text/plain",
                    "source_language_code": "am",
                    "target_language_code": "en",
                }
            )
            translated_query = resp.translations[0].translated_text
            stems            = porter_analyzer(translated_query)
        else:
            translated_query = None
            if use_english_index:
                stems = porter_analyzer(original or "")
            else:
                stems = stem_word(original or "")

        qs    = self.get_queryset()
        count = qs.count()
        page  = self.paginate_queryset(qs)
        data  = self.get_serializer(page or qs, many=True).data

        resp = {
            'original_query': original,
            'stemmed_query':  stems,
            'model_used':     model,
            'method_used':    method,
            'count':          count,
            'results':        data,
        }
        if translated_query is not None:
            resp['translated_query'] = translated_query

        return Response(resp)
class TranslateTextView(APIView):
    def post(self, request):
        print(os.getenv("GOOGLE_APPLICATION_CREDENTIALS"))
        print(os.getenv("GOOGLE_PROJECT_ID"))
        original_text = request.data.get('text')
        target_language = request.data.get('target_language', 'en')  # Default to Amharic
        source_language = request.data.get('source_language', 'auto')

        if not original_text:
            return Response({'error': 'Text is required'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            # Load project ID from environment variable
            project_id = "subtle-proxy-457512-i0"
            if not project_id:
                return Response({'error': 'Google project ID not configured'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

            # Initialize Google Translate client (uses GOOGLE_APPLICATION_CREDENTIALS)
            client = translate.TranslationServiceClient()

            # Set parent for translation request
            location = "global"
            parent = f"projects/{project_id}/locations/{location}"

            # Perform translation
            response = client.translate_text(
                request={
                    "parent": parent,
                    "contents": [original_text],
                    "mime_type": "text/plain",
                    "source_language_code": source_language if source_language != 'auto' else None,
                    "target_language_code": target_language,
                }
            )

            translated_text = response.translations[0].translated_text

            # Save to database
            translation = Translation(
                original_text=original_text,
                translated_text=translated_text,
                source_language=source_language,
                target_language=target_language
            )
            translation.save()

            # Serialize and return response
            serializer = TranslationSerializer(translation)
            return Response(serializer.data, status=status.HTTP_201_CREATED)

        except Exception as e:
            print(f"Error Details: {str(e)}")  # Debug: Print full error
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)   
        

class TranslationDetailView(APIView):
    def get_object(self, pk):
        try:
            return Translation.objects.get(pk=pk)
        except Translation.DoesNotExist:
            return None

    def get(self, request, pk):
        """
        Retrieve a single translation by ID.
        """
        translation = self.get_object(pk)
        if not translation:
            return Response({'error': 'Translation not found'}, status=status.HTTP_404_NOT_FOUND)
        serializer = TranslationSerializer(translation)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def put(self, request, pk):
        """
        Update an existing translation.
        """
        translation = self.get_object(pk)
        if not translation:
            return Response({'error': 'Translation not found'}, status=status.HTTP_404_NOT_FOUND)

        serializer = TranslationSerializer(translation, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk):
        """
        Delete a translation by ID.
        """
        translation = self.get_object(pk)
        if not translation:
            return Response({'error': 'Translation not found'}, status=status.HTTP_404_NOT_FOUND)
        translation.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    def list(self, request, *args, **kwargs):
        # Get the original query
        original_query = self.request.query_params.get('search', '').strip()
        # Stem the query
        stemmed_query = stem_word(original_query) if original_query else ''

        # Get the queryset
        queryset = self.get_queryset()

        # Calculate the total count of matching items
        total_count = queryset.count()

        # Paginate if needed
        page = self.paginate_queryset(queryset)
        serializer = self.get_serializer(page or queryset, many=True)

        # Return response with original query, stemmed query, total count, and results
        return Response({
            'original_query': original_query,
            'stemmed_query': stemmed_query,
            'total_count': total_count,
            'results': serializer.data
        }, status=status.HTTP_200_OK)
    
class TelegramMessageLookupView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request):
        sender_id = request.query_params.get('sender_id')
        date = request.query_params.get('date')
        channel_name = request.query_params.get('channel_name')

        if not (sender_id and date and channel_name):
            return Response(
                {'error': 'sender_id, date, and channel_name are required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            telegram_message = TelegramMessage.objects.get(
                sender_id=sender_id,
                date=date,
                channel_name=channel_name
            )
            serializer = TelegramMessageSerializer(telegram_message)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except TelegramMessage.DoesNotExist:
            return Response(
                {'error': 'Telegram message not found'},
                status=status.HTTP_404_NOT_FOUND
            )
