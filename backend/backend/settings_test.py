# backend/settings_test.py
from .settings import *        # import all your normal settings
from pathlib import Path
from django.db.backends.signals import connection_created
import uuid
from django.dispatch import receiver


# use an in-memory SQLite database for *all* tests
DATABASES = {
    "default": {
        "ENGINE":   "django.db.backends.sqlite3",
        "NAME":     ":memory:",
    }

}

# speed up password hashing for tests
PASSWORD_HASHERS = [
    "django.contrib.auth.hashers.MD5PasswordHasher",
]

# stubbing out any external services here
# e.g. send all emails to the console
EMAIL_BACKEND = "django.core.mail.backends.locmem.EmailBackend"


# e.g. CELERY_TASK_ALWAYS_EAGER = True
MIGRATION_MODULES = {
    "api": None,
}


from django.db.backends.signals import connection_created
from django.dispatch import receiver

@receiver(connection_created)
def _add_sqlite_collations(sender, connection, **kwargs):
    # only for SQLite in tests
    if connection.vendor == "sqlite":
        # this must match exactly the db_collation you used in your fields
        collation_name = "Latin1_General_100_CI_AS_SC_UTF8"
        # register a trivial Python comparison function
        connection.connection.create_collation(
            collation_name,
            lambda a, b: (a > b) - (a < b)
        )


@receiver(connection_created)
def _patch_sqlite_uuid_conversion(sender, connection, **kwargs):
    if connection.vendor == "sqlite":
        # register your custom collation
        connection.connection.create_collation(
            "Latin1_General_100_CI_AS_SC_UTF8",
            lambda a, b: (a > b) - (a < b),
        )

        # monkey-patch convert_uuidfield_value
        def safe_convert_uuid(value, expression, conn):
            # if it's already a UUID instance, or it's NULL/None, just return it
            if value is None or isinstance(value, uuid.UUID):
                return value
            # otherwise assume it's a string and parse it
            return uuid.UUID(value)

        connection.ops.convert_uuidfield_value = safe_convert_uuid

