import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// User state
class UserState {
  final bool isAuthenticated;
  final bool isAdmin;
  final Map<String, dynamic>? userData;

  const UserState({
    this.isAuthenticated = false,
    this.isAdmin = false,
    this.userData,
  });

  UserState copyWith({
    bool? isAuthenticated,
    bool? isAdmin,
    Map<String, dynamic>? userData,
  }) {
    return UserState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isAdmin: isAdmin ?? this.isAdmin,
      userData: userData ?? this.userData,
    );
  }
}

extension UserRoleHelpers on UserState {
  bool hasRole(String role) {
    final roles = userData?['realm_access']?['roles'] as List<dynamic>?;
    if (roles == null) return false;
    return roles.contains(role);
  }
  bool hasAnyRole(List<String> rolesToCheck) {
    final roles = userData?['realm_access']?['roles'] as List<dynamic>?;
    if (roles == null) return false;
    return rolesToCheck.any((role) => roles.contains(role));
  }
  bool get isEditor => hasRole('admin');
  bool get isAdmin => isAdmin || hasRole('admin') || hasRole('realm-admin');
}

// User notifier
class UserNotifier extends StateNotifier<UserState> {
  final authRepository = authRepositoryProvider;

  UserNotifier(Ref ref) : super(const UserState()) {
    _init(ref);
  }

  Future<void> _init(Ref ref) async {
    final repository = ref.read(authRepositoryProvider);
    final isAuthenticated = await repository.isAuthenticated();
    if (isAuthenticated) {
      final userData = await repository.getCurrentUser();
      if (userData != null) {
        // Check for superuser status in user data
        final isAdmin = userData.containsKey('is_superuser') 
                       ? userData['is_superuser'] == true 
                       : false;
        state = UserState(
          isAuthenticated: true,
          isAdmin: isAdmin,
          userData: userData,
        );
      }
    }
  }

  // Login update
  void setUserData(Map<String, dynamic> userData) {
    // Check specifically for is_superuser flag for admin status
    final isAdmin = userData.containsKey('is_superuser') 
                  ? userData['is_superuser'] == true 
                  : false;
    
    state = UserState(
      isAuthenticated: true,
      isAdmin: isAdmin,
      userData: userData,
    );
  }

  // Logout
  void clearUserData() {
    state = const UserState(
      isAuthenticated: false,
      isAdmin: false,
      userData: null,
    );
  }
}

// Provider
final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier(ref);
});

final userPermissionsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final token = ref.read(authTokenProvider);
  if (token == null) throw Exception('No access token');
  final response = await http.get(
    Uri.parse('https://localhost:8000/api/user/permissions/'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to fetch permissions');
  }
}); 