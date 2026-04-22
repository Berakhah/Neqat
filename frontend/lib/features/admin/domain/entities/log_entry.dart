class LogEntry {
  final String id;
  final String type;
  final String action;
  final String details;
  final String outcome;
  final String timestamp;
  final String? user;
  final String? ipAddress;
  final String? userAgent;
  final String? objectType;
  final String? objectId;
  final String? actionTaken;
  final String? moderator;
  final String? beforeStatus;
  final String? afterStatus;
  final String? reason;

  LogEntry({
    required this.id,
    required this.type,
    required this.action,
    required this.details,
    required this.outcome,
    required this.timestamp,
    this.user,
    this.ipAddress,
    this.userAgent,
    this.objectType,
    this.objectId,
    this.actionTaken,
    this.moderator,
    this.beforeStatus,
    this.afterStatus,
    this.reason,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      id: json['id'],
      type: json['type'] ?? 'system_log', // Default to system_log if not specified
      action: json['action'] ?? '',
      details: json['details'] ?? '',
      outcome: json['outcome'] ?? '',
      timestamp: json['timestamp'] ?? '',
      user: json['user'],
      ipAddress: json['ip_address'],
      userAgent: json['user_agent'],
      objectType: json['object_type'],
      objectId: json['object_id'],
      actionTaken: json['action_taken'],
      moderator: json['moderator'],
      beforeStatus: json['before_status'],
      afterStatus: json['after_status'],
      reason: json['reason'],
    );
  }
} 