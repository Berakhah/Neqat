import json

from channels.generic.websocket import AsyncWebsocketConsumer
from asgiref.sync import sync_to_async
from .models import AdminLog
from .serializers import AdminLogSerializer

class LogConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.log_group_name = "admin_logs"

        # Join log group
        await self.channel_layer.group_add(
            self.log_group_name,
            self.channel_name
        )

        await self.accept()

        # Send last 50 logs to the newly connected client
        await self.send_initial_logs()

    async def send_initial_logs(self):
        logs = await sync_to_async(AdminLog.objects.order_by('-timestamp')[:50].all)()
        serializer = AdminLogSerializer(logs, many=True)
        await self.send(text_data=json.dumps({
            "initial_logs": serializer.data
        }))

    async def disconnect(self, close_code):
        # Leave log group
        await self.channel_layer.group_discard(
            self.log_group_name,
            self.channel_name
        )

    # Receive message from WebSocket
    async def receive(self, text_data):
        # We don't expect clients to send messages, but if they do, we can handle it here.
        pass

    # Receive message from log group
    async def send_log_message(self, event):
        message = event["message"]

        # Send message to WebSocket
        await self.send(text_data=json.dumps({
            "message": message
        })) 