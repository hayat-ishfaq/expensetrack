import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/session_provider.dart';
import '../../../expenses/domain/expense_category.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';
import '../../../household/presentation/providers/household_providers.dart';
import '../../data/firebase_budget_repository.dart';
import '../../domain/budget_repository.dart';
import '../../domain/dashboard_stats.dart';

/// Riverpod provider for the [BudgetRepository] data layer.
/// Wire FirebaseBudgetRepository in production; override in tests.
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return FirebaseBudgetRepository(FirebaseFirestore.instance);
});

/// Currently selected month on the dashboard (defaults to current month).
class DashboardMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void setMonth(DateTime month) => state = month;
}

final dashboardMonthProvider =
    NotifierProvider<DashboardMonthNotifier, DateTime>(
  DashboardMonthNotifier.new,
);

/// Computes monthly financial statistics for the dashboard.
final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final expenses = ref.watch(householdExpensesProvider).value ?? const [];
  final userId = ref.watch(sessionProvider).value?.user?.id ?? '';
  final selectedMonth = ref.watch(dashboardMonthProvider);

  return DashboardStats.fromExpenses(
    allExpenses: expenses,
    userId: userId,
    targetMonth: selectedMonth,
  );
});

/// Progress of overall monthly budget.
class BudgetStatus {
  const BudgetStatus({
    required this.budgetPaisa,
    required this.spentPaisa,
    required this.percentage,
    required this.remainingPaisa,
    required this.isApproaching,
    required this.isExceeded,
    this.hasCategoryBudgets = false,
  });

  final int budgetPaisa;
  final int spentPaisa;
  final double percentage;
  final int remainingPaisa;
  final bool isApproaching;
  final bool isExceeded;
  final bool hasCategoryBudgets;
}

final budgetStatusProvider = Provider<BudgetStatus?>((ref) {
  final household = ref.watch(currentHouseholdProvider).value;
  if (household == null) return null;

  final totalBudget = household.effectiveTotalBudgetPaisa;
  if (totalBudget <= 0) return null;

  final stats = ref.watch(dashboardStatsProvider);
  final spent = stats.totalSpendingPaisa;
  final pct = (spent / totalBudget) * 100.0;
  final remaining = totalBudget - spent;

  return BudgetStatus(
    budgetPaisa: totalBudget,
    spentPaisa: spent,
    percentage: pct,
    remainingPaisa: remaining,
    isApproaching: pct >= 85.0 && pct < 100.0,
    isExceeded: pct >= 100.0,
    hasCategoryBudgets: household.categoryBudgetsPaisa.isNotEmpty,
  );
});

/// Progress and health of a single category budget (flat-wide).
class CategoryBudgetStatus {
  const CategoryBudgetStatus({
    required this.categoryId,
    required this.label,
    required this.icon,
    required this.color,
    required this.category,
    required this.budgetPaisa,
    required this.spentPaisa,
    required this.remainingPaisa,
    required this.percentage,
    required this.isApproaching,
    required this.isExceeded,
  });

  final String categoryId;
  final String label;
  final IconData icon;
  final Color color;
  final ExpenseCategory category;
  final int budgetPaisa;
  final int spentPaisa;
  final int remainingPaisa;
  final double percentage;
  final bool isApproaching;
  final bool isExceeded;
}

