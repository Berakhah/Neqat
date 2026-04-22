import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/features/auth/data/datasources/auth_api_service.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'dart:convert';

@GenerateMocks([http.Client, FlutterSecureStorage])
import 'auth_api_service_test.mocks.dart';

void main() {
  late AuthApiService authApiService;
  late MockClient mockClient;
  late MockFlutterSecureStorage mockSecureStorage;

  setUp(() {
    mockClient = MockClient();
    mockSecureStorage = MockFlutterSecureStorage();
    authApiService = AuthApiService(
      client: mockClient,
      secureStorage: mockSecureStorage,
    );
  });

  group('AuthApiService', () {
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

        when(mockClient.post(
          Uri.parse(ApiConstants.login),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          json.encode(mockResponse),
          200,
        ));

        when(mockSecureStorage.write(
          key: anyNamed('key'),
          value: anyNamed('value'),
        )).thenAnswer((_) async => null);

        // Act
        final result = await authApiService.login(
          email: email,
          password: password,
        );

        // Assert
        expect(result, equals(mockResponse));
        verify(mockSecureStorage.write(
          key: 'access_token',
          value: 'mock_access_token',
        )).called(1);
        verify(mockSecureStorage.write(
          key: 'refresh_token',
          value: 'mock_refresh_token',
        )).called(1);
      });

      test('should return error when login fails', () async {
        // Arrange
        final email = 'test@example.com';
        final password = 'wrong_password';
        final mockResponse = {
          'error': true,
          'message': 'Invalid credentials'
        };

        when(mockClient.post(
          Uri.parse(ApiConstants.login),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          json.encode(mockResponse),
          401,
        ));

        // Act
        final result = await authApiService.login(
          email: email,
          password: password,
        );

        // Assert
        expect(result['error'], isTrue);
        expect(result['message'], contains('Invalid credentials'));
        verifyNever(mockSecureStorage.write(
          key: any,
          value: any,
        ));
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

        when(mockClient.post(
          Uri.parse(ApiConstants.register),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          json.encode(mockResponse),
          201,
        ));

        // Act
        final result = await authApiService.register(
          username: username,
          email: email,
          password: password,
        );

        // Assert
        expect(result, equals(mockResponse));
        verify(mockSecureStorage.write(
          key: 'access_token',
          value: 'mock_access_token',
        )).called(1);
      });

      test('should return error when registration fails', () async {
        // Arrange
        final username = 'testuser';
        final email = 'existing@example.com';
        final password = 'password123';
        final mockResponse = {
          'error': true,
          'message': 'Email already exists'
        };

        when(mockClient.post(
          Uri.parse(ApiConstants.register),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          json.encode(mockResponse),
          400,
        ));

        // Act
        final result = await authApiService.register(
          username: username,
          email: email,
          password: password,
        );

        // Assert
        expect(result['error'], isTrue);
        expect(result['message'], contains('Email already exists'));
      });
    });

    group('logout', () {
      test('should clear tokens when logout is successful', () async {
        // Arrange
        when(mockSecureStorage.delete(key: any))
            .thenAnswer((_) async => null);

        // Act
        await authApiService.logout();

        // Assert
        verify(mockSecureStorage.delete(key: 'access_token')).called(1);
        verify(mockSecureStorage.delete(key: 'refresh_token')).called(1);
      });
    });

    group('getCurrentUser', () {
      test('should return user data when token is valid', () async {
        // Arrange
        final mockUserData = {
          'id': 1,
          'email': 'test@example.com',
          'name': 'Test User'
        };

        when(mockSecureStorage.read(key: 'access_token'))
            .thenAnswer((_) async => 'mock_token');

        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          json.encode(mockUserData),
          200,
        ));

        // Act
        final result = await authApiService.getCurrentUser();

        // Assert
        expect(result, equals(mockUserData));
      });

      test('should return null when getting current user fails', () async {
        // Arrange
        when(mockSecureStorage.read(key: 'access_token'))
            .thenAnswer((_) async => null);

        // Act
        final result = await authApiService.getCurrentUser();

        // Assert
        expect(result, isNull);
      });
    });
  });
} 