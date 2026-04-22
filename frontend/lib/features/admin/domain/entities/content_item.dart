abstract class ContentItem {
  final String id;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status;
  final String? moderationNotes;
  final String? moderatedBy;
  final DateTime? moderatedAt;

  ContentItem({
    required this.id,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    this.moderationNotes,
    this.moderatedBy,
    this.moderatedAt,
  });
} 