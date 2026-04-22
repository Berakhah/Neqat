import os

SECURE_SSL_REDIRECT = False  # Set to True in production with HTTPS
SESSION_COOKIE_SECURE = False  # Set to True in production with HTTPS
CSRF_COOKIE_SECURE = False  # Set to True in production with HTTPS
from pathlib import Path
from datetime import timedelta
from dotenv import load_dotenv
from .keycloak_config import KEYCLOAK_CONFIG
from django.utils.translation import gettext_lazy as _

# Load environment variables from custom .env file if specified
env_file = os.getenv('DJANGO_DOTENV_FILE', '.env')
load_dotenv(env_file)
print(f"Loaded environment from: {env_file}")

# Validate required Keycloak configuration
required_keycloak_vars = [
    'KEYCLOAK_SERVER_URL',
    'KEYCLOAK_REALM',
    'KEYCLOAK_CLIENT_ID',
    'KEYCLOAK_CLIENT_SECRET',
]

# Check and warn about missing configuration
missing_vars = [var for var in required_keycloak_vars if not os.getenv(var)]
if missing_vars:
    print(f"WARNING: Missing required Keycloak environment variables: {', '.join(missing_vars)}")
    print("Authentication may not work correctly without these variables.")

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = os.getenv('DJANGO_SECRET_KEY')

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = os.getenv('DEBUG', 'True') == 'True'

ALLOWED_HOSTS = os.getenv('ALLOWED_HOSTS', 'localhost,127.0.0.1,192.168.64.132').split(',')

# Add CSRF trusted origins for production (required for POST requests from Flutter)
CSRF_TRUSTED_ORIGINS = os.getenv(
    'CSRF_TRUSTED_ORIGINS',
    'http://localhost:8000,http://localhost:8080,http://keycloak:8080'
).split(',')

# CORS Configuration
CORS_ALLOW_ALL_ORIGINS = True
CORS_ALLOW_CREDENTIALS = True
CORS_ALLOWED_ORIGINS = os.getenv(
    'CORS_ALLOWED_ORIGINS',
    'http://localhost:3000,http://frontend:3000,http://localhost:8080,http://keycloak:8080,http://192.168.134.132:8000,http://192.168.134.132:3000,http://192.168.134.132:8080,http://localhost:49794,http://localhost:53165'
).split(',')
CORS_ALLOW_METHODS = [
    'DELETE',
    'GET',
    'OPTIONS',
    'PATCH',
    'POST',
    'PUT',
]
CORS_ALLOW_HEADERS = [
    'accept',
    'accept-encoding',
    'authorization',
    'content-type',
    'dnt',
    'origin',
    'user-agent',
    'x-csrftoken',
    'x-requested-with',
]

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'rest_framework.authtoken',
    'social_django',
    'drf_yasg',
    'corsheaders',  # Added for CORS support
    'api',
    'django_extensions',
    'channels',
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',  # Added for CORS
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    'api.middleware.SystemLogMiddleware',  # Updated import path
    'api.middleware.UUIDMiddleware',       # Updated import path
]

ROOT_URLCONF = 'backend.urls'

# Static files (CSS, JavaScript, Images) and Flutter web build
STATIC_URL = os.getenv('STATIC_URL', '/static/')
STATICFILES_DIRS = [BASE_DIR / 'static']  # Place Flutter web build assets here
STATIC_ROOT = BASE_DIR / 'staticfiles'

# Templates (for serving Flutter web index.html)
TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],  # Place Flutter web index.html here
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
                'social_django.context_processors.backends',
                'social_django.context_processors.login_redirect',
            ],
        },
    },
]

ASGI_APPLICATION = 'backend.asgi.application'

# Database Configuration
db_engine = os.getenv('DATABASE_ENGINE', 'mssql')

if db_engine == 'sqlite3':
    # SQLite configuration for local development
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': BASE_DIR / os.getenv('DATABASE_NAME', 'db.sqlite3'),
        }
    }
