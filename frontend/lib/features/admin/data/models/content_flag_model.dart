import 'package:frontend/features/admin/domain/entities/content_flag.dart';

class ContentFlagModel extends ContentFlag {
  ContentFlagModel({
    required String id,
    required String contentType,
    required String contentId,
    required String reportedBy,
    required String reason,
    required DateTime createdAt,
    required bool resolved,
    String? description,
    String? resolvedBy,
    DateTime? resolvedAt,
    String? resolutionNotes,
  }) : super(
          id: id,
          contentType: contentType,
          contentId: contentId,
          reportedBy: reportedBy,
          reason: reason,
          createdAt: createdAt,
          resolved: resolved,
          description: description,
          resolvedBy: resolvedBy,
          resolvedAt: resolvedAt,
          resolutionNotes: resolutionNotes,
        );

  factory ContentFlagModel.fromJson(Map<String, dynamic> json) {
    return ContentFlagModel(
      id: json['id'],
      contentType: json['content_type'],
      contentId: json['content_id'],
      reportedBy: json['reported_by']['username'] ?? 'Unknown',
      reason: json['reason'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      resolved: json['resolved'] ?? false,
      resolvedBy: json['resolved_by'] != null ? json['resolved_by']['username'] : null,
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at']) : null,
      resolutionNotes: json['resolution_notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content_type': contentType,
      'content_id': contentId,
      'reason': reason,
      'description': description,
      'resolved': resolved,
      'resolution_notes': resolutionNotes,
    };
  }
} 