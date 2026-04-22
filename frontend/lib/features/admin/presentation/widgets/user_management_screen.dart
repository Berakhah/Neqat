import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/admin_providers.dart';
import '../controllers/admin_user_controller.dart';
import '../controllers/user_management_controller.dart';
import '../../domain/entities/admin_user.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  String _searchQuery = '';
  bool _showActiveOnly = false;
  bool _showStaffOnly = false;
  
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(userManagementControllerProvider.notifier).loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final usersState = ref.watch(userManagementControllerProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(userManagementControllerProvider.notifier).loadUsers();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: usersState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (users) => _buildUsersList(users),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to user creation screen or show dialog
          _showAddUserDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search users...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                FilterChip(
                  label: const Text('Active Only'),
                  selected: _showActiveOnly,
                  onSelected: (selected) {
                    setState(() {
                      _showActiveOnly = selected;
                    });
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Staff Only'),
                  selected: _showStaffOnly,
                  onSelected: (selected) {
                    setState(() {
                      _showStaffOnly = selected;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersList(List<AdminUser> users) {
    // Apply filters
    final filteredUsers = users.where((user) {
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!(user.userName.toLowerCase().contains(query) ||
              (user.email?.toLowerCase().contains(query) ?? false) ||
              (user.firstName?.toLowerCase().contains(query) ?? false) ||
              (user.lastName?.toLowerCase().contains(query) ?? false))) {
          return false;
        }
      }
      
      // Apply active filter
      if (_showActiveOnly && !user.isActive) {
        return false;
      }
      
      // Apply staff filter
      if (_showStaffOnly && !user.isStaff) {
        return false;
      }
      
      return true;
    }).toList();
    
    if (filteredUsers.isEmpty) {
      return const Center(
        child: Text('No users found matching the criteria'),
      );
    }
    
    return ListView.builder(
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return _buildUserCard(user);
      },
    );
  }
  
  Widget _buildUserCard(AdminUser user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: user.isStaff ? Colors.blue.shade300 : Colors.grey.shade300,
          width: user.isStaff ? 2 : 1,
        ),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: user.isActive ? Colors.green.shade100 : Colors.grey.shade300,
          child: user.profileImage != null
              ? ClipOval(
                  child: Image.network(
                    user.profileImage!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.person,
                      color: user.isActive ? Colors.green : Colors.grey,
                    ),
                  ),
                )
              : Icon(
                  Icons.person,
                  color: user.isActive ? Colors.green : Colors.grey,
                ),
        ),
        title: Row(
          children: [
            Text(
              user.userName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (user.isStaff)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Chip(
                  label: const Text('Staff'),
                  backgroundColor: Colors.blue.shade100,
                  labelStyle: TextStyle(
                    color: Colors.blue.shade800,
                    fontSize: 12,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                ),
              ),
          ],
        ),
        subtitle: Text(
          user.email ?? 'No email',
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            _handleUserAction(value, user);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
              ),
            ),
            PopupMenuItem(
              value: user.isActive ? 'disable' : 'enable',
              child: ListTile(
                leading: Icon(user.isActive ? Icons.block : Icons.check_circle),
                title: Text(user.isActive ? 'Disable' : 'Enable'),
              ),
            ),
            PopupMenuItem(
              value: user.isStaff ? 'removeStaff' : 'makeStaff',
              child: ListTile(
                leading: Icon(user.isStaff ? Icons.person : Icons.admin_panel_settings),
                title: Text(user.isStaff ? 'Remove Staff' : 'Make Staff'),
              ),
            ),
            const PopupMenuItem(
              value: 'resetPassword',
              child: ListTile(
                leading: Icon(Icons.password),
                title: Text('Reset Password'),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user.firstName != null || user.lastName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text('${user.firstName ?? ''} ${user.lastName ?? ''}'.trim()),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('Joined: ${DateFormat('MMM d, yyyy').format(user.dateJoined)}'),
                    ],
                  ),
                ),
                const Divider(),
                _buildUserStats(user),
                const SizedBox(height: 16),
                _buildUserActions(user),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUserStats(AdminUser user) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.post_add, '${user.postCount ?? 0}', 'Posts'),
          _buildStatItem(Icons.comment, '${user.commentCount ?? 0}', 'Comments'),
          _buildStatItem(Icons.flag, '${user.flagCount ?? 0}', 'Flags'),
          _buildStatItem(
            Icons.access_time, 
            user.lastActive != null 
                ? DateFormat('MMM d').format(user.lastActive!) 
                : 'Never',
            'Last Active'
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
  
  Widget _buildUserActions(AdminUser user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.post_add, size: 16),
          label: const Text('View Posts'),
          onPressed: () {
            // Navigate to user posts screen
            _viewUserPosts(user);
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.blue.shade300),
          ),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.comment, size: 16),
          label: const Text('View Comments'),
          onPressed: () {
            // Navigate to user comments screen
            _viewUserComments(user);
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.green.shade300),
          ),
        ),
      ],
    );
  }
  
  void _handleUserAction(String action, AdminUser user) {
    final notifier = ref.read(userManagementControllerProvider.notifier);
    
    switch (action) {
      case 'edit':
        _showEditUserDialog(context, user);
        break;
      case 'disable':
        notifier.disableUser(user.id);
        break;
      case 'enable':
        notifier.enableUser(user.id);
        break;
      case 'makeStaff':
        notifier.makeStaff(user.id);
        break;
      case 'removeStaff':
        notifier.removeStaff(user.id);
        break;
      case 'resetPassword':
        _showResetPasswordDialog(context, user);
        break;
    }
  }
  
  void _showAddUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Create user logic
              Navigator.of(context).pop();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
  
  void _showEditUserDialog(BuildContext context, AdminUser user) {
    // Pre-fill fields with user data
    final usernameController = TextEditingController(text: user.userName);
    final emailController = TextEditingController(text: user.email);
    final firstNameController = TextEditingController(text: user.firstName);
    final lastNameController = TextEditingController(text: user.lastName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Update user logic
              ref.read(userManagementControllerProvider.notifier).updateUser(
                user.id,
                usernameController.text,
                emailController.text,
                firstNameController.text,
                lastNameController.text,
              );
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  void _showResetPasswordDialog(BuildContext context, AdminUser user) {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Password for ${user.userName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newPasswordController.text == confirmPasswordController.text) {
                ref.read(userManagementControllerProvider.notifier).resetPassword(
                  user.id,
                  newPasswordController.text,
                );
                Navigator.of(context).pop();
              } else {
                // Show password mismatch error
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
  
  void _viewUserPosts(AdminUser user) {
    final notifier = ref.read(userManagementControllerProvider.notifier);
    notifier.viewUserPosts(user.id);
    
    // Navigate to a filtered post list or show dialog with posts
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${user.userName}\'s Posts'),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: FutureBuilder(
            future: ref.read(adminApiServiceProvider).getUserPosts(user.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
                return const Center(child: Text('No posts found'));
              } else {
                final posts = snapshot.data as List;
                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return ListTile(
                      title: Text(post['title'] ?? 'Untitled Post'),
                      subtitle: Text(
                        post['status'] ?? 'Unknown Status',
                        style: TextStyle(
                          color: _getStatusColor(post['status'])
                        ),
                      ),
                      trailing: Text(
                        post['created_at'] != null 
                            ? DateFormat('MMM d, yyyy').format(DateTime.parse(post['created_at']))
                            : 'Unknown date'
                      ),
                    );
                  },
                );
              }
            },
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
  
  void _viewUserComments(AdminUser user) {
    final notifier = ref.read(userManagementControllerProvider.notifier);
    notifier.viewUserComments(user.id);
    
    // Navigate to a filtered comment list or show dialog with comments
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${user.userName}\'s Comments'),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: FutureBuilder(
            future: ref.read(adminApiServiceProvider).getUserComments(user.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
                return const Center(child: Text('No comments found'));
              } else {
                final comments = snapshot.data as List;
                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return ListTile(
                      title: Text(comment['content'] ?? 'No content'),
                      subtitle: Text(
                        comment['status'] ?? 'Unknown Status',
                        style: TextStyle(
                          color: _getStatusColor(comment['status'])
                        ),
                      ),
                      trailing: Text(
                        comment['created_at'] != null 
                            ? DateFormat('MMM d, yyyy').format(DateTime.parse(comment['created_at']))
                            : 'Unknown date'
                      ),
                    );
                  },
                );
              }
            },
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
  
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
} 