import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/admin/presentation/controllers/dashboard_controller.dart';
import 'package:frontend/features/admin/presentation/widgets/dashboard_stats_card.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/app/providers/user_provider.dart';
import 'package:animations/animations.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  int _selectedIndex = 0;
  DateTime? _lastUpdated;
  Timer? _refreshTimer;

  final List<_AdminNavDestination> _destinations = [
    _AdminNavDestination('Dashboard', Icons.dashboard, '/admin'),
    _AdminNavDestination('Content Moderation', Icons.article, '/admin/content'),
    _AdminNavDestination('User Management', Icons.people, '/admin/users'),
    _AdminNavDestination('Reported Content', Icons.flag, '/admin/flags'),
    _AdminNavDestination('Notifications', Icons.notifications, '/admin/notifications'),
    _AdminNavDestination('Audit Log', Icons.security, '/admin/audit-log'),
    _AdminNavDestination('Settings', Icons.settings, '/admin/settings'),
  ];

  void _onNavTap(BuildContext context, int index) {
    setState(() => _selectedIndex = index);
    final dest = _destinations[index];
    if (dest.route == '/admin') {
      context.go(dest.route);
    } else {
      context.push(dest.route);
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_refreshData);
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _refreshData());
  }

  void _refreshData() {
    setState(() {
      _lastUpdated = DateTime.now();
    });
    ref.read(dashboardControllerProvider.notifier).loadDashboardData();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardControllerProvider);
    final userState = ref.watch(userProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final nav = isWide
            ? NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (i) => _onNavTap(context, i),
                labelType: NavigationRailLabelType.all,
                leading: Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.deepPurple,
                        child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        userState.userData?['username'] ?? 'Admin',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                destinations: _destinations
                    .map((d) => NavigationRailDestination(
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Icon(d.icon, key: ValueKey(d.icon)),
                          ),
                          label: Text(d.label),
                        ))
                    .toList(),
              )
            : null;
        final drawer = !isWide
            ? Drawer(
                child: ListView(
                  children: [
                    UserAccountsDrawerHeader(
                      decoration: const BoxDecoration(color: Colors.deepPurple),
                      accountName: Text(userState.userData?['username'] ?? 'Admin'),
                      accountEmail: Text(userState.isAdmin ? 'Administrator' : 'User'),
                      currentAccountPicture: const CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.admin_panel_settings, color: Colors.deepPurple, size: 32),
                      ),
                    ),
                    ..._destinations.asMap().entries.map((entry) {
                      final i = entry.key;
                      final d = entry.value;
                      return ListTile(
                        leading: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Icon(d.icon, key: ValueKey(d.icon)),
                        ),
                        title: Text(d.label),
                        selected: _selectedIndex == i,
                        onTap: () {
                          Navigator.pop(context);
                          _onNavTap(context, i);
                        },
                      );
                    }),
                  ],
                ),
              )
            : null;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin Dashboard'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshData,
                tooltip: 'Refresh',
              ),
            ],
          ),
          drawer: drawer,
          body: Row(
            children: [
              if (isWide) nav!,
              Expanded(
                child: PageTransitionSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, animation, secondaryAnimation) =>
                      SharedAxisTransition(
                    animation: animation,
                    secondaryAnimation: secondaryAnimation,
                    transitionType: SharedAxisTransitionType.horizontal,
                    child: child,
                  ),
                  child: dashboardState.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) => Center(
                      child: Text(
                        'Error loading dashboard: $error',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    data: (dashboardData) {
                      return RefreshIndicator(
                        onRefresh: () async => _refreshData(),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_lastUpdated != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Text(
                                    'Last updated: ${DateFormat.Hms().format(_lastUpdated!)}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ),
                              Text(
                                'Dashboard Overview',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 16),
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
                                        leading: Icon(
                                          _getLogIcon(log['action']),
                                          color: _getLogColor(log['action']),
                                        ),
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
                ),
              ),
            ],
          ),
        );
      },
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

class _AdminNavDestination {
  final String label;
  final IconData icon;
  final String route;
  const _AdminNavDestination(this.label, this.icon, this.route);
}
