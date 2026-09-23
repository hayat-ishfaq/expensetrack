import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/firebase_error_mapper.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/models/household_member.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../expenses/domain/expense.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';
import '../../../household/presentation/providers/household_providers.dart';
import '../../../settlement/domain/settlement.dart';
import '../../../settlement/presentation/providers/settlement_providers.dart';

/// Settlement screen: Calm, trustworthy financial reconciliation UI with
/// personal debt/credit metrics, directional transfer visualization, and
/// a Pending -> Confirm -> Settled interactive confirmation lifecycle.
class SettleUpScreen extends ConsumerStatefulWidget {
  const SettleUpScreen({super.key});

  @override
  ConsumerState<SettleUpScreen> createState() => _SettleUpScreenState();
}

class _SettleUpScreenState extends ConsumerState<SettleUpScreen> {
  /// Track which transfers have been settled in the current session.
  /// Key format: '${fromMemberId}_${toMemberId}_${amountPaisa}'
  final Set<String> _settledTransferKeys = {};

  String _transferKey(SettlementTransfer transfer) =>
      '${transfer.fromMemberId}_${transfer.toMemberId}_${transfer.amountPaisa}';

  void _markAsSettled(SettlementTransfer transfer) {
    setState(() {
      _settledTransferKeys.add(_transferKey(transfer));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final settlementAsync = ref.watch(settlementProvider);
    final expensesAsync = ref.watch(householdExpensesProvider);
    final membersAsync = ref.watch(householdMembersProvider);
    final session = ref.watch(sessionProvider).value;
    final household = ref.watch(currentHouseholdProvider).value;
    final currentUserId = session?.user?.id ?? '';
    final isOwner = household != null &&
        (household.ownerId.isEmpty || household.ownerId == currentUserId);

    return Scaffold(
      backgroundColor: isDark ? CoSpendColors.darkCanvas : CoSpendColors.canvas,
      appBar: AppBar(
        title: const Text('Reconciliation & Settle Up'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
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
            return const EmptyState(
              icon: Icons.check_circle_outline,
              title: 'All settled up',
              message: 'Everyone is even — no transfers are needed right now.',
            );
          }
          return _SettlementView(
            settlement: settlement,
            members: membersAsync.value ?? const <HouseholdMember>[],
            currentUserId: currentUserId,
            isOwner: isOwner,
            isDark: isDark,
            settledTransferKeys: _settledTransferKeys,
            onConfirmSettle: _markAsSettled,
          );
        },
      ),
    );
  }
}

class _SettlementView extends StatelessWidget {
  const _SettlementView({
    required this.settlement,
    required this.members,
    required this.currentUserId,
    required this.isOwner,
    required this.isDark,
    required this.settledTransferKeys,
    required this.onConfirmSettle,
  });

  final Settlement settlement;
  final List<HouseholdMember> members;
  final String currentUserId;
  final bool isOwner;
  final bool isDark;
  final Set<String> settledTransferKeys;
  final ValueChanged<SettlementTransfer> onConfirmSettle;

  String _nameFor(String id) {
    for (final member in members) {
      if (member.id == id && member.name.trim().isNotEmpty) return member.name;
    }
    return id == currentUserId ? 'You' : id;
  }

