class ContentFlag {
  final String id;
  final String contentType;
  final String contentId;
  final String reportedBy;
  final String reason;
  final String? description;
  final DateTime createdAt;
  final bool resolved;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final String? resolutionNotes;

  ContentFlag({
    required this.id,
    required this.contentType,
    required this.contentId,
    required this.reportedBy,
    required this.reason,
    required this.createdAt,
    required this.resolved,
    this.description,
    this.resolvedBy,
    this.resolvedAt,
    this.resolutionNotes,
  });
} 