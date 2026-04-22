import time
import json
from django.utils import timezone
from django.utils.deprecation import MiddlewareMixin
from django.conf import settings
from .models import SystemLog, UserActivity, NeqatUser
import uuid

class SystemLogMiddleware(MiddlewareMixin):
    """
    Middleware to log system events and user activities for the admin panel.
    """
    
    def __init__(self, get_response):
        self.get_response = get_response
        
    def get_client_ip(self, request):
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip
    
    def process_request(self, request):
        request.start_time = time.time()
        return None
    
    def process_response(self, request, response):
        # Skip logging for static and media files
        if request.path.startswith(settings.STATIC_URL) or request.path.startswith(settings.MEDIA_URL):
            return response
            
        # Safely check if user is authenticated
        is_authenticated = hasattr(request, 'user') and request.user is not None and request.user.is_authenticated
            
        # Log specific actions
        if is_authenticated:
            self._update_user_activity(request)
            
            # Log login events
            if request.path.endswith('/login/') and request.method == 'POST' and 200 <= response.status_code < 300:
                self._log_event(request, 'LOGIN', 'User logged in successfully', response)
                
            # Log logout events
            elif request.path.endswith('/logout/') and request.method == 'POST':
                self._log_event(request, 'LOGOUT', 'User logged out', response)
                
            # Log profile updates
            elif request.path.endswith('/user/profile/') and request.method in ['PUT', 'PATCH']:
                self._log_event(request, 'PROFILE_UPDATE', 'User updated their profile', response)
                
        # Log registration events
        elif request.path.endswith('/register/') and request.method == 'POST' and 200 <= response.status_code < 300:
            try:
                data = json.loads(request.body)
                email = data.get('email', 'Unknown')
                details = f"New user registration with email: {email}"
                self._log_event(request, 'REGISTER', details, response, user=None)
            except Exception:
                pass
                
        # Log password reset events
        elif request.path.endswith('/forgot-password/') and request.method == 'POST':
            try:
                data = json.loads(request.body)
                email = data.get('email', 'Unknown')
                details = f"Password reset requested for email: {email}"
                
                # Try to find the associated user
                try:
                    user = NeqatUser.objects.get(email=email)
                    self._log_event(request, 'PASSWORD_RESET', details, response, user=user)
                except NeqatUser.DoesNotExist:
                    self._log_event(request, 'PASSWORD_RESET', details, response, user=None)
            except Exception:
                pass
        
        # Log admin actions for improved tracking
        elif request.path.startswith('/admin/') and is_authenticated and request.user.is_staff:
            if request.method in ['POST', 'PUT', 'DELETE', 'PATCH']:
                path_parts = request.path.strip('/').split('/')
                if len(path_parts) > 2:
                    model_name = path_parts[1]
                    details = f"Admin action on {model_name}: {request.method}"
                    self._log_event(request, 'ADMIN_ACTION', details, response)
        
        return response
    
    def _log_event(self, request, action, details, response, user=None):
        # Get or use provided user
        if user is None and hasattr(request, 'user') and request.user is not None and request.user.is_authenticated:
            user = request.user
            
        # Create the system log entry
        try:
            SystemLog.objects.create(
                user=user,
                action=action,
                details=details,
                ip_address=self.get_client_ip(request),
                user_agent=request.META.get('HTTP_USER_AGENT', '')
            )
        except Exception as e:
            print(f"Error logging event: {str(e)}")
    
    def _update_user_activity(self, request):
        """Update the user's activity record"""
        if hasattr(request, 'user') and request.user is not None and request.user.is_authenticated:
            try:
                user_activity, created = UserActivity.objects.get_or_create(user=request.user)
                user_activity.last_active = timezone.now()
                
                # If this is a login, increment the counter
                if request.path.endswith('/login/') and request.method == 'POST':
                    user_activity.login_count += 1
                    
                # Calculate session duration if available
                if hasattr(request, 'start_time'):
                    duration = time.time() - request.start_time
                    user_activity.session_duration += timezone.timedelta(seconds=duration)
                    
                user_activity.save()
            except Exception as e:
                print(f"Error updating user activity: {str(e)}")

class UUIDEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, uuid.UUID):
            # Return a string representation of the UUID
            return str(obj)
        return super().default(obj)

class UUIDMiddleware:
    """
    Middleware that ensures UUIDs are properly serialized to strings in response content
    """
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        response = self.get_response(request)
        
        # Only process JSON responses
        if hasattr(response, 'content') and response.headers.get('Content-Type', '').startswith('application/json'):
            try:
                # Decode the content
                content = response.content.decode('utf-8')
                data = json.loads(content)
                
                # Re-encode it with our custom encoder
                response.content = json.dumps(data, cls=UUIDEncoder).encode('utf-8')
                
                # Update the content length
                response['Content-Length'] = len(response.content)
            except (json.JSONDecodeError, UnicodeDecodeError):
                pass
                
        return response 