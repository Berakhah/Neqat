import 'package:frontend/shared/domain/utils/either.dart';
import 'package:frontend/shared/domain/error/failure.dart';
import 'package:frontend/features/admin/domain/entities/comment.dart';
import 'package:frontend/features/admin/domain/repositories/admin_repository.dart';

class RejectComment {
  final AdminRepository repository;

  RejectComment(this.repository);

  Future<Either<Failure, Comment>> call({required String commentId, required String notes}) {
    return repository.rejectComment(commentId, notes: notes);
  }
} 