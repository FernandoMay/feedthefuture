import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feed_the_future/auth_repository_impl.dart';
import 'package:feed_the_future/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

// import '../../../data/repositories/auth_repository_impl.dart';
// import '../../../domain/entities/app_user.dart';
// import '../../../domain/repositories/auth_repository.dart';
// import '../../../domain/usecases/auth_usecases.dart';

// Repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    googleSignIn: GoogleSignIn(),
  );
});

// Auth state stream
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// Current user (sync shortcut)
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authStateProvider).value;
});

// Auth notifier
class AuthNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _repository.authStateChanges.listen(
      (user) => state = AsyncValue.data(user),
      onError: (e) => state = AsyncValue.error(e, StackTrace.current),
    );
  }

  Future<String?> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    final result = await SignInWithEmailUseCase(_repository)
        .call(email: email, password: password);
    return result.fold(
      (failure) {
        state = AsyncValue.data(null);
        return failure.message;
      },
      (user) {
        state = AsyncValue.data(user);
        return null;
      },
    );
  }

  Future<String?> register({
    required String email,
    required String password,
    required String displayName,
    required String role,
    String? organizationName,
  }) async {
    state = const AsyncValue.loading();
    final result = await RegisterWithEmailUseCase(_repository).call(
      email: email,
      password: password,
      displayName: displayName,
      role: role,
      organizationName: organizationName,
    );
    return result.fold(
      (failure) {
        state = AsyncValue.data(null);
        return failure.message;
      },
      (user) {
        state = AsyncValue.data(user);
        return null;
      },
    );
  }

  Future<void> signOut() async {
    await SignOutUseCase(_repository).call();
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<AppUser?>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
