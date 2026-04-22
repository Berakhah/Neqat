import 'package:flutter/material.dart';
import 'package:frontend/presentation/widgets/blog_tile.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/app/providers/auth_provider.dart';
import 'package:frontend/domain/entities/article_model.dart';
import 'package:frontend/l10n/app_localizations.dart'; 
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:uuid/uuid.dart';
import 'package:frontend/app/themes.dart';

class CommentScreen extends ConsumerStatefulWidget {
  final ArticleModel article;
  final bool isTelegram;
  final String? newsId; // keep this optional now

  const CommentScreen({
    Key? key,
    required this.article,
    this.isTelegram = false, // ← default to false
    this.newsId,
  }) : super(key: key);

  @override
  _CommentScreenState createState() => _CommentScreenState();
}

class _CommentScreenState extends ConsumerState<CommentScreen> {
  final _commentController = TextEditingController();
  bool _isLoading = false;
  List<dynamic> _comments = [];
  String? _backendNewsId;
  String? _replyingToCommentId;
  Set<String> _visibleReplies = {};
  String? _currentUserProfileImage;
  String? _currentUserFirstName; // Store the user's first name

  @override
  void initState() {
    super.initState();
    _loadCurrentUserProfile();
    _fetchBackendNewsId().then((value) async => await _fetchComments());
  }

