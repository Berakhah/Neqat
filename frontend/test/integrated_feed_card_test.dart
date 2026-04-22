import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/integrated_feed/widgets/integrated_feed_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/providers/user_provider.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Edit/Delete buttons enabled only for owner or admin', (WidgetTester tester) async {
    final post = {'id': 1, 'created_by': 'owner', 'title': 'Test', 'content': 'Test content'};
    // Owner
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProvider.overrideWithValue(UserState(
            isAuthenticated: true,
            isAdmin: false,
            userData: {'username': 'owner', 'realm_access': {'roles': ['user']}},
          )),
        ],
        child: MaterialApp(
          home: IntegratedFeedCard(item: post),
        ),
      ),
    );
    expect(tester.widget<IconButton>(find.byIcon(Icons.edit)).onPressed, isNotNull);
    expect(tester.widget<IconButton>(find.byIcon(Icons.delete)).onPressed, isNotNull);

    // Not owner, not admin
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProvider.overrideWithValue(UserState(
            isAuthenticated: true,
            isAdmin: false,
            userData: {'username': 'other', 'realm_access': {'roles': ['user']}},
          )),
        ],
        child: MaterialApp(
          home: IntegratedFeedCard(item: post),
        ),
      ),
    );
    expect(tester.widget<IconButton>(find.byIcon(Icons.edit)).onPressed, isNull);
    expect(tester.widget<IconButton>(find.byIcon(Icons.delete)).onPressed, isNull);

    // Admin
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProvider.overrideWithValue(UserState(
            isAuthenticated: true,
            isAdmin: true,
            userData: {'username': 'admin', 'realm_access': {'roles': ['admin']}},
          )),
        ],
        child: MaterialApp(
          home: IntegratedFeedCard(item: post),
        ),
      ),
    );
    expect(tester.widget<IconButton>(find.byIcon(Icons.edit)).onPressed, isNotNull);
    expect(tester.widget<IconButton>(find.byIcon(Icons.delete)).onPressed, isNotNull);
  });
} 