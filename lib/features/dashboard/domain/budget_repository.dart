/// Abstract repository interface for budget read/write operations.
///
/// Concrete implementation: [FirebaseBudgetRepository].
abstract interface class BudgetRepository {
  /// Returns the total monthly budget (paisa) for [householdId],
  /// or `null` when no budget has been set.
  Future<int?> fetchTotalBudget({required String householdId});

  /// Returns a map of category-id -> budget (paisa) for [householdId].
  Future<Map<String, int>> fetchCategoryBudgets({required String householdId});

  /// Returns a nested map of category-id -> member-id -> budget (paisa).
  Future<Map<String, Map<String, int>>> fetchMemberCategoryBudgets({
    required String householdId,
  });

  /// Overwrites the household-wide monthly budget cap.
  Future<void> updateTotalBudget({
    required String householdId,
    required int budgetPaisa,
  });

  /// Overwrites category budgets and optionally the per-member allocations.
  Future<void> updateCategoryBudgets({
    required String householdId,
    required Map<String, int> categoryBudgetsPaisa,
    Map<String, Map<String, int>> memberCategoryBudgetsPaisa = const {},
  });
}
