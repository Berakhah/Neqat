import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/providers/auth_provider.dart';
import 'package:frontend/domain/entities/article_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Provider to check if an article is bookmarked
final isBookmarkedProvider = FutureProvider.family<bool, String>((ref, newsId) async {
  String? accessToken = ref.read(authProvider);
  final prefs = await SharedPreferences.getInstance();

  // Refresh token logic
  Future<String?> _refreshToken() async {
    try {
      final refreshToken = prefs.getString('refresh_token');
      final authProviderType = prefs.getString('auth_provider') ?? 'neqat';
      if (refreshToken == null) return null;

      final response = await http.post(
        Uri.parse('${dotenv.env['django_api']}/api/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['access'];
        final newRefreshToken = data['refresh'];
        await prefs.setString('access_token', newAccessToken);
        await prefs.setString('refresh_token', newRefreshToken);
        await prefs.setString('auth_provider', authProviderType);
        ref.read(authProvider.notifier).setToken(newAccessToken);
        return newAccessToken;
      }
      developer.log('Token refresh failed: ${response.statusCode}');
      return null;
    } catch (e) {
      developer.log('Token refresh error: $e');
      return null;
    }
  }

  // Get access token
  if (accessToken == null) {
    accessToken = prefs.getString('access_token');
    if (accessToken == null) {
      accessToken = await _refreshToken();
      if (accessToken == null) {
        developer.log('No access token available');
        return false;
      }
    }
  }

  // Fetch backend news_id
  final newsResponse = await http.get(
    Uri.parse('${dotenv.env['django_api']}/api/news/?url=${Uri.encodeComponent(newsId)}'),
    headers: {'Authorization': 'Bearer $accessToken'},
  );

  String? backendNewsId;
  if (newsResponse.statusCode == 200) {
    final data = jsonDecode(newsResponse.body);
    if (data['results'] != null && data['results'].isNotEmpty) {
      backendNewsId = data['results'][0]['id'];
    }
  } else if (newsResponse.statusCode == 401) {
    accessToken = await _refreshToken();
    if (accessToken != null) {
      final retryResponse = await http.get(
        Uri.parse('${dotenv.env['django_api']}/api/news/?url=${Uri.encodeComponent(newsId)}'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (retryResponse.statusCode == 200) {
        final data = jsonDecode(retryResponse.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          backendNewsId = data['results'][0]['id'];
        }
      }
    }
  }

  if (backendNewsId == null) {
    developer.log('Failed to fetch backend news_id for URL: $newsId');
    return false;
  }

  // Check if bookmarked
  final bookmarkResponse = await http.get(
    Uri.parse(
      '${dotenv.env['django_api']}/api/interactions/?content_type=NEWS&content_id=$backendNewsId&interaction_type=BOOKMARK',
    ),
    headers: {'Authorization': 'Bearer $accessToken'},
  );

  if (bookmarkResponse.statusCode == 200) {
    final data = jsonDecode(bookmarkResponse.body);
    developer.log('Bookmark response: ${bookmarkResponse.statusCode} - ${bookmarkResponse.body}');
    if (data['results'] != null && data['results'] is List && (data['results'] as List).isNotEmpty) {
      return (data['results'] as List).any((result) => result['interaction_type'] == 'BOOKMARK');
    }
    return false;
  } else if (bookmarkResponse.statusCode == 401) {
    accessToken = await _refreshToken();
    if (accessToken != null) {
      final retryResponse = await http.get(
        Uri.parse(
          '${dotenv.env['django_api']}/api/interactions/?content_type=NEWS&content_id=$backendNewsId&interaction_type=BOOKMARK',
        ),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      developer.log('Bookmark retry response: ${retryResponse.statusCode} - ${retryResponse.body}');
      if (retryResponse.statusCode == 200) {
        final data = jsonDecode(retryResponse.body);
        if (data['results'] != null && data['results'] is List && (data['results'] as List).isNotEmpty) {
          return (data['results'] as List).any((result) => result['interaction_type'] == 'BOOKMARK');
        }
        return false;
      }
    }
  }

  developer.log('Bookmark check failed: ${bookmarkResponse.statusCode} - ${bookmarkResponse.body}');
  return false;
});

// Notifier to handle bookmark toggling
class BookmarkNotifier extends StateNotifier<bool> {
  BookmarkNotifier(this.ref, this.newsId, bool initialState) : super(initialState);

  final Ref ref;
  final String newsId;

  Future<void> toggleBookmark() async {
    String? accessToken = ref.read(authProvider);
    final prefs = await SharedPreferences.getInstance();

    // Refresh token logic
    Future<String?> _refreshToken() async {
      try {
        final refreshToken = prefs.getString('refresh_token');
        final authProviderType = prefs.getString('auth_provider') ?? 'neqat';
        if (refreshToken == null) return null;

        final response = await http.post(
          Uri.parse('${dotenv.env['django_api']}/api/token/refresh/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh': refreshToken}),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final newAccessToken = data['access'];
          final newRefreshToken = data['refresh'];
          await prefs.setString('access_token', newAccessToken);
          await prefs.setString('refresh_token', newRefreshToken);
          await prefs.setString('auth_provider', authProviderType);
          ref.read(authProvider.notifier).setToken(newAccessToken);
          return newAccessToken;
        }
        developer.log('Token refresh failed: ${response.statusCode}');
        return null;
      } catch (e) {
        developer.log('Token refresh error: $e');
        return null;
      }
    }

    // Get access token
    if (accessToken == null) {
      accessToken = prefs.getString('access_token');
      if (accessToken == null) {
        accessToken = await _refreshToken();
        if (accessToken == null) {
          developer.log('No access token available');
          return;
        }
      }
    }

    // Fetch backend news_id
    final newsResponse = await http.get(
      Uri.parse('${dotenv.env['django_api']}/api/news/?url=${Uri.encodeComponent(newsId)}'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    String? backendNewsId;
    if (newsResponse.statusCode == 200) {
      final data = jsonDecode(newsResponse.body);
      if (data['results'] != null && data['results'].isNotEmpty) {
        backendNewsId = data['results'][0]['id'];
      }
    } else if (newsResponse.statusCode == 401) {
      accessToken = await _refreshToken();
      if (accessToken != null) {
        final retryResponse = await http.get(
          Uri.parse('${dotenv.env['django_api']}/api/news/?url=${Uri.encodeComponent(newsId)}'),
          headers: {'Authorization': 'Bearer $accessToken'},
        );
        if (retryResponse.statusCode == 200) {
          final data = jsonDecode(retryResponse.body);
          if (data['results'] != null && data['results'].isNotEmpty) {
            backendNewsId = data['results'][0]['id'];
          }
        }
      }
    }

    if (backendNewsId == null) {
      developer.log('Failed to fetch backend news_id for URL: $newsId');
      return;
    }

    if (state) {
      // Remove bookmark (delete interaction)
      final deleteResponse = await http.delete(
        Uri.parse(
          '${dotenv.env['django_api']}/api/interactions/delete_interaction/?content_type=NEWS&content_id=$backendNewsId&interaction_type=BOOKMARK',
        ),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (deleteResponse.statusCode == 204) {
        state = false;
      } else if (deleteResponse.statusCode == 401) {
        accessToken = await _refreshToken();
        if (accessToken != null) {
          final retryResponse = await http.delete(
            Uri.parse(
              '${dotenv.env['django_api']}/api/interactions/delete_interaction/?content_type=NEWS&content_id=$backendNewsId&interaction_type=BOOKMARK',
            ),
            headers: {'Authorization': 'Bearer $accessToken'},
          );
          if (retryResponse.statusCode == 204) {
            state = false;
          }
        }
      } else {
        developer.log('Delete bookmark failed: ${deleteResponse.statusCode} - ${deleteResponse.body}');
      }
    } else {
      // Add bookmark
      final addResponse = await http.post(
        Uri.parse('${dotenv.env['django_api']}/api/interactions/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'content_type': 'NEWS',
          'content_id': backendNewsId,
          'interaction_type': 'BOOKMARK',
          'interaction_value': 1.0,
        }),
      );

      if (addResponse.statusCode == 201) {
        state = true;
      } else if (addResponse.statusCode == 401) {
        accessToken = await _refreshToken();
        if (accessToken != null) {
          final retryResponse = await http.post(
            Uri.parse('${dotenv.env['django_api']}/api/interactions/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode({
              'content_type': 'NEWS',
              'content_id': backendNewsId,
              'interaction_type': 'BOOKMARK',
              'interaction_value': 1.0,
            }),
          );
          if (retryResponse.statusCode == 201) {
            state = true;
          }
        }
      } else {
        developer.log('Add bookmark failed: ${addResponse.statusCode} - ${addResponse.body}');
      }
    }

    // Invalidate the isBookmarkedProvider to refresh the UI
    ref.invalidate(isBookmarkedProvider(newsId));
  }
}

// Provider for the bookmark notifier
final bookmarkProvider = StateNotifierProvider.family<BookmarkNotifier, bool, String>((ref, newsId) {
  final isBookmarkedAsync = ref.watch(isBookmarkedProvider(newsId));
  // Initialize with false until the async provider resolves
  final initialState = isBookmarkedAsync.when(
    data: (isBookmarked) => isBookmarked,
    loading: () => false,
    error: (error, stack) => false,
  );
  return BookmarkNotifier(ref, newsId, initialState);
});

// Provider to fetch all bookmarked articles
final bookmarkedArticlesProvider = FutureProvider<List<ArticleModel>>((ref) async {
  String? accessToken = ref.read(authProvider);
  final prefs = await SharedPreferences.getInstance();

  // Refresh token logic
  Future<String?> _refreshToken() async {
    try {
      final refreshToken = prefs.getString('refresh_token');
      final authProviderType = prefs.getString('auth_provider') ?? 'neqat';
      if (refreshToken == null) return null;

      final response = await http.post(
        Uri.parse('${dotenv.env['django_api']}/api/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['access'];
        final newRefreshToken = data['refresh'];
        await prefs.setString('access_token', newAccessToken);
        await prefs.setString('refresh_token', newRefreshToken);
        await prefs.setString('auth_provider', authProviderType);
        ref.read(authProvider.notifier).setToken(newAccessToken);
        return newAccessToken;
      }
      developer.log('Token refresh failed: ${response.statusCode}');
      return null;
    } catch (e) {
      developer.log('Token refresh error: $e');
      return null;
    }
  }

  // Get access token
  if (accessToken == null) {
    accessToken = prefs.getString('access_token');
    if (accessToken == null) {
      accessToken = await _refreshToken();
      if (accessToken == null) {
        developer.log('No access token available');
        return [];
      }
    }
  }

  // Fetch all bookmark interactions
  final bookmarkResponse = await http.get(
    Uri.parse('${dotenv.env['django_api']}/api/interactions/?content_type=NEWS&interaction_type=BOOKMARK'),
    headers: {'Authorization': 'Bearer $accessToken'},
  );

  List<String> contentIds = [];
  if (bookmarkResponse.statusCode == 200) {
    final data = jsonDecode(bookmarkResponse.body);
    if (data['results'] != null && data['results'] is List) {
      contentIds = (data['results'] as List).map((interaction) => interaction['content_id'].toString()).toList();
    }
  } else if (bookmarkResponse.statusCode == 401) {
    accessToken = await _refreshToken();
    if (accessToken != null) {
      final retryResponse = await http.get(
        Uri.parse('${dotenv.env['django_api']}/api/interactions/?content_type=NEWS&interaction_type=BOOKMARK'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (retryResponse.statusCode == 200) {
        final data = jsonDecode(retryResponse.body);
        if (data['results'] != null && data['results'] is List) {
          contentIds = (data['results'] as List).map((interaction) => interaction['content_id'].toString()).toList();
        }
      }
    }
  }

  if (contentIds.isEmpty) {
    return [];
  }

  // Fetch article details
  final List<ArticleModel> articles = [];
  for (final contentId in contentIds) {
    final newsResponse = await http.get(
      Uri.parse('${dotenv.env['django_api']}/api/news/$contentId/'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (newsResponse.statusCode == 200) {
      final data = jsonDecode(newsResponse.body);
      articles.add(
        ArticleModel.fromJson({
          'url': data['url'],
          'title': data['title'],
          'description': data['content'] ?? '',
          'urlToImage': data['image_url'] ?? '',
          'publishedAt': data['published_at'] ?? '',
          'source': data['source'] ?? '',
          'type': ArticleType.news,
          'author': data['author'] ?? '',
          'content': data['content'] ?? '',
        }),
      );
    } else if (newsResponse.statusCode == 401) {
      accessToken = await _refreshToken();
      if (accessToken != null) {
        final retryResponse = await http.get(
          Uri.parse('${dotenv.env['django_api']}/api/news/$contentId/'),
          headers: {'Authorization': 'Bearer $accessToken'},
        );
        if (retryResponse.statusCode == 200) {
          final data = jsonDecode(retryResponse.body);
          articles.add(
            ArticleModel.fromJson({
              'url': data['url'],
              'title': data['title'],
              'description': data['content'] ?? '',
              'urlToImage': data['image_url'] ?? '',
              'publishedAt': data['published_at'] ?? '',
              'source': data['source'] ?? '',
              'type': ArticleType.news,
              'author': data['author'] ?? '',
              'content': data['content'] ?? '',
            }),
          );
        }
      }
    }
  }

  return articles;
});