import 'package:frontend/shared/domain/utils/either.dart';
import 'package:frontend/shared/domain/error/failure.dart';
import 'package:frontend/features/admin/domain/entities/content_flag.dart';
import 'package:frontend/features/admin/domain/repositories/admin_repository.dart';

class ResolveContentFlag {
  final AdminRepository repository;

  ResolveContentFlag(this.repository);

  Future<Either<Failure, ContentFlag>> call({required String flagId, required String notes}) {
    return repository.resolveContentFlag(flagId, notes: notes);
  }
} 