import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/settings/data/datasource/user_remote_datasource_impl.dart';
import 'package:frontend/features/settings/data/repositories/user_repository_impl.dart';
import 'package:frontend/features/settings/domain/entities/failure.dart';
import 'package:frontend/features/settings/domain/entities/user.dart';
import 'package:frontend/features/settings/domain/repositories/user_repository.dart';
import 'package:frontend/features/settings/data/models/user_model.dart';

// State for the user profile
class UserProfileState {
  final UserModel? user;
  final bool isLoading;
  final Failure? failure;

  UserProfileState({this.user, this.isLoading = false, this.failure});

  UserProfileState copyWith({UserModel? user, bool? isLoading, Failure? failure}) {
    return UserProfileState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      failure: failure,
    );
  }
}

// User profile notifier that connects to the repository
class UserProfileNotifier extends StateNotifier<UserProfileState> {
  final UserRepository _repository;

  UserProfileNotifier(this._repository) : super(UserProfileState());

  Future<void> getUserProfile() async {
    print("getUserProfile called");
    state = state.copyWith(isLoading: true, failure: null);

    final result = await _repository.getUser();

    result.fold(
      (failure) => state = state.copyWith(isLoading: false, failure: failure),
      (userModel) {
        print("UserProfileNotifier - getUserProfile: Fetched user with profile_photo: ${userModel.profile_photo}");
        state = state.copyWith(isLoading: false, user: userModel);
      },
    );
  }

  Future<void> updateUserProfile(User user) async {
    print("updateUserProfile called");
    state = state.copyWith(isLoading: true, failure: null);

    final result = await _repository.updateUser(user);

    result.fold(
      (failure) => state = state.copyWith(isLoading: false, failure: failure),
      (updatedUserModel) {
        print("UserProfileNotifier - updateUserProfile: Updated user with profile_photo: ${updatedUserModel.profile_photo}");
        state = state.copyWith(isLoading: false, user: updatedUserModel);
      },
    );
  }
}

// Data source provider
final userRemoteDataSourceProvider = Provider<UserRemoteDataSourceImpl>((ref) {
  return UserRemoteDataSourceImpl();
});

// Repository provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final dataSource = ref.watch(userRemoteDataSourceProvider);
  return UserRepositoryImpl(remoteDataSource: dataSource);
});

// Provider for the user profile
final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfileState>((ref) {
      final repository = ref.watch(userRepositoryProvider);
      return UserProfileNotifier(repository);
    });
