import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../domain/entities/admin_user.dart';
import '../../data/datasources/admin_api_service.dart';

class AdminUsersState {
  final bool isLoading;
  final List<AdminUser> users;
  final String? error;

  AdminUsersState({
    this.isLoading = false,
    this.users = const [],
    this.error,
  });

  AdminUsersState copyWith({
    bool? isLoading,
    List<AdminUser>? users,
    String? error,
  }) {
    return AdminUsersState(
      isLoading: isLoading ?? this.isLoading,
      users: users ?? this.users,
      error: error,
    );
  }
}

final adminUserControllerProvider = StateNotifierProvider<AdminUserController, AdminUsersState>((ref) {
  final adminApiService = ref.watch(adminApiServiceProvider);
  return AdminUserController(adminApiService);
});

class AdminUserController extends StateNotifier<AdminUsersState> {
  final AdminApiService _adminApiService;
  final Logger _logger = Logger();

  AdminUserController(this._adminApiService) : super(AdminUsersState());

  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final users = await _adminApiService.getUsers();
      state = state.copyWith(isLoading: false, users: users);
    } catch (e) {
      _logger.e('Failed to load users', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load users: $e',
      );
    }
  }

  Future<void> disableUser(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _adminApiService.disableUser(userId);
      
      // Update user in state
      final updatedUsers = state.users.map((user) {
        if (user.id == userId) {
          return user.copyWith(isActive: false);
        }
        return user;
      }).toList();
      
      state = state.copyWith(isLoading: false, users: updatedUsers);
    } catch (e) {
      _logger.e('Failed to disable user', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to disable user: $e',
      );
    }
  }

  Future<void> enableUser(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _adminApiService.enableUser(userId);
      
      // Update user in state
      final updatedUsers = state.users.map((user) {
        if (user.id == userId) {
          return user.copyWith(isActive: true);
        }
        return user;
      }).toList();
      
      state = state.copyWith(isLoading: false, users: updatedUsers);
    } catch (e) {
      _logger.e('Failed to enable user', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to enable user: $e',
      );
    }
  }

  Future<void> makeStaff(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _adminApiService.makeStaff(userId);
      
      // Update user in state
      final updatedUsers = state.users.map((user) {
        if (user.id == userId) {
          return user.copyWith(isStaff: true);
        }
        return user;
      }).toList();
      
      state = state.copyWith(isLoading: false, users: updatedUsers);
    } catch (e) {
      _logger.e('Failed to make user staff', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to make user staff: $e',
      );
    }
  }

  Future<void> removeStaff(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _adminApiService.removeStaff(userId);
      
      // Update user in state
      final updatedUsers = state.users.map((user) {
        if (user.id == userId) {
          return user.copyWith(isStaff: false);
        }
        return user;
      }).toList();
      
      state = state.copyWith(isLoading: false, users: updatedUsers);
    } catch (e) {
      _logger.e('Failed to remove staff status', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to remove staff status: $e',
      );
    }
  }

  Future<void> resetPassword(String userId, String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _adminApiService.resetPassword(userId, newPassword);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      _logger.e('Failed to reset password', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to reset password: $e',
      );
    }
  }

  Future<void> updateUser(
    String userId,
    String userName,
    String email,
    String? firstName,
    String? lastName,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final updatedUser = await _adminApiService.updateUser(
        userId,
        userName,
        email,
        firstName,
        lastName,
      );
      
      // Update user in state
      final updatedUsers = state.users.map((user) {
        if (user.id == userId) {
          return updatedUser;
        }
        return user;
      }).toList();
      
      state = state.copyWith(isLoading: false, users: updatedUsers);
    } catch (e) {
      _logger.e('Failed to update user', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update user: $e',
      );
    }
  }

  Future<void> viewUserPosts(String userId) async {
    // This method is primarily for UI signaling and future analytics tracking
    _logger.i('Viewing posts for user: $userId');
    // No state update needed as we're using a FutureBuilder in the UI
  }

  Future<void> viewUserComments(String userId) async {
    // This method is primarily for UI signaling and future analytics tracking
    _logger.i('Viewing comments for user: $userId');
    // No state update needed as we're using a FutureBuilder in the UI
  }
} 