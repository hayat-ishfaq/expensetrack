/// Firestore collection names, kept in one place so the schema is easy to
/// audit and evolve.
abstract final class FirestoreCollections {
  static const String users = 'users';
  static const String households = 'households';
  static const String members = 'members';
  static const String expenses = 'expenses';
  static const String settlements = 'settlements';

  /// Top-level mapping of invite code -> household, so joining a flat never
  /// requires an unscoped read of the `households` collection.
  static const String inviteCodes = 'inviteCodes';
}
