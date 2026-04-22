import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/features/admin/data/datasources/admin_api_service.dart';
import 'package:frontend/features/admin/presentation/providers/admin_providers.dart';

final systemLogsProvider = FutureProvider.family<List<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
  final apiService = ref.watch(adminRepositoryProvider) as AdminApiService;
  return apiService.getSystemLogs(
    page: params['page'] ?? 1,
    action: params['action'],
    username: params['username'],
    startDate: params['startDate'],
    endDate: params['endDate'],
  );
});

class SystemLogsPage extends ConsumerStatefulWidget {
  const SystemLogsPage({super.key});

  @override
  ConsumerState<SystemLogsPage> createState() => _SystemLogsPageState();
}

class _SystemLogsPageState extends ConsumerState<SystemLogsPage> {
  int _currentPage = 1;
  String _selectedLogType = 'All';
  final TextEditingController _usernameController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  
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

  Map<String, dynamic> get _filterParams => {
    'page': _currentPage,
    'action': _selectedLogType == 'All' ? null : _selectedLogType,
    'username': _usernameController.text.trim().isEmpty ? null : _usernameController.text.trim(),
    'startDate': _startDate != null ? _startDate!.toIso8601String().substring(0, 10) : null,
    'endDate': _endDate != null ? _endDate!.toIso8601String().substring(0, 10) : null,
  };

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logsAsyncValue = ref.watch(systemLogsProvider(_filterParams));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(systemLogsProvider(_filterParams)),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(context),
          Expanded(
            child: logsAsyncValue.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return const Center(child: Text('No logs found'));
                }
                
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.refresh(systemLogsProvider(_filterParams));
                  },
                  child: ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
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
  
  Widget _buildFilterBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      color: Colors.grey.shade100,
      child: Column(
        children: [
          Row(
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
                        _currentPage = 1;
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
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Username:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    hintText: 'Enter username',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) {
                    setState(() {
                      _currentPage = 1;
                    });
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: 'Search by username',
                onPressed: () {
                  setState(() {
                    _currentPage = 1;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Date range:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _startDate = picked;
                        _currentPage = 1;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Start date',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    child: Text(_startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : 'Select'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _endDate = picked;
                        _currentPage = 1;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'End date',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    child: Text(_endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : 'Select'),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Clear dates',
                onPressed: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                    _currentPage = 1;
                  });
                },
              ),
            ],
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