  HouseholdMember? _memberFor(String id) {
    for (final member in members) {
      if (member.id == id) return member;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Current user's net position calculation
    int totalYouOwePaisa = 0;
    int totalYouAreOwedPaisa = 0;

    for (final balance in settlement.balances) {
      if (balance.memberId == currentUserId) {
        if (balance.owes) {
          totalYouOwePaisa = balance.netPaisa.abs();
        } else if (balance.isOwed) {
          totalYouAreOwedPaisa = balance.netPaisa;
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // 1. Personal Reconciliation Hero (Dual Metrics)
        _PersonalReconciliationHero(
          totalYouOwePaisa: totalYouOwePaisa,
          totalYouAreOwedPaisa: totalYouAreOwedPaisa,
          isDark: isDark,
        ),
        const SizedBox(height: 14),

        // 2. Household Summary Card ('Total to settle' preserved for tests & transparency)
        _HouseholdSummaryCard(
          totalOwedPaisa: settlement.totalOwedPaisa,
          transfersCount: settlement.transfers.length,
          settledCount: settledTransferKeys.length,
          isDark: isDark,
        ),
        const SizedBox(height: 24),

        // 3. Suggested Transfers Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'SUGGESTED TRANSFERS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: isDark
                      ? CoSpendColors.darkTextMuted
                      : CoSpendColors.textMuted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${settlement.transfers.length} Optimized',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? CoSpendColors.darkTextSubtle
                    : CoSpendColors.textSubtle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 4. Directional Transfer Cards (Ahmed -> You, etc.)
        for (final transfer in settlement.transfers) ...[
          _DirectionalTransferCard(
            key: ValueKey(
              'transfer_${transfer.fromMemberId}_${transfer.toMemberId}_${transfer.amountPaisa}',
            ),
            transfer: transfer,
            fromMember: _memberFor(transfer.fromMemberId),
            toMember: _memberFor(transfer.toMemberId),
            fromName: _nameFor(transfer.fromMemberId),
            toName: _nameFor(transfer.toMemberId),
            currentUserId: currentUserId,
            isOwner: isOwner,
            isSettled: settledTransferKeys.contains(
              '${transfer.fromMemberId}_${transfer.toMemberId}_${transfer.amountPaisa}',
            ),
            isDark: isDark,
            onConfirmSettle: () => onConfirmSettle(transfer),
          ),
          const SizedBox(height: 12),
        ],

        const SizedBox(height: 12),

        // 5. Member Balances Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'FLATMATE BALANCES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: isDark
                      ? CoSpendColors.darkTextMuted
                      : CoSpendColors.textMuted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${settlement.balances.length} Members',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? CoSpendColors.darkTextSubtle
                    : CoSpendColors.textSubtle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 6. Flatmate Balance Tiles
        for (final balance in settlement.balances)
          _FlatmateBalanceTile(
            balance: balance,
            name: _nameFor(balance.memberId),
            member: _memberFor(balance.memberId),
            isMe: balance.memberId == currentUserId,
            isDark: isDark,
          ),

        const SizedBox(height: 16),
        Center(
          child: Text(
            'Suggestions only — settle however works best for your flat.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? CoSpendColors.darkTextSubtle
                  : CoSpendColors.textSubtle,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// PERSONAL RECONCILIATION HERO CARD (DUAL METRICS)
// =============================================================================

class _PersonalReconciliationHero extends StatelessWidget {
  const _PersonalReconciliationHero({
    required this.totalYouOwePaisa,
    required this.totalYouAreOwedPaisa,
    required this.isDark,
  });

  final int totalYouOwePaisa;
  final int totalYouAreOwedPaisa;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final netDifference = totalYouAreOwedPaisa - totalYouOwePaisa;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? CoSpendColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? CoSpendColors.darkBorder : const Color(0x1F0A2542),
          width: 1,
        ),
        boxShadow: CoSpendShadows.softCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'YOUR RECONCILIATION SUMMARY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: isDark
                        ? CoSpendColors.darkTextMuted
                        : CoSpendColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: netDifference > 0
                      ? CoSpendColors.jadeGreen.withValues(alpha: 0.12)
                      : (netDifference < 0
                          ? CoSpendColors.alertRed.withValues(alpha: 0.12)
                          : const Color(0x140A2542)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  netDifference > 0
                      ? 'Net: In Credit'
                      : (netDifference < 0 ? 'Net: In Debt' : 'Net: Balanced'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: netDifference > 0
                        ? CoSpendColors.jadeGreen
                        : (netDifference < 0
                            ? CoSpendColors.alertRed
                            : (isDark
                                ? CoSpendColors.darkTextMuted
                                : CoSpendColors.textMuted)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dual Cards: Total you owe vs Total you're owed
          Row(
            children: [
              // Total you owe
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: totalYouOwePaisa > 0
                        ? CoSpendColors.alertRed.withValues(alpha: 0.08)
                        : (isDark
                            ? CoSpendColors.darkCardElevated
                            : const Color(0xFFF7F8FA)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: totalYouOwePaisa > 0
                          ? CoSpendColors.alertRed.withValues(alpha: 0.25)
                          : (isDark
                              ? CoSpendColors.darkBorder
                              : const Color(0x140A2542)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.arrow_upward_rounded,
                            size: 14,
                            color: totalYouOwePaisa > 0
                                ? CoSpendColors.alertRed
                                : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Total you owe',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? CoSpendColors.darkTextMuted
                                    : CoSpendColors.textMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          Money.format(totalYouOwePaisa),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: totalYouOwePaisa > 0
                                ? CoSpendColors.alertRed
                                : (isDark
                                    ? CoSpendColors.darkTextPrimary
                                    : CoSpendColors.prussianBlue),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Total you're owed
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: totalYouAreOwedPaisa > 0
                        ? CoSpendColors.jadeGreen.withValues(alpha: 0.08)
                        : (isDark
                            ? CoSpendColors.darkCardElevated
                            : const Color(0xFFF7F8FA)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: totalYouAreOwedPaisa > 0
                          ? CoSpendColors.jadeGreen.withValues(alpha: 0.25)
                          : (isDark
                              ? CoSpendColors.darkBorder
                              : const Color(0x140A2542)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.arrow_downward_rounded,
                            size: 14,
                            color: totalYouAreOwedPaisa > 0
                                ? CoSpendColors.jadeGreen
                                : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              "Total you're owed",
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? CoSpendColors.darkTextMuted
                                    : CoSpendColors.textMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          Money.format(totalYouAreOwedPaisa),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: totalYouAreOwedPaisa > 0
                                ? CoSpendColors.jadeGreen
                                : (isDark
                                    ? CoSpendColors.darkTextPrimary
                                    : CoSpendColors.prussianBlue),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// HOUSEHOLD SUMMARY CARD ('Total to settle')
// =============================================================================

class _HouseholdSummaryCard extends StatelessWidget {
  const _HouseholdSummaryCard({
    required this.totalOwedPaisa,
    required this.transfersCount,
    required this.settledCount,
    required this.isDark,
  });

  final int totalOwedPaisa;
  final int transfersCount;
  final int settledCount;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [
                  Color(0xFF0F3156),
                  Color(0xFF0A223C),
                ]
              : const [
                  CoSpendColors.prussianBlue,
                  Color(0xFF133863),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: CoSpendShadows.softCard,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.swap_horiz_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total to settle',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    Money.format(totalOwedPaisa),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: Colors.white,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$settledCount / $transfersCount settled',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// DIRECTIONAL TRANSFER CARD: Ahmed ↓ You (Clean Visual Flow)
// =============================================================================

class _DirectionalTransferCard extends StatelessWidget {
  const _DirectionalTransferCard({
    super.key,
    required this.transfer,
    required this.fromMember,
    required this.toMember,
    required this.fromName,
    required this.toName,
    required this.currentUserId,
    required this.isOwner,
    required this.isSettled,
    required this.isDark,
    required this.onConfirmSettle,
  });

  final SettlementTransfer transfer;
  final HouseholdMember? fromMember;
  final HouseholdMember? toMember;
  final String fromName;
  final String toName;
  final String currentUserId;
  final bool isOwner;
  final bool isSettled;
  final bool isDark;
  final VoidCallback onConfirmSettle;

  bool get _isUserInvolved =>
      transfer.fromMemberId == currentUserId ||
      transfer.toMemberId == currentUserId;

  bool get _canUserConfirm => _isUserInvolved || isOwner;

  void _showConfirmationDialog(BuildContext context) {
    if (!_canUserConfirm) {
      showAppSnack(
        context,
        'Only involved flatmates or the flat owner can confirm this transfer.',
        error: true,
      );
      return;
    }

    showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Confirm Settlement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Has ${fromName == "You" ? "your payment of" : "$fromName paid"} ${Money.format(transfer.amountPaisa)} to ${toName == "You" ? "you" : toName} been completed?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: CoSpendColors.jadeGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: CoSpendColors.jadeGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reconciling ${Money.format(transfer.amountPaisa)} will mark this transfer as settled.',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: CoSpendColors.jadeGreenDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CoSpendColors.jadeGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop(true);
            },
            child: const Text('Confirm & Settle'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        onConfirmSettle();
        if (context.mounted) {
          showAppSnack(
            context,
            'Transfer of ${Money.format(transfer.amountPaisa)} confirmed as settled.',
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final fromInitial = fromName.trim().isEmpty
        ? '?'
        : fromName.trim().characters.first.toUpperCase();
    final toInitial = toName.trim().isEmpty
        ? '?'
        : toName.trim().characters.first.toUpperCase();

    final isMePaying = transfer.fromMemberId == currentUserId;
    final isMeReceiving = transfer.toMemberId == currentUserId;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSettled
            ? (isDark
                ? CoSpendColors.darkCardElevated.withValues(alpha: 0.4)
                : const Color(0xFFF9FBFA))
            : (isDark ? CoSpendColors.darkCard : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSettled
              ? CoSpendColors.jadeGreen.withValues(alpha: 0.3)
              : (_isUserInvolved
                  ? CoSpendColors.prussianBlue.withValues(alpha: 0.25)
                  : (isDark
                      ? CoSpendColors.darkBorder
                      : const Color(0x140A2542))),
          width: _isUserInvolved ? 1.5 : 1.0,
        ),
        boxShadow: CoSpendShadows.softCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Semantic accessibility description for tests & screen readers:
          // e.g. "Sara pays Ali"
          Semantics(
            label: '$fromName pays $toName',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '$fromName pays $toName',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? CoSpendColors.darkTextMuted
                          : CoSpendColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // Status state badge (Pending -> Confirm -> Settled)
                _SettlementStatusBadge(
                  isSettled: isSettled,
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Directional Flow:
          // Ahmed (Payer)
          //   ↓
          // You (Payee)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Directional Column (Avatars connected by arrow)
              Column(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: isMePaying
                        ? CoSpendColors.alertRed.withValues(alpha: 0.15)
                        : (isDark
                            ? CoSpendColors.prussianBlueLight
                            : CoSpendColors.prussianBlue
                                .withValues(alpha: 0.1)),
                    child: Text(
                      fromInitial,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isMePaying
                            ? CoSpendColors.alertRed
                            : (isDark
                                ? Colors.white
                                : CoSpendColors.prussianBlue),
                      ),
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 18,
                    color: isDark
                        ? CoSpendColors.darkBorder
                        : const Color(0x1F0A2542),
                  ),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark
                          ? CoSpendColors.darkCardElevated
                          : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_downward_rounded,
                      size: 14,
                      color: isDark
                          ? CoSpendColors.darkTextPrimary
                          : CoSpendColors.prussianBlue,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 18,
                    color: isDark
                        ? CoSpendColors.darkBorder
                        : const Color(0x1F0A2542),
                  ),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: isMeReceiving
                        ? CoSpendColors.jadeGreen.withValues(alpha: 0.15)
                        : (isDark
                            ? CoSpendColors.prussianBlueLight
                            : CoSpendColors.prussianBlue
                                .withValues(alpha: 0.1)),
                    child: Text(
                      toInitial,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isMeReceiving
                            ? CoSpendColors.jadeGreen
                            : (isDark
                                ? Colors.white
                                : CoSpendColors.prussianBlue),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Names and amount column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Payer Name
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            fromName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? CoSpendColors.darkTextPrimary
                                  : CoSpendColors.prussianBlue,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isMePaying) ...[
                          const SizedBox(width: 6),
                          _TagBadge(
                            label: 'YOU',
                            color: CoSpendColors.alertRed,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Amount typography
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        Money.format(transfer.amountPaisa),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: isDark
                              ? CoSpendColors.darkTextPrimary
                              : CoSpendColors.prussianBlue,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Payee Name
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            toName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? CoSpendColors.darkTextPrimary
                                  : CoSpendColors.prussianBlue,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isMeReceiving) ...[
                          const SizedBox(width: 6),
                          _TagBadge(
                            label: 'YOU',
                            color: CoSpendColors.jadeGreen,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Interactive Confirmation CTA or Settled State with subtle animation
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: CoSpendAnimations.fast,
                    child: isSettled
                        ? Container(
                            key: const ValueKey('settled_badge'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: CoSpendColors.jadeGreen
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: CoSpendColors.jadeGreen
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 14,
                                  color: CoSpendColors.jadeGreen,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Settled',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: CoSpendColors.jadeGreen,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Semantics(
                            button: true,
                            label: 'Confirm settlement of ${Money.format(transfer.amountPaisa)} from $fromName to $toName',
                            enabled: _canUserConfirm,
                            child: OutlinedButton.icon(
                              key: const ValueKey('confirm_btn'),
                              onPressed: _canUserConfirm
                                  ? () => _showConfirmationDialog(context)
                                  : null,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: CoSpendColors.jadeGreen,
                                side: BorderSide(
                                  color: _canUserConfirm
                                      ? CoSpendColors.jadeGreen
                                      : const Color(0x1F0A2542),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(
                                Icons.done_all_rounded,
                                size: 14,
                              ),
                              label: const Text(
                                'Confirm',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettlementStatusBadge extends StatelessWidget {
  const _SettlementStatusBadge({
    required this.isSettled,
    required this.isDark,
  });

  final bool isSettled;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (isSettled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: CoSpendColors.jadeGreen.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, size: 11, color: CoSpendColors.jadeGreen),
            SizedBox(width: 3),
            Text(
              'SETTLED',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: CoSpendColors.jadeGreen,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: CoSpendColors.warningAmber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded,
              size: 11, color: CoSpendColors.warningAmber),
          SizedBox(width: 3),
          Text(
            'PENDING',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: CoSpendColors.warningAmber,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagBadge extends StatelessWidget {
  const _TagBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

// =============================================================================
// FLATMATE BALANCE TILE
// =============================================================================

class _FlatmateBalanceTile extends StatelessWidget {
  const _FlatmateBalanceTile({
    required this.balance,
    required this.name,
    required this.member,
    required this.isMe,
    required this.isDark,
  });

  final SettlementBalance balance;
  final String name;
  final HouseholdMember? member;
  final bool isMe;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name.trim().characters.first.toUpperCase();
    final color = balance.isOwed
        ? CoSpendColors.jadeGreen
        : CoSpendColors.alertRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? CoSpendColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? CoSpendColors.darkBorder : const Color(0x140A2542),
        ),
        boxShadow: CoSpendShadows.softCard,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: isDark
                ? CoSpendColors.prussianBlueLight
                : CoSpendColors.prussianBlue.withValues(alpha: 0.12),
            child: Text(
              initial,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: isDark ? Colors.white : CoSpendColors.prussianBlue,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontWeight: isMe ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 14,
                          color: isDark
                              ? CoSpendColors.darkTextPrimary
                              : CoSpendColors.prussianBlue,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      const _TagBadge(
                        label: 'YOU',
                        color: CoSpendColors.prussianBlue,
                      ),
                    ],
                  ],
                ),
                Text(
                  balance.isOwed ? 'Is owed' : 'Owes',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark
                        ? CoSpendColors.darkTextMuted
                        : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Text(
            Money.formatSigned(balance.netPaisa),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SETTLEMENT SKELETON
// =============================================================================

class _SettlementSkeleton extends StatelessWidget {
  const _SettlementSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        SkeletonBox(height: 120),
        SizedBox(height: 14),
        SkeletonBox(height: 72),
        SizedBox(height: 24),
        SkeletonBox(height: 20, width: 140),
        SizedBox(height: 12),
        SkeletonBox(height: 130),
        SizedBox(height: 12),
        SkeletonBox(height: 130),
        SizedBox(height: 24),
        SkeletonBox(height: 20, width: 140),
        SizedBox(height: 12),
        SkeletonBox(height: 60),
        SizedBox(height: 8),
        SkeletonBox(height: 60),
      ],
    );
  }
}