import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:frontend/core/constants/api_constants.dart';

class AuthApiService {
  final http.Client _client;
  final FlutterSecureStorage _secureStorage;
  final Logger _logger = Logger();
  
  // Set this to true when backend is not available
  static const bool useMockMode = false; // Disabled since we're fixing the backend

  AuthApiService({
    http.Client? client,
    FlutterSecureStorage? secureStorage,
  })  : _client = client ?? http.Client(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  // Helper method to get auth token
  Future<String?> _getToken() async {
    return await _secureStorage.read(key: 'access_token');
  }

  // Helper method to get refresh token
  Future<String?> _getRefreshToken() async {
    return await _secureStorage.read(key: 'refresh_token');
  }

  // Helper method to save tokens
  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(key: 'access_token', value: accessToken);
    await _secureStorage.write(key: 'refresh_token', value: refreshToken);
    _logger.i("Auth tokens saved");
  }

  // Helper method to remove tokens
  Future<void> _removeTokens() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
    _logger.i("Auth tokens removed");
  }

  // Helper method to create headers with auth token if available
  Future<Map<String, String>> _getHeaders({bool requiresAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Helper method to extract error message from response
  String? _extractErrorMessage(Map<String, dynamic> responseData) {
    if (responseData.containsKey('detail')) {
      return responseData['detail'];
    } else if (responseData.containsKey('message')) {
      return responseData['message'];
    } else if (responseData.containsKey('error')) {
      if (responseData['error'] is String) {
        return responseData['error'];
      } else if (responseData['error'] is Map) {
        return responseData['error'].toString();
      }
    } else if (responseData.containsKey('non_field_errors')) {
      final errors = responseData['non_field_errors'];
      if (errors is List && errors.isNotEmpty) {
        return errors.join(', ');
      }
    }

    final fieldErrors = <String>[];
    for (final key in responseData.keys) {
      final value = responseData[key];
      if (value is List && value.isNotEmpty) {
        fieldErrors.add('$key: ${value.join(', ')}');
      } else if (value is String) {
        fieldErrors.add('$key: $value');
      }
    }

    if (fieldErrors.isNotEmpty) {
      return fieldErrors.join('; ');
    }

    return null;
  }

  // Helper method to handle HTTP errors
  Map<String, dynamic> _handleHttpError(dynamic error) {
    String errorMessage;
    
    _logger.e("HTTP error: ${error.toString()}", error: error);
    
    if (error is TimeoutException) {
      errorMessage = 'Connection timed out. Please check your internet connection and try again.';
    } else if (error.toString().contains('Failed host lookup')) {
      errorMessage = 'Cannot find the server. Please check your network settings.';
    } else if (error.toString().contains('Connection refused')) {
      errorMessage = 'Connection refused. Please ensure the server is running.';
    } else if (error.toString().contains('Certificate verify failed')) {
      errorMessage = 'SSL certificate verification failed.';
    } else if (error.toString().contains('Failed to fetch') || 
              error.toString().contains('ClientException')) {
      errorMessage = 'Network connection error. Please check your internet connection.';
    } else {
      errorMessage = 'Network error: ${error.toString()}';
    }
    
    return {
      'error': true,
      'message': errorMessage,
      'technical_details': error.toString(),
    };
  }

  // Helper method to make HTTP requests with retry logic
  Future<http.Response> _makeRequest(
    Future<http.Response> Function() requestFn,
    String operation,
  ) async {
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        _logger.i("Making $operation request (attempt ${retryCount + 1}/$maxRetries)");
        final response = await requestFn();
        return response;
      } catch (e) {
        retryCount++;
        if (retryCount == maxRetries) {
          _logger.e("$operation failed after $maxRetries attempts", error: e);
          rethrow;
        }
        _logger.w("$operation attempt $retryCount failed, retrying...", error: e);
        await Future.delayed(Duration(seconds: 1 * retryCount)); // Exponential backoff
      }
    }
    throw Exception("Unexpected error in _makeRequest");
  }

  // User registration
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      _logger.i("Registering: $email");
      
      final headers = await _getHeaders(requiresAuth: false);
      
      final requestBody = {
        'user_name': username,
        'email': email,
        'password': password,
      };
      
      try {
        final registerUrl = ApiConstants.register;
        
        final response = await _client.post(
          Uri.parse(registerUrl),
          headers: headers,
          body: jsonEncode(requestBody),
        ).timeout(Duration(seconds: 10));
        
        Map<String, dynamic> responseData;
        try {
          responseData = json.decode(response.body) as Map<String, dynamic>;
        } catch (e) {
          _logger.e("Failed to parse JSON response", error: e);
          return {
            'error': true,
            'message': 'Invalid response from server: ${response.body}',
          };
        }

        if (response.statusCode == 201) {
          _logger.i("Registration successful");
          if (responseData.containsKey('access')) {
            await _saveTokens(responseData['access'], responseData['refresh']);
          } else if (responseData.containsKey('token')) {
            await _saveTokens(responseData['token'], responseData['refresh'] ?? '');
          }
          return responseData;
        } else {
          _logger.w("Registration failed: ${response.statusCode}");
          return {
            'error': true,
            'message': _extractErrorMessage(responseData) ?? 'Registration failed',
            'data': responseData,
          };
        }
      } catch (e) {
        _logger.e("Registration failed: ${e.toString()}");
        return _handleHttpError(e);
      }
    } catch (e) {
      _logger.e("Registration error: ${e.toString()}", error: e);
      return _handleHttpError(e);
    }
  }

  // User login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      _logger.i("Logging in: $email");
      
      final headers = await _getHeaders(requiresAuth: false);
      final loginUrl = ApiConstants.login;
      
      try {
        // Use user_name field as required by the Django backend
        final response = await _client.post(
          Uri.parse(loginUrl),
          headers: headers,
          body: jsonEncode({
            'user_name': email,
            'password': password,
          }),
        ).timeout(Duration(seconds: 10));
        
        _logger.d("Login response status: ${response.statusCode}");
        _logger.d("Login response body: ${response.body.substring(0, min(100, response.body.length))}...");
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          await _saveTokens(data['access'], data['refresh']);
          
          // Extract is_superuser from access token if it exists
          final isAdmin = _extractIsAdminFromToken(data['access']);
          data['user']['is_superuser'] = isAdmin;
          
          _logger.i("Login successful. User is admin: $isAdmin");
          return data;
        } else {
          _logger.w("Login failed: ${response.statusCode}");
          try {
            // More defensive JSON parsing
            final responseBody = response.body.trim();
            if (responseBody.startsWith('{') && responseBody.endsWith('}')) {
              final errorData = jsonDecode(responseBody);
              return {
                'error': true,
                'message': _extractErrorMessage(errorData) ?? 'Login failed',
              };
            } else {
              // Not a JSON response, return a more helpful error
              return {
                'error': true,
                'message': 'Server error (${response.statusCode}). Please contact support.',
                'details': 'Raw response not in JSON format'
              };
            }
          } catch (e) {
            _logger.e("Failed to parse error response", error: e);
            return {
              'error': true,
              'message': 'Login failed. The server is not responding correctly.',
              'details': 'Status: ${response.statusCode}, Error: ${e.toString().substring(0, min(100, e.toString().length))}'
            };
          }
        }
      } catch (e) {
        _logger.e("Login failed: ${e.toString()}");
        return _handleHttpError(e);
      }
    } catch (e) {
      _logger.e("Login error: ${e.toString()}", error: e);
      return _handleHttpError(e);
    }
  }

  // Social login
  Future<Map<String, dynamic>> socialLogin({
    required String provider,
    required String token,
  }) async {
    try {
      final socialLoginUrl = ApiConstants.socialLogin;
      _logger.i("Social login: $provider");

      final headers = await _getHeaders(requiresAuth: false);
      
      final requestBody = {
        'provider': provider,
        'access_token': token,
      };

      final response = await _client
          .post(
            Uri.parse(socialLoginUrl),
            headers: headers,
            body: json.encode(requestBody),
          )
          .timeout(Duration(seconds: 10));

      _logger.d("Social login response status: ${response.statusCode}");
      
      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body) as Map<String, dynamic>;
      } catch (e) {
        _logger.e("Failed to parse JSON response", error: e);
        return {
          'error': true,
          'message': 'Invalid response from server: ${response.body}',
        };
      }

      if (response.statusCode == 200) {
        _logger.i("Social login successful");
        if (responseData.containsKey('access')) {
          await _saveTokens(responseData['access'], responseData['refresh']);
          _logger.d("Saved auth token from response");
        } else if (responseData.containsKey('token')) {
          await _saveTokens(responseData['access'], responseData['refresh']);
          _logger.d("Saved auth token from response");
        } else {
          _logger.w("Social login successful but no token in response");
        }
        return responseData;
      } else {
        _logger.w("Social login failed with status code: ${response.statusCode}");
        _logger.d("Social login error response: $responseData");
        return {
          'error': true,
          'message': _extractErrorMessage(responseData) ?? 'Social login failed',
          'data': responseData,
        };
      }
    } on TimeoutException catch (e) {
      _logger.e("Social login timeout error", error: e);
      return {
        'error': true,
        'message': e.message ?? 'Connection timed out. Please check your server and try again.',
      };
    } catch (e) {
      String errorMessage = 'Network error: ${e.toString()}';
      if (e.toString().contains('Failed host lookup')) {
        errorMessage = 'Cannot connect to server. Please make sure your Django server is running and accessible.';
      } else if (e.toString().contains('Connection refused')) {
        errorMessage = 'Connection refused. Make sure your server is running on the correct port.';
      }
      _logger.e("Social login error: $errorMessage", error: e);
      return {
        'error': true,
        'message': errorMessage,
      };
    }
  }

  // Request password reset
  Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
  }) async {
    try {
      final forgotPasswordUrl = ApiConstants.forgotPassword;
      _logger.i("Making password reset request: $email");

      final headers = await _getHeaders(requiresAuth: false);
      final requestBody = {
        'email': email,
      };

      final response = await _client.post(
        Uri.parse(forgotPasswordUrl),
        headers: headers,
        body: json.encode(requestBody),
      ).timeout(Duration(seconds: 15));

      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body) as Map<String, dynamic>;
      } catch (e) {
        _logger.e("Failed to parse JSON response", error: e);
        return {
          'error': true,
          'message': 'Invalid response from server: ${response.body}',
        };
      }

      if (response.statusCode == 200) {
        _logger.i("Password reset request successful");
        return responseData;
      } else {
        _logger.w("Password reset request failed: ${response.statusCode}");
        return {
          'error': true,
          'message': _extractErrorMessage(responseData) ?? 'Failed to send reset email',
          'data': responseData,
        };
      }
    } catch (e) {
      _logger.e("Password reset error: ${e.toString()}", error: e);
      return _handleHttpError(e);
    }
  }

  // Reset password with verification code
  Future<Map<String, dynamic>> resetPassword({
    required String verificationCode,
    required String newPassword,
  }) async {
    try {
      final resetPasswordUrl = ApiConstants.resetPassword;
      _logger.i("Making password reset confirmation");

      final headers = await _getHeaders(requiresAuth: false);
      final requestBody = {
        'token': verificationCode,
        'new_password': newPassword,
      };

      final response = await _client.post(
        Uri.parse(resetPasswordUrl),
        headers: headers,
        body: json.encode(requestBody),
      ).timeout(Duration(seconds: 15));

      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body) as Map<String, dynamic>;
      } catch (e) {
        _logger.e("Failed to parse JSON response", error: e);
        return {
          'error': true,
          'message': 'Invalid response from server: ${response.body}',
        };
      }

      if (response.statusCode == 200) {
        _logger.i("Password reset successful");
        return responseData;
      } else {
        _logger.w("Password reset failed: ${response.statusCode}");
        return {
          'error': true,
          'message': _extractErrorMessage(responseData) ?? 'Failed to reset password',
          'data': responseData,
        };
      }
    } catch (e) {
      _logger.e("Password reset confirmation error", error: e);
      return _handleHttpError(e);
    }
  }

  // Get user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final headers = await _getHeaders(requiresAuth: true);
      
      final response = await _makeRequest(
        () => http.get(
          Uri.parse(ApiConstants.currentUser),
          headers: headers,
        ),
        'getCurrentUser',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.i("Successfully fetched current user");
        return data;
      } else {
        _logger.e("Failed to fetch current user", error: response.body);
        throw Exception(_extractErrorMessage(jsonDecode(response.body)) ?? 'Failed to get current user');
      }
    } catch (e) {
      _logger.e("Error fetching current user", error: e);
      final errorResult = _handleHttpError(e);
      throw Exception(errorResult['message']);
    }
  }

  // Logout
  Future<Map<String, dynamic>> logout() async {
    try {
      _logger.i("Logging out user");
      
      final headers = await _getHeaders();
      final logoutUrl = ApiConstants.logout;
      
      // Get the refresh token to send to backend for blacklisting
      final refreshToken = await _getRefreshToken();
      
      if (refreshToken == null) {
        _logger.w("No refresh token found, clearing local storage only");
        await _removeTokens();
        return {'success': true, 'message': 'Logged out successfully'};
      }
      
      try {
        final response = await _client.post(
          Uri.parse(logoutUrl),
          headers: headers,
          body: jsonEncode({
            'refresh': refreshToken,
          }),
        ).timeout(Duration(seconds: 10));
        
        // Clear tokens regardless of response
        await _removeTokens();
        
        if (response.statusCode == 200) {
          _logger.i("Logout successful");
          return {'success': true, 'message': 'Logged out successfully'};
        } else {
          _logger.w("Logout failed: ${response.statusCode}, but tokens cleared locally");
          return {
            'success': true, 
            'message': 'Logged out locally, but server logout failed',
            'details': 'Server response: ${response.statusCode}'
          };
        }
      } catch (e) {
        _logger.e("Logout request failed: ${e.toString()}, but tokens cleared locally");
        await _removeTokens();
        return {
          'success': true,
          'message': 'Logged out locally, but server logout failed',
          'details': 'Error: ${e.toString()}'
        };
      }
    } catch (e) {
      _logger.e("Logout error: ${e.toString()}", error: e);
      // Clear tokens anyway in case of error
      await _removeTokens();
      return {
        'success': true,
        'message': 'Logged out locally',
        'details': 'Error: ${e.toString()}'
      };
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _getToken();
    return token != null;
  }

  // Get current user
  Future<Map<String, dynamic>> getCurrentUser() async {
    return await getUserProfile();
  }

  /// Extracts the is_superuser flag from the JWT token
  /// Returns true if the user is a superuser, false otherwise
  bool _extractIsAdminFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        _logger.e('Invalid JWT token format');
        return false;
      }

      // Decode the payload (second part)
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final data = json.decode(decoded) as Map<String, dynamic>;

      // Check if is_superuser exists and is true
      return data.containsKey('is_superuser') && data['is_superuser'] == true;
    } catch (e) {
      _logger.e('Error extracting is_superuser from token: $e');
      return false;
    }
  }
}