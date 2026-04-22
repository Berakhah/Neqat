import time
import json
from django.utils import timezone
from django.utils.deprecation import MiddlewareMixin
from django.conf import settings
import uuid
from .models import SystemLog
import logging
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer

logger = logging.getLogger(__name__)

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
        if not request.path.startswith('/api/'):  # Only log API requests
            return
        
        try:
            request.request_id = str(uuid.uuid4())
            user = request.user if request.user.is_authenticated else None
            ip_address = self.get_client_ip(request)
            user_agent = request.META.get('HTTP_USER_AGENT', '')
            
            log_entry = SystemLog.objects.create(
                request_id=request.request_id,
                user=user,
                action='API Request - Start',
                details=f'{request.method} {request.path}',
                outcome='pending',
                ip_address=ip_address,
                user_agent=user_agent
            )

            # Broadcast initial log entry
            channel_layer = get_channel_layer()
            if channel_layer:
                async_to_sync(channel_layer.group_send)(
                    "admin_logs",
                    {
                        "type": "send_log_message",
                        "message": {
                            "id": str(log_entry.id),
                            "type": "system_log",
                            "request_id": str(log_entry.request_id),
                            "user": str(log_entry.user) if log_entry.user else "Anonymous",
                            "action": log_entry.action,
                            "details": log_entry.details,
                            "outcome": log_entry.outcome,
                            "timestamp": str(log_entry.timestamp),
                            "ip_address": log_entry.ip_address,
                            "user_agent": log_entry.user_agent,
                        },
                    }
                )

        except Exception as e:
            logger.error(f"Error logging request in middleware: {e}")

    def process_response(self, request, response):
        if not request.path.startswith('/api/') or not hasattr(request, 'request_id'):
            return response
        
        try:
            # Create a new log entry for the response, linked by request_id
            user = request.user if request.user.is_authenticated else None
            ip_address = self.get_client_ip(request)
            user_agent = request.META.get('HTTP_USER_AGENT', '')

            log_entry = SystemLog.objects.create(
                request_id=request.request_id,
                user=user,
                action='API Request - End',
                details=f'{request.method} {request.path} | Status: {response.status_code}',
                outcome=f'HTTP {response.status_code}',
                ip_address=ip_address,
                user_agent=user_agent
            )

            # Broadcast updated log entry (now a new entry)
            channel_layer = get_channel_layer()
            if channel_layer:
                async_to_sync(channel_layer.group_send)(
                    "admin_logs",
                    {
                        "type": "send_log_message",
                        "message": {
                            "id": str(log_entry.id),
                            "type": "system_log_update",
                            "request_id": str(log_entry.request_id),
                            "user": str(log_entry.user) if log_entry.user else "Anonymous",
                            "action": log_entry.action,
                            "details": log_entry.details,
                            "outcome": log_entry.outcome,
                            "timestamp": str(log_entry.timestamp),
                            "ip_address": log_entry.ip_address,
                            "user_agent": log_entry.user_agent,
                        },
                    }
                )

        except Exception as e:
            logger.error(f"Error updating SystemLog entry in middleware: {e}")
        
        return response
    
    def _update_user_activity(self, request):
        """Update the user's activity record"""
        if hasattr(request, 'user') and request.user.is_authenticated:
            try:
                from .models import UserActivity
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
        if hasattr(response, 'content') and response.get('Content-Type', '').startswith('application/json'):
            try:
                # Decode the content
                content = response.content.decode('utf-8')
                data = json.loads(content)
                
                # Re-encode it with our custom encoder
                response.content = json.dumps(data, cls=UUIDEncoder).encode('utf-8')
                
                # Update the content length
                response['Content-Length'] = len(response.content)
            except (json.JSONDecodeError, UnicodeDecodeError):
                # If we can't decode the response, leave it as is
                pass
                
        return response 