/// Service for proxying images through the backend to avoid CORS issues
class ImageProxyService {
  static final ImageProxyService _instance = ImageProxyService._internal();
  String _backendUrl;

  factory ImageProxyService({String? backendUrl}) {
    if (backendUrl != null) {
      _instance._backendUrl = backendUrl;
    }
    return _instance;
  }

  ImageProxyService._internal() : _backendUrl = 'https://localhost:8000';

  /// Converts an external image URL to a proxied URL
  /// 
  /// This will route the image request through the backend to avoid CORS issues
  String getProxiedImageUrl(String originalUrl) {
    // Don't proxy if the URL is already from our backend or is a data URI
    if (originalUrl.startsWith(_backendUrl) || 
        originalUrl.startsWith('data:') ||
        originalUrl.startsWith('file:') ||
        originalUrl.startsWith('asset:')) {
      return originalUrl;
    }
    
    // Encode the URL to ensure it's safely passed as a query parameter
    final encodedUrl = Uri.encodeComponent(originalUrl);
    return '$_backendUrl/api/proxy-image/?url=$encodedUrl';
  }
} 