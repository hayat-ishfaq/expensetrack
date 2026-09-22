import 'package:expensetrack/features/expenses/domain/expense.dart';
import 'package:expensetrack/features/expenses/domain/expense_category.dart';
import 'package:expensetrack/features/settlement/domain/settlement.dart';
import 'package:expensetrack/features/settlement/domain/settlement_engine.dart';
import 'package:flutter_test/flutter_test.dart';

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

Settlement _compute(List<Expense> expenses, [Set<String> memberIds = const {}]) =>
    SettlementEngine.compute(expenses: expenses, memberIds: memberIds);

void main() {
  group('SettlementEngine.expenses', () {
    test('empty expenses produce an empty, settled settlement', () {
      final settlement = _compute(const []);

      expect(settlement.balances, isEmpty);
      expect(settlement.transfers, isEmpty);
      expect(settlement.totalOwedPaisa, 0);
      expect(settlement.isSettled, isTrue);
    });

    test('a single person paying for themselves nets to zero', () {
      final settlement = _compute(
        [
          _expense(
            id: 'e1',
            paidById: 'a',
            amountPaisa: 50000,
            splitAmongIds: const ['a'],
            splitAmountsPaisa: const [50000],
          ),
        ],
        const {'a'},
      );

      expect(settlement.balances, isEmpty);
      expect(settlement.transfers, isEmpty);
      expect(settlement.isSettled, isTrue);
    });

    test('two members split one expense -> one transfer to the payer', () {
      // Ali pays Rs. 1,500, split equally with Sara.
      final settlement = _compute(
        [
          _expense(
            id: 'e1',
            paidById: 'a',
            amountPaisa: 150000,
            splitAmongIds: const ['a', 'b'],
            splitAmountsPaisa: const [75000, 75000],
          ),
        ],
        const {'a', 'b'},
      );

      expect(settlement.balances, [
        const SettlementBalance(memberId: 'a', netPaisa: 75000),
        const SettlementBalance(memberId: 'b', netPaisa: -75000),
      ]);
      expect(settlement.transfers, [
        const SettlementTransfer(
          fromMemberId: 'b',
          toMemberId: 'a',
          amountPaisa: 75000,
        ),
      ]);
      expect(settlement.totalOwedPaisa, 75000);
    });

    test('equal split with paisa remainder conserves the total exactly', () {
      // Rs. 10 split three ways -> 334 / 333 / 333 paisa.
      final settlement = _compute(
        [
          _expense(
            id: 'e1',
            paidById: 'a',
            amountPaisa: 1000,
            splitAmongIds: const ['a', 'b', 'c'],
            splitAmountsPaisa: const [334, 333, 333],
          ),
        ],
        const {'a', 'b', 'c'},
      );

      final sum =
          settlement.balances.fold<int>(0, (sum, b) => sum + b.netPaisa);
      expect(sum, 0, reason: 'balances must always conserve');
      expect(settlement.totalOwedPaisa, 666);

      final credits = settlement.balances.where((b) => b.isOwed);
      final debts = settlement.balances.where((b) => b.owes);
      expect(credits.fold<int>(0, (s, b) => s + b.netPaisa), 666);
      expect(debts.fold<int>(0, (s, b) => s - b.netPaisa), 666);

      expect(settlement.transfers, [
        const SettlementTransfer(
          fromMemberId: 'b',
          toMemberId: 'a',
          amountPaisa: 333,
        ),
        const SettlementTransfer(
          fromMemberId: 'c',
          toMemberId: 'a',
          amountPaisa: 333,
        ),
      ]);
    });

    test('expenses in both directions net into a single transfer', () {
      // Ali paid Rs. 100 (split 50/50), Sara paid Rs. 40 (split 20/20).
      final settlement = _compute(
        [
          _expense(
            id: 'e1',
            paidById: 'a',
            amountPaisa: 10000,
            splitAmongIds: const ['a', 'b'],
            splitAmountsPaisa: const [5000, 5000],
          ),
          _expense(
            id: 'e2',
            paidById: 'b',
            amountPaisa: 4000,
            splitAmongIds: const ['a', 'b'],
            splitAmountsPaisa: const [2000, 2000],
          ),
        ],
        const {'a', 'b'},
      );

      // Without netting this would be two transfers; netted -> exactly one.
      expect(settlement.transfers, [
        const SettlementTransfer(
          fromMemberId: 'b',
          toMemberId: 'a',
          amountPaisa: 3000,
        ),
      ]);
    });

    test('three members settle in at most (n - 1) transfers', () {
      final settlement = _compute(
        [
          _expense(
            id: 'e1',
            paidById: 'a',
            amountPaisa: 1000,
            splitAmongIds: const ['a', 'b'],
            splitAmountsPaisa: const [500, 500],
          ),
          _expense(
            id: 'e2',
            paidById: 'c',
            amountPaisa: 1000,
            splitAmongIds: const ['c', 'b'],
            splitAmountsPaisa: const [500, 500],
          ),
        ],
        const {'a', 'b', 'c'},
      );

      expect(settlement.transfers.length, lessThanOrEqualTo(2));
      expect(settlement.transfers, [
        const SettlementTransfer(
          fromMemberId: 'b',
          toMemberId: 'a',
          amountPaisa: 500,
        ),
        const SettlementTransfer(
          fromMemberId: 'b',
          toMemberId: 'c',
          amountPaisa: 500,
        ),
      ]);
    });

    test('a perfect circle needs no transfers at all', () {
      // A owes B owes C owes A, all for the same amount -> everyone nets zero.
      final settlement = _compute(
        [
          _expense(
            id: 'e1',
            paidById: 'a',
            amountPaisa: 9000,
            splitAmongIds: const ['b'],
            splitAmountsPaisa: const [9000],
          ),
          _expense(
            id: 'e2',
            paidById: 'b',
            amountPaisa: 9000,
            splitAmongIds: const ['c'],
            splitAmountsPaisa: const [9000],
          ),
          _expense(
            id: 'e3',
            paidById: 'c',
            amountPaisa: 9000,
            splitAmongIds: const ['a'],
            splitAmountsPaisa: const [9000],
          ),
        ],
        const {'a', 'b', 'c'},
      );

      expect(settlement.balances, isEmpty);
      expect(settlement.transfers, isEmpty);
      expect(settlement.isSettled, isTrue);
    });

    test('custom (uneven) shares are honored exactly', () {
      final settlement = _compute(
        [
          _expense(
            id: 'e1',
            paidById: 'a',
            amountPaisa: 1000,
            splitAmongIds: const ['a', 'b'],
            splitAmountsPaisa: const [600, 400],
          ),
        ],
        const {'a', 'b'},
      );

      expect(settlement.balances, [
        const SettlementBalance(memberId: 'a', netPaisa: 400),
        const SettlementBalance(memberId: 'b', netPaisa: -400),
      ]);
      expect(settlement.transfers.single.amountPaisa, 400);
    });

    test('zero-balance members are excluded from balances and transfers', () {
      final settlement = _compute(
        [
          _expense(
            id: 'e1',
            paidById: 'a',
            amountPaisa: 100,
            splitAmongIds: const ['a', 'b'],
            splitAmountsPaisa: const [50, 50],
          ),
        ],
        const {'a', 'b', 'c'},
      );

      final memberIds = settlement.balances.map((b) => b.memberId).toSet();
      expect(memberIds, {'a', 'b'});
      expect(memberIds, isNot(contains('c')));
    });

    test('no transfer is self-referential or non-positive', () {
      final settlement = _compute(
        [
          _expense(
            id: 'e1',
            paidById: 'a',
            amountPaisa: 12300,
            splitAmongIds: const ['a', 'b', 'c'],
            splitAmountsPaisa: const [4100, 4100, 4100],
          ),
          _expense(
            id: 'e2',
            paidById: 'c',
            amountPaisa: 5007,
            splitAmongIds: const ['c', 'b', 'd'],
            splitAmountsPaisa: const [1669, 1669, 1669],
          ),
          _expense(
            id: 'e3',
            paidById: 'b',
            amountPaisa: 900,
            splitAmongIds: const ['b', 'a'],
            splitAmountsPaisa: const [450, 450],
          ),
        ],
        const {'a', 'b', 'c', 'd'},
      );

      for (final transfer in settlement.transfers) {
        expect(transfer.amountPaisa, greaterThan(0));
        expect(transfer.fromMemberId, isNot(transfer.toMemberId));
      }
    });

    test('balances always sum to zero across a mixed scenario', () {
      final settlement = _compute(
        [
          _expense(
            id: 'e1',
            paidById: 'a',
            amountPaisa: 30000,
            splitAmongIds: const ['a', 'b', 'c'],
            splitAmountsPaisa: const [10000, 10000, 10000],
          ),
          _expense(
            id: 'e2',
            paidById: 'c',
            amountPaisa: 7777,
            splitAmongIds: const ['c', 'b'],
            splitAmountsPaisa: const [4000, 3777],
          ),
          _expense(
            id: 'e3',
            paidById: 'b',
            amountPaisa: 1234,
            splitAmongIds: const ['b', 'a', 'c'],
            splitAmountsPaisa: const [400, 400, 434],
          ),
        ],
        const {'a', 'b', 'c'},
      );

      final sum =
          settlement.balances.fold<int>(0, (total, b) => total + b.netPaisa);
      expect(sum, 0);

      final credits = settlement.balances.where((b) => b.isOwed);
      final debts = settlement.balances.where((b) => b.owes);
      final creditSum = credits.fold<int>(0, (s, b) => s + b.netPaisa);
      final debtSum = debts.fold<int>(0, (s, b) => s - b.netPaisa);
      expect(creditSum, debtSum);
      expect(settlement.totalOwedPaisa, creditSum);
    });

    test('result is deterministic regardless of input or member order', () {
      final expenses = [
        _expense(
          id: 'e1',
          paidById: 'a',
          amountPaisa: 20000,
          splitAmongIds: const ['a', 'b', 'c'],
          splitAmountsPaisa: const [7000, 7000, 6000],
        ),
        _expense(
          id: 'e2',
          paidById: 'b',
          amountPaisa: 8000,
          splitAmongIds: const ['b', 'c'],
          splitAmountsPaisa: const [4000, 4000],
        ),
      ];

      final forward = _compute(expenses, const {'a', 'b', 'c'});
      final reversed = _compute(
        expenses.reversed.toList(),
        const {'c', 'b', 'a'},
      );

      expect(reversed.balances, forward.balances);
      expect(reversed.transfers, forward.transfers);
      expect(reversed.totalOwedPaisa, forward.totalOwedPaisa);
    });

    test('members who left the flat are still settled via their expenses', () {
      // Only 'a' is a current member; 'b' is an ex-flatmate with an open
      // share. They must still appear so the math conserves.
      final settlement = _compute(
        [
          _expense(
            id: 'e1',
            paidById: 'a',
            amountPaisa: 100,
            splitAmongIds: const ['a', 'b'],
            splitAmountsPaisa: const [50, 50],
          ),
        ],
        const {'a'},
      );

      expect(
        settlement.balances.map((b) => b.memberId).toSet(),
        {'a', 'b'},
      );
      expect(settlement.transfers, [
        const SettlementTransfer(
          fromMemberId: 'b',
          toMemberId: 'a',
          amountPaisa: 50,
        ),
      ]);
    });
  });
}