import 'package:expensetrack/core/theme/app_theme.dart';
import 'package:expensetrack/features/auth/domain/auth_user.dart';
import 'package:expensetrack/features/auth/presentation/providers/auth_providers.dart';
import 'package:expensetrack/features/expenses/domain/expense.dart';
import 'package:expensetrack/features/expenses/domain/expense_category.dart';
import 'package:expensetrack/features/expenses/presentation/providers/expense_providers.dart';
import 'package:expensetrack/features/household/presentation/providers/household_providers.dart';
import 'package:expensetrack/features/shell/presentation/screens/expenses_screen.dart';
import 'package:expensetrack/shared/models/app_user.dart';
import 'package:expensetrack/shared/models/household.dart';
import 'package:expensetrack/shared/models/household_member.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/fake_expense_repository.dart';
import '../../support/fake_household_repository.dart';

final _testUser = AppUser(
  id: 'u-ali',
  name: 'Ali Khan',
  email: 'ali@example.com',
  householdId: 'hh-1',
  createdAt: DateTime(2026, 9, 1),
);

final _members = [
  HouseholdMember(
    id: 'u-ali',
    name: 'Ali Khan',
    email: 'ali@example.com',
    role: MemberRole.owner,
    joinedAt: DateTime(2026, 9, 1),
  ),
  HouseholdMember(
    id: 'u-sara',
    name: 'Sara',
    email: 'sara@example.com',
    role: MemberRole.member,
    joinedAt: DateTime(2026, 9, 2),
  ),
];

final _household = Household(
  id: 'hh-1',
  name: 'CoSpend House',
  ownerId: 'u-ali',
  inviteCode: 'FLAT-1234',
  memberCount: 2,
  monthlyBudgetPaisa: 5000000,
  currency: 'PKR',
  createdAt: DateTime(2026, 9, 1),
);

final _now = DateTime.now();
final _today = DateTime(_now.year, _now.month, _now.day, 14, 30);
final _yesterday = _today.subtract(const Duration(days: 1));
final _thisWeek = _today.subtract(const Duration(days: 3));
final _earlier = _today.subtract(const Duration(days: 20));

final _timelineExpenses = [
  Expense(
    id: 'exp-today',
    householdId: 'hh-1',
    description: 'Organic Milk & Eggs',
    category: ExpenseCategory.groceries,
    amountPaisa: 65000,
    paidById: 'u-ali',
    splitAmongIds: ['u-ali', 'u-sara'],
    splitAmountsPaisa: [32500, 32500],
    spentAt: _today,
    createdByUserId: 'u-ali',
    createdAt: _today,
  ),
  Expense(
    id: 'exp-yesterday',
    householdId: 'hh-1',
    description: 'Pizza Dinner',
    category: ExpenseCategory.food,
    amountPaisa: 180000,
    paidById: 'u-sara',
    splitAmongIds: ['u-ali', 'u-sara'],
    splitAmountsPaisa: [90000, 90000],
    spentAt: _yesterday,
    createdByUserId: 'u-sara',
    createdAt: _yesterday,
  ),
  Expense(
    id: 'exp-thisweek',
    householdId: 'hh-1',
    description: 'Cleaning Supplies',
    category: ExpenseCategory.cleaning,
    amountPaisa: 42000,
    paidById: 'u-ali',
    splitAmongIds: ['u-ali', 'u-sara'],
    splitAmountsPaisa: [21000, 21000],
    spentAt: _thisWeek,
    createdByUserId: 'u-ali',
    createdAt: _thisWeek,
  ),
  Expense(
    id: 'exp-earlier',
    householdId: 'hh-1',
    description: 'Monthly Apartment Rent',
    category: ExpenseCategory.rent,
    amountPaisa: 3500000,
    paidById: 'u-ali',
    splitAmongIds: ['u-ali', 'u-sara'],
    splitAmountsPaisa: [1750000, 1750000],
    spentAt: _earlier,
    createdByUserId: 'u-ali',
    createdAt: _earlier,
  ),
];

