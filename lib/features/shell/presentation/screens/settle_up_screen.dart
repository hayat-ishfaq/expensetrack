import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/firebase_error_mapper.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/models/household_member.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../expenses/domain/expense.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';
import '../../../household/presentation/providers/household_providers.dart';
import '../../../settlement/domain/settlement.dart';
import '../../../settlement/presentation/providers/settlement_providers.dart';

/// Settle-up tab: who owes whom, with the fewest transfers possible.
class SettleUpScreen extends ConsumerWidget {
  const SettleUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settlementAsync = ref.watch(settlementProvider);
    final expensesAsync = ref.watch(householdExpensesProvider);
    final membersAsync = ref.watch(householdMembersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settle Up')),
      body: settlementAsync.when(
        loading: () => const _SettlementSkeleton(),
        error: (error, _) => ErrorView(
          message: error is AppException
              ? error.message
              : FirebaseErrorMapper.messageFor(error),
          onRetry: () {
            ref.invalidate(householdExpensesProvider);
            ref.invalidate(householdMembersProvider);
          },
        ),
        data: (settlement) {
          final hasExpenses =
              (expensesAsync.value ?? const <Expense>[]).isNotEmpty;
          if (!hasExpenses) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No expenses yet',
              message: 'Add your first expense to start splitting the bills.',
            );
          }
          if (settlement.isSettled) {
            return const EmptyState(
              icon: Icons.check_circle_outline,
              title: 'All settled up',
              message: 'Everyone is even — no transfers are needed right now.',
            );
          }
          return _SettlementView(
            settlement: settlement,
            membersAsync: membersAsync,
          );
        },
      ),
    );
  }
}

class _SettlementView extends ConsumerWidget {
  const _SettlementView({
    required this.settlement,
    required this.membersAsync,
  });

  final Settlement settlement;
  final AsyncValue<List<HouseholdMember>> membersAsync;

  String _nameFor(String id, List<HouseholdMember> members) {
    for (final member in members) {
      if (member.id == id && member.name.trim().isNotEmpty) return member.name;
    }
    return id;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final members = membersAsync.value ?? const <HouseholdMember>[];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SummaryCard(totalPaisa: settlement.totalOwedPaisa),
        const SizedBox(height: 20),
        Text(
          'Balances',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        for (final balance in settlement.balances)
          _BalanceTile(
            balance: balance,
            name: _nameFor(balance.memberId, members),
          ),
        const SizedBox(height: 20),
        Text(
          'How to settle',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        for (final transfer in settlement.transfers)
          _TransferTile(
            transfer: transfer,
            fromName: _nameFor(transfer.fromMemberId, members),
            toName: _nameFor(transfer.toMemberId, members),
          ),
        const SizedBox(height: 8),
        Text(
          'Suggestions only — settle however works best for your flat.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.totalPaisa});

  final int totalPaisa;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.swap_horiz_rounded,
                color: scheme.onPrimary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total to settle',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Money.format(totalPaisa),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceTile extends StatelessWidget {
  const _BalanceTile({required this.balance, required this.name});

  final SettlementBalance balance;
  final String name;

  static const Color _credit = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final initial =
        name.isEmpty ? '?' : name.trim().characters.first.toUpperCase();
    final color =
        balance.isOwed ? _credit : scheme.error;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.surfaceContainerHighest,
          child: Text(
            initial,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(balance.isOwed ? 'Is owed' : 'Owes'),
        trailing: Text(
          Money.formatSigned(balance.netPaisa),
          style: theme.textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

class _TransferTile extends StatelessWidget {
  const _TransferTile({
    required this.transfer,
    required this.fromName,
    required this.toName,
  });

  final SettlementTransfer transfer;
  final String fromName;
  final String toName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: scheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.arrow_forward_rounded,
            color: scheme.onSecondaryContainer,
            size: 20,
          ),
        ),
        title: Text(
          '$fromName pays $toName',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: Text(
          Money.format(transfer.amountPaisa),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

class _SettlementSkeleton extends StatelessWidget {
  const _SettlementSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        SkeletonBox(height: 78),
        SizedBox(height: 20),
        SkeletonBox(height: 24, width: 120),
        SizedBox(height: 10),
        SkeletonBox(height: 56),
        SizedBox(height: 8),
        SkeletonBox(height: 56),
        SizedBox(height: 20),
        SkeletonBox(height: 24, width: 120),
        SizedBox(height: 10),
        SkeletonBox(height: 56),
        SizedBox(height: 8),
        SkeletonBox(height: 56),
      ],
    );
  }
}