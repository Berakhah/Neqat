import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/admin/domain/entities/post.dart';
import 'package:frontend/features/admin/presentation/providers/admin_providers.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:frontend/features/admin/domain/entities/moderation_history.dart';

class ContentModerationPage extends ConsumerStatefulWidget {
  const ContentModerationPage({super.key});

  @override
  ConsumerState<ContentModerationPage> createState() => _ContentModerationPageState();
}

class _ContentModerationPageState extends ConsumerState<ContentModerationPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _notesController = TextEditingController();
  
  // Bulk selection state
  Set<String> selectedPostIds = {};
  Set<String> selectedCommentIds = {};
  bool selectAllPosts = false;
  bool selectAllComments = false;
  
  DateTime? _lastUpdatedPosts;
  DateTime? _lastUpdatedComments;
  Timer? _refreshTimer;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(_refreshAll);
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _refreshAll());
  }
  
  void _refreshAll() {
    _refreshPosts();
    _refreshComments();
  }
  
  void _refreshPosts() {
    setState(() {
      _lastUpdatedPosts = DateTime.now();
    });
      ref.read(pendingPostsProvider.notifier).loadPendingPosts();
  }
  
  void _refreshComments() {
    setState(() {
      _lastUpdatedComments = DateTime.now();
    });
      ref.read(pendingCommentsProvider.notifier).loadPendingComments();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Moderation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAll,
            tooltip: 'Refresh',
          ),
        ],
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
    final adminRepository = ref.read(adminRepositoryProvider);
    
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
        
        return Column(
          children: [
            if (_lastUpdatedPosts != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                child: Text(
                  'Last updated: ${DateFormat.Hms().format(_lastUpdatedPosts!)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            if (selectedPostIds.isNotEmpty)
              BulkActionBar(
                selectedCount: selectedPostIds.length,
                onApprove: _onBulkApprovePosts,
                onReject: _onBulkRejectPosts,
              ),
            CheckboxListTile(
              title: const Text('Select All'),
              value: selectAllPosts,
              onChanged: (checked) {
                setState(() {
                  selectAllPosts = checked ?? false;
                  if (selectAllPosts) {
                    selectedPostIds = posts.map((p) => p.id).toSet();
                  } else {
                    selectedPostIds.clear();
                  }
                });
              },
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _refreshPosts(),
          child: ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
                            leading: Checkbox(
                              value: selectedPostIds.contains(post.id),
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    selectedPostIds.add(post.id);
                                  } else {
                                    selectedPostIds.remove(post.id);
                                  }
                                  selectAllPosts = selectedPostIds.length == posts.length;
                                });
                              },
                            ),
            title: Text(
              post.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('By ${post.createdBy} • ${post.createdAt.toString().substring(0, 10)}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.history),
                              tooltip: 'View Moderation History',
                              onPressed: () => _showModerationHistoryDialog('POST', post.id),
                            ),
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
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check, color: Colors.green),
                    label: const Text('Approve'),
                    onPressed: () => _showApproveDialog(post.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade50,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Reject'),
                    onPressed: () => _showRejectDialog(post.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                    ),
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
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildCommentsTab() {
    final commentsState = ref.watch(pendingCommentsProvider);
    final adminRepository = ref.read(adminRepositoryProvider);
    
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
        
        return Column(
          children: [
            if (_lastUpdatedComments != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                child: Text(
                  'Last updated: ${DateFormat.Hms().format(_lastUpdatedComments!)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            if (selectedCommentIds.isNotEmpty)
              BulkActionBar(
                selectedCount: selectedCommentIds.length,
                onApprove: _onBulkApproveComments,
                onReject: _onBulkRejectComments,
              ),
            CheckboxListTile(
              title: const Text('Select All'),
              value: selectAllComments,
              onChanged: (checked) {
                setState(() {
                  selectAllComments = checked ?? false;
                  if (selectAllComments) {
                    selectedCommentIds = comments.map((c) => c.id).toSet();
                  } else {
                    selectedCommentIds.clear();
                  }
                });
              },
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _refreshComments(),
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
                            leading: Checkbox(
                              value: selectedCommentIds.contains(comment.id),
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    selectedCommentIds.add(comment.id);
                                  } else {
                                    selectedCommentIds.remove(comment.id);
                                  }
                                  selectAllComments = selectedCommentIds.length == comments.length;
                                });
                              },
                            ),
                      title: Text(
                        'Comment on Post #${comment.postId}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('By ${comment.createdBy} • ${comment.createdAt.toString().substring(0, 10)}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.history),
                              tooltip: 'View Moderation History',
                              onPressed: () => _showModerationHistoryDialog('COMMENT', comment.id),
                            ),
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
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.check, color: Colors.green),
                              label: const Text('Approve'),
                              onPressed: () => _showApproveCommentDialog(comment.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade50,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.close, color: Colors.red),
                              label: const Text('Reject'),
                              onPressed: () => _showRejectCommentDialog(comment.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade50,
                              ),
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
              ),
            ),
          ],
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
                  final state = ref.read(pendingPostsProvider);
                  final errorMsg = state is AsyncError ? state.error.toString() : 'Failed to approve post';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMsg),
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
                  final state = ref.read(pendingPostsProvider);
                  final errorMsg = state is AsyncError ? state.error.toString() : 'Failed to reject post';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMsg),
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
                  final state = ref.read(pendingCommentsProvider);
                  final errorMsg = state is AsyncError ? state.error.toString() : 'Failed to approve comment';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMsg),
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
                  final state = ref.read(pendingCommentsProvider);
                  final errorMsg = state is AsyncError ? state.error.toString() : 'Failed to reject comment';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMsg),
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

  void _onBulkApprovePosts() async {
    final success = await ref.read(pendingPostsProvider.notifier).bulkApprovePosts(selectedPostIds.toList());
    if (success) {
      setState(() {
        selectedPostIds.clear();
        selectAllPosts = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Posts approved')));
      }
    }
  }

  void _onBulkRejectPosts() async {
    final notes = await _showNotesDialog();
    if (notes != null && notes.isNotEmpty) {
      final success = await ref.read(pendingPostsProvider.notifier).bulkRejectPosts(selectedPostIds.toList(), notes);
      if (success) {
        setState(() {
          selectedPostIds.clear();
          selectAllPosts = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Posts rejected')));
        }
      }
    }
  }

  void _onBulkApproveComments() async {
    final success = await ref.read(pendingCommentsProvider.notifier).bulkApproveComments(selectedCommentIds.toList());
    if (success) {
      setState(() {
        selectedCommentIds.clear();
        selectAllComments = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comments approved')));
      }
    }
  }

  void _onBulkRejectComments() async {
    final notes = await _showNotesDialog();
    if (notes != null && notes.isNotEmpty) {
      final success = await ref.read(pendingCommentsProvider.notifier).bulkRejectComments(selectedCommentIds.toList(), notes);
      if (success) {
        setState(() {
          selectedCommentIds.clear();
          selectAllComments = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comments rejected')));
        }
      }
    }
  }

  Future<String?> _showNotesDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reason for rejection'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Notes'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showModerationHistoryDialog(String contentType, String contentId) {
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<List<ModerationHistory>>(
        future: ref.read(adminRepositoryProvider).fetchModerationHistory(contentType: contentType, contentId: contentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AlertDialog(
              title: Text('Moderation History'),
              content: SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
            );
          } else if (snapshot.hasError) {
            return AlertDialog(
              title: const Text('Moderation History'),
              content: Text('Error: \\${snapshot.error}'),
              actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
            );
          } else {
            final history = snapshot.data ?? [];
            return AlertDialog(
              title: const Text('Moderation History'),
              content: SizedBox(
                width: 400,
                height: 300,
                child: history.isEmpty
                    ? const Center(child: Text('No moderation history found.'))
                    : ListView.separated(
                        itemCount: history.length,
                        separatorBuilder: (context, i) => const Divider(),
                        itemBuilder: (context, i) {
                          final h = history[i];
                          return ListTile(
                            leading: Icon(Icons.event_note, color: Colors.blueGrey),
                            title: Text(h.actionDisplay),
                            subtitle: Text('By \\${h.actor} on \\${h.timestamp.toLocal()}'),
                            trailing: h.notes != null && h.notes!.isNotEmpty
                                ? Tooltip(message: h.notes!, child: const Icon(Icons.sticky_note_2, color: Colors.amber))
                                : null,
                          );
                        },
                      ),
              ),
              actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
            );
          }
        },
      ),
    );
  }
}

class BulkActionBar extends StatelessWidget {
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final int selectedCount;
  const BulkActionBar({
    required this.onApprove,
    required this.onReject,
    required this.selectedCount,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blueGrey[50],
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Text('$selectedCount selected'),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Approve'),
              onPressed: onApprove,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade50),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.close),
              label: const Text('Reject'),
              onPressed: onReject,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50),
            ),
          ],
        ),
      ),
    );
  }
} 