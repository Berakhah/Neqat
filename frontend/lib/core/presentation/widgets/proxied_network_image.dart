import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/network/image_proxy_service.dart';

/// A widget that displays a network image while handling CORS
/// by proxying requests through the backend
class ProxiedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, String, dynamic)? errorBuilder;
  final Widget? placeholder;
  final bool useCache;

  /// Service for proxying images
  final _imageProxyService = ImageProxyService();

  ProxiedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorBuilder,
    this.placeholder,
    this.useCache = true,
  });

  @override
  Widget build(BuildContext context) {
    // Get the proxied URL
    final String proxiedUrl = _imageProxyService.getProxiedImageUrl(imageUrl);

    // Default error widget
    final errorWidget = errorBuilder ??
        (context, url, error) => SvgPicture.asset(
              'images/neqat_logo/logo-color.svg',
              width: width,
              height: height,
            );

    // If caching is enabled, use CachedNetworkImage
    if (useCache) {
      return CachedNetworkImage(
        imageUrl: proxiedUrl,
        width: width,
        height: height,
        fit: fit,
        errorWidget: errorWidget,
        placeholder: (context, url) => placeholder ??
            Container(
              width: width,
              height: height,
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            ),
      );
    }

    // Otherwise use regular Image.network
    return Image.network(
      proxiedUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => 
          errorWidget(context, proxiedUrl, error),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return placeholder ??
            Container(
              width: width,
              height: height,
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
      },
    );
  }
} 