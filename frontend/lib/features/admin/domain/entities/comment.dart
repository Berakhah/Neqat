import 'content_item.dart';

class Comment extends ContentItem {
  final String postId;
  final String content;
  final String? parentCommentId;

  Comment({
    required super.id,
    required super.createdBy,
    required super.createdAt,
    required super.updatedAt,
    required super.status,
    required this.postId,
    required this.content,
    this.parentCommentId,
    super.moderationNotes,
    super.moderatedBy,
    super.moderatedAt,
  });
} 