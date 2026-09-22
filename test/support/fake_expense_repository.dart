import 'package:expensetrack/features/expenses/domain/expense.dart';
import 'package:expensetrack/features/expenses/domain/expense_repository.dart';

/// In-memory [ExpenseRepository] for widget tests. No Firebase involved.
class FakeExpenseRepository implements ExpenseRepository {
  FakeExpenseRepository({this.expenses = const []});

  List<Expense> expenses;

  @override
  Stream<List<Expense>> watchExpenses(String householdId) async* {
    yield expenses;
  }

  @override
  Stream<List<Expense>> watchRecentExpenses(
    String householdId, {
    int limit = 5,
  }) async* {
    yield expenses.take(limit).toList();
  }

  @override
  Future<Expense> createExpense(Expense expense) async {
    expenses = [...expenses, expense];
    return expense;
  }

  @override
  Future<void> updateExpense(Expense expense) async {}

  @override
  Future<void> deleteExpense({
    required String householdId,
    required String expenseId,
  }) async {}
}