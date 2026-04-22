# Telegram Scraper

A component for the Neqat application that allows scraping messages from Telegram channels and integrating them into the application's newsfeed.

## Overview

The Telegram scraper connects to Telegram's API to fetch messages from public channels and store them in the application's database. It features:

- Authentication with Telegram API
- Message retrieval from specified channels
- Redundancy checking to avoid duplicate messages
- Integration with the application's newsfeed
- Real-time message listening capability

## Prerequisites

- Python 3.8+
- Django
- SQL Server (configured)
- Telegram API credentials (api_id and api_hash)

## Setup

### 1. Install Required Packages

```bash
pip install telethon django djangorestframework
```

### 2. Get Telegram API Credentials

1. Visit https://my.telegram.org/auth
2. Log in with your Telegram account
3. Go to 'API development tools'
4. Create a new application
5. Note down the `api_id` and `api_hash`

### 3. Create Environment Variables

Create a `.env` file in the backend directory with the following content:

```
TELEGRAM_API_ID=your_api_id
TELEGRAM_API_HASH=your_api_hash
```

### 4. Authenticate with Telegram

Run the authentication script to create a session file:

```bash
python auth_telegram.py
```

This will prompt you to enter your phone number and the verification code sent to your Telegram account. Once authenticated, it creates a session file that allows the scraper to connect without re-authenticating.

## Usage

### Fetch Messages from a Channel

To fetch messages from a specific channel:

```bash
python manage.py telegram_scraper --channel channel_name --limit 50
```

Parameters:
- `--channel`: Telegram channel name or username (required)
- `--limit`: Maximum number of messages to fetch (default: 100)
- `--listen`: Continuously listen for new messages (optional)
- `--api-id`: Override the Telegram API ID from .env (optional)
- `--api-hash`: Override the Telegram API Hash from .env (optional)

Example:
```bash
python manage.py telegram_scraper --channel techcrunch --limit 20
```
### Run the stemmer
```bash
 python manage.py build_amh_ir
```

### Listen for New Messages

To continuously listen for new messages in a channel:

```bash
python manage.py telegram_scraper --channel channel_name --listen
```

Press Ctrl+C to stop listening.

## API Endpoints

The scraped messages can be accessed through the following API endpoints:

- `GET /api/telegram-messages/` - Get all messages
- `GET /api/telegram-messages/?channel=channel_name` - Get messages from a specific channel
- `GET /api/telegram-messages/top_channels/` - Get top channels by message count and recency

## Integration with Newsfeed

Telegram messages are stored in the database by the backend scraper and then accessed by the frontend through API endpoints. The frontend never connects to Telegram directly.

The architecture follows this pattern:
1. Backend scraper fetches data from Telegram and stores it in the database
2. Backend API exposes endpoints to access the stored messages
3. Frontend fetches data exclusively through these backend API endpoints

Users can:
- View all content in a unified feed
- Filter to show only Telegram messages
- Filter by specific Telegram channels

## Database Schema

Telegram messages are stored in the database with the following fields:

- `sender_id`: ID of the message sender
- `message`: Content of the message (limited to 4000 characters)
- `date`: Date and time when the message was sent
- `channel_name`: Name of the Telegram channel
- `created_at`: Date and time when the message was stored
- `updated_at`: Date and time when the message was last updated

## Troubleshooting

### Common Issues

1. **Authentication Error**: Ensure your Telegram API credentials are correct and the session file exists.
   
2. **Channel Not Found**: Verify the channel name/username is correct. Try using the full username format: `@username`.

3. **Database Errors**: Check SQL Server connection settings and compatibility with Django models.

4. **Session Expired**: Re-run the authentication script if your session has expired.

### SQL Server Notes

The scraper is optimized for SQL Server compatibility, with special handling for:
- Data type compatibility between nvarchar and text types
- Asynchronous database operations in Django

## License

This component is part of the Neqat application and is subject to the same license terms. 