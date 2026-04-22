import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';

@GenerateMocks([AuthRepository])
import 'auth_repository_test.mocks.dart';

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  group('AuthRepository Tests', () {
    test('login should return user data when credentials are valid', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'password123';
      final expectedResponse = {
        'id': 1,
        'name': 'Test User',
        'email': email,
        'token': 'mock_token'
      };

      when(mockAuthRepository.login(
        email: email,
        password: password,
      )).thenAnswer((_) async => expectedResponse);

      // Act
      final result = await mockAuthRepository.login(
        email: email,
        password: password,
      );

      // Assert
      expect(result, equals(expectedResponse));
      verify(mockAuthRepository.login(
        email: email,
        password: password,
      )).called(1);
    });

    test('register should return user data when registration is successful', () async {
      // Arrange
      const username = 'testuser';
      const email = 'test@example.com';
      const password = 'password123';
      final expectedResponse = {
        'id': 1,
        'name': username,
        'email': email,
        'token': 'mock_token'
      };

      when(mockAuthRepository.register(
        username: username,
        email: email,
        password: password,
      )).thenAnswer((_) async => expectedResponse);

      // Act
      final result = await mockAuthRepository.register(
        username: username,
        email: email,
        password: password,
      );

      // Assert
      expect(result, equals(expectedResponse));
      verify(mockAuthRepository.register(
        username: username,
        email: email,
        password: password,
      )).called(1);
    });

    test('logout should return true when successful', () async {
      // Arrange
      when(mockAuthRepository.logout())
          .thenAnswer((_) async => true);

      // Act
      final result = await mockAuthRepository.logout();

      // Assert
      expect(result, isTrue);
      verify(mockAuthRepository.logout()).called(1);
    });

    test('getCurrentUser should return user data when user is logged in', () async {
      // Arrange
      final expectedUser = {
        'id': 1,
        'name': 'Test User',
        'email': 'test@example.com',
        'token': 'mock_token'
      };

      when(mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => expectedUser);

      // Act
      final result = await mockAuthRepository.getCurrentUser();

      // Assert
      expect(result, equals(expectedUser));
      verify(mockAuthRepository.getCurrentUser()).called(1);
    });

    test('isAuthenticated should return true when user is logged in', () async {
      // Arrange
      when(mockAuthRepository.isAuthenticated())
          .thenAnswer((_) async => true);

      // Act
      final result = await mockAuthRepository.isAuthenticated();

      // Assert
      expect(result, isTrue);
      verify(mockAuthRepository.isAuthenticated()).called(1);
    });
  });
} 