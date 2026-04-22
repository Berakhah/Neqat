class ModerationHistory {
  final String id;
  final String contentType;
  final String contentTypeDisplay;
  final String contentId;
  final String action;
  final String actionDisplay;
  final String actor;
  final DateTime timestamp;
  final String? notes;
  final Map<String, dynamic>? before;
  final Map<String, dynamic>? after;

  ModerationHistory({
    required this.id,
    required this.contentType,
    required this.contentTypeDisplay,
    required this.contentId,
    required this.action,
    required this.actionDisplay,
    required this.actor,
    required this.timestamp,
    this.notes,
    this.before,
    this.after,
  });

  factory ModerationHistory.fromJson(Map<String, dynamic> json) {
    return ModerationHistory(
      id: json['id'],
      contentType: json['content_type'],
      contentTypeDisplay: json['content_type_display'] ?? json['content_type'],
      contentId: json['content_id'],
      action: json['action'],
      actionDisplay: json['action_display'] ?? json['action'],
      actor: json['actor'] ?? 'Unknown',
      timestamp: DateTime.parse(json['timestamp']),
      notes: json['notes'],
      before: json['before'],
      after: json['after'],
    );
  }
} 