import 'package:flutter/material.dart';
import 'package:frontend/features/admin/domain/entities/admin_user.dart';

class UserActionDialog extends StatelessWidget {
  final AdminUser user;
  final String title;
  final String message;
  final String confirmText;
  final VoidCallback onConfirm;
  final Color? confirmColor;
  
  const UserActionDialog({
    super.key,
    required this.user,
    required this.title,
    required this.message,
    required this.confirmText,
    required this.onConfirm,
    this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            onConfirm();
            Navigator.of(context).pop();
          },
          style: confirmColor != null
              ? TextButton.styleFrom(foregroundColor: confirmColor)
              : null,
          child: Text(confirmText),
        ),
      ],
    );
  }
  
  // Factory constructor for different action types
  factory UserActionDialog.deactivate(
    AdminUser user, {
    required VoidCallback onConfirm,
  }) {
    return UserActionDialog(
      user: user,
      title: 'Deactivate User',
      message: 'Are you sure you want to deactivate ${user.username}? They will no longer be able to log in.',
      confirmText: 'Deactivate',
      onConfirm: onConfirm,
      confirmColor: Colors.red,
    );
  }
  
  factory UserActionDialog.activate(
    AdminUser user, {
    required VoidCallback onConfirm,
  }) {
    return UserActionDialog(
      user: user,
      title: 'Activate User',
      message: 'Are you sure you want to activate ${user.username}?',
      confirmText: 'Activate',
      onConfirm: onConfirm,
      confirmColor: Colors.green,
    );
  }
  
  factory UserActionDialog.resetPassword(
    AdminUser user, {
    required VoidCallback onConfirm,
  }) {
    return UserActionDialog(
      user: user,
      title: 'Reset Password',
      message: 'Send a password reset link to ${user.email}?',
      confirmText: 'Send Link',
      onConfirm: onConfirm,
    );
  }
  
  factory UserActionDialog.delete(
    AdminUser user, {
    required VoidCallback onConfirm,
  }) {
    return UserActionDialog(
      user: user,
      title: 'Delete User',
      message: 'Are you sure you want to permanently delete ${user.username}? This action cannot be undone.',
      confirmText: 'Delete',
      onConfirm: onConfirm,
      confirmColor: Colors.red,
    );
  }
} 