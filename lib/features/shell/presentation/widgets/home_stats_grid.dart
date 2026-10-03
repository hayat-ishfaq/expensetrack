import 'package:flutter/material.dart';

import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/money.dart';

/// 2x2 grid of stat cards for the home dashboard.
class HomeStatsGrid extends StatelessWidget {
  const HomeStatsGrid({
    super.key,
    required this.totalBudgetPaisa,
    required this.totalSpendingPaisa,
    required this.userSharePaisa,
    required this.userPaidPaisa,
    required this.isDark,
  });

  final int totalBudgetPaisa;
  final int totalSpendingPaisa;
  final int userSharePaisa;
  final int userPaidPaisa;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final budgetUsedPct = totalBudgetPaisa > 0
        ? ((totalSpendingPaisa / totalBudgetPaisa) * 100).round()
        : 0;
    final remainingPaisa = (userSharePaisa - userPaidPaisa).abs();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.account_balance_wallet_outlined,
                iconColor: CoSpendColors.jadeGreen,
                label: 'TOTAL BUDGET',
                value: Money.format(totalBudgetPaisa),
                subtitle: 'Household limit',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.trending_up_rounded,
                iconColor: const Color(0xFF60A5FA),
                label: 'TOTAL SPENDINGS',
                value: Money.format(totalSpendingPaisa),
                subtitle: totalBudgetPaisa > 0
                    ? '$budgetUsedPct% of flat budget used'
                    : 'This month',
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.person_outline_rounded,
                iconColor: const Color(0xFFA78BFA),
                label: 'YOUR SHARE',
                value: Money.format(userSharePaisa),
                subtitle: 'Your allocated quota',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.home_outlined,
                iconColor: const Color(0xFFFB923C),
                label: 'SPENT BY YOU',
                value: Money.format(userPaidPaisa),
                subtitle: userPaidPaisa <= userSharePaisa
                    ? '${Money.format(remainingPaisa)} remaining'
                    : '${Money.format(remainingPaisa)} over',
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.isDark,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? CoSpendColors.darkCard : CoSpendColors.white,
        borderRadius: CoSpendRadii.cardRadius,
        border: Border.all(
          color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
          width: 0.8,
        ),
        boxShadow: isDark ? null : CoSpendShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: isDark ? Colors.white : CoSpendColors.prussianBlue,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
