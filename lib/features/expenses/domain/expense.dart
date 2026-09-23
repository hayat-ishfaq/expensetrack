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
    this.customCategoryId,
    this.subcategory,
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

  /// Optional ID of a household custom category if not using standard enum.
  final String? customCategoryId;

  /// Optional subcategory name (e.g. 'Groceries', 'Fast Food', 'Bill').
  final String? subcategory;

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

  factory Expense.fromMap(String id, Map<String, dynamic> map) {
    final catRaw = map['category'] as String?;
    final customCatId = map['customCategoryId'] as String? ??
        (ExpenseCategory.fromId(catRaw) == ExpenseCategory.other &&
                catRaw != null &&
                catRaw != 'other'
            ? catRaw
            : null);

    return Expense(
      id: id,
      householdId: map['householdId'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: ExpenseCategory.fromId(catRaw),
      customCategoryId: customCatId,
      subcategory: map['subcategory'] as String?,
      amountPaisa: (map['amountPaisa'] as num?)?.toInt() ?? 0,
      paidById: map['paidById'] as String? ?? '',
      splitAmongIds:
          (map['splitAmongIds'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      splitAmountsPaisa: (map['splitAmountsPaisa'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      spentAt: (map['spentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdByUserId: map['createdByUserId'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      splitType: map['splitType'] as String? ?? 'equal',
    );
  }

  Map<String, dynamic> toMap() => {
        'householdId': householdId,
        'description': description,
        'category': customCategoryId ?? category.id,
        'customCategoryId': customCategoryId,
        'subcategory': subcategory,
        'amountPaisa': amountPaisa,
        'paidById': paidById,
        'splitAmongIds': splitAmongIds,
        'splitAmountsPaisa': splitAmountsPaisa,
        'spentAt': Timestamp.fromDate(spentAt),
        'createdByUserId': createdByUserId,
        'createdAt': Timestamp.fromDate(createdAt),
        'splitType': splitType,
      };

  Expense copyWith({
    String? description,
    ExpenseCategory? category,
    String? customCategoryId,
    String? subcategory,
    int? amountPaisa,
    String? paidById,
    List<String>? splitAmongIds,
    List<int>? splitAmountsPaisa,
    DateTime? spentAt,
    String? splitType,
  }) =>
      Expense(
        id: id,
        householdId: householdId,
        description: description ?? this.description,
        category: category ?? this.category,
        customCategoryId: customCategoryId ?? this.customCategoryId,
        subcategory: subcategory ?? this.subcategory,
        amountPaisa: amountPaisa ?? this.amountPaisa,
        paidById: paidById ?? this.paidById,
        splitAmongIds: splitAmongIds ?? this.splitAmongIds,
        splitAmountsPaisa: splitAmountsPaisa ?? this.splitAmountsPaisa,
        spentAt: spentAt ?? this.spentAt,
        createdByUserId: createdByUserId,
        createdAt: createdAt,
        splitType: splitType ?? this.splitType,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Expense &&
          other.id == id &&
          other.description == description &&
          other.category == category &&
          other.customCategoryId == customCategoryId &&
          other.subcategory == subcategory &&
          other.amountPaisa == amountPaisa &&
          other.paidById == paidById &&
          other.splitType == splitType;

  @override
  int get hashCode => Object.hash(
        id,
        description,
        category,
        customCategoryId,
        subcategory,
        amountPaisa,
        paidById,
        splitType,
      );
}
