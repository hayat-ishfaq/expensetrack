/// Global app-wide constants.
///
/// The product name lives here so "FlatSplit" can be renamed in one place.
abstract final class AppConstants {
  static const String appName = 'FlatSplit';
  static const String tagline = 'Shared expenses, simplified.';

  /// ISO currency code used for new households.
  static const String defaultCurrency = 'PKR';

  /// Invite codes look like `FLAT-7K29`.
  static const String invitePrefix = 'FLAT-';
  static const int inviteCodeLength = 4;

  static const int minPasswordLength = 8;
  static const int maxNameLength = 60;
  static const int maxFlatNameLength = 50;
  static const int maxDescriptionLength = 120;

  /// Practical upper bound for a flat; larger groups get an explicit warning.
  static const int maxHouseholdMembers = 10;
}
