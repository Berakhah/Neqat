import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/admin/domain/entities/admin_user.dart';
import 'package:frontend/features/admin/presentation/controllers/user_management_controller.dart';
import 'package:frontend/features/admin/presentation/widgets/filter_bar.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class UserManagementPage extends ConsumerStatefulWidget {
  const UserManagementPage({super.key});

  @override
  ConsumerState<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends ConsumerState<UserManagementPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 1;
  bool _isSearching = false;
  DateTime? _lastUpdated;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(_refreshUsers);
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _refreshUsers());
  }

  void _refreshUsers() {
    setState(() {
      _lastUpdated = DateTime.now();
    });
    ref.read(userManagementControllerProvider.notifier).loadUsers(page: _currentPage);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userManagementControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? FilterBar(
                searchController: _searchController,
                searchHint: 'Search users...',
                onSearchChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    if (value.length > 2) {
                    ref.read(userManagementControllerProvider.notifier).searchUsers(query: value);
                    }
                  },
                )
                : const Text('User Management'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                  _refreshUsers();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: userState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
              child: Text(
                'Error loading users: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          return RefreshIndicator(
            onRefresh: () async => _refreshUsers(),
            child: Column(
              children: [
                if (_lastUpdated != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                    child: Text(
                      'Last updated: ${DateFormat.Hms().format(_lastUpdated!)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return _buildUserListItem(user);
                    },
                  ),
                ),
                _buildPagination(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserListItem(AdminUser user) {
    final bool isActive = user.isActive ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(user.username.substring(0, 1).toUpperCase() ?? 'U'),
        ),
        title: Text(
          user.fullName ?? user.username ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(user.email ?? 'No email'),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Inactive',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: user.isAdmin ?? false ? Colors.purple : Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.isAdmin ?? false ? 'Admin' : 'User',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleUserAction(value, user),
          itemBuilder:
              (context) => [
                const PopupMenuItem(value: 'view', child: Text('View Details')),
                PopupMenuItem(
                  value: isActive ? 'deactivate' : 'activate',
                  child: Text(isActive ? 'Deactivate User' : 'Activate User'),
                ),
                const PopupMenuItem(
                  value: 'reset_password',
                  child: Text('Reset Password'),
                ),
                if (user.isAdmin != true) // Don't allow deleting admins
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete User'),
                  ),
              ],
        ),
        onTap: () => _showUserDetails(user),
      ),
    );
  }

  void _handleUserAction(String action, AdminUser user) {
    switch (action) {
      case 'view':
        _showUserDetails(user);
        break;
      case 'activate':
        _updateUserStatus(user, true);
        break;
      case 'deactivate':
        _updateUserStatus(user, false);
        break;
      case 'reset_password':
        _showPasswordResetDialog(user);
        break;
      case 'delete':
        _showDeleteConfirmation(user);
        break;
    }
  }

  void _showUserDetails(AdminUser user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('User Details'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('Username', user.username ?? 'N/A'),
                  _buildDetailRow('Full Name', user.fullName ?? 'N/A'),
                  _buildDetailRow('Email', user.email ?? 'N/A'),
                  _buildDetailRow(
                    'Status',
                    user.isActive ?? false ? 'Active' : 'Inactive',
                  ),
                  _buildDetailRow(
                    'Role',
                    user.isAdmin ?? false ? 'Admin' : 'Regular User',
                  ),
                  _buildDetailRow('Joined', user.dateJoinedString ?? 'N/A'),
                  _buildDetailRow('Last Login', user.lastLogin ?? 'N/A'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _updateUserStatus(AdminUser user, bool status) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(status ? 'Activate User' : 'Deactivate User'),
            content: Text(
              'Are you sure you want to ${status ? 'activate' : 'deactivate'} ${user.username}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ref
                      .read(userManagementControllerProvider.notifier)
                      .updateUserStatus(user.id ?? '', status);
                },
                child: Text(status ? 'Activate' : 'Deactivate'),
              ),
            ],
          ),
    );
  }

  void _showPasswordResetDialog(AdminUser user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reset Password'),
            content: const Text(
              'This will send a password reset link to the user\'s email. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Call password reset API
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Password reset link sent to ${user.email}',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Send Reset Link'),
              ),
            ],
          ),
    );
  }

  void _showDeleteConfirmation(AdminUser user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete User'),
            content: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  const TextSpan(text: 'Are you sure you want to delete '),
                  TextSpan(
                    text: user.username ?? 'this user',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: '? This action cannot be undone.'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () {
                  Navigator.of(context).pop();
                  // Call delete user API
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User deleted successfully'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  ref
                      .read(userManagementControllerProvider.notifier)
                      .loadUsers(page: _currentPage);
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed:
                _currentPage > 1
                    ? () {
                      setState(() {
                        _currentPage--;
                      });
                      ref
                          .read(userManagementControllerProvider.notifier)
                          .loadUsers(page: _currentPage);
                    }
                    : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Page $_currentPage',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _currentPage++;
              });
              ref
                  .read(userManagementControllerProvider.notifier)
                  .loadUsers(page: _currentPage);
            },
          ),
        ],
      ),
    );
  }
}
