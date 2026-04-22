import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/preferences/presentation/controllers/preferences_controller.dart';
import 'package:frontend/features/preferences/presentation/providers/preferences_providers.dart';
import 'package:intl/intl.dart';

class IntegratedFeedCard extends ConsumerWidget {
  final Map<String, dynamic> item;
  
  const IntegratedFeedCard({
    Key? key,
    required this.item,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final String source = item['source'] ?? '';
    final String title = item['title'] ?? '';
    final String content = item['content'] ?? '';
    final DateTime timestamp = DateTime.parse(item['timestamp']);
    final String formattedDate = DateFormat('MMM d, yyyy - HH:mm').format(timestamp);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with source info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.primaryContainer,
            child: Row(
              children: [
                Icon(
                  Icons.article,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    source,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                Text(
                  formattedDate,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          
          // Image if available
          if (item['image_url'] != null)
            SizedBox(
              width: double.infinity,
              height: 180,
              child: Image.network(
                item['image_url'],
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
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          
          // Tags
          if (item['tags'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: (item['tags'] as List<dynamic>).map((tag) {
                  return Chip(
                    label: Text(
                      tag['name'],
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.grey[200],
                    padding: const EdgeInsets.all(4),
                  );
                }).toList(),
              ),
            ),
          
          // Interaction buttons
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInteractionButton(
                  context,
                  ref,
                  icon: Icons.thumb_up_outlined,
                  label: 'Like',
                  onPressed: () {
                    final contentId = item['id'];
                    ref.read(preferencesControllerProvider.notifier)
                        .trackContentLike('NEWS', contentId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('You liked this item')),
                    );
                  },
                ),
                _buildInteractionButton(
                  context,
                  ref,
                  icon: Icons.bookmark_outline,
                  label: 'Save',
                  onPressed: () {
                    final contentId = item['id'];
                    ref.read(preferencesControllerProvider.notifier)
                        .trackContentBookmark('NEWS', contentId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Item saved to your bookmarks')),
                    );
                  },
                ),
                _buildInteractionButton(
                  context,
                  ref,
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onPressed: () {
                    final contentId = item['id'];
                    ref.read(preferencesControllerProvider.notifier)
                        .trackContentShare('NEWS', contentId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Share functionality will be implemented soon')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInteractionButton(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
} 