import os

# IMPORTANT: Set this to a strong, base64-encoded 32-byte key in your environment or .env file
ENCRYPTED_MODEL_FIELDS_KEY = os.getenv('ENCRYPTED_MODEL_FIELDS_KEY')
 
# For django-encrypted-model-fields compatibility
FIELD_ENCRYPTION_KEY = ENCRYPTED_MODEL_FIELDS_KEY  # Should be set to REPLACE_WITH_YOUR_BASE64_KEY in your environment 