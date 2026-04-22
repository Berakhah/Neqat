import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/admin/data/datasources/admin_api_service.dart';
import 'package:frontend/features/admin/domain/entities/admin_user.dart';
import 'package:frontend/features/admin/presentation/providers/admin_providers.dart' as providers;
import 'package:logger/logger.dart';

final userManagementControllerProvider =
    StateNotifierProvider<UserManagementController, AsyncValue<List<AdminUser>>>(
  (ref) {
    final apiService = ref.watch(providers.adminApiServiceProvider);
    return UserManagementController(apiService);
  },
);

class UserManagementController extends StateNotifier<AsyncValue<List<AdminUser>>> {
  final AdminApiService _apiService;
  final Logger _logger = Logger();

  UserManagementController(this._apiService) : super(const AsyncValue.loading());

  Future<void> loadUsers({int page = 1}) async {
    try {
      state = const AsyncValue.loading();
      final users = await _apiService.getUsers();
      
      state = AsyncValue.data(users);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> searchUsers({required String query}) async {
    try {
      state = const AsyncValue.loading();
      final users = await _apiService.searchUsers(search: query, page: 1);
      state = AsyncValue.data(users);
    } catch (e) {
      _logger.e('Failed to search users', error: e);
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateUserStatus(String userId, bool isActive) async {
    try {
      if (isActive) {
        await _apiService.enableUser(userId);
      } else {
        await _apiService.disableUser(userId);
      }
      
      // Reload current users to reflect the update
      await loadUsers();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  // Additional methods needed by the UserManagementScreen
  Future<void> disableUser(String userId) async {
    try {
      await _apiService.disableUser(userId);
      await loadUsers(); // Reload the list
    } catch (e) {
      _logger.e('Failed to disable user', error: e);
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  Future<void> enableUser(String userId) async {
    try {
      await _apiService.enableUser(userId);
      await loadUsers(); // Reload the list
    } catch (e) {
      _logger.e('Failed to enable user', error: e);
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  Future<void> makeStaff(String userId) async {
    try {
      await _apiService.makeStaff(userId);
      await loadUsers(); // Reload the list
    } catch (e) {
      _logger.e('Failed to make user staff', error: e);
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  Future<void> removeStaff(String userId) async {
    try {
      await _apiService.removeStaff(userId);
      await loadUsers(); // Reload the list
    } catch (e) {
      _logger.e('Failed to remove staff status', error: e);
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  Future<void> updateUser(
    String userId,
    String userName,
    String email,
    String? firstName,
    String? lastName,
  ) async {
    try {
      await _apiService.updateUser(
        userId,
        userName,
        email,
        firstName,
        lastName,
      );
      await loadUsers(); // Reload the list
    } catch (e) {
      _logger.e('Failed to update user', error: e);
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  Future<void> resetPassword(String userId, String newPassword) async {
    try {
      await _apiService.resetPassword(userId, newPassword);
    } catch (e) {
      _logger.e('Failed to reset password', error: e);
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  Future<void> viewUserPosts(String userId) async {
    _logger.i('Viewing posts for user: $userId');
    // This is a UI action, no state update needed
  }
  
  Future<void> viewUserComments(String userId) async {
    _logger.i('Viewing comments for user: $userId');
    // This is a UI action, no state update needed
  }
} 