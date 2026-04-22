import 'package:frontend/shared/domain/utils/either.dart';
import 'package:frontend/shared/domain/error/failure.dart';

import '../entities/user_preference.dart';
import '../repositories/preferences_repository.dart';

class UpdatePreferences {
  final PreferencesRepository repository;

  UpdatePreferences(this.repository);

  Future<Either<Failure, List<UserPreference>>> call(List<Map<String, dynamic>> updates) {
    return repository.updatePreferences(updates);
  }
} 