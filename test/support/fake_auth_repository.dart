import 'dart:async';

import 'package:expensetrack/features/auth/domain/auth_repository.dart';
import 'package:expensetrack/features/auth/domain/auth_user.dart';
import 'package:expensetrack/shared/models/app_user.dart';

/// In-memory [AuthRepository] for widget and unit tests. No Firebase involved.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.currentUser, this.appUser});

  /// Current auth identity (emit changes via [emitAuthState]).
  AuthUser? currentUser;

  /// Current profile document.
  AppUser? appUser;

  final StreamController<AuthUser?> _authChanges =
      StreamController<AuthUser?>.broadcast();

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield currentUser;
    yield* _authChanges.stream;
  }

  @override
  Stream<AppUser?> watchCurrentUser(String uid) async* {
    yield appUser;
  }

  /// Pushes a new auth state to listeners and updates [currentUser].
  void emitAuthState(AuthUser? user) {
    currentUser = user;
    _authChanges.add(user);
  }

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError('Not exercised in widget tests.');

  @override
  Future<AppUser> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) =>
      throw UnimplementedError('Not exercised in widget tests.');

  @override
  Future<void> sendPasswordReset({required String email}) async {}

  @override
  Future<void> signOut() async {}
}