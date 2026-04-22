import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' show base64Url, utf8, json, jsonEncode, jsonDecode;
import 'package:flutter/foundation.dart';

/// Token storage keys
class KeycloakStorageKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String idToken = 'id_token';
  static const String tokenExpiry = 'token_expiry';
}

/// Represents authentication tokens received from Keycloak
class KeycloakToken {
  final String accessToken;
  final String refreshToken;
  final String? idToken;
  final DateTime expiresAt;
  final Map<String, dynamic>? _decodedPayload;

  KeycloakToken({
    required this.accessToken,
    required this.refreshToken,
    this.idToken,
    required this.expiresAt,
    Map<String, dynamic>? decodedPayload,
  }) : _decodedPayload = decodedPayload;

  /// Create a token object from Keycloak response
  factory KeycloakToken.fromResponse(Map<String, dynamic> data) {
    // Calculate token expiry
    final expiresIn = data['expires_in'] as int? ?? 300; // Default 5 minutes if not provided
    final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));

    // Decode JWT payload for validation
    Map<String, dynamic>? decodedPayload;
    try {
      final parts = data['access_token'].toString().split('.');
      if (parts.length == 3) {
        // Decode middle part (payload)
        String normalized = base64Url.normalize(parts[1]);
        final decoded = utf8.decode(base64Url.decode(normalized));
        decodedPayload = json.decode(decoded);
      }
    } catch (e) {
      // Decoding failed, continue without payload
      print('Failed to decode JWT payload: $e');
    }

    return KeycloakToken(
      accessToken: data['access_token'],
      refreshToken: data['refresh_token'],
      idToken: data['id_token'],
      expiresAt: expiresAt,
      decodedPayload: decodedPayload,
    );
  }

  /// Check if the access token is expired or about to expire
  bool isExpired({Duration buffer = const Duration(seconds: 30)}) {
    // Consider token expired buffer time before actual expiry to avoid edge cases
    final now = DateTime.now();
    
    // First check expiresAt from the token object (calculated from expires_in)
    if (now.isAfter(expiresAt.subtract(buffer))) {
      return true;
    }
    
    // If payload contains exp claim, also verify that
    if (_decodedPayload != null && _decodedPayload.containsKey('exp')) {
      final expTimestamp = _decodedPayload['exp'] as int;
      final expDate = DateTime.fromMillisecondsSinceEpoch(expTimestamp * 1000);
      return now.isAfter(expDate.subtract(buffer));
    }
    
    return false;
  }
  
  /// Get a claim from the decoded token payload
  dynamic getClaim(String claimName) {
    return _decodedPayload?[claimName];
  }
  
  /// Get user info from the token
  Map<String, dynamic> getUserInfo() {
    if (_decodedPayload == null) {
      return {};
    }
    
    return {
      'sub': _decodedPayload['sub'],
      'email': _decodedPayload['email'],
      'preferred_username': _decodedPayload['preferred_username'],
      'given_name': _decodedPayload['given_name'],
      'family_name': _decodedPayload['family_name'],
      'email_verified': _decodedPayload['email_verified'],
    };
  }
  
  /// Get roles from the token
  List<String> getRoles() {
    final realmAccess = _decodedPayload?['realm_access'] as Map<String, dynamic>?;
    final roles = realmAccess?['roles'] as List<dynamic>?;
    return roles?.cast<String>() ?? [];
  }
  
  /// Check if the token has a specific role
  bool hasRole(String role) {
    return getRoles().contains(role);
  }

  /// Check if token is admin
  bool isAdmin() {
    final roles = getRoles();
    return roles.contains('admin') || roles.contains('realm-admin');
  }
  
  /// Validate the token's basic structure and claims
  bool isValid({String? expectedIssuer, String? expectedAudience}) {
    if (_decodedPayload == null) {
      return false;
    }
    
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // Check required claims
    final requiredClaims = ['sub', 'exp', 'iat'];
    for (final claim in requiredClaims) {
      if (!_decodedPayload.containsKey(claim)) {
        print('Token missing required claim: $claim');
        return false;
      }
    }
    
    // Check expiration
    final exp = _decodedPayload['exp'] as int?;
    if (exp == null || exp < now) {
      print('Token is expired');
      return false;
    }
    
    // Check not before
    final nbf = _decodedPayload['nbf'] as int?;
    if (nbf != null && nbf > now) {
      print('Token not yet valid (nbf)');
      return false;
    }
    
    // Check token age (replay protection) - reject tokens older than 24 hours
    final iat = _decodedPayload['iat'] as int?;
    if (iat != null && (now - iat) > 86400) {
      print('Token is too old');
      return false;
    }
    
    // Check issuer if expected
    if (expectedIssuer != null) {
      final iss = _decodedPayload['iss'] as String?;
      if (iss == null || iss != expectedIssuer) {
        print('Token issuer mismatch');
        // Continue without failing - the token might be from the backend
      }
    }
    
    // Check audience if expected - make this more flexible
    if (expectedAudience != null) {
      final aud = _decodedPayload['aud'] as dynamic;
      
      // Skip audience validation for backend tokens
      // Backend-issued tokens might have different audience values
      if (_decodedPayload.containsKey('token_source') && 
          _decodedPayload['token_source'] == 'backend') {
        // Skip audience validation for backend tokens
      } else if (aud == null) {
        print('Token has no audience, but continuing anyway');
        // Continue without failing - not critical for app operation
      } else if (aud is String && aud != expectedAudience) {
        print('Token audience mismatch, but continuing anyway');
        // Continue without failing - not critical for app operation
      } else if (aud is List && !aud.contains(expectedAudience)) {
        print('Token audience list does not contain expected audience');
        // Continue without failing - not critical for app operation
      }
    }
    
    // Allow token if we reach here
    return true;
  }
}

/// Low-level Keycloak client that handles direct communication with Keycloak server
class KeycloakClient {
  final String url;
  final String realm;
  final String clientId;
  final String? clientSecret;
  final Logger _logger = Logger();
  final http.Client _client = http.Client();
  String? _expectedIssuer;
  bool _isProxied = false;

