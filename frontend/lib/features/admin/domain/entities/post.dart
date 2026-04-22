import 'content_item.dart';

class Post extends ContentItem {
  final String title;
  final String content;
  final String? imageUrl;

  Post({
    required super.id,
    required super.createdBy,
    required super.createdAt,
    required super.updatedAt,
    required super.status,
    required this.title,
    required this.content,
    this.imageUrl,
    super.moderationNotes,
    super.moderatedBy,
    super.moderatedAt,
  });
} 