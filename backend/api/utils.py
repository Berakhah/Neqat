import uuid
import json
import logging
from .models import AdminLog
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer

logger = logging.getLogger(__name__)

def log_permission_denial(request, action, details):
    user = getattr(request, 'user', None)
    if user and user.is_authenticated:
        SystemLog.objects.create(
            id=uuid.uuid4(),
            user=user,
            action=action,
            details=details,
            outcome='denied',
            ip_address=request.META.get('REMOTE_ADDR', ''),
            user_agent=request.META.get('HTTP_USER_AGENT', '')
        )

def log_admin_action(
    request,
    action,
    details,
    outcome,
    object_type=None,
    object_id=None,
    action_taken=None,
    moderator=None,
    before_status=None,
    after_status=None,
    reason=None,
):
    try:
        user = request.user if request.user.is_authenticated else None
        ip_address = request.META.get('REMOTE_ADDR', '')
        user_agent = request.META.get('HTTP_USER_AGENT', '')

        log_entry = AdminLog.objects.create(
            user=user.username if user else "Anonymous",
            action=action,
            details=details,
            outcome=outcome,
            object_type=object_type,
            object_id=object_id,
            action_taken=action_taken,
            moderator=moderator,
            before_status=before_status,
            after_status=after_status,
            reason=reason,
            ip_address=ip_address,
            user_agent=user_agent
        )

        # Broadcast the log entry to WebSocket clients
        channel_layer = get_channel_layer()
        if channel_layer:
            from .serializers import AdminLogSerializer
            serializer = AdminLogSerializer(log_entry)
            async_to_sync(channel_layer.group_send)(
                "admin_logs",
                {
                    "type": "send_log_message",
                    "message": serializer.data,
                }
            )

        logger.info(f"Admin action logged: {action} - {details} - {outcome}")

    except Exception as e:
        logger.error(f"Error logging admin action: {e}") 