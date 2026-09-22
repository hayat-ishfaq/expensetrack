import 'package:flutter/material.dart';

import '../../../../core/utils/money.dart';
import '../../domain/dashboard_stats.dart';

class FinancialSummaryCards extends StatelessWidget {
  const FinancialSummaryCards({
    super.key,
    required this.stats,
  });

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Balance visual style
    final balancePaisa = stats.userBalancePaisa;
    final isCredit = balancePaisa > 0;
    final isDebt = balancePaisa < 0;

    final balanceBgColor = isCredit
        ? const Color(0xFF10B981).withValues(alpha: 0.12)
        : isDebt
            ? const Color(0xFFEF4444).withValues(alpha: 0.12)
            : scheme.surfaceContainerHighest;

    final balanceTextColor = isCredit
        ? const Color(0xFF059669)
        : isDebt
            ? const Color(0xFFDC2626)
            : scheme.onSurfaceVariant;

    final balanceLabel = isCredit
        ? 'You should receive'
        : isDebt
            ? 'You owe'
            : 'Settled up';

    return Column(
      children: [
        // Top 2 Cards: Total Spending & Your Balance (Hero metrics)
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'TOTAL SPENDING',
                amount: Money.format(stats.totalSpendingPaisa),
                icon: Icons.account_balance_wallet_rounded,
                iconColor: scheme.primary,
                bgColor: scheme.surfaceContainerLow,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: balanceBgColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: balanceTextColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'YOUR BALANCE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: balanceTextColor,
                          ),
                        ),
                        Icon(
                          isCredit
                              ? Icons.arrow_downward_rounded
                              : isDebt
                                  ? Icons.arrow_upward_rounded
                                  : Icons.check_circle_rounded,
                          size: 16,
                          color: balanceTextColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      Money.formatSigned(balancePaisa),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: balanceTextColor,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      balanceLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: balanceTextColor.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Bottom 2 Cards: Your Share & You Paid
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'YOUR SHARE',
                amount: Money.format(stats.userSharePaisa),
                icon: Icons.pie_chart_outline_rounded,
                iconColor: const Color(0xFFF59E0B),
                bgColor: scheme.surfaceContainerLow,
                subtext: 'Your contribution',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'YOU PAID',
                amount: Money.format(stats.userPaidPaisa),
                icon: Icons.payments_outlined,
                iconColor: const Color(0xFF3B82F6),
                bgColor: scheme.surfaceContainerLow,
                subtext: 'Paid from your pocket',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    this.subtext,
  });

  final String label;
  final String amount;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String? subtext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Icon(icon, size: 16, color: iconColor),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            amount,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtext != null) ...[
            const SizedBox(height: 4),
            Text(
              subtext!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
