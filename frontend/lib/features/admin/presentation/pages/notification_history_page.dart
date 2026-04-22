import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/admin/data/datasources/admin_api_service.dart';

class NotificationHistoryPage extends ConsumerStatefulWidget {
  const NotificationHistoryPage({super.key});

  @override
  ConsumerState<NotificationHistoryPage> createState() => _NotificationHistoryPageState();
}

class _NotificationHistoryPageState extends ConsumerState<NotificationHistoryPage> {
  late Future<List<Map<String, dynamic>>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _fetchNotifications();
  }

  Future<List<Map<String, dynamic>>> _fetchNotifications() async {
    final api = ref.read(adminApiServiceProvider);
    return await api.getNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification History')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No notifications found'));
          }
          final notifications = snapshot.data!;
          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, i) => const Divider(),
            itemBuilder: (context, i) {
              final n = notifications[i];
              return ListTile(
                title: Text(n['title'] ?? 'No Title'),
                subtitle: Text(n['notification_type'] ?? ''),
                trailing: Text(n['created_at']?.toString().substring(0, 19) ?? ''),
                onTap: () => _showDetailsDialog(context, n),
              );
            },
          );
        },
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification['title'] ?? 'No Title'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${notification['notification_type'] ?? ''}'),
            const SizedBox(height: 8),
            Text('Message:'),
            Text(notification['message'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Created: ${notification['created_at']?.toString().substring(0, 19) ?? ''}'),
            if (notification['is_global'] == true) ...[
              const SizedBox(height: 8),
              const Text('Sent to: All Users'),
            ]
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
} 