import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/app/providers/auth_provider.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/services/keycloak_service.dart';
import 'package:logger/logger.dart';
import 'dart:convert';

class DioClient {
  late Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Logger _logger = Logger();
  final ProviderRef? _ref;
  final KeycloakService _keycloakService;
  bool _isRefreshing = false;
  
  DioClient({ProviderRef? ref, KeycloakService? keycloakService}) 
      : _ref = ref,
        _keycloakService = keycloakService ?? KeycloakService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      responseType: ResponseType.json,
      contentType: 'application/json',
      headers: ApiConstants.defaultHeaders,
    ));
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onResponse: _onResponse,
      onError: _onError,
    ));
  }
  
  // Request interceptor to add authentication token
  void _onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Add authorization token to requests if available
    final token = await _secureStorage.read(key: KeycloakStorageKeys.accessToken);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      
      // Check if token is about to expire and refresh if needed
      if (await _shouldRefreshToken(token)) {
        try {
          // Only refresh token if not already refreshing
          if (!_isRefreshing) {
            _isRefreshing = true;
            final refreshResult = await _keycloakService.refreshAccessToken();
            _isRefreshing = false;
            
            if (refreshResult != null) {
              final newToken = refreshResult['access'] as String?;
              if (newToken != null) {
                options.headers['Authorization'] = 'Bearer $newToken';
                
                // Update auth state if provider reference is available
                if (_ref != null) {
                  _ref.read(authProvider.notifier).setToken(newToken);
                }
              }
            }
          }
        } catch (e) {
          _logger.e('Token refresh during request failed: $e');
        }
      }
    }
    
    return handler.next(options);
  }
  
  // Response interceptor
  void _onResponse(Response response, ResponseInterceptorHandler handler) {
    return handler.next(response);
  }
  
  // Error interceptor to handle authentication errors
  void _onError(DioException e, ErrorInterceptorHandler handler) async {
    // Handle 401 Unauthorized errors
    if (e.response?.statusCode == 401) {
      _logger.w('Received 401 Unauthorized response');
      
      if (!_isRefreshing) {
        _isRefreshing = true;
        
        try {
          // Try to refresh the token
          final refreshResult = await _keycloakService.refreshAccessToken();
          
          if (refreshResult != null) {
            _isRefreshing = false;
            final newToken = refreshResult['access'] as String?;
            
            if (newToken != null) {
              // Update auth state if provider reference is available
              if (_ref != null) {
                _ref.read(authProvider.notifier).setToken(newToken);
              }
              
              // Retry the original request with new token
              final options = e.requestOptions;
              options.headers['Authorization'] = 'Bearer $newToken';
              
              // Execute the request with the updated header
              final response = await _dio.fetch(options);
              return handler.resolve(response);
            }
          }
        } catch (refreshError) {
          _logger.e('Token refresh failed', error: refreshError);
        } finally {
          _isRefreshing = false;
        }
        
        // If still here, token refresh failed - clear authentication
        await _clearAuthentication();
      }
    }
    
    // For all other errors, continue with error pipeline
    return handler.next(e);
  }
  
  // Check if token needs refresh (about to expire)
  Future<bool> _shouldRefreshToken(String token) async {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      
      final normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> data = json.decode(payload);
      
      if (data.containsKey('exp')) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(data['exp'] * 1000);
        final now = DateTime.now();
        
        // Refresh if token expires in less than 5 minutes
        return expiry.isBefore(now.add(const Duration(minutes: 5)));
      }
      
      return true;
    } catch (e) {
      _logger.e('Error checking token expiry: $e');
      return true;
    }
  }
  
  // Clear authentication on permanent auth failures
  Future<void> _clearAuthentication() async {
    try {
      await _secureStorage.delete(key: KeycloakStorageKeys.accessToken);
      await _secureStorage.delete(key: KeycloakStorageKeys.refreshToken);
      
      // Update auth state if provider reference is available
      if (_ref != null) {
        await _ref.read(authProvider.notifier).clear();
      }
      
      _logger.i('Authentication cleared due to token error');
    } catch (e) {
      _logger.e('Error clearing authentication: $e');
    }
  }
  
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.post(path, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.put(path, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.patch(path, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Response> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.delete(path, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Exception _handleError(DioException e) {
    String errorMessage = 'An error occurred';
    
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        errorMessage = 'Connection timeout. Please check your internet connection and try again.';
        break;
      case DioExceptionType.sendTimeout:
        errorMessage = 'Request timed out while sending data. Please check your internet connection and try again.';
        break;
      case DioExceptionType.receiveTimeout:
        errorMessage = 'Response timed out. Please check your internet connection and try again.';
        break;
      case DioExceptionType.badResponse:
        errorMessage = 'Bad server response: ${e.response?.statusCode}';
        // Handle specific response errors
        if (e.response?.data != null) {
          try {
            final responseData = e.response!.data;
            if (responseData is Map<String, dynamic>) {
              if (responseData.containsKey('detail')) {
                errorMessage = responseData['detail'];
              } else if (responseData.containsKey('message')) {
                errorMessage = responseData['message'];
              } else if (responseData.containsKey('error')) {
                errorMessage = responseData['error'];
              } else if (responseData.containsKey('error_description')) {
                errorMessage = responseData['error_description'];
              }
            } else if (responseData is String) {
              errorMessage = responseData;
            }
          } catch (e) {
            errorMessage = 'Error processing response';
            _logger.e('Error details: $e');
          }
        }
        break;
      case DioExceptionType.cancel:
        errorMessage = 'Request cancelled';
        break;
      case DioExceptionType.connectionError:
        errorMessage = 'Connection error. Please check your internet connection and try again.';
        // Log more details for debugging
        _logger.e('Connection error details: ${e.message}');
        // Check for SSL/certificate errors
        if (e.message?.contains('certificate') ?? false) {
          errorMessage = 'SSL certificate error. Please check your connection security settings.';
        } else if (e.message?.contains('SSL') ?? false) {
          errorMessage = 'SSL connection error. Please check your connection security settings.';
        }
        break;
      case DioExceptionType.unknown:
        errorMessage = 'Unknown error: ${e.message}';
        // Check for common network-related errors in the unknown category
        final errorString = e.message?.toLowerCase() ?? '';
        if (errorString.contains('network') || 
            errorString.contains('connection') || 
            errorString.contains('internet')) {
          errorMessage = 'Network connection error. Please check your internet connection and try again.';
        } else if (errorString.contains('certificate') || 
                  errorString.contains('ssl') || 
                  errorString.contains('handshake')) {
          errorMessage = 'Connection security error. Please check your network settings.';
        }
        // Log more details for debugging
        _logger.e('Unknown error details: ${e.message}');
        break;
      default:
        errorMessage = 'Error: ${e.message}';
    }
    
    _logger.e('DioError: $errorMessage');
    return Exception(errorMessage);
  }
}

// Dio client provider for dependency injection
final dioClientProvider = Provider<DioClient>((ref) {
  final keycloakService = ref.read(authServiceProvider);
  return DioClient(ref: ref, keycloakService: keycloakService);
});