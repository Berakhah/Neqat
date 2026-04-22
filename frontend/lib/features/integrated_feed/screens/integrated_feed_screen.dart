import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/integrated_feed/providers/integrated_feed_provider.dart';
import 'package:frontend/features/integrated_feed/widgets/integrated_feed_card.dart';

class IntegratedFeedScreen extends ConsumerStatefulWidget {
  const IntegratedFeedScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<IntegratedFeedScreen> createState() => _IntegratedFeedScreenState();
}

class _IntegratedFeedScreenState extends ConsumerState<IntegratedFeedScreen> {
  String? _currentFilter;
  final Set<String> _viewedItems = {};
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final integratedFeedAsync = ref.watch(integratedFeedProvider);
    
    // Get the filtered feed
    final filteredFeed = ref.watch(filteredIntegratedFeedProvider(_currentFilter));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('News Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh news data
              ref.refresh(integratedFeedProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // All filter
                FilterChip(
                  label: const Text('All'),
                  selected: _currentFilter == null,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _currentFilter = null);
                    }
                  },
                ),
                const SizedBox(width: 8),
                
                // News filter
                FilterChip(
                  label: const Text('News'),
                  selected: _currentFilter == 'news',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _currentFilter = 'news');
                    }
                  },
                ),
                
                // Add more category filters based on available tags
                // This would be dynamically generated based on your tag data
              ],
            ),
          ),
          
          // Content area
          Expanded(
            child: integratedFeedAsync.when(
              data: (_) {
                if (filteredFeed.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No content available',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try changing the filter or refreshing',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.refresh(integratedFeedProvider);
                  },
                  child: ListView.builder(
                    itemCount: filteredFeed.length,
                    itemBuilder: (context, index) {
                      final item = filteredFeed[index];
                      final itemId = item['id'] as String;
                      
                      // Track item view if not already viewed
                      if (!_viewedItems.contains(itemId)) {
                        _viewedItems.add(itemId);
                        // TODO: Add tracking functionality if needed
                      }
                      
                      return IntegratedFeedCard(item: item);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading feed',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          ref.refresh(integratedFeedProvider);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 