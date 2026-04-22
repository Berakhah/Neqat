import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/admin/data/datasources/admin_api_service.dart';
import 'package:go_router/go_router.dart';

class NotificationComposePage extends ConsumerStatefulWidget {
  const NotificationComposePage({super.key});

  @override
  ConsumerState<NotificationComposePage> createState() => _NotificationComposePageState();
}

class _NotificationComposePageState extends ConsumerState<NotificationComposePage> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _message = '';
  String _notificationType = 'ANNOUNCEMENT';
  bool _isGlobal = true;
  List<String> _selectedUserIds = [];
  bool _sending = false;
  String? _sendResult;

  final List<DropdownMenuItem<String>> _typeOptions = const [
    DropdownMenuItem(value: 'ANNOUNCEMENT', child: Text('System Announcement')),
    DropdownMenuItem(value: 'USER_SPECIFIC', child: Text('User Specific')),
    DropdownMenuItem(value: 'ALERT', child: Text('Alert')),
    DropdownMenuItem(value: 'INFO', child: Text('Information')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compose Notification'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View Notification History',
            onPressed: () {
              context.go('/admin/notifications/history');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _notificationType,
                items: _typeOptions,
                onChanged: (val) => setState(() => _notificationType = val ?? 'ANNOUNCEMENT'),
                decoration: const InputDecoration(labelText: 'Notification Type'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Title'),
                onChanged: (val) => _title = val,
                validator: (val) => val == null || val.isEmpty ? 'Title required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Message'),
                maxLines: 5,
                onChanged: (val) => _message = val,
                validator: (val) => val == null || val.isEmpty ? 'Message required' : null,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Send to all users (Global)'),
                value: _isGlobal,
                onChanged: (val) => setState(() => _isGlobal = val),
              ),
              if (!_isGlobal) ...[
                const SizedBox(height: 8),
                _UserSelector(
                  onChanged: (ids) => setState(() => _selectedUserIds = ids),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: _sending ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.send),
                label: const Text('Send Notification'),
                onPressed: _sending ? null : _onSend,
              ),
              if (_sendResult != null) ...[
                const SizedBox(height: 16),
                Text(_sendResult!, style: TextStyle(color: _sendResult!.contains('success') ? Colors.green : Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onSend() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _sendResult = null;
    });
    try {
      final api = ref.read(adminApiServiceProvider);
      final notification = {
        'title': _title,
        'message': _message,
        'notification_type': _notificationType,
        'is_global': _isGlobal,
        if (!_isGlobal) 'target_users': _selectedUserIds,
      };
      // Create notification
      final notificationId = await api.createNotification(notification);
      // Send notification
      await api.sendNotification(notificationId);
      setState(() {
        _sendResult = 'Notification sent successfully!';
      });
    } catch (e) {
      setState(() {
        _sendResult = 'Failed to send notification: $e';
      });
    } finally {
      setState(() {
        _sending = false;
      });
    }
  }
}

class _UserSelector extends ConsumerStatefulWidget {
  final ValueChanged<List<String>> onChanged;
  const _UserSelector({required this.onChanged, super.key});

  @override
  ConsumerState<_UserSelector> createState() => _UserSelectorState();
}

class _UserSelectorState extends ConsumerState<_UserSelector> {
  List<Map<String, dynamic>> _users = [];
  List<String> _selected = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(adminApiServiceProvider);
      final users = await api.getUsers();
      setState(() {
        _users = users.map((u) => {'id': u.id, 'name': u.userName, 'email': u.email}).toList();
      });
    } catch (_) {
      setState(() => _users = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Users', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _users.map((user) {
            final selected = _selected.contains(user['id']);
            return FilterChip(
              label: Text('${user['name']} (${user['email'] ?? ''})'),
              selected: selected,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selected.add(user['id']);
                  } else {
                    _selected.remove(user['id']);
                  }
                  widget.onChanged(_selected);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
} 