else:
    # SQL Server configuration
    DATABASES = {
        'default': {
            'ENGINE': 'mssql',
            'NAME': os.getenv('DATABASE_NAME', 'NeqatDB'),
            'HOST': os.getenv('DATABASE_HOST', 'localhost'),
            'PORT': os.getenv('DATABASE_PORT', '1433'),
            'USER': os.getenv('DATABASE_USER', 'SA'),
            'PASSWORD': os.getenv('DATABASE_PASSWORD', 'NEQ@T2025ComplexPass!'),
            'OPTIONS': {
                'driver': 'ODBC Driver 18 for SQL Server',
                'extra_params': 'TrustServerCertificate=yes;Encrypt=no;',
            },
        }
    }

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

# Internationalization
# https://docs.djangoproject.com/en/5.0/topics/i18n/

LANGUAGE_CODE = 'en-us'

TIME_ZONE = 'UTC'

USE_I18N = True

USE_TZ = True

# Available languages for translation
LANGUAGES = [
    ('en', _('English')),
    ('am', _('Amharic')),
]

# Path to locale directory
LOCALE_PATHS = [
    os.path.join(BASE_DIR, 'locale'),
]

# Media files (User-uploaded content)
MEDIA_URL = os.getenv('MEDIA_URL', '/Images/')
MEDIA_ROOT = os.path.join(BASE_DIR, 'Images')

# Default primary key field type
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# Custom User Model
AUTH_USER_MODEL = 'api.NeqatUser'

# REST Framework Configuration
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'api.keycloak_backend.KeycloakAuthentication',
    ),
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.IsAuthenticated',
    ),
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 10,
    'DEFAULT_RENDERER_CLASSES': (
        'rest_framework.renderers.JSONRenderer',
        'rest_framework.renderers.BrowsableAPIRenderer',
    ),
    'DEFAULT_THROTTLE_CLASSES': [
        'rest_framework.throttling.UserRateThrottle',
        'rest_framework.throttling.AnonRateThrottle',
        'rest_framework.throttling.ScopedRateThrottle',
    ],
    'DEFAULT_THROTTLE_RATES': {
        'user': '1000/day',
        'anon': '100/day',
        'login': '5/minute',
        'password_reset': '3/hour',
        'flag_content': '5/hour',
    },
}

# Authentication Backends
AUTHENTICATION_BACKENDS = (
    'django.contrib.auth.backends.ModelBackend',
    'api.keycloak_backend.KeycloakAuthentication',
)

# Keycloak Configuration (from keycloak_config.py)
# KEYCLOAK_CONFIG is imported at the top of the file

# Frontend URL for redirects
FRONTEND_URL = os.getenv('FRONTEND_URL', 'http://localhost:3000')

# Social Auth Configuration
# Google
SOCIAL_AUTH_GOOGLE_OAUTH2_KEY = os.getenv('GOOGLE_OAUTH2_KEY')
SOCIAL_AUTH_GOOGLE_OAUTH2_SECRET = os.getenv('GOOGLE_OAUTH2_SECRET')
SOCIAL_AUTH_GOOGLE_OAUTH2_SCOPE = os.getenv('GOOGLE_OAUTH2_SCOPE', 'email,profile').split(',')

# Twitter
SOCIAL_AUTH_TWITTER_KEY = os.getenv('TWITTER_API_KEY')
SOCIAL_AUTH_TWITTER_SECRET = os.getenv('TWITTER_API_SECRET')

# GitHub
SOCIAL_AUTH_GITHUB_KEY = os.getenv('GITHUB_CLIENT_ID')
SOCIAL_AUTH_GITHUB_SECRET = os.getenv('GITHUB_CLIENT_SECRET')
SOCIAL_AUTH_GITHUB_SCOPE = os.getenv('GITHUB_SCOPE', 'user:email').split(',')

# Social Auth Pipeline
SOCIAL_AUTH_PIPELINE = (
    'social_core.pipeline.social_auth.social_details',
    'social_core.pipeline.social_auth.social_uid',
    'social_core.pipeline.social_auth.auth_allowed',
    'social_core.pipeline.social_auth.social_user',
    'social_core.pipeline.user.get_username',
    'api.pipeline.create_neqat_user',
    'social_core.pipeline.social_auth.associate_user',
    'social_core.pipeline.social_auth.load_extra_data',
    'social_core.pipeline.user.user_details',
)

