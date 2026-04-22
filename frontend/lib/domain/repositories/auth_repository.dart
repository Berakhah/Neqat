// Auth repository interface that defines the contract for authentication operations
abstract class AuthRepository {
  // User registration
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  });

  // User login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  });

  // Social login
  Future<Map<String, dynamic>> socialLogin({
    required String provider,
    required String token,
  });

  // Request password reset
  Future<Map<String, dynamic>> requestPasswordReset({required String email});

  // Reset password with verification code
  Future<Map<String, dynamic>> resetPassword({
    required String verificationCode,
    required String newPassword,
  });

  // Logout user
  Future<bool> logout();

  // Get current user information
  Future<Map<String, dynamic>?> getUserProfile();

  // Check if user is authenticated
  Future<bool> isAuthenticated();
}
