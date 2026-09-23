import 'package:expensetrack/core/theme/app_theme.dart';
import 'package:expensetrack/features/auth/domain/auth_user.dart';
import 'package:expensetrack/features/auth/presentation/providers/auth_providers.dart';
import 'package:expensetrack/features/expenses/presentation/providers/expense_providers.dart';
import 'package:expensetrack/features/expenses/presentation/screens/add_expense_screen.dart';
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

Widget _buildAddExpenseScreen({
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
      home: const AddExpenseScreen(),
    ),
  );
}

void main() {
  group('AddExpenseScreen Redesign Tests', () {
    testWidgets('renders visual amount hero with dominant Rs. and hint 0',
        (tester) async {
      final repo = FakeExpenseRepository();
      await tester.pumpWidget(_buildAddExpenseScreen(expenses: repo));
      await tester.pumpAndSettle();

      expect(find.text('Add Expense'), findsOneWidget);
      expect(find.text('HOW MUCH WAS SPENT?'), findsOneWidget);
      expect(find.text('Rs.'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('progressively reveals description, category, date, and payer',
        (tester) async {
      final repo = FakeExpenseRepository();
      await tester.pumpWidget(_buildAddExpenseScreen(expenses: repo));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(2)); // Amount & Description
      expect(find.text('CATEGORY'), findsOneWidget);
      expect(find.text('DATE'), findsOneWidget);
      expect(find.text('PAID BY'), findsOneWidget);
      expect(find.text('Ali Khan'), findsWidgets);
      expect(find.text('SPLIT EXPENSE'), findsOneWidget);
      expect(find.text('Equal'), findsOneWidget);
      expect(find.text('Exact'), findsOneWidget);
      expect(find.text('%'), findsOneWidget);
    });

    testWidgets('toggles participants in equal split mode and updates share',
        (tester) async {
      final repo = FakeExpenseRepository();
      await tester.pumpWidget(_buildAddExpenseScreen(expenses: repo));
      await tester.pumpAndSettle();

      // Enter amount: 1000
      await tester.enterText(find.byType(TextFormField).first, '1000');
      await tester.pumpAndSettle();

      // Two members selected initially => Rs. 500.00 / person
      expect(find.textContaining('Rs. 500'), findsWidgets);

      // Tap on Sara to exclude her
      final saraFinder = find.text('Sara');
      await tester.scrollUntilVisible(
        saraFinder,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(saraFinder);
      await tester.pumpAndSettle();

      // Now only Ali is selected => Rs. 1,000.00 / person and Sara is Excluded
      expect(find.text('Excluded'), findsOneWidget);
      expect(find.textContaining('Rs. 1,000'), findsWidgets);
    });

    testWidgets('switches split mode to Exact and shows allocation balance',
        (tester) async {
      final repo = FakeExpenseRepository();
      await tester.pumpWidget(_buildAddExpenseScreen(expenses: repo));
      await tester.pumpAndSettle();

      // Enter amount: 1200
      await tester.enterText(find.byType(TextFormField).first, '1200');
      await tester.pumpAndSettle();

      // Tap Exact segmented button
      final exactFinder = find.text('Exact');
      await tester.ensureVisible(exactFinder);
      await tester.pumpAndSettle();
      await tester.tap(exactFinder);
      await tester.pumpAndSettle();

      expect(find.textContaining('Allocated:'), findsOneWidget);
      expect(find.textContaining('Remaining:'), findsOneWidget);
    });

    testWidgets('switches split mode to % and validates 100%', (tester) async {
      final repo = FakeExpenseRepository();
      await tester.pumpWidget(_buildAddExpenseScreen(expenses: repo));
      await tester.pumpAndSettle();

      // Enter amount: 2000
      await tester.enterText(find.byType(TextFormField).first, '2000');
      await tester.pumpAndSettle();

      // Tap % segmented button
      final pctFinder = find.text('%');
      await tester.ensureVisible(pctFinder);
      await tester.pumpAndSettle();
      await tester.tap(pctFinder);
      await tester.pumpAndSettle();

      // Initial equal percentages (50.0% each) => 100.0%
      expect(find.text('Total: 100.0%'), findsOneWidget);
      expect(find.text('100% Balanced ✓'), findsOneWidget);
    });

    testWidgets('validates form and submits expense', (tester) async {
      final repo = FakeExpenseRepository();
      await tester.pumpWidget(_buildAddExpenseScreen(expenses: repo));
      await tester.pumpAndSettle();

      // Enter amount: 1500
      await tester.enterText(find.byType(TextFormField).first, '1500');
      // Enter description
      await tester.enterText(find.byType(TextFormField).at(1), 'Grocery shopping');
      await tester.pumpAndSettle();

      // Scroll to and tap Add Expense button
      final saveButton = find.byKey(const ValueKey('save_expense_button'));
      await tester.scrollUntilVisible(
        saveButton,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify repository recorded the expense
      expect(repo.expenses.length, 1);
      expect(repo.expenses.first.description, 'Grocery shopping');
      expect(repo.expenses.first.amountPaisa, 150000);
    });

    testWidgets('renders cleanly in Dark Mode', (tester) async {
      final repo = FakeExpenseRepository();
      await tester.pumpWidget(_buildAddExpenseScreen(
        expenses: repo,
        themeMode: ThemeMode.dark,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Add Expense'), findsOneWidget);
      expect(find.text('HOW MUCH WAS SPENT?'), findsOneWidget);
    });

    testWidgets('renders on small screen size (320x480) with zero overflow',
        (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = FakeExpenseRepository();
      await tester.pumpWidget(_buildAddExpenseScreen(expenses: repo));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Add Expense'), findsOneWidget);
    });
  });
}
