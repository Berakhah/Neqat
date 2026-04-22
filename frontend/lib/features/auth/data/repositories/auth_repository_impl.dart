import 'package:frontend/features/auth/data/datasources/auth_api_service.dart';
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApiService _authApiService;

  AuthRepositoryImpl({required AuthApiService authApiService})
      : _authApiService = authApiService;

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return await _authApiService.login(
      email: email,
      password: password,
    );
  }

  @override
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    return await _authApiService.register(
      username: username,
      email: email,
      password: password,
    );
  }

  @override
  Future<Map<String, dynamic>> socialLogin({
    required String provider,
    required String token,
  }) async {
    return await _authApiService.socialLogin(
      provider: provider,
      token: token,
    );
  }

  @override
  Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
  }) async {
    return await _authApiService.requestPasswordReset(
      email: email,
    );
  }

  @override
  Future<Map<String, dynamic>> resetPassword({
    required String verificationCode,
    required String newPassword,
  }) async {
    return await _authApiService.resetPassword(
      verificationCode: verificationCode,
      newPassword: newPassword,
    );
  }

  @override
  Future<bool> logout() async {
    await _authApiService.logout();
    return true;
  }

  @override
  Future<Map<String, dynamic>> getUserProfile() async {
    final result = await _authApiService.getUserProfile();
    if (result.containsKey('error') && result['error'] == true) {
      return {'error': true, 'message': 'Failed to get user profile'};
    }
    return result;
  }

  @override
  Future<bool> isAuthenticated() async {
    return await _authApiService.isAuthenticated();
  }

  @override
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      return await _authApiService.getCurrentUser();
    } catch (e) {
      return null;
    }
  }
} 