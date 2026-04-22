import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/domain/entities/show_category_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/app/providers/auth_provider.dart';

class ShowCategoryNews {
  List<ShowCategoryModel> categories = [];

  Future<void> getCategoryNews(String category, WidgetRef ref) async {
    String? baseUrl = dotenv.env['django_api'];
    if (baseUrl == null) {
      print('Error: django_api not set in .env');
      return;
    }
    String url = '$baseUrl/api/news/?tags=${category.toLowerCase()}';
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

      categories.clear();
      int page = 1;
      while (url != null) {
        print('Fetching page $page for category $category from: $url');
        var response = await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        print('Category API Response: Status ${response.statusCode}');
        print('Response Body: ${response.body}');

        if (response.statusCode == 200) {
          var jsonData = jsonDecode(response.body);
          if (jsonData['results'] == null) {
            print('Error: No "results" field in API response');
            return;
          }
          print('Results count: ${jsonData['results'].length}');
          for (var element in jsonData['results']) {
            print('Processing article: ${element['title'] ?? 'No title'}');
            // Verify the article has the correct category tag
            bool hasCategoryTag =
                (element['tags'] as List<dynamic>?)?.any(
                  (tag) => tag['name'].toLowerCase() == category.toLowerCase(),
                ) ??
                false;
            print(
              'Tags: ${element['tags']?.map((t) => t['name']).toList() ?? []}',
            );
            if (!hasCategoryTag) {
              print('Skipped article: Missing $category tag');
              continue;
            }
            if (element['title'] != null) {
              ShowCategoryModel categoryModel = ShowCategoryModel(
                author: element['author']?.toString() ?? 'Unknown',
                title: element['title']?.toString() ?? 'Untitled',
                description:
                    element['content']?.toString() ??
                    element['description']?.toString() ??
                    'No description',
                url: element['url']?.toString() ?? '',
                urlToImage:
                    element['image_url']?.toString().isNotEmpty == true
                        ? element['image_url'].toString()
                        : '',
                content: element['content']?.toString() ?? 'No content',
              );
              categories.add(categoryModel);
              print('Added article: ${categoryModel.title}');
            } else {
              print('Skipped article: Missing title');
            }
          }
          url = jsonData['next'];
          page++;
        } else if (response.statusCode == 401) {
          print('Unauthorized: Invalid or expired token');
          throw Exception('Authentication failed: ${response.statusCode}');
        } else {
          print('Failed to load category news: ${response.statusCode}');
          throw Exception(
            'Failed to load category news: ${response.statusCode}',
          );
        }
      }
      print('Fetched ${categories.length} articles for category $category');
    } catch (e) {
      print('Error fetching category news: $e');
    }
  }
}