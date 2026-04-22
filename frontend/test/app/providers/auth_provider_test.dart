import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/providers/auth_provider.dart';

void main() {
  group('AuthNotifier', () {
    test('initial state should be null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final currentState = container.read(authProvider);
      expect(currentState, isNull);
    });

    test('setToken should update state with token', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(authProvider.notifier).setToken('test_token');
      final currentState = container.read(authProvider);
      
      expect(currentState, equals('test_token'));
    });

    test('clearToken should set state to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // First set a token
      container.read(authProvider.notifier).setToken('test_token');
      expect(container.read(authProvider), equals('test_token'));

      // Then clear it
      container.read(authProvider.notifier).clearToken();
      expect(container.read(authProvider), isNull);
    });

    test('state should be immutable', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Set initial token
      container.read(authProvider.notifier).setToken('initial_token');
      final firstState = container.read(authProvider);

      // Set new token
      container.read(authProvider.notifier).setToken('new_token');
      final secondState = container.read(authProvider);

      // Verify states are different
      expect(firstState, isNot(equals(secondState)));
      expect(firstState, equals('initial_token'));
      expect(secondState, equals('new_token'));
    });
  });
} 