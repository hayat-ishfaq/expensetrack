import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/firebase_error_mapper.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/models/household_member.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../expenses/domain/expense.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';
import '../../../household/presentation/providers/household_providers.dart';
import '../../domain/settlement.dart';
import '../providers/settlement_providers.dart';

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
          final recorded =
              ref.watch(recordedSettlementsProvider).value ?? const [];
          if (settlement.isSettled && recorded.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
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
                      'All settled up',
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

  HouseholdMember? _memberFor(String id, List<HouseholdMember> members) {
    for (final member in members) {
      if (member.id == id) return member;
    }
    return null;
  }

  void _showOverviewSheet(
    BuildContext context,
    Settlement settlement,
    List<HouseholdMember> members,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: isDark ? CoSpendColors.darkCard : CoSpendColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const TintedIcon(
                  icon: Icons.swap_horiz_rounded,
                  color: CoSpendColors.prussianBlue,
                ),
                const SizedBox(width: 12),
                Text(
                  'Settlement Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'CoSpend uses a smart greedy debt-simplification algorithm to settle all group expenses with the minimum number of transactions possible.',
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? CoSpendColors.darkCanvas : CoSpendColors.canvas,
                borderRadius: CoSpendRadii.cardRadius,
                border: Border.all(
                  color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total group debt:'),
                      Text(
                        Money.format(settlement.totalOwedPaisa),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Required transfers:'),
                      Text(
                        '${settlement.transfers.length} payments',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Active flatmates involved:'),
                      Text(
                        '${settlement.balances.length} members',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMemberBalanceSheet(
    BuildContext context,
    WidgetRef ref,
    SettlementBalance balance,
    String memberName,
    Settlement settlement,
    List<HouseholdMember> members,
    bool isDark,
  ) {
    final member = _memberFor(balance.memberId, members);
    final isOwed = balance.isOwed;
    final accentColor = isOwed ? CoSpendColors.jadeGreen : CoSpendColors.alertRed;

    // Look for transfers involving this member and the logged in user
    final relevantTransfers = settlement.transfers
        .where((t) =>
            t.fromMemberId == balance.memberId ||
            t.toMemberId == balance.memberId)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: isDark ? CoSpendColors.darkCard : CoSpendColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                AppAvatar(
                  name: memberName,
                  photoUrl: member?.photoUrl,
                  size: 46,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        memberName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                        ),
                      ),
                      Text(
                        isOwed ? 'Is owed by the flat' : 'Owes money to flat',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isOwed ? CoSpendColors.jadeGreenTint : CoSpendColors.alertRedTint,
                    borderRadius: CoSpendRadii.pillRadius,
                  ),
                  child: Text(
                    Money.formatSigned(balance.netPaisa),
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Transfers involving $memberName:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : CoSpendColors.prussianBlue,
              ),
            ),
            const SizedBox(height: 8),
            if (relevantTransfers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No direct transfers pending for $memberName.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                  ),
                ),
              )
            else
              for (final t in relevantTransfers)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? CoSpendColors.darkCanvas : CoSpendColors.canvas,
                      borderRadius: CoSpendRadii.cardRadius,
                      border: Border.all(
                        color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_nameFor(t.fromMemberId, members)} pays ${_nameFor(t.toMemberId, members)}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                        Text(
                          Money.format(t.amountPaisa),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransferSheet(
    BuildContext context,
    WidgetRef ref,
    SettlementTransfer transfer,
    String fromName,
    String toName,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: isDark ? CoSpendColors.darkCard : CoSpendColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const TintedIcon(
                  icon: Icons.payments_rounded,
                  color: CoSpendColors.jadeGreen,
                ),
                const SizedBox(width: 12),
                Text(
                  'Record Transfer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? CoSpendColors.darkCanvas : CoSpendColors.canvas,
                borderRadius: CoSpendRadii.cardRadius,
                border: Border.all(
                  color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Payer (Debtor):', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(fromName, style: const TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Recipient (Creditor):', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(toName, style: const TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Amount to settle:', style: TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                        Money.format(transfer.amountPaisa),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: CoSpendColors.jadeGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Supported payment methods: Cash in hand, JazzCash, EasyPaisa, or direct Bank Transfer. Record this transfer once payment has changed hands.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ref.read(settlementActionsProvider.notifier).record(transfer);
                    },
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Confirm Settle'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReceiptSheet(
    BuildContext context,
    RecordedSettlement payment,
    String fromName,
    String toName,
    String recorderName,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: isDark ? CoSpendColors.darkCard : CoSpendColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: CoSpendColors.jadeGreenLight,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.verified_rounded,
                    color: CoSpendColors.jadeGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settlement Receipt',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                        ),
                      ),
                      const Text(
                        'Completed transfer',
                        style: TextStyle(
                          fontSize: 12,
                          color: CoSpendColors.jadeGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? CoSpendColors.darkCanvas : CoSpendColors.canvas,
                borderRadius: CoSpendRadii.cardRadius,
                border: Border.all(
                  color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Amount Paid:'),
                      Text(
                        Money.format(payment.amountPaisa),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: CoSpendColors.jadeGreen,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Paid By:'),
                      Text(fromName, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Paid To:'),
                      Text(toName, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Settled On:'),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(payment.settledAt),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  if (recorderName.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Recorded By:'),
                        Text(recorderName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final members = membersAsync.value ?? const <HouseholdMember>[];
    final recorded =
        ref.watch(recordedSettlementsProvider).value ?? const [];
    final recording = ref.watch(settlementActionsProvider).isLoading;

    ref.listen<AsyncValue<void>>(settlementActionsProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        final error = next.error!;
        showAppSnack(
          context,
          error is AppException
              ? error.message
              : FirebaseErrorMapper.messageFor(error),
          error: true,
        );
      } else if (previous?.isLoading == true &&
          !next.isLoading &&
          !next.hasError) {
        showAppSnack(context, 'Settlement recorded.');
      }
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        if (settlement.isSettled) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? CoSpendColors.darkCard : CoSpendColors.white,
              borderRadius: CoSpendRadii.cardLargeRadius,
              border: Border.all(
                color: CoSpendColors.jadeGreen.withValues(alpha: 0.3),
                width: 1.2,
              ),
              boxShadow: isDark ? null : CoSpendShadows.card,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: CoSpendColors.jadeGreenLight,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.check_rounded,
                    color: CoSpendColors.jadeGreen,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All settled up!',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Everyone is even — past settlements are logged below.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ] else ...[
          _SummaryHeroCard(
            totalPaisa: settlement.totalOwedPaisa,
            onTap: () => _showOverviewSheet(context, settlement, members, isDark),
          ),
          const SizedBox(height: 20),
          const SectionLabel('Balances', padding: EdgeInsets.only(bottom: 8)),
          for (final balance in settlement.balances)
            _BalanceTile(
              balance: balance,
              name: _nameFor(balance.memberId, members),
              isDark: isDark,
              onTap: () => _showMemberBalanceSheet(
                context,
                ref,
                balance,
                _nameFor(balance.memberId, members),
                settlement,
                members,
                isDark,
              ),
            ),
          const SizedBox(height: 16),
          const SectionLabel('How to settle', padding: EdgeInsets.only(bottom: 8)),
          for (final transfer in settlement.transfers)
            _TransferTile(
              transfer: transfer,
              fromName: _nameFor(transfer.fromMemberId, members),
              toName: _nameFor(transfer.toMemberId, members),
              isDark: isDark,
              recording: recording,
              onRecord: () => _showTransferSheet(
                context,
                ref,
                transfer,
                _nameFor(transfer.fromMemberId, members),
                _nameFor(transfer.toMemberId, members),
                isDark,
              ),
            ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Tap any card to view details or record a payment.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                height: 1.5,
              ),
            ),
          ),
        ],
        if (recorded.isNotEmpty) ...[
          const SizedBox(height: 20),
          const SectionLabel(
            'Settlement history',
            padding: EdgeInsets.only(bottom: 8),
          ),
          for (final payment in recorded)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: CoSpendRadii.cardRadius,
                onTap: () => _showReceiptSheet(
                  context,
                  payment,
                  _nameFor(payment.fromUserId, members),
                  _nameFor(payment.toUserId, members),
                  _nameFor(payment.recordedByUserId, members),
                  isDark,
                ),
                child: CoSpendCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: CoSpendColors.jadeGreen.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.done_all_rounded,
                          size: 18,
                          color: CoSpendColors.jadeGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_nameFor(payment.fromUserId, members)} paid ${_nameFor(payment.toUserId, members)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('dd MMM yyyy, hh:mm a').format(payment.settledAt),
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textSubtle,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        Money.format(payment.amountPaisa),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: CoSpendColors.jadeGreen,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textSubtle,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _SummaryHeroCard extends StatelessWidget {
  const _SummaryHeroCard({
    required this.totalPaisa,
    this.onTap,
  });

  final int totalPaisa;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                    'Total to settle',
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
                    'Across all flatmates · Tap for summary',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white70,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceTile extends StatelessWidget {
  const _BalanceTile({
    required this.balance,
    required this.name,
    required this.isDark,
    this.onTap,
  });

  final SettlementBalance balance;
  final String name;
  final bool isDark;
  final VoidCallback? onTap;

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
      child: InkWell(
        borderRadius: CoSpendRadii.cardRadius,
        onTap: onTap,
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
                      isOwed ? 'Is owed money · Tap details' : 'Owes money · Tap details',
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
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textSubtle,
              ),
            ],
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
    required this.isDark,
    required this.recording,
    required this.onRecord,
  });

  final SettlementTransfer transfer;
  final String fromName;
  final String toName;
  final bool isDark;
  final bool recording;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: CoSpendRadii.cardRadius,
        onTap: recording ? null : onRecord,
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
                    Text(
                      '$fromName pays $toName',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to review & record',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
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
                  TextButton(
                    onPressed: recording ? null : onRecord,
                    child: const Text('Record'),
                  ),
                ],
              ),
            ],
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