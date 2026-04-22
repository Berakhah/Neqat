import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminSettingsPage extends ConsumerStatefulWidget {
  const AdminSettingsPage({Key? key}) : super(key: key);

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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
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
              subtitle: const Text('Automatically approve new posts and comments'),
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
              subtitle: const Text('Set the sensitivity level for content moderation'),
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
  
  void _saveSettings() {
    // Here you would implement the actual saving logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  void _showConfirmDialog(String title, String message, VoidCallback onConfirm) {
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
            child: const Text('Confirm'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
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