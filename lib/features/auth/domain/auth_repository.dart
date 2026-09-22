import '../../../shared/models/app_user.dart';
import 'auth_user.dart';

/// Authentication boundary. UI code depends on this interface instead of the
/// Firebase SDK, so it can be faked in tests.
abstract interface class AuthRepository {
  /// Emits the current Firebase auth state (null when signed out).
  Stream<AuthUser?> authStateChanges();

  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  });

  /// Creates the account and provisions the `users/{uid}` profile document.
  Future<AppUser> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  });

  Future<void> sendPasswordReset({required String email});

  Future<void> signOut();

  /// Streams the `users/{uid}` document; emits null when it does not exist.
  Stream<AppUser?> watchCurrentUser(String uid);
}