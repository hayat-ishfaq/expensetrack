/// Typed errors surfaced to the UI.
///
/// Repositories throw these instead of raw Firebase exceptions, so screens
/// never have to reason about SDK-specific failure modes and users never see
/// raw Firebase messages.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class NetworkException extends AppException {
  const NetworkException([
    super.message = "You're offline. This action will be available when you're connected.",
  ]);
}

final class AuthException extends AppException {
  const AuthException(super.message);
}

final class ValidationException extends AppException {
  const ValidationException(super.message);
}

final class NotFoundException extends AppException {
  const NotFoundException([
    super.message = 'This item no longer exists.',
  ]);
}

/// Household-specific failures, e.g. an invite code that doesn't match any
/// flat or a flat that can't be created.
final class HouseholdException extends AppException {
  const HouseholdException(super.message);
}

final class PermissionException extends AppException {
  const PermissionException([
    super.message = "You don't have permission to do that.",
  ]);
}

final class UnknownException extends AppException {
  const UnknownException([
    super.message = 'Something went wrong. Please try again.',
  ]);
}
