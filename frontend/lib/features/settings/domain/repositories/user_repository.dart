import 'package:dartz/dartz.dart';
import '../entities/user.dart';
import '../entities/failure.dart';
import '../../data/models/user_model.dart';

abstract class UserRepository {
  Future<Either<Failure, UserModel>> getUser();
  Future<Either<Failure, UserModel>> updateUser(User user);
}
