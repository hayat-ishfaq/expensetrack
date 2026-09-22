/// One member's net position inside the household.
///
/// Positive [netPaisa] means the flat owes that member (a credit); negative
/// means the member owes the rest of the flat (a debt). All values are
/// integer paisa, matching the rest of the app.
class SettlementBalance {
  const SettlementBalance({
    required this.memberId,
    required this.netPaisa,
  });

  final String memberId;

  /// Positive = owed money, negative = owes money, never zero (zero-balance
  /// members are excluded from [Settlement.balances] entirely).
  final int netPaisa;

  /// Whether the flat owes this member.
  bool get isOwed => netPaisa > 0;

  /// Whether this member owes the flat.
  bool get owes => netPaisa < 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettlementBalance &&
          other.memberId == memberId &&
          other.netPaisa == netPaisa;

  @override
  int get hashCode => Object.hash(memberId, netPaisa);

  @override
  String toString() => 'SettlementBalance($memberId: $netPaisa)';
}

/// One suggested transfer: [fromMemberId] (the debtor) pays [toMemberId]
/// (the creditor) [amountPaisa].
class SettlementTransfer {
  const SettlementTransfer({
    required this.fromMemberId,
    required this.toMemberId,
    required this.amountPaisa,
  });

  final String fromMemberId;
  final String toMemberId;

  /// Always positive; a transfer never settles two members in the same
  /// direction twice.
  final int amountPaisa;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettlementTransfer &&
          other.fromMemberId == fromMemberId &&
          other.toMemberId == toMemberId &&
          other.amountPaisa == amountPaisa;

  @override
  int get hashCode => Object.hash(fromMemberId, toMemberId, amountPaisa);
}

/// The complete settlement picture for a household, produced by
/// `SettlementEngine.compute`.
class Settlement {
  const Settlement({required this.balances, required this.transfers});

  final List<SettlementBalance> balances;
  final List<SettlementTransfer> transfers;

  static const Settlement empty = Settlement(
    balances: [],
    transfers: [],
  );

  /// No transfers needed — the flat is even.
  bool get isSettled => transfers.isEmpty;

  /// Total amount that needs to change hands. Equals the sum of all credits
  /// (and, symmetrically, the absolute sum of all debts).
  int get totalOwedPaisa => balances
      .where((balance) => balance.isOwed)
      .fold(0, (sum, balance) => sum + balance.netPaisa);
}