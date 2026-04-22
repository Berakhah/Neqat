import 'package:dartz/dartz.dart';
import 'package:frontend/shared/domain/error/failure.dart';
import 'package:frontend/features/admin/domain/entities/post.dart';
import 'package:frontend/features/admin/domain/entities/comment.dart';
import 'package:frontend/features/admin/domain/entities/content_flag.dart';
import 'package:frontend/features/admin/domain/entities/admin_user.dart';
import 'package:frontend/features/admin/domain/entities/dashboard_metrics.dart';
import '../entities/moderation_history.dart';

abstract class AdminRepository {
  // Posts
  Future<Either<Failure, List<Post>>> getPosts({String? status, int page = 1});
  Future<Either<Failure, Post>> approvePost(String postId, {String? notes});
  Future<Either<Failure, Post>> rejectPost(String postId, {required String notes});
  
  // Comments
  Future<Either<Failure, List<Comment>>> getComments({String? status, int page = 1});
  Future<Either<Failure, Comment>> approveComment(String commentId, {String? notes});
  Future<Either<Failure, Comment>> rejectComment(String commentId, {required String notes});
  
  // Content Flags
  Future<Either<Failure, List<ContentFlag>>> getContentFlags({bool? resolved, int page = 1});
  Future<Either<Failure, ContentFlag>> resolveContentFlag(String flagId, {required String notes});
  
  // Dashboard
  Future<Either<Failure, DashboardMetrics>> getDashboardData();
  
  // User Management
  Future<Either<Failure, List<AdminUser>>> getUsers({int page = 1});
  Future<Either<Failure, AdminUser>> updateUserStatus(String userId, {required bool isActive});

  Future<Either<Failure, int>> bulkApprovePosts(List<String> ids);
  Future<Either<Failure, int>> bulkRejectPosts(List<String> ids, String notes);
  Future<Either<Failure, int>> bulkApproveComments(List<String> ids);
  Future<Either<Failure, int>> bulkRejectComments(List<String> ids, String notes);

  Future<List<ModerationHistory>> fetchModerationHistory({required String contentType, required String contentId});
} 