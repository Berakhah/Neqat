abstract class AuthRepository {
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  });
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  });
  Future<bool> logout();
  Future<Map<String, dynamic>?> getCurrentUser();
  Future<Map<String, dynamic>> socialLogin({
    required String provider,
    required String token,
  });
  Future<Map<String, dynamic>> getUserProfile();
  Future<bool> isAuthenticated();
  Future<Map<String, dynamic>> requestPasswordReset({required String email});
  Future<Map<String, dynamic>> resetPassword({
    required String verificationCode,
    required String newPassword,
  });
}
