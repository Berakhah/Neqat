import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/admin/domain/entities/dashboard_metrics.dart';
import 'package:frontend/features/admin/presentation/controllers/dashboard_controller.dart';
import 'package:frontend/features/admin/presentation/widgets/dashboard_stats_card.dart';
import 'package:frontend/features/admin/presentation/widgets/recent_activity_list.dart';
import 'package:go_router/go_router.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(dashboardControllerProvider.notifier).loadDashboardData());
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(dashboardControllerProvider.notifier).loadDashboardData(),
          ),
        ],
      ),
      body: dashboardState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text(
            'Error loading dashboard: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
        data: (dashboardData) {
          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(dashboardControllerProvider.notifier).loadDashboardData();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard Overview',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  
                  // Stats cards
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      DashboardStatsCard(
                        title: 'Total Users',
                        value: dashboardData.totalUsers.toString(),
                        icon: Icons.people,
                        color: Colors.blue,
                        onTap: () => context.push('/admin/users'),
                      ),
                      DashboardStatsCard(
                        title: 'Active Users',
                        value: dashboardData.activeUsers.toString(),
                        icon: Icons.person_outline,
                        color: Colors.green,
                        onTap: () => context.push('/admin/users'),
                      ),
                      DashboardStatsCard(
                        title: 'New Users (30 days)',
                        value: dashboardData.newUsersLastMonth.toString(),
                        icon: Icons.person_add,
                        color: Colors.orange,
                        onTap: () => context.push('/admin/users'),
                      ),
                      DashboardStatsCard(
                        title: 'System Logs',
                        value: dashboardData.recentLogs.length.toString(),
                        icon: Icons.list_alt,
                        color: Colors.purple,
                        onTap: () => context.push('/admin/logs'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  Text(
                    'Content Management',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  
                  // Content management cards
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      DashboardStatsCard(
                        title: 'Pending Posts',
                        value: dashboardData.pendingPosts.toString(),
                        icon: Icons.article,
                        color: Colors.red,
                        onTap: () => context.push('/admin/posts/pending'),
                      ),
                      DashboardStatsCard(
                        title: 'Pending Comments',
                        value: dashboardData.pendingComments.toString(),
                        icon: Icons.comment,
                        color: Colors.amber,
                        onTap: () => context.push('/admin/comments/pending'),
                      ),
                      DashboardStatsCard(
                        title: 'Content Moderation',
                        value: 'Manage',
                        icon: Icons.admin_panel_settings,
                        color: Colors.teal,
                        onTap: () => context.push('/admin/content'),
                      ),
                      DashboardStatsCard(
                        title: 'Settings',
                        value: 'Configure',
                        icon: Icons.settings,
                        color: Colors.grey,
                        onTap: () => context.push('/admin/settings'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  Text(
                    'Recent System Logs',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  
                  // Recent system logs
                  if (dashboardData.recentLogs.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No recent system logs'),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: dashboardData.recentLogs.length,
                      itemBuilder: (context, index) {
                        final log = dashboardData.recentLogs[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(log['details'] ?? 'Unknown action'),
                            subtitle: Text(
                              '${log['action_display'] ?? log['action'] ?? 'Action'} • ${log['timestamp'] ?? 'Unknown time'}',
                            ),
                            leading: Icon(_getLogIcon(log['action']), color: _getLogColor(log['action'])),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Admin Panel',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
                context.go('/admin');
              },
            ),
            ListTile(
              leading: const Icon(Icons.article),
              title: const Text('Content Moderation'),
              onTap: () {
                Navigator.pop(context);
                context.push('/admin/content');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('User Management'),
              onTap: () {
                Navigator.pop(context);
                context.push('/admin/users');
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('Reported Content'),
              onTap: () {
                Navigator.pop(context);
                context.push('/admin/flags');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                context.push('/admin/settings');
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper method to get appropriate icon for log action
  IconData _getLogIcon(String? action) {
    switch (action) {
      case 'LOGIN':
        return Icons.login;
      case 'LOGOUT':
        return Icons.logout;
      case 'REGISTER':
        return Icons.person_add;
      case 'ADMIN_ACTION':
        return Icons.admin_panel_settings;
      case 'SECURITY':
        return Icons.security;
      case 'CONTENT':
        return Icons.article;
      default:
        return Icons.info;
    }
  }
  
  // Helper method to get appropriate color for log action
  Color _getLogColor(String? action) {
    switch (action) {
      case 'LOGIN':
        return Colors.green;
      case 'LOGOUT':
        return Colors.blue;
      case 'REGISTER':
        return Colors.purple;
      case 'ADMIN_ACTION':
        return Colors.orange;
      case 'SECURITY':
        return Colors.red;
      case 'CONTENT':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
} 