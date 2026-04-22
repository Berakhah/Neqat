import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/preferences/presentation/controllers/preferences_controller.dart';
import 'package:frontend/features/preferences/presentation/providers/preferences_providers.dart';

/// Provider that combines news articles and potentially other feed sources
final integratedFeedProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // Get personalized news
  final personalizedNewsFuture = ref.watch(personalizedNewsProvider.future);
  
  try {
    // Wait for personalized news to load
    final List<dynamic> rawNewsArticles = await personalizedNewsFuture;
    
    // Convert raw news to the right format
    final List<Map<String, dynamic>> newsArticles = rawNewsArticles
        .map((item) => item as Map<String, dynamic>)
        .toList();
    
    // Sort by timestamp (newest first)
    newsArticles.sort((a, b) {
      final dateA = DateTime.parse(a['timestamp']);
      final dateB = DateTime.parse(b['timestamp']);
      return dateB.compareTo(dateA);
    });
    
    return newsArticles;
  } catch (e) {
    // If news loading fails, return empty list
    return [];
  }
});

/// Provider to get a filtered version of the integrated feed
final filteredIntegratedFeedProvider = Provider.family<List<Map<String, dynamic>>, String?>((ref, filter) {
  final integratedFeedAsync = ref.watch(integratedFeedProvider);
  
  return integratedFeedAsync.when(
    data: (feed) {
      if (filter == null) {
        return feed;
      } else if (filter == 'news') {
        return feed;
      } else {
        // Filter by category or tag
        return feed.where((item) => 
          item['tags'] != null && 
          (item['tags'] as List).any((tag) => 
            tag is Map && tag['name'] == filter
          )
        ).toList();
      }
    },
    loading: () => [],
    error: (_, __) => [],
  );
}); 