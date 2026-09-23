import 'package:expensetrack/core/theme/app_theme.dart';
import 'package:expensetrack/features/auth/domain/auth_user.dart';
import 'package:expensetrack/features/auth/presentation/providers/auth_providers.dart';
import 'package:expensetrack/features/expenses/domain/expense.dart';
import 'package:expensetrack/features/expenses/domain/expense_category.dart';
import 'package:expensetrack/features/expenses/presentation/providers/expense_providers.dart';
import 'package:expensetrack/features/household/presentation/providers/household_providers.dart';
import 'package:expensetrack/features/shell/presentation/screens/settle_up_screen.dart';
import 'package:expensetrack/shared/models/app_user.dart';
import 'package:expensetrack/shared/models/household.dart';
import 'package:expensetrack/shared/models/household_member.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/fake_expense_repository.dart';
import '../../support/fake_household_repository.dart';

Expense _expense({
  required String id,
  required String paidById,
  required int amountPaisa,
  required List<String> splitAmongIds,
  required List<int> splitAmountsPaisa,
}) =>
    Expense(
      id: id,
      householdId: 'hh-1',
      description: 'Shared expense',
      category: ExpenseCategory.other,
      amountPaisa: amountPaisa,
      paidById: paidById,
      splitAmongIds: splitAmongIds,
      splitAmountsPaisa: splitAmountsPaisa,
      spentAt: DateTime(2026, 9, 20),
      createdByUserId: paidById,
      createdAt: DateTime(2026, 9, 20),
    );

final _members = [
  HouseholdMember(
    id: 'u-a',
    name: 'Ali',
    email: 'ali@example.com',
    role: MemberRole.owner,
    joinedAt: DateTime(2026, 9, 1),
  ),
  HouseholdMember(
    id: 'u-b',
    name: 'Sara',
    email: 'sara@example.com',
    role: MemberRole.member,
    joinedAt: DateTime(2026, 9, 2),
  ),
  HouseholdMember(
    id: 'u-c',
    name: 'Ahmed',
    email: 'ahmed@example.com',
    role: MemberRole.member,
    joinedAt: DateTime(2026, 9, 3),
  ),
];

final _household = Household(
  id: 'hh-1',
  name: 'Sunset Flats',
  ownerId: 'u-a',
  inviteCode: 'FLAT-0001',
  memberCount: 3,
  monthlyBudgetPaisa: 0,
  currency: 'PKR',
  createdAt: DateTime(2026, 9, 1),
);

Widget _buildApp({
  required FakeExpenseRepository expenses,
  required FakeHouseholdRepository household,
  String currentUserId = 'u-a',
  String currentUserName = 'Ali',
  ThemeMode themeMode = ThemeMode.light,
}) {
  final auth = FakeAuthRepository(
    currentUser: AuthUser(uid: currentUserId, email: '$currentUserId@example.com'),
    appUser: AppUser(
      id: currentUserId,
      name: currentUserName,
      email: '$currentUserId@example.com',
      householdId: 'hh-1',
      createdAt: DateTime(2026, 9, 1),
    ),
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
      home: const SettleUpScreen(),
    ),
  );
}

