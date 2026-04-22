import 'package:frontend/shared/domain/utils/either.dart';
import 'package:frontend/shared/domain/error/failure.dart';
import 'package:frontend/features/admin/domain/entities/post.dart';
import 'package:frontend/features/admin/domain/repositories/admin_repository.dart';

class RejectPost {
  final AdminRepository repository;

  RejectPost(this.repository);

  Future<Either<Failure, Post>> call({required String postId, required String notes}) {
    return repository.rejectPost(postId, notes: notes);
  }
} 