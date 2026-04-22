import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/presentation/widgets/blog_tile.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/providers/auth_provider.dart';
import 'dart:io' show Platform;

// Provider for view count
final viewCountProvider = FutureProvider.family<int, String>((ref, url) async {
  try {
    String? accessToken = ref.read(authProvider);
    if (accessToken == null) {
      final prefs = await SharedPreferences.getInstance();
      accessToken = prefs.getString('access_token');
      if (accessToken == null) return 0;
    }

    final response = await http.get(
      Uri.parse('${dotenv.env['django_api']}/api/comments/view_count/?news_id=$url'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['view_count'] ?? 0;
    }
    return 0;
  } catch (e) {
    return 0;
  }
});

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
  bool _hasLaunchedUrl = false;

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    _currentUrl = widget.blogUrl;
    _fetchBackendNewsIdAndRecordView();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    webViewBackground = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF121212)
        : Colors.white;
    if (!kIsWeb) {
      _initializeWebViewForMobile();
    } else if (!_hasLaunchedUrl) {
      _launchUrl(_currentUrl!);
    }
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

    if (kIsWeb) {
      return WillPopScope(
        onWillPop: () async {
          // Return to previous screen
          Navigator.of(context).pop();
          return false;
        },
        child: Scaffold(
          appBar: appBar,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Opening article in a new tab...',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    _launchUrl(_currentUrl!);
                    // Return to previous screen after launching URL
                    Navigator.of(context).pop();
                  },
                  child: const Text('Click here if not redirected automatically'),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
    if (_hasLaunchedUrl) return;
    
    String secureUrl = url.startsWith('http://')
        ? url.replaceFirst('http://', 'https://')
        : url;
    final Uri uri = Uri.parse(secureUrl);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch $secureUrl')),
          );
        }
      } else {
        setState(() {
          _hasLaunchedUrl = true;
        });
        // Return to previous screen after successful launch
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching URL: $e')),
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
          // Force UI update by incrementing the update counter
          ref.read(viewCountUpdateProvider.notifier).state++;
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
}

extension on WebResourceError {
  get failingUrl => null;
}