Widget _buildExpensesScreen({
  required FakeExpenseRepository expenses,
  ThemeMode themeMode = ThemeMode.light,
}) {
  final auth = FakeAuthRepository(
    currentUser: const AuthUser(uid: 'u-ali', email: 'ali@example.com'),
    appUser: _testUser,
  );
  final household = FakeHouseholdRepository(
    household: _household,
    members: _members,
  );

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      expenseRepositoryProvider.overrideWithValue(expenses),
      householdRepositoryProvider.overrideWithValue(household),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const ExpensesScreen(),
    ),
  );
}

void main() {
  group('ExpensesScreen Redesign Tests', () {
    testWidgets('renders timeline with 4-tier date grouping (Today, Yesterday, etc.)',
        (tester) async {
      await tester.pumpWidget(_buildExpensesScreen(
        expenses: FakeExpenseRepository(expenses: _timelineExpenses),
      ));
      await tester.pumpAndSettle();

      // Check Header
      expect(find.text('Expenses'), findsOneWidget);
      expect(find.text('4 total'), findsOneWidget);

      // Check Group Headers
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('YESTERDAY'), findsOneWidget);

      // Check Expenses
      expect(find.text('Organic Milk & Eggs'), findsOneWidget);
      expect(find.text('Pizza Dinner'), findsOneWidget);

      // Check Add Expense Action
      expect(find.text('Add Expense'), findsOneWidget);
    });

    testWidgets('search filters expenses by description or roommate name',
        (tester) async {
      await tester.pumpWidget(_buildExpensesScreen(
        expenses: FakeExpenseRepository(expenses: _timelineExpenses),
      ));
      await tester.pumpAndSettle();

      // Search for Pizza
      await tester.enterText(find.byType(TextField), 'Pizza');
      await tester.pumpAndSettle();

      expect(find.text('Pizza Dinner'), findsOneWidget);
      expect(find.text('Organic Milk & Eggs'), findsNothing);

      // Clear search
      await tester.tap(find.byIcon(Icons.clear_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Organic Milk & Eggs'), findsOneWidget);
    });

    testWidgets('animated category filter chip filters items', (tester) async {
      await tester.pumpWidget(_buildExpensesScreen(
        expenses: FakeExpenseRepository(expenses: _timelineExpenses),
      ));
      await tester.pumpAndSettle();

      // Tap Groceries chip
      await tester.tap(find.text('Groceries'));
      await tester.pumpAndSettle();

      expect(find.text('Organic Milk & Eggs'), findsOneWidget);
      expect(find.text('Pizza Dinner'), findsNothing);

      // Tap All chip to reset
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(find.text('Organic Milk & Eggs'), findsOneWidget);
      expect(find.text('Pizza Dinner'), findsOneWidget);
    });

    testWidgets('shows empty search state when query yields no results',
        (tester) async {
      await tester.pumpWidget(_buildExpensesScreen(
        expenses: FakeExpenseRepository(expenses: _timelineExpenses),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'NonExistentXYZ');
      await tester.pumpAndSettle();

      expect(find.text('No expenses found'), findsOneWidget);
      expect(find.text('Clear Filters'), findsOneWidget);

      // Tap Clear Filters
      await tester.tap(find.text('Clear Filters'));
      await tester.pumpAndSettle();

      expect(find.text('Organic Milk & Eggs'), findsOneWidget);
    });

    testWidgets('shows overall empty state when household has no expenses',
        (tester) async {
      await tester.pumpWidget(_buildExpensesScreen(
        expenses: FakeExpenseRepository(expenses: const []),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No expenses yet'), findsOneWidget);
      expect(find.text('Add your first expense'), findsOneWidget);
    });

    testWidgets('renders cleanly in Dark Mode', (tester) async {
      await tester.pumpWidget(_buildExpensesScreen(
        expenses: FakeExpenseRepository(expenses: _timelineExpenses),
        themeMode: ThemeMode.dark,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Expenses'), findsOneWidget);
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('Organic Milk & Eggs'), findsOneWidget);
    });

    testWidgets('renders on small screen size (320x480) with zero overflow',
        (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildExpensesScreen(
        expenses: FakeExpenseRepository(expenses: _timelineExpenses),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Expenses'), findsOneWidget);
    });
  });
}
