import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'article_view.dart';  // Import the viewCountProvider

class ArticleView extends ConsumerStatefulWidget {
  final String blogUrl;
  final String title;

  const ArticleView({
    Key? key,
    required this.blogUrl,
    required this.title,
  }) : super(key: key);

  @override
  ConsumerState<ArticleView> createState() => _ArticleViewState();
}

class _ArticleViewState extends ConsumerState<ArticleView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _backendNewsId;
  bool _isInitialized = false;
  String? _currentUrl;
  late Color webViewBackground;

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    _currentUrl = widget.blogUrl;
    // Do NOT call _initializeWebView() here!
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    webViewBackground = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF121212)
        : Colors.white;
    _initializeWebView(); // Now it's safe!
  }

  @override
  void didUpdateWidget(ArticleView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.blogUrl != widget.blogUrl) {
      setState(() {
        _currentUrl = widget.blogUrl;
        _isLoading = true;
      });
      _initializeWebView();
    }
  }

  void _initializeWebView() {
    if (_currentUrl == null) return;
    _initializeWebViewForMobile();
    _fetchBackendNewsIdAndRecordView();
  }

  void _initializeWebViewForMobile() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(webViewBackground)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Web resource error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(_currentUrl!));
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      iconTheme: Theme.of(context).appBarTheme.iconTheme,
      centerTitle: true,
      elevation: 0.0,
      title: Text(widget.title),
    );

    return Scaffold(
      appBar: appBar,
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: webViewBackground,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    String secureUrl = url.startsWith('http://')
      ? url.replaceFirst('http://', 'https://')
      : url;
    final Uri uri = Uri.parse(secureUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $secureUrl'))
        );
      }
    }
  }

  Future<void> _fetchBackendNewsIdAndRecordView() async {
    try {
      String? accessToken = ref.read(authProvider);
      final prefs = await SharedPreferences.getInstance();
      if (accessToken == null) {
        accessToken = prefs.getString('access_token');
        if (accessToken != null) {
          ref.read(authProvider.notifier).setToken(accessToken);
        } else {
          accessToken = await _refreshToken();
          if (accessToken == null) return;
        }
      }

      // Fetch backend news_id using the original URL
      final newsResponse = await http.get(
        Uri.parse('${dotenv.env['django_api']}/api/news/?url=${Uri.encodeComponent(_currentUrl!)}'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (newsResponse.statusCode == 200) {
        final data = jsonDecode(newsResponse.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          setState(() {
            _backendNewsId = data['results'][0]['id'];
          });
          // Record view interaction
          await _recordViewInteraction(accessToken);
        }
      } else if (newsResponse.statusCode == 401) {
        accessToken = await _refreshToken();
        if (accessToken != null) {
          final retryResponse = await http.get(
            Uri.parse('${dotenv.env['django_api']}/api/news/?url=${Uri.encodeComponent(_currentUrl!)}'),
            headers: {'Authorization': 'Bearer $accessToken'},
          );
          if (retryResponse.statusCode == 200) {
            final data = jsonDecode(retryResponse.body);
            if (data['results'] != null && data['results'].isNotEmpty) {
              setState(() {
                _backendNewsId = data['results'][0]['id'];
              });
              await _recordViewInteraction(accessToken);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching backend news ID: $e');
    }
  }

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
        ref.read(authProvider.notifier).setToken(newAccessToken);
        return newAccessToken;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _recordViewInteraction(String accessToken) async {
    if (_backendNewsId == null) return;

    try {
      // Record view interaction
      final response = await http.post(
        Uri.parse('${dotenv.env['django_api']}/api/interactions/batch_record/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode([
          {
            'content_type': 'NEWS',
            'content_id': _backendNewsId,
            'interaction_type': 'VIEW',
            'interaction_value': 1.0,
          }
        ]),
      );

      if (response.statusCode == 201) {
        // Fetch updated view count
        final viewResponse = await http.get(
          Uri.parse('${dotenv.env['django_api']}/api/comments/view_count/?news_id=$_backendNewsId'),
          headers: {'Authorization': 'Bearer $accessToken'},
        );

        if (viewResponse.statusCode == 200) {
          final viewData = jsonDecode(viewResponse.body);
          // Invalidate the viewCountProvider to force UI update
          ref.invalidate(viewCountProvider(_currentUrl!));
          debugPrint('Updated view count: ${viewData['view_count']}');
        } else {
          debugPrint('Failed to fetch view count: ${viewResponse.body}');
        }
      } else {
        debugPrint('Failed to record view interaction: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error recording view interaction: $e');
    }
  }
}

extension on WebResourceError {
  get failingUrl => null;
} 