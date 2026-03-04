import 'package:equatable/equatable.dart';

abstract class AppFailure extends Equatable {
  final String message;
  final String? code;

  const AppFailure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

class AuthFailure extends AppFailure {
  const AuthFailure({required super.message, super.code});
}

class FirestoreFailure extends AppFailure {
  const FirestoreFailure({required super.message, super.code});
}

class ServerFailure extends AppFailure {
  const ServerFailure({required super.message, super.code});
}

class NetworkFailure extends AppFailure {
  const NetworkFailure({required super.message, super.code});
}

class ValidationFailure extends AppFailure {
  const ValidationFailure({required super.message, super.code});
}
