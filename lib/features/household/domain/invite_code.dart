import 'dart:math';

import '../../../core/constants/app_constants.dart';

/// Pure invite-code generation, e.g. `FLAT-7K29`.
///
/// Kept free of Firebase so it can be unit tested without a backend. The
/// alphabet omits look-alike characters (0/O, 1/I/L) so codes are easy to
/// read out loud.
abstract final class InviteCode {
  static const String _alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  /// Generates a code of the form `FLAT-XXXX`.
  static String generate(Random random) {
    final suffix = List.generate(
      AppConstants.inviteCodeLength,
      (_) => _alphabet[random.nextInt(_alphabet.length)],
    ).join();
    return '${AppConstants.invitePrefix}$suffix';
  }
}