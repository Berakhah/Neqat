import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/features/admin/domain/entities/dashboard_metrics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../domain/entities/admin_user.dart';

final adminApiServiceProvider = Provider<AdminApiService>((ref) {
  return AdminApiService();
});

class AdminApiService {
  final String baseUrl = 'http://localhost:8000/api/';
  final logger = Logger();
  final _storage = const FlutterSecureStorage();
  final _logger = Logger();
  final DioClient _dioClient;

  AdminApiService([DioClient? dioClient]) : _dioClient = dioClient ?? DioClient();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'access_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Posts API methods
  Future<List<dynamic>> fetchPosts({String? status, int page = 1}) async {
    final headers = await _getHeaders();
    final queryParams = {
      if (status != null) 'status': status,
      'page': page.toString(),
    };
    
    final uri = Uri.parse('${baseUrl}admin/posts/')
        .replace(queryParameters: queryParams);
    
    final response = await http.get(uri, headers: headers);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'] ?? [];
    } else {
      throw Exception('Failed to load posts: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> approvePost(String postId, {String? notes}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${baseUrl}admin/posts/$postId/approve/');
    
    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode({'notes': notes}),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to approve post: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> rejectPost(String postId, {required String notes}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${baseUrl}admin/posts/$postId/reject/');
    
    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode({'notes': notes}),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to reject post: ${response.statusCode}');
    }
  }

  // Comments API methods
  Future<List<dynamic>> fetchComments({String? status, int page = 1}) async {
    final headers = await _getHeaders();
    final queryParams = {
      if (status != null) 'status': status,
      'page': page.toString(),
    };
    
    final uri = Uri.parse('${baseUrl}admin/comments/')
        .replace(queryParameters: queryParams);
    
    final response = await http.get(uri, headers: headers);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'] ?? [];
    } else {
      throw Exception('Failed to load comments: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> approveComment(String commentId, {String? notes}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${baseUrl}admin/comments/$commentId/approve/');
    
    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode({'notes': notes}),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to approve comment: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> rejectComment(String commentId, {required String notes}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${baseUrl}admin/comments/$commentId/reject/');
    
    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode({'notes': notes}),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to reject comment: ${response.statusCode}');
    }
  }

  // Content Flags API methods
  Future<List<dynamic>> fetchContentFlags({bool? resolved, int page = 1}) async {
    final headers = await _getHeaders();
    final queryParams = {
      if (resolved != null) 'resolved': resolved.toString(),
      'page': page.toString(),
    };
    
    final uri = Uri.parse('${baseUrl}admin/content-flags/')
        .replace(queryParameters: queryParams);
    
    final response = await http.get(uri, headers: headers);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'] ?? [];
    } else {
      throw Exception('Failed to load content flags: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> resolveContentFlag(String flagId, {required String notes}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${baseUrl}admin/content-flags/$flagId/');
    
    final response = await http.patch(
      uri,
      headers: headers,
      body: json.encode({
        'resolved': true,
        'resolution_notes': notes,
      }),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to resolve content flag: ${response.statusCode}');
    }
  }

