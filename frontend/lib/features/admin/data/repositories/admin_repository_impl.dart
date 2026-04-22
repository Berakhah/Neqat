import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:frontend/shared/domain/error/failure.dart';
import 'package:frontend/features/admin/data/datasources/admin_api_service.dart';
import 'package:frontend/features/admin/data/models/post_model.dart';
import 'package:frontend/features/admin/data/models/comment_model.dart';
import 'package:frontend/features/admin/data/models/content_flag_model.dart';
import 'package:frontend/features/admin/domain/entities/post.dart';
import 'package:frontend/features/admin/domain/entities/comment.dart';
import 'package:frontend/features/admin/domain/entities/content_flag.dart';
import 'package:frontend/features/admin/domain/entities/admin_user.dart';
import 'package:frontend/features/admin/domain/entities/dashboard_metrics.dart';
import 'package:frontend/features/admin/domain/entities/moderation_history.dart';
import 'package:frontend/features/admin/domain/repositories/admin_repository.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminApiService adminApiService;

  AdminRepositoryImpl({required this.adminApiService});

  @override
  Future<Either<Failure, List<Post>>> getPosts({String? status, int page = 1}) async {
    try {
      final postsJson = await adminApiService.fetchPosts(status: status, page: page);
      final posts = postsJson.map((json) => PostModel.fromJson(json)).toList();
      return Right(posts);
    } on SocketException {
      return Left(NetworkFailure(message: 'No internet connection'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Post>> approvePost(String postId, {String? notes}) async {
    try {
      final postJson = await adminApiService.approvePost(postId, notes: notes);
      final post = PostModel.fromJson(postJson);
      return Right(post);
    } on SocketException {
      return Left(NetworkFailure(message: 'No internet connection'));
    } catch (e) {
      String msg = _extractBackendError(e);
      return Left(ServerFailure(message: msg));
    }
  }

  @override
  Future<Either<Failure, Post>> rejectPost(String postId, {required String notes}) async {
    try {
      final postJson = await adminApiService.rejectPost(postId, notes: notes);
      final post = PostModel.fromJson(postJson);
      return Right(post);
    } on SocketException {
      return Left(NetworkFailure(message: 'No internet connection'));
    } catch (e) {
      String msg = _extractBackendError(e);
      return Left(ServerFailure(message: msg));
    }
  }

  @override
  Future<Either<Failure, List<Comment>>> getComments({String? status, int page = 1}) async {
    try {
      final commentsJson = await adminApiService.fetchComments(status: status, page: page);
      final comments = commentsJson.map((json) => CommentModel.fromJson(json)).toList();
      return Right(comments);
    } on SocketException {
      return Left(NetworkFailure(message: 'No internet connection'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Comment>> approveComment(String commentId, {String? notes}) async {
    try {
      final commentJson = await adminApiService.approveComment(commentId, notes: notes);
      final comment = CommentModel.fromJson(commentJson);
      return Right(comment);
    } on SocketException {
      return Left(NetworkFailure(message: 'No internet connection'));
    } catch (e) {
      String msg = _extractBackendError(e);
      return Left(ServerFailure(message: msg));
    }
  }

  @override
  Future<Either<Failure, Comment>> rejectComment(String commentId, {required String notes}) async {
    try {
      final commentJson = await adminApiService.rejectComment(commentId, notes: notes);
      final comment = CommentModel.fromJson(commentJson);
      return Right(comment);
    } on SocketException {
      return Left(NetworkFailure(message: 'No internet connection'));
    } catch (e) {
      String msg = _extractBackendError(e);
      return Left(ServerFailure(message: msg));
    }
  }

  @override
  Future<Either<Failure, List<ContentFlag>>> getContentFlags({bool? resolved, int page = 1}) async {
    try {
      final flagsJson = await adminApiService.fetchContentFlags(resolved: resolved, page: page);
      final flags = flagsJson.map((json) => ContentFlagModel.fromJson(json)).toList();
      return Right(flags);
    } on SocketException {
      return Left(NetworkFailure(message: 'No internet connection'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ContentFlag>> resolveContentFlag(String flagId, {required String notes}) async {
    try {
      final flagJson = await adminApiService.resolveContentFlag(flagId, notes: notes);
      final flag = ContentFlagModel.fromJson(flagJson);
      return Right(flag);
    } on SocketException {
      return Left(NetworkFailure(message: 'No internet connection'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, DashboardMetrics>> getDashboardData() async {
    try {
      final dashboardMetrics = await adminApiService.fetchDashboardData();
      return Right(dashboardMetrics);
    } on SocketException {
      return Left(NetworkFailure(message: 'No internet connection'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AdminUser>>> getUsers({int page = 1}) async {
    try {
      final users = await adminApiService.getUsers();
      return Right(users);
    } on SocketException {
      return Left(NetworkFailure(message: 'No internet connection'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AdminUser>> updateUserStatus(String userId, {required bool isActive}) async {
    try {
      if (isActive) {
        await adminApiService.enableUser(userId);
      } else {
        await adminApiService.disableUser(userId);
      }
      
      // Since enableUser/disableUser don't return user data,
      // we need to find another way to return the updated user.
      // For now, we'll just return a placeholder success response.
      // Ideally the UI would refresh the user list after this operation.
      throw UnimplementedError('AdminUser data not returned from enable/disable API');
    } on SocketException {
      return Left(NetworkFailure(message: 'No internet connection'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> bulkApprovePosts(List<String> ids) async {
    try {
      final result = await adminApiService.bulkApprovePosts(ids);
      return Right(result['approved'] ?? 0);
    } catch (e) {
      String msg = _extractBackendError(e);
      return Left(ServerFailure(message: msg));
    }
  }

  @override
  Future<Either<Failure, int>> bulkRejectPosts(List<String> ids, String notes) async {
    try {
      final result = await adminApiService.bulkRejectPosts(ids, notes);
      return Right(result['rejected'] ?? 0);
    } catch (e) {
      String msg = _extractBackendError(e);
      return Left(ServerFailure(message: msg));
    }
  }

  @override
  Future<Either<Failure, int>> bulkApproveComments(List<String> ids) async {
    try {
      final result = await adminApiService.bulkApproveComments(ids);
      return Right(result['approved'] ?? 0);
    } catch (e) {
      String msg = _extractBackendError(e);
      return Left(ServerFailure(message: msg));
    }
  }

  @override
  Future<Either<Failure, int>> bulkRejectComments(List<String> ids, String notes) async {
    try {
      final result = await adminApiService.bulkRejectComments(ids, notes);
      return Right(result['rejected'] ?? 0);
    } catch (e) {
      String msg = _extractBackendError(e);
      return Left(ServerFailure(message: msg));
    }
  }

  @override
  Future<List<ModerationHistory>> fetchModerationHistory({required String contentType, required String contentId}) async {
    final records = await adminApiService.fetchModerationHistory(contentType: contentType, contentId: contentId);
    return records.map((json) => ModerationHistory.fromJson(json)).toList();
  }

  String _extractBackendError(Object e) {
    final msg = e.toString();
    // Try to extract the backend error message if present in Exception('...')
    final match = RegExp(r"Exception: (.*)").firstMatch(msg);
    if (match != null && match.groupCount > 0) {
      return match.group(1)!;
    }
    return msg;
  }
} 