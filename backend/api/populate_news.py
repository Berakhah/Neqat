import requests
import json
from datetime import datetime
import datetime as dt
from dotenv import load_dotenv
import os
from pathlib import Path
from uuid import uuid4

# Configuration
BASE_DIR = Path(__file__).resolve().parent.parent.parent

# Load .env file
load_dotenv(os.path.join(BASE_DIR, 'frontend/api.env'))

# Access environment variables
NEWS_API_KEY = os.getenv('API_KEY')
DJANGO_API_URL = os.getenv('django_api')
QUERY = "news"
LANGUAGE = "en"
BATCH_SIZE = 50
SOURCES = "bbc-news,cnn,the-new-york-times,reuters,associated-press,nbc-news,abc-news,al-jazeera-english,the-guardian-uk,the-washington-post"
CATEGORIES = ["business", "entertainment", "general", "health", "science", "sports", "technology"]

def fetch_news_from_newsapi():
    """Fetch news articles from NewsAPI.org 'everything' endpoint."""
    params = {
        "q": QUERY,
        "language": LANGUAGE,
        "sortBy": "publishedAt",
        "apiKey": NEWS_API_KEY,
        "sources": SOURCES,
        "excludeDomains": "biztoc.com",
    }
    try:
        response = requests.get("https://newsapi.org/v2/everything", params=params)
        response.raise_for_status()
        data = response.json()
        if data.get("status") != "ok":
            raise Exception(f"NewsAPI error: {data.get('message', 'Unknown error')}")
        return data.get("articles", [])
    except Exception as e:
        print(f"Error fetching news: {e}")
        return []

def fetch_top_headlines_from_newsapi():
    """Fetch top headlines from NewsAPI.org 'top-headlines' endpoint."""
    params = {
        "language": LANGUAGE,
        "apiKey": NEWS_API_KEY,
        "sources": SOURCES,
    }
    try:
        response = requests.get("https://newsapi.org/v2/top-headlines", params=params)
        response.raise_for_status()
        data = response.json()
        if data.get("status") != "ok":
            raise Exception(f"Top Headlines error: {data.get('message', 'Unknown error')}")
        return data.get("articles", [])
    except Exception as e:
        print(f"Error fetching top headlines: {e}")
        return []

def fetch_category_news_from_newsapi(category):
    """Fetch category-specific news from NewsAPI.org 'top-headlines' endpoint."""
    params = {
        "country": "us",
        "category": category,
        "language": LANGUAGE,
        "apiKey": NEWS_API_KEY,
    }
    try:
        response = requests.get("https://newsapi.org/v2/top-headlines", params=params)
        response.raise_for_status()
        data = response.json()
        if data.get("status") != "ok":
            raise Exception(f"Category {category} error: {data.get('message', 'Unknown error')}")
        return data.get("articles", [])
    except Exception as e:
        print(f"Error fetching {category} news: {e}")
        return []

def map_newsapi_to_django(newsapi_articles, tag_name=None, is_top_headline=False):
    """Map NewsAPI.org articles to Django News model format."""
    django_articles = []
    tag_names = ['top_headlines'] if is_top_headline else [tag_name] if tag_name else ['World']

    for article in newsapi_articles:
        title = article.get("title", "Untitled")
        print(f"Processing article: {title}")

        # 1) Normalize and lowercase description (or set to "")
        raw_desc = article.get("description")
        if raw_desc is None:
            raw_desc = ""
            print(f"Warning: Description is None for article: {title}")
        description = raw_desc.lower()

        # 2) Skip BBC News bulletins
        source_name = article.get("source", {}).get("name", "").lower()
        if source_name == "bbc news" and "five minute news bulletin" in description:
            print(f"Skipping BBC News bulletin: {title}")
            continue

        # 3) Handle content fallback
        raw_content = article.get("content")
        if raw_content is None:
            if description:
                content = description
                print(f"Warning: Content is None for article: {title}, using description")
            else:
                content = ""
                print(f"Warning: Both content and description are None for article: {title}, using empty string")
        else:
            content = raw_content

        # 4) Truncate to 1000 chars
        content = content[:1000]

        django_articles.append({
            "id":         str(uuid4()),
            "title":      title,
            "content":    content,
            "author":     article.get("author", "Unknown"),
            "source":     article.get("source", {}).get("name", "Unknown"),
            "url":        article.get("url", ""),
            "image_url":  article.get("urlToImage", ""),
            "timestamp":  article.get("publishedAt", datetime.now(dt.UTC).isoformat()),
            "language":   LANGUAGE,
            "tag_names":  tag_names,
        })

        print(f"Added article: {title} with tags: {tag_names}")

    return django_articles

def send_to_django_api(articles):
    """Send articles to Django bulk create endpoint in batches."""
    headers = {"Content-Type": "application/json"}
    created_count = 0
    error_count = 0
    
    for i in range(0, len(articles), BATCH_SIZE):
        batch = articles[i:i + BATCH_SIZE]
        try:
            response = requests.post(f"{DJANGO_API_URL}/api/news/bulk/create/", json=batch, headers=headers)
            response.raise_for_status()
            response_data = response.json()
            
            if isinstance(response_data, list):
                created = response_data
                errors = []
            elif isinstance(response_data, dict):
                created = response_data.get("created", [])
                errors = response_data.get("errors", [])
            else:
                raise ValueError(f"Unexpected response format: {response_data}")
            
            created_count += len(created)
            error_count += len(errors)
            print(f"Batch {i // BATCH_SIZE + 1}: Created {len(created)} articles, {len(errors)} errors")
            if errors:
                print("Errors:", errors)
        except requests.exceptions.RequestException as e:
            print(f"Error sending batch {i // BATCH_SIZE + 1}: {e}")
            print(f"Response: {response.text if 'response' in locals() else 'No response'}")
            error_count += len(batch)
    
    return created_count, error_count

def main():
    if not NEWS_API_KEY:
        print("Error: NEWS_API_KEY is not set. Please set API_KEY in .env file.")
        return
    
    all_articles = []
    
    # Fetch regular news
    print("Fetching news from NewsAPI.org...")
    newsapi_articles = fetch_news_from_newsapi()
    print(f"Fetched {len(newsapi_articles)} regular articles")
    django_articles = map_newsapi_to_django(newsapi_articles)
    all_articles.extend(django_articles)
    
    # Fetch top headlines
    print("Fetching top headlines from NewsAPI.org...")
    top_headlines = fetch_top_headlines_from_newsapi()
    print(f"Fetched {len(top_headlines)} top headlines")
    django_top_headlines = map_newsapi_to_django(top_headlines, is_top_headline=True)
    all_articles.extend(django_top_headlines)
    
    # Fetch category-specific news
    for category in CATEGORIES:
        print(f"Fetching {category} news from NewsAPI.org...")
        category_articles = fetch_category_news_from_newsapi(category)
        print(f"Fetched {len(category_articles)} {category} articles")
        # Capitalize category to match tag names (e.g., 'politics' -> 'Politics')
        django_category_articles = map_newsapi_to_django(category_articles, tag_name=category.capitalize())
        all_articles.extend(django_category_articles)
    
    print(f"Total articles to send: {len(all_articles)}")
    
    print("Sending articles to Django API...")
    created_count, error_count = send_to_django_api(all_articles)
    
    print(f"Population complete. Created {created_count} new articles, {error_count} errors")

if __name__ == "__main__":
    main()