  // Dashboard data
  Future<DashboardMetrics> fetchDashboardData() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${baseUrl}admin/dashboard/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return DashboardMetrics.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to fetch dashboard data: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Failed to fetch dashboard data', error: e);
      throw Exception('Could not fetch dashboard data: $e');
    }
  }

  // Method for DashboardRepositoryImpl - renamed to align with repository usage
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${baseUrl}admin/dashboard/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch dashboard data: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Failed to fetch dashboard data', error: e);
      throw Exception('Could not fetch dashboard data: $e');
    }
  }

  Future<Map<String, dynamic>> getContentTrends({required String period}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${baseUrl}admin/dashboard/content-trends?period=$period'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch content trends: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Failed to fetch content trends', error: e);
      throw Exception('Could not fetch content trends: $e');
    }
  }

  Future<Map<String, dynamic>> getContentByCategory() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${baseUrl}admin/dashboard/content-categories'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch content by category: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Failed to fetch content by category', error: e);
      throw Exception('Could not fetch content by category: $e');
    }
  }

  Future<Map<String, dynamic>> getUserEngagementRates() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${baseUrl}admin/dashboard/user-engagement'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch user engagement rates: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Failed to fetch user engagement rates', error: e);
      throw Exception('Could not fetch user engagement rates: $e');
    }
  }

  Future<Map<String, dynamic>> getUserTrends({required String period}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${baseUrl}admin/dashboard/user-trends?period=$period'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch user trends: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Failed to fetch user trends', error: e);
      throw Exception('Could not fetch user trends: $e');
    }
  }

  Future<Map<String, dynamic>> getUsersByLocation() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${baseUrl}admin/dashboard/users-location'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch users by location: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Failed to fetch users by location', error: e);
      throw Exception('Could not fetch users by location: $e');
    }
  }

  // User management
  Future<List<AdminUser>> getUsers() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${baseUrl}admin/users/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        List<dynamic> usersData;
        
        // Check if the response is a paginated response (object with 'results')
        // or a direct list of users
        if (responseData is Map && responseData.containsKey('results')) {
          usersData = responseData['results'] as List<dynamic>;
        } else if (responseData is List) {
          usersData = responseData;
        } else {
          // Log the actual response for debugging
          _logger.d('Unexpected users response format: ${response.body}');
          usersData = [];
        }
        
        return usersData.map((user) => AdminUser.fromJson(user)).toList();
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Failed to get users', error: e);
      throw Exception('Could not load users: $e');
    }
  }

  Future<void> disableUser(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${baseUrl}admin/users/$userId/disable/'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to disable user: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Failed to disable user', error: e);
      throw Exception('Could not disable user: $e');
    }
  }

  Future<void> enableUser(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${baseUrl}admin/users/$userId/enable/'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to enable user: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Failed to enable user', error: e);
      throw Exception('Could not enable user: $e');
    }
  }

  Future<void> makeStaff(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${baseUrl}admin/users/$userId/make_staff/'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to make user staff: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Failed to make user staff', error: e);
      throw Exception('Could not make user staff: $e');
    }
  }

  Future<void> removeStaff(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${baseUrl}admin/users/$userId/remove_staff/'),
        headers: headers,
        body: json.encode({}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to remove staff status: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Failed to remove staff status', error: e);
      throw Exception('Could not remove staff status: $e');
    }
  }

  Future<void> resetPassword(String userId, String newPassword) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${baseUrl}admin/users/$userId/reset_password/'),
        headers: headers,
        body: json.encode({
          'new_password': newPassword,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to reset password: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Failed to reset password', error: e);
      throw Exception('Could not reset password: $e');
    }
  }

  Future<AdminUser> updateUser(
    String userId,
    String userName,
    String email,
    String? firstName,
    String? lastName,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('${baseUrl}admin/users/$userId/'),
        headers: headers,
        body: json.encode({
          'user_name': userName,
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AdminUser.fromJson(data);
      } else {
        throw Exception('Failed to update user: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Failed to update user', error: e);
      throw Exception('Could not update user: $e');
    }
  }

  Future<List<dynamic>> getUserPosts(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${baseUrl}admin/posts/?user_id=$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        
        // Check if the response is a paginated response (object with 'results')
        // or a direct list
        if (responseData is Map && responseData.containsKey('results')) {
          return responseData['results'] as List<dynamic>;
        } else if (responseData is List) {
          return responseData;
        } else {
          // Log the actual response for debugging
          _logger.d('Unexpected posts response format: ${response.body}');
          return [];
        }
      } else {
        throw Exception('Failed to get user posts: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Failed to get user posts', error: e);
      throw Exception('Could not get user posts: $e');
    }
  }

  Future<List<dynamic>> getUserComments(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${baseUrl}admin/comments/?user_id=$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        
        // Check if the response is a paginated response (object with 'results')
        // or a direct list
        if (responseData is Map && responseData.containsKey('results')) {
          return responseData['results'] as List<dynamic>;
        } else if (responseData is List) {
          return responseData;
        } else {
          // Log the actual response for debugging
          _logger.d('Unexpected comments response format: ${response.body}');
          return [];
        }
      } else {
        throw Exception('Failed to get user comments: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Failed to get user comments', error: e);
      throw Exception('Could not get user comments: $e');
    }
  }

  Future<List<AdminUser>> searchUsers({required String search, int page = 1}) async {
    try {
      final headers = await _getHeaders();
      final queryParams = {
        'page': page.toString(),
        'search': search,
      };
      
      final uri = Uri.parse('${baseUrl}admin/users/')
          .replace(queryParameters: queryParams);
      
      final response = await http.get(uri, headers: headers);
      
      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        List<dynamic> usersData;
        
        // Check if the response is a paginated response (object with 'results')
        // or a direct list of users
        if (responseData is Map && responseData.containsKey('results')) {
          usersData = responseData['results'] as List<dynamic>;
        } else if (responseData is List) {
          usersData = responseData;
        } else {
          // Log the actual response for debugging
          _logger.d('Unexpected users search response format: ${response.body}');
          usersData = [];
        }
        
        return usersData.map((user) => AdminUser.fromJson(user)).toList();
      } else {
        throw Exception('Failed to search users: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Failed to search users', error: e);
      throw Exception('Could not search users: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSystemLogs({int page = 1}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${baseUrl}admin/logs/?page=$page'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData is Map && responseData.containsKey('results')) {
          // Handle paginated response
          return List<Map<String, dynamic>>.from(responseData['results']);
        } else if (responseData is List) {
          // Handle direct list response
          return List<Map<String, dynamic>>.from(responseData);
        } else {
          _logger.d('Unexpected logs response format: ${response.body}');
          return [];
        }
      } else {
        throw Exception('Failed to load system logs: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Failed to get system logs', error: e);
      throw Exception('Could not load system logs: $e');
    }
  }
} 