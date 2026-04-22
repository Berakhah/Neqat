import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

/// A session timeout handler that monitors user activity
/// and logs out after a period of inactivity
class SessionTimeoutHandler extends ConsumerStatefulWidget {
  final Widget child;
  final Duration timeout;
  final Duration warningDuration;
  
  const SessionTimeoutHandler({
    super.key,
    required this.child,
    this.timeout = const Duration(minutes: 30),
    this.warningDuration = const Duration(minutes: 1),
  });

  @override
  ConsumerState<SessionTimeoutHandler> createState() => _SessionTimeoutHandlerState();
}

class _SessionTimeoutHandlerState extends ConsumerState<SessionTimeoutHandler> with WidgetsBindingObserver {
  Timer? _timeoutTimer;
  Timer? _warningTimer;
  DateTime _lastActivity = DateTime.now();
  bool _showingWarning = false;
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resetTimers();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelTimers();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came to foreground - check if session timed out while in background
      _checkSessionValidity();
    } else if (state == AppLifecycleState.paused) {
      // App went to background - store last active timestamp
      _lastActivity = DateTime.now();
    }
  }

  /// Reset inactivity timers
  void _resetTimers() {
    // Cancel existing timers
    _cancelTimers();
    
    // Update last activity time
    _lastActivity = DateTime.now();
    
    // Get current auth state
    final authState = ref.read(authProvider);
    
    // Only set timers if authenticated
    if (authState.isAuthenticated) {
      // Set warning timer
      _warningTimer = Timer(widget.timeout - widget.warningDuration, _showWarning);
      
      // Set timeout timer
      _timeoutTimer = Timer(widget.timeout, _handleTimeout);
    }
  }

  /// Cancel all active timers
  void _cancelTimers() {
    _timeoutTimer?.cancel();
    _warningTimer?.cancel();
    _timeoutTimer = null;
    _warningTimer = null;
    
    // Clear any showing warning
    if (_showingWarning) {
      Navigator.of(context, rootNavigator: true).pop();
      _showingWarning = false;
    }
  }

  /// Show inactivity warning
  void _showWarning() {
    // Only show warning if still authenticated
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) return;
    
    _showingWarning = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session Timeout Warning'),
        content: Text('Your session will expire in ${widget.warningDuration.inSeconds} seconds due to inactivity.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showingWarning = false;
              _resetTimers();
            },
            child: const Text('Stay Logged In'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showingWarning = false;
              _handleTimeout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  /// Handle session timeout - logout user
  void _handleTimeout() async {
    // Check if still authenticated first
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) return;
    
    _logger.i('Session timed out after inactivity');
    
    // Logout and clear authentication
    await ref.read(authProvider.notifier).logout();
    
    // If still mounted, navigate to login
    if (mounted) {
      _showingWarning = false;
      context.go('/login');
      
      // Show timeout notification
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have been logged out due to inactivity'),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  /// Check if session timed out while app was in background
  void _checkSessionValidity() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastActivity);
    
    // If inactive for longer than timeout, immediately timeout
    if (elapsed >= widget.timeout) {
      _handleTimeout();
    } 
    // If inactive for longer than warning threshold, show warning
    else if (elapsed >= (widget.timeout - widget.warningDuration) && !_showingWarning) {
      _showWarning();
    } 
    // Otherwise, reset timers based on last activity
    else {
      _resetTimers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      // Reset timers on any user interaction
      onPointerDown: (_) => _resetTimers(),
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}

/// Provider for configurable session timeout settings
final sessionTimeoutSettingsProvider = StateProvider<Map<String, dynamic>>((ref) {
  return {
    'enabled': true,
    'timeoutMinutes': 30,
    'warningMinutes': 1,
  };
});

/// Wrap your app with this to enable session timeout handling
class SessionTimeoutWrapper extends ConsumerWidget {
  final Widget child;
  
  const SessionTimeoutWrapper({
    super.key,
    required this.child,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(sessionTimeoutSettingsProvider);
    
    // If session timeout is disabled in settings, just return the child
    if (settings['enabled'] != true) {
      return child;
    }
    
    return SessionTimeoutHandler(
      timeout: Duration(minutes: settings['timeoutMinutes'] ?? 30),
      warningDuration: Duration(minutes: settings['warningMinutes'] ?? 1),
      child: child,
    );
  }
} 