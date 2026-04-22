import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../models/tag_model.dart';
import '../models/user_preference_model.dart';
import '../models/preference_update.dart';
import '../models/content_interaction.dart';

class PreferencesApiService {
  final String baseUrl = 'https://localhost:8000/api/';
  final _storage = const FlutterSecureStorage();
  final _logger = Logger();

  // Helper method to get headers with auth token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'access_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get all available tags
  Future<List<TagModel>> getTags() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${baseUrl}tags/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData.containsKey('results')) {
          final List<dynamic> results = responseData['results'];
          return results.map((json) => TagModel.fromJson(json)).toList();
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load tags: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Failed to get tags', error: e);
      throw Exception('Could not load tags: $e');
    }
  }

  // Get user preferences
  Future<List<UserPreferenceModel>> getUserPreferences() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${baseUrl}preferences/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => UserPreferenceModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load preferences: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Failed to get preferences', error: e);
      throw Exception('Could not load preferences: $e');
    }
  }

  // Update preferences
  Future<List<Map<String, dynamic>>> updatePreferences(List<PreferenceUpdate> updates) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${baseUrl}preferences/update_preferences/'),
        headers: headers,
        body: json.encode(updates.map((update) => update.toJson()).toList()),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to update preferences: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Failed to update preferences', error: e);
      throw Exception('Could not update preferences: $e');
    }
  }
  
  // Record content interactions
  Future<void> recordContentInteraction(ContentInteraction interaction) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${baseUrl}interactions/'),
        headers: headers,
        body: json.encode(interaction.toJson()),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to record interaction: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Failed to record content interaction', error: e);
      // Just log the error but don't rethrow - we don't want to disturb the user experience
    }
  }
  
  // Batch record multiple content interactions
  Future<void> batchRecordInteractions(List<ContentInteraction> interactions) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${baseUrl}interactions/batch_record/'),
        headers: headers,
        body: json.encode(interactions.map((interaction) => interaction.toJson()).toList()),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to record interactions: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Failed to batch record content interactions', error: e);
      // Just log the error but don't rethrow - we don't want to disturb the user experience
    }
  }
  
  // Get personalized news
  Future<List<dynamic>> getPersonalizedNews() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${baseUrl}news/personalized/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load personalized news: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Failed to get personalized news', error: e);
      throw Exception('Could not load personalized news: $e');
    }
  }
} 