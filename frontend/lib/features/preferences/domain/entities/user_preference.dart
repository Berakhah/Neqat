import 'tag.dart';

class UserPreference {
  final String id;
  final Tag tag;
  final int preferenceLevel;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserPreference({
    required this.id,
    required this.tag,
    required this.preferenceLevel,
    required this.createdAt,
    required this.updatedAt,
  });

  UserPreference copyWith({
    String? id,
    Tag? tag,
    int? preferenceLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserPreference(
      id: id ?? this.id,
      tag: tag ?? this.tag,
      preferenceLevel: preferenceLevel ?? this.preferenceLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is UserPreference &&
    runtimeType == other.runtimeType &&
    id == other.id;

  @override
  int get hashCode => id.hashCode;
} 