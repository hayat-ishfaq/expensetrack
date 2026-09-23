import 'package:expensetrack/core/theme/app_theme.dart';
import 'package:expensetrack/core/utils/money.dart';
import 'package:expensetrack/features/auth/domain/auth_user.dart';
import 'package:expensetrack/features/auth/presentation/providers/auth_providers.dart';
import 'package:expensetrack/features/expenses/domain/expense.dart';
import 'package:expensetrack/features/expenses/domain/expense_category.dart';
import 'package:expensetrack/features/expenses/presentation/providers/expense_providers.dart';
import 'package:expensetrack/features/household/presentation/providers/household_providers.dart';
import 'package:expensetrack/features/shell/presentation/screens/home_screen.dart';
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

final _householdWithBudget = Household(
  id: 'hh-1',
  name: 'CoSpend House',
  ownerId: 'u-ali',
  inviteCode: 'FLAT-1234',
  memberCount: 2,
  monthlyBudgetPaisa: 5000000, // Rs. 50,000
  categoryBudgetsPaisa: {
    'groceries': 2000000, // Rs. 20,000
    'electricity': 1500000, // Rs. 15,000
  },
  memberCategoryBudgetsPaisa: {
    'groceries': {'u-ali': 1000000, 'u-sara': 1000000},
  },
  currency: 'PKR',
  createdAt: DateTime(2026, 9, 1),
);

final _householdWithoutBudget = Household(
  id: 'hh-1',
  name: 'CoSpend House',
  ownerId: 'u-ali',
  inviteCode: 'FLAT-1234',
  memberCount: 2,
  monthlyBudgetPaisa: 0,
  currency: 'PKR',
  createdAt: DateTime(2026, 9, 1),
);

final _testExpenses = [
  Expense(
    id: 'exp-1',
    householdId: 'hh-1',
    description: 'Weekly Groceries',
    category: ExpenseCategory.groceries,
    amountPaisa: 450000, // Rs. 4,500
    paidById: 'u-ali',
    splitAmongIds: ['u-ali', 'u-sara'],
    splitAmountsPaisa: [225000, 225000],
    spentAt: DateTime.now(),
    createdByUserId: 'u-ali',
    createdAt: DateTime.now(),
  ),
  Expense(
    id: 'exp-2',
    householdId: 'hh-1',
    description: 'Electricity Bill',
    category: ExpenseCategory.electricity,
    amountPaisa: 300000, // Rs. 3,000
    paidById: 'u-sara',
    splitAmongIds: ['u-ali', 'u-sara'],
    splitAmountsPaisa: [150000, 150000],
    spentAt: DateTime.now(),
    createdByUserId: 'u-sara',
    createdAt: DateTime.now(),
  ),
];

Widget _buildHomeScreen({
  required FakeExpenseRepository expenses,
  required FakeHouseholdRepository household,
  ThemeMode themeMode = ThemeMode.light,
}) {
  final auth = FakeAuthRepository(
    currentUser: const AuthUser(uid: 'u-ali', email: 'ali@example.com'),
    appUser: _testUser,
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
      home: const HomeScreen(),
    ),
  );
}

void main() {
  group('HomeScreen Redesign Tests', () {
    testWidgets('renders top header with dynamic greeting, actual user name, and invite code',
        (tester) async {
      await tester.pumpWidget(_buildHomeScreen(
        expenses: FakeExpenseRepository(expenses: _testExpenses),
        household: FakeHouseholdRepository(
          household: _householdWithBudget,
          members: _members,
        ),
      ));
      await tester.pumpAndSettle();

      // Check User Name (NOT hardcoded, from authenticated session)
      expect(find.text('Ali Khan'), findsOneWidget);

      // Check Invite Code
      expect(find.text('FLAT-1234'), findsOneWidget);

      // Check Subtitle status
      expect(find.text('Your household is on track this month'), findsOneWidget);

      // Check Add Expense action
      expect(find.text('Add Expense'), findsOneWidget);
    });

    testWidgets('renders financial hero card with spent, total budget, and percentage',
        (tester) async {
      await tester.pumpWidget(_buildHomeScreen(
        expenses: FakeExpenseRepository(expenses: _testExpenses),
        household: FakeHouseholdRepository(
          household: _householdWithBudget,
          members: _members,
        ),
      ));
      await tester.pumpAndSettle();

      // Hero Card Tag
      expect(find.text('MONTHLY BUDGET'), findsOneWidget);
      expect(find.text('ON TRACK'), findsOneWidget);

      // Total spent across expenses: Rs. 4,500 + Rs. 3,000 = Rs. 7,500
      expect(find.text(Money.format(750000)), findsWidgets);
    });

    testWidgets('renders 4 financial metrics with correct labels', (tester) async {
      await tester.pumpWidget(_buildHomeScreen(
        expenses: FakeExpenseRepository(expenses: _testExpenses),
        household: FakeHouseholdRepository(
          household: _householdWithBudget,
          members: _members,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('TOTAL BUDGET'), findsOneWidget);
      expect(find.text('TOTAL SPENDINGS'), findsOneWidget);
      expect(find.text('YOUR SHARE'), findsOneWidget);
      expect(find.text('YOUR SPENDING'), findsOneWidget);
    });

    testWidgets('renders budget overview categories and recent activity', (tester) async {
      await tester.pumpWidget(_buildHomeScreen(
        expenses: FakeExpenseRepository(expenses: _testExpenses),
        household: FakeHouseholdRepository(
          household: _householdWithBudget,
          members: _members,
        ),
      ));
      await tester.pumpAndSettle();

      // Budget Overview
      expect(find.text('Budget Overview'), findsOneWidget);
      expect(find.text('Groceries'), findsWidgets);
      expect(find.text('Electricity'), findsWidgets);

      // Scroll to Recent Activity
      await tester.scrollUntilVisible(
        find.text('Recent Activity'),
        200,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.text('Weekly Groceries'), findsOneWidget);
      expect(find.text('Electricity Bill'), findsOneWidget);
    });

    testWidgets('renders empty state when no expenses exist', (tester) async {
      await tester.pumpWidget(_buildHomeScreen(
        expenses: FakeExpenseRepository(expenses: const []),
        household: FakeHouseholdRepository(
          household: _householdWithBudget,
          members: _members,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('No expenses recorded yet'),
        200,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();

      expect(find.text('No expenses recorded yet'), findsOneWidget);
    });

    testWidgets('renders CTA card when household budget is unset', (tester) async {
      await tester.pumpWidget(_buildHomeScreen(
        expenses: FakeExpenseRepository(expenses: const []),
        household: FakeHouseholdRepository(
          household: _householdWithoutBudget,
          members: _members,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No Monthly Budget Set'), findsOneWidget);
      expect(find.text('Set Target'), findsOneWidget);
    });

    testWidgets('renders in Dark Mode without layout or visual errors', (tester) async {
      await tester.pumpWidget(_buildHomeScreen(
        expenses: FakeExpenseRepository(expenses: _testExpenses),
        household: FakeHouseholdRepository(
          household: _householdWithBudget,
          members: _members,
        ),
        themeMode: ThemeMode.dark,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Ali Khan'), findsOneWidget);
      expect(find.text('MONTHLY BUDGET'), findsOneWidget);
    });

    testWidgets('renders on compact screen size (320x480) with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildHomeScreen(
        expenses: FakeExpenseRepository(expenses: _testExpenses),
        household: FakeHouseholdRepository(
          household: _householdWithBudget,
          members: _members,
        ),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Ali Khan'), findsOneWidget);
    });
  });
}
