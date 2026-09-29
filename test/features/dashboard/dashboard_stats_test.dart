import 'package:expensetrack/features/dashboard/domain/dashboard_stats.dart';
import 'package:expensetrack/features/expenses/domain/expense.dart';
import 'package:expensetrack/features/expenses/domain/expense_category.dart';
import 'package:expensetrack/shared/models/household.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardStats', () {
    final now = DateTime(2026, 9, 23);

    final sampleExpenses = [
      // Hayat paid 14,500, split 3 ways (4,834, 4,833, 4,833)
      Expense(
        id: 'e1',
        householdId: 'h1',
        description: 'Groceries',
        category: ExpenseCategory.groceries,
        amountPaisa: 1450000,
        paidById: 'hayat',
        splitAmongIds: ['hayat', 'ali', 'ahmed'],
        splitAmountsPaisa: [483400, 483300, 483300],
        spentAt: DateTime(2026, 9, 5),
        createdByUserId: 'hayat',
        createdAt: DateTime(2026, 9, 5),
      ),
      // Ali paid 8,000, split 3 ways (2,667, 2,667, 2,666)
      Expense(
        id: 'e2',
        householdId: 'h1',
        description: 'Electricity',
        category: ExpenseCategory.electricity,
        amountPaisa: 800000,
        paidById: 'ali',
        splitAmongIds: ['hayat', 'ali', 'ahmed'],
        splitAmountsPaisa: [266700, 266700, 266600],
        spentAt: DateTime(2026, 9, 12),
        createdByUserId: 'ali',
        createdAt: DateTime(2026, 9, 12),
      ),
      // Ahmed paid 7,500, split 3 ways (2,500 each)
      Expense(
        id: 'e3',
        householdId: 'h1',
        description: 'Internet',
        category: ExpenseCategory.internet,
        amountPaisa: 750000,
        paidById: 'ahmed',
        splitAmongIds: ['hayat', 'ali', 'ahmed'],
        splitAmountsPaisa: [250000, 250000, 250000],
        spentAt: DateTime(2026, 9, 12),
        createdByUserId: 'ahmed',
        createdAt: DateTime(2026, 9, 12),
      ),
      // Expense from previous month (August) - should be ignored
      Expense(
        id: 'e4',
        householdId: 'h1',
        description: 'August Food',
        category: ExpenseCategory.food,
        amountPaisa: 500000,
        paidById: 'hayat',
        splitAmongIds: ['hayat'],
        splitAmountsPaisa: [500000],
        spentAt: DateTime(2026, 8, 20),
        createdByUserId: 'hayat',
        createdAt: DateTime(2026, 8, 20),
      ),
    ];

    test('calculates total spending for target month only', () {
      final stats = DashboardStats.fromExpenses(
        allExpenses: sampleExpenses,
        userId: 'hayat',
        targetMonth: now,
      );

      // 14,500 + 8,000 + 7,500 = 30,000 Rs. (3,000,000 paisa)
      expect(stats.totalSpendingPaisa, 3000000);
      expect(stats.expenseCount, 3);
    });

    test('calculates personal metrics for a creditor (Hayat)', () {
      final stats = DashboardStats.fromExpenses(
        allExpenses: sampleExpenses,
        userId: 'hayat',
        targetMonth: now,
      );

      expect(stats.userPaidPaisa, 1450000); // 14,500 Rs.
      // Share: 4,834 + 2,667 + 2,500 = 10,001 Rs. (1,000,100 paisa)
      expect(stats.userSharePaisa, 1000100);
      // Balance: 14,500 - 10,001 = +4,499 Rs. (credit)
      expect(stats.userBalancePaisa, 449900);
      expect(stats.userBalancePaisa > 0, isTrue);
    });

    test('calculates personal metrics for a debtor (Ali)', () {
      final stats = DashboardStats.fromExpenses(
        allExpenses: sampleExpenses,
        userId: 'ali',
        targetMonth: now,
      );

      expect(stats.userPaidPaisa, 800000); // 8,000 Rs.
      // Share: 4,833 + 2,667 + 2,500 = 10,000 Rs.
      expect(stats.userSharePaisa, 1000000);
      // Balance: 8,000 - 10,000 = -2,000 Rs. (debt)
      expect(stats.userBalancePaisa, -200000);
      expect(stats.userBalancePaisa < 0, isTrue);
    });

    test('identifies category breakdown and top category', () {
      final stats = DashboardStats.fromExpenses(
        allExpenses: sampleExpenses,
        userId: 'hayat',
        targetMonth: now,
      );

      expect(stats.categoryBreakdown[ExpenseCategory.groceries], 1450000);
      expect(stats.categoryBreakdown[ExpenseCategory.electricity], 800000);
      expect(stats.categoryBreakdown[ExpenseCategory.internet], 750000);
      expect(stats.highestCategory, ExpenseCategory.groceries);
    });

    test('identifies highest spending day', () {
      final stats = DashboardStats.fromExpenses(
        allExpenses: sampleExpenses,
        userId: 'hayat',
        targetMonth: now,
      );

      // Day 12 has 8,000 + 7,500 = 15,500 Rs. (greater than Day 5 with 14,500)
      expect(stats.highestSpendingDay, 12);
    });

    test('calculates effective total budget from category budgets sum', () {
      final householdWithCatBudgets = Household(
        id: 'h1',
        name: 'Model Town Flat',
        ownerId: 'u1',
        currency: 'PKR',
        createdAt: DateTime(2026, 9, 1),
        inviteCode: 'FLAT-TEST',
        memberCount: 3,
        monthlyBudgetPaisa: 5000000,
        categoryBudgetsPaisa: {
          'groceries': 1500000, // 15,000 Rs.
          'electricity': 1000000, // 10,000 Rs.
          'internet': 500000, // 5,000 Rs.
        },
      );

      // Sum of category budgets: 15,000 + 10,000 + 5,000 = 30,000 Rs.
      expect(householdWithCatBudgets.effectiveTotalBudgetPaisa, 3000000);

      final householdWithoutCatBudgets = Household(
        id: 'h2',
        name: 'Gulberg Flat',
        ownerId: 'u1',
        currency: 'PKR',
        createdAt: DateTime(2026, 9, 1),
        inviteCode: 'FLAT-TEST',
        memberCount: 3,
        monthlyBudgetPaisa: 5000000,
        categoryBudgetsPaisa: const {},
      );

      // Falls back to monthlyBudgetPaisa
      expect(householdWithoutCatBudgets.effectiveTotalBudgetPaisa, 5000000);
    });

    test('tracks individual user category spending by consumption share and payment', () {
      final stats = DashboardStats.fromExpenses(
        allExpenses: sampleExpenses,
        userId: 'ali',
        targetMonth: now,
      );

      // Ali's allocated share for electricity: 2,667 Rs. (266,700 paisa)
      expect(stats.userCategorySpending[ExpenseCategory.electricity], 266700);
      // Ali's allocated share for groceries: 4,833 Rs. (483,300 paisa)
      expect(stats.userCategorySpending[ExpenseCategory.groceries], 483300);

      // Ali paid out of pocket for electricity: 8,000 Rs. (800,000 paisa)
      expect(stats.userPaidCategorySpending[ExpenseCategory.electricity], 800000);
      // Ali didn't front groceries out of pocket (Hayat did)
      expect(stats.userPaidCategorySpending[ExpenseCategory.groceries], isNull);
    });

    test('correctly configures and accesses memberCategoryBudgetsPaisa', () {
      final household = Household(
        id: 'h1',
        name: 'DHA Phase 5 Flat',
        ownerId: 'u1',
        currency: 'PKR',
        createdAt: DateTime(2026, 9, 1),
        inviteCode: 'FLAT-TEST',
        memberCount: 3,
        monthlyBudgetPaisa: 3000000,
        categoryBudgetsPaisa: {
          'food': 3000000, // 30,000 Rs.
        },
        memberCategoryBudgetsPaisa: {
          'food': {
            'hayat': 1000000, // 10,000 Rs.
            'ali': 1000000,   // 10,000 Rs.
            'ahmed': 1000000, // 10,000 Rs.
          },
        },
      );

      expect(household.getMemberCategoryBudget('food', 'hayat'), 1000000);
      expect(household.getMemberCategoryBudget('food', 'ali'), 1000000);
      expect(household.getMemberCategoryBudget('food', 'unknown_user'), 0);
      expect(household.getMemberCategoryBudget('electricity', 'hayat'), 0);

      // Verify toMap and fromMap serialization roundtrip
      final map = household.toMap();
      final reconstituted = Household.fromMap(household.id, map);
      expect(reconstituted.getMemberCategoryBudget('food', 'hayat'), 1000000);
    });
  });
}


