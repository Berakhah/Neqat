import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/app/providers/auth_provider.dart';
import 'package:frontend/app/providers/user_provider.dart';
import 'package:frontend/services/keycloak_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

class AuthCallbackScreen extends ConsumerStatefulWidget {
  final String? accessToken;
  final String? refreshToken;
  final String? expiresIn;
  final String? error;

  const AuthCallbackScreen({
    super.key,
    this.accessToken,
    this.refreshToken,
    this.expiresIn,
    this.error,
  });

  @override
  ConsumerState<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends ConsumerState<AuthCallbackScreen> {
  final _logger = Logger();
  bool _isProcessing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _processCallback();
  }

  Future<void> _processCallback() async {
    try {
      if (widget.error != null) {
        setState(() {
          _errorMessage = 'Authentication failed: ${widget.error}';
          _isProcessing = false;
        });
        return;
      }

      if (widget.accessToken == null || widget.refreshToken == null) {
        setState(() {
          _errorMessage = 'Authentication failed: Missing tokens';
          _isProcessing = false;
        });
        return;
      }

      // Update auth state using finishSocialLogin
      final expiresIn = int.tryParse(widget.expiresIn ?? '300') ?? 300;
      await ref.read(authProvider.notifier).finishSocialLogin(
        widget.accessToken!,
        widget.refreshToken!,
        expiresIn: expiresIn,
      );

      // Get user info from the updated auth state
      final userInfo = ref.read(authProvider).user;

      // Navigate to home page
      if (mounted) {
        final isAdmin = userInfo != null && userInfo.containsKey('realm_access') && 
          (userInfo['realm_access'] as Map).containsKey('roles') &&
          ((userInfo['realm_access']['roles'] as List).contains('admin'));
        if (isAdmin) {
          context.go('/admin');
        } else {
          context.go('/');
        }
      }
    } catch (e) {
      _logger.e('Error processing OAuth callback', error: e);
      setState(() {
        _errorMessage = 'Error processing authentication: $e';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isProcessing
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Completing authentication, please wait...'),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Return to Login'),
                  ),
                ],
              ),
      ),
    );
  }
} 