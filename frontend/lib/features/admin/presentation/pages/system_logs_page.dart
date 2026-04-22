import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/features/admin/data/datasources/admin_api_service.dart';
import 'package:frontend/features/admin/presentation/providers/admin_providers.dart';

final systemLogsProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, page) async {
  final apiService = ref.watch(adminRepositoryProvider) as AdminApiService;
  return apiService.getSystemLogs(page: page);
});

class SystemLogsPage extends ConsumerStatefulWidget {
  const SystemLogsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SystemLogsPage> createState() => _SystemLogsPageState();
}

class _SystemLogsPageState extends ConsumerState<SystemLogsPage> {
  int _currentPage = 1;
  String _selectedLogType = 'All';
  
  final List<String> _logTypes = [
    'All',
    'LOGIN',
    'LOGOUT',
    'REGISTER',
    'PASSWORD_RESET',
    'PROFILE_UPDATE',
    'ADMIN_ACTION',
    'ERROR',
    'SECURITY',
    'CONTENT',
  ];

  @override
  Widget build(BuildContext context) {
    final logsAsyncValue = ref.watch(systemLogsProvider(_currentPage));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(systemLogsProvider(_currentPage)),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: logsAsyncValue.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return const Center(child: Text('No logs found'));
                }
                
                // Filter logs if a type is selected
                final filteredLogs = _selectedLogType == 'All' 
                    ? logs 
                    : logs.where((log) => log['action'] == _selectedLogType).toList();
                
                if (filteredLogs.isEmpty) {
                  return Center(
                    child: Text('No ${_selectedLogType.toLowerCase()} logs found'),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.refresh(systemLogsProvider(_currentPage));
                  },
                  child: ListView.builder(
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = filteredLogs[index];
                      return _buildLogCard(log);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error loading logs: $error'),
              ),
            ),
          ),
          _buildPagination(),
        ],
      ),
    );
  }
  
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          const Text('Filter by type:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 16.0),
          Expanded(
            child: DropdownButton<String>(
              value: _selectedLogType,
              isExpanded: true,
              underline: Container(
                height: 1,
                color: Colors.grey.shade400,
              ),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedLogType = newValue;
                  });
                }
              },
              items: _logTypes.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLogCard(Map<String, dynamic> log) {
    // Extract the log details
    final String action = log['action'] ?? 'UNKNOWN';
    final String details = log['details'] ?? 'No details';
    final String timestamp = log['timestamp'] ?? '';
    final String username = log['user']?['user_name'] ?? log['user']?['username'] ?? 'System';
    final String ipAddress = log['ip_address'] ?? 'Unknown';
    
    // Format timestamp if available
    String formattedDate = 'Unknown date';
    if (timestamp.isNotEmpty) {
      try {
        final DateTime dateTime = DateTime.parse(timestamp);
        formattedDate = DateFormat('MMM dd, yyyy HH:mm:ss').format(dateTime);
      } catch (e) {
        formattedDate = timestamp;
      }
    }
    
    // Determine card color based on action type
    Color cardColor;
    IconData actionIcon;
    
    switch (action) {
      case 'LOGIN':
        cardColor = Colors.green.shade50;
        actionIcon = Icons.login;
        break;
      case 'LOGOUT':
        cardColor = Colors.blue.shade50;
        actionIcon = Icons.logout;
        break;
      case 'REGISTER':
        cardColor = Colors.purple.shade50;
        actionIcon = Icons.person_add;
        break;
      case 'ERROR':
        cardColor = Colors.red.shade50;
        actionIcon = Icons.error;
        break;
      case 'SECURITY':
        cardColor = Colors.orange.shade50;
        actionIcon = Icons.security;
        break;
      case 'ADMIN_ACTION':
        cardColor = Colors.indigo.shade50;
        actionIcon = Icons.admin_panel_settings;
        break;
      case 'CONTENT':
        cardColor = Colors.teal.shade50;
        actionIcon = Icons.article;
        break;
      default:
        cardColor = Colors.grey.shade50;
        actionIcon = Icons.info;
    }
    
    return Card(
      color: cardColor,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ExpansionTile(
        leading: Icon(actionIcon),
        title: Text(
          action,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '$username • $formattedDate',
          style: const TextStyle(fontSize: 12.0),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 80.0,
                      child: Text(
                        'Details:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        details,
                        style: const TextStyle(
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    const SizedBox(
                      width: 80.0,
                      child: Text(
                        'IP Address:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(ipAddress),
                  ],
                ),
                if (log['user_agent'] != null) ...[
                  const SizedBox(height: 8.0),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        width: 80.0,
                        child: Text(
                          'User Agent:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          log['user_agent'],
                          style: const TextStyle(
                            fontSize: 12.0,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
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
            onPressed: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage--;
                    });
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
            },
          ),
        ],
      ),
    );
  }
} 