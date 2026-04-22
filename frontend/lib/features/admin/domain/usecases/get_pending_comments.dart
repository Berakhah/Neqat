import 'package:frontend/shared/domain/utils/either.dart';
import 'package:frontend/shared/domain/error/failure.dart';
import 'package:frontend/features/admin/domain/entities/comment.dart';
import 'package:frontend/features/admin/domain/repositories/admin_repository.dart';

class GetPendingComments {
  final AdminRepository repository;

  GetPendingComments(this.repository);

  Future<Either<Failure, List<Comment>>> call({int page = 1}) {
    return repository.getComments(status: 'PENDING', page: page);
  }
} 