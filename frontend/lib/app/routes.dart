import 'package:flutter/material.dart';
import 'package:frontend/core/presentation/guards/auth_guard.dart';
import 'package:frontend/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:frontend/features/admin/presentation/pages/admin_settings_page.dart';
import 'package:frontend/features/admin/presentation/pages/content_moderation_page.dart';
import 'package:frontend/features/admin/presentation/widgets/user_management_screen.dart';
import 'package:frontend/features/auth/screens/email_verification_screen.dart';
import 'package:frontend/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:frontend/features/review/domain/entities/product.dart';
import 'package:frontend/features/review/presentation/pages/review_screen.dart';
import 'package:frontend/features/settings/presentation/pages/settings_screen.dart';
import 'package:frontend/presentation/screens/home_screen.dart';
import 'package:frontend/features/auth/screens/login_screen.dart';
import 'package:frontend/presentation/screens/manual_entry_screen.dart';
import 'package:frontend/presentation/screens/navigation_page.dart';
import 'package:frontend/features/auth/screens/reset_password_screen.dart';
import 'package:frontend/presentation/screens/product_details_screen.dart';
import 'package:frontend/presentation/screens/scanner_screen.dart';
import 'package:frontend/features/auth/screens/signup_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/features/auth/screens/auth_callback_screen.dart';
import 'package:frontend/features/auth/screens/biometric_test_screen.dart';
import 'package:frontend/features/admin/presentation/pages/reported_content_page.dart';
import 'package:frontend/features/admin/presentation/pages/notification_compose_page.dart';
import 'package:frontend/features/admin/presentation/pages/notification_history_page.dart';
import 'package:frontend/features/admin/presentation/pages/audit_log_page.dart';
import 'package:frontend/features/user/presentation/pages/user_activity_log_page.dart';
import 'package:frontend/features/admin/presentation/screens/realtime_log_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    // Protected routes that require authentication
    GoRoute(
      path: '/',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          child: AuthGuard(child: const BottomNavigationPage()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    // Public auth routes
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    // Protected routes
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          child: AuthGuard(child: const HomeScreen()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          child: AuthGuard(child: const SettingsScreen()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      path: '/user/activity-log',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          child: AuthGuard(child: const UserActivityLogPage()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      path: '/productDetails',
      pageBuilder: (context, state) {
        final product = state.extra as Product?;
        return CustomTransitionPage(
          child: AuthGuard(child: ProductDetailsPage(product: product)),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      path: '/scanner',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          child: AuthGuard(child: const ScannerPage()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      path: '/reviews',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          child: AuthGuard(child: const ReviewScreen()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    // Password reset routes (public)
    GoRoute(
      path: '/reset-password',
      builder: (context, state) {
        // Extract the token parameter for legacy reset flow
        final token = state.uri.queryParameters['token'];

        // Extract Keycloak reset parameters
        final resetKey = state.uri.queryParameters['key'];
        final code = state.uri.queryParameters['code'];

        return ResetPasswordScreen(
          token: token,
          resetKey: resetKey,
          code: code,
        );
      },
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ResetPasswordScreen(),
    ),
    // Auth callback for social login (public)
    GoRoute(
      path: '/auth/callback',
      builder: (context, state) {
        // Extract tokens from URL parameters
        final accessToken = state.uri.queryParameters['access_token'];
        final refreshToken = state.uri.queryParameters['refresh_token'];
        final expiresIn = state.uri.queryParameters['expires_in'];
        final error = state.uri.queryParameters['error'];

        // Pass tokens to the callback screen
        return AuthCallbackScreen(
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiresIn: expiresIn,
          error: error,
        );
      },
    ),
    // Email verification (public)
    GoRoute(
      path: '/verify-email',
      builder: (context, state) {
        // Extract verification parameters from URL
        final verificationKey = state.uri.queryParameters['key'];
        final code = state.uri.queryParameters['code'];
        final success = state.uri.queryParameters['success'];
        final error = state.uri.queryParameters['error'];

        return EmailVerificationScreen(
          verificationKey: verificationKey,
          code: code,
          success: success,
          error: error,
        );
      },
    ),
    // Admin routes - use AdminGuard
    GoRoute(
      path: '/admin',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          child: AdminGuard(child: const AdminDashboardPage()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      path: '/admin/content',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          child: AdminGuard(child: const ContentModerationPage()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      path: '/admin/posts/pending',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          child: AdminGuard(child: const ContentModerationPage()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      path: '/admin/comments/pending',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          child: AdminGuard(child: const ContentModerationPage()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      path: '/admin/users',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          child: AdminGuard(child: const UserManagementScreen()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      path: '/admin/flags',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          child: AdminGuard(child: const ReportedContentPage()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      path: '/admin/settings',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          child: AdminGuard(child: const AdminSettingsPage()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      path: '/admin/logs',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          child: AdminGuard(child: const ContentModerationPage()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    // Additional protected routes
    GoRoute(
      path: '/manualEntry',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          child: AuthGuard(child: const ManualEntryPage()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    // Biometric test route
    GoRoute(
      path: '/biometric-test',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          child: AuthGuard(child: const BiometricTestScreen()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(path: '/scanner', builder: (context, state) => const ScannerPage()),
    GoRoute(
      path: '/admin/notifications',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          child: AdminGuard(child: const NotificationComposePage()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      path: '/admin/notifications/history',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          child: AdminGuard(child: const NotificationHistoryPage()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      path: '/admin/audit-log',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          child: AdminGuard(child: const AuditLogPage()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    // New route for Real-time Logs
    GoRoute(
      path: '/admin/realtime-logs',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          child: AdminGuard(child: const RealtimeLogScreen()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
  ],
  debugLogDiagnostics: true,
);
