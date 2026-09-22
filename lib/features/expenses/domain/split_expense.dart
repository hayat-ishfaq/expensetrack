/// Pure-Dart split math for shared expenses.
///
/// Splitting an integer amount (`paisa`) across N participants in *integer*
/// paisa is non-trivial: either someone pays a rounding drift, or the shares
/// fail to sum to the total. This module distributes the remainder so that
/// every share is within 1 paisa of every other, and the shares always sum
/// EXACTLY to the amount. It is intentionally pure (no Flutter, no Firebase)
/// so it is trivially unit-testable and used identically by the expense
/// writer and the settlement engine.
abstract final class SplitCalculator {
  /// Splits [amountPaisa] across [participantCount] shares.
  ///
  /// Returns a list of length [participantCount] whose entries sum to
  /// [amountPaisa]. When the amount does not divide evenly, the first
  /// `amountPaisa % participantCount` shares get one extra paisa each, so all
  /// shares differ by at most 1 and no rounding drift is ever introduced.
  ///
  /// Throws [ArgumentError] if [participantCount] is not positive. Splitting
  /// across zero participants is invalid because an expense must be split
  /// across at least one member (the payer).
  static List<int> split(int amountPaisa, int participantCount) {
    if (participantCount < 1) {
      throw ArgumentError.value(
        participantCount,
        'participantCount',
        'must be a positive integer',
      );
    }
    if (participantCount == 1) return [amountPaisa];

    final base = amountPaisa ~/ participantCount;
    final remainder = amountPaisa % participantCount;
    return List<int>.generate(
      participantCount,
      (index) => base + (index < remainder ? 1 : 0),
      growable: false,
    );
  }
}
