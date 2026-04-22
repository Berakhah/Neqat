import requests
import json
from datetime import datetime, timezone
from dotenv import load_dotenv
import os
from pathlib import Path
from uuid import uuid4
import sys

# Configuration
BASE_DIR = Path(__file__).resolve().parent.parent.parent

# Load from dedicated .env.news file first, then fall back to other locations
ENV_FILES = [
    os.path.join(BASE_DIR, 'backend', '.env.news'),
    os.path.join(BASE_DIR, 'frontend/api.env'),
    os.path.join(BASE_DIR, '.env')
]

env_loaded = False
for env_file in ENV_FILES:
    if os.path.exists(env_file):
        load_dotenv(env_file)
        print(f"Loaded environment variables from: {env_file}")
        env_loaded = True
        break

if not env_loaded:
    print("Warning: No environment file found. Using default values where possible.")

# Access environment variables
NEWS_API_KEY = os.getenv('API_KEY')
DJANGO_API_URL = os.getenv('django_api', 'http://localhost:8000')
QUERY = "news"
LANGUAGE = "en"
BATCH_SIZE = 50
SOURCES = "bbc-news,cnn,the-new-york-times,reuters,associated-press,nbc-news,abc-news,al-jazeera-english,the-guardian-uk,the-washington-post"
CATEGORIES = ["business", "entertainment", "general", "health", "science", "sports", "technology"]

# Keycloak authentication configuration
KEYCLOAK_SERVER_URL = os.getenv('KEYCLOAK_SERVER_URL', 'http://localhost:8080')  # Fallback to localhost for non-Docker
KEYCLOAK_REALM = os.getenv('KEYCLOAK_REALM', 'neqat-realm')
KEYCLOAK_CLIENT_ID = os.getenv('KEYCLOAK_CLIENT_ID', 'django-backend')
KEYCLOAK_CLIENT_SECRET = os.getenv('KEYCLOAK_CLIENT_SECRET', '**********')

# Keycloak token keys
KEYCLOAK_ACCESS_TOKEN_KEY = os.getenv('KEYCLOAK_ACCESS_TOKEN_KEY', 'access_token')
KEYCLOAK_REFRESH_TOKEN_KEY = os.getenv('KEYCLOAK_REFRESH_TOKEN_KEY', 'refresh_token')
KEYCLOAK_ID_TOKEN_KEY = os.getenv('KEYCLOAK_ID_TOKEN_KEY', 'id_token')
KEYCLOAK_TOKEN_EXPIRY_KEY = os.getenv('KEYCLOAK_TOKEN_EXPIRY_KEY', 'token_expiry')

# Keycloak roles (not used directly in this script but defined for reference)
KEYCLOAK_ROLE_ADMIN = os.getenv('KEYCLOAK_ROLE_ADMIN', 'admin')
KEYCLOAK_ROLE_USER = os.getenv('KEYCLOAK_ROLE_USER', 'user')

# Replace KEYCLOAK_USERNAME with KEYCLOAK_EMAIL for user authentication
KEYCLOAK_EMAIL = os.getenv('KEYCLOAK_EMAIL')
KEYCLOAK_PASSWORD = os.getenv('KEYCLOAK_PASSWORD')

def get_keycloak_token():
    """Get an access token from Keycloak using Resource Owner Password Credentials Grant (email as username)."""
    token_url = f"{KEYCLOAK_SERVER_URL}/realms/{KEYCLOAK_REALM}/protocol/openid-connect/token"
    print(f"Authenticating with Keycloak at {token_url} using client ID {KEYCLOAK_CLIENT_ID}")

    payload = {
        'client_id': KEYCLOAK_CLIENT_ID,
        'client_secret': KEYCLOAK_CLIENT_SECRET,
        'grant_type': 'password',
        'username': KEYCLOAK_EMAIL,
        'password': KEYCLOAK_PASSWORD,
    }

    if not KEYCLOAK_CLIENT_SECRET:
        print("Warning: No client secret provided. This might fail if the client is configured as confidential.")
    if not KEYCLOAK_EMAIL or not KEYCLOAK_PASSWORD:
        print("Error: KEYCLOAK_EMAIL and KEYCLOAK_PASSWORD must be set in the environment.")
        return None

    try:
        response = requests.post(token_url, data=payload)
        if response.status_code != 200:
            print(f"Authentication failed with status code {response.status_code}")
            print(f"Response: {response.text}")
            return None
        token_data = response.json()
        print("Authentication successful!")
        access_token = token_data.get(KEYCLOAK_ACCESS_TOKEN_KEY)
        print("Access token:", access_token)
        return access_token
    except Exception as e:
        print(f"Error getting Keycloak token: {e}")
        return None

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
        print(f"Fetching page 1 for category {category} from: https://newsapi.org/v2/top-headlines")
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
        # Log article details for debugging
        title = article.get("title", "Untitled")
        print(f"Processing article: {title}")
        
        # Handle None for description
        description = article.get("description")
        if description is None:
            description = ""
            print(f"Warning: Description is None for article: {title}")
        else:
            description = description.lower()
        
        # Skip BBC News articles with bulletin descriptions
        source_name = article.get("source", {}).get("name", "").lower()
        if source_name == "bbc news" and "five minute news bulletin" in description:
            print(f"Skipping BBC News bulletin: {title}")
            continue
        
        article_id = str(uuid4())
        content = article.get("content")
        if content is None:
            content = description
            print(f"Warning: Content is None for article: {title}, using description")
        if content is None:  # If description was also None
            content = ""
            print(f"Warning: Both content and description are None for article: {title}, using empty string")
        content = content[:1000]
        
        django_article = {
            "id": article_id,
            "title": title,
            "content": content,
            "author": article.get("author", "Unknown"),
            "source": article.get("source", {}).get("name", "Unknown"),
            "url": article.get("url", ""),
            "image_url": article.get("urlToImage", ""),
            "timestamp": article.get("publishedAt", datetime.now(timezone.utc).isoformat()),
            "language": LANGUAGE,
            "tag_names": tag_names
        }
        
        django_articles.append(django_article)
        print(f"Added article: {title} with tags: {tag_names}")
    return django_articles

