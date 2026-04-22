#!/bin/bash
echo "Running Telegram Scraper"
cd ..

# Check if the .env file exists, and notify the user
if [ -f .env ]; then
    echo "Using API credentials from .env file"
else
    echo "WARNING: .env file not found! Please create one with TELEGRAM_API_ID and TELEGRAM_API_HASH"
    echo "Creating a temporary .env file with placeholder values"
    echo "TELEGRAM_API_ID=your_api_id" > .env
    echo "TELEGRAM_API_HASH=your_api_hash" >> .env
    echo "Please update these values before running again"
    exit 1
fi

# Run the scraper
python manage.py telegram_scraper --channel channel_name --limit 100

echo "Scraper finished" 