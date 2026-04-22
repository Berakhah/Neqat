import requests
import base64
import json
from django.core.management.base import BaseCommand
from api.models import NeqatUser
from django.conf import settings
import logging

logger = logging.getLogger(__name__)

class Command(BaseCommand):
    help = 'Synchronize Keycloak IDs for users missing them'
    
    def add_arguments(self, parser):
        parser.add_argument('--admin-user', type=str, default='admin',
                          help='Admin username for Keycloak access')
        parser.add_argument('--admin-password', type=str, default='NEQ@T2025',
                          help='Admin password for Keycloak access')
        parser.add_argument('--dry-run', action='store_true',
                          help='Only show what would be done without making changes')
    
    def decode_jwt(self, token):
        """Decode a JWT token without validation."""
        if not token:
            return {}
        
        try:
            parts = token.split('.')
            if len(parts) != 3:
                return {}
            
            # Add padding if needed
            payload = parts[1]
            payload += '=' * (4 - len(payload) % 4)
            
            # Decode payload
            decoded_bytes = base64.b64decode(payload)
            decoded_str = decoded_bytes.decode('utf-8')
            return json.loads(decoded_str)
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"Failed to decode JWT: {str(e)}"))
            return {}
    
    def get_admin_token(self, admin_username, admin_password):
        """Get an admin token from Keycloak."""
        try:
            self.stdout.write(f"Authenticating admin user: {admin_username}")
            
            # Build token endpoint URL directly with localhost
            token_endpoint = f"http://localhost:8080/realms/{settings.KEYCLOAK_CONFIG['KEYCLOAK_REALM']}/protocol/openid-connect/token"
            
            # Make POST request to get token
            response = requests.post(
                token_endpoint,
                headers={"Content-Type": "application/x-www-form-urlencoded"},
                data={
                    "client_id": settings.KEYCLOAK_CONFIG['KEYCLOAK_CLIENT_ID'],
                    "client_secret": settings.KEYCLOAK_CONFIG['KEYCLOAK_CLIENT_SECRET'],
                    "grant_type": "client_credentials"
                },
                verify=False  # For testing only
            )
            
            if response.status_code == 200:
                token_data = response.json()
                self.stdout.write(self.style.SUCCESS("Admin authentication successful with client credentials"))
                return token_data.get("access_token")
            else:
                self.stdout.write(self.style.WARNING(f"Client credentials auth failed: {response.status_code}"))
                self.stdout.write(self.style.WARNING(f"Response: {response.text}"))
                
                # Try using direct admin password grant
                self.stdout.write("Trying with direct password grant...")
                admin_response = requests.post(
                    token_endpoint,
                    headers={"Content-Type": "application/x-www-form-urlencoded"},
                    data={
                        "client_id": "admin-cli",
                        "username": admin_username,
                        "password": admin_password,
                        "grant_type": "password"
                    },
                    verify=False
                )
                
                if admin_response.status_code == 200:
                    admin_token_data = admin_response.json()
                    self.stdout.write(self.style.SUCCESS("Admin authentication successful with password grant"))
                    return admin_token_data.get("access_token")
                else:
                    self.stdout.write(self.style.ERROR(f"Password grant auth failed: {admin_response.status_code}"))
                    self.stdout.write(self.style.ERROR(f"Response: {admin_response.text}"))
                    
                    # Try master realm as last resort
                    self.stdout.write("Trying with master realm...")
                    master_response = requests.post(
                        "http://localhost:8080/realms/master/protocol/openid-connect/token",
                        headers={"Content-Type": "application/x-www-form-urlencoded"},
                        data={
                            "client_id": "admin-cli",
                            "username": admin_username,
                            "password": admin_password,
                            "grant_type": "password"
                        },
                        verify=False
                    )
                    
                    if master_response.status_code == 200:
                        master_token_data = master_response.json()
                        self.stdout.write(self.style.SUCCESS("Admin authentication successful with master realm"))
                        return master_token_data.get("access_token")
                    else:
                        self.stdout.write(self.style.ERROR(f"Master realm auth failed: {master_response.status_code}"))
                        return None
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"Authentication request failed: {str(e)}"))
            return None
    
    def find_keycloak_user_by_email(self, email, admin_token):
        """Find a Keycloak user by email."""
        try:
            # Build user endpoint URL
            users_endpoint = f"http://localhost:8080/admin/realms/{settings.KEYCLOAK_CONFIG['KEYCLOAK_REALM']}/users"
            
            # Make GET request to find users
            params = {
                "email": email,
                "exact": "true"
            }
            
            headers = {
                "Authorization": f"Bearer {admin_token}",
                "Content-Type": "application/json"
            }
            
            response = requests.get(
                users_endpoint,
                headers=headers,
                params=params,
                verify=False
            )
            
            if response.status_code == 200:
                users = response.json()
                if len(users) > 0:
                    # Return the first matching user
                    return users[0]
                else:
                    self.stdout.write(self.style.WARNING(f"No Keycloak user found with email: {email}"))
                    return None
            else:
                self.stdout.write(self.style.ERROR(f"Failed to find Keycloak user: {response.status_code}"))
                self.stdout.write(self.style.ERROR(f"Response: {response.text}"))
                return None
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"Error finding Keycloak user: {str(e)}"))
            return None
    
    def handle(self, *args, **options):
        admin_username = options['admin_user']
        admin_password = options['admin_password']
        dry_run = options['dry_run']
        
        # Get admin token
        admin_token = self.get_admin_token(admin_username, admin_password)
        if not admin_token:
            self.stdout.write(self.style.ERROR("Failed to get admin token. Cannot continue."))
            return
        
        # Find users without Keycloak ID
        users_without_keycloak_id = NeqatUser.objects.filter(keycloak_id__isnull=True) | NeqatUser.objects.filter(keycloak_id='')
        
        self.stdout.write(f"Found {users_without_keycloak_id.count()} users without Keycloak ID")
        
        if dry_run:
            self.stdout.write(self.style.WARNING("DRY RUN - No changes will be made"))
        
        # Process each user
        synced_users = 0
        for user in users_without_keycloak_id:
            self.stdout.write(f"Processing user: {user.user_name} ({user.email})")
            
            # Find user in Keycloak
            keycloak_user = self.find_keycloak_user_by_email(user.email, admin_token)
            
            if keycloak_user:
                keycloak_id = keycloak_user.get("id")
                self.stdout.write(self.style.SUCCESS(f"Found Keycloak user with ID: {keycloak_id}"))
                
                if not dry_run:
                    # Update Django user with Keycloak ID
                    user.keycloak_id = keycloak_id
                    user.save(update_fields=['keycloak_id'])
                    self.stdout.write(self.style.SUCCESS(f"Updated user {user.user_name} with Keycloak ID: {keycloak_id}"))
                    synced_users += 1
                else:
                    self.stdout.write(self.style.WARNING(f"DRY RUN - Would update user {user.user_name} with Keycloak ID: {keycloak_id}"))
            else:
                self.stdout.write(self.style.ERROR(f"No matching Keycloak user found for {user.user_name} ({user.email})"))
        
        # Print summary
        if dry_run:
            self.stdout.write(self.style.SUCCESS(f"DRY RUN - Would have synchronized {synced_users} out of {users_without_keycloak_id.count()} users"))
        else:
            self.stdout.write(self.style.SUCCESS(f"Successfully synchronized {synced_users} out of {users_without_keycloak_id.count()} users")) 