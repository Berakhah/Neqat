import 'package:frontend/features/admin/domain/entities/post.dart';

class PostModel extends Post {
  PostModel({
    required String id,
    required String createdBy,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String status,
    required String title,
    required String content,
    String? imageUrl,
    String? moderationNotes,
    String? moderatedBy,
    DateTime? moderatedAt,
  }) : super(
          id: id,
          createdBy: createdBy,
          createdAt: createdAt,
          updatedAt: updatedAt,
          status: status,
          title: title,
          content: content,
          imageUrl: imageUrl,
          moderationNotes: moderationNotes,
          moderatedBy: moderatedBy,
          moderatedAt: moderatedAt,
        );

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'],
      createdBy: json['created_by']['username'] ?? 'Unknown',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      status: json['status'],
      title: json['title'],
      content: json['content'],
      imageUrl: json['image'],
      moderationNotes: json['moderation_notes'],
      moderatedBy: json['moderated_by'] != null ? json['moderated_by']['username'] : null,
      moderatedAt: json['moderated_at'] != null ? DateTime.parse(json['moderated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'image': imageUrl,
      'status': status,
      'moderation_notes': moderationNotes,
    };
  }
} 