import 'package:flutter/material.dart';

import '../../../../core/utils/money.dart';

/// Clean 2x2 financial summary cards showcasing:
/// 1. Total Allocated Flat Budget
/// 2. Total Flat Spending
/// 3. User's Allocated Budget Share
/// 4. Total Spending by User
class FinancialSummaryCards extends StatelessWidget {
  const FinancialSummaryCards({
    super.key,
    required this.totalBudgetPaisa,
    required this.totalSpendingPaisa,
    required this.userAllocatedSharePaisa,
    required this.userSpentPaisa,
  });

  final int totalBudgetPaisa;
  final int totalSpendingPaisa;
  final int userAllocatedSharePaisa;
  final int userSpentPaisa;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final isFlatOver = totalBudgetPaisa > 0 && totalSpendingPaisa > totalBudgetPaisa;
    final flatPct = totalBudgetPaisa > 0
        ? (totalSpendingPaisa / totalBudgetPaisa * 100).round()
        : 0;

    final isUserOver = userAllocatedSharePaisa > 0 && userSpentPaisa > userAllocatedSharePaisa;
    final userRemainingPaisa = userAllocatedSharePaisa - userSpentPaisa;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        return Transform.translate(
          offset: Offset(0, 16 * (1.0 - val)),
          child: Opacity(
            opacity: val,
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          // Row 1: Flat Budget & Flat Spending
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'TOTAL BUDGET',
                  amount: totalBudgetPaisa > 0
                      ? Money.format(totalBudgetPaisa)
                      : 'Not set',
                  icon: Icons.savings_rounded,
                  iconColor: scheme.primary,
                  bgColor: scheme.surfaceContainerLow,
                  subtext: totalBudgetPaisa > 0
                      ? 'Household limit'
                      : 'Set monthly target',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: 'TOTAL SPENDINGS',
                  amount: Money.format(totalSpendingPaisa),
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: isFlatOver
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF3B82F6),
                  bgColor: isFlatOver
                      ? const Color(0xFFEF4444).withValues(alpha: 0.08)
                      : scheme.surfaceContainerLow,
                  subtext: totalBudgetPaisa > 0
                      ? '$flatPct% of flat budget used'
                      : 'Across all flatmates',
                  isWarning: isFlatOver,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Your Allocated Share & Total Spent by You
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'YOUR SHARE',
                  amount: userAllocatedSharePaisa > 0
                      ? Money.format(userAllocatedSharePaisa)
                      : 'Unset',
                  icon: Icons.pie_chart_outline_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  bgColor: scheme.surfaceContainerLow,
                  subtext: 'Your allocated quota',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: 'SPENT BY YOU',
                  amount: Money.format(userSpentPaisa),
                  icon: Icons.person_rounded,
                  iconColor: isUserOver
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981),
                  bgColor: isUserOver
                      ? const Color(0xFFEF4444).withValues(alpha: 0.08)
                      : scheme.surfaceContainerLow,
                  subtext: userAllocatedSharePaisa > 0
                      ? (isUserOver
                          ? 'Over by ${Money.format(-userRemainingPaisa)}'
                          : '${Money.format(userRemainingPaisa)} remaining')
                      : 'Your total spending',
                  isWarning: isUserOver,
                ),
              ),
            ],
          ),
        ],
      ),
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
    this.isWarning = false,
  });

  final String label;
  final String amount;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String? subtext;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isWarning
              ? const Color(0xFFEF4444).withValues(alpha: 0.35)
              : scheme.outlineVariant.withValues(alpha: 0.4),
          width: isWarning ? 1.5 : 1.0,
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
                  color: isWarning
                      ? const Color(0xFFEF4444)
                      : scheme.onSurfaceVariant,
                  fontSize: 10.5,
                ),
              ),
              Icon(icon, size: 16, color: iconColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              letterSpacing: -0.4,
              color: isWarning ? const Color(0xFFEF4444) : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtext != null) ...[
            const SizedBox(height: 3),
            Text(
              subtext!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isWarning
                    ? const Color(0xFFEF4444)
                    : scheme.onSurfaceVariant,
                fontSize: 11,
                fontWeight: isWarning ? FontWeight.w600 : FontWeight.normal,
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
