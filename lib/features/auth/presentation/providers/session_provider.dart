import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/session_state.dart';
import 'auth_providers.dart';

/// Resolves where the user is in the app (signed out / needs household /
/// ready). Every router redirect reads this provider.
class SessionController extends AsyncNotifier<SessionState> {
  @override
  Future<SessionState> build() async {
    final authUser = await ref.watch(authStateProvider.future);
    if (authUser == null) return const SessionSignedOut();

    final appUser = await ref.watch(currentUserProvider.future);
    if (appUser == null) return const SessionSignedOut();
    if (appUser.householdId == null) {
      return SessionNeedsHousehold(user: appUser);
    }
    return SessionReady(user: appUser);
  }
}

final sessionProvider =
    AsyncNotifierProvider<SessionController, SessionState>(
  SessionController.new,
);