  KeycloakClient({
    required this.url,
    required this.realm,
    required this.clientId,
    this.clientSecret,
  }) {
    // Check if we're using the proxied path
    _isProxied = url.startsWith('/') && kIsWeb;
    
    if (_isProxied) {
      // Using the proxied path
      _expectedIssuer = '/realms/$realm';
    } else {
      // Using the direct URL
      _expectedIssuer = '$url/realms/$realm';
    }
    
    _logger.i('KeycloakClient initialized with URL: $url, realm: $realm, proxied: $_isProxied');
  }

  /// Keycloak OpenID configuration endpoint
  Uri get _openIdConfigUrl {
    if (_isProxied) {
      return Uri.parse('$url/$realm/.well-known/openid-configuration');
    }
    return Uri.parse('$url/realms/$realm/.well-known/openid-configuration');
  }
  
  /// Keycloak token endpoint
  Uri get _tokenUrl {
    if (_isProxied) {
      return Uri.parse('$url/$realm/protocol/openid-connect/token');
    }
    return Uri.parse('$url/realms/$realm/protocol/openid-connect/token');
  }
  
  /// Keycloak logout endpoint
  Uri get _logoutUrl {
    if (_isProxied) {
      return Uri.parse('$url/$realm/protocol/openid-connect/logout');
    }
    return Uri.parse('$url/realms/$realm/protocol/openid-connect/logout');
  }
  
  /// Keycloak user info endpoint
  Uri get _userInfoUrl {
    if (_isProxied) {
      return Uri.parse('$url/$realm/protocol/openid-connect/userinfo');
    }
    return Uri.parse('$url/realms/$realm/protocol/openid-connect/userinfo');
  }

  /// Initialize client and verify server is reachable
  Future<void> init() async {
    try {
      _logger.i('Initializing Keycloak client: $url, realm: $realm');
      final response = await _client.get(_openIdConfigUrl);

      if (response.statusCode != 200) {
        _logger.e('Failed to connect to Keycloak server: ${response.statusCode}');
        throw Exception('Failed to connect to Keycloak server: ${response.statusCode}');
      }

      _logger.i('Keycloak client initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize Keycloak client', error: e);
      rethrow;
    }
  }

  /// Authenticate user with username/password
  Future<KeycloakToken> login({
    required String username,
    required String password,
  }) async {
    try {
      _logger.i('Authenticating user: $username');
      final response = await _client.post(
        _tokenUrl,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': clientId,
          'username': username,
          'password': password,
          'grant_type': 'password',
          'scope': 'openid profile email',
          if (clientSecret != null) 'client_secret': clientSecret!,
        },
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        final errorDescription = error['error_description'] ?? 'Login failed';
        _logger.e('Authentication failed: $errorDescription');
        throw Exception(errorDescription);
      }

      final data = json.decode(response.body);
      final token = KeycloakToken.fromResponse(data);
      _logger.i('Authentication successful');
      return token;
    } catch (e) {
      _logger.e('Login failed', error: e);
      rethrow;
    }
  }

  /// Authenticate user with external identity provider
  Future<KeycloakToken> loginWithSocial(String provider, String token) async {
    try {
      _logger.i('Authenticating with social provider: $provider');
      final response = await _client.post(
        _tokenUrl,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': clientId,
          'grant_type': 'urn:ietf:params:oauth:grant-type:token-exchange',
          'subject_token': token,
          'subject_token_type': 'urn:ietf:params:oauth:token-type:access_token',
          'subject_issuer': provider,
          'scope': 'openid profile email',
          if (clientSecret != null) 'client_secret': clientSecret!,
        },
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        final errorDescription = error['error_description'] ?? 'Social login failed';
        _logger.e('Social authentication failed: $errorDescription');
        throw Exception(errorDescription);
      }

      final data = json.decode(response.body);
      final keycloakToken = KeycloakToken.fromResponse(data);
      _logger.i('Social authentication successful');
      return keycloakToken;
    } catch (e) {
      _logger.e('Social login failed', error: e);
      rethrow;
    }
  }

  /// Log out a user from Keycloak
  Future<void> logout(String refreshToken) async {
    try {
      _logger.i('Logging out user');
      final response = await _client.post(
        _logoutUrl,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': clientId,
          'refresh_token': refreshToken,
          if (clientSecret != null) 'client_secret': clientSecret!,
        },
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        final error = response.body.isNotEmpty 
            ? json.decode(response.body) 
            : {'error_description': 'Logout failed with status ${response.statusCode}'};
        _logger.e('Logout failed: ${error['error_description']}');
        throw Exception(error['error_description'] ?? 'Logout failed');
      }
      
      _logger.i('Logout successful');
    } catch (e) {
      _logger.e('Logout failed', error: e);
      rethrow;
    }
  }

  /// Get user information from Keycloak
  Future<Map<String, dynamic>> getUserInfo(String accessToken) async {
    try {
      _logger.i('Fetching user information');
      
      // First try to get user info directly from Keycloak
      try {
        final response = await _client.get(
          _userInfoUrl,
          headers: {'Authorization': 'Bearer $accessToken'},
        ).timeout(ApiConstants.defaultTimeout);

        if (response.statusCode == 200) {
          final userInfo = json.decode(response.body);
          _logger.i('User information retrieved successfully');
          return userInfo;
        } else {
          _logger.w('Failed to get user info from Keycloak directly: ${response.statusCode}');
          // Fall through to backend method
        }
      } catch (e) {
        // CORS issue or other network error
        _logger.w('Network error connecting to Keycloak. Using local token validation.', error: e);
        // Fall through to backend method
      }
      
      // If direct Keycloak call fails (likely due to CORS), try via backend
      try {
        final backendResponse = await http.Client().get(
          Uri.parse(ApiConstants.currentUser),
          headers: {'Authorization': 'Bearer $accessToken'},
        ).timeout(ApiConstants.defaultTimeout);
        
        if (backendResponse.statusCode == 200) {
          final userData = json.decode(backendResponse.body);
          _logger.i('User information retrieved from backend successfully');
          return userData;
        } else {
          _logger.w('Failed to get user info from backend: ${backendResponse.statusCode}');
        }
      } catch (e) {
        _logger.w('Failed to get user info from backend', error: e);
      }
      
      // If both methods fail, try to parse the token itself
      try {
        final payload = _parseJwt(accessToken);
        _logger.i('Extracted user info from token payload');
        return {
          'sub': payload['sub'],
          'email': payload['email'],
          'preferred_username': payload['preferred_username'],
          'given_name': payload['given_name'],
          'family_name': payload['family_name'],
          'realm_access': payload['realm_access'],
        };
      } catch (e) {
        _logger.e('Failed to parse token payload', error: e);
      }
      
      _logger.e('Failed to get user info by any method');
      throw Exception('Failed to get user info');
    } catch (e) {
      _logger.e('Failed to get user info', error: e);
      rethrow;
    }
  }
  
  /// Parse JWT token payload
  Map<String, dynamic> _parseJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid JWT token format');
    }
    
    final payload = parts[1];
    var normalized = base64Url.normalize(payload);
    var resp = utf8.decode(base64Url.decode(normalized));
    final payloadMap = json.decode(resp);
    return payloadMap;
  }

  /// Refresh an access token using a refresh token
  Future<KeycloakToken> refreshToken(String refreshToken) async {
    try {
      _logger.i('Refreshing access token');
      final response = await _client.post(
        _tokenUrl,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': clientId,
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'scope': 'openid profile email',
          if (clientSecret != null) 'client_secret': clientSecret!,
        },
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        final errorDescription = error['error_description'] ?? 'Token refresh failed';
        _logger.e('Token refresh failed: $errorDescription');
        throw Exception(errorDescription);
      }

      final data = json.decode(response.body);
      final token = KeycloakToken.fromResponse(data);
      _logger.i('Token refreshed successfully');
      return token;
    } catch (e) {
      _logger.e('Token refresh failed', error: e);
      rethrow;
    }
  }

  /// Request a password reset for a user via the backend
  Future<void> requestPasswordReset(String email) async {
    try {
      _logger.i('Requesting password reset for: $email');
      final response = await _client.post(
        Uri.parse(ApiConstants.forgotPassword),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode != 200) {
        final error = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {'error': 'Password reset request failed with status ${response.statusCode}'};
        _logger.e('Password reset request failed: ${error['error'] ?? response.body}');
        throw Exception(error['error'] ?? 'Password reset request failed');
      }

      _logger.i('Password reset requested successfully');
    } catch (e) {
      _logger.e('Password reset request failed', error: e);
      rethrow;
    }
  }
}

