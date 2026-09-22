import 'split_expense.dart';

enum SplitMode {
  equal(label: 'Equally'),
  custom(label: 'Exact amounts'),
  percentage(label: 'By %');

  const SplitMode({required this.label});
  final String label;
}

/// Utility for validating and calculating expense splits across participants.
abstract final class SplitHelper {
  /// Computes equal split shares for [totalPaisa] across [participantCount].
  static List<int> computeEqualShares(int totalPaisa, int participantCount) {
    if (participantCount <= 0 || totalPaisa <= 0) return const [];
    return SplitCalculator.split(totalPaisa, participantCount);
  }

  /// Validates a custom split.
  ///
  /// Returns `null` if valid, or a user-facing error message describing what is wrong.
  static String? validateCustomShares({
    required int totalPaisa,
    required List<int> sharesPaisa,
  }) {
    if (totalPaisa <= 0) return 'Total amount must be greater than zero.';
    if (sharesPaisa.isEmpty) return 'Select at least one participant.';
    for (final share in sharesPaisa) {
      if (share < 0) return 'Shares cannot be negative.';
    }
    final sum = sharesPaisa.fold<int>(0, (prev, curr) => prev + curr);
    if (sum != totalPaisa) {
      final diffPaisa = totalPaisa - sum;
      if (diffPaisa > 0) {
        return 'Allocate remaining amount (${(diffPaisa / 100).toStringAsFixed(0)} Rs.)';
      } else {
        return 'Over allocated by ${((-diffPaisa) / 100).toStringAsFixed(0)} Rs.';
      }
    }
    return null;
  }

  /// Computes integer paisa shares from a list of percentages (0-100).
  ///
  /// Guarantees that the returned shares sum EXACTLY to [totalPaisa] by
  /// allocating remainder cents to the largest percentages.
  static List<int> computePercentageShares({
    required int totalPaisa,
    required List<double> percentages,
  }) {
    if (percentages.isEmpty || totalPaisa <= 0) return const [];

    final rawShares = percentages.map((p) => (totalPaisa * (p / 100.0)).floor()).toList();
    var sumRaw = rawShares.fold<int>(0, (prev, curr) => prev + curr);
    var remainder = totalPaisa - sumRaw;

    // Distribute remaining paisa one by one to items with largest fractional parts
    final indicesWithFractions = List.generate(percentages.length, (i) {
      final exact = totalPaisa * (percentages[i] / 100.0);
      final fraction = exact - rawShares[i];
      return (index: i, fraction: fraction);
    });
    indicesWithFractions.sort((a, b) => b.fraction.compareTo(a.fraction));

    for (var i = 0; i < remainder && i < indicesWithFractions.length; i++) {
      final targetIdx = indicesWithFractions[i].index;
      rawShares[targetIdx] += 1;
    }

    return rawShares;
  }

  /// Validates percentage shares.
  ///
  /// Returns `null` if the percentages sum to ~100%, or an error message.
  static String? validatePercentages({
    required int totalPaisa,
    required List<double> percentages,
  }) {
    if (totalPaisa <= 0) return 'Total amount must be greater than zero.';
    if (percentages.isEmpty) return 'Select at least one participant.';
    for (final p in percentages) {
      if (p < 0) return 'Percentages cannot be negative.';
    }
    final sum = percentages.fold<double>(0.0, (prev, curr) => prev + curr);
    final diff = 100.0 - sum;
    if (diff.abs() > 0.05) {
      if (diff > 0) {
        return 'Percentages add up to ${sum.toStringAsFixed(1)}% (need ${diff.toStringAsFixed(1)}% more)';
      } else {
        return 'Percentages add up to ${sum.toStringAsFixed(1)}% (${(-diff).toStringAsFixed(1)}% over)';
      }
    }
    return null;
  }
}
