# Keycloak Configuration for Proper Token Audience Validation

This document outlines how to configure Keycloak to issue tokens with proper audience (`aud`) claims that will validate successfully in your Neqat application.

## Understanding the Audience Issue

The JWT audience (`aud`) claim identifies the intended recipients of the token. In a multi-service environment like Neqat, you have:

- The Flutter front-end (client)
- The Django backend (resource server)
- Potentially other services

When tokens are issued, Keycloak needs to include the correct audience values in the tokens to ensure all services that need to validate the tokens can do so.

## Configuring Keycloak Clients

### 1. Create Client for your Flutter App

1. Log in to the Keycloak Admin Console
2. Select your realm (`neqat-realm`)
3. Go to "Clients" → "Create client"
4. Enter the following:
   - **Client ID**: `flutter-client` (must match `KeycloakConfig.clientId`)
   - **Client type**: `OpenID Connect`
   - **Client authentication**: `On` (for confidential clients)
5. On the next screen, configure:
   - **Root URL**: `http://localhost:8000` (or your app's URL)
   - **Valid redirect URIs**: Add your app's redirect URIs
   - **Web origins**: Set appropriate CORS origins

### 2. Configure Resource Server Client (Backend)

1. Create another client for your backend:
   - **Client ID**: `backend-service` (must match `KeycloakConfig.backendClientId`)
   - **Client type**: `OpenID Connect`
   - **Client authentication**: `On`
2. On the next screen, configure:
   - **Service accounts roles**: `Enabled` (allows client credential flow)
   - **Authorization**: `Enabled` (if you need fine-grained authorization)

### 3. Configure Audience Mappers

For your Flutter client to receive tokens that include both itself AND the backend as audiences:

1. In your flutter-client, go to "Client scopes" tab
2. Click on the dedicated client scope (usually named `flutter-client-dedicated`)
3. Go to "Mappers" tab
4. Click "Create" and add an audience mapper:
   - **Name**: `backend-audience-mapper`
   - **Mapper type**: `Audience`
   - **Included Client Audience**: Select your backend client (`backend-service`)
   - **Add to ID token**: `On`
   - **Add to access token**: `On`

This ensures tokens issued to your Flutter client also include the backend service in the audience claim.

### 4. Configure your Backend Client for Token Exchange (optional)

If you're using token exchange between services:

1. In your backend-service client settings, go to "Advanced" tab
2. Enable "Fine-grain OpenID Connect configuration" 
3. Set "Access token audience" to include both client IDs

## Environment Configuration

Ensure your `.env` file (or environment variables) includes:

```
KEYCLOAK_URL=http://localhost:8080
KEYCLOAK_REALM=neqat-realm
KEYCLOAK_CLIENT_ID=flutter-client
KEYCLOAK_CLIENT_SECRET=your-client-secret  # From Client > Credentials tab
KEYCLOAK_BACKEND_CLIENT_ID=backend-service
```

## Validating in Development

To debug audience validation issues:

1. Open your browser's developer tools when logged in
2. Find a request with an Authorization header
3. Copy the token (without "Bearer ")
4. Go to [jwt.io](https://jwt.io/) and paste the token
5. Check the "aud" claim in the payload section
6. Verify it includes the expected audience values

## Keycloak Configuration for Django Backend

If you're using Django with a Keycloak adapter, configure the adapter with a similar list of accepted audiences:

```python
# settings.py
OIDC_CONFIG = {
    'OIDC_RP_CLIENT_ID': 'backend-service',
    'OIDC_RP_CLIENT_SECRET': 'your-client-secret',
    'OIDC_ACCEPT_AUDIENCE': ['backend-service', 'flutter-client', 'account'],
    # Other OIDC settings...
}
```

This ensures the Django backend can validate tokens that were issued to the Flutter client but are being used to access backend resources.

## Troubleshooting

Common issues:

- **Token audience mismatch**: Check the audience mapper is correctly configured and the audience in the issued token matches what your application expects.
- **No audience in token**: Ensure the audience mapper is added to the client scope and is set to be included in access tokens.
- **Issuer mismatch**: The issuer URL in your app config must exactly match the Keycloak issuer URL, including protocol, host, port, and realm path.

Remember to clear browser cookies and app storage when making changes to Keycloak configuration as old tokens might still be in use. 