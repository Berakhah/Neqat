abstract class Failure {
  final String message;

  Failure({required this.message});
}

class ServerFailure extends Failure {
  ServerFailure({required super.message});
}

class CacheFailure extends Failure {
  CacheFailure({required super.message});
}

class NetworkFailure extends Failure {
  NetworkFailure({required super.message});
}

class UnauthorizedFailure extends Failure {
  UnauthorizedFailure({required super.message});
}

class AuthenticationFailure extends Failure {
  AuthenticationFailure({required super.message, int? statusCode});
}

class ValidationFailure extends Failure {
  final Map<String, List<String>>? errors;

  ValidationFailure({required super.message, this.errors, int? statusCode});
} 