def send_to_django_api(articles, access_token=None):
    """Send articles to Django bulk create endpoint in batches with authentication."""
    headers = {"Content-Type": "application/json"}
    
    # Add authorization header if token is provided
    if access_token:
        headers["Authorization"] = f"Bearer {access_token}"
        print(f"Using authentication token for API request")
    else:
        print("Warning: No authentication token provided for API request")
    
    created_count = 0
    error_count = 0
    
    bulk_endpoint = f"{DJANGO_API_URL}/api/news/bulk/"
    print(f"Sending articles to endpoint: {bulk_endpoint}")
    
    for i in range(0, len(articles), BATCH_SIZE):
        batch = articles[i:i + BATCH_SIZE]
        try:
            # Send the batch to the API
            print(f"Sending batch {i // BATCH_SIZE + 1} with {len(batch)} articles")
            response = requests.post(bulk_endpoint, json=batch, headers=headers)
            print(f"API Response: Status {response.status_code}")
            
            if response.status_code >= 400:
                print(f"Error response body: {response.text}")
                raise requests.exceptions.RequestException(f"API returned error status {response.status_code}")
            
            try:
                response_data = response.json()
            except json.JSONDecodeError:
                print(f"Could not parse response as JSON: {response.text}")
                raise
            
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

def create_tags_if_not_exist(access_token=None):
    """Create the tag categories if they don't exist."""
    headers = {"Content-Type": "application/json"}
    if access_token:
        headers["Authorization"] = f"Bearer {access_token}"
    
    # List of tags to ensure exist
    needed_tags = ['World', 'top_headlines'] + [cat.capitalize() for cat in CATEGORIES]
    
    tags_endpoint = f"{DJANGO_API_URL}/api/tags/"
    print(f"Checking tags at endpoint: {tags_endpoint}")
    
    # First, get existing tags
    try:
        response = requests.get(tags_endpoint, headers=headers)
        if response.status_code >= 400:
            print(f"Error accessing tags endpoint: {response.status_code}")
            print(f"Response: {response.text}")
            return False
        
        existing_tags = response.json()
        existing_tag_names = [tag['name'] for tag in existing_tags]
        print(f"Found {len(existing_tags)} existing tags")
        
        # Create any missing tags
        for tag_name in needed_tags:
            if tag_name not in existing_tag_names:
                try:
                    tag_data = {"name": tag_name, "description": f"{tag_name} news category"}
                    response = requests.post(tags_endpoint, json=tag_data, headers=headers)
                    
                    if response.status_code >= 400:
                        print(f"Error creating tag {tag_name}: {response.status_code}")
                        print(f"Response: {response.text}")
                        continue
                    
                    print(f"Created tag: {tag_name}")
                except Exception as e:
                    print(f"Error creating tag {tag_name}: {e}")
            else:
                print(f"Tag already exists: {tag_name}")
        
        return True
    except Exception as e:
        print(f"Error checking or creating tags: {e}")
        return False

def main():
    # Check if NewsAPI key is set
    if not NEWS_API_KEY:
        print("Error: NEWS_API_KEY is not set. Please set API_KEY in one of the environment files.")
        sys.exit(1)
    
    # Check if Django API URL is set
    if not DJANGO_API_URL:
        print("Error: django_api URL is not set. Please set django_api in one of the environment files.")
        sys.exit(1)
    
    # Print configuration details
    print(f"Using Django API URL: {DJANGO_API_URL}")
    print(f"Using Keycloak server: {KEYCLOAK_SERVER_URL}")
    print(f"Using Keycloak realm: {KEYCLOAK_REALM}")
    print(f"Using Keycloak client ID: {KEYCLOAK_CLIENT_ID}")
    
    # Get authentication token
    print("Authenticating with Keycloak...")
    access_token = get_keycloak_token()
    
    # For development/testing, allow skipping authentication if it fails
    if not access_token:
        print("Warning: Could not authenticate with Keycloak. Running in unauthenticated mode.")
        print("This will only work if the API allows unauthenticated access to the bulk create endpoint.")
        print("For production use, please provide valid Keycloak credentials.")
    
    # Ensure tags exist
    print("Creating necessary tags if they don't exist...")
    if not create_tags_if_not_exist(access_token):
        print("Warning: Failed to create all necessary tags. Some articles may not be categorized correctly.")
    
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
    
    if not all_articles:
        print("No articles to send. Exiting.")
        sys.exit(0)
    
    print("Sending articles to Django API...")
    created_count, error_count = send_to_django_api(all_articles, access_token)
    
    print(f"Population complete. Created {created_count} new articles, {error_count} errors")
    
    if error_count > 0 and created_count == 0:
        print("All articles failed to be created. Check the error messages and your configuration.")
        sys.exit(1)

if __name__ == "__main__":
    main()