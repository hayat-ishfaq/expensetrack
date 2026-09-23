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
    if (value == null || value.trim().isEmpty) {
      return 'Invite code is required.';
    }
    final code = normalizeInviteCode(value);
    if (!_invitePattern.hasMatch(code)) {
      return 'Enter a valid invite code (e.g. FLAT-7K29).';
    }
    return null;
  }

  /// Uppercases, trims, extracts and normalizes the invite code.
  ///
  /// Supports:
  /// - Full shared message: "Flat Invite Code: FLAT-7K29\n\nJoin my flat..." -> "FLAT-7K29"
  /// - Standard formatted code: "FLAT-7K29", "flat-7k29" -> "FLAT-7K29"
  /// - Short code / suffix: "7k29", "7K29" -> "FLAT-7K29"
  /// - Loose whitespace: " FLAT - 7K29 " -> "FLAT-7K29"
  static String normalizeInviteCode(String? value) {
    if (value == null) return '';
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';

    // 1. Search for explicit FLAT-XXXX pattern anywhere in the text (e.g. from shared invite messages)
    final patternMatch = RegExp(
      r'FLAT-([A-Z0-9]{4})\b',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (patternMatch != null) {
      return 'FLAT-${patternMatch.group(1)!.toUpperCase()}';
    }

    // 2. Search for loose "FLAT XXXX" or "FLAT: XXXX"
    final loosePrefixMatch = RegExp(
      r'FLAT[\s:-]+([A-Z0-9]{4})\b',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (loosePrefixMatch != null) {
      return 'FLAT-${loosePrefixMatch.group(1)!.toUpperCase()}';
    }

    // 3. If it starts with FLAT-, preserve the full string with prefix
    final upper = trimmed.toUpperCase().replaceAll(' ', '');
    if (upper.startsWith(AppConstants.invitePrefix)) {
      return upper;
    }

    // 4. If the string is just a 4-character suffix without FLAT prefix (e.g. "7K29")
    final cleanAlphaNum =
        trimmed.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (cleanAlphaNum.length == 4) {
      return 'FLAT-$cleanAlphaNum';
    }

    return '${AppConstants.invitePrefix}$upper';
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
