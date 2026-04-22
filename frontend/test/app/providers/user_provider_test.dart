import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:frontend/app/providers/user_provider.dart';
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';

@GenerateMocks([AuthRepository])
import 'user_provider_test.mocks.dart';

void main() {
  late ProviderContainer container;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
      ],
    );
    addTearDown(container.dispose);
  });

  group('UserNotifier', () {
    test('initial state should have default values', () {
      final state = container.read(userProvider);
      
      expect(state.isAuthenticated, isFalse);
      expect(state.isAdmin, isFalse);
      expect(state.userData, isNull);
    });

    test('setUserData should update state correctly', () {
      final mockUserData = {
        'id': 1,
        'name': 'Test User',
        'email': 'test@example.com',
        'is_superuser': true
      };

      container.read(userProvider.notifier).setUserData(mockUserData);
      final state = container.read(userProvider);

      expect(state.isAuthenticated, isTrue);
      expect(state.isAdmin, isTrue);
      expect(state.userData, equals(mockUserData));
    });

    test('clearUserData should reset state to defaults', () {
      // First set some data
      final mockUserData = {
        'id': 1,
        'name': 'Test User',
        'email': 'test@example.com',
        'is_superuser': true
      };
      container.read(userProvider.notifier).setUserData(mockUserData);

      // Then clear it
      container.read(userProvider.notifier).clearUserData();
      final state = container.read(userProvider);

      expect(state.isAuthenticated, isFalse);
      expect(state.isAdmin, isFalse);
      expect(state.userData, isNull);
    });

    test('should initialize with authenticated user data', () async {
      final mockUserData = {
        'id': 1,
        'name': 'Test User',
        'email': 'test@example.com',
        'is_superuser': true
      };

      when(mockAuthRepository.isAuthenticated())
          .thenAnswer((_) async => true);
      when(mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => mockUserData);

      // Create a new container to trigger initialization
      final newContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      );
      addTearDown(newContainer.dispose);

      // Wait for async operations to complete
      await Future.delayed(Duration.zero);

      final state = newContainer.read(userProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.isAdmin, isTrue);
      expect(state.userData, equals(mockUserData));
    });

    test('should handle non-authenticated state during initialization', () async {
      when(mockAuthRepository.isAuthenticated())
          .thenAnswer((_) async => false);

      // Create a new container to trigger initialization
      final newContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      );
      addTearDown(newContainer.dispose);

      // Wait for async operations to complete
      await Future.delayed(Duration.zero);

      final state = newContainer.read(userProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.isAdmin, isFalse);
      expect(state.userData, isNull);
    });

    test('copyWith should update only specified fields', () {
      final initialUserData = {
        'id': 1,
        'name': 'Test User',
        'email': 'test@example.com'
      };

      // Set initial state
      container.read(userProvider.notifier).setUserData(initialUserData);
      final initialState = container.read(userProvider);

      // Create new state with copyWith
      final newState = initialState.copyWith(
        isAdmin: true,
      );

      // Verify only isAdmin was updated
      expect(newState.isAuthenticated, equals(initialState.isAuthenticated));
      expect(newState.isAdmin, isTrue);
      expect(newState.userData, equals(initialState.userData));
    });
  });
} 