import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:frontend/core/constants/api_constants.dart';

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
    return await _secureStorage.read(key: 'access_token');
  }

  // Get refresh token
  Future<String?> _getRefreshToken() async {
    return await _secureStorage.read(key: 'refresh_token');
  }

  // Save tokens
  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(key: 'access_token', value: accessToken);
    await _secureStorage.write(key: 'refresh_token', value: refreshToken);
    _logger.i("Auth tokens saved successfully");
  }

  // Remove tokens
  Future<void> _removeTokens() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
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
        body: json.encode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _saveTokens(data['access'], data['refresh']);
        return true;
      }
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