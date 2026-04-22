import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/admin/data/datasources/admin_api_service.dart';
import 'package:frontend/features/admin/presentation/widgets/filter_bar.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:frontend/app/providers/auth_provider.dart';

class AuditLogPage extends ConsumerStatefulWidget {
  const AuditLogPage({super.key});

  @override
  ConsumerState<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends ConsumerState<AuditLogPage> {
  String _selectedAction = 'All';
  final TextEditingController _usernameController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _lastUpdated;
  Timer? _refreshTimer;

  List<String> get _actionTypes => ['All', 'PERMISSION_DENIED', 'ADMIN_ACTION'];

  Map<String, dynamic> get _filterParams => {
    'page': 1,
    'action': _selectedAction == 'All' ? null : _selectedAction,
    'username': _usernameController.text.trim().isEmpty ? null : _usernameController.text.trim(),
    'startDate': _startDate != null ? _startDate!.toIso8601String().substring(0, 10) : null,
    'endDate': _endDate != null ? _endDate!.toIso8601String().substring(0, 10) : null,
  };

  @override
  void initState() {
    super.initState();
    _refreshData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _refreshData());
  }

  void _refreshData() {
    setState(() {
      _lastUpdated = DateTime.now();
    });
    ref.refresh(systemLogsProvider(_filterParams));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _usernameController.dispose();
    super.dispose();
  }

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
    final logsAsync = ref.watch(systemLogsProvider(_filterParams));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
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
            child: FilterBar(
              actions: _actionTypes,
              selectedAction: _selectedAction,
              onActionChanged: (val) {
                if (val != null) setState(() => _selectedAction = val);
              },
              searchController: _usernameController,
              searchHint: 'Username',
              onSearchChanged: (_) => setState(() {}),
              startDate: _startDate,
              endDate: _endDate,
              onDateRangePick: () => _pickDateRange(context),
              onClearDateRange: () => setState(() {
                _startDate = null;
                _endDate = null;
              }),
            ),
          ),
          if (_lastUpdated != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                'Last updated: ${DateFormat.Hms().format(_lastUpdated!)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          Expanded(
            child: logsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (logs) {
                final filtered = logs.where((log) {
                  if (_selectedAction == 'All') return true;
                  return log['action'] == _selectedAction;
                }).toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('No audit log entries found.'));
                }
                return RefreshIndicator(
                  onRefresh: () async => _refreshData(),
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (context, i) => const Divider(),
                    itemBuilder: (context, i) {
                      final log = filtered[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: log['action'] == 'PERMISSION_DENIED'
                              ? Colors.red.shade100
                              : Colors.blue.shade100,
                          child: Icon(
                            log['action'] == 'PERMISSION_DENIED'
                                ? Icons.block
                                : Icons.admin_panel_settings,
                            color: log['action'] == 'PERMISSION_DENIED'
                                ? Colors.red
                                : Colors.blue,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              log['action'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                log['details'] ?? 'No details',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text('User: ${log['user']?['user_name'] ?? 'System'}'),
                        trailing: Text(
                          log['timestamp']?.toString().substring(0, 19) ?? '',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        onTap: () => _showDetailsDialog(context, log),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(log['action'] ?? 'Log Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User: ${log['user']?['user_name'] ?? 'System'}'),
            const SizedBox(height: 8),
            Text('Details:'),
            Text(log['details'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Timestamp: ${log['timestamp']?.toString().substring(0, 19) ?? ''}'),
            if (log['ip_address'] != null) ...[
              const SizedBox(height: 8),
              Text('IP: ${log['ip_address']}'),
            ],
          ],
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
      final params = _filterParams;
      final query = [
        if (params['action'] != null) 'action=${params['action']}',
        if (params['username'] != null) 'username=${params['username']}',
        if (params['startDate'] != null) 'start_date=${params['startDate']}',
        if (params['endDate'] != null) 'end_date=${params['endDate']}',
        'format=$format',
      ].where((e) => e.isNotEmpty).join('&');
      final url = Uri.parse('https://localhost:8000/api/admin/logs/export/?$query');
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': format == 'csv' ? 'text/csv' : 'application/json',
      });
      if (response.statusCode == 200) {
        final fileName = format == 'csv' ? 'system_log.csv' : 'system_log.json';
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

final systemLogsProvider = FutureProvider.family<List<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
  final apiService = ref.watch(adminApiServiceProvider);
  return apiService.getSystemLogs(
    page: params['page'] ?? 1,
    action: params['action'],
    username: params['username'],
    startDate: params['startDate'],
    endDate: params['endDate'],
  );
}); 