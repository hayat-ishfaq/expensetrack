import 'package:expensetrack/core/theme/app_theme.dart';
import 'package:expensetrack/features/auth/domain/auth_user.dart';
import 'package:expensetrack/features/auth/presentation/providers/auth_providers.dart';
import 'package:expensetrack/features/dashboard/presentation/screens/category_budget_screen.dart';
import 'package:expensetrack/features/expenses/domain/expense.dart';
import 'package:expensetrack/features/expenses/domain/expense_category.dart';
import 'package:expensetrack/features/expenses/presentation/providers/expense_providers.dart';
import 'package:expensetrack/features/household/presentation/providers/household_providers.dart';
import 'package:expensetrack/shared/models/app_user.dart';
import 'package:expensetrack/shared/models/household.dart';
import 'package:expensetrack/shared/models/household_member.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/fake_expense_repository.dart';
import '../../support/fake_household_repository.dart';

void main() {
  final now = DateTime.now();

  final ownerUser = AppUser(
    id: 'u-owner',
    name: 'Hayat Owner',
    email: 'owner@example.com',
    householdId: 'hh-1',
    createdAt: DateTime(2026, 1, 1),
  );

  final memberUser = AppUser(
    id: 'u-member',
    name: 'Ali Member',
    email: 'ali@example.com',
    householdId: 'hh-1',
    createdAt: DateTime(2026, 1, 1),
  );

  final members = [
    HouseholdMember(
      id: 'u-owner',
      name: 'Hayat Owner',
      email: 'owner@example.com',
      role: MemberRole.owner,
      joinedAt: DateTime(2026, 1, 1),
    ),
    HouseholdMember(
      id: 'u-member',
      name: 'Ali Member',
      email: 'ali@example.com',
      role: MemberRole.member,
      joinedAt: DateTime(2026, 1, 2),
    ),
  ];

  Widget buildScreen({
    required AppUser user,
    required Household household,
    List<HouseholdMember>? memberList,
    List<Expense>? expenses,
    ThemeMode themeMode = ThemeMode.light,
  }) {
    final auth = FakeAuthRepository(
      currentUser: AuthUser(uid: user.id, email: user.email),
      appUser: user,
    );
    final hhRepo = FakeHouseholdRepository(
      household: household,
      members: memberList ?? members,
    );
    final expRepo = FakeExpenseRepository(
      expenses: expenses ?? [],
    );

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        householdRepositoryProvider.overrideWithValue(hhRepo),
        expenseRepositoryProvider.overrideWithValue(expRepo),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        home: const CategoryBudgetScreen(),
      ),
    );
  }

  group('CategoryBudgetScreen - Owner Experience', () {
    testWidgets('renders monthly budget hero, edit inputs, and save CTA',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final household = Household(
        id: 'hh-1',
        name: 'CoSpend Flat',
        ownerId: 'u-owner',
        inviteCode: 'FLAT-1234',
        memberCount: 2,
        monthlyBudgetPaisa: 0,
        categoryBudgetsPaisa: {
          ExpenseCategory.rent.id: 2000000, // Rs. 20,000 for rent
        },
        currency: 'PKR',
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        buildScreen(
          user: ownerUser,
          household: household,
        ),
      );
      await tester.pumpAndSettle();

      // Monthly budget hero exists
      expect(find.text('TOTAL MONTHLY BUDGET'), findsOneWidget);
      expect(find.text('Rs. 20,000'), findsWidgets);

      // Owner should see editable input with Rs. 20000 in controller
      expect(find.byType(TextField), findsWidgets);
      expect(
        find.byWidgetPredicate(
          (w) => w is TextField && w.controller?.text == '20000',
        ),
        findsOneWidget,
      );

      // Owner should see quick chips
      expect(find.text('+1,000'), findsWidgets);
      expect(find.text('+5,000'), findsWidgets);
      expect(find.text('+10,000'), findsWidgets);
      expect(find.text('✕ Clear'), findsOneWidget);

      // Owner should see save button
      expect(find.byKey(const Key('save_budgets_button')), findsOneWidget);
      expect(find.text('Save Budgets & Allocations'), findsOneWidget);

      // Owner should NOT see the member view-only banner
      expect(find.text('Managed by household owner'), findsNothing);
    });

    testWidgets('tapping quick increment chip increases amount',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final household = Household(
        id: 'hh-1',
        name: 'CoSpend Flat',
        ownerId: 'u-owner',
        inviteCode: 'FLAT-1234',
        memberCount: 2,
        monthlyBudgetPaisa: 0,
        categoryBudgetsPaisa: {
          ExpenseCategory.rent.id: 1000000, // Rs. 10,000
        },
        currency: 'PKR',
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        buildScreen(
          user: ownerUser,
          household: household,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) => w is TextField && w.controller?.text == '10000',
        ),
        findsOneWidget,
      );

      // Tap +5,000 chip for rent
      await tester.tap(find.text('+5,000').first);
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) => w is TextField && w.controller?.text == '15000',
        ),
        findsOneWidget,
      );
    });

    testWidgets('expand member division and trigger divide equally',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final household = Household(
        id: 'hh-1',
        name: 'CoSpend Flat',
        ownerId: 'u-owner',
        inviteCode: 'FLAT-1234',
        memberCount: 2,
        monthlyBudgetPaisa: 0,
        categoryBudgetsPaisa: {
          ExpenseCategory.rent.id: 2000000, // Rs. 20,000
        },
        currency: 'PKR',
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        buildScreen(
          user: ownerUser,
          household: household,
        ),
      );
      await tester.pumpAndSettle();

      // Tap member allocations accordion
      final memberAllocationsToggle = find.text('Member Allocations').first;
      await tester.tap(memberAllocationsToggle);
      await tester.pumpAndSettle();

      // Divide equally button should appear for owner with multiple members
      expect(find.text('Divide Equally'), findsOneWidget);

      // Tap Divide Equally
      await tester.tap(find.text('Divide Equally'));
      await tester.pumpAndSettle();

      // Each member should now have 10,000 (20,000 / 2)
      expect(
        find.byWidgetPredicate(
          (w) => w is TextField && w.controller?.text == '10000',
        ),
        findsNWidgets(2),
      );
      expect(find.text('Allocated: Rs. 20000 / 20000'), findsOneWidget);
    });
  });

  group('CategoryBudgetScreen - Member Experience', () {
    testWidgets(
        'renders view-only state with explanation banner and NO edit textfields',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final household = Household(
        id: 'hh-1',
        name: 'CoSpend Flat',
        ownerId: 'u-owner', // u-member is not owner
        inviteCode: 'FLAT-1234',
        memberCount: 2,
        monthlyBudgetPaisa: 0,
        categoryBudgetsPaisa: {
          ExpenseCategory.rent.id: 1500000, // Rs. 15,000
        },
        currency: 'PKR',
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        buildScreen(
          user: memberUser,
          household: household,
        ),
      );
      await tester.pumpAndSettle();

      // Must explain "Managed by household owner"
      expect(find.text('Managed by household owner'), findsOneWidget);
      expect(
        find.textContaining('Monthly caps and member quotas are configured by the flat owner'),
        findsOneWidget,
      );

      // Must NOT have any editable TextFields!
      expect(find.byType(TextField), findsNothing);

      // Must NOT have Clear All or Save button
      expect(find.byKey(const Key('clear_all_budgets_btn')), findsNothing);
      expect(find.byKey(const Key('save_budgets_button')), findsNothing);

      // Must NOT have quick increment chips
      expect(find.text('+1,000'), findsNothing);

      // Shows read-only limit
      expect(find.text('Rs. 15,000'), findsWidgets);
      expect(find.text('monthly cap'), findsWidgets);

      // Shows Member Quota card
      expect(find.text('Your Member Quota'), findsWidgets);
    });
  });

  group('CategoryBudgetScreen - Status Indicators & Multi-Attribute States', () {
    testWidgets('shows Healthy, Approaching, Exceeded, and Uncapped status badges',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final household = Household(
        id: 'hh-1',
        name: 'CoSpend Flat',
        ownerId: 'u-owner',
        inviteCode: 'FLAT-1234',
        memberCount: 2,
        monthlyBudgetPaisa: 0,
        categoryBudgetsPaisa: {
          ExpenseCategory.rent.id: 1000000, // Rs. 10,000
          ExpenseCategory.food.id: 500000, // Rs. 5,000
          ExpenseCategory.groceries.id: 400000, // Rs. 4,000
          // others are 0 (uncapped)
        },
        currency: 'PKR',
        createdAt: DateTime(2026, 1, 1),
      );

      final expenses = [
        // Rent: spent 3,000 / 10,000 (30% -> HEALTHY / ON TRACK)
        Expense(
          id: 'e1',
          householdId: 'hh-1',
          description: 'Rent Part 1',
          category: ExpenseCategory.rent,
          amountPaisa: 300000,
          paidById: 'u-owner',
          splitAmongIds: ['u-owner', 'u-member'],
          splitAmountsPaisa: [150000, 150000],
          spentAt: DateTime(now.year, now.month, 5),
          createdByUserId: 'u-owner',
          createdAt: DateTime(now.year, now.month, 5),
        ),
        // Food: spent 4,500 / 5,000 (90% -> APPROACHING)
        Expense(
          id: 'e2',
          householdId: 'hh-1',
          description: 'Dining Out',
          category: ExpenseCategory.food,
          amountPaisa: 450000,
          paidById: 'u-owner',
          splitAmongIds: ['u-owner', 'u-member'],
          splitAmountsPaisa: [225000, 225000],
          spentAt: DateTime(now.year, now.month, 8),
          createdByUserId: 'u-owner',
          createdAt: DateTime(now.year, now.month, 8),
        ),
        // Groceries: spent 6,000 / 4,000 (150% -> EXCEEDED)
        Expense(
          id: 'e3',
          householdId: 'hh-1',
          description: 'Grocery run',
          category: ExpenseCategory.groceries,
          amountPaisa: 600000,
          paidById: 'u-owner',
          splitAmongIds: ['u-owner', 'u-member'],
          splitAmountsPaisa: [300000, 300000],
          spentAt: DateTime(now.year, now.month, 10),
          createdByUserId: 'u-owner',
          createdAt: DateTime(now.year, now.month, 10),
        ),
      ];

      await tester.pumpWidget(
        buildScreen(
          user: ownerUser,
          household: household,
          expenses: expenses,
        ),
      );
      await tester.pumpAndSettle();

      // Check Healthy state (Icon + Text)
      expect(find.text('ON TRACK (30%)'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsWidgets);

      // Check Approaching state (Icon + Text)
      expect(find.text('APPROACHING (90%)'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsWidgets);

      // Check Exceeded state (Icon + Text)
      expect(find.textContaining('EXCEEDED BY Rs. 2,000'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsWidgets);

      // Check Uncapped state (Icon + Text)
      expect(find.text('UNCAPPED'), findsWidgets);
      expect(find.byIcon(Icons.all_inclusive_rounded), findsWidgets);
    });
  });

  group('CategoryBudgetScreen - Edge Cases & Layout Safety', () {
    testWidgets('handles large amounts without overflow', (tester) async {
      final household = Household(
        id: 'hh-1',
        name: 'CoSpend Flat',
        ownerId: 'u-owner',
        inviteCode: 'FLAT-1234',
        memberCount: 2,
        monthlyBudgetPaisa: 0,
        categoryBudgetsPaisa: {
          ExpenseCategory.rent.id: 5000000000, // Rs. 50,000,000
        },
        currency: 'PKR',
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        buildScreen(
          user: ownerUser,
          household: household,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) => w is TextField && w.controller?.text == '50000000',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly in dark mode', (tester) async {
      final household = Household(
        id: 'hh-1',
        name: 'CoSpend Flat',
        ownerId: 'u-owner',
        inviteCode: 'FLAT-1234',
        memberCount: 2,
        monthlyBudgetPaisa: 0,
        categoryBudgetsPaisa: {
          ExpenseCategory.rent.id: 1000000,
        },
        currency: 'PKR',
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        buildScreen(
          user: ownerUser,
          household: household,
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TOTAL MONTHLY BUDGET'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly on compact screen (320x480) with zero overflow',
        (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final household = Household(
        id: 'hh-1',
        name: 'CoSpend Flat',
        ownerId: 'u-owner',
        inviteCode: 'FLAT-1234',
        memberCount: 2,
        monthlyBudgetPaisa: 0,
        categoryBudgetsPaisa: {
          ExpenseCategory.rent.id: 1500000,
        },
        currency: 'PKR',
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        buildScreen(
          user: memberUser,
          household: household,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Managed by household owner'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
