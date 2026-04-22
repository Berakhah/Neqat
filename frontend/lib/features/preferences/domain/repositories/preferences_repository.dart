import 'package:frontend/shared/domain/utils/either.dart';
import 'package:frontend/shared/domain/error/failure.dart';

import '../entities/tag.dart';
import '../entities/user_preference.dart';

abstract class PreferencesRepository {
  Future<Either<Failure, List<Tag>>> getTags();
  Future<Either<Failure, List<UserPreference>>> getUserPreferences();
  Future<Either<Failure, List<UserPreference>>> updatePreferences(
      List<Map<String, dynamic>> updates);
} 