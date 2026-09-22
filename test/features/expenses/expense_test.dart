import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expensetrack/features/expenses/domain/expense.dart';
import 'package:expensetrack/features/expenses/domain/expense_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Expense', () {
    test('fromMap/toMap round-trip preserves all fields', () {
      final spentAt = DateTime(2026, 9, 20, 18, 30);
      final createdAt = DateTime(2026, 9, 20, 18, 45);

      final expense = Expense(
        id: 'expense-1',
        householdId: 'household-1',
        description: 'Weekly groceries',
        category: ExpenseCategory.groceries,
        amountPaisa: 450050,
        paidById: 'user-a',
        splitAmongIds: const ['user-a', 'user-b', 'user-c'],
        splitAmountsPaisa: const [150017, 150017, 150016],
        spentAt: spentAt,
        createdByUserId: 'user-a',
        createdAt: createdAt,
      );

      final map = expense.toMap();
      final restored = Expense.fromMap('expense-1', map);

      expect(restored.householdId, 'household-1');
      expect(restored.description, 'Weekly groceries');
      expect(restored.category, ExpenseCategory.groceries);
      expect(restored.amountPaisa, 450050);
      expect(restored.paidById, 'user-a');
      expect(restored.splitAmongIds, ['user-a', 'user-b', 'user-c']);
      expect(restored.splitAmountsPaisa, [150017, 150017, 150016]);
      expect(restored.spentAt, spentAt);
      expect(restored.createdByUserId, 'user-a');
      expect(restored.createdAt, createdAt);
    });

    test('splitAmountsPaisa sums to amountPaisa for a sample expense', () {
      const amount = 100000;
      const shares = [33334, 33333, 33333];
      expect(shares.reduce((a, b) => a + b), amount);
    });

    test('unknown category id maps to other (forward compatibility)', () {
      final expense = Expense.fromMap('e1', {
        'householdId': 'h1',
        'description': 'Mystery charge',
        'category': 'someFutureCategory',
        'amountPaisa': 100,
        'paidById': 'u1',
        'spentAt': Timestamp.now(),
        'createdAt': Timestamp.now(),
      });
      expect(expense.category, ExpenseCategory.other);
    });

    test('missing category maps to other', () {
      final expense = Expense.fromMap('e1', {
        'householdId': 'h1',
        'description': 'No category',
        'amountPaisa': 100,
        'paidById': 'u1',
        'spentAt': Timestamp.now(),
        'createdAt': Timestamp.now(),
      });
      expect(expense.category, ExpenseCategory.other);
    });

    test('unknown stored fields fall back to safe defaults', () {
      final expense = Expense.fromMap('e1', const {});
      expect(expense.description, '');
      expect(expense.amountPaisa, 0);
      expect(expense.splitAmongIds, isEmpty);
      expect(expense.splitAmountsPaisa, isEmpty);
    });

    test('toMap persists category as the stable string id', () {
      final expense = Expense(
        id: 'e1',
        householdId: 'h1',
        description: 'Rent',
        category: ExpenseCategory.rent,
        amountPaisa: 3000000,
        paidById: 'u1',
        splitAmongIds: const ['u1', 'u2'],
        splitAmountsPaisa: const [1500000, 1500000],
        spentAt: DateTime(2026, 9, 1),
        createdByUserId: 'u1',
        createdAt: DateTime(2026, 9, 1),
      );
      expect(expense.toMap()['category'], 'rent');
    });

    test('supports customCategoryId and subcategory round-trip', () {
      final expense = Expense(
        id: 'e2',
        householdId: 'h1',
        description: 'Monthly Gym Membership',
        category: ExpenseCategory.other,
        customCategoryId: 'cat_fitness_123',
        subcategory: 'Gym Pass',
        amountPaisa: 500000,
        paidById: 'u1',
        splitAmongIds: const ['u1'],
        splitAmountsPaisa: const [500000],
        spentAt: DateTime(2026, 9, 21),
        createdByUserId: 'u1',
        createdAt: DateTime(2026, 9, 21),
      );

      final map = expense.toMap();
      expect(map['customCategoryId'], 'cat_fitness_123');
      expect(map['subcategory'], 'Gym Pass');
      expect(map['category'], 'cat_fitness_123');

      final restored = Expense.fromMap('e2', map);
      expect(restored.customCategoryId, 'cat_fitness_123');
      expect(restored.subcategory, 'Gym Pass');
      expect(restored.category, ExpenseCategory.other);
    });

    test('copyWith updates fields correctly', () {
      final expense = Expense(
        id: 'e3',
        householdId: 'h1',
        description: 'Lunch',
        category: ExpenseCategory.food,
        amountPaisa: 120000,
        paidById: 'u1',
        splitAmongIds: const ['u1'],
        splitAmountsPaisa: const [120000],
        spentAt: DateTime(2026, 9, 22),
        createdByUserId: 'u1',
        createdAt: DateTime(2026, 9, 22),
      );

      final modified = expense.copyWith(
        subcategory: 'Fast Food',
        description: 'Burgers',
      );

      expect(modified.subcategory, 'Fast Food');
      expect(modified.description, 'Burgers');
      expect(modified.amountPaisa, 120000);
      expect(modified.id, 'e3');
    });
  });
}