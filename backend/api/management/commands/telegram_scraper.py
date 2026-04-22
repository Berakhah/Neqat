import asyncio
import logging
import os
from dotenv import load_dotenv
from django.core.management.base import BaseCommand, CommandError
from api.telegram.scraper import TelegramScraperService

# Ensure environment variables are loaded
load_dotenv()

logger = logging.getLogger(__name__)

class Command(BaseCommand):
    help = 'Run the Telegram scraper to fetch messages from channels'

    def add_arguments(self, parser):
        parser.add_argument(
            '--channel', 
            dest='channel',
            required=True,
            help='The Telegram channel to scrape'
        )
        parser.add_argument(
            '--limit', 
            dest='limit',
            type=int,
            default=100,
            help='Number of past messages to fetch (default: 100)'
        )
        parser.add_argument(
            '--listen', 
            action='store_true',
            help='Continuously listen for new messages after fetching past messages'
        )
        parser.add_argument(
            '--api-id',
            dest='api_id',
            help='Override the Telegram API ID from .env'
        )
        parser.add_argument(
            '--api-hash',
            dest='api_hash',
            help='Override the Telegram API Hash from .env'
        )

    def handle(self, *args, **options):
        # Check environment variables
        api_id = options.get('api_id') or os.getenv('TELEGRAM_API_ID') or os.getenv('api_id')
        api_hash = options.get('api_hash') or os.getenv('TELEGRAM_API_HASH') or os.getenv('api_hash')
        
        if not api_id or not api_hash:
            self.stderr.write(
                self.style.ERROR(
                    'Telegram API credentials not found. Please set TELEGRAM_API_ID and TELEGRAM_API_HASH '
                    'environment variables in .env file or pass them as --api-id and --api-hash arguments.'
                )
            )
            return
            
        channel = options['channel']
        limit = options['limit']
        listen = options['listen']
        
        self.stdout.write(self.style.SUCCESS(f'Starting Telegram scraper for channel: {channel}'))
        self.stdout.write(f'API ID: {"*" * 5}{api_id[-3:] if api_id else "Not set"}')
        self.stdout.write(f'API Hash: {"*" * 5}{api_hash[-3:] if api_hash else "Not set"}')
        
        # Run the async tasks
        try:
            asyncio.run(self._run_scraper(channel, limit, listen, api_id, api_hash))
        except KeyboardInterrupt:
            self.stdout.write(self.style.WARNING('Scraper stopped by user'))
        except Exception as e:
            self.stderr.write(self.style.ERROR(f'Failed to run scraper: {str(e)}'))
    
    async def _run_scraper(self, channel, limit, listen, api_id, api_hash):
        scraper = None
        try:
            scraper = TelegramScraperService(api_id=api_id, api_hash=api_hash)
            await scraper.start_client()
            
            # Fetch past messages
            message_count = await scraper.get_past_messages(channel, limit)
            self.stdout.write(self.style.SUCCESS(f'Fetched {message_count} messages from {channel}'))
            
            # Listen for new messages if requested
            if listen:
                self.stdout.write(self.style.WARNING(
                    f'Now listening for new messages in {channel}. Press Ctrl+C to stop.'
                ))
                await scraper.listen_for_messages(channel)
            else:
                await scraper.disconnect()
                
        except Exception as e:
            self.stderr.write(self.style.ERROR(f'Error running Telegram scraper: {str(e)}'))
            logger.error(f'Error running Telegram scraper: {str(e)}', exc_info=True)
            # Ensure client is disconnected
            try:
                if scraper and hasattr(scraper, 'client'):
                    await scraper.disconnect()
            except Exception as disconnect_error:
                logger.error(f'Error disconnecting Telegram client: {str(disconnect_error)}', exc_info=True) 