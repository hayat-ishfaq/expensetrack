import 'package:expensetrack/core/utils/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money.tryParsePaisa', () {
    test('parses plain and grouped amounts', () {
      expect(Money.tryParsePaisa('1500'), 150000);
      expect(Money.tryParsePaisa('1,500'), 150000);
      expect(Money.tryParsePaisa('  1,500  '), 150000);
      expect(Money.tryParsePaisa('30,000'), 3000000);
    });

    test('parses currency prefixes and decimals', () {
      expect(Money.tryParsePaisa('Rs. 1,500'), 150000);
      expect(Money.tryParsePaisa('rs 1500'), 150000);
      expect(Money.tryParsePaisa('1500.50'), 150050);
      expect(Money.tryParsePaisa('1500.5'), 150050);
      expect(Money.tryParsePaisa('0.07'), 7);
    });

    test('accepts zero (validity of > 0 is the validator’s job)', () {
      expect(Money.tryParsePaisa('0'), 0);
      expect(Money.tryParsePaisa('0.00'), 0);
    });

    test('rejects invalid input', () {
      expect(Money.tryParsePaisa(null), isNull);
      expect(Money.tryParsePaisa(''), isNull);
      expect(Money.tryParsePaisa('   '), isNull);
      expect(Money.tryParsePaisa('-5'), isNull);
      expect(Money.tryParsePaisa('abc'), isNull);
      expect(Money.tryParsePaisa('NaN'), isNull);
      expect(Money.tryParsePaisa('Infinity'), isNull);
      expect(Money.tryParsePaisa('1e5'), isNull);
      expect(Money.tryParsePaisa('12.345'), isNull);
      expect(Money.tryParsePaisa('1500.'), isNull);
      expect(Money.tryParsePaisa('.5'), isNull);
      expect(Money.tryParsePaisa('15 00'), isNull);
    });
  });

  group('Money.format', () {
    test('formats whole rupees with grouping', () {
      expect(Money.format(150000), 'Rs. 1,500');
      expect(Money.format(3000000), 'Rs. 30,000');
      expect(Money.format(1450000), 'Rs. 14,500');
      expect(Money.format(0), 'Rs. 0');
    });

    test('shows decimals only when they exist', () {
      expect(Money.format(145050), 'Rs. 1,450.50');
      expect(Money.format(7), 'Rs. 0.07');
    });

    test('formats negatives', () {
      expect(Money.format(-200000), '-Rs. 2,000');
    });
  });

  group('Money.formatSigned', () {
    test('adds an explicit sign to credit balances', () {
      expect(Money.formatSigned(450000), '+Rs. 4,500');
      expect(Money.formatSigned(-200000), '-Rs. 2,000');
      expect(Money.formatSigned(0), 'Rs. 0');
    });
  });
}
