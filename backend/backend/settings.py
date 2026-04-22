import os
from pathlib import Path
from datetime import timedelta
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = 'qh!n$8$44^hlgyh%d=4^l)btia8p#hkfec8=d#z | 000@=*%=3g'

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = True

ALLOWED_HOSTS = ['localhost','192.168.10.102', '127.0.0.1', '10.0.2.2', '192.168.1.4', '192.168.8.104','192.168.100.10','10.1.1.4', '10.42.0.93','192.168.100.10','192.168.226.99', '172.20.10.4', '192.168.170.99', '192.168.180.99']

# Add CSRF trusted origins for production (required for POST requests from Flutter)
CSRF_TRUSTED_ORIGINS = [
    'http://localhost:8000',
    'http://127.0.0.1:8000',
    'http://10.0.2.2:8000',
    'http://192.168.1.4:8000',
    'http://192.168.8.104:8000',
    'http://192.168.100.10:8000',
    'http://10.1.1.4:8000',
    'http://10.42.0.93:8000',
    'http://192.168.226.99:8000',
    'http://192.168.170.99:8000',
    'http://192.168.180.99:8000',
    'http://192.168.10.102:8000'
]
# CORS Configuration
CORS_ALLOW_ALL_ORIGINS = True  # Only for development
CORS_ALLOW_CREDENTIALS = True
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
    'access-control-allow-origin',
    'access-control-allow-headers',
    'access-control-allow-methods',
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
    # 'api.middleware.SystemLogMiddleware',  # Temporarily disabled for testing
    'api.middleware.UUIDMiddleware',  # Added for UUID serialization
]

ROOT_URLCONF = 'backend.urls'
TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],  # Added for custom templates if needed
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

WSGI_APPLICATION = 'backend.wsgi.application'

# Database Configuration
# Using SQLite for development (easier to set up)
# DATABASES = {
#     'default': {
#         'ENGINE': 'django.db.backends.sqlite3',
#         'NAME': BASE_DIR / 'db.sqlite3',
#     },
# }

# SQL Server configuration 
DATABASES = {
    'default': {
        'ENGINE': 'mssql',  # Requires 'mssql-django' package
        'NAME': 'NeqatDB',
        'HOST': 'localhost',
        'PORT': '1433',
        'USER': 'SA',
        'PASSWORD': 'ChangeMe_Dev123!',
        'OPTIONS': {
            'driver': 'ODBC Driver 18 for SQL Server',
            'extra_params': 'TrustServerCertificate=yes',  # May be needed for local development
        },
    },
}

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

# Internationalization
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

# Static files (CSS, JavaScript, Images)
STATIC_URL = '/static/'
STATICFILES_DIRS = [BASE_DIR / 'static']  # Added for custom static files
STATIC_ROOT = BASE_DIR / 'staticfiles'  # For collectstatic in production

# Media files (User-uploaded content)
MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

# Default primary key field type
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# Custom User Model
AUTH_USER_MODEL = 'api.NeqatUser'

# REST Framework Configuration
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
        'rest_framework.authentication.SessionAuthentication',  # Added for development
    ),
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.IsAuthenticated',
    ),
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 100,
    'DEFAULT_RENDERER_CLASSES': (
        'rest_framework.renderers.JSONRenderer',
        'rest_framework.renderers.BrowsableAPIRenderer',
    ),
    'UNAUTHENTICATED_USER': None,  # This ensures unauthenticated requests are handled properly
    'EXCEPTION_HANDLER': 'rest_framework.views.exception_handler',  # Added for better error handling
}

# Simple JWT Configuration
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=60),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=1),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
    'SIGNING_KEY': SECRET_KEY,
    'AUTH_HEADER_TYPES': ('Bearer',),
}

# Authentication Backends
AUTHENTICATION_BACKENDS = (
    'social_core.backends.google.GoogleOAuth2',
    'social_core.backends.twitter.TwitterOAuth',
    'social_core.backends.github.GithubOAuth2',
    'django.contrib.auth.backends.ModelBackend',
)

# Social Auth Configuration
# Google
SOCIAL_AUTH_GOOGLE_OAUTH2_KEY = '162490596813-40a51nrtjtho4v6s0j6dcebdlno6jnoe.apps.googleusercontent.com'
SOCIAL_AUTH_GOOGLE_OAUTH2_SECRET = ''  # Add your Google OAuth2 secret here
SOCIAL_AUTH_GOOGLE_OAUTH2_SCOPE = ['email', 'profile']

# Twitter
SOCIAL_AUTH_TWITTER_KEY = 'your-twitter-api-key'  # Add your Twitter API Key
SOCIAL_AUTH_TWITTER_SECRET = 'your-twitter-api-secret'  # Add your Twitter API Secret

# GitHub
SOCIAL_AUTH_GITHUB_KEY = 'your-github-client-id'  # Add your GitHub Client ID
SOCIAL_AUTH_GITHUB_SECRET = 'your-github-client-secret'  # Add your GitHub Client Secret
SOCIAL_AUTH_GITHUB_SCOPE = ['user:email']

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
SOCIAL_AUTH_REDIRECT_URI = 'http://localhost:8000/auth/complete/google-oauth2/'
SOCIAL_AUTH_TWITTER_REDIRECT_URI = 'http://localhost:8000/auth/complete/twitter/'
SOCIAL_AUTH_GITHUB_REDIRECT_URI = 'http://localhost:8000/auth/complete/github/'

# Email Configuration for development
EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'
# Uncomment below for production with real email delivery
# EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
# EMAIL_HOST = 'smtp.gmail.com'
# EMAIL_PORT = 587
# EMAIL_USE_TLS = True
# EMAIL_HOST_USER = 'your-email@gmail.com'
# EMAIL_HOST_PASSWORD = 'your-app-password'
DEFAULT_FROM_EMAIL = 'noreply@neqat.com'

# Security Settings (for production)
SECURE_SSL_REDIRECT = False  # Set to True in production with HTTPS
SESSION_COOKIE_SECURE = False  # Set to True in production with HTTPS
CSRF_COOKIE_SECURE = False  # Set to True in production with HTTPS
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = 'DENY'

# Import compatibility mode for UUID handling
try:
    import api.compatibility_mode
    print("UUID compatibility mode enabled for SQL Server")
except ImportError:
    pass