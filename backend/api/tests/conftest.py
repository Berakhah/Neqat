import os
import django
import pytest
from rest_framework.test import APIClient

# This fixture ensures Django is set up and apps are loaded before tests run
@pytest.fixture(scope='session')
def django_db_setup(django_test_environment, django_db_blocker):
    """Fixture to ensure Django's test environment and apps are set up."""
    if not django.apps.apps.ready:
        try:
            django.setup()
        except Exception as e:
            # This might catch and reveal the exact import error if it's still happening during setup
            print(f"Error during django.setup(): {e}")
            raise # Re-raise the exception

    # Explicitly import your models after setup
    # This can sometimes force the app registry to load correctly
    try:
        from api import models as api_models
        # Accessing a model can also help ensure the app is ready
        api_models.NeqatUser # Access the model to trigger potential loading issues here
        api_models.Post
        api_models.SystemLog
        api_models.UserActivity
    except django.core.exceptions.AppRegistryNotReady as e:
         print(f"AppRegistryNotReady error after django.setup(): {e}")
         raise # Re-raise the exception
    except Exception as e:
         print(f"Unexpected error during model import after django.setup(): {e}")
         raise # Re-raise the exception


    with django_db_blocker.unblock():
        # You can add any initial database setup here if needed
        pass

# NEW FIXTURE: Temporarily remove admin during tests
@pytest.fixture(scope='session', autouse=True)
def disable_admin_during_tests(settings):
    """Temporarily remove 'django.contrib.admin' from INSTALLED_APPS for tests."""
    original_installed_apps = settings.INSTALLED_APPS
    settings.INSTALLED_APPS = [
        app for app in original_installed_apps if app != 'django.contrib.admin'
    ]
    yield # Allow tests to run
    settings.INSTALLED_APPS = original_installed_apps # Restore original settings

@pytest.fixture
def api_client():
    return APIClient()

@pytest.fixture
def admin_user(db):
    from django.contrib.auth import get_user_model # Import here
    User = get_user_model()
    return User.objects.create_user(username='admin', is_superuser=True)

@pytest.fixture
def editor_user(db):
    from django.contrib.auth import get_user_model # Import here
    User = get_user_model()
    return User.objects.create_user(username='editor')

@pytest.fixture
def normal_user(db):
    from django.contrib.auth import get_user_model # Import here
    User = get_user_model()
    return User.objects.create_user(username='user')

@pytest.fixture
def admin_token(admin_user):
    # Replace with your Keycloak token retrieval logic or mock
    return "admin_jwt_token"

@pytest.fixture
def editor_token(editor_user):
    return "editor_jwt_token"

@pytest.fixture
def user_token(normal_user):
    return "user_jwt_token"

@pytest.fixture
def post_owned_by_user(db, normal_user):
    from api.models import Post
    return Post.objects.create(title="User's Post", content="...", created_by=normal_user)

@pytest.fixture
def post_not_owned_by_user(db, editor_user):
    from api.models import Post
    return Post.objects.create(title="Editor's Post", content="... test content", created_by=editor_user) 