import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/admin/domain/entities/post.dart';
import 'package:frontend/features/admin/domain/entities/comment.dart';
import 'package:frontend/features/admin/domain/usecases/approve_post.dart';
import 'package:frontend/features/admin/domain/usecases/reject_post.dart';
import 'package:frontend/features/admin/domain/usecases/get_pending_posts.dart';
import 'package:frontend/features/admin/domain/usecases/approve_comment.dart';
import 'package:frontend/features/admin/domain/usecases/reject_comment.dart';
import 'package:frontend/features/admin/domain/usecases/get_pending_comments.dart';
import 'package:frontend/features/admin/presentation/providers/admin_providers.dart';
import 'package:dartz/dartz.dart';
import 'package:frontend/shared/domain/error/failure.dart';

class PostModerationController extends StateNotifier<AsyncValue<List<Post>>> {
  final GetPendingPosts _getPendingPosts;
  final ApprovePost _approvePost;
  final RejectPost _rejectPost;
  final Future<Either<Failure, int>> Function(List<String>) _bulkApprovePosts;
  final Future<Either<Failure, int>> Function(List<String>, String) _bulkRejectPosts;
  
  PostModerationController({
    required GetPendingPosts getPendingPosts,
    required ApprovePost approvePost,
    required RejectPost rejectPost,
    required Future<Either<Failure, int>> Function(List<String>) bulkApprovePosts,
    required Future<Either<Failure, int>> Function(List<String>, String) bulkRejectPosts,
  }) : _getPendingPosts = getPendingPosts,
       _approvePost = approvePost,
       _rejectPost = rejectPost,
       _bulkApprovePosts = bulkApprovePosts,
       _bulkRejectPosts = bulkRejectPosts,
       super(const AsyncValue.loading());
  
  Future<void> loadPendingPosts({int page = 1}) async {
    state = const AsyncValue.loading();
    final result = await _getPendingPosts(page: page);
    
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (posts) => state = AsyncValue.data(posts),
    );
  }
  
  Future<bool> approvePost(String postId, {String? notes}) async {
    final currentState = state;
    if (currentState is AsyncData<List<Post>>) {
      final result = await _approvePost(postId: postId, notes: notes);
      
      return result.fold(
        (failure) {
          state = AsyncValue.error(failure.message, StackTrace.current);
          return false;
        },
        (approvedPost) {
          final posts = List<Post>.from(currentState.value);
          final index = posts.indexWhere((post) => post.id == postId);
          
          if (index != -1) {
            posts.removeAt(index);
            state = AsyncValue.data(posts);
          }
          
          return true;
        },
      );
    }
    
    return false;
  }
  
  Future<bool> rejectPost(String postId, {required String notes}) async {
    final currentState = state;
    if (currentState is AsyncData<List<Post>>) {
      final result = await _rejectPost(postId: postId, notes: notes);
      
      return result.fold(
        (failure) {
          state = AsyncValue.error(failure.message, StackTrace.current);
          return false;
        },
        (rejectedPost) {
          final posts = List<Post>.from(currentState.value);
          final index = posts.indexWhere((post) => post.id == postId);
          
          if (index != -1) {
            posts.removeAt(index);
            state = AsyncValue.data(posts);
          }
          
          return true;
        },
      );
    }
    
    return false;
  }

  Future<bool> bulkApprovePosts(List<String> ids) async {
    final result = await _bulkApprovePosts(ids);
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (approvedCount) {
        if (state is AsyncData<List<Post>>) {
          final posts = List<Post>.from((state as AsyncData<List<Post>>).value);
          posts.removeWhere((post) => ids.contains(post.id));
          state = AsyncValue.data(posts);
        }
        return true;
      },
    );
  }

  Future<bool> bulkRejectPosts(List<String> ids, String notes) async {
    final result = await _bulkRejectPosts(ids, notes);
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (rejectedCount) {
        if (state is AsyncData<List<Post>>) {
          final posts = List<Post>.from((state as AsyncData<List<Post>>).value);
          posts.removeWhere((post) => ids.contains(post.id));
          state = AsyncValue.data(posts);
        }
        return true;
      },
    );
  }
}

class CommentModerationController extends StateNotifier<AsyncValue<List<Comment>>> {
  final GetPendingComments _getPendingComments;
  final ApproveComment _approveComment;
  final RejectComment _rejectComment;
  final Future<Either<Failure, int>> Function(List<String>) _bulkApproveComments;
  final Future<Either<Failure, int>> Function(List<String>, String) _bulkRejectComments;
  
  CommentModerationController({
    required GetPendingComments getPendingComments,
    required ApproveComment approveComment,
    required RejectComment rejectComment,
    required Future<Either<Failure, int>> Function(List<String>) bulkApproveComments,
    required Future<Either<Failure, int>> Function(List<String>, String) bulkRejectComments,
  }) : _getPendingComments = getPendingComments,
       _approveComment = approveComment,
       _rejectComment = rejectComment,
       _bulkApproveComments = bulkApproveComments,
       _bulkRejectComments = bulkRejectComments,
       super(const AsyncValue.loading());
  
  Future<void> loadPendingComments({int page = 1}) async {
    state = const AsyncValue.loading();
    final result = await _getPendingComments(page: page);
    
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (comments) => state = AsyncValue.data(comments),
    );
  }
  
  Future<bool> approveComment(String commentId, {String? notes}) async {
    final currentState = state;
    if (currentState is AsyncData<List<Comment>>) {
      final result = await _approveComment(commentId: commentId, notes: notes);
      
      return result.fold(
        (failure) {
          state = AsyncValue.error(failure.message, StackTrace.current);
          return false;
        },
        (approvedComment) {
          final comments = List<Comment>.from(currentState.value);
          final index = comments.indexWhere((comment) => comment.id == commentId);
          
          if (index != -1) {
            comments.removeAt(index);
            state = AsyncValue.data(comments);
          }
          
          return true;
        },
      );
    }
    
    return false;
  }
  
  Future<bool> rejectComment(String commentId, {required String notes}) async {
    final currentState = state;
    if (currentState is AsyncData<List<Comment>>) {
      final result = await _rejectComment(commentId: commentId, notes: notes);
      
      return result.fold(
        (failure) {
          state = AsyncValue.error(failure.message, StackTrace.current);
          return false;
        },
        (rejectedComment) {
          final comments = List<Comment>.from(currentState.value);
          final index = comments.indexWhere((comment) => comment.id == commentId);
          
          if (index != -1) {
            comments.removeAt(index);
            state = AsyncValue.data(comments);
          }
          
          return true;
        },
      );
    }
    
    return false;
  }

  Future<bool> bulkApproveComments(List<String> ids) async {
    final result = await _bulkApproveComments(ids);
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (approvedCount) {
        if (state is AsyncData<List<Comment>>) {
          final comments = List<Comment>.from((state as AsyncData<List<Comment>>).value);
          comments.removeWhere((comment) => ids.contains(comment.id));
          state = AsyncValue.data(comments);
        }
        return true;
      },
    );
  }

  Future<bool> bulkRejectComments(List<String> ids, String notes) async {
    final result = await _bulkRejectComments(ids, notes);
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (rejectedCount) {
        if (state is AsyncData<List<Comment>>) {
          final comments = List<Comment>.from((state as AsyncData<List<Comment>>).value);
          comments.removeWhere((comment) => ids.contains(comment.id));
          state = AsyncValue.data(comments);
        }
        return true;
      },
    );
  }
} 