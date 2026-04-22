import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io' if (kIsWeb) 'dart:html';

class ArticleView extends StatefulWidget {
  final String blogUrl;
  const ArticleView({super.key, required this.blogUrl});

  @override
  State<ArticleView> createState() => _ArticleViewState();
}

class _ArticleViewState extends State<ArticleView> {
  late final WebViewController _controller;
  bool _isLoading = true; // Track WebView loading state

  @override
  void initState() {
    _isLoading = true;
    super.initState();
    // Convert HTTP to HTTPS
    String secureUrl = widget.blogUrl.startsWith('http://')
        ? widget.blogUrl.replaceFirst('http://', 'https://')
        : widget.blogUrl;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _isLoading = progress < 100;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            // Apply dark theme if needed
            if (Theme.of(context).brightness == Brightness.dark) {
              _controller.runJavaScript('''
document.documentElement.setAttribute("data-theme", "dark");
''');
            } else {
              _controller.runJavaScript('''
document.documentElement.removeAttribute("data-theme");
''');
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint(
              'WebView error: ${error.description}, URL: ${error.failingUrl}',
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(secureUrl));
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      iconTheme: Theme.of(context).appBarTheme.iconTheme,
      centerTitle: true,
      elevation: 0.0,
    );

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      return Scaffold(
        appBar: appBar,
        body: _isLoading
            ? _buildShimmerLoading(context)
            : WebViewWidget(controller: _controller),
      );
    } else {
      return Scaffold(
        appBar: appBar,
        body: Center(
          child: ElevatedButton(
            onPressed: () => _launchUrl(widget.blogUrl),
            child: Text(
              'Open in Browser',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildShimmerLoading(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AppBar placeholder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: 56, // Approximate AppBar height
                color: Theme.of(context).highlightColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Title placeholder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: 24,
                color: Theme.of(context).highlightColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Description placeholder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.7,
                height: 16,
                color: Theme.of(context).highlightColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Content placeholder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height *
                    2.6, // Large content area
                color: Theme.of(context).highlightColor,
              ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch $secureUrl')));
      }
    }
  }
}

extension on WebResourceError {
  get failingUrl => null;
}
