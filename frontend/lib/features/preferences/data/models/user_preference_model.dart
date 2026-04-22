import '../../domain/entities/user_preference.dart';
import '../../domain/entities/tag.dart';
import 'tag_model.dart';

class UserPreferenceModel extends UserPreference {
  const UserPreferenceModel({
    required String id,
    required Tag tag,
    required int preferenceLevel,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(
          id: id,
          tag: tag,
          preferenceLevel: preferenceLevel,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory UserPreferenceModel.fromJson(Map<String, dynamic> json) {
    return UserPreferenceModel(
      id: json['id'],
      tag: json['tag'] is Map<String, dynamic> 
          ? TagModel.fromJson(json['tag']) 
          : TagModel(
              id: json['tag'],
              name: json['tag_name'] ?? 'Unknown Tag',
              description: null,
            ),
      preferenceLevel: json['preference_level'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tag': tag.id,
      'preference_level': preferenceLevel,
    };
  }

  factory UserPreferenceModel.fromEntity(UserPreference preference) {
    return UserPreferenceModel(
      id: preference.id,
      tag: preference.tag,
      preferenceLevel: preference.preferenceLevel,
      createdAt: preference.createdAt,
      updatedAt: preference.updatedAt,
    );
  }
} 