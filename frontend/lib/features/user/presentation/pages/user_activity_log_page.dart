import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:frontend/app/providers/auth_provider.dart';

// TODO: Uncomment and implement userApiServiceProvider when available
// final userActivityLogProvider = FutureProvider.family<List<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
//   // Replace with your actual API service
//   final apiService = ref.watch(userApiServiceProvider);
//   return apiService.getUserActivityLogs(
//     page: params['page'] ?? 1,
//     action: params['action'],
//     startDate: params['startDate'],
//     endDate: params['endDate'],
//   );
// });

// TODO: Implement userApiServiceProvider in user/data/datasources/user_api_service.dart
// TODO: Add exportUserActivityLogs method similar to adminApiService.exportSystemLogs
// TODO: Wire up export button to call exportUserActivityLogs and handle file download

final userActivityLogProvider = FutureProvider.family<List<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
  // TEMP: Return empty list until userApiServiceProvider is implemented
  return [];
});

class UserActivityLogPage extends ConsumerStatefulWidget {
  const UserActivityLogPage({super.key});

  @override
  ConsumerState<UserActivityLogPage> createState() => _UserActivityLogPageState();
}

class _UserActivityLogPageState extends ConsumerState<UserActivityLogPage> {
  String _selectedAction = 'All';
  DateTime? _startDate;
  DateTime? _endDate;
  int _currentPage = 1;

  List<String> get _actionTypes => [
    'All', 'LOGIN', 'LOGOUT', 'REGISTER', 'PASSWORD_RESET', 'PROFILE_UPDATE', 'CONTENT', 'SECURITY', 'ERROR', 'ADMIN_ACTION'
  ];

  Map<String, dynamic> get _filterParams => {
    'page': _currentPage,
    'action': _selectedAction == 'All' ? null : _selectedAction,
    'startDate': _startDate != null ? _startDate!.toIso8601String().substring(0, 10) : null,
    'endDate': _endDate != null ? _endDate!.toIso8601String().substring(0, 10) : null,
  };

  Future<void> _pickDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(userActivityLogProvider(_filterParams));
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Activity Log'),
        backgroundColor: Colors.deepPurple,
        actions: [
          PopupMenuButton<String>(
            onSelected: (format) => _exportLogs(context, format),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'csv', child: Text('Export as CSV')),
              const PopupMenuItem(value: 'json', child: Text('Export as JSON')),
            ],
            icon: const Icon(Icons.download),
            tooltip: 'Export',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedAction,
                    items: _actionTypes.map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedAction = val ?? 'All'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.date_range),
                  onPressed: () => _pickDateRange(context),
                  tooltip: 'Pick date range',
                ),
                if (_startDate != null || _endDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() {
                      _startDate = null;
                      _endDate = null;
                    }),
                    tooltip: 'Clear date range',
                  ),
              ],
            ),
          ),
          Expanded(
            child: logsAsync.when(
              loading: () => _buildLoadingList(),
              error: (err, stack) => _buildErrorState(err, context),
              data: (logs) => logs.isEmpty
                  ? _buildEmptyState()
                  : _buildLogList(logs),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      itemCount: 8,
      itemBuilder: (context, i) => const ListTile(
        leading: CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.hourglass_empty)),
        title: SizedBox(height: 16, child: DecoratedBox(decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.all(Radius.circular(4))))),
        subtitle: SizedBox(height: 12, child: DecoratedBox(decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.all(Radius.circular(4))))),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('No activity found', style: TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object err, BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text('Failed to load activity log', style: const TextStyle(fontSize: 18, color: Colors.red)),
          const SizedBox(height: 8),
          Text(err.toString(), style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList(List<Map<String, dynamic>> logs) {
    return ListView.separated(
      itemCount: logs.length,
      separatorBuilder: (context, i) => const Divider(),
      itemBuilder: (context, i) {
        final log = logs[i];
        final action = log['action'] ?? 'UNKNOWN';
        final details = log['details'] ?? 'No details';
        final timestamp = log['timestamp'] ?? '';
        final formattedDate = timestamp.isNotEmpty ? DateFormat('MMM dd, yyyy HH:mm:ss').format(DateTime.parse(timestamp)) : '';
        final iconData = _iconForAction(action);
        final color = _colorForAction(action);
        return ExpansionTile(
          leading: CircleAvatar(backgroundColor: color.withOpacity(0.15), child: Icon(iconData, color: color)),
          title: Text(details, style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text(formattedDate),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (log['ip_address'] != null) Text('IP: ${log['ip_address']}'),
                  if (log['user_agent'] != null) Text('Device: ${log['user_agent']}'),
                  if (log['object_type'] != null && log['object_id'] != null)
                    Text('Object: ${log['object_type']} (${log['object_id']})'),
                  if (log['before'] != null) Text('Before: ${log['before']}'),
                  if (log['after'] != null) Text('After: ${log['after']}'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _iconForAction(String action) {
    switch (action) {
      case 'LOGIN': return Icons.login;
      case 'LOGOUT': return Icons.logout;
      case 'REGISTER': return Icons.person_add;
      case 'PASSWORD_RESET': return Icons.lock_reset;
      case 'PROFILE_UPDATE': return Icons.edit;
      case 'ADMIN_ACTION': return Icons.admin_panel_settings;
      case 'SECURITY': return Icons.security;
      case 'CONTENT': return Icons.article;
      case 'ERROR': return Icons.error;
      default: return Icons.info;
    }
  }

  Color _colorForAction(String action) {
    switch (action) {
      case 'LOGIN': return Colors.green;
      case 'LOGOUT': return Colors.blue;
      case 'REGISTER': return Colors.purple;
      case 'PASSWORD_RESET': return Colors.orange;
      case 'PROFILE_UPDATE': return Colors.teal;
      case 'ADMIN_ACTION': return Colors.indigo;
      case 'SECURITY': return Colors.red;
      case 'CONTENT': return Colors.deepOrange;
      case 'ERROR': return Colors.redAccent;
      default: return Colors.grey;
    }
  }

  Future<void> _exportLogs(BuildContext context, String format) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final token = ref.read(authProvider.select((state) => state.token));
      if (token == null) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Not authenticated. Please log in.')),
        );
        return;
      }
      final url = Uri.parse('https://localhost:8000/api/useractivity/export/?format=$format');
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': format == 'csv' ? 'text/csv' : 'application/json',
      });
      if (response.statusCode == 200) {
        final fileName = format == 'csv' ? 'user_activity_log.csv' : 'user_activity_log.json';
        final filePath = await _downloadAndSaveFile(response.bodyBytes, fileName);
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Exported to $filePath')),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Export failed: ${response.statusCode}')),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Export error: $e')),
      );
    }
  }

  Future<String> _downloadAndSaveFile(List<int> bytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }
} 