import '../../../shared/models/app_user.dart';

/// Where the user is in the onboarding/usage funnel. Computed from auth state
/// plus their profile document; drives every router redirect.
sealed class SessionState {
  const SessionState();

  /// The profile of the signed-in user, when one exists.
  AppUser? get user => switch (this) {
        SessionNeedsHousehold(:final user) || SessionReady(:final user) =>
          user,
        _ => null,
      };

  String? get householdId => user?.householdId;
}

/// Auth state has not resolved yet (still connecting to Firebase).
final class SessionInitializing extends SessionState {
  const SessionInitializing();
}

final class SessionSignedOut extends SessionState {
  const SessionSignedOut();
}

/// Signed in, but the user has not created/joined a household yet.
final class SessionNeedsHousehold extends SessionState {
  const SessionNeedsHousehold({required this.user});

  @override
  final AppUser user;
}

/// Signed in and a member of a household — the full app is available.
final class SessionReady extends SessionState {
  const SessionReady({required this.user});

  @override
  final AppUser user;
}