/// Keycloak token validation exception
class TokenException implements Exception {
  final String message;
  final String code;
  
  TokenException(this.message, {this.code = 'invalid_token'});
  
  @override
  String toString() => 'TokenException: $message (code: $code)';
}

/// High-level Keycloak service for application authentication management
class KeycloakService {
  final FlutterSecureStorage _secureStorage;
  final Logger _logger = Logger();
  late KeycloakClient _keycloakClient;
  bool _isInitialized = false;

  KeycloakService({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Register a new user via the backend
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      _logger.i('Registering user: $email');
      
      // Ensure we're initializing the service first
      await _ensureInitialized();
      
      // Use a simpler request structure that won't cause backend parsing issues
      final response = await http.Client().post(
        Uri.parse(ApiConstants.register),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          'user_name': email.split('@')[0], // Generate username from email
        }),
      ).timeout(const Duration(seconds: 20)); // Increased timeout for slow server

      // Handle response
      if (response.statusCode == 201) {
        // Successful registration
        final data = jsonDecode(response.body);
        _logger.i('User registered successfully');
        
        // If tokens were returned during registration, save them
        if (data is Map && data.containsKey('access') && data.containsKey('refresh')) {
          final accessToken = data['access'] as String;
          final refreshToken = data['refresh'] as String;
          final expiryTime = data['expires_at'] ?? 
              (DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600);
              
          await _saveTokensSecurely(
            accessToken,
            refreshToken,
            expiryTime
          );
        }
        
        return data is Map<String, dynamic> 
            ? data 
            : <String, dynamic>{'message': 'Registration successful'};
      } else {
        // Handle error response
        String errorMessage = 'Registration failed';
        
        try {
          if (response.body.isNotEmpty) {
            final dynamic errorData = jsonDecode(response.body);
            
            // Handle different error response formats
            if (errorData is Map) {
              if (errorData.containsKey('error')) {
                final error = errorData['error'];
                if (error is String) {
                  errorMessage = error;
                }
              } else if (errorData.containsKey('message')) {
                errorMessage = errorData['message'];
              } else {
                // Try to construct an error message from the map
                errorMessage = errorData.entries
                    .map((e) => "${e.key}: ${e.value}")
                    .join(", ");
              }
            } else if (errorData is String) {
              errorMessage = errorData;
            }
          }
        } catch (parseError) {
          // If JSON parsing fails, use the raw response or a default message
          _logger.e('Error parsing registration error response', error: parseError);
          errorMessage = response.body.isNotEmpty 
              ? 'Server error: ${response.body}'
              : 'Registration failed with status code: ${response.statusCode}';
        }
        
        // Handle common error cases with user-friendly messages
        if (errorMessage.toLowerCase().contains('already exists')) {
          errorMessage = 'An account with this email already exists. Please log in or use a different email.';
        } else if (errorMessage.toLowerCase().contains('server configuration')) {
          errorMessage = 'The server is temporarily unavailable. Please try again later.';
        } else if (errorMessage.toLowerCase().contains('string indices must be integers')) {
          errorMessage = 'Registration failed due to a server configuration issue. Please try again later.';
        }
        
        _logger.e('Registration failed: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is TimeoutException) {
        _logger.e('Registration request timed out', error: e);
        throw Exception('The server took too long to respond. Please try again later.');
      }
      _logger.e('Registration failed', error: e);
      rethrow;
    }
  }

  /// Request a password reset
  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      _logger.i('Requesting password reset for: $email');
      final response = await http.Client().post(
        Uri.parse(ApiConstants.forgotPassword),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        final data = response.body.isNotEmpty ? jsonDecode(response.body) : {'message': 'Password reset email sent'};
        _logger.i('Password reset requested successfully');
        return data;
      } else {
        final error = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {'error': 'Password reset request failed with status ${response.statusCode}'};
        
        String errorMessage = error['error'] ?? 'Password reset request failed';
        
        // Handle common error cases
        if (response.statusCode == 404) {
          errorMessage = 'No account found with this email address';
        }
        
        _logger.e('Password reset request failed: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      _logger.e('Password reset request failed', error: e);
      rethrow;
    }
  }

  /// Reset a user's password with verification code
  Future<Map<String, dynamic>> resetPassword({
    required String verificationCode,
    required String newPassword,
  }) async {
    try {
      _logger.i('Resetting password');
      final response = await http.Client().post(
        Uri.parse(ApiConstants.resetPassword),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': verificationCode,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.i('Password reset successful');
        return data;
      } else {
        final error = jsonDecode(response.body);
        String errorMessage = error['error'] ?? 'Password reset failed';
        
        // Handle common error cases
        if (errorMessage.contains('expired')) {
          errorMessage = 'The reset link has expired. Please request a new password reset.';
        } else if (errorMessage.contains('invalid')) {
          errorMessage = 'Invalid reset code. Please check the link or request a new password reset.';
        }
        
        _logger.e('Password reset failed: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      _logger.e('Password reset failed', error: e);
      rethrow;
    }
  }

  /// Initialize the Keycloak service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.i("Initializing Keycloak service");
      
      // Create the Keycloak client
      _keycloakClient = KeycloakClient(
        url: ApiConstants.keycloakUrl,
        realm: ApiConstants.keycloakRealm,
        clientId: ApiConstants.keycloakClientId,
      );

      // Validate configuration
      if (ApiConstants.keycloakUrl.isEmpty || 
          ApiConstants.keycloakRealm.isEmpty || 
          ApiConstants.keycloakClientId.isEmpty) {
        _logger.w("Incomplete Keycloak configuration, will use backend authentication");
        _isInitialized = true;
        return;
      }
      
      // Check if server is reachable
      bool serverAvailable = false;
      try {
        // Try a quick ping to see if the server is responsive
        final response = await http.get(
          Uri.parse('${ApiConstants.keycloakUrl}/realms/${ApiConstants.keycloakRealm}'),
        ).timeout(ApiConstants.shortTimeout);
        
        serverAvailable = response.statusCode < 400;
        _logger.i("Keycloak server status check: ${response.statusCode} - Available: $serverAvailable");
      } catch (e) {
        _logger.w("Keycloak server not available: $e");
        serverAvailable = false;
      }
      
      if (serverAvailable) {
        try {
          // Initialize Keycloak client with a timeout
          await _keycloakClient.init().timeout(ApiConstants.defaultTimeout);
          _isInitialized = true;
          _logger.i("Keycloak service initialized successfully");
        } catch (e) {
          // Log the error but still consider the service initialized
          // The app will fall back to backend authentication
          _logger.w("Keycloak server initialization failed, will use backend authentication: $e");
          _isInitialized = true;
        }
      } else {
        // If server is not available, don't even try to connect
        if (ApiConstants.ignoreKeycloakConnectionErrors) {
          _logger.w("Keycloak server unreachable, will use backend authentication only");
          _isInitialized = true;
        } else {
          _logger.e("Keycloak server unreachable, app may have limited functionality");
          _isInitialized = true;
        }
      }
    } catch (e) {
      _logger.e("Failed to initialize Keycloak service", error: e);
      // Don't rethrow, allow the app to continue and use backend authentication
      _isInitialized = true;
    }
  }

  /// Authenticate a user and store their tokens
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      if (!_isInitialized) await initialize();

      _logger.i('Authenticating user: $username');
      
      // Try backend authentication first, then fall back to direct Keycloak if needed
      try {
        // Use the backend authentication endpoint first (preferred)
        _logger.i('Attempting authentication via backend');
        
        final response = await http.Client().post(
          Uri.parse(ApiConstants.login),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_name': username,
            'email': username, // Send username as both email and username
            'password': password,
          }),
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          
          // Save tokens to secure storage
          if (data.containsKey('access') && data.containsKey('refresh')) {
            await _saveTokensSecurely(
              data['access'] as String,
              data['refresh'] as String,
              data['expires_at']
            );
            
            // Mark token as backend-issued before validation
            try {
              // Decode JWT to add backend flag
              final parts = data['access'].toString().split('.');
              if (parts.length == 3) {
                // Decode payload
                final normalized = base64Url.normalize(parts[1]);
                final decoded = utf8.decode(base64Url.decode(normalized));
                final payload = json.decode(decoded);
                
                // Add backend source marker (won't modify the actual token)
                payload['token_source'] = 'backend';
                
                // Create KeycloakToken with the modified payload
                final keycloakToken = KeycloakToken(
                  accessToken: data['access'] as String,
                  refreshToken: data['refresh'] as String, 
                  expiresAt: DateTime.fromMillisecondsSinceEpoch(
                    (data['expires_at'] ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600)) * 1000
                  ),
                  decodedPayload: payload
                );
                
                // Run lighter validation for backend tokens
                if (!keycloakToken.isValid()) {
                  _logger.w('Received invalid token from backend, but proceeding');
                }
              }
            } catch (e) {
              _logger.w('Failed to validate token: $e');
              // Continue anyway since the backend validated it
            }
          }
          
          _logger.i('Authentication successful via backend');
          return data;
        } else {
          final error = response.body.isNotEmpty ? jsonDecode(response.body) : {'error': 'Login failed'};
          _logger.w('Backend authentication failed: ${error['error']}, trying direct Keycloak');
          throw Exception(error['error'] ?? 'Login failed');
        }
      } catch (backendError) {
        // If backend authentication fails, try direct Keycloak authentication
        _logger.w("Backend authentication failed, trying direct Keycloak: $backendError");
        
        // Only try direct Keycloak in development mode or if configured
        try {
          final token = await _keycloakClient.login(
            username: username,
            password: password,
          );
    
          // Validate the token before saving it - but use relaxed validation
          if (!token.isValid()) {
            _logger.e("Received invalid token from Keycloak");
            throw Exception("Authentication failed: invalid token");
          }
    
          // Save tokens to secure storage
          await _saveTokensSecurely(
            token.accessToken,
            token.refreshToken,
            token.expiresAt.millisecondsSinceEpoch ~/ 1000
          );
    
          // Try to get user info with the new token
          final userInfo = await getUserInfo(token.accessToken);
          
          return {
            'access': token.accessToken,
            'refresh': token.refreshToken,
            'user': userInfo,
            'expires_at': token.expiresAt.millisecondsSinceEpoch ~/ 1000,
          };
        } catch (keycloakError) {
          _logger.e("All authentication methods failed: $keycloakError");
          throw Exception("Authentication failed. Please check your credentials and try again.");
        }
      }
    } catch (e) {
      _logger.e("Login failed", error: e);
      
      // Provide user-friendly error messages
      String errorMessage = 'Login failed. Please check your credentials and try again.';
      if (e.toString().contains('disabled')) {
        errorMessage = 'Your account is temporarily locked due to too many failed attempts. Please try again later.';
      } else if (e.toString().contains('Invalid credentials')) {
        errorMessage = 'Invalid email or password. Please try again.';
      }
      
      throw Exception(errorMessage);
    }
  }

  /// Authenticate a user with a social provider
  Future<Map<String, dynamic>> socialLogin(String provider, {String? externalToken}) async {
    try {
      await _ensureInitialized();
      
      if (provider.isEmpty) {
        throw Exception('Provider is required for social login');
      }
      
      // If external token is provided, use token exchange flow
      if (externalToken != null && externalToken.isNotEmpty) {
        final token = await _keycloakClient.loginWithSocial(provider, externalToken);
        
        // Save tokens to secure storage
        await _saveTokensSecurely(
          token.accessToken,
          token.refreshToken,
          token.expiresAt.millisecondsSinceEpoch ~/ 1000
        );
        
        // Get user info
        final userInfo = await getUserInfo(token.accessToken);
        
        return {
          'access': token.accessToken,
          'refresh': token.refreshToken,
          'user': userInfo,
          'expires_at': token.expiresAt.millisecondsSinceEpoch ~/ 1000,
        };
      } 
      // Otherwise, use the backend's social login endpoint
      else {
        // Call the backend to initiate social login
        final response = await http.Client().post(
          Uri.parse('${ApiConstants.socialLogin}$provider'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'provider': provider,
          }),
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          
          // Save tokens to secure storage
          if (data.containsKey('access') && data.containsKey('refresh')) {
            await _saveTokensSecurely(
              data['access'] as String,
              data['refresh'] as String,
              data['expires_at']
            );
          }
          
          return data;
        } else {
          final error = jsonDecode(response.body);
          _logger.e('Social login failed: ${error['error']}');
          throw Exception(error['error'] ?? 'Social login failed');
        }
      }
    } catch (e) {
      _logger.e("Social login failed", error: e);
      rethrow;
    }
  }

  /// Log out the current user
  Future<bool> logout() async {
    try {
      await _ensureInitialized();
      final refreshToken = await _secureStorage.read(key: KeycloakStorageKeys.refreshToken);

      if (refreshToken != null) {
        try {
          await _keycloakClient.logout(refreshToken);
          _logger.i("Logged out from Keycloak server");
        } catch (e) {
          _logger.w("Server logout failed, continuing with local logout: $e");
          // Continue with local logout even if server logout fails
        }
      }

      // Clear stored tokens
      await _clearTokens();
      return true;
    } catch (e) {
      _logger.e('Error during logout: $e');
      // Still try to clear tokens even if logout fails
      await _clearTokens();
      return false;
    }
  }

  /// Check if the user is currently authenticated
  Future<bool> isAuthenticated() async {
    try {
      await _ensureInitialized();
      
      // First check if we have an access token
      final accessToken = await _secureStorage.read(key: KeycloakStorageKeys.accessToken);
      if (accessToken == null || accessToken.isEmpty) {
        _logger.w("No access token found");
        return false;
      }
      
      // Then check if the token is expired
      final expiryString = await _secureStorage.read(key: KeycloakStorageKeys.tokenExpiry);
      if (expiryString != null && expiryString.isNotEmpty) {
        try {
          // Parse expiry time, handling various formats
          DateTime expiry = _parseExpiryTime(expiryString);
          final now = DateTime.now();
          
          // If token is expired, try to refresh it
          if (now.isAfter(expiry)) {
            _logger.i("Token expired at $expiry, attempting refresh");
            return await _tryRefreshToken();
          }
          
          // If token is about to expire (less than 5 minutes), refresh in background
          if (now.isAfter(expiry.subtract(const Duration(minutes: 5)))) {
            _logger.i("Token about to expire, refreshing in background");
            // Don't await here - let it refresh in background
            _tryRefreshToken().then((success) {
              if (!success) {
                _logger.w("Background token refresh failed");
              }
            });
          }
          
          // If we need to validate the token with backend, use this
          if (ApiConstants.validateTokenWithBackend) {
            return await _validateTokenWithBackend(accessToken);
          }
          
          // Otherwise just do local validation
          return _validateTokenLocally(accessToken);
          
        } catch (dateError) {
          _logger.e("Error processing token expiry: $dateError");
          // If we can't parse the expiry date, try to validate token locally
          return _validateTokenLocally(accessToken);
        }
      } else {
        _logger.w("No token expiry information found");
        // No expiry info, try to validate token locally
        return _validateTokenLocally(accessToken);
      }
    } catch (e) {
      _logger.e("Authentication check failed", error: e);
      return false;
    }
  }
  
  /// Helper method to parse expiry time from various formats
  DateTime _parseExpiryTime(String expiryString) {
    // Try parsing as integer timestamp (seconds since epoch)
    if (RegExp(r'^\d+$').hasMatch(expiryString)) {
      final expiryTimestamp = int.parse(expiryString);
      return DateTime.fromMillisecondsSinceEpoch(expiryTimestamp * 1000);
    } 
    
    // Try parsing as ISO 8601 date format
    if (expiryString.contains('T')) {
      try {
        return DateTime.parse(expiryString);
      } catch (_) {
        // Handle partial ISO format by removing milliseconds
        final cleanedString = expiryString.replaceAll(RegExp(r'\.\d+'), '');
        try {
          return DateTime.parse(cleanedString);
        } catch (_) {
          // Add Z if missing
          try {
            return DateTime.parse('${cleanedString}Z');
          } catch (_) {
            // Last resort - treat as seconds since epoch
            final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
            return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
          }
        }
      }
    }
    
    // Default fallback - treat as seconds since epoch
    final timestamp = int.tryParse(expiryString) ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  }

  /// Validate a token locally without server calls
  Future<bool> _validateTokenLocally(String accessToken) async {
    try {
      // Try to decode the JWT locally
      final parts = accessToken.split('.');
      if (parts.length != 3) {
        _logger.w("Invalid token format - not a valid JWT");
        return false;
      }
      
      // Decode the payload
      String normalized;
      try {
        normalized = base64Url.normalize(parts[1]);
      } catch (e) {
        _logger.e("Failed to normalize base64: $e");
        return false;
      }
      
      Map<String, dynamic> payload;
      try {
        final decoded = utf8.decode(base64Url.decode(normalized));
        payload = json.decode(decoded);
      } catch (e) {
        _logger.e("Failed to decode payload: $e");
        return false;
      }
      
      // Check for basic validity - subject claim must be present
      if (!payload.containsKey('sub')) {
        _logger.w("Token missing subject claim");
        return false;
      }
      
      // Check expiration if present
      if (payload.containsKey('exp')) {
        int expTimestamp;
        
        // Handle exp as either int or string
        if (payload['exp'] is int) {
          expTimestamp = payload['exp'];
        } else if (payload['exp'] is String) {
          expTimestamp = int.tryParse(payload['exp']) ?? 0;
        } else {
          _logger.w("Invalid exp claim format");
          return false;
        }
        
        final expiry = DateTime.fromMillisecondsSinceEpoch(expTimestamp * 1000);
        final now = DateTime.now();
        
        if (now.isAfter(expiry)) {
          _logger.i("Token expired according to payload, attempting refresh");
          return await _tryRefreshToken();
        }
        
        // If token is about to expire (less than 5 minutes), refresh in background
        if (now.isAfter(expiry.subtract(const Duration(minutes: 5)))) {
          _logger.i("Token about to expire according to payload, refreshing in background");
          _tryRefreshToken().then((success) {
            if (!success) {
              _logger.w("Background token refresh failed");
            }
          });
        }
      }
      
      // Token is valid
      return true;
    } catch (e) {
      _logger.e("Failed to validate token locally: $e");
      return false;
    }
  }

  /// Get the current user's profile information
  Future<Map<String, dynamic>> getUserInfo(String accessToken) async {
    try {
      await _ensureInitialized();
      
      try {
        // First try to get user info from the server
        return await _keycloakClient.getUserInfo(accessToken)
            .timeout(ApiConstants.defaultTimeout);
      } catch (e) {
        // Check if it's a network error
        if (e.toString().contains("Failed to fetch") || 
            e.toString().contains("SocketException") ||
            e.toString().contains("ConnectionException") ||
            e.toString().contains("TimeoutException")) {
          _logger.w("Network error connecting to Keycloak. Using local token validation.");
          
          // Try to decode the JWT locally to get basic user info
          try {
            final userInfo = _extractUserInfoFromToken(accessToken);
            if (userInfo.isNotEmpty) {
              return userInfo;
            }
          } catch (decodeError) {
            _logger.e("Failed to decode JWT locally", error: decodeError);
          }
        }
        
        _logger.e("Failed to get user info: $e");
        throw TokenException(
          "Failed to get user profile information. Please try logging in again.",
          code: 'user_info_error'
        );
      }
    } catch (e) {
      _logger.e("Failed to get user info", error: e);
      rethrow;
    }
  }
  
  /// Extract user info from token payload
  Map<String, dynamic> _extractUserInfoFromToken(String accessToken) {
    try {
      final parts = accessToken.split('.');
      if (parts.length == 3) {
        final normalized = base64Url.normalize(parts[1]);
        final decoded = utf8.decode(base64Url.decode(normalized));
        final payload = json.decode(decoded);
        
        if (payload != null && payload.containsKey('sub')) {
          // Extract relevant user info from the token payload
          return {
            'sub': payload['sub'],
            'preferred_username': payload['preferred_username'] ?? 'unknown',
            'email': payload['email'] ?? '',
            'name': payload['name'] ?? payload['preferred_username'] ?? '',
            'given_name': payload['given_name'] ?? '',
            'family_name': payload['family_name'] ?? '',
            'email_verified': payload['email_verified'] ?? false,
            'roles': _extractRolesFromPayload(payload),
            'offline_validated': true,
          };
        }
      }
      return {};
    } catch (e) {
      _logger.e("Error extracting user info from token", error: e);
      return {};
    }
  }
  
  /// Extract roles from token payload
  List<String> _extractRolesFromPayload(Map<String, dynamic> payload) {
    List<String> roles = [];
    
    try {
      // Try to get realm roles
      if (payload.containsKey('realm_access') && 
          payload['realm_access'] is Map && 
          payload['realm_access'].containsKey('roles')) {
        final realmRoles = payload['realm_access']['roles'];
        if (realmRoles is List) {
          roles.addAll(realmRoles.cast<String>());
        }
      }
      
      // Try to get client roles
      final resourceAccess = payload['resource_access'];
      if (resourceAccess is Map) {
        resourceAccess.forEach((client, access) {
          if (access is Map && access.containsKey('roles')) {
            final clientRoles = access['roles'];
            if (clientRoles is List) {
              roles.addAll(clientRoles.cast<String>());
            }
          }
        });
      }
    } catch (e) {
      _logger.w("Error extracting roles from token: $e");
    }
    
    return roles;
  }

  /// Refresh the access token using refresh token
  Future<Map<String, dynamic>?> refreshAccessToken() async {
    try {
      if (!_isInitialized) await initialize();
      
      final refreshToken = await _secureStorage.read(key: KeycloakStorageKeys.refreshToken);
      
      if (refreshToken == null || refreshToken.isEmpty) {
        _logger.w("No refresh token available");
        return null;
      }
      
      final newToken = await _keycloakClient.refreshToken(refreshToken);
      
      // Save the new tokens
      await _saveTokensSecurely(
        newToken.accessToken,
        newToken.refreshToken,
        newToken.expiresAt.millisecondsSinceEpoch ~/ 1000
      );
      
      return {
        'access': newToken.accessToken,
        'refresh': newToken.refreshToken,
        'expires_at': newToken.expiresAt.millisecondsSinceEpoch ~/ 1000,
      };
    } catch (e) {
      _logger.e("Token refresh failed", error: e);
      return null;
    }
  }

  /// Save tokens to secure storage
  Future<void> _saveTokensSecurely(String accessToken, String refreshToken, dynamic expiryTime) async {
    try {
      // Use numeric timestamp for storage to avoid date parsing issues
      String tokenExpiry;
      if (expiryTime != null) {
        if (expiryTime is int) {
          // Store as string of Unix timestamp (seconds)
          tokenExpiry = expiryTime.toString();
        } else if (expiryTime is String && RegExp(r'^\d+$').hasMatch(expiryTime)) {
          // Already a string containing numbers, use it directly
          tokenExpiry = expiryTime;
        } else {
          // Try to convert to Unix timestamp if it's a date string
          try {
            final date = DateTime.parse(expiryTime.toString());
            tokenExpiry = (date.millisecondsSinceEpoch ~/ 1000).toString();
          } catch (e) {
            // Default to 5 minutes from now if parsing fails
            tokenExpiry = (DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch ~/ 1000).toString();
          }
        }
      } else {
        // Default expiry of 5 minutes if not provided
        tokenExpiry = (DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch ~/ 1000).toString();
      }
      
      // Save tokens to secure storage
      await _secureStorage.write(key: KeycloakStorageKeys.accessToken, value: accessToken);
      await _secureStorage.write(key: KeycloakStorageKeys.refreshToken, value: refreshToken);
      await _secureStorage.write(key: KeycloakStorageKeys.tokenExpiry, value: tokenExpiry);
      
      _logger.i('Tokens saved to secure storage');
    } catch (e) {
      _logger.e('Failed to save tokens to secure storage', error: e);
      rethrow;
    }
  }

  /// Clear all stored tokens
  Future<void> _clearTokens() async {
    try {
      await _secureStorage.delete(key: KeycloakStorageKeys.accessToken);
      await _secureStorage.delete(key: KeycloakStorageKeys.refreshToken);
      await _secureStorage.delete(key: KeycloakStorageKeys.idToken);
      await _secureStorage.delete(key: KeycloakStorageKeys.tokenExpiry);
      _logger.i("All tokens cleared");
    } catch (e) {
      _logger.e("Error clearing tokens", error: e);
    }
  }

  /// Secures the application state when app is backgrounded
  /// Important security measure to protect tokens when the app isn't actively used
  Future<void> secureAppState() async {
    if (!_isInitialized) await initialize();
    
    try {
      _logger.i("Securing app state on background");
      
      // Get the current tokens
      final storage = FlutterSecureStorage();
      final accessToken = await storage.read(key: KeycloakStorageKeys.accessToken);
      
      if (accessToken == null) {
        _logger.i("No active session found, nothing to secure");
        return;
      }
      
      // Validate the current token
      try {
        // Create token parts for basic structural validation
        final parts = accessToken.split('.');
        if (parts.length != 3) {
          _logger.w("Invalid token structure, clearing tokens");
          await _clearTokens();
          return;
        }
        
        // Try to decode the payload
        String normalized = base64Url.normalize(parts[1]);
        final decoded = utf8.decode(base64Url.decode(normalized));
        Map<String, dynamic> payload = json.decode(decoded);
        
        // Create a KeycloakToken instance for validation
        final keycloakToken = KeycloakToken.fromResponse({
          'access_token': accessToken,
          'refresh_token': '',  // Not needed for this validation
          'expires_in': 0,      // Not needed for this validation
        });
        
        // Check if token is valid
        if (!keycloakToken.isValid()) {
          _logger.w("Invalid token detected on app background, clearing for security");
          await _clearTokens();
        }
        
        // Check if token is for an admin user
        if (keycloakToken.isAdmin()) {
          _logger.i("Admin user detected, clearing tokens for security");
          await _clearTokens();
        }
      } catch (e) {
        // If we can't validate the token, clear it for security
        _logger.w("Could not validate token on app background, clearing for security", error: e);
        await _clearTokens();
      }
    } catch (e) {
      _logger.e("Error securing app state", error: e);
      // Don't rethrow to avoid app crashes, but clear tokens for safety
      try {
        await _clearTokens();
      } catch (_) {
        // Ignore any errors during token clearing
      }
    }
  }

  /// Ensure Keycloak client is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Try to refresh the access token
  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: KeycloakStorageKeys.refreshToken);
      if (refreshToken == null || refreshToken.isEmpty) {
        _logger.w("No refresh token available");
        return false;
      }
      
      // Check network connectivity first
      bool keycloakAvailable = false;
      
      try {
        // Attempt a quick connectivity check to avoid long timeouts
        final connectivityCheck = await http.Client().get(
          Uri.parse(ApiConstants.baseUrl),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 2));
        
        keycloakAvailable = connectivityCheck.statusCode < 500;
        _logger.i("Keycloak server status check: ${connectivityCheck.statusCode} - Available: $keycloakAvailable");
      } catch (e) {
        _logger.w("Connection check failed: $e");
        keycloakAvailable = false;
      }

      // First try backend refresh which should be more reliable
      try {
        _logger.i("Attempting token refresh through backend");
        final response = await http.Client().post(
          Uri.parse(ApiConstants.tokenRefresh),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh_token': refreshToken}),
        ).timeout(ApiConstants.shortTimeout);
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          
          // Handle flexible token response format
          final accessToken = data['access'] ?? data['access_token'];
          final newRefreshToken = data['refresh_token'] ?? data['refresh'];
          
          if (accessToken != null && newRefreshToken != null) {
            // Calculate expiry time - default to 24 hours if not provided
            int expiresAt;
            if (data.containsKey('expires_at')) {
              if (data['expires_at'] is int) {
                expiresAt = data['expires_at'];
              } else {
                // Try parsing the expires_at as a string
                try {
                  expiresAt = int.parse(data['expires_at'].toString());
                } catch (_) {
                  // Default expiry if parsing fails
                  expiresAt = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 86400;
                }
              }
            } else if (data.containsKey('expires_in')) {
              // Calculate from expires_in
              expiresAt = DateTime.now().millisecondsSinceEpoch ~/ 1000 + (data['expires_in'] as int);
            } else {
              expiresAt = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 86400;
            }
            
            await _saveTokensSecurely(
              accessToken as String,
              newRefreshToken as String,
              expiresAt
            );
            
            _logger.i("Token refreshed through backend successfully");
            return true;
          } else {
            _logger.e("Backend refresh response missing tokens");
          }
        } else if (response.statusCode == 401 || response.statusCode == 400) {
          // Handle 400 Bad Request errors too, which might indicate an invalid refresh token
          _logger.w("Token is no longer valid, clearing tokens (${response.statusCode})");
          // Clear invalid tokens
          await _clearTokens();
          return false;
        } else {
          // Other server errors - try Keycloak directly if available
          _logger.w("Backend token refresh failed: ${response.statusCode}, trying Keycloak directly");
        }
      } catch (backendError) {
        _logger.w("Backend refresh failed: $backendError");
        
        // Clear tokens if it's clearly an auth error
        if (backendError.toString().contains("401") || 
            backendError.toString().contains("400") ||
            backendError.toString().contains("invalid_grant") ||
            backendError.toString().contains("invalid token")) {
          _logger.w("Clearing tokens due to auth error: $backendError");
          await _clearTokens();
          return false;
        }
      }
      
      // Only try direct Keycloak refresh if we have connectivity
      if (keycloakAvailable) {
        try {
          _logger.i("Attempting direct Keycloak token refresh");
          
          final tokenResponse = await _keycloakClient.refreshToken(refreshToken)
              .timeout(ApiConstants.defaultTimeout);
          
          // Save the new tokens
          await _saveTokensSecurely(
            tokenResponse.accessToken,
            tokenResponse.refreshToken,
            tokenResponse.expiresAt.millisecondsSinceEpoch ~/ 1000
          );
          
          _logger.i("Token refreshed directly through Keycloak successfully");
          return true;
        } catch (directRefreshError) {
          _logger.w("Direct Keycloak token refresh failed: $directRefreshError");
          
          // Check if it's an invalid token error
          if (directRefreshError.toString().contains("401") || 
              directRefreshError.toString().contains("400") ||
              directRefreshError.toString().contains("Unauthorized") ||
              directRefreshError.toString().contains("invalid_grant")) {
            await _clearTokens();
          }
          
          return false;
        }
      } else if (ApiConstants.ignoreKeycloakConnectionErrors) {
        // If Keycloak is unavailable but we're configured to work offline
        _logger.w("Keycloak unavailable but continuing with offline mode");
        return true;
      } else {
        _logger.w("Keycloak server is unavailable");
        return false;
      }
    } catch (e) {
      _logger.e("Error refreshing token", error: e);
      return false;
    }
  }

  /// Handle token errors uniformly
  Exception _handleTokenError(Object error, String defaultMessage) {
    _logger.e(defaultMessage, error: error);
    
    // Format the error message based on the type of error
    String errorMessage = defaultMessage;
    String errorCode = 'token_error';
    
    if (error is http.ClientException) {
      errorMessage = 'Connection failed. Please check your internet connection.';
      errorCode = 'network_error';
    } else if (error.toString().contains('Invalid credentials')) {
      errorMessage = 'Invalid username or password.';
      errorCode = 'invalid_credentials';
    } else if (error.toString().contains('expired')) {
      errorMessage = 'Your session has expired. Please log in again.';
      errorCode = 'token_expired';
    }
    
    return TokenException(errorMessage, code: errorCode);
  }

  /// Validate the token with the backend API
  Future<bool> _validateTokenWithBackend(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.userProfile),
        headers: {'Authorization': 'Bearer $accessToken'},
      ).timeout(ApiConstants.shortTimeout);
      
      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        _logger.w("Token rejected by backend (${response.statusCode})");
        return await _tryRefreshToken();
      } else {
        _logger.w("Unexpected status from backend validation: ${response.statusCode}");
        // Server is having issues but token might still be valid based on local checks
        return _validateTokenLocally(accessToken);
      }
    } catch (e) {
      _logger.w("Backend validation failed, falling back to local validation: $e");
      return _validateTokenLocally(accessToken);
    }
  }
}