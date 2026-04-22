import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/admin/domain/entities/post.dart';
import 'package:frontend/features/admin/presentation/controllers/content_moderation_controller.dart';

class ContentModerationPage extends ConsumerStatefulWidget {
  const ContentModerationPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ContentModerationPage> createState() => _ContentModerationPageState();
}

class _ContentModerationPageState extends ConsumerState<ContentModerationPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _notesController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    Future.microtask(() {
      ref.read(pendingPostsProvider.notifier).loadPendingPosts();
      ref.read(pendingCommentsProvider.notifier).loadPendingComments();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Moderation'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Posts'),
            Tab(text: 'Comments'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostsTab(),
          _buildCommentsTab(),
        ],
      ),
    );
  }
  
  Widget _buildPostsTab() {
    final postsState = ref.watch(pendingPostsProvider);
    
    return postsState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text(
          'Error loading posts: $error',
          style: const TextStyle(color: Colors.red),
        ),
      ),
      data: (posts) {
        if (posts.isEmpty) {
          return const Center(
            child: Text('No pending posts to moderate'),
          );
        }
        
        return RefreshIndicator(
          onRefresh: () async {
            await ref.read(pendingPostsProvider.notifier).loadPendingPosts();
          },
          child: ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return _buildPostCard(post);
            },
          ),
        );
      },
    );
  }
  
  Widget _buildPostCard(Post post) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              post.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('By ${post.createdBy} • ${post.createdAt.toString().substring(0, 10)}'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(post.content),
          ),
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Image.network(
                post.imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.broken_image, size: 100, color: Colors.grey),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.check, color: Colors.green),
                  label: const Text('Approve'),
                  onPressed: () => _showApproveDialog(post.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade50,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text('Reject'),
                  onPressed: () => _showRejectDialog(post.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCommentsTab() {
    final commentsState = ref.watch(pendingCommentsProvider);
    
    return commentsState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text(
          'Error loading comments: $error',
          style: const TextStyle(color: Colors.red),
        ),
      ),
      data: (comments) {
        if (comments.isEmpty) {
          return const Center(
            child: Text('No pending comments to moderate'),
          );
        }
        
        return RefreshIndicator(
          onRefresh: () async {
            await ref.read(pendingCommentsProvider.notifier).loadPendingComments();
          },
          child: ListView.builder(
            itemCount: comments.length,
            itemBuilder: (context, index) {
              final comment = comments[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text(
                        'Comment on Post #${comment.postId}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('By ${comment.createdBy} • ${comment.createdAt.toString().substring(0, 10)}'),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(comment.content),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check, color: Colors.green),
                            label: const Text('Approve'),
                            onPressed: () => _showApproveCommentDialog(comment.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade50,
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.close, color: Colors.red),
                            label: const Text('Reject'),
                            onPressed: () => _showRejectCommentDialog(comment.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade50,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
  
  void _showApproveDialog(String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to approve this post?'),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _notesController.clear();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final notes = _notesController.text.trim();
              final success = await ref.read(pendingPostsProvider.notifier).approvePost(
                postId,
                notes: notes.isNotEmpty ? notes : null,
              );
              
              if (context.mounted) {
                Navigator.of(context).pop();
                _notesController.clear();
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post approved successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to approve post'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }
  
  void _showRejectDialog(String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to reject this post?'),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection (required)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _notesController.clear();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final notes = _notesController.text.trim();
              if (notes.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason for rejection'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              final success = await ref.read(pendingPostsProvider.notifier).rejectPost(
                postId,
                notes: notes,
              );
              
              if (context.mounted) {
                Navigator.of(context).pop();
                _notesController.clear();
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post rejected successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to reject post'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
  
  void _showApproveCommentDialog(String commentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Comment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to approve this comment?'),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _notesController.clear();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final notes = _notesController.text.trim();
              final success = await ref.read(pendingCommentsProvider.notifier).approveComment(
                commentId,
                notes: notes.isNotEmpty ? notes : null,
              );
              
              if (context.mounted) {
                Navigator.of(context).pop();
                _notesController.clear();
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Comment approved successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to approve comment'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }
  
  void _showRejectCommentDialog(String commentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Comment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to reject this comment?'),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection (required)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _notesController.clear();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final notes = _notesController.text.trim();
              if (notes.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason for rejection'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              final success = await ref.read(pendingCommentsProvider.notifier).rejectComment(
                commentId,
                notes: notes,
              );
              
              if (context.mounted) {
                Navigator.of(context).pop();
                _notesController.clear();
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Comment rejected successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to reject comment'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
} 