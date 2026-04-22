import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/domain/entities/search_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/app/providers/auth_provider.dart';

class ShowSearchNews extends ConsumerWidget {
  final List<ShowSearchModel> searches = [];

  ShowSearchNews({super.key});

  Future<void> getSearchNews({
    required String Search,
    required WidgetRef ref,
  }) async {
    String? baseUrl = dotenv.env['django_api'];
    if (baseUrl == null) {
      print('Error: django_api not set in .env');
      return;
    }
    String url = '$baseUrl/api/news/search/?search=$Search';
    try {
      String? token = ref.read(authTokenProvider);
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

      var response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print('Search API Response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        searches.clear();
        for (var element in jsonData['results']) {
          ShowSearchModel searchModel = ShowSearchModel(
            author: element['author'] ?? 'Unknown',
            title: element['title'] ?? 'Untitled',
            description: element['content'] ?? element['description'] ?? '',
            url: element['url'] ?? '',
            urlToImage: element['image_url'] ?? '',
            content: element['content'] ?? '',
          );
          searches.add(searchModel);
        }
      } else {
        throw Exception('Failed to search news: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching news: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container();
  }
}