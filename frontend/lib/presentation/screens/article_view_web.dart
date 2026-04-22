import 'package:flutter/material.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';
import 'dart:ui' as ui;
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;
import 'package:js/js.dart';
import 'dart:js_interop';

class ArticleViewWeb {
  static void initializeWebView(String url, BuildContext context, Function(bool) onLoadingChanged) {
    WebViewPlatform.instance = WebWebViewPlatform();
    final viewId = 'webview-${url.hashCode}';
    
    ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
      final container = html.DivElement()
        ..style.cssText = 'width: 100%; height: 100%; display: flex; flex-direction: column; background: ${Theme.of(context).brightness == Brightness.dark ? '#121212' : '#FFFFFF'};';
      
      String processedUrl = url;
      if (!processedUrl.startsWith('http://') && !processedUrl.startsWith('https://')) {
        processedUrl = 'https://$processedUrl';
      } else if (processedUrl.startsWith('http://')) {
        processedUrl = processedUrl.replaceFirst('http://', 'https://');
      }
      final encodedUrl = Uri.encodeFull(processedUrl);

      // Create iframe
      final iframe = html.IFrameElement()
        ..src = encodedUrl
        ..style.cssText = '''
          width: 100%;
          height: 100%;
          border: none;
          background: ${Theme.of(context).brightness == Brightness.dark ? '#121212' : '#FFFFFF'};
        '''
        ..setAttribute('crossorigin', 'anonymous')
        ..setAttribute('referrerpolicy', 'no-referrer')
        ..setAttribute('sandbox', 'allow-same-origin allow-scripts allow-popups allow-forms allow-downloads allow-top-navigation')
        ..setAttribute('allow', 'fullscreen')
        ..setAttribute('loading', 'eager')
        ..setAttribute('importance', 'high')
        ..setAttribute('fetchpriority', 'high')
        ..setAttribute('allowfullscreen', 'true')
        ..setAttribute('allowtransparency', 'true')
        ..setAttribute('frameborder', '0')
        ..setAttribute('scrolling', 'yes')
        ..setAttribute('marginwidth', '0')
        ..setAttribute('marginheight', '0')
        ..setAttribute('hspace', '0')
        ..setAttribute('vspace', '0');

      // Add error handling
      iframe.onError.listen((event) {
        html.window.open(encodedUrl, '_blank');
        _showLoadingMessage(container, context);
      });

      // Add load event listener
      iframe.onLoad.listen((event) {
        onLoadingChanged(false);
      });

      container.children.add(iframe);
      return container;
    });
  }

  static void _showLoadingMessage(html.DivElement container, BuildContext context) {
    container.children.clear();
    final loadingContainer = html.DivElement()
      ..style.cssText = '''
        width: 100%;
        height: 100%;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        padding: 20px;
        text-align: center;
        background: ${Theme.of(context).brightness == Brightness.dark ? '#121212' : '#FFFFFF'};
      ''';
    
    final title = html.HeadingElement.h2()
      ..text = 'Opening Article'
      ..style.cssText = 'color: ${Theme.of(context).brightness == Brightness.dark ? '#FFFFFF' : '#000000'}; margin-bottom: 16px;';
    
    final message = html.ParagraphElement()
      ..text = 'The article is being opened in a new tab...'
      ..style.cssText = 'color: ${Theme.of(context).brightness == Brightness.dark ? '#CCCCCC' : '#666666'}; margin-bottom: 24px;';
    
    final spinner = html.DivElement()
      ..style.cssText = '''
        width: 40px;
        height: 40px;
        border: 4px solid #f3f3f3;
        border-top: 4px solid #2196F3;
        border-radius: 50%;
        animation: spin 1s linear infinite;
      ''';
    
    final style = html.StyleElement()
      ..text = '''
        @keyframes spin {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
      ''';
    
    loadingContainer.children.addAll([title, message, spinner]);
    container.children.addAll([style, loadingContainer]);
  }
} 