SOCIAL_AUTH_USERNAME_IS_FULL_EMAIL = True
SOCIAL_AUTH_USER_MODEL = 'api.NeqatUser'

# Social Auth Redirect URIs
SOCIAL_AUTH_REDIRECT_URI = os.getenv('SOCIAL_AUTH_REDIRECT_URI', 'http://localhost:8000/api/auth/callback')
SOCIAL_AUTH_TWITTER_REDIRECT_URI = os.getenv('SOCIAL_AUTH_TWITTER_REDIRECT_URI', 'http://localhost:8000/auth/complete/twitter/')
SOCIAL_AUTH_GITHUB_REDIRECT_URI = os.getenv('SOCIAL_AUTH_GITHUB_REDIRECT_URI', 'http://localhost:8000/auth/complete/github/')

# Email Configuration
EMAIL_BACKEND = os.getenv('EMAIL_BACKEND', 'django.core.mail.backends.console.EmailBackend')
EMAIL_HOST = os.getenv('EMAIL_HOST', 'smtp.gmail.com')
EMAIL_PORT = int(os.getenv('EMAIL_PORT', '587'))
EMAIL_USE_TLS = os.getenv('EMAIL_USE_TLS', 'True') == 'True'
EMAIL_HOST_USER = os.getenv('EMAIL_HOST_USER')
EMAIL_HOST_PASSWORD = os.getenv('EMAIL_HOST_PASSWORD')
DEFAULT_FROM_EMAIL = os.getenv('DEFAULT_FROM_EMAIL', 'noreply@neqat.com')

# Security Settings
SECURE_SSL_REDIRECT = os.getenv('SECURE_SSL_REDIRECT', 'False') == 'True'
SESSION_COOKIE_SECURE = os.getenv('SESSION_COOKIE_SECURE', 'True') == 'True'
CSRF_COOKIE_SECURE = os.getenv('CSRF_COOKIE_SECURE', 'True') == 'True'
SECURE_BROWSER_XSS_FILTER = os.getenv('SECURE_BROWSER_XSS_FILTER', 'True') == 'True'
SECURE_CONTENT_TYPE_NOSNIFF = os.getenv('SECURE_CONTENT_TYPE_NOSNIFF', 'True') == 'True'
X_FRAME_OPTIONS = os.getenv('X_FRAME_OPTIONS', 'DENY')
SECURE_HSTS_SECONDS = int(os.getenv('SECURE_HSTS_SECONDS', '31536000'))  # 1 year
SECURE_HSTS_INCLUDE_SUBDOMAINS = os.getenv('SECURE_HSTS_INCLUDE_SUBDOMAINS', 'True') == 'True'
SECURE_HSTS_PRELOAD = os.getenv('SECURE_HSTS_PRELOAD', 'True') == 'True'

# Import compatibility mode for UUID handling
try:
    import api.compatibility_mode
    print("UUID compatibility mode enabled for SQL Server")
except ImportError:
    pass

# Logging Configuration
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
            'style': '{',
        },
        'simple': {
            'format': '{levelname} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'console': {
            'level': 'DEBUG',
            'class': 'logging.StreamHandler',
            'formatter': 'verbose',
        },
    },
    'loggers': {
        'django': {
            'handlers': ['console'],
            'level': 'INFO',
            'propagate': True,
        },
        'api': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'api.keycloak_backend': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'api.token_manager': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'api.views': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
    },
}

# Encryption key for django-encrypted-model-fields
# IMPORTANT: Set this to a strong, base64-encoded 32-byte key in your environment or .env file
ENCRYPTED_MODEL_FIELDS_KEY = os.getenv('ENCRYPTED_MODEL_FIELDS_KEY', 'REPLACE_WITH_YOUR_BASE64_KEY')

# For django-encrypted-model-fields compatibility
FIELD_ENCRYPTION_KEY = ENCRYPTED_MODEL_FIELDS_KEY

CHANNEL_LAYERS = {
    "default": {
        "BACKEND": "channels_redis.pubsub.RedisPubSubChannelLayer",
        "CONFIG": {
            "hosts": [os.getenv('REDIS_URL', 'redis://localhost:6379/1')],
        },
    },
}