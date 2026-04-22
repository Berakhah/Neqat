class ContentInteraction {
  final String contentType; // NEWS or POST
  final String contentId;
  final String interactionType; // VIEW, LIKE, BOOKMARK, SHARE, CLICK, TIME_SPENT
  final double interactionValue;

  ContentInteraction({
    required this.contentType,
    required this.contentId,
    required this.interactionType,
    this.interactionValue = 1.0,
  });

  factory ContentInteraction.fromJson(Map<String, dynamic> json) {
    return ContentInteraction(
      contentType: json['content_type'],
      contentId: json['content_id'],
      interactionType: json['interaction_type'],
      interactionValue: json['interaction_value']?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content_type': contentType,
      'content_id': contentId,
      'interaction_type': interactionType,
      'interaction_value': interactionValue,
    };
  }

  // Convenience constructors for common interaction types
  factory ContentInteraction.view(String contentType, String contentId) {
    return ContentInteraction(
      contentType: contentType,
      contentId: contentId,
      interactionType: 'VIEW',
    );
  }

  factory ContentInteraction.like(String contentType, String contentId) {
    return ContentInteraction(
      contentType: contentType,
      contentId: contentId,
      interactionType: 'LIKE',
    );
  }

  factory ContentInteraction.bookmark(String contentType, String contentId) {
    return ContentInteraction(
      contentType: contentType,
      contentId: contentId,
      interactionType: 'BOOKMARK',
    );
  }

  factory ContentInteraction.share(String contentType, String contentId) {
    return ContentInteraction(
      contentType: contentType,
      contentId: contentId,
      interactionType: 'SHARE',
    );
  }

  factory ContentInteraction.timeSpent(String contentType, String contentId, double seconds) {
    return ContentInteraction(
      contentType: contentType,
      contentId: contentId,
      interactionType: 'TIME_SPENT',
      interactionValue: seconds, // Time spent in seconds
    );
  }
} 