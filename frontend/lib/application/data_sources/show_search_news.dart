import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/app/providers/auth_provider.dart';
import 'package:frontend/domain/entities/search_model.dart';

/// Handles fetching news and telegram counts + results
class ShowSearchNews {
  List<ShowSearchModel> searches = [];
  String? originalQuery;
  List<String>? stemmedQuery;
  int? newsCount;
  int? telegramCount;

  Future<void> getSearchNews({
    required String Search,
    required WidgetRef ref,
  }) async {
    final baseUrl = dotenv.env['django_api'];
    if (baseUrl == null) {
      print('Error: django_api not set in .env');
      return;
    }

    try {
      // — AUTH TOKEN —
      String? token = ref.read(authProvider);
      if (token == null) {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString('access_token');
        if (token != null) ref.read(authProvider.notifier).setToken(token);
      }
      if (token == null) {
        print('Error: No access token found');
        return;
      }

      // — FETCH NEWS (stems + count) —
      final newsUrl = Uri.parse('$baseUrl/api/news/?search=$Search');
      final newsResponse = await http.get(
        newsUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print(
        'News API Response: ${newsResponse.statusCode} ${newsResponse.body}',
      );
      searches.clear();
      if (newsResponse.statusCode == 200) {
        final jsonData = jsonDecode(newsResponse.body);
        originalQuery = jsonData['original_query'] as String?;
        stemmedQuery =
            (jsonData['stemmed_query'] as List<dynamic>?)?.cast<String>();
        newsCount = jsonData['count'] as int?;
        for (final element in jsonData['results']) {
          searches.add(
            ShowSearchModel(
              author: element['sender_id'] ?? element['author'] ?? 'Unknown',
              title: element['channel_name'] ?? element['title'] ?? 'Untitled',
              description: element['message'] ?? element['content'] ?? '',
              url: element['url'] ?? '',
              urlToImage: element['image_url'] ?? '',
              content: element['message'] ?? element['content'] ?? '',
              type: 'news',
            ),
          );
        }
      } else {
        print('Failed to search news: ${newsResponse.statusCode}');
      }

      // — FETCH TELEGRAM (metadata + messages) IN ONE SHOT —
      final tgUrl = Uri.parse(
        '$baseUrl/api/telegram-messages/'
        '?search=$Search'
        '&model=bm25'
        '&method=default'
        '&top_k=30',
      );
      final tgResponse = await http.get(
        tgUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print(
        'Telegram API Response: ${tgResponse.statusCode} ${tgResponse.body}',
      );
      if (tgResponse.statusCode == 200) {
        final tgJson = jsonDecode(tgResponse.body);

        // ** Override your query + stems with the Telegram endpoint’s English‐stemmed info **
        originalQuery = tgJson['original_query'] as String?;
        stemmedQuery =
            (tgJson['stemmed_query'] as List<dynamic>?)?.cast<String>();
        telegramCount = tgJson['count'] as int?;

        final messages = List<Map<String, dynamic>>.from(tgJson['results']);
        for (final msg in messages) {
          searches.add(
            ShowSearchModel(
              author: msg['sender_id'] ?? 'Unknown',
              title: msg['channel_name'] ?? 'Telegram Message',
              description: msg['message'] ?? '',
              url: '',
              urlToImage: msg['image_url'] ?? '',
              content: msg['message'] ?? '',
              type: 'telegram',
              channelName: msg['channel_name'] ?? '',
              senderId: msg['sender_id'] ?? 'unknown',
              date: msg['date'] ?? '',
            ),
          );
        }
      } else {
        print('Failed to fetch telegram messages: ${tgResponse.statusCode}');
      }

      // — SORT RESULTS (telegram first, then by date descending) —
      searches.sort((a, b) {
        if (a.type == 'telegram' && b.type != 'telegram') return -1;
        if (a.type != 'telegram' && b.type == 'telegram') return 1;
        final dateA = a.date != null ? DateTime.parse(a.date!) : DateTime.now();
        final dateB = b.date != null ? DateTime.parse(b.date!) : DateTime.now();
        return dateB.compareTo(dateA);
      });
    } catch (e) {
      print('Error searching news or Telegram messages: $e');
    }
  }
}
