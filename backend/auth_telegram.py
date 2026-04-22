import asyncio
import os
from dotenv import load_dotenv
import logging

# Setup logging
logging.basicConfig(level=logging.INFO, 
                    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger("TelegramAuth")

# Ensure environment variables are loaded
load_dotenv()

async def main():
    try:
        from telethon import TelegramClient
        
        # Extract credentials
        api_id = os.getenv("TELEGRAM_API_ID") or os.getenv("api_id")
        api_hash = os.getenv("TELEGRAM_API_HASH") or os.getenv("api_hash")
        
        if not api_id or not api_hash:
            print("ERROR: API ID and Hash not found in environment variables!")
            return
            
        # Create client
        print(f"Creating Telegram client with API ID: {api_id[-4:]} (masked)")
        client = TelegramClient('scraper_session', int(api_id), api_hash)
        
        # Start client and authorize
        print("Starting client and waiting for authorization...")
        await client.start()
        
        if await client.is_user_authorized():
            me = await client.get_me()
            print(f"Successfully logged in as: {me.username or me.first_name}")
            print("Your session has been saved to 'scraper_session' file.")
            print("You can now run the scraper scripts without needing to authenticate again.")
        else:
            print("Authentication failed. Please try again.")
            
        await client.disconnect()
        print("Disconnected from Telegram")
                
    except Exception as e:
        print(f"ERROR: {str(e)}")
        logger.error(f"Error in Telegram authentication: {str(e)}", exc_info=True)

if __name__ == "__main__":
    print("Telegram Authentication Utility")
    print("===================================")
    print("This script will help you authenticate with Telegram.")
    print("You will need to enter your phone number and the verification code sent to you.")
    print()
    print("The session will be saved to a file so you don't need to authenticate again.")
    print("===================================")
    asyncio.run(main())
    print("===================================")
    print("Authentication process completed") 