final categoryBudgetsStatusProvider =
    Provider<List<CategoryBudgetStatus>>((ref) {
  final household = ref.watch(currentHouseholdProvider).value;
  if (household == null || household.categoryBudgetsPaisa.isEmpty) {
    return const [];
  }

  final stats = ref.watch(dashboardStatsProvider);
  final result = <CategoryBudgetStatus>[];

  household.categoryBudgetsPaisa.forEach((catId, budgetPaisa) {
    if (budgetPaisa <= 0) return;
    final cat = ExpenseCategory.fromId(catId);
    final custom = household.customCategories
        .where((c) => c.id == catId)
        .firstOrNull;
    final label = custom?.label ?? cat.label;
    final icon = custom?.icon ?? cat.icon;
    final color = custom?.color ?? cat.color;

    final spent = stats.categoryIdBreakdown[catId] ??
        stats.categoryBreakdown[cat] ??
        0;
    final pct = (spent / budgetPaisa) * 100.0;
    final remaining = budgetPaisa - spent;

    result.add(
      CategoryBudgetStatus(
        categoryId: catId,
        label: label,
        icon: icon,
        color: color,
        category: cat,
        budgetPaisa: budgetPaisa,
        spentPaisa: spent,
        remainingPaisa: remaining,
        percentage: pct,
        isApproaching: pct >= 85.0 && pct < 100.0,
        isExceeded: pct >= 100.0,
      ),
    );
  });

  // Sort: exceeded first, then highest percentage used
  result.sort((a, b) => b.percentage.compareTo(a.percentage));
  return result;
});

/// Progress and health of a member's individual allocation for a category.
class MemberCategoryBudgetStatus {
  const MemberCategoryBudgetStatus({
    required this.categoryId,
    required this.label,
    required this.icon,
    required this.color,
    required this.category,
    required this.totalCategoryBudgetPaisa,
    required this.totalCategorySpentPaisa,
    required this.myBudgetPaisa,
    required this.mySpentPaisa,
    required this.myRemainingPaisa,
    required this.myPercentage,
    required this.isApproaching,
    required this.isExceeded,
  });

  final String categoryId;
  final String label;
  final IconData icon;
  final Color color;
  final ExpenseCategory category;
  final int totalCategoryBudgetPaisa;
  final int totalCategorySpentPaisa;
  final int myBudgetPaisa;
  final int mySpentPaisa;
  final int myRemainingPaisa;
  final double myPercentage;
  final bool isApproaching;
  final bool isExceeded;
}

/// Computes the current user's individual category budget statuses.
final myCategoryBudgetsStatusProvider =
    Provider<List<MemberCategoryBudgetStatus>>((ref) {
  final household = ref.watch(currentHouseholdProvider).value;
  final session = ref.watch(sessionProvider).value;
  final userId = session?.user?.id ?? '';
  if (household == null || userId.isEmpty) return const [];

  final stats = ref.watch(dashboardStatsProvider);
  final result = <MemberCategoryBudgetStatus>[];

  household.categoryBudgetsPaisa.forEach((catId, totalBudget) {
    if (totalBudget <= 0) return;
    final cat = ExpenseCategory.fromId(catId);
    final custom = household.customCategories
        .where((c) => c.id == catId)
        .firstOrNull;
    final label = custom?.label ?? cat.label;
    final icon = custom?.icon ?? cat.icon;
    final color = custom?.color ?? cat.color;

    final myBudget = household.getMemberCategoryBudget(catId, userId);
    if (myBudget <= 0) return;

    final mySpent = stats.userCategoryIdBreakdown[catId] ??
        stats.userCategorySpending[cat] ??
        0;
    final totalSpent = stats.categoryIdBreakdown[catId] ??
        stats.categoryBreakdown[cat] ??
        0;
    final pct = (mySpent / myBudget) * 100.0;
    final remaining = myBudget - mySpent;

    result.add(
      MemberCategoryBudgetStatus(
        categoryId: catId,
        label: label,
        icon: icon,
        color: color,
        category: cat,
        totalCategoryBudgetPaisa: totalBudget,
        totalCategorySpentPaisa: totalSpent,
        myBudgetPaisa: myBudget,
        mySpentPaisa: mySpent,
        myRemainingPaisa: remaining,
        myPercentage: pct,
        isApproaching: pct >= 85.0 && pct < 100.0,
        isExceeded: pct >= 100.0,
      ),
    );
  });

  result.sort((a, b) => b.myPercentage.compareTo(a.myPercentage));
  return result;
});

/// List of categories where current user's individual budget has been exhausted.
final exceededBudgetAlertsProvider =
    Provider<List<MemberCategoryBudgetStatus>>((ref) {
  final myBudgets = ref.watch(myCategoryBudgetsStatusProvider);
  return myBudgets.where((b) => b.isExceeded).toList();
});
