import 'package:expensetrack/features/expenses/domain/expense_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExpenseCategory', () {
    test('has exactly 12 categories', () {
      expect(ExpenseCategory.values.length, 12);
    });

    test('category ids are unique', () {
      final ids = ExpenseCategory.values.map((c) => c.id).toSet();
      expect(ids.length, ExpenseCategory.values.length,
          reason: 'every category needs a distinct Firestore id');
    });

    test('ids are lowercase machine-friendly slugs', () {
      for (final category in ExpenseCategory.values) {
        expect(
          category.id,
          matches(RegExp(r'^[a-z][a-zA-Z0-9]*$')),
          reason: '${category.label} has a non-slug id ${category.id}',
        );
        expect(category.id, isNot(category.id.toUpperCase()),
            reason: '${category.label} id must stay lowercase');
      }
    });

    test('every category has a non-empty label', () {
      for (final category in ExpenseCategory.values) {
        expect(category.label.trim(), isNotEmpty,
            reason: '${category.id} has an empty label');
      }
    });

    test('fromId round-trips known ids', () {
      for (final category in ExpenseCategory.values) {
        expect(ExpenseCategory.fromId(category.id), category);
      }
    });

    test('fromId falls back to other for unknown ids', () {
      expect(ExpenseCategory.fromId('nonexistent-xyz'), ExpenseCategory.other);
      expect(ExpenseCategory.fromId(''), ExpenseCategory.other);
      expect(ExpenseCategory.fromId(null), ExpenseCategory.other);
    });

    test('rent is the first category (default picker order)', () {
      expect(ExpenseCategory.values.first, ExpenseCategory.rent);
    });
  });
}