import 'package:expensetrack/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('accepts valid addresses', () {
      expect(Validators.email('hayat@example.com'), isNull);
      expect(Validators.email('  a.b+tag@uni.edu.pk  '), isNull);
    });

    test('rejects missing or malformed addresses', () {
      expect(Validators.email(null), isNotNull);
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('   '), isNotNull);
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('hayat@'), isNotNull);
      expect(Validators.email('hayat@example'), isNotNull);
    });
  });

  group('Validators.password', () {
    test('requires at least 8 characters', () {
      expect(Validators.password(null), isNotNull);
      expect(Validators.password(''), isNotNull);
      expect(Validators.password('short'), isNotNull);
      expect(Validators.password('12345678'), isNull);
    });

    test('confirmPassword checks equality', () {
      expect(Validators.confirmPassword('secret123', 'secret123'), isNull);
      expect(Validators.confirmPassword('secret999', 'secret123'), isNotNull);
      expect(Validators.confirmPassword('', 'secret123'), isNotNull);
    });
  });

  group('Validators.amount', () {
    test('requires a positive numeric amount', () {
      expect(Validators.amount(null), isNotNull);
      expect(Validators.amount(''), isNotNull);
      expect(Validators.amount('0'), isNotNull);
      expect(Validators.amount('-100'), isNotNull);
      expect(Validators.amount('abc'), isNotNull);
      expect(Validators.amount('1000'), isNull);
      expect(Validators.amount('1,500.50'), isNull);
    });
  });

  group('Validators.name / flatName / description', () {
    test('name validation', () {
      expect(Validators.name(null), isNotNull);
      expect(Validators.name('H'), isNotNull);
      expect(Validators.name('Hayat Ullah'), isNull);
      expect(Validators.name('a' * 61), isNotNull);
    });

    test('flat name validation', () {
      expect(Validators.flatName(null), isNotNull);
      expect(Validators.flatName('   '), isNotNull);
      expect(Validators.flatName('Air University Hostel'), isNull);
      expect(Validators.flatName('x' * 51), isNotNull);
    });

    test('description validation', () {
      expect(Validators.description(null), isNotNull);
      expect(Validators.description(''), isNotNull);
      expect(Validators.description('Chicken + Drinks'), isNull);
      expect(Validators.description('x' * 121), isNotNull);
    });
  });

  group('Validators.inviteCode', () {
    test('normalizes case, spacing and missing prefix', () {
      expect(Validators.normalizeInviteCode(' 7k29 '), 'FLAT-7K29');
      expect(Validators.normalizeInviteCode('flat-7k29'), 'FLAT-7K29');
      expect(Validators.normalizeInviteCode('FLAT-7K29'), 'FLAT-7K29');
      expect(Validators.normalizeInviteCode(null), '');
    });

    test('validates normalized codes', () {
      expect(Validators.inviteCode('7k29'), isNull);
      expect(Validators.inviteCode('FLAT-7K29'), isNull);
      expect(Validators.inviteCode(''), isNotNull);
      expect(Validators.inviteCode('FLAT-'), isNotNull);
      expect(Validators.inviteCode('FLAT-TOOLONG'), isNotNull);
      expect(Validators.inviteCode('NOPE-1234'), isNotNull);
    });
  });
}
