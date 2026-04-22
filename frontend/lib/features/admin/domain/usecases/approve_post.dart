import 'package:frontend/shared/domain/utils/either.dart';
import 'package:frontend/shared/domain/error/failure.dart';
import 'package:frontend/features/admin/domain/entities/post.dart';
import 'package:frontend/features/admin/domain/repositories/admin_repository.dart';

class ApprovePost {
  final AdminRepository repository;

  ApprovePost(this.repository);

  Future<Either<Failure, Post>> call({required String postId, String? notes}) {
    return repository.approvePost(postId, notes: notes);
  }
} 