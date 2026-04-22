// DEPRECATED: Use 'package:dartz/dartz.dart' for Either instead of this file.
// This file is kept for legacy reasons but should not be used in new code.

abstract class Either<L, R> {
  const Either();

  bool get isLeft;
  bool get isRight;

  T fold<T>(T Function(L left) leftFn, T Function(R right) rightFn);
  
  R getOrElse(R Function() defaultValue);
}

class Left<L, R> extends Either<L, R> {
  final L value;

  const Left(this.value);

  @override
  bool get isLeft => true;

  @override
  bool get isRight => false;

  @override
  T fold<T>(T Function(L left) leftFn, T Function(R right) rightFn) {
    return leftFn(value);
  }

  @override
  R getOrElse(R Function() defaultValue) {
    return defaultValue();
  }

  @override
  String toString() => 'Left($value)';
}

class Right<L, R> extends Either<L, R> {
  final R value;

  const Right(this.value);

  @override
  bool get isLeft => false;

  @override
  bool get isRight => true;

  @override
  T fold<T>(T Function(L left) leftFn, T Function(R right) rightFn) {
    return rightFn(value);
  }

  @override
  R getOrElse(R Function() defaultValue) {
    return value;
  }

  @override
  String toString() => 'Right($value)';
} 