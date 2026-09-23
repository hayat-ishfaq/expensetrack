import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/expenses/domain/custom_category.dart';

/// Default curated subcategories for standard expense categories.
const Map<String, List<String>> defaultCategorySubcategories = {
  'food': ['Groceries', 'Fast Food', 'Snacks & Chai', 'Dining Out', 'Meat & Veg'],
  'electricity': ['Monthly Bill', 'Generator Fuel', 'Maintenance'],
  'internet': ['Monthly Bill', 'Router / Equipment', 'Add-on Data'],
  'water': ['Water Tanker', 'Drinking Bottles', 'Pipeline Bill'],
  'gas': ['Gas Cylinder', 'Pipeline Bill'],
  'household': ['Cleaning Items', 'Furniture', 'Kitchenware', 'Repairs'],
  'transport': ['Fuel / Petrol', 'Careem / Uber', 'Public Transit', 'Vehicle Maintenance'],
  'entertainment': ['Movies & Outings', 'Subscriptions', 'Gaming', 'Events'],
  'rent': ['Monthly Rent', 'Building Maintenance', 'Security Deposit'],
  'cleaning': ['Maid Salary', 'Cleaning Supplies', 'Laundry'],
  'other': ['Medical', 'Emergency', 'General'],
};

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
    this.customCategories = const [],
    this.categorySubcategories = const {},
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

  /// User-defined custom categories created for this household.
  final List<CustomCategory> customCategories;

  /// Subcategories defined for categories (maps categoryId -> list of subcategory names).
  final Map<String, List<String>> categorySubcategories;

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

  /// Returns total allocated budget for a member across all categories (in paisa).
  /// If member-specific quotas are set, sums them. If no member quotas are set,
  /// returns their equal share of the effective total budget.
  int getMemberTotalBudget(String userId) {
    int total = 0;
    for (final catBudget in memberCategoryBudgetsPaisa.values) {
      total += catBudget[userId] ?? 0;
    }
    if (total > 0) return total;
    if (memberCount > 0 && effectiveTotalBudgetPaisa > 0) {
      return (effectiveTotalBudgetPaisa / memberCount).round();
    }
    return 0;
  }

  /// Returns all available subcategories for [categoryId], combining default
  /// suggestions, custom category subcategories, and any added household subcategories.
  List<String> getSubcategories(String categoryId) {
    final result = <String>{};
    if (defaultCategorySubcategories.containsKey(categoryId)) {
      result.addAll(defaultCategorySubcategories[categoryId]!);
    }
    for (final custom in customCategories) {
      if (custom.id == categoryId) {
        result.addAll(custom.subcategories);
        break;
      }
    }
    if (categorySubcategories.containsKey(categoryId)) {
      result.addAll(categorySubcategories[categoryId]!);
    }
    return result.toList();
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

    final rawCustomCats = map['customCategories'] as List?;
    final customCategories = rawCustomCats
            ?.map((c) =>
                CustomCategory.fromMap(Map<String, dynamic>.from(c as Map)))
            .toList() ??
        const <CustomCategory>[];

    final rawSubcats = map['categorySubcategories'] as Map?;
    final categorySubcategories = <String, List<String>>{};
    if (rawSubcats != null) {
      rawSubcats.forEach((catId, list) {
        if (list is List) {
          categorySubcategories[catId.toString()] =
              list.map((e) => e.toString()).toList();
        }
      });
    }

    return Household(
      id: id,
      name: map['name'] as String? ?? '',
      ownerId: map['ownerId'] as String? ?? '',
      inviteCode: map['inviteCode'] as String? ?? '',
      memberCount: (map['memberCount'] as num?)?.toInt() ?? 1,
      monthlyBudgetPaisa: (map['monthlyBudgetPaisa'] as num?)?.toInt() ?? 0,
      categoryBudgetsPaisa: categoryBudgets,
      memberCategoryBudgetsPaisa: memberCategoryBudgets,
      customCategories: customCategories,
      categorySubcategories: categorySubcategories,
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
        'customCategories': customCategories.map((c) => c.toMap()).toList(),
        'categorySubcategories': categorySubcategories,
        'currency': currency,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  Household copyWith({
    String? name,
    int? memberCount,
    int? monthlyBudgetPaisa,
    Map<String, int>? categoryBudgetsPaisa,
    Map<String, Map<String, int>>? memberCategoryBudgetsPaisa,
    List<CustomCategory>? customCategories,
    Map<String, List<String>>? categorySubcategories,
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
        customCategories: customCategories ?? this.customCategories,
        categorySubcategories:
            categorySubcategories ?? this.categorySubcategories,
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