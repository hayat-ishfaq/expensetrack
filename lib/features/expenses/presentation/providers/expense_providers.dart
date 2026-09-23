import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/session_provider.dart';
import '../../data/firebase_expense_repository.dart';
import '../../domain/expense.dart';
import '../../domain/expense_repository.dart';

/// Repository provider for expenses. Overridable in tests.
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return FirebaseExpenseRepository(FirebaseFirestore.instance);
});

/// Streams all expenses for the current user's household.
final householdExpensesProvider = StreamProvider<List<Expense>>((ref) {
  final householdId = ref.watch(sessionProvider).value?.householdId;
  if (householdId == null) return Stream.value(const []);
  return ref.watch(expenseRepositoryProvider).watchExpenses(householdId);
});

/// The most recent 5 expenses for the dashboard.
/// Re-uses the main household expenses stream to eliminate duplicate Firestore listeners.
final recentExpensesProvider = Provider<AsyncValue<List<Expense>>>((ref) {
  final allExpensesAsync = ref.watch(householdExpensesProvider);
  return allExpensesAsync.whenData((expenses) => expenses.take(5).toList());
});

/// Controller managing expense operations (create, update, delete).
class ExpenseActions extends AsyncNotifier<void> {
  @override
  Future<void> build() => Future.value();

  ExpenseRepository get _repository => ref.read(expenseRepositoryProvider);

  Future<void> addExpense(Expense expense) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.createExpense(expense);
    });
  }

  Future<void> updateExpense(Expense expense) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.updateExpense(expense);
    });
  }

  Future<void> deleteExpense({
    required String householdId,
    required String expenseId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteExpense(
        householdId: householdId,
        expenseId: expenseId,
      );
    });
  }
}

final expenseActionsProvider =
    AsyncNotifierProvider<ExpenseActions, void>(ExpenseActions.new);
