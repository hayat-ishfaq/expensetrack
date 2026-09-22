import 'expense.dart';

abstract class ExpenseRepository {
  /// Records a new shared expense in the household.
  Future<Expense> createExpense(Expense expense);

  /// Updates an existing expense.
  Future<void> updateExpense(Expense expense);

  /// Deletes an expense.
  Future<void> deleteExpense({
    required String householdId,
    required String expenseId,
  });

  /// Streams all expenses for the given [householdId], ordered by [spentAt] descending.
  Stream<List<Expense>> watchExpenses(String householdId);

  /// Streams the most recent [limit] expenses for the dashboard.
  Stream<List<Expense>> watchRecentExpenses(String householdId, {int limit = 5});
}
