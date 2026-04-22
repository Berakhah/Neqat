import 'package:frontend/shared/domain/utils/either.dart';
import 'package:frontend/shared/domain/error/failure.dart';
import 'package:frontend/features/admin/domain/entities/comment.dart';
import 'package:frontend/features/admin/domain/repositories/admin_repository.dart';

class ApproveComment {
  final AdminRepository repository;

  ApproveComment(this.repository);

  Future<Either<Failure, Comment>> call({required String commentId, String? notes}) {
    return repository.approveComment(commentId, notes: notes);
  }
} 