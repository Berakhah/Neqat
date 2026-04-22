import 'package:frontend/shared/domain/utils/either.dart';
import 'package:frontend/shared/domain/error/failure.dart';

import '../entities/tag.dart';
import '../repositories/preferences_repository.dart';

class GetTags {
  final PreferencesRepository repository;

  GetTags(this.repository);

  Future<Either<Failure, List<Tag>>> call() {
    return repository.getTags();
  }
} 