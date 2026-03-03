import 'package:equatable/equatable.dart';

abstract class AppFailure extends Equatable {
  final String message;
  final String? code;

  const AppFailure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

class AuthFailure extends AppFailure {
  const AuthFailure({required String message, String? code})
      : super(message: message, code: code);
}

class FirestoreFailure extends AppFailure {
  const FirestoreFailure({required String message, String? code})
      : super(message: message, code: code);
}

class ServerFailure extends AppFailure {
  const ServerFailure({required String message, String? code})
      : super(message: message, code: code);
}

class NetworkFailure extends AppFailure {
  const NetworkFailure({required String message, String? code})
      : super(message: message, code: code);
}

class ValidationFailure extends AppFailure {
  const ValidationFailure({required String message, String? code})
      : super(message: message, code: code);
}
