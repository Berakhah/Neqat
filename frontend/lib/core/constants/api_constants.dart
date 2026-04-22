import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  // Set this to true when testing on an Android emulator or simulator
  static const bool useEmulator = false;

  // Host addresses for different environments
  // For Android emulator, use 10.0.2.2 instead of localhost
  static const String emulatorHost = '10.0.2.2:8000';

  // For physical devices on the same network as the development server
  // Get the host from environment variable
  static String get devServerHost {
    final apiUrl = dotenv.env['django_api'] ?? 'http://192.168.180.99:8000';
    // Remove http:// if present and any trailing slashes
    return apiUrl
        .replaceAll('http://', '')
        .replaceAll('https://', '')
        .replaceAll('/', '');
  }

  // For localhost testing (web or direct connection)
  static const String localhostHost = 'localhost:8000';

  // Base URL for Django backend
  static String get baseUrl {
    // For web, use localhost
    if (kIsWeb) {
      return 'http://$localhostHost';
    }
    // For physical devices
    if (!useEmulator) {
      return 'http://$devServerHost';
    }
    // For Android emulator
    if (Platform.isAndroid) {
      return 'http://$emulatorHost';
    }
    // Default for iOS simulator or others
    return 'http://$localhostHost';
  }

  // Authentication Endpoints - Make sure these match exactly with Django URLs
  static String get login => '$baseUrl/api/login/';
  static String get register => '$baseUrl/api/register/';
  static String get forgotPassword => '$baseUrl/api/forgot-password/';
  static String get resetPassword => '$baseUrl/api/reset-password/';
  static String get socialLogin =>
      '$baseUrl/api/login/'; // Generic endpoint, provider specified in body
  static String get googleLogin => '$baseUrl/api/login/google/';
  static String get facebookLogin => '$baseUrl/api/login/facebook/';
  static String get appleLogin => '$baseUrl/api/login/apple/';
  static String get currentUser => '$baseUrl/api/user/';
  static String get logout => '$baseUrl/api/logout/';
  static String get userProfile => '$baseUrl/api/user/profile/';
  static String get tokenRefresh => '$baseUrl/api/token/refresh/';

  // Content endpoints
  static String get posts => '$baseUrl/api/posts/';
  static String get comments => '$baseUrl/api/comments/';
  static String get contentFlags => '$baseUrl/api/content-flags/';

  // Admin endpoints
  static String get adminDashboard => '$baseUrl/api/admin/dashboard/';
  static String get adminUsers => '$baseUrl/api/admin/users/';
  static String get adminPosts => '$baseUrl/api/admin/posts/';
  static String get adminComments => '$baseUrl/api/admin/comments/';
  static String get adminContentFlags => '$baseUrl/api/admin/content-flags/';

  // Social Auth Providers (match these with backend)
  static const String providerGoogle = 'google';
  static const String providerFacebook = 'facebook';
  static const String providerApple = 'apple';

  // HTTP Headers
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
