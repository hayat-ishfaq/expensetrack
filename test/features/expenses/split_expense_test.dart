import 'package:expensetrack/features/expenses/domain/split_expense.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SplitCalculator.split', () {
    test('single participant gets the full amount', () {
      expect(SplitCalculator.split(5000, 1), [5000]);
      expect(SplitCalculator.split(0, 1), [0]);
    });

    test('even division produces equal shares', () {
      expect(SplitCalculator.split(1000, 2), [500, 500]);
      expect(SplitCalculator.split(3000, 3), [1000, 1000, 1000]);
      expect(SplitCalculator.split(0, 4), [0, 0, 0, 0]);
    });

    test('remainder is distributed as 1-paisa extras', () {
      // 1000 / 3 -> 334, 333, 333 (first shares get the extra paisa).
      expect(SplitCalculator.split(1000, 3), [334, 333, 333]);
      expect(SplitCalculator.split(100, 3), [34, 33, 33]);
    });

    test('shares always sum exactly to the amount', () {
      for (var amount = 0; amount < 500; amount++) {
        for (var count = 1; count <= 8; count++) {
          final shares = SplitCalculator.split(amount, count);
          expect(
            shares.reduce((a, b) => a + b),
            amount,
            reason: 'amount=$amount count=$count shares=$shares',
          );
        }
      }
    });

    test('all shares differ by at most 1 paisa', () {
      for (var amount = 0; amount < 500; amount++) {
        for (var count = 1; count <= 8; count++) {
          final shares = SplitCalculator.split(amount, count);
          final min = shares.reduce((a, b) => a < b ? a : b);
          final max = shares.reduce((a, b) => a > b ? a : b);
          expect(max - min, lessThanOrEqualTo(1),
              reason: 'amount=$amount count=$count shares=$shares');
        }
      }
    });

    test('shares are non-negative integers', () {
      for (var amount = 0; amount < 100; amount++) {
        for (var count = 1; count <= 6; count++) {
          final shares = SplitCalculator.split(amount, count);
          for (final share in shares) {
            expect(share, isNonNegative);
          }
        }
      }
    });

    test('amounts smaller than the participant count yield zero shares', () {
      expect(SplitCalculator.split(1, 3), [1, 0, 0]);
      expect(SplitCalculator.split(2, 4), [1, 1, 0, 0]);
    });

    test('deterministic across repeated calls', () {
      for (var i = 0; i < 5; i++) {
        expect(SplitCalculator.split(123457, 7), SplitCalculator.split(123457, 7));
      }
    });
  });
}