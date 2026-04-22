import 'package:flutter_riverpod/flutter_riverpod.dart';

// Notifier for managing JWT access token
class AuthNotifier extends StateNotifier<String?> {
  AuthNotifier() : super(null);

  void setToken(String token) {
    state = token;
  }

  void clearToken() {
    state = null;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, String?>((ref) => AuthNotifier());