import '../constants/app_constants.dart';
import 'money.dart';

/// Form validators. Every validator returns `null` when the value is valid,
/// or a user-facing message explaining what to fix.
abstract final class Validators {
  static final RegExp _emailPattern =
      RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]{2,}$');
  static final RegExp _invitePattern =
      RegExp(r'^FLAT-[A-Z0-9]{4}$');

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required.';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required.';
    if (!_emailPattern.hasMatch(value.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (value.length < AppConstants.minPasswordLength) {
      return 'Password must be at least '
          '${AppConstants.minPasswordLength} characters.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Please confirm your password.';
    if (value != original) return 'Passwords do not match.';
    return null;
  }

  /// Full name for sign-up / profile editing.
  static String? name(String? value) {
    final error = required(value, field: 'Full name');
    if (error != null) return error;
    final trimmed = value!.trim();
    if (trimmed.length < 2) return 'That name looks too short.';
    if (trimmed.length > AppConstants.maxNameLength) {
      return 'Keep the name under ${AppConstants.maxNameLength} characters.';
    }
    return null;
  }

  static String? flatName(String? value) {
    final error = required(value, field: 'Flat name');
    if (error != null) return error;
    if (value!.trim().length > AppConstants.maxFlatNameLength) {
      return 'Keep the flat name under '
          '${AppConstants.maxFlatNameLength} characters.';
    }
    return null;
  }

  static String? inviteCode(String? value) {
    final code = normalizeInviteCode(value);
    if (code.isEmpty) return 'Invite code is required.';
    if (!_invitePattern.hasMatch(code)) {
      return 'Enter a valid invite code (e.g. FLAT-7K29).';
    }
    return null;
  }

  /// Uppercases, trims and adds the `FLAT-` prefix when the user only typed
  /// the short code (e.g. `7k29` -> `FLAT-7K29`).
  static String normalizeInviteCode(String? value) {
    var code = (value ?? '').trim().toUpperCase().replaceAll(' ', '');
    if (code.isNotEmpty && !code.startsWith(AppConstants.invitePrefix)) {
      code = '${AppConstants.invitePrefix}$code';
    }
    return code;
  }

  /// Expense amount: required, numeric, greater than zero, max two decimals.
  static String? amount(String? value) {
    if (value == null || value.trim().isEmpty) return 'Amount is required.';
    final paisa = Money.tryParsePaisa(value);
    if (paisa == null) return 'Enter a valid amount, e.g. 1500 or 1500.50.';
    if (paisa <= 0) return 'Amount must be greater than zero.';
    return null;
  }

  static String? description(String? value) {
    final error = required(value, field: 'Description');
    if (error != null) return error;
    if (value!.trim().length > AppConstants.maxDescriptionLength) {
      return 'Keep it under ${AppConstants.maxDescriptionLength} characters.';
    }
    return null;
  }
}
