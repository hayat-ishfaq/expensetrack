import '../../expenses/domain/expense.dart';
import 'settlement.dart';

/// Pure-Dart settlement math — no Flutter, no Firebase.
///
/// Every expense already stores exact per-member shares
/// (`splitAmountsPaisa`), so settlement is only netting:
///
///     net(member) = Σ(what member paid) − Σ(member's stored shares)
///
/// Balances are then cleared with a greedy largest-debtor /
/// largest-creditor match, which never needs more than
/// *(participants − 1)* transfers. Output is fully deterministic: the same
/// inputs always yield the same balances and transfers, so UIs and tests can
/// rely on stable ordering.
abstract final class SettlementEngine {
  /// Computes the settlement for [expenses] across the given [memberIds].
  ///
  /// Anyone who appears in an expense — including people who have since left
  /// the flat — is included in the math so balances always conserve exactly.
  static Settlement compute({
    required List<Expense> expenses,
    Set<String> memberIds = const {},
  }) {
    // Union of the current household and everyone mentioned by an expense.
    final involved = <String>{...memberIds};
    for (final expense in expenses) {
      involved.add(expense.paidById);
      involved.addAll(expense.splitAmongIds);
    }
    if (involved.isEmpty) return Settlement.empty;

    final net = <String, int>{for (final id in involved) id: 0};
    for (final expense in expenses) {
      net[expense.paidById] = net[expense.paidById]! + expense.amountPaisa;
      for (var i = 0; i < expense.splitAmongIds.length; i++) {
        final share = i < expense.splitAmountsPaisa.length
            ? expense.splitAmountsPaisa[i]
            : 0;
        net[expense.splitAmongIds[i]] = net[expense.splitAmongIds[i]]! - share;
      }
    }

    final balances = net.entries
        .where((entry) => entry.value != 0)
        .map((entry) =>
            SettlementBalance(memberId: entry.key, netPaisa: entry.value))
        .toList()
      ..sort((a, b) => a.memberId.compareTo(b.memberId));

    if (balances.isEmpty) return Settlement.empty;

    // Deterministic ordering: ties on equal amounts break on member id.
    final debtors = balances.where((balance) => balance.owes).toList()
      ..sort((a, b) {
        final byAmount = a.netPaisa.compareTo(b.netPaisa);
        return byAmount != 0 ? byAmount : a.memberId.compareTo(b.memberId);
      });
    final creditors = balances.where((balance) => balance.isOwed).toList()
      ..sort((a, b) {
        final byAmount = b.netPaisa.compareTo(a.netPaisa);
        return byAmount != 0 ? byAmount : a.memberId.compareTo(b.memberId);
      });

    // Greedy match: walk debtors in order, each covered by the remaining
    // creditor with the largest credit. Every transfer fully clears at least
    // one side, so at most (participants − 1) transfers are produced.
    final transfers = <SettlementTransfer>[];
    var creditorIndex = 0;
    for (final debtor in debtors) {
      var remainingPaisa = -debtor.netPaisa;
      while (remainingPaisa > 0 && creditorIndex < creditors.length) {
        final credited = creditors[creditorIndex].netPaisa;
        if (credited <= 0) {
          creditorIndex++;
          continue;
        }
        final amount = remainingPaisa < credited ? remainingPaisa : credited;
        transfers.add(SettlementTransfer(
          fromMemberId: debtor.memberId,
          toMemberId: creditors[creditorIndex].memberId,
          amountPaisa: amount,
        ));
        creditors[creditorIndex] = SettlementBalance(
          memberId: creditors[creditorIndex].memberId,
          netPaisa: credited - amount,
        );
        remainingPaisa -= amount;
        if (credited - amount == 0) creditorIndex++;
      }
    }

    return Settlement(balances: balances, transfers: transfers);
  }
}