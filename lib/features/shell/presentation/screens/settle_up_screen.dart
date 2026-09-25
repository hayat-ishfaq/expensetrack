import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/firebase_error_mapper.dart';
import '../../../../core/theme/design_system.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settle Up',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: isDark ? Colors.white : CoSpendColors.prussianBlue,
          ),
        ),
      ),
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: CoSpendColors.jadeGreenLight,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.check_rounded,
                        color: CoSpendColors.jadeGreen,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'All settled up! 🎉',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Everyone is even — no transfers are needed right now.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final members = membersAsync.value ?? const <HouseholdMember>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        _SummaryHeroCard(totalPaisa: settlement.totalOwedPaisa),
        const SizedBox(height: 20),

        const SectionLabel('Balances', padding: EdgeInsets.only(bottom: 8)),
        for (final balance in settlement.balances)
          _BalanceTile(
            balance: balance,
            name: _nameFor(balance.memberId, members),
            isDark: isDark,
          ),

        const SizedBox(height: 16),
        const SectionLabel('How to settle', padding: EdgeInsets.only(bottom: 8)),
        for (final transfer in settlement.transfers)
          _TransferTile(
            transfer: transfer,
            fromName: _nameFor(transfer.fromMemberId, members),
            toName: _nameFor(transfer.toMemberId, members),
            isDark: isDark,
          ),

        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Suggestions only — settle however works best for your flat.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryHeroCard extends StatelessWidget {
  const _SummaryHeroCard({required this.totalPaisa});

  final int totalPaisa;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: CoSpendRadii.cardLargeRadius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: CoSpendColors.heroGradient,
        ),
        boxShadow: CoSpendShadows.heroBannerShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: CoSpendColors.glassWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: CoSpendColors.glassBorderWhite,
                width: 0.8,
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.swap_horiz_rounded,
              color: CoSpendColors.jadeGreen,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL TO SETTLE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: Color(0xFF93C5FD),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  Money.format(totalPaisa),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.6,
                    height: 1.1,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Across all flatmates',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceTile extends StatelessWidget {
  const _BalanceTile({
    required this.balance,
    required this.name,
    required this.isDark,
  });

  final SettlementBalance balance;
  final String name;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name.trim().characters.first.toUpperCase();
    final isOwed = balance.isOwed;
    final accentColor = isOwed ? CoSpendColors.jadeGreen : CoSpendColors.alertRed;
    final bgColor = isOwed
        ? CoSpendColors.jadeGreenTint
        : CoSpendColors.alertRedTint;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CoSpendCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: CoSpendColors.prussianBlueTint,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isOwed ? 'Is owed money' : 'Owes money',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: CoSpendRadii.pillRadius,
              ),
              child: Text(
                Money.formatSigned(balance.netPaisa),
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: -0.3,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
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
    required this.isDark,
  });

  final SettlementTransfer transfer;
  final String fromName;
  final String toName;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CoSpendCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: CoSpendColors.prussianBlueTint,
                borderRadius: BorderRadius.circular(CoSpendRadii.xs),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.arrow_forward_rounded,
                color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                      ),
                      children: [
                        TextSpan(
                          text: fromName,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const TextSpan(text: ' pays '),
                        TextSpan(
                          text: toName,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Transfer to settle',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              Money.format(transfer.amountPaisa),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15.5,
                letterSpacing: -0.3,
                color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
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
        SkeletonBox(height: 110, radius: 20),
        SizedBox(height: 20),
        SkeletonBox(height: 16, width: 80),
        SizedBox(height: 10),
        SkeletonBox(height: 66, radius: 16),
        SizedBox(height: 8),
        SkeletonBox(height: 66, radius: 16),
        SizedBox(height: 20),
        SkeletonBox(height: 16, width: 100),
        SizedBox(height: 10),
        SkeletonBox(height: 66, radius: 16),
        SizedBox(height: 8),
        SkeletonBox(height: 66, radius: 16),
      ],
    );
  }
}