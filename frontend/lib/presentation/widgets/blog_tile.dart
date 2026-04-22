import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:frontend/app/providers/bookmark_provider.dart';
import 'package:frontend/domain/entities/article_model.dart';
import 'package:frontend/presentation/screens/article_view.dart';
import 'package:frontend/presentation/screens/comment_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/app/providers/auth_provider.dart';
import 'package:frontend/l10n/app_localizations.dart';

// Provider to fetch comment count for an article
final commentCountProvider = FutureProvider.family<int, String>((
  ref,
  newsId,
) async {
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
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get access token
  if (accessToken == null) {
    accessToken = prefs.getString('access_token');
    if (accessToken == null) {
      accessToken = await _refreshToken();
      if (accessToken == null) return 0;
    }
  }

  // Fetch backend news_id
  final newsResponse = await http.get(
    Uri.parse(
      '${dotenv.env['django_api']}/api/news/?url=${Uri.encodeComponent(newsId)}',
    ),
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
        Uri.parse(
          '${dotenv.env['django_api']}/api/news/?url=${Uri.encodeComponent(newsId)}',
        ),
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
      '${dotenv.env['django_api']}/api/comments/?news_id=$backendNewsId',
    ),
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
    accessToken = await _refreshToken();
    if (accessToken != null) {
      final retryResponse = await http.get(
        Uri.parse(
          '${dotenv.env['django_api']}/api/comments/?news_id=$backendNewsId',
        ),
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

// Provider to force UI updates
final viewCountUpdateProvider = StateProvider<int>((ref) => 0);

// Provider to fetch view count for an article
final viewCountProvider = FutureProvider.family<int, String>((ref, url) async {
  // Watch the update provider to force refresh
  ref.watch(viewCountUpdateProvider);

  try {
    String? accessToken = ref.read(authProvider);
    final prefs = await SharedPreferences.getInstance();

    if (accessToken == null) {
      accessToken = prefs.getString('access_token');
      if (accessToken == null) {
        accessToken = await _refreshToken();
        if (accessToken == null) return 0;
      }
    }

    // Fetch backend news_id
    final newsResponse = await http.get(
      Uri.parse('${dotenv.env['django_api']}/api/news/?url=${Uri.encodeComponent(url)}'),
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
          Uri.parse('${dotenv.env['django_api']}/api/news/?url=${Uri.encodeComponent(url)}'),
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

    // Fetch view count
    final viewResponse = await http.get(
      Uri.parse('${dotenv.env['django_api']}/api/comments/view_count/?news_id=$backendNewsId'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (viewResponse.statusCode == 200) {
      final data = jsonDecode(viewResponse.body);
      return data['view_count'] as int;
    } else if (viewResponse.statusCode == 401) {
      accessToken = await _refreshToken();
      if (accessToken != null) {
        final retryResponse = await http.get(
          Uri.parse('${dotenv.env['django_api']}/api/comments/view_count/?news_id=$backendNewsId'),
          headers: {'Authorization': 'Bearer $accessToken'},
        );
        if (retryResponse.statusCode == 200) {
          final data = jsonDecode(retryResponse.body);
          return data['view_count'] as int;
        }
      }
    }

    return 0;
  } catch (e) {
    return 0;
  }
});

// Helper function for token refresh
Future<String?> _refreshToken() async {
  try {
    final prefs = await SharedPreferences.getInstance();
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
      return newAccessToken;
    }
    return null;
  } catch (e) {
    return null;
  }
}

class BlogTile extends ConsumerWidget {
  final ArticleModel article;
  final VoidCallback? onBookmarkTap;
  @override
  const BlogTile({required this.article, this.onBookmarkTap, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    // Watch the comment count provider
    final commentCountAsync = ref.watch(commentCountProvider(article.url!));
    // Watch the view count provider
    final viewCountAsync = ref.watch(viewCountProvider(article.url!));
    // Watch the bookmark provider
    final isBookmarked = ref.watch(bookmarkProvider(article.url!));

    return GestureDetector(
      // inside BlogTile.build():
      onTap: () {
        if (article.type == ArticleType.telegram) {
          // If this is a Telegram message, open our CommentScreen instead of the web-view.
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => CommentScreen(
                    article: article,
                    isTelegram: true,
                    newsId: null,
                  ),
            ),
          );
        } else {
          // For normal news, go to your web-view
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ArticleView(
                blogUrl: article.url!,
                title: article.title ?? l10n.noTitle,
              ),
            ),
          );
        }
      },

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
                      _buildArticleContent(context, l10n),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInteractionBar(
                    context,
                    l10n,
                    commentCountAsync,
                    viewCountAsync,
                    isBookmarked,
                    ref,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArticleImage(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 120,
        width: 120,
        child:
            article.urlToImage != null && article.urlToImage!.isNotEmpty
                ? CachedNetworkImage(
                  imageUrl: article.urlToImage!,
                  height: 120,
                  width: 120,
                  fit: BoxFit.cover,
                  errorWidget:
                      (context, url, error) => SvgPicture.asset(
                        'images/neqat_logo/logo-color.svg',
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                )
                : SvgPicture.asset(
                  'images/neqat_logo/logo-color.svg',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
      ),
    );
  }

  Widget _buildArticleContent(BuildContext context, AppLocalizations l10n) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            article.title ?? l10n.noTitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            article.description ?? l10n.noDescription,
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
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<int> commentCountAsync,
    AsyncValue<int> viewCountAsync,
    bool isBookmarked,
    WidgetRef ref,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildInteractionItem(
          context,
          l10n,
          icon: Icons.visibility_outlined,
          count: viewCountAsync.when(
            data: (count) => count,
            loading: () => null,
            error: (error, stack) => 0,
          ),
          onTap: () {},
        ),
        _buildInteractionItem(
          context,
          l10n,
          icon: Icons.comment_outlined,
          count: commentCountAsync.when(
            data: (count) => count,
            loading: () => null,
            error: (error, stack) => 0,
          ),
          onTap: () {
            if (article.url == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.postCommentNoIdMessage)),
              );
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CommentScreen(
                  article: article,
                  isTelegram: false,
                  newsId: article.url,
                ),
              ),
            );
          },
        ),
        _buildInteractionItem(
          context,
          l10n,
          icon:
              isBookmarked
                  ? Icons.bookmark_added_outlined
                  : Icons.bookmark_add_outlined,
          count: null,
          onTap:
              onBookmarkTap ??
              () {
                // fallback if no callback was provided
                ref
                    .read(bookmarkProvider(article.url!).notifier)
                    .toggleBookmark();
              },

          color:
              isBookmarked ? Colors.blue : null, // Golden color for bookmarked
        ),
        _buildInteractionItem(
          context,
          l10n,
          icon: Icons.share_outlined,
          count: null,
          onTap: () {
            if (article.url == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.postCommentNoIdMessage)),
              );
              return;
            }
            Share.share(
              l10n.shareArticleMessage(
                article.title ?? l10n.noTitle,
                article.url!,
              ),
              subject: article.title ?? l10n.noTitle,
            );
          },
        ),
      ],
    );
  }

  Widget _buildInteractionItem(
    BuildContext context,
    AppLocalizations l10n, {
    required IconData icon,
    required int? count,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
            ),
            child: Center(
              child: Icon(
                icon,
                size: 20,
                color:
                    color ??
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 4),
            Text(
              count > 1000
                  ? '${(count / 1000).toStringAsFixed(1)}${l10n.thousandAbbreviation}'
                  : '$count',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
        builder: (context) => ArticleView(
          blogUrl: article.url!,
          title: article.title ?? AppLocalizations.of(context)!.noTitle,
        ),
      ),
    );
  }
}
