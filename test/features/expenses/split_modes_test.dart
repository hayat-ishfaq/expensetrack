import 'package:expensetrack/features/expenses/domain/split_modes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SplitHelper - Equal Shares', () {
    test('splits evenly when divisible', () {
      final shares = SplitHelper.computeEqualShares(300000, 3);
      expect(shares, [100000, 100000, 100000]);
      expect(shares.fold<int>(0, (a, b) => a + b), 300000);
    });

    test('distributes remainder paisas without drift', () {
      final shares = SplitHelper.computeEqualShares(1000, 3);
      expect(shares, [334, 333, 333]);
      expect(shares.fold<int>(0, (a, b) => a + b), 1000);
    });

    test('handles single participant', () {
      final shares = SplitHelper.computeEqualShares(150000, 1);
      expect(shares, [150000]);
    });

    test('returns empty for invalid count or total', () {
      expect(SplitHelper.computeEqualShares(1000, 0), isEmpty);
      expect(SplitHelper.computeEqualShares(0, 3), isEmpty);
    });
  });

  group('SplitHelper - Custom Shares Validation', () {
    test('returns null when sum matches total', () {
      final err = SplitHelper.validateCustomShares(
        totalPaisa: 300000,
        sharesPaisa: [150000, 50000, 100000],
      );
      expect(err, isNull);
    });

    test('detects under-allocation', () {
      final err = SplitHelper.validateCustomShares(
        totalPaisa: 300000,
        sharesPaisa: [100000, 50000, 100000],
      );
      expect(err, isNotNull);
      expect(err, contains('Allocate remaining'));
    });

    test('detects over-allocation', () {
      final err = SplitHelper.validateCustomShares(
        totalPaisa: 300000,
        sharesPaisa: [200000, 100000, 100000],
      );
      expect(err, isNotNull);
      expect(err, contains('Over allocated'));
    });

    test('rejects negative share', () {
      final err = SplitHelper.validateCustomShares(
        totalPaisa: 300000,
        sharesPaisa: [350000, -50000],
      );
      expect(err, isNotNull);
      expect(err, contains('cannot be negative'));
    });
  });

  group('SplitHelper - Percentage Shares', () {
    test('computes exact paisa shares from clean percentages', () {
      final shares = SplitHelper.computePercentageShares(
        totalPaisa: 300000,
        percentages: [50.0, 25.0, 25.0],
      );
      expect(shares, [150000, 75000, 75000]);
      expect(shares.fold<int>(0, (a, b) => a + b), 300000);
    });

    test('guarantees exact sum even with repeating fractions', () {
      final shares = SplitHelper.computePercentageShares(
        totalPaisa: 100000,
        percentages: [33.33, 33.33, 33.34],
      );
      expect(shares.fold<int>(0, (a, b) => a + b), 100000);
    });

    test('guarantees exact sum conservation on large amounts with percentage drift', () {
      // 2,000,000 paisa (Rs. 20,000) with 49.98% + 49.98% (within the 0.05% tolerance)
      final shares = SplitHelper.computePercentageShares(
        totalPaisa: 2000000,
        percentages: [49.98, 49.98],
      );
      expect(shares.fold<int>(0, (a, b) => a + b), 2000000);
    });

    test('validates percentages sum to 100%', () {
      expect(
        SplitHelper.validatePercentages(
          totalPaisa: 100000,
          percentages: [50.0, 50.0],
        ),
        isNull,
      );

      final under = SplitHelper.validatePercentages(
        totalPaisa: 100000,
        percentages: [40.0, 50.0],
      );
      expect(under, contains('need 10.0% more'));

      final over = SplitHelper.validatePercentages(
        totalPaisa: 100000,
        percentages: [60.0, 50.0],
      );
      expect(over, contains('10.0% over'));
    });
  });
}
