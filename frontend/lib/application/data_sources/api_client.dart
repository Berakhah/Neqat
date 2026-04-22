import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/services/keycloak_service.dart';

class ApiClient {
  final http.Client _client;
  final FlutterSecureStorage _secureStorage;
  final Logger _logger = Logger();
  
  ApiClient({
    http.Client? client,
    FlutterSecureStorage? secureStorage,
  })  : _client = client ?? http.Client(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  // Get auth token
  Future<String?> _getToken() async {
    return await _secureStorage.read(key: KeycloakStorageKeys.accessToken);
  }

  // Get refresh token
  Future<String?> _getRefreshToken() async {
    return await _secureStorage.read(key: KeycloakStorageKeys.refreshToken);
  }

  // Save tokens
  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(key: KeycloakStorageKeys.accessToken, value: accessToken);
    await _secureStorage.write(key: KeycloakStorageKeys.refreshToken, value: refreshToken);
    _logger.i("Auth tokens saved successfully");
  }

  // Remove tokens
  Future<void> _removeTokens() async {
    await _secureStorage.delete(key: KeycloakStorageKeys.accessToken);
    await _secureStorage.delete(key: KeycloakStorageKeys.refreshToken);
    _logger.i("Auth tokens removed");
  }

  // Get headers with auth token if available
  Future<Map<String, String>> _getHeaders({bool requiresAuth = true}) async {
    final headers = Map<String, String>.from(ApiConstants.defaultHeaders);
    
    if (requiresAuth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }

  // Refresh token if expired
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _client.post(
        Uri.parse(ApiConstants.tokenRefresh),
        headers: ApiConstants.defaultHeaders,
        body: json.encode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Handle Keycloak token format
        final accessToken = data['access'] ?? data['access_token'];
        final newRefreshToken = data['refresh_token'] ?? data['refresh'];
        
        if (accessToken != null && newRefreshToken != null) {
          await _saveTokens(accessToken, newRefreshToken);
          
          // Save expiry if provided
          if (data.containsKey('expires_at')) {
            await _secureStorage.write(
              key: KeycloakStorageKeys.tokenExpiry,
              value: data['expires_at'].toString()
            );
          } else if (data.containsKey('expires_in')) {
            // Calculate expiry from expires_in
            final expiresAt = DateTime.now().add(
              Duration(seconds: data['expires_in'])
            ).millisecondsSinceEpoch ~/ 1000;
            await _secureStorage.write(
              key: KeycloakStorageKeys.tokenExpiry,
              value: expiresAt.toString()
            );
          }
          
          return true;
        }
        
        _logger.w("Token refresh response missing tokens");
        return false;
      }
      
      _logger.e("Token refresh failed with status: ${response.statusCode}");
      return false;
    } catch (e) {
      _logger.e("Token refresh failed", error: e);
      return false;
    }
  }

  // Make API request with automatic token refresh
  Future<http.Response> request({
    required String url,
    required String method,
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      
      http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client.get(Uri.parse(url), headers: headers);
          break;
        case 'POST':
          response = await _client.post(
            Uri.parse(url),
            headers: headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'PUT':
          response = await _client.put(
            Uri.parse(url),
            headers: headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'DELETE':
          response = await _client.delete(Uri.parse(url), headers: headers);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      // Handle token expiration
      if (response.statusCode == 401 && requiresAuth) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          // Retry the request with new token
          return request(
            url: url,
            method: method,
            body: body,
            requiresAuth: requiresAuth,
          );
        } else {
          // Token refresh failed, clear tokens and throw error
          await _removeTokens();
          throw Exception('Authentication failed');
        }
      }

      return response;
    } catch (e) {
      _logger.e("API request failed", error: e);
      rethrow;
    }
  }

  // Helper method to handle HTTP errors
  Map<String, dynamic> _handleHttpError(dynamic error) {
    if (error is http.ClientException) {
      return {
        'error': true,
        'message': 'Network error: ${error.message}',
      };
    } else if (error is FormatException) {
      return {
        'error': true,
        'message': 'Invalid response format',
      };
    } else {
      return {
        'error': true,
        'message': error.toString(),
      };
    }
  }
} 