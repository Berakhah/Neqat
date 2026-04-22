import telethon
import os
import asyncio
import logging
from datetime import datetime
from dotenv import load_dotenv
from django.conf import settings
from django.db import transaction
from asgiref.sync import sync_to_async
from ..models import TelegramMessage

logger = logging.getLogger(__name__)

# Ensure environment variables are loaded
load_dotenv()

class TelegramScraperService:
    def __init__(self, api_id=None, api_hash=None, session_name="tel_scrapper_session"):
        """
        Initialize the Telegram scraper service with API credentials.
        If not provided, will attempt to read from environment variables.
        """
        self.api_id = api_id or os.getenv("TELEGRAM_API_ID") or os.getenv("api_id")
        self.api_hash = api_hash or os.getenv("TELEGRAM_API_HASH") or os.getenv("api_hash")
        self.session_name = session_name
        self.client = None
        
        logger.info(f"TelegramScraperService initialized. API ID available: {bool(self.api_id)}, API Hash available: {bool(self.api_hash)}")

    async def start_client(self):
        """
        Start the Telegram client session and return the client object
        """
        if not self.api_id or not self.api_hash:
            error_msg = "Telegram API credentials not found. Set TELEGRAM_API_ID and TELEGRAM_API_HASH environment variables."
            logger.error(error_msg)
            raise ValueError(error_msg)
            
        logger.info(f"Starting Telegram client with API ID: {self.api_id}")
        self.client = telethon.TelegramClient(self.session_name, self.api_id, self.api_hash)
        await self.client.start()
        me = await self.client.get_me()
        logger.info(f"Connected to Telegram as: {me.username}")
        return self.client

    async def listen_for_messages(self, channel_name):
        """
        Continuously listen for new messages in the specified channel
        """
        if not self.client:
            await self.start_client()
            
        @self.client.on(telethon.events.NewMessage(chats=channel_name))
        async def message_handler(event):
            await self.save_message(event.message, channel_name)
            
        logger.info(f"Started listening for messages in channel: {channel_name}")
        await self.client.run_until_disconnected()
    
    async def get_past_messages(self, channel_name, limit=100):
        """
        Retrieve past messages from the specified channel
        """
        if not self.client:
            await self.start_client()
            
        logger.info(f"Fetching {limit} past messages from channel: {channel_name}")
        messages = await self.client.get_messages(channel_name, limit=limit)
        
        saved_count = 0
        duplicate_count = 0
        
        for message in messages:
            is_new = await self.save_message(message, channel_name)
            if is_new:
                saved_count += 1
            else:
                duplicate_count += 1
            
        logger.info(f"Retrieved {len(messages)} messages from {channel_name}. Saved {saved_count} new messages, found {duplicate_count} duplicates.")
        return saved_count
    
    @sync_to_async
    def _check_existing_message(self, sender_id, message_text, message_date, channel_name):
        """
        Check if a message already exists in the database using SQL Server compatible queries
        """
        # For SQL Server compatibility, we'll use a separate query for each condition
        # and check if any results are returned rather than using complex filter conditions
        query = TelegramMessage.objects.filter(
            sender_id=str(sender_id),
            channel_name=channel_name
        )
        
        # Filter by date separately (approximate match for datetime)
        date_matches = []
        for msg in query:
            if abs((msg.date - message_date).total_seconds()) < 5:  # Within 5 seconds
                date_matches.append(msg)
                
        # Check message text for matches among date matches
        for msg in date_matches:
            if msg.message == message_text:
                return True
                
        return False
    
    @sync_to_async
    def _create_message(self, sender_id, message_text, message_date, channel_name):
        """
        Create a new message in the database
        """
        with transaction.atomic():
            TelegramMessage.objects.create(
                sender_id=str(sender_id),
                message=message_text,
                date=message_date,
                channel_name=channel_name
            )
    
    async def save_message(self, message, channel_name):
        """
        Save a Telegram message to the database, checking for duplicates.
        Returns True if a new message was saved, False if it was a duplicate.
        """
        try:
            # Parse the date string if it's a string
            message_date = message.date
            if isinstance(message_date, str):
                message_date = datetime.fromisoformat(message_date)
            
            message_text = message.text if message.text else ""
            
            # Check for existing messages with same sender_id, message, date and channel_name to avoid duplicates
            existing_message = await self._check_existing_message(
                message.sender_id, 
                message_text, 
                message_date, 
                channel_name
            )
            
            if existing_message:
                logger.debug(f"Duplicate message from {message.sender_id} in {channel_name} at {message_date} - skipping")
                return False
                
            # Create a new TelegramMessage object
            await self._create_message(
                message.sender_id,
                message_text,
                message_date,
                channel_name
            )
            
            logger.debug(f"Saved new message from {message.sender_id} in {channel_name}")
            return True
            
        except Exception as e:
            logger.error(f"Error saving message: {str(e)}")
            return False
    
    async def disconnect(self):
        """
        Disconnect the Telegram client
        """
        if self.client:
            await self.client.disconnect()
            logger.info("Disconnected from Telegram") 