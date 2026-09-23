import 'package:flutter/material.dart';

import '../../../../core/theme/design_system.dart';
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
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'TOTAL SPENDINGS',
                amount: Money.format(totalSpendingPaisa),
                icon: Icons.account_balance_wallet_rounded,
                iconColor: isFlatOver ? CoSpendColors.alertRed : CoSpendColors.prussianBlue,
                subtext: totalBudgetPaisa > 0
                    ? '$flatPct% of flat budget used'
                    : 'Across all flatmates',
                isWarning: isFlatOver,
              ),
            ),
          ],
        ),
        const SizedBox(width: 12, height: 12),

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
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'SPENT BY YOU',
                amount: Money.format(userSpentPaisa),
                icon: Icons.person_rounded,
                iconColor: isUserOver ? CoSpendColors.alertRed : CoSpendColors.jadeGreen,
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
        ? (isDark ? const Color(0xFF2A1218) : CoSpendColors.alertRedLight)
        : (isDark ? CoSpendColors.darkCard : CoSpendColors.white);

    final borderColor = isWarning
        ? CoSpendColors.alertRed.withValues(alpha: 0.35)
        : (isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: CoSpendRadii.cardRadius,
        border: Border.all(color: borderColor, width: 1),
        boxShadow: !isDark ? CoSpendShadows.cardSubtle : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top-left icon in brand tint circle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 16, color: iconColor),
              ),
              if (isWarning)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: CoSpendColors.alertRed.withValues(alpha: 0.15),
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

          // Label above in small gray caps
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: isWarning
                  ? CoSpendColors.alertRed
                  : (isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted),
            ),
          ),
          const SizedBox(height: 4),

          // Number as visual hero (larger, Prussian Blue / White, semibold/extrabold)
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.4,
              color: isWarning
                  ? CoSpendColors.alertRed
                  : (isDark ? CoSpendColors.darkTextPrimary : CoSpendColors.prussianBlue),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Subtitle below in muted gray
          if (subtext != null) ...[
            const SizedBox(height: 4),
            Text(
              subtext!,
              style: TextStyle(
                color: isWarning
                    ? CoSpendColors.alertRed
                    : (isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted),
                fontSize: 11.5,
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
