import 'package:expensetrack/features/auth/domain/auth_user.dart';
import 'package:expensetrack/features/auth/presentation/providers/auth_providers.dart';
import 'package:expensetrack/features/expenses/domain/expense.dart';
import 'package:expensetrack/features/expenses/domain/expense_category.dart';
import 'package:expensetrack/features/expenses/presentation/providers/expense_providers.dart';
import 'package:expensetrack/features/household/presentation/providers/household_providers.dart';
import 'package:expensetrack/features/settlement/presentation/providers/settlement_providers.dart';
import 'package:expensetrack/features/settlement/presentation/screens/settle_up_screen.dart';
import 'package:expensetrack/shared/models/app_user.dart';
import 'package:expensetrack/shared/models/household.dart';
import 'package:expensetrack/shared/models/household_member.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/fake_expense_repository.dart';
import '../../support/fake_household_repository.dart';
import '../../support/fake_settlement_repository.dart';

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
];

final _household = Household(
  id: 'hh-1',
  name: 'Sunset Flats',
  ownerId: 'u-a',
  inviteCode: 'FLAT-0001',
  memberCount: 2,
  monthlyBudgetPaisa: 0,
  currency: 'PKR',
  createdAt: DateTime(2026, 9, 1),
);

Widget _buildApp({
  required FakeExpenseRepository expenses,
  required FakeHouseholdRepository household,
}) {
  final auth = FakeAuthRepository(
    currentUser: const AuthUser(uid: 'u-a', email: 'ali@example.com'),
    appUser: AppUser(
      id: 'u-a',
      name: 'Ali',
      email: 'ali@example.com',
      householdId: 'hh-1',
      createdAt: DateTime(2026, 9, 1),
    ),
  );

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      expenseRepositoryProvider.overrideWithValue(expenses),
      householdRepositoryProvider.overrideWithValue(household),
      settlementRepositoryProvider.overrideWithValue(FakeSettlementRepository()),
    ],
    child: const MaterialApp(home: SettleUpScreen()),
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
}