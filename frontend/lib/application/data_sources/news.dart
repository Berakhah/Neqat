import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/domain/entities/article_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/app/providers/auth_provider.dart';

class News extends ConsumerWidget {
  List<ArticleModel> news = [];

  Future<void> getNews(WidgetRef ref) async {
    String? baseUrl = dotenv.env['django_api'];
    if (baseUrl == null) {
      print('Error: django_api not set in .env');
      return;
    }
    String? url = '$baseUrl/api/news/?tags=world';
    try {
      String? token = ref.read(authProvider as ProviderListenable<String?>);
      if (token == null) {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString('access_token');
        if (token != null) {
          ref.read(authProvider.notifier).setToken(token);
        }
      }
      if (token == null) {
        print('Error: No access token found');
        return;
      }

      news.clear();
      while (url != null) {
        var response = await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        print('News API Response: ${response.statusCode} ${response.body}');

        if (response.statusCode == 200) {
          var jsonData = jsonDecode(response.body);
          for (var element in jsonData['results']) {
            ArticleModel articleModel = ArticleModel(
              author: element['author'] ?? 'Unknown',
              title: element['title'] ?? 'Untitled',
              description: element['content'] ?? element['description'] ?? '',
              url: element['url'] ?? '',
              urlToImage: element['image_url'] ?? '',
              content: element['content'] ?? '',
            );
            news.add(articleModel);
          }
          url = jsonData['next']; // Get next page URL or null
        } else {
          throw Exception('Failed to load news: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error fetching news: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container();
  }
}
