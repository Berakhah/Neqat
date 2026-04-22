import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiClient {
  static final String baseUrl = '${dotenv.env['django_api']}/api/';

  /// Fetch Telegram messages, with optional IR model/method parameters.
  Future<List<Map<String, dynamic>>> fetchTelegramMessages({
    required String? token,
    String? query,
    String model = 'bm25',
    String method = 'translate',
    int topK = 30,
  }) async {
    // Build query‐string parameters
    final params = <String, String>{
      if (query != null && query.isNotEmpty) 'search': query,
      'model': model,
      'method': method,
      'top_k': '$topK',
    };

    final uri = Uri.parse('${baseUrl}telegram-messages/')
        .replace(queryParameters: params);

    final response = await http.get(
      uri,
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      // If your DRF viewset is paginated, it will return { results: [...] }
      final List raw = jsonData['results'] ?? jsonData;
      return List<Map<String, dynamic>>.from(raw);
    } else {
      throw Exception(
        'Failed to load Telegram messages: ${response.statusCode}',
      );
    }
  }
}

// Provider for ApiClient
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
