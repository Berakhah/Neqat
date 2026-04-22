import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/admin/presentation/providers/admin_providers.dart';

class AdminSettingsPage extends ConsumerStatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  ConsumerState<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends ConsumerState<AdminSettingsPage> {
  // Settings state
  bool _autoApproveContent = false;
  bool _enableUserRegistration = true;
  bool _enableSocialLogin = true;
  bool _enableEmailNotifications = true;
  String _moderationLevel = 'Medium';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(adminApiServiceProvider);
      final settings = await api.getAdminSettings();
      setState(() {
        _autoApproveContent = settings['auto_approve_content'] == true || settings['auto_approve_content'] == 'true';
        _enableUserRegistration = settings['enable_user_registration'] == true || settings['enable_user_registration'] == 'true';
        _enableSocialLogin = settings['enable_social_login'] == true || settings['enable_social_login'] == 'true';
        _enableEmailNotifications = settings['enable_email_notifications'] == true || settings['enable_email_notifications'] == 'true';
        _moderationLevel = settings['moderation_level'] ?? 'Medium';
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load settings: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);
    try {
      final api = ref.read(adminApiServiceProvider);
      await api.updateAdminSettings({
        'auto_approve_content': _autoApproveContent,
        'enable_user_registration': _enableUserRegistration,
        'enable_social_login': _enableSocialLogin,
        'enable_email_notifications': _enableEmailNotifications,
        'moderation_level': _moderationLevel,
      });
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Settings'),
        actions: [
          IconButton(
            icon: _saving ? CircularProgressIndicator(color: Colors.white) : const Icon(Icons.save),
            onPressed: _saving ? null : _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Global Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Content Settings
            const Text(
              'Content Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SwitchListTile(
              title: const Text('Auto-approve content'),
              subtitle:
                  const Text('Automatically approve new posts and comments'),
              value: _autoApproveContent,
              onChanged: (value) {
                setState(() {
                  _autoApproveContent = value;
                });
              },
            ),

            // Dropdown for moderation level
            ListTile(
              title: const Text('Moderation level'),
              subtitle: const Text(
                  'Set the sensitivity level for content moderation'),
              trailing: DropdownButton<String>(
                value: _moderationLevel,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _moderationLevel = newValue;
                    });
                  }
                },
                items: <String>['Low', 'Medium', 'High', 'Very High']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),

            const Divider(),

            // User Settings
            const Text(
              'User Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SwitchListTile(
              title: const Text('Enable user registration'),
              subtitle: const Text('Allow new users to register'),
              value: _enableUserRegistration,
              onChanged: (value) {
                setState(() {
                  _enableUserRegistration = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Enable social login'),
              subtitle: const Text('Allow users to login with social accounts'),
              value: _enableSocialLogin,
              onChanged: (value) {
                setState(() {
                  _enableSocialLogin = value;
                });
              },
            ),

            const Divider(),

            // Notification Settings
            const Text(
              'Notification Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SwitchListTile(
              title: const Text('Enable email notifications'),
              subtitle: const Text('Send notifications to users via email'),
              value: _enableEmailNotifications,
              onChanged: (value) {
                setState(() {
                  _enableEmailNotifications = value;
                });
              },
            ),

            const SizedBox(height: 32),

            // Admin actions
            const Text(
              'Admin Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever),
              label: const Text('Clear System Logs'),
              onPressed: () => _showConfirmDialog(
                'Clear System Logs',
                'Are you sure you want to clear all system logs? This action cannot be undone.',
                _clearSystemLogs,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reset Content Flags'),
              onPressed: () => _showConfirmDialog(
                'Reset Content Flags',
                'Are you sure you want to reset all content flags? This action cannot be undone.',
                _resetContentFlags,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmDialog(
      String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _clearSystemLogs() {
    // Here you would implement the actual clearing logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('System logs cleared'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _resetContentFlags() {
    // Here you would implement the actual reset logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Content flags reset'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
