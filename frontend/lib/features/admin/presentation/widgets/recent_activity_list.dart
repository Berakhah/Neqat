import 'package:flutter/material.dart';

class RecentActivityList extends StatelessWidget {
  final List<Map<String, dynamic>> activities;

  const RecentActivityList({
    super.key,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const Center(
        child: Text('No recent activities'),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final activity = activities[index];
        final timestamp = activity['timestamp'] ?? '';
        
        IconData icon;
        Color iconColor;
        
        switch (activity['action']) {
          case 'LOGIN':
            icon = Icons.login;
            iconColor = Colors.green;
            break;
          case 'LOGOUT':
            icon = Icons.logout;
            iconColor = Colors.orange;
            break;
          case 'REGISTER':
            icon = Icons.person_add;
            iconColor = Colors.blue;
            break;
          case 'ADMIN_ACTION':
            icon = Icons.admin_panel_settings;
            iconColor = Colors.purple;
            break;
          case 'SECURITY':
            icon = Icons.security;
            iconColor = Colors.red;
            break;
          default:
            icon = Icons.info;
            iconColor = Colors.grey;
        }
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: iconColor.withOpacity(0.2),
            child: Icon(
              icon,
              color: iconColor,
            ),
          ),
          title: Text(activity['details'] ?? 'Unknown activity'),
          subtitle: Text(
            '${activity['user_name'] ?? 'System'} • $timestamp',
          ),
          trailing: activity['action'] == 'SECURITY' 
              ? const Icon(Icons.warning, color: Colors.red)
              : null,
          onTap: () {
            // Could navigate to a detailed view of the activity
          },
        );
      },
    );
  }
} 