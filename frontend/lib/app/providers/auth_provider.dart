import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:frontend/services/keycloak_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// Conditional import for web platform
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html if (dart.library.html) '';
import 'package:frontend/app/utils/html_stub.dart' as html if (dart.library.io) '';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? errorMessage;
  final Map<String, dynamic>? user;
  final String? token;
  final AuthStatus status;

  AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.errorMessage,
    this.user,
    this.token,
    this.status = AuthStatus.initial,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? errorMessage,
    Map<String, dynamic>? user,
    String? token,
    AuthStatus? status,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      user: user ?? this.user,
      token: token ?? this.token,
      status: status ?? this.status,
    );
  }
}

enum AuthStatus {
  initial,
  authenticating,
  authenticated,
  authenticationFailed,
  registering,
  registered,
  registrationFailed,
  passwordResetRequested,
  passwordReset,
  passwordResetFailed,
  loggingOut,
  loggedOut,
  logoutFailed,
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final Logger _logger = Logger();

  AuthNotifier(this._authRepository) : super(AuthState());

  Future<void> login(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, status: AuthStatus.authenticating);
      final result = await _authRepository.login(email: email, password: password);
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: result['user'],
        token: result['access'],
        status: AuthStatus.authenticated,
      );
      _logger.i('Login successful for $email');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
        status: AuthStatus.authenticationFailed,
      );
      _logger.e('Login failed: $e');
    }
  }

  Future<void> socialLogin(String provider) async {
    try {
      state = state.copyWith(isLoading: true, status: AuthStatus.authenticating);
      _logger.i('Starting social login with provider: $provider');
      
      // Step 1: Get the social auth URL from backend
      try {
        final authUrl = await _authRepository.getSocialAuthUrl(provider);
        _logger.i('Received auth URL: $authUrl');
        
        // Step 2: Launch the URL and wait for callback
        try {
          final callbackUrl = await FlutterWebAuth2.authenticate(
            url: authUrl,
            callbackUrlScheme: 'neqat', // Make sure this matches your app's scheme
          );
          _logger.i('Received callback URL: $callbackUrl');
          
          // Step 3: Extract tokens from callback URL
          final uri = Uri.parse(callbackUrl);
          final accessToken = uri.queryParameters['access_token'];
          final refreshToken = uri.queryParameters['refresh_token'];
          final expiresIn = uri.queryParameters['expires_in'];
          
          if (accessToken == null || refreshToken == null) {
            throw Exception('Social login failed: No tokens returned in callback URL');
          }
          
          // Step 4: Finish login with tokens
          try {
            final user = await _authRepository.getUserFromToken(accessToken);
            state = state.copyWith(
              isAuthenticated: true,
              isLoading: false,
              user: user,
              token: accessToken,
              status: AuthStatus.authenticated,
            );
            _logger.i('Social login successful with $provider');
          } catch (e) {
            _logger.e('Failed to get user from token: $e');
            throw Exception('Failed to get user information after authentication');
          }
        } catch (e) {
          _logger.e('Authentication flow failed: $e');
          if (e.toString().contains('connection') || 
              e.toString().contains('network') ||
              e.toString().contains('SSL')) {
            throw Exception('Connection error during authentication. Please check your internet connection and try again.');
          } else {
            throw Exception('Authentication failed: ${e.toString()}');
          }
        }
      } catch (e) {
        _logger.e('Failed to get social auth URL: $e');
        if (e.toString().contains('connection') || 
            e.toString().contains('network') ||
            e.toString().contains('SSL')) {
          throw Exception('Connection error. Please check your internet connection and try again.');
        } else {
          throw Exception('Failed to start social login: ${e.toString()}');
        }
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
        status: AuthStatus.authenticationFailed,
      );
      _logger.e('Social login failed: $e');
    }
  }

  Future<void> register(String firstName, String lastName, String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, status: AuthStatus.registering);
      final result = await _authRepository.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );
      state = state.copyWith(
        isLoading: false,
        user: result['user'],
        status: AuthStatus.registered,
      );
      _logger.i('Registration successful for $email');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
        status: AuthStatus.registrationFailed,
      );
      _logger.e('Registration failed: $e');
    }
  }

  Future<void> requestPasswordReset(String email) async {
    try {
      state = state.copyWith(isLoading: true, status: AuthStatus.passwordResetRequested);
      await _authRepository.requestPasswordReset(email: email);
      state = state.copyWith(
        isLoading: false,
        status: AuthStatus.passwordResetRequested,
      );
      _logger.i('Password reset requested for $email');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
        status: AuthStatus.passwordResetFailed,
      );
      _logger.e('Password reset request failed: $e');
    }
  }

  Future<void> resetPassword(String verificationCode, String newPassword) async {
    try {
      state = state.copyWith(isLoading: true, status: AuthStatus.passwordReset);
      await _authRepository.resetPassword(
        verificationCode: verificationCode,
        newPassword: newPassword,
      );
      state = state.copyWith(
        isLoading: false,
        status: AuthStatus.passwordReset,
      );
      _logger.i('Password reset successful');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
        status: AuthStatus.passwordResetFailed,
      );
      _logger.e('Password reset failed: $e');
    }
  }

  Future<void> logout() async {
    try {
      state = state.copyWith(isLoading: true, status: AuthStatus.loggingOut);
      final success = await _authRepository.logout();
      if (success) {
        state = state.copyWith(
          isAuthenticated: false,
          isLoading: false,
          user: null,
          token: null,
          status: AuthStatus.loggedOut,
        );
        _logger.i('Logout successful');
      } else {
        throw Exception('Logout failed');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
        status: AuthStatus.logoutFailed,
      );
      _logger.e('Logout failed: $e');
    }
  }

  Future<void> clear() async {
    try {
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        user: null,
        token: null,
        errorMessage: null,
        status: AuthStatus.initial,
      );
      await _authRepository.logout();
      _logger.i('Auth state cleared');
    } catch (e) {
      _logger.e('Clear auth state failed: $e');
    }
  }

  void setToken(String token) {
    state = state.copyWith(token: token);
    _logger.i('Token set');
  }

  void clearToken() {
    state = state.copyWith(token: null);
    _logger.i('Token cleared');
  }

  Future<void> checkAuthStatus() async {
    try {
      final isAuthenticated = await _authRepository.isAuthenticated();
      if (isAuthenticated) {
        final user = await _authRepository.getCurrentUser();
        final token = await _authRepository.getAccessToken();
        state = state.copyWith(
          isAuthenticated: true,
          user: user,
          token: token,
          status: AuthStatus.authenticated,
        );
        _logger.i('User is authenticated');
      } else {
        state = state.copyWith(
          isAuthenticated: false,
          user: null,
          token: null,
          status: AuthStatus.initial,
        );
        _logger.i('User is not authenticated');
      }
    } catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        errorMessage: e.toString(),
        status: AuthStatus.initial,
      );
      _logger.e('Auth status check failed: $e');
    }
  }

  Future<void> finishSocialLogin(String accessToken, String refreshToken, {int? expiresIn}) async {
    try {
      state = state.copyWith(isLoading: true, status: AuthStatus.authenticating);
      // Store tokens in secure storage
      final storage = const FlutterSecureStorage();
      await storage.write(key: KeycloakStorageKeys.accessToken, value: accessToken);
      await storage.write(key: KeycloakStorageKeys.refreshToken, value: refreshToken);
      // Calculate and store expiry
      final expirySeconds = expiresIn ?? 300;
      final expiryTimestamp = DateTime.now().add(Duration(seconds: expirySeconds)).millisecondsSinceEpoch ~/ 1000;
      await storage.write(key: KeycloakStorageKeys.tokenExpiry, value: expiryTimestamp.toString());
      // Fetch user info
      final user = await _authRepository.getUserFromToken(accessToken);
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: user,
        token: accessToken,
        status: AuthStatus.authenticated,
      );
      _logger.i('Social login finalized from callback and tokens stored');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
        status: AuthStatus.authenticationFailed,
      );
      _logger.e('Social login callback failed: $e');
    }
  }

  // Method to handle web-specific social login callbacks
  Future<void> checkWebSocialLoginCallback() async {
    if (kIsWeb) {
      try {
        _logger.i('Checking for web social login callback');
        // Use js interop to check localStorage for callback URL
        final jsWindow = html.window;
        final callbackUrl = jsWindow.localStorage['social_login_callback'];
        
        if (callbackUrl != null && callbackUrl.isNotEmpty) {
          _logger.i('Found social login callback in localStorage: $callbackUrl');
          // Clear the localStorage item to prevent reprocessing
          jsWindow.localStorage.remove('social_login_callback');
          
          // Process the callback URL
          final uri = Uri.parse(callbackUrl);
          final accessToken = uri.queryParameters['access_token'];
          final refreshToken = uri.queryParameters['refresh_token'];
          final expiresIn = uri.queryParameters['expires_in'];
          
          if (accessToken == null || refreshToken == null) {
            throw Exception('Social login failed: No tokens returned in callback URL');
          }
          
          // Finish login with tokens
          try {
            final user = await _authRepository.getUserFromToken(accessToken);
            state = state.copyWith(
              isAuthenticated: true,
              isLoading: false,
              user: user,
              token: accessToken,
              status: AuthStatus.authenticated,
            );
            _logger.i('Web social login successful');
          } catch (e) {
            _logger.e('Failed to get user from token: $e');
            throw Exception('Failed to get user information after authentication');
          }
        }
      } catch (e) {
        _logger.e('Error checking web social login callback: $e');
        state = state.copyWith(
          isLoading: false,
          errorMessage: e.toString(),
          status: AuthStatus.authenticationFailed,
        );
      }
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final keycloakService = ref.read(authServiceProvider);
  return AuthRepositoryImpl(keycloakService: keycloakService);
});

final authServiceProvider = Provider<KeycloakService>((ref) {
  return KeycloakService(secureStorage: const FlutterSecureStorage());
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.read(authRepositoryProvider);
  return AuthNotifier(authRepository);
});

final authTokenProvider = Provider<String?>((ref) {
  return ref.watch(authProvider.select((state) => state.token));
});