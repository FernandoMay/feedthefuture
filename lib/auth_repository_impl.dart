import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/errors/failures.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../models/app_user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  const AuthRepositoryImpl({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required GoogleSignIn googleSignIn,
  })  : _auth = auth,
        _firestore = firestore,
        _googleSignIn = googleSignIn;

  @override
  Stream<AppUser?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      try {
        final doc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .get();
        if (!doc.exists) return null;
        return AppUserModel.fromFirestore(doc);
      } catch (_) {
        return null;
      }
    });
  }

  @override
  Future<Either<AppFailure, AppUser>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(credential.user!.uid)
          .get();
      if (!doc.exists) {
        return const Left(AuthFailure(message: 'Usuario no encontrado'));
      }
      return Right(AppUserModel.fromFirestore(doc));
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(message: _mapAuthError(e.code), code: e.code));
    } catch (e) {
      return Left(ServerFailure(message: 'Error inesperado: $e'));
    }
  }

  @override
  Future<Either<AppFailure, AppUser>> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    required String role,
    String? organizationName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user!.updateDisplayName(displayName);

      final userModel = AppUserModel(
        id: credential.user!.uid,
        email: email,
        displayName: displayName,
        role: role,
        organizationName: organizationName,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(credential.user!.uid)
          .set(userModel.toFirestore());

      return Right(userModel);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(message: _mapAuthError(e.code), code: e.code));
    } catch (e) {
      return Left(ServerFailure(message: 'Error al registrar: $e'));
    }
  }

  @override
  Future<Either<AppFailure, AppUser>> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return const Left(AuthFailure(message: 'Inicio cancelado'));
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final uid = userCredential.user!.uid;

      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (!doc.exists) {
        final newUser = AppUserModel(
          id: uid,
          email: userCredential.user!.email!,
          displayName: userCredential.user!.displayName ?? 'Usuario',
          role: AppConstants.roleCommunity,
          photoUrl: userCredential.user!.photoURL,
          createdAt: DateTime.now(),
        );
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .set(newUser.toFirestore());
        return Right(newUser);
      }

      return Right(AppUserModel.fromFirestore(doc));
    } catch (e) {
      return Left(AuthFailure(message: 'Error con Google: $e'));
    }
  }

  @override
  Future<Either<AppFailure, void>> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(message: 'Error al cerrar sesión'));
    }
  }

  @override
  Future<Either<AppFailure, void>> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(message: _mapAuthError(e.code)));
    }
  }

  @override
  Future<Either<AppFailure, AppUser?>> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return const Right(null);
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();
      if (!doc.exists) return const Right(null);
      return Right(AppUserModel.fromFirestore(doc));
    } catch (e) {
      return Left(FirestoreFailure(message: 'Error al obtener usuario'));
    }
  }

  @override
  Future<Either<AppFailure, AppUser>> updateProfile({
    String? displayName,
    String? phone,
    String? organizationName,
    UserLocation? location,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return const Left(AuthFailure(message: 'No autenticado'));

      final updates = <String, dynamic>{};
      if (displayName != null) updates['displayName'] = displayName;
      if (phone != null) updates['phone'] = phone;
      if (organizationName != null) updates['organizationName'] = organizationName;
      if (location != null) {
        updates['location'] = {
          'latitude': location.latitude,
          'longitude': location.longitude,
          if (location.address != null) 'address': location.address,
          if (location.city != null) 'city': location.city,
        };
      }

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update(updates);

      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();
      return Right(AppUserModel.fromFirestore(doc));
    } catch (e) {
      return Left(FirestoreFailure(message: 'Error al actualizar perfil'));
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No existe una cuenta con este email';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'email-already-in-use':
        return 'Este email ya está registrado';
      case 'invalid-email':
        return 'Email inválido';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      case 'network-request-failed':
        return 'Sin conexión a internet';
      default:
        return 'Error de autenticación';
    }
  }
}
