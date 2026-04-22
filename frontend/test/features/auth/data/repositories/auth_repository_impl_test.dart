import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:frontend/features/auth/data/datasources/auth_api_service.dart';
import 'package:frontend/features/auth/data/repositories/auth_repository_impl.dart';

@GenerateMocks([AuthApiService])
import 'auth_repository_impl_test.mocks.dart';

void main() {
  late AuthRepositoryImpl authRepository;
  late MockAuthApiService mockAuthApiService;

  setUp(() {
    mockAuthApiService = MockAuthApiService();
    authRepository = AuthRepositoryImpl(authApiService: mockAuthApiService);
  });

  group('AuthRepositoryImpl', () {
    group('login', () {
      test('should return user data when login is successful', () async {
        // Arrange
        final email = 'test@example.com';
        final password = 'password123';
        final mockResponse = {
          'access': 'mock_access_token',
          'refresh': 'mock_refresh_token',
          'user': {
            'id': 1,
            'email': email,
            'name': 'Test User'
          }
        };

        when(mockAuthApiService.login(
          email: email,
          password: password,
        )).thenAnswer((_) async => mockResponse);

        // Act
        final result = await authRepository.login(
          email: email,
          password: password,
        );

        // Assert
        expect(result, equals(mockResponse));
        verify(mockAuthApiService.login(
          email: email,
          password: password,
        )).called(1);
      });

      test('should return error when login fails', () async {
        // Arrange
        final email = 'test@example.com';
        final password = 'wrong_password';
        final mockError = {
          'error': true,
          'message': 'Invalid credentials'
        };

        when(mockAuthApiService.login(
          email: email,
          password: password,
        )).thenAnswer((_) async => mockError);

        // Act
        final result = await authRepository.login(
          email: email,
          password: password,
        );

        // Assert
        expect(result['error'], isTrue);
        expect(result['message'], equals('Invalid credentials'));
      });
    });

    group('register', () {
      test('should return user data when registration is successful', () async {
        // Arrange
        final username = 'testuser';
        final email = 'test@example.com';
        final password = 'password123';
        final mockResponse = {
          'access': 'mock_access_token',
          'refresh': 'mock_refresh_token',
          'user': {
            'id': 1,
            'email': email,
            'name': username
          }
        };

        when(mockAuthApiService.register(
          username: username,
          email: email,
          password: password,
        )).thenAnswer((_) async => mockResponse);

        // Act
        final result = await authRepository.register(
          username: username,
          email: email,
          password: password,
        );

        // Assert
        expect(result, equals(mockResponse));
        verify(mockAuthApiService.register(
          username: username,
          email: email,
          password: password,
        )).called(1);
      });
    });

    group('getCurrentUser', () {
      test('should return user data when user is authenticated', () async {
        // Arrange
        final mockUserData = {
          'id': 1,
          'email': 'test@example.com',
          'name': 'Test User'
        };

        when(mockAuthApiService.getCurrentUser())
            .thenAnswer((_) async => mockUserData);

        // Act
        final result = await authRepository.getCurrentUser();

        // Assert
        expect(result, equals(mockUserData));
        verify(mockAuthApiService.getCurrentUser()).called(1);
      });

      test('should return null when user is not authenticated', () async {
        // Arrange
        when(mockAuthApiService.getCurrentUser())
            .thenAnswer((_) async => null);

        // Act
        final result = await authRepository.getCurrentUser();

        // Assert
        expect(result, isNull);
        verify(mockAuthApiService.getCurrentUser()).called(1);
      });
    });

    group('isAuthenticated', () {
      test('should return true when user is authenticated', () async {
        // Arrange
        when(mockAuthApiService.isAuthenticated())
            .thenAnswer((_) async => true);

        // Act
        final result = await authRepository.isAuthenticated();

        // Assert
        expect(result, isTrue);
        verify(mockAuthApiService.isAuthenticated()).called(1);
      });

      test('should return false when user is not authenticated', () async {
        // Arrange
        when(mockAuthApiService.isAuthenticated())
            .thenAnswer((_) async => false);

        // Act
        final result = await authRepository.isAuthenticated();

        // Assert
        expect(result, isFalse);
        verify(mockAuthApiService.isAuthenticated()).called(1);
      });
    });

    group('logout', () {
      test('should return true when logout is successful', () async {
        // Arrange
        when(mockAuthApiService.logout())
            .thenAnswer((_) async => true);

        // Act
        final result = await authRepository.logout();

        // Assert
        expect(result, isTrue);
        verify(mockAuthApiService.logout()).called(1);
      });
    });
  });
} 