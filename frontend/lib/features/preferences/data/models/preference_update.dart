class PreferenceUpdate {
  final String tagId;
  final int preferenceLevel;

  PreferenceUpdate({
    required this.tagId,
    required this.preferenceLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'tag_id': tagId,
      'preference_level': preferenceLevel,
    };
  }
} 