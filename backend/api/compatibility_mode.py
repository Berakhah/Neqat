import uuid
from django.db import models
# from mssql.operations import DatabaseOperations

# --- Removed custom uuid_converter and DB converter patch to avoid double conversion with mssql backend ---
# def uuid_converter(value, expression, connection):
#    if value is not None and not isinstance(value, uuid.UUID):
#         value = uuid.UUID(value)
#    return value

# from django.db.backends.base.operations import BaseDatabaseOperations
# original_get_db_converters = BaseDatabaseOperations.get_db_converters
#
# def patched_get_db_converters(self, expression):
#     converters = original_get_db_converters(self, expression)
#     if isinstance(getattr(expression, 'output_field', None), models.UUIDField):
#         converters.append(uuid_converter)
#     return converters
#
# BaseDatabaseOperations.get_db_converters = patched_get_db_converters

# Ensure UUIDs get stored as strings
original_get_prep_value = models.UUIDField.get_prep_value

def patched_get_prep_value(self, value):
    if value is None:
        return None
    if isinstance(value, uuid.UUID):
        return str(value)
    try:
        return str(uuid.UUID(value))
    except (AttributeError, ValueError):
        return value

models.UUIDField.get_prep_value = patched_get_prep_value 