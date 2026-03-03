import 'package:dartz/dartz.dart';
import 'package:feed_the_future/core/errors/failures.dart';
import 'package:feed_the_future/features/auth/domain/entities/app_user.dart';
import 'package:feed_the_future/features/auth/domain/repositories/auth_repository.dart';

class SignInWithEmailUseCase {
  final AuthRepository _repository;

  SignInWithEmailUseCase(this._repository);

  Future<Either<AppFailure, AppUser>> call({
    required String email,
    required String password,
  }) {
    return _repository.signInWithEmail(email: email, password: password);
  }
}

class RegisterWithEmailUseCase {
  final AuthRepository _repository;

  RegisterWithEmailUseCase(this._repository);

  Future<Either<AppFailure, AppUser>> call({
    required String email,
    required String password,
    required String displayName,
    required String role,
    String? organizationName,
  }) {
    return _repository.registerWithEmail(
      email: email,
      password: password,
      displayName: displayName,
      role: role,
      organizationName: organizationName,
    );
  }
}

class SignInWithGoogleUseCase {
  final AuthRepository _repository;

  SignInWithGoogleUseCase(this._repository);

  Future<Either<AppFailure, AppUser>> call() {
    return _repository.signInWithGoogle();
  }
}

class SignOutUseCase {
  final AuthRepository _repository;

  SignOutUseCase(this._repository);

  Future<Either<AppFailure, void>> call() {
    return _repository.signOut();
  }
}

class SendPasswordResetEmailUseCase {
  final AuthRepository _repository;

  SendPasswordResetEmailUseCase(this._repository);

  Future<Either<AppFailure, void>> call(String email) {
    return _repository.sendPasswordResetEmail(email);
  }
}

class GetCurrentUserUseCase {
  final AuthRepository _repository;

  GetCurrentUserUseCase(this._repository);

  Future<Either<AppFailure, AppUser?>> call() {
    return _repository.getCurrentUser();
  }
}

class UpdateProfileUseCase {
  final AuthRepository _repository;

  UpdateProfileUseCase(this._repository);

  Future<Either<AppFailure, AppUser>> call({
    String? displayName,
    String? phone,
    String? organizationName,
    UserLocation? location,
  }) {
    return _repository.updateProfile(
      displayName: displayName,
      phone: phone,
      organizationName: organizationName,
      location: location,
    );
  }
}
