import 'package:dartz/dartz.dart';
import 'package:frontend/shared/domain/error/failure.dart';
import 'package:frontend/features/admin/domain/entities/content_flag.dart';
import 'package:frontend/features/admin/domain/repositories/admin_repository.dart';

class GetUnresolvedFlags {
  final AdminRepository repository;

  GetUnresolvedFlags(this.repository);

  Future<Either<Failure, List<ContentFlag>>> call({int page = 1}) {
    return repository.getContentFlags(resolved: false, page: page);
  }
} 