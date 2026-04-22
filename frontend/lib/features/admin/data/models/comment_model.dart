import 'package:frontend/features/admin/domain/entities/comment.dart';

class CommentModel extends Comment {
  CommentModel({
    required String id,
    required String createdBy,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String status,
    required String postId,
    required String content,
    String? parentCommentId,
    String? moderationNotes,
    String? moderatedBy,
    DateTime? moderatedAt,
  }) : super(
          id: id,
          createdBy: createdBy,
          createdAt: createdAt,
          updatedAt: updatedAt,
          status: status,
          postId: postId,
          content: content,
          parentCommentId: parentCommentId,
          moderationNotes: moderationNotes,
          moderatedBy: moderatedBy,
          moderatedAt: moderatedAt,
        );

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'],
      createdBy: json['created_by'] ?? 'Unknown',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      status: json['status'],
      postId: json['post'],
      content: json['content'],
      parentCommentId: json['parent_comment'],
      moderationNotes: json['moderation_notes'],
      moderatedBy: json['moderated_by'],
      moderatedAt: json['moderated_at'] != null ? DateTime.parse(json['moderated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post': postId,
      'content': content,
      'parent_comment': parentCommentId,
      'status': status,
      'moderation_notes': moderationNotes,
    };
  }
} 