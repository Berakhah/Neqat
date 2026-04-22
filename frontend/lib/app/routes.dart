import 'package:flutter/material.dart';
import 'package:frontend/app/providers/user_provider.dart';
import 'package:frontend/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:frontend/features/admin/presentation/pages/admin_settings_page.dart';
import 'package:frontend/features/admin/presentation/pages/content_moderation_page.dart';
import 'package:frontend/features/admin/presentation/widgets/user_management_screen.dart';
import 'package:frontend/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:frontend/features/review/domain/entities/product.dart';
import 'package:frontend/features/review/presentation/pages/review_screen.dart';
import 'package:frontend/features/settings/presentation/pages/profile_screen.dart';
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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/settings/presentation/pages/settings_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const BottomNavigationPage(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),

    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),

    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/productDetails',
      builder: (context, state) {
        final product = state.extra as Product?;
        return ProductDetailsPage(product: product);
      },
    ),
    GoRoute(path: '/scanner', builder: (context, state) => const ScannerPage()),
    GoRoute(
      path: '/reviews',
      builder: (context, state) => const ReviewScreen(),
    ),
    GoRoute(
      path: '/resetpassword',
      builder: (context, state) => const ResetPasswordScreen(),
    ),
    GoRoute(
      path: '/forgotpassword',
      builder: (context, state) => const ResetPasswordScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return Consumer(
          builder: (context, ref, _) {
            final userState = ref.watch(userProvider);
            if (!userState.isAuthenticated || !userState.isAdmin) {
              Future.microtask(() => context.go('/login'));
              return const SizedBox();
            }
            return child;
          },
        );
      },
      routes: [
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboardPage(),
        ),
        GoRoute(
          path: '/admin/content',
          builder: (context, state) => const ContentModerationPage(),
        ),
        GoRoute(
          path: '/admin/posts/pending',
          builder: (context, state) => const ContentModerationPage(),
        ),
        GoRoute(
          path: '/admin/comments/pending',
          builder: (context, state) => const ContentModerationPage(),
        ),
        GoRoute(
          path: '/admin/users',
          builder: (context, state) => const UserManagementScreen(),
        ),
        GoRoute(
          path: '/admin/flags',
          builder: (context, state) => const ContentModerationPage(),
        ),
        GoRoute(
          path: '/admin/settings',
          builder: (context, state) => const AdminSettingsPage(),
        ),
        GoRoute(
          path: '/admin/logs',
          builder: (context, state) => const ContentModerationPage(),
        ),
      ],
    ),
    GoRoute(
      path: '/manualEntry',
      builder: (context, state) => const ManualEntryPage(),
    ),
    GoRoute(path: '/scanner', builder: (context, state) => const ScannerPage()),
  ],
);
