import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/settings/presentation/pages/settings_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/providers/user_provider.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Admin Panel is visible for admin users', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProvider.overrideWithValue(UserState(
            isAuthenticated: true,
            isAdmin: true,
            userData: {'username': 'admin', 'realm_access': {'roles': ['admin']}},
          )),
        ],
        child: MaterialApp(home: SettingsScreen()),
      ),
    );
    expect(find.text('Admin Panel'), findsOneWidget);
  });

  testWidgets('Admin Panel is not visible for non-admin users', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProvider.overrideWithValue(UserState(
            isAuthenticated: true,
            isAdmin: false,
            userData: {'username': 'user', 'realm_access': {'roles': ['user']}},
          )),
        ],
        child: MaterialApp(home: SettingsScreen()),
      ),
    );
    expect(find.text('Admin Panel'), findsNothing);
  });
} 