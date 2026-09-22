import 'package:cloud_firestore/cloud_firestore.dart';

import 'expense_category.dart';

/// A single shared expense, mirroring `households/{id}/expenses/{eid}`.
///
/// All money is integer paisa (`amountPaisa`), consistent with the rest of
/// the app. Sums of [splitAmountsPaisa] always equal [amountPaisa] — the
/// split is computed with pure-Dart integer math by [SplitCalculator.split]
/// or custom/percentage split modes at write time and stored alongside
/// the expense so the UI and settlement engine never need to re-derive it.
class Expense {
  const Expense({
    required this.id,
    required this.householdId,
    required this.description,
    required this.category,
    required this.amountPaisa,
    required this.paidById,
    required this.splitAmongIds,
    required this.splitAmountsPaisa,
    required this.spentAt,
    required this.createdByUserId,
    required this.createdAt,
    this.splitType = 'equal',
  });

  final String id;
  final String householdId;
  final String description;
  final ExpenseCategory category;
  final int amountPaisa;

  /// uid of the member who fronted the money.
  final String paidById;

  /// Member uids this expense is split across (includes [paidById] if they share).
  final List<String> splitAmongIds;

  /// Per-participant share in paisa, parallel to [splitAmongIds]. Sums to
  /// [amountPaisa]; used directly by the settlement engine.
  final List<int> splitAmountsPaisa;

  final DateTime spentAt;
  final String createdByUserId;
  final DateTime createdAt;

  /// Split type used: 'equal', 'custom', or 'percentage'.
  final String splitType;

  factory Expense.fromMap(String id, Map<String, dynamic> map) => Expense(
        id: id,
        householdId: map['householdId'] as String? ?? '',
        description: map['description'] as String? ?? '',
        category: ExpenseCategory.fromId(map['category'] as String?),
        amountPaisa: map['amountPaisa'] as int? ?? 0,
        paidById: map['paidById'] as String? ?? '',
        splitAmongIds:
            (map['splitAmongIds'] as List?)?.cast<String>() ?? const [],
        splitAmountsPaisa:
            (map['splitAmountsPaisa'] as List?)?.cast<int>() ?? const [],
        spentAt: (map['spentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        createdByUserId: map['createdByUserId'] as String? ?? '',
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ??
            DateTime.now(),
        splitType: map['splitType'] as String? ?? 'equal',
      );

  Map<String, dynamic> toMap() => {
        'householdId': householdId,
        'description': description,
        'category': category.id,
        'amountPaisa': amountPaisa,
        'paidById': paidById,
        'splitAmongIds': splitAmongIds,
        'splitAmountsPaisa': splitAmountsPaisa,
        'spentAt': Timestamp.fromDate(spentAt),
        'createdByUserId': createdByUserId,
        'createdAt': Timestamp.fromDate(createdAt),
        'splitType': splitType,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Expense &&
          other.id == id &&
          other.description == description &&
          other.category == category &&
          other.amountPaisa == amountPaisa &&
          other.paidById == paidById &&
          other.splitType == splitType;

  @override
  int get hashCode =>
      Object.hash(id, description, category, amountPaisa, paidById, splitType);
}
