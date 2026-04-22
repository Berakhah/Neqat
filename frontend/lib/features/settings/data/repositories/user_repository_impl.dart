import 'package:dartz/dartz.dart';
import 'package:frontend/features/settings/data/datasource/user_remote_datasource_impl.dart';
import 'package:frontend/features/settings/data/models/user_model.dart';
import 'package:frontend/features/settings/domain/repositories/user_repository.dart';
import '../../domain/entities/failure.dart';
import '../../domain/entities/user.dart';

class UserRepositoryImpl extends UserRepository {
  final UserRemoteDataSourceImpl remoteDataSource;
  UserRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, UserModel>> getUser() async {
    try {
      final user = await remoteDataSource.getUserProfile();
      return Right(user);
    } catch (e) {
      return Left(Failure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserModel>> updateUser(User user) async {
    try {
      // Cast the User entity back to UserModel for the data source
      final userModel = UserModel.fromEntity(user);
      await remoteDataSource.updateUserProfile(userModel); // This method now returns void on success
      // We need to fetch the user again after updating to get the latest data from the backend
      return await getUser(); // Re-fetch the user to get the updated profile_photo URL
    } on Exception catch (e) {
      return Left(Failure(errorMessage: e.toString()));
    }
  }
}
