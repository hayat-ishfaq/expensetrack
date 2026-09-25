import 'package:flutter/material.dart';

import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/money.dart';

/// Premium 2x2 financial summary cards — Revolut/Monarch inspired metric tiles.
/// Showcasing: Total Flat Budget, Total Spendings, Your Allocated Share, Spent By You.
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
    final isFlatOver = totalBudgetPaisa > 0 && totalSpendingPaisa > totalBudgetPaisa;
    final flatPct = totalBudgetPaisa > 0
        ? (totalSpendingPaisa / totalBudgetPaisa * 100).round()
        : 0;

    final isUserOver = userAllocatedSharePaisa > 0 && userSpentPaisa > userAllocatedSharePaisa;
    final userRemainingPaisa = userAllocatedSharePaisa - userSpentPaisa;

    return Column(
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
                iconColor: CoSpendColors.jadeGreen,
                subtext: totalBudgetPaisa > 0
                    ? 'Household limit'
                    : 'Set monthly target',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'TOTAL SPENDINGS',
                amount: Money.format(totalSpendingPaisa),
                icon: Icons.account_balance_wallet_rounded,
                iconColor: isFlatOver ? CoSpendColors.alertRed : CoSpendColors.prussianBlue,
                subtext: totalBudgetPaisa > 0
                    ? '$flatPct% of flat budget'
                    : 'Across all flatmates',
                isWarning: isFlatOver,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

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
                iconColor: CoSpendColors.prussianBlue,
                subtext: 'Your allocated quota',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'SPENT BY YOU',
                amount: Money.format(userSpentPaisa),
                icon: Icons.person_rounded,
                iconColor: isUserOver ? CoSpendColors.alertRed : CoSpendColors.jadeGreen,
                subtext: userAllocatedSharePaisa > 0
                    ? (isUserOver
                        ? 'Over by ${Money.format(-userRemainingPaisa)}'
                        : '${Money.format(userRemainingPaisa)} left')
                    : 'Your total spending',
                isWarning: isUserOver,
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
    this.subtext,
    this.isWarning = false,
  });

  final String label;
  final String amount;
  final IconData icon;
  final Color iconColor;
  final String? subtext;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isWarning
        ? (isDark ? const Color(0xFF1F0C0C) : CoSpendColors.alertRedLight)
        : (isDark ? CoSpendColors.darkCard : CoSpendColors.white);

    final borderColor = isWarning
        ? CoSpendColors.alertRed.withValues(alpha: 0.3)
        : (isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: CoSpendRadii.cardRadius,
        border: Border.all(color: borderColor, width: 0.8),
        boxShadow: !isDark ? CoSpendShadows.card : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: tinted icon + optional warning badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 17, color: iconColor),
              ),
              if (isWarning)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: CoSpendColors.alertRed.withValues(alpha: 0.12),
                    borderRadius: CoSpendRadii.pillRadius,
                  ),
                  child: const Text(
                    'OVER',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: CoSpendColors.alertRed,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Label
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: isWarning
                  ? CoSpendColors.alertRed
                  : (isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted),
            ),
          ),
          const SizedBox(height: 4),

          // Amount — visual hero
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              letterSpacing: -0.5,
              color: isWarning
                  ? CoSpendColors.alertRed
                  : (isDark ? CoSpendColors.darkTextPrimary : CoSpendColors.prussianBlue),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Subtext
          if (subtext != null) ...[
            const SizedBox(height: 3),
            Text(
              subtext!,
              style: TextStyle(
                color: isWarning
                    ? CoSpendColors.alertRed.withValues(alpha: 0.75)
                    : (isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted),
                fontSize: 11,
                fontWeight: isWarning ? FontWeight.w600 : FontWeight.w400,
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
