import 'package:cloud_firestore/cloud_firestore.dart';

/// A shared household ("flat"), mirroring the `households/{id}` document.
class Household {
  const Household({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.inviteCode,
    required this.memberCount,
    required this.monthlyBudgetPaisa,
    this.categoryBudgetsPaisa = const {},
    this.memberCategoryBudgetsPaisa = const {},
    required this.currency,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String ownerId;

  /// Join code shown to roommates, e.g. `FLAT-7K29`.
  final String inviteCode;
  final int memberCount;

  /// Overall monthly budget in paisa; 0 means unset.
  final int monthlyBudgetPaisa;

  /// Category-specific budgets in paisa: Category ID -> budget in paisa.
  final Map<String, int> categoryBudgetsPaisa;

  /// Member-specific division for category budgets:
  /// Category ID -> (User ID -> budget in paisa).
  final Map<String, Map<String, int>> memberCategoryBudgetsPaisa;

  final String currency;
  final DateTime createdAt;

  /// Returns total budget: either sum of category budgets (if configured)
  /// or overall monthly budget.
  int get effectiveTotalBudgetPaisa {
    if (categoryBudgetsPaisa.isNotEmpty) {
      return categoryBudgetsPaisa.values.fold<int>(0, (a, b) => a + b);
    }
    return monthlyBudgetPaisa;
  }

  /// Get a specific member's budget in a specific category (in paisa), or 0 if unset.
  int getMemberCategoryBudget(String categoryId, String userId) {
    return memberCategoryBudgetsPaisa[categoryId]?[userId] ?? 0;
  }

  factory Household.fromMap(String id, Map<String, dynamic> map) {
    final rawCatBudgets = map['categoryBudgetsPaisa'] as Map?;
    final categoryBudgets = rawCatBudgets?.map(
          (k, v) => MapEntry(k.toString(), (v as num).toInt()),
        ) ??
        const <String, int>{};

    final rawMemberBudgets = map['memberCategoryBudgetsPaisa'] as Map?;
    final memberCategoryBudgets = <String, Map<String, int>>{};

    if (rawMemberBudgets != null) {
      rawMemberBudgets.forEach((catKey, userBudgetsMap) {
        if (userBudgetsMap is Map) {
          final userMap = <String, int>{};
          userBudgetsMap.forEach((uid, amount) {
            userMap[uid.toString()] = (amount as num).toInt();
          });
          memberCategoryBudgets[catKey.toString()] = userMap;
        }
      });
    }

    return Household(
      id: id,
      name: map['name'] as String? ?? '',
      ownerId: map['ownerId'] as String? ?? '',
      inviteCode: map['inviteCode'] as String? ?? '',
      memberCount: map['memberCount'] as int? ?? 1,
      monthlyBudgetPaisa: map['monthlyBudgetPaisa'] as int? ?? 0,
      categoryBudgetsPaisa: categoryBudgets,
      memberCategoryBudgetsPaisa: memberCategoryBudgets,
      currency: map['currency'] as String? ?? 'PKR',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'ownerId': ownerId,
        'inviteCode': inviteCode,
        'memberCount': memberCount,
        'monthlyBudgetPaisa': monthlyBudgetPaisa,
        'categoryBudgetsPaisa': categoryBudgetsPaisa,
        'memberCategoryBudgetsPaisa': memberCategoryBudgetsPaisa,
        'currency': currency,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  Household copyWith({
    String? name,
    int? memberCount,
    int? monthlyBudgetPaisa,
    Map<String, int>? categoryBudgetsPaisa,
    Map<String, Map<String, int>>? memberCategoryBudgetsPaisa,
  }) =>
      Household(
        id: id,
        name: name ?? this.name,
        ownerId: ownerId,
        inviteCode: inviteCode,
        memberCount: memberCount ?? this.memberCount,
        monthlyBudgetPaisa:
            monthlyBudgetPaisa ?? this.monthlyBudgetPaisa,
        categoryBudgetsPaisa:
            categoryBudgetsPaisa ?? this.categoryBudgetsPaisa,
        memberCategoryBudgetsPaisa:
            memberCategoryBudgetsPaisa ?? this.memberCategoryBudgetsPaisa,
        currency: currency,
        createdAt: createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Household &&
          other.id == id &&
          other.name == name &&
          other.inviteCode == inviteCode &&
          other.memberCount == memberCount;

  @override
  int get hashCode => Object.hash(id, name, inviteCode, memberCount);
}