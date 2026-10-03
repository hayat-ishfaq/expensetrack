import 'dart:async';

import 'package:expensetrack/features/auth/domain/auth_user.dart';
import 'package:expensetrack/features/auth/domain/session_state.dart';
import 'package:expensetrack/features/auth/presentation/providers/auth_providers.dart';
import 'package:expensetrack/features/auth/presentation/providers/session_provider.dart';
import 'package:expensetrack/shared/models/app_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_auth_repository.dart';

/// Resolves [sessionProvider] to its first non-loading value.
///
/// A bare `container.read(provider.future)` never subscribes to the underlying
/// streams in Riverpod 3, so an explicit listener is required to keep the
/// auth -> profile -> session chain alive.
Future<SessionState> resolveSession(FakeAuthRepository fakeAuth) {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(fakeAuth),
      firebaseInitProvider.overrideWith((ref) async {}),
    ],
  );
  addTearDown(container.dispose);

  final completer = Completer<SessionState>();
  final subscription = container.listen<AsyncValue<SessionState>>(
    sessionProvider,
    (_, next) {
      if (completer.isCompleted) return;
      if (next.isLoading) return;
      if (next.hasError) {
        completer.completeError(next.error!);
        return;
      }
      completer.complete(next.value!);
    },
  );
  addTearDown(subscription.close);
  return completer.future.timeout(const Duration(seconds: 5));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppUser profileWithHousehold({String? householdId}) => AppUser(
        id: 'u1',
        name: 'Hayat',
        email: 'hayat@example.com',
        householdId: householdId,
        createdAt: DateTime(2026, 9, 1),
      );

  test('signed out session is reported as signed out', () async {
    final session = await resolveSession(FakeAuthRepository());

    expect(session, isA<SessionSignedOut>());
    expect(session.user, isNull);
  });

  test('signed in without a household requires household setup', () async {
    final fakeAuth = FakeAuthRepository(
      currentUser: const AuthUser(uid: 'u1', email: 'hayat@example.com'),
      appUser: profileWithHousehold(),
    );
    final session = await resolveSession(fakeAuth);

    expect(session, isA<SessionNeedsHousehold>());
    expect(session.householdId, isNull);
  });

  test('signed in with a household is ready', () async {
    final fakeAuth = FakeAuthRepository(
      currentUser: const AuthUser(uid: 'u1', email: 'hayat@example.com'),
      appUser: profileWithHousehold(householdId: 'house-1'),
    );
    final session = await resolveSession(fakeAuth);

    expect(session, isA<SessionReady>());
    expect(session.householdId, 'house-1');
  });
}