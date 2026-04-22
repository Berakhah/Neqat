import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/preferences_providers.dart';
import '../controllers/preferences_controller.dart';

class PersonalizedContentScreen extends ConsumerStatefulWidget {
  const PersonalizedContentScreen({super.key});

  @override
  ConsumerState<PersonalizedContentScreen> createState() => _PersonalizedContentScreenState();
}

class _PersonalizedContentScreenState extends ConsumerState<PersonalizedContentScreen> {
  // Track viewed articles for logging interactions
  final Set<String> _viewedArticles = {};
  
  @override
  Widget build(BuildContext context) {
    final personalizedNews = ref.watch(personalizedNewsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('For You'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(personalizedNewsProvider);
        },
        child: personalizedNews.when(
          data: (newsList) {
            if (newsList.isEmpty) {
              return const Center(
                child: Text('No personalized content available yet'),
              );
            }
            
            return ListView.builder(
              itemCount: newsList.length,
              itemBuilder: (context, index) {
                final news = newsList[index];
                final newsId = news['id'] as String;
                
                // Track this article as viewed if not already tracked
                if (!_viewedArticles.contains(newsId)) {
                  _viewedArticles.add(newsId);
                  // Record the interaction
                  ref.read(preferencesControllerProvider.notifier).trackContentView('NEWS', newsId);
                }
                
                return _buildNewsCard(news);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Error loading personalized content: $error'),
          ),
        ),
      ),
    );
  }
  
  Widget _buildNewsCard(Map<String, dynamic> news) {
    final DateTime timestamp = DateTime.parse(news['timestamp']);
    final String formattedDate = DateFormat('MMM d, yyyy').format(timestamp);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (news['image_url'] != null)
            SizedBox(
              width: double.infinity,
              height: 180,
              child: Image.network(
                news['image_url'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 40),
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  news['title'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  news['content'].length > 150
                      ? '${news['content'].substring(0, 150)}...'
                      : news['content'],
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      news['source'] ?? 'Unknown source',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildTagChips(news),
                const SizedBox(height: 8),
                _buildInteractionButtons(news),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTagChips(Map<String, dynamic> news) {
    final List<dynamic> tags = news['tags'] ?? [];
    
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: tags.map((tag) {
        return Chip(
          label: Text(
            tag['name'],
            style: const TextStyle(fontSize: 12),
          ),
          backgroundColor: Colors.grey[200],
          padding: const EdgeInsets.all(4),
        );
      }).toList(),
    );
  }
  
  Widget _buildInteractionButtons(Map<String, dynamic> news) {
    final newsId = news['id'] as String;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildInteractionButton(
          icon: Icons.thumb_up_outlined,
          label: 'Like',
          onPressed: () {
            ref.read(preferencesControllerProvider.notifier).trackContentLike('NEWS', newsId);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You liked this article')),
            );
          },
        ),
        _buildInteractionButton(
          icon: Icons.bookmark_outline,
          label: 'Save',
          onPressed: () {
            ref.read(preferencesControllerProvider.notifier).trackContentBookmark('NEWS', newsId);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Article saved to your bookmarks')),
            );
          },
        ),
        _buildInteractionButton(
          icon: Icons.share_outlined,
          label: 'Share',
          onPressed: () {
            ref.read(preferencesControllerProvider.notifier).trackContentShare('NEWS', newsId);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Share functionality will be implemented soon')),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildInteractionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
} 