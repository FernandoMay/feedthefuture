import 'package:dartz/dartz.dart';
import 'package:feed_the_future/core/errors/failures.dart';
import 'package:feed_the_future/features/auth/domain/entities/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;

  Future<Either<AppFailure, AppUser>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Either<AppFailure, AppUser>> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    required String role,
    String? organizationName,
  });

  Future<Either<AppFailure, AppUser>> signInWithGoogle();

  Future<Either<AppFailure, void>> signOut();

  Future<Either<AppFailure, void>> sendPasswordResetEmail(String email);

  Future<Either<AppFailure, AppUser?>> getCurrentUser();

  Future<Either<AppFailure, AppUser>> updateProfile({
    String? displayName,
    String? phone,
    String? organizationName,
    UserLocation? location,
  });
}
