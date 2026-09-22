import 'dart:math';

import 'package:expensetrack/core/constants/app_constants.dart';
import 'package:expensetrack/features/household/domain/invite_code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final random = Random(42);

  test('generated codes match the FLAT-XXXX format', () {
    for (var i = 0; i < 500; i++) {
      final code = InviteCode.generate(random);
      expect(code, matches(RegExp(r'^FLAT-[A-Z0-9]{4}$')),
          reason: 'Unexpected code: $code');
      expect(code.startsWith(AppConstants.invitePrefix), isTrue);
    }
  });

  test('codes exclude look-alike characters (0, O, 1, I, L)', () {
    for (var i = 0; i < 500; i++) {
      final code = InviteCode.generate(random);
      // The literal `FLAT-` prefix legitimately contains an L; only the
      // generated suffix must avoid ambiguous characters.
      final suffix = code.replaceFirst(AppConstants.invitePrefix, '');
      expect(suffix.contains(RegExp(r'[0O1IL]')), isFalse,
          reason: 'Ambiguous character in code: $code');
    }
  });

  test('codes vary across generations', () {
    final seen = <String>{};
    for (var i = 0; i < 200; i++) {
      seen.add(InviteCode.generate(random));
    }
    expect(seen.length, greaterThan(100));
  });

  test('generation is deterministic for a fixed seed', () {
    expect(InviteCode.generate(Random(7)), InviteCode.generate(Random(7)));
  });
}