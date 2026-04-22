import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/features/admin/data/datasources/admin_api_service.dart';
import 'package:frontend/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:frontend/features/admin/domain/repositories/admin_repository.dart';
import 'package:frontend/features/admin/domain/usecases/approve_comment.dart';
import 'package:frontend/features/admin/domain/usecases/approve_post.dart';
import 'package:frontend/features/admin/domain/usecases/get_dashboard_data.dart';
import 'package:frontend/features/admin/domain/usecases/get_pending_comments.dart';
import 'package:frontend/features/admin/domain/usecases/get_pending_posts.dart';
import 'package:frontend/features/admin/domain/usecases/get_unresolved_flags.dart';
import 'package:frontend/features/admin/domain/usecases/reject_comment.dart';
import 'package:frontend/features/admin/domain/usecases/reject_post.dart';
import 'package:frontend/features/admin/domain/usecases/resolve_content_flag.dart';
import 'package:frontend/features/admin/presentation/controllers/content_moderation_controller.dart';
import 'package:frontend/features/admin/domain/entities/post.dart';
import 'package:frontend/features/admin/domain/entities/comment.dart';
import 'package:dartz/dartz.dart';
import 'package:frontend/shared/domain/error/failure.dart';

// DioClient Provider
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

// API Service Provider
final adminApiServiceProvider = Provider<AdminApiService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AdminApiService(dioClient);
});

// Repository Provider
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final apiService = ref.watch(adminApiServiceProvider);
  return AdminRepositoryImpl(adminApiService: apiService);
});

// Use Case Providers
final getPendingPostsProvider = Provider<GetPendingPosts>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return GetPendingPosts(repository);
});

final approvePostProvider = Provider<ApprovePost>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return ApprovePost(repository);
});

final rejectPostProvider = Provider<RejectPost>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return RejectPost(repository);
});

final getPendingCommentsProvider = Provider<GetPendingComments>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return GetPendingComments(repository);
});

final approveCommentProvider = Provider<ApproveComment>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return ApproveComment(repository);
});

final rejectCommentProvider = Provider<RejectComment>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return RejectComment(repository);
});

final getUnresolvedFlagsProvider = Provider<GetUnresolvedFlags>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return GetUnresolvedFlags(repository);
});

final resolveContentFlagProvider = Provider<ResolveContentFlag>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return ResolveContentFlag(repository);
});

final getDashboardDataProvider = Provider<GetDashboardData>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return GetDashboardData(repository);
});

final pendingPostsProvider = StateNotifierProvider<PostModerationController, AsyncValue<List<Post>>>((ref) {
  final getPendingPosts = ref.watch(getPendingPostsProvider);
  final approvePost = ref.watch(approvePostProvider);
  final rejectPost = ref.watch(rejectPostProvider);
  final bulkApprovePosts = ref.watch(adminRepositoryProvider).bulkApprovePosts;
  final bulkRejectPosts = ref.watch(adminRepositoryProvider).bulkRejectPosts;
  return PostModerationController(
    getPendingPosts: getPendingPosts,
    approvePost: approvePost,
    rejectPost: rejectPost,
    bulkApprovePosts: bulkApprovePosts,
    bulkRejectPosts: bulkRejectPosts,
  );
});

final pendingCommentsProvider = StateNotifierProvider<CommentModerationController, AsyncValue<List<Comment>>>((ref) {
  final getPendingComments = ref.watch(getPendingCommentsProvider);
  final approveComment = ref.watch(approveCommentProvider);
  final rejectComment = ref.watch(rejectCommentProvider);
  final bulkApproveComments = ref.watch(adminRepositoryProvider).bulkApproveComments;
  final bulkRejectComments = ref.watch(adminRepositoryProvider).bulkRejectComments;
  return CommentModerationController(
    getPendingComments: getPendingComments,
    approveComment: approveComment,
    rejectComment: rejectComment,
    bulkApproveComments: bulkApproveComments,
    bulkRejectComments: bulkRejectComments,
  );
}); 