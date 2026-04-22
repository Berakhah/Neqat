import 'package:frontend/shared/domain/utils/either.dart';
import 'package:frontend/shared/domain/error/failure.dart';
import 'package:frontend/features/admin/domain/entities/post.dart';
import 'package:frontend/features/admin/domain/repositories/admin_repository.dart';

class GetPendingPosts {
  final AdminRepository repository;

  GetPendingPosts(this.repository);

  Future<Either<Failure, List<Post>>> call({int page = 1}) {
    return repository.getPosts(status: 'PENDING', page: page);
  }
} 