  Future<void> _loadCurrentUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserProfileImage = prefs.getString('profile_image');
      _currentUserFirstName =
          prefs.getString('user_name') ?? 'A'; // Default to 'A' if not found
    });
  }

  Future<String?> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      final authProviderType = prefs.getString('auth_provider') ?? 'neqat';
      if (refreshToken == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unexpected error occurred.')));
        return null;
      }

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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unexpected error occurred.')),
        );
        return null;
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Token refresh error: ${e.toString()}')));
      return null;
    }
  }

  Future<void> _fetchBackendNewsId() async {
    try {
      String? accessToken = ref.read(authTokenProvider);
      if (accessToken == null) {
        final prefs = await SharedPreferences.getInstance();
        accessToken = prefs.getString('access_token');
        if (accessToken != null) {
          ref.read(authProvider.notifier).setToken(accessToken);
        } else {
          accessToken = await _refreshToken();
          if (accessToken == null) return;
        }
      }

      final response = await http.get(
        Uri.parse(
          '${dotenv.env['django_api']}/api/news/?url=${Uri.encodeComponent(widget.newsId!)}',
        ),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          setState(() {
            _backendNewsId = data['results'][0]['id'];
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Article not found.')),
          );
        }
      } else if (response.statusCode == 401) {
        accessToken = await _refreshToken();
        if (accessToken != null) {
          final retryResponse = await http.get(
            Uri.parse(
              '${dotenv.env['django_api']}/api/news/?url=${Uri.encodeComponent(widget.newsId!)}',
            ),
            headers: {'Authorization': 'Bearer $accessToken'},
          );
          if (retryResponse.statusCode == 200) {
            final data = jsonDecode(retryResponse.body);
            if (data['results'] != null && data['results'].isNotEmpty) {
              setState(() {
                _backendNewsId = data['results'][0]['id'];
              });
              return;
            }
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch article: ${response.body}'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch article: ${response.body}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Exception while fetching article: $e')));
    }
  }

  Future<void> _fetchComments() async {
    if (_backendNewsId == null) return;

    try {
      String? accessToken = ref.read(authTokenProvider);
      if (accessToken == null) {
        final prefs = await SharedPreferences.getInstance();
        accessToken = prefs.getString('access_token');
        if (accessToken != null) {
          ref.read(authProvider.notifier).setToken(accessToken);
        } else {
          accessToken = await _refreshToken();
          if (accessToken == null) return;
        }
      }

      final response = await http.get(
        Uri.parse(
          '${dotenv.env['django_api']}/api/comments/?news_id=$_backendNewsId',
        ),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['results'] != null) {
          setState(() {
            _comments = data['results'] as List<dynamic>;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid comment data.')),
          );
        }
      } else if (response.statusCode == 401) {
        accessToken = await _refreshToken();
        if (accessToken != null) {
          final retryResponse = await http.get(
            Uri.parse(
              '${dotenv.env['django_api']}/api/comments/?news_id=$_backendNewsId',
            ),
            headers: {'Authorization': 'Bearer $accessToken'},
          );
          if (retryResponse.statusCode == 200) {
            final data = jsonDecode(retryResponse.body);
            if (data is Map<String, dynamic> && data['results'] != null) {
              setState(() {
                _comments = data['results'] as List<dynamic>;
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Invalid comment data.')),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load comments: ${retryResponse.body}'),
              ),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load comments: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Exception while loading comments: ${e.toString()}')));
    }
  }

  Future<void> _postComment({String? parentCommentId}) async {
    if (_backendNewsId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No comment ID found.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? accessToken = ref.read(authTokenProvider);
      if (accessToken == null) {
        final prefs = await SharedPreferences.getInstance();
        accessToken = prefs.getString('access_token');
        if (accessToken != null) {
          ref.read(authProvider.notifier).setToken(accessToken);
        } else {
          accessToken = await _refreshToken();
          if (accessToken == null) {
            setState(() => _isLoading = false);
            return;
          }
        }
      }

      final commentContent = _commentController.text.trim();
      if (commentContent.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Empty comment.')),
      );
        setState(() => _isLoading = false);
        return;
      }

      final body = {
        'news_id': _backendNewsId,
        'content': commentContent,
        if (parentCommentId != null) 'parent_comment': parentCommentId,
      };

      final response = await http.post(
        Uri.parse('${dotenv.env['django_api']}/api/comments/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Comment posted successfully.')),
      );
        _commentController.clear();
        setState(() {
          _replyingToCommentId = null;
        });

        // Fetch updated comments
        final commentsResponse = await http.get(
          Uri.parse(
            '${dotenv.env['django_api']}/api/comments/?news_id=$_backendNewsId',
          ),
          headers: {'Authorization': 'Bearer $accessToken'},
        );

        if (commentsResponse.statusCode == 200) {
          final data = jsonDecode(commentsResponse.body);
          if (data is Map<String, dynamic> && data['results'] != null) {
            setState(() {
              _comments = data['results'] as List<dynamic>;
            });
            // Invalidate commentCountProvider to update UI
            ref.invalidate(commentCountProvider(widget.newsId!));
            debugPrint('Updated comments fetched');
          } else {
            debugPrint('Invalid comment data format');
          }
        } else {
          debugPrint(
            'Failed to fetch updated comments: ${commentsResponse.body}',
          );
        }
      } else {
        if (response.statusCode == 401) {
          accessToken = await _refreshToken();
          if (accessToken != null) {
            final retryResponse = await http.post(
              Uri.parse('${dotenv.env['django_api']}/api/comments/'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $accessToken',
              },
              body: jsonEncode(body),
            );
            if (retryResponse.statusCode == 201) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Comment posted successfully.')),
              );
              _commentController.clear();
              setState(() {
                _replyingToCommentId = null;
              });

              // Fetch updated comments after retry
              final commentsResponse = await http.get(
                Uri.parse(
                  '${dotenv.env['django_api']}/api/comments/?news_id=$_backendNewsId',
                ),
                headers: {'Authorization': 'Bearer $accessToken'},
              );

              if (commentsResponse.statusCode == 200) {
                final data = jsonDecode(commentsResponse.body);
                if (data is Map<String, dynamic> && data['results'] != null) {
                  setState(() {
                    _comments = data['results'] as List<dynamic>;
                  });
                  // Invalidate commentCountProvider to update UI
                  ref.invalidate(commentCountProvider(widget.newsId!));
                  debugPrint('Updated comments fetched after retry');
                } else {
                  debugPrint('Invalid comment data format after retry');
                }
              } else {
                debugPrint(
                  'Failed to fetch updated comments after retry: ${commentsResponse.body}',
                );
              }
              return;
            }
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('General error: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startReply(String commentId) {
    setState(() {
      _replyingToCommentId = commentId;
    });
    _commentController.clear();
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
    });
    _commentController.clear();
  }

  void _toggleReplies(String commentId) {
    setState(() {
      if (_visibleReplies.contains(commentId)) {
        _visibleReplies.remove(commentId);
      } else {
        _visibleReplies.add(commentId);
      }
    });
  }

  int _countNestedReplies(dynamic comment) {
    int count = 0;
    final replies = comment['replies'] as List<dynamic>?;
    if (replies != null) {
      count += replies.length;
      for (var reply in replies) {
        count += _countNestedReplies(reply);
      }
    }
    return count;
  }

  String? _getReplyingToUsername() {
    if (_replyingToCommentId == null) return null;
    dynamic findComment(List<dynamic> comments, String id) {
      for (var comment in comments) {
        if (comment['id'] == id) return comment;
        final replies = comment['replies'] as List<dynamic>?;
        if (replies != null) {
          var found = findComment(replies, id);
          if (found != null) return found;
        }
      }
      return null;
    }

    final comment = findComment(_comments, _replyingToCommentId!);
    return comment != null ? comment['created_by'] ?? 'Anonymous' : null;
  }

  String _formatRelativeTime(String createdAt) {
    try {
      final now = DateTime.now().toUtc();
      final commentTime = DateTime.parse(createdAt).toUtc();
      final difference = now.difference(commentTime);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '${weeks}w';
      } else {
        final months = (difference.inDays / 30).floor();
        return '${months}m';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Access AppLocalizations
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Theme(
      data: theme.copyWith(
        dividerTheme: theme.dividerTheme.copyWith(thickness: 0.5),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Comments',
            style: getInterTextStyle(
              isDark: isDark,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: theme.appBarTheme.elevation,
          titleTextStyle: theme.appBarTheme.titleTextStyle,
        ),
        body: Stack(
          children: [
            ListView(
              padding: EdgeInsets.only(bottom: 80),
              children: [
                // Article Tile
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: theme.dividerTheme.color!),
                    ),
                    color: theme.cardTheme.color,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: widget.article.urlToImage!,
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                          errorWidget:
                              (context, url, error) => SvgPicture.asset(
                                'images/neqat_logo/logo-color.svg',
                                width: 80,
                                height: 80,
                              ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor:
                                      isDark
                                          ? Colors.grey[700]
                                          : Colors.grey[300],
                                  child: Text(
                                    widget.article.author![0].toUpperCase(),
                                    style: getInterTextStyle(
                                      isDark: isDark,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          widget.article.author!,
                                          style: getInterTextStyle(
                                            isDark: isDark,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          '@${widget.article.author!.toLowerCase().replaceAll(' ', '')}',
                                          style: getInterTextStyle(
                                            isDark: isDark,
                                            fontSize: 12,
                                            fontWeight: FontWeight.normal,
                                            color:
                                                theme
                                                    .textTheme
                                                    .bodySmall!
                                                    .color,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              widget.article.title!,
                              style: getInterTextStyle(
                                isDark: isDark,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              widget.article.description!,
                              style: getInterTextStyle(
                                isDark: isDark,
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                color: theme.textTheme.bodyMedium!.color,
                              ),
                              maxLines: widget.isTelegram ? null : 2,
                              overflow:
                                  widget.isTelegram
                                      ? null
                                      : TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Comments
                if (_comments.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'No comments yet.',
                        style: getInterTextStyle(
                          isDark: isDark,
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                  )
                else
                  ..._comments.asMap().entries.map((entry) {
                    final index = entry.key;
                    final comment = entry.value;
                    return Column(
                      children: [
                        if (index > 0)
                          SizedBox(height: 16), // Spacing between comments
                        _buildCommentWidget(comment, 0),
                      ],
                    );
                  }),
              ],
            ),
            // Fixed Comment Input
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  border: Border(
                    top: BorderSide(color: theme.dividerTheme.color!),
                  ),
                ),
                child: Column(
                  children: [
                    if (_replyingToCommentId != null)
                      Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Replying to ${_getReplyingToUsername() ?? 'Anonymous'}',
                                style: getInterTextStyle(
                                  isDark: isDark,
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                  color: theme.textTheme.bodyMedium!.color,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _cancelReply,
                              icon: Icon(
                                Icons.cancel,
                                color: theme.textTheme.bodySmall!.color,
                              ),
                              constraints: BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              isDark ? Colors.grey[700] : Colors.grey[300],
                          backgroundImage:
                              _currentUserProfileImage != null
                                  ? NetworkImage(_currentUserProfileImage!)
                                  : null,
                          child:
                              _currentUserProfileImage == null
                                  ? Text(
                                      _currentUserFirstName![0].toUpperCase(),
                                      style: getInterTextStyle(
                                        isDark: isDark,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText:
                                  _replyingToCommentId != null
                                      ? 'Write a reply...'
                                      : 'Add a comment...',
                              border: theme.inputDecorationTheme.border,
                              enabledBorder:
                                  theme.inputDecorationTheme.enabledBorder,
                              focusedBorder:
                                  theme.inputDecorationTheme.focusedBorder,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              hintStyle: getInterTextStyle(
                                isDark: isDark,
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                color:
                                    theme.inputDecorationTheme.hintStyle!.color,
                              ),
                              filled: true,
                              fillColor: theme.cardTheme.color,
                            ),
                            maxLines: 1,
                            style: getInterTextStyle(
                              isDark: isDark,
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        _isLoading
                            ? CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              )
                            : IconButton(
                                onPressed:
                                    () => _postComment(
                                          parentCommentId: _replyingToCommentId,
                                        ),
                                icon: Icon(
                                  Icons.send,
                                  color: theme.colorScheme.primary,
                                ),
                                padding: EdgeInsets.all(12),
                                constraints: BoxConstraints(),
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentWidget(dynamic comment, int depth) {
    final l10n = AppLocalizations.of(context)!; // Access AppLocalizations
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final replies = comment['replies'] as List<dynamic>?;
    final replyCount = _countNestedReplies(comment);
    final showReplies = _visibleReplies.contains(comment['id']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _startReply(comment['id']),
          child: Container(
            padding: EdgeInsets.only(
              left: 16 + (depth * 16),
              right: 16,
              top: 8,
              bottom: 8,
            ),
            decoration: BoxDecoration(color: theme.cardTheme.color),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                  child: Text(
                    comment['created_by']?[0].toUpperCase() ?? 'A',
                    style: getInterTextStyle(
                      isDark: isDark,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              comment['created_by'] ?? 'Anonymous',
                              style: getInterTextStyle(
                                isDark: isDark,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _formatRelativeTime(comment['created_at']),
                              style: getInterTextStyle(
                                isDark: isDark,
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                                color: theme.textTheme.bodySmall!.color,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        comment['content'],
                        style: getInterTextStyle(
                          isDark: isDark,
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      if (replyCount > 0)
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: TextButton(
                            onPressed: () => _toggleReplies(comment['id']),
                            child: Text(
                              '${replyCount == 1 ? "1 reply" : "$replyCount replies"}',
                              style: getInterTextStyle(
                                isDark: isDark,
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Recursively render replies if visible
        if (showReplies && replies != null && replies.isNotEmpty)
          ...replies.asMap().entries.map((entry) {
            final index = entry.key;
            final reply = entry.value;
            return Column(
              children: [
                if (index > 0) SizedBox(height: 8),
                _buildCommentWidget(reply, depth + 1),
              ],
            );
          }),
      ],
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}