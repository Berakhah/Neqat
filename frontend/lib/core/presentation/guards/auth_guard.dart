import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/app/providers/auth_provider.dart';
import 'package:frontend/app/providers/user_provider.dart';
import 'package:frontend/services/keycloak_service.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:logger/logger.dart';
import 'dart:convert';
import 'dart:ui';

/// A route guard that requires authentication
///
/// This guard will redirect unauthenticated users to the login page.
/// It also validates the token and attempts to refresh it if needed.
class AuthGuard extends ConsumerWidget {
  final Widget child;
  final bool requireAdmin;
  final List<String>? requiredRoles;
  final String? redirectTo;
  final Logger _logger = Logger();

  AuthGuard({
    super.key,
    required this.child,
    this.requireAdmin = false,
    this.requiredRoles,
    this.redirectTo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the auth state
    final authState = ref.watch(authProvider);
    final userState = ref.watch(userProvider);

    return FutureBuilder<bool>(
      future: _validateAuthentication(ref, context),
      builder: (context, snapshot) {
        // Show loading indicator while validating
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final isValid = snapshot.data ?? false;
        
        // Handle authentication failure
        if (!isValid) {
          // Don't navigate during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final destination = redirectTo ?? '/login';
            _logger.i('User not authenticated, redirecting to $destination');
            context.go(destination);
          });
          
          // Return empty container to avoid flicker
          return const SizedBox.shrink();
        }
        
        // If admin access is required, check for admin role
        if (requireAdmin && !userState.isAdmin) {
          // Don't navigate during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _logger.i('User is not an admin, redirecting to home');
            context.go('/');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You do not have admin access.')),
            );
          });
          
          // Return empty container to avoid flicker
          return const SizedBox.shrink();
        }
        
        // If specific roles are required, check for them
        if (requiredRoles != null && !userState.hasAnyRole(requiredRoles!)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _logger.i('User lacks required roles, redirecting to home');
            context.go('/');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You do not have permission to access this page.')),
            );
          });
          return const SizedBox.shrink();
        }
        
        // Authentication is valid, return the child
        return child;
      },
    );
  }

  /// Validates the user's authentication and refreshes token if needed
  Future<bool> _validateAuthentication(WidgetRef ref, BuildContext context) async {
    try {
      // Check if we have an initial auth state
      final authState = ref.read(authProvider);
      if (!authState.isAuthenticated || authState.token == null) {
        _logger.i('No authentication state');
        return false;
      }
      
      // Get KeycloakService
      final keycloakService = ref.read(authServiceProvider);
      
      // Check token validity
      final isTokenValid = await _isTokenValid(authState.token!);
      if (!isTokenValid) {
        _logger.i('Token is invalid, attempting refresh');
        
        try {
          // Attempt token refresh
          final refreshResult = await keycloakService.refreshAccessToken();
          
          // If refresh was successful
          if (refreshResult != null) {
            final newAccessToken = refreshResult['access'] as String?;
            if (newAccessToken != null) {
              // Update the auth state with new token
              ref.read(authProvider.notifier).setToken(newAccessToken);
              _logger.i('Token refreshed successfully');
              return true;
            }
          }
          
          _logger.w('Token refresh failed');
          // Clear the authentication state
          await ref.read(authProvider.notifier).clear();
          return false;
        } catch (e) {
          _logger.e('Token refresh error: $e');
          // Clear the authentication state
          await ref.read(authProvider.notifier).clear();
          return false;
        }
      }
      
      // Token is valid
      return true;
    } catch (e) {
      _logger.e('Authentication validation error: $e');
      // Clear the authentication state on error
      await ref.read(authProvider.notifier).clear();
      return false;
    }
  }
  
  /// Check if a token is valid by inspecting its payload
  Future<bool> _isTokenValid(String token) async {
    try {
      // Simple check if token has valid structure
      final parts = token.split('.');
      if (parts.length != 3) return false;
      
      // Decode the payload
      final normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> data = json.decode(payload);
      
      // Check expiration
      if (data.containsKey('exp')) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(data['exp'] * 1000);
        final now = DateTime.now();
        
        // Add 30-second buffer to prevent edge cases
        return expiry.isAfter(now.add(const Duration(seconds: 30)));
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
}

/// A route guard that requires admin privileges
///
/// This guard extends AuthGuard and additionally checks for admin role
class AdminGuard extends AuthGuard {
  AdminGuard({
    super.key,
    required super.child,
    super.redirectTo,
  }) : super(
    requireAdmin: true,
  );
} 