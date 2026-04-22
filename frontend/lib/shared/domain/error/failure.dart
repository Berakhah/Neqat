abstract class Failure {
  final String message;

  Failure({required this.message});
}

class ServerFailure extends Failure {
  ServerFailure({required String message}) : super(message: message);
}

class CacheFailure extends Failure {
  CacheFailure({required String message}) : super(message: message);
}

class NetworkFailure extends Failure {
  NetworkFailure({required String message}) : super(message: message);
}

class UnauthorizedFailure extends Failure {
  UnauthorizedFailure({required String message}) : super(message: message);
}

class AuthenticationFailure extends Failure {
  AuthenticationFailure({required String message, int? statusCode})
      : super(message: message);
}

class ValidationFailure extends Failure {
  final Map<String, List<String>>? errors;

  ValidationFailure({required String message, this.errors, int? statusCode})
      : super(message: message);
} 