void main() {
  testWidgets('shows an empty state when there are no expenses',
      (tester) async {
    await tester.pumpWidget(_buildApp(
      expenses: FakeExpenseRepository(),
      household: FakeHouseholdRepository(
        household: _household,
        members: _members,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('No expenses yet'), findsOneWidget);
  });

  testWidgets('shows all settled up when expenses even out', (tester) async {
    await tester.pumpWidget(_buildApp(
      expenses: FakeExpenseRepository(expenses: [
        _expense(
          id: 'e1',
          paidById: 'u-a',
          amountPaisa: 1000,
          splitAmongIds: const ['u-a', 'u-b'],
          splitAmountsPaisa: const [500, 500],
        ),
        _expense(
          id: 'e2',
          paidById: 'u-b',
          amountPaisa: 1000,
          splitAmongIds: const ['u-a', 'u-b'],
          splitAmountsPaisa: const [500, 500],
        ),
      ]),
      household: FakeHouseholdRepository(
        household: _household,
        members: _members,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('All settled up'), findsOneWidget);
    expect(find.text('Sara pays Ali'), findsNothing);
  });

  testWidgets('shows balances and the suggested settle-up transfers',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Ali paid Rs. 3,000 split equally with Sara -> Sara owes Rs. 1,500.
    await tester.pumpWidget(_buildApp(
      expenses: FakeExpenseRepository(expenses: [
        _expense(
          id: 'e1',
          paidById: 'u-a',
          amountPaisa: 300000,
          splitAmongIds: const ['u-a', 'u-b'],
          splitAmountsPaisa: const [150000, 150000],
        ),
      ]),
      household: FakeHouseholdRepository(
        household: _household,
        members: _members,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Total to settle'), findsOneWidget);
    expect(find.text('+Rs. 1,500'), findsOneWidget, reason: 'Ali is owed');
    expect(find.text('-Rs. 1,500'), findsOneWidget, reason: 'Sara owes');
    expect(find.text('Sara pays Ali'), findsOneWidget);
    expect(find.text('Rs. 1,500'), findsWidgets);
  });

  testWidgets('shows personal reconciliation metrics: Total you owe & Total you are owed',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Sara (u-b) owes Ali (u-a) Rs. 1,500
    // Viewing as Sara (u-b):
    await tester.pumpWidget(_buildApp(
      currentUserId: 'u-b',
      currentUserName: 'Sara',
      expenses: FakeExpenseRepository(expenses: [
        _expense(
          id: 'e1',
          paidById: 'u-a',
          amountPaisa: 300000,
          splitAmongIds: const ['u-a', 'u-b'],
          splitAmountsPaisa: const [150000, 150000],
        ),
      ]),
      household: FakeHouseholdRepository(
        household: _household,
        members: _members,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Total you owe'), findsOneWidget);
    expect(find.text("Total you're owed"), findsOneWidget);
    expect(find.text('Net: In Debt'), findsOneWidget);
  });

  testWidgets('directional transfer visualization renders with downward arrow',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildApp(
      currentUserId: 'u-a',
      currentUserName: 'Ali',
      expenses: FakeExpenseRepository(expenses: [
        _expense(
          id: 'e1',
          paidById: 'u-a',
          amountPaisa: 300000,
          splitAmongIds: const ['u-a', 'u-b'],
          splitAmountsPaisa: const [150000, 150000],
        ),
      ]),
      household: FakeHouseholdRepository(
        household: _household,
        members: _members,
      ),
    ));
    await tester.pumpAndSettle();

    // Check downward arrow exists
    expect(find.byIcon(Icons.arrow_downward_rounded), findsWidgets);
    expect(find.text('Sara'), findsWidgets);
    expect(find.text('Ali'), findsWidgets);
    expect(find.text('Rs. 1,500'), findsWidgets);
  });

  testWidgets('settlement confirmation flow: Pending -> Confirm -> Settled',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildApp(
      currentUserId: 'u-a', // Ali is payee and owner
      currentUserName: 'Ali',
      expenses: FakeExpenseRepository(expenses: [
        _expense(
          id: 'e1',
          paidById: 'u-a',
          amountPaisa: 300000,
          splitAmongIds: const ['u-a', 'u-b'],
          splitAmountsPaisa: const [150000, 150000],
        ),
      ]),
      household: FakeHouseholdRepository(
        household: _household,
        members: _members,
      ),
    ));
    await tester.pumpAndSettle();

    // Starts in PENDING state
    expect(find.text('PENDING'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);

    // Tap Confirm button
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    // Confirmation dialog is shown
    expect(find.text('Confirm Settlement'), findsOneWidget);
    expect(find.text('Confirm & Settle'), findsOneWidget);

    // Confirm settlement
    await tester.tap(find.text('Confirm & Settle'));
    await tester.pumpAndSettle();

    // State transitions to SETTLED
    expect(find.text('SETTLED'), findsOneWidget);
    expect(find.text('Settled'), findsWidgets);
    expect(find.byKey(const ValueKey('settled_badge')), findsOneWidget);
  });

  testWidgets('prevents invalid settlement actions by uninvolved member',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildApp(
      currentUserId: 'u-c',
      currentUserName: 'Ahmed',
      expenses: FakeExpenseRepository(expenses: [
        _expense(
          id: 'e1',
          paidById: 'u-a',
          amountPaisa: 300000,
          splitAmongIds: const ['u-a', 'u-b'],
          splitAmountsPaisa: const [150000, 150000],
        ),
      ]),
      household: FakeHouseholdRepository(
        household: _household,
        members: _members,
      ),
    ));
    await tester.pumpAndSettle();

    // Confirm button should be disabled for Ahmed (onPressed == null)
    final confirmButton = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('confirm_btn')),
    );
    expect(confirmButton.onPressed, isNull);
  });

  testWidgets('renders cleanly in dark mode', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildApp(
      currentUserId: 'u-a',
      themeMode: ThemeMode.dark,
      expenses: FakeExpenseRepository(expenses: [
        _expense(
          id: 'e1',
          paidById: 'u-a',
          amountPaisa: 300000,
          splitAmongIds: const ['u-a', 'u-b'],
          splitAmountsPaisa: const [150000, 150000],
        ),
      ]),
      household: FakeHouseholdRepository(
        household: _household,
        members: _members,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Reconciliation & Settle Up'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders cleanly on compact screen (320x480) with zero overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildApp(
      currentUserId: 'u-a',
      expenses: FakeExpenseRepository(expenses: [
        _expense(
          id: 'e1',
          paidById: 'u-a',
          amountPaisa: 300000,
          splitAmongIds: const ['u-a', 'u-b'],
          splitAmountsPaisa: const [150000, 150000],
        ),
      ]),
      household: FakeHouseholdRepository(
        household: _household,
        members: _members,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Total you owe'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}