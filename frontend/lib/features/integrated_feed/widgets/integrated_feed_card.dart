import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/preferences/presentation/controllers/preferences_controller.dart';
import 'package:intl/intl.dart';
import 'package:frontend/app/providers/user_provider.dart';
import 'package:frontend/features/admin/data/datasources/admin_api_service.dart';
import 'package:frontend/features/integrated_feed/providers/integrated_feed_provider.dart';

class IntegratedFeedCard extends ConsumerWidget {
  final Map<String, dynamic> item;

  const IntegratedFeedCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final String source = item['source'] ?? '';
    final String title = item['title'] ?? '';
    final String content = item['content'] ?? '';
    final DateTime timestamp = DateTime.parse(item['timestamp']);
    final String formattedDate = DateFormat(
      'MMM d, yyyy - HH:mm',
    ).format(timestamp);
    final userState = ref.watch(userProvider);
    final String currentUsername = userState.userData?['username'] ?? '';
    final bool isOwner = item['created_by'] == currentUsername;
    final bool isAdmin = userState.isAdmin;

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
                Icon(Icons.article, size: 16, color: theme.colorScheme.primary),
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
                Text(formattedDate, style: theme.textTheme.bodySmall),
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
                children:
                    (item['tags'] as List<dynamic>).map((tag) {
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
                    ref
                        .read(preferencesControllerProvider.notifier)
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
                    ref
                        .read(preferencesControllerProvider.notifier)
                        .trackContentBookmark('NEWS', contentId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Item saved to your bookmarks'),
                      ),
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
                    ref
                        .read(preferencesControllerProvider.notifier)
                        .trackContentShare('NEWS', contentId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Share functionality will be implemented soon',
                        ),
                      ),
                    );
                  },
                ),
                _buildInteractionButton(
                  context,
                  ref,
                  icon: Icons.edit,
                  label: 'Edit',
                  onPressed: (isOwner || isAdmin)
                      ? () async {
                          final TextEditingController titleController = TextEditingController(text: item['title']);
                          final TextEditingController contentController = TextEditingController(text: item['content']);
                          final result = await showDialog<Map<String, String>>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Edit Post'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: titleController,
                                    decoration: const InputDecoration(labelText: 'Title'),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: contentController,
                                    decoration: const InputDecoration(labelText: 'Content'),
                                    maxLines: 3,
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop({
                                      'title': titleController.text,
                                      'content': contentController.text,
                                    });
                                  },
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          );
                          if (result != null) {
                            try {
                              final api = ref.read(adminApiServiceProvider);
                              await api.editPost(item['id'], result, admin: isAdmin);
                              ref.refresh(integratedFeedProvider);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Post updated successfully')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to update post: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        }
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('You are not allowed to edit this post.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        },
                  disabled: !(isOwner || isAdmin),
                ),
                _buildInteractionButton(
                  context,
                  ref,
                  icon: Icons.delete,
                  label: 'Delete',
                  onPressed: (isOwner || isAdmin)
                      ? () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Post'),
                              content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              final api = ref.read(adminApiServiceProvider);
                              await api.deletePost(item['id'], admin: isAdmin);
                              ref.refresh(integratedFeedProvider);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Post deleted successfully')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to delete post: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        }
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('You are not allowed to delete this post.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        },
                  disabled: !(isOwner || isAdmin),
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
    bool disabled = false,
  }) {
    return InkWell(
      onTap: disabled ? null : onPressed,
      child: Opacity(
        opacity: disabled ? 0.5 : 1.0,
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
      ),
    );
  }
}
