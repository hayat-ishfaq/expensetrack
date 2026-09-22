import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/app_user.dart';
import '../../data/firebase_auth_repository.dart';
import '../../domain/auth_repository.dart';
import '../../domain/auth_user.dart';

/// Composition root for auth. Overridden in tests.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(FirebaseAuth.instance, FirebaseFirestore.instance);
});

/// Streams the Firebase auth state (null = signed out).
final authStateProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// Streams the signed-in user's `users/{uid}` profile document.
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final authUser = ref.watch(authStateProvider).value;
  final repository = ref.watch(authRepositoryProvider);
  if (authUser == null) return Stream.value(null);
  return repository.watchCurrentUser(authUser.uid);
});

/// One-shot auth commands (sign in / sign up / reset). Screens watch this to
/// show loading state and surface mapped errors.
class AuthActions extends AsyncNotifier<void> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  Future<void> build() async {}

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.signInWithEmail(email: email, password: password);
    });
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.signUpWithEmail(
        name: name,
        email: email,
        password: password,
      );
    });
  }

  Future<void> resetPassword({required String email}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.sendPasswordReset(email: email);
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.signOut();
    });
  }
}

final authActionsProvider =
    AsyncNotifierProvider<AuthActions, void>(AuthActions.new);