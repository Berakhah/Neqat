import 'package:frontend/services/keycloak_service.dart';
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';
import 'package:frontend/core/constants/api_constants.dart';

/// Implementation of the AuthRepository interface using Keycloak as the authentication provider
class AuthRepositoryImpl implements AuthRepository {
  final KeycloakService _keycloakService;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Logger _logger = Logger();
  final Dio dio = Dio();

  AuthRepositoryImpl({required KeycloakService keycloakService})
    : _keycloakService = keycloakService;

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      _logger.i('Attempting to login user: $email');
      final result = await _keycloakService.login(username: email, password: password);
      _logger.i('User logged in successfully');
      return result;
    } catch (e) {
      _logger.e('Login failed', error: e);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      _logger.i('Attempting to register user: $email');
      final result = await _keycloakService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      _logger.i('User registered successfully');
      return result;
    } catch (e) {
      _logger.e('Registration failed', error: e);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> socialLogin({
    required String provider,
    required String token,
  }) async {
    try {
      _logger.i('Attempting social login with provider: $provider');
      final result = await _keycloakService.socialLogin(provider, externalToken: token);
      _logger.i('Social login successful');
      return result;
    } catch (e) {
      _logger.e('Social login failed', error: e);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
  }) async {
    try {
      _logger.i('Requesting password reset for: $email');
      await _keycloakService.requestPasswordReset(email);
      _logger.i('Password reset request sent');
      return {'message': 'Password reset link sent to your email'};
    } catch (e) {
      _logger.e('Password reset request failed', error: e);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> resetPassword({
    required String verificationCode,
    required String newPassword,
  }) async {
    try {
      _logger.i('Attempting to reset password');
      final result = await _keycloakService.resetPassword(
        verificationCode: verificationCode,
        newPassword: newPassword,
      );
      _logger.i('Password reset successful');
      return result;
    } catch (e) {
      _logger.e('Password reset failed', error: e);
      rethrow;
    }
  }

  @override
  Future<bool> logout() async {
    try {
      _logger.i('Logging out user');
      final result = await _keycloakService.logout();
      _logger.i('User logged out successfully');
      return result;
    } catch (e) {
      _logger.e('Logout failed', error: e);
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      _logger.i('Retrieving user profile');
      final accessToken = await _secureStorage.read(key: KeycloakStorageKeys.accessToken);
      if (accessToken == null) {
        _logger.e('No access token available to retrieve user profile');
        throw Exception('No access token available');
      }
      
      final userInfo = await _keycloakService.getUserInfo(accessToken);
      _logger.i('User profile retrieved successfully');
      return userInfo;
    } catch (e) {
      _logger.e('Failed to get user profile', error: e);
      rethrow;
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      _logger.i('Checking if user is authenticated');
      final result = await _keycloakService.isAuthenticated();
      _logger.i('Authentication check completed: $result');
      return result;
    } catch (e) {
      _logger.e('Authentication check failed', error: e);
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      _logger.i('Getting current user information');
      final accessToken = await _secureStorage.read(key: KeycloakStorageKeys.accessToken);
      if (accessToken == null) {
        _logger.w('No access token available to get current user');
        return null;
      }
      
      final userInfo = await _keycloakService.getUserInfo(accessToken);
      _logger.i('Current user information retrieved successfully');
      return userInfo;
    } catch (e) {
      _logger.e('Failed to get current user', error: e);
      return null;
    }
  }

  @override
  Future<String?> getAccessToken() async {
    try {
      _logger.i('Retrieving access token');
      final accessToken = await _secureStorage.read(key: KeycloakStorageKeys.accessToken);
      return accessToken;
    } catch (e) {
      _logger.e('Failed to get access token', error: e);
      return null;
    }
  }

  @override
  Future<String> getSocialAuthUrl(String provider) async {
    final response = await dio.get('${ApiConstants.baseUrl}api/login/$provider/');
    if (response.statusCode == 200 && response.data['auth_url'] != null) {
      return response.data['auth_url'];
    } else {
      throw Exception('Failed to get social auth URL');
    }
  }

  @override
  Future<Map<String, dynamic>> getUserFromToken(String accessToken) async {
    final response = await dio.get(
      '${ApiConstants.baseUrl}user/profile/',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Failed to get user from token');
    }
  }
}