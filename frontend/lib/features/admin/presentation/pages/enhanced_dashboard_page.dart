import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/admin/domain/entities/dashboard_metrics.dart';
import 'package:frontend/features/admin/presentation/controllers/dashboard_controller.dart';
import 'package:frontend/features/admin/presentation/widgets/dashboard_stats_card.dart';
import 'package:frontend/features/admin/presentation/widgets/recent_activity_list.dart';
import 'package:frontend/features/admin/presentation/widgets/analytics_chart.dart';
import 'package:frontend/features/admin/presentation/widgets/metrics_data_table.dart';
import 'package:frontend/features/admin/presentation/widgets/location_map_chart.dart';

class EnhancedDashboardPage extends ConsumerStatefulWidget {
  const EnhancedDashboardPage({Key? key}) : super(key: key);

  @override
  ConsumerState<EnhancedDashboardPage> createState() => _EnhancedDashboardPageState();
}

class _EnhancedDashboardPageState extends ConsumerState<EnhancedDashboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedUserTrendPeriod = 'monthly';
  String _selectedContentTrendPeriod = 'monthly';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    Future.microtask(() => 
      ref.read(dashboardControllerProvider.notifier).loadDashboardData()
    );
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(dashboardControllerProvider.notifier).loadDashboardData(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Analytics'),
            Tab(text: 'User Insights'),
          ],
        ),
      ),
      body: dashboardState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text(
            'Error loading dashboard: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
        data: (metrics) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(metrics),
              _buildAnalyticsTab(metrics),
              _buildUserInsightsTab(metrics),
            ],
          );
        },
      ),
      drawer: _buildDrawer(context),
    );
  }
  
  Widget _buildOverviewTab(DashboardMetrics metrics) {
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
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            
            // Stats cards - first row
            Row(
              children: [
                Expanded(
                  child: DashboardStatsCard(
                    title: 'Total Users',
                    value: metrics.totalUsers.toString(),
                    icon: Icons.people,
                    color: Colors.blue,
                    onTap: () => Navigator.pushNamed(context, '/admin/users'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DashboardStatsCard(
                    title: 'Active Users',
                    value: metrics.activeUsers.toString(),
                    icon: Icons.person_outline,
                    color: Colors.green,
                    onTap: () => Navigator.pushNamed(context, '/admin/users/active'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Stats cards - second row
            Row(
              children: [
                Expanded(
                  child: DashboardStatsCard(
                    title: 'Pending Posts',
                    value: metrics.pendingPosts.toString(),
                    icon: Icons.article,
                    color: Colors.orange,
                    onTap: () => Navigator.pushNamed(context, '/admin/posts/pending'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DashboardStatsCard(
                    title: 'Pending Comments',
                    value: metrics.pendingComments.toString(),
                    icon: Icons.comment,
                    color: Colors.purple,
                    onTap: () => Navigator.pushNamed(context, '/admin/comments/pending'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Stats cards - third row
            Row(
              children: [
                Expanded(
                  child: DashboardStatsCard(
                    title: 'Unresolved Flags',
                    value: metrics.unresolvedFlags.toString(),
                    icon: Icons.flag,
                    color: Colors.red,
                    onTap: () => Navigator.pushNamed(context, '/admin/flags'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DashboardStatsCard(
                    title: 'New Users Today',
                    value: metrics.newUsersToday.toString(),
                    icon: Icons.person_add,
                    color: Colors.teal,
                    onTap: () => Navigator.pushNamed(context, '/admin/users/new'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Recent activities
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            
            RecentActivityList(
              activities: metrics.recentActivities,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab(DashboardMetrics metrics) {
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
              'Content Analytics',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            
            // Content trend chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Content Growth Trends',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        DropdownButton<String>(
                          value: _selectedContentTrendPeriod,
                          items: const [
                            DropdownMenuItem(value: 'daily', child: Text('Daily')),
                            DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                            DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedContentTrendPeriod = value;
                              });
                              ref.read(dashboardControllerProvider.notifier)
                                .switchTrendPeriod('content', value);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 250,
                      child: AnalyticsChart(
                        data: metrics.contentTrends[_selectedContentTrendPeriod] ?? [],
                        label: 'Content',
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Content by category
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Content by Category',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 300,
                      child: MetricsDataTable(
                        data: metrics.contentByCategory.entries
                          .map((e) => {'category': e.key, 'count': e.value})
                          .toList(),
                        columns: const ['Category', 'Count'],
                        valueFields: const ['category', 'count'],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Content metrics
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Content Metrics',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Content Today'),
                      trailing: Text(
                        metrics.totalContentToday.toString(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.date_range),
                      title: const Text('Content This Week'),
                      trailing: Text(
                        metrics.totalContentThisWeek.toString(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.calendar_month),
                      title: const Text('Content This Month'),
                      trailing: Text(
                        metrics.totalContentThisMonth.toString(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInsightsTab(DashboardMetrics metrics) {
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
              'User Insights',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            
            // User trend chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'User Growth Trends',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        DropdownButton<String>(
                          value: _selectedUserTrendPeriod,
                          items: const [
                            DropdownMenuItem(value: 'daily', child: Text('Daily')),
                            DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                            DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedUserTrendPeriod = value;
                              });
                              ref.read(dashboardControllerProvider.notifier)
                                .switchTrendPeriod('user', value);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 250,
                      child: AnalyticsChart(
                        data: metrics.userTrends[_selectedUserTrendPeriod] ?? [],
                        label: 'Users',
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Users by location
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Users by Location',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 300,
                      child: LocationMapChart(
                        locationData: metrics.usersByLocation,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // User engagement
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Engagement Rates',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 300,
                      child: MetricsDataTable(
                        data: metrics.userEngagementRates.entries
                          .map((e) => {'metric': e.key, 'rate': '${(e.value * 100).toStringAsFixed(1)}%'})
                          .toList(),
                        columns: const ['Metric', 'Rate'],
                        valueFields: const ['metric', 'rate'],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Enhanced Analytics',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: true,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.article),
            title: const Text('Content Moderation'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/content');
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('User Management'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/users');
            },
          ),
          ListTile(
            leading: const Icon(Icons.flag),
            title: const Text('Reported Content'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/flags');
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/notifications');
            },
          ),
          ListTile(
            leading: const Icon(Icons.list),
            title: const Text('System Logs'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/logs');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/settings');
            },
          ),
        ],
      ),
    );
  }
} 