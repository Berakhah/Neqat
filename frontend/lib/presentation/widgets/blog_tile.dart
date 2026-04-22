import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/core/presentation/widgets/proxied_network_image.dart';
import 'package:frontend/domain/entities/article_model.dart';
import 'package:frontend/presentation/screens/article_view.dart';
import 'package:frontend/presentation/screens/comment_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/app/providers/auth_provider.dart';

// Provider to fetch comment count for an article
final commentCountProvider =
    FutureProvider.family<int, String>((ref, newsId) async {
  String? accessToken = ref.read(authTokenProvider);
  final prefs = await SharedPreferences.getInstance();

  // Refresh token logic (same as CommentScreen)
  Future<String?> refreshToken() async {
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
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get access token
  if (accessToken == null) {
    accessToken = prefs.getString('access_token');
    if (accessToken == null) {
      accessToken = await refreshToken();
      if (accessToken == null) return 0;
    }
  }

  // Fetch backend news_id
  final newsResponse = await http.get(
    Uri.parse(
        '${dotenv.env['django_api']}/api/news/?url=${Uri.encodeComponent(newsId)}'),
    headers: {'Authorization': 'Bearer $accessToken'},
  );

  String? backendNewsId;
  if (newsResponse.statusCode == 200) {
    final data = jsonDecode(newsResponse.body);
    if (data['results'] != null && data['results'].isNotEmpty) {
      backendNewsId = data['results'][0]['id'];
    }
  } else if (newsResponse.statusCode == 401) {
    accessToken = await refreshToken();
    if (accessToken != null) {
      final retryResponse = await http.get(
        Uri.parse(
            '${dotenv.env['django_api']}/api/news/?url=${Uri.encodeComponent(newsId)}'),
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

  if (backendNewsId == null) return 0;

  // Fetch comments
  final commentsResponse = await http.get(
    Uri.parse(
        '${dotenv.env['django_api']}/api/comments/?news_id=$backendNewsId'),
    headers: {'Authorization': 'Bearer $accessToken'},
  );

  // Recursive function to count comments and replies
  int countNestedComments(List<dynamic> comments) {
    int count = comments.length;
    for (var comment in comments) {
      final replies = comment['replies'] as List<dynamic>?;
      if (replies != null && replies.isNotEmpty) {
        count += countNestedComments(replies);
      }
    }
    return count;
  }

  if (commentsResponse.statusCode == 200) {
    final data = jsonDecode(commentsResponse.body);
    if (data is Map<String, dynamic> && data['results'] != null) {
      return countNestedComments(data['results'] as List<dynamic>);
    }
  } else if (commentsResponse.statusCode == 401) {
    accessToken = await refreshToken();
    if (accessToken != null) {
      final retryResponse = await http.get(
        Uri.parse(
            '${dotenv.env['django_api']}/api/comments/?news_id=$backendNewsId'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (retryResponse.statusCode == 200) {
        final data = jsonDecode(retryResponse.body);
        if (data is Map<String, dynamic> && data['results'] != null) {
          return countNestedComments(data['results'] as List<dynamic>);
        }
      }
    }
  }

  return 0;
});

class BlogTile extends ConsumerWidget {
  final ArticleModel article;

  const BlogTile({required this.article, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the comment count provider
    final commentCountAsync = ref.watch(commentCountProvider(article.url!));

    return GestureDetector(
      onTap: () => _navigateToArticle(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Material(
            elevation: 3,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildArticleImage(context),
                      const SizedBox(width: 12),
                      _buildArticleContent(context),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInteractionBar(context, commentCountAsync),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArticleImage(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ProxiedNetworkImage(
        imageUrl: article.urlToImage!,
        height: 120,
        width: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, url, error) => SvgPicture.asset(
          'images/neqat_logo/logo-color.svg',
          width: 120,
          height: 120,
        ),
      ),
    );
  }

  Widget _buildArticleContent(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            article.title!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            article.description!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionBar(
      BuildContext context, AsyncValue<int> commentCountAsync) {
    // Mock data for views (replace with actual data if available)
    const int viewCount = 1234;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildInteractionItem(
          context,
          icon: Icons.visibility_outlined,
          count: viewCount,
          onTap: () {
            // Optional: Handle view count tap (e.g., show analytics)
          },
        ),
        _buildInteractionItem(
          context,
          icon: Icons.comment_outlined,
          count: commentCountAsync.when(
            data: (count) => count,
            loading: () => null, // Show no count while loading
            error: (error, stack) => 0, // Show 0 on error
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    CommentScreen(newsId: article.url!, article: article),
              ),
            );
          },
        ),
        _buildInteractionItem(
          context,
          icon: Icons.share_outlined,
          count: null,
          onTap: () {
            Share.share(
              '${article.title}\n${article.url}',
              subject: article.title,
            );
          },
        ),
      ],
    );
  }

  Widget _buildInteractionItem(
    BuildContext context, {
    required IconData icon,
    required int? count,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          if (count != null) ...[
            const SizedBox(width: 4),
            Text(
              count > 1000 ? '${(count / 1000).toStringAsFixed(1)}K' : '$count',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                    fontSize: 12,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToArticle(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleView(blogUrl: article.url!),
      ),
    );
  }
}