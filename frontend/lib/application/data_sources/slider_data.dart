import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/domain/entities/slider_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/app/providers/auth_provider.dart';

class Sliders extends ConsumerWidget {
  List<SliderModel> sliders = [];

  Future<void> getSliders(WidgetRef ref) async {
    String? baseUrl = dotenv.env['django_api'];
    if (baseUrl == null) {
      print('Error: django_api not set in .env');
      return;
    }
    String url = '$baseUrl/api/news/?tags=top_headlines';
    try {
      String? token = ref.read(authProvider);
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

      sliders.clear();
      int page = 1;
      while (url != null) {
        print('Fetching page $page from: $url');
        var response = await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        print('Sliders API Response: Status ${response.statusCode}');
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
            // Relaxed validation to include articles with missing fields
            if (element['title'] != null) {
              SliderModel sliderModel = SliderModel(
                author: element['author'] ?? 'Unknown',
                title: element['title'] ?? 'Untitled',
                description:
                    element['content'] ??
                    element['description'] ??
                    'No description',
                url: element['url'] ?? '',
                urlToImage:
                    element['image_url']?.isNotEmpty == true
                        ? element['image_url']
                        : '',
                content: element['content'] ?? 'No content',
              );
              sliders.add(sliderModel);
              print('Added article: ${sliderModel.title}');
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
          print('Failed to load sliders: ${response.statusCode}');
          throw Exception('Failed to load sliders: ${response.statusCode}');
        }
      }
      print('Fetched ${sliders.length} top headlines');
    } catch (e) {
      print('Error fetching sliders: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container();
  }
}
