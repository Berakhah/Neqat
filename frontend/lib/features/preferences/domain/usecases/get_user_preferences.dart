import 'package:frontend/shared/domain/utils/either.dart';
import 'package:frontend/shared/domain/error/failure.dart';

import '../entities/user_preference.dart';
import '../repositories/preferences_repository.dart';

class GetUserPreferences {
  final PreferencesRepository repository;

  GetUserPreferences(this.repository);

  Future<Either<Failure, List<UserPreference>>> call() {
    return repository.getUserPreferences();
  }
} 