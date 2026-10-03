import 'package:flutter/material.dart';

import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/money.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';

/// Deep Prussian Blue gradient hero card showing total monthly spending
/// and budget progress bar.
class HomeHeroSpendCard extends StatelessWidget {
  const HomeHeroSpendCard({
    super.key,
    required this.totalSpendingPaisa,
    required this.budgetPaisa,
    required this.sharedSpendingPaisa,
    required this.individualSpendingPaisa,
    this.budgetStatus,
  });

  final int totalSpendingPaisa;
  final int budgetPaisa;
  final int sharedSpendingPaisa;
  final int individualSpendingPaisa;
  final BudgetStatus? budgetStatus;

  @override
  Widget build(BuildContext context) {
    final pct = budgetStatus?.percentage ?? 0.0;
    final clampedPct = pct.clamp(0.0, 100.0);
    final isExceeded = budgetStatus?.isExceeded ?? false;
    final isApproaching = budgetStatus?.isApproaching ?? false;
    final progressColor = isExceeded
        ? CoSpendColors.alertRed
        : isApproaching
            ? CoSpendColors.warningAmber
            : CoSpendColors.jadeGreen;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: CoSpendRadii.cardLargeRadius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A1F3D),
            Color(0xFF0E2D5A),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: CoSpendColors.prussianBlue.withValues(alpha: 0.45),
            blurRadius: 28,
            offset: const Offset(0, 12),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Monthly Spend',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.75),
                  letterSpacing: 0.1,
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 0.8,
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: CoSpendColors.jadeGreen,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            Money.format(totalSpendingPaisa),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.8,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          if (budgetPaisa > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Budget Limit',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
                Text(
                  Money.format(budgetPaisa),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: CoSpendRadii.pillRadius,
              child: Stack(
                children: [
                  Container(height: 7, color: Colors.white.withValues(alpha: 0.15)),
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    tween: Tween<double>(begin: 0, end: clampedPct / 100.0),
                    builder: (context, value, child) => FractionallySizedBox(
                      widthFactor: value,
                      child: Container(
                        height: 7,
                        decoration: BoxDecoration(
                          color: progressColor,
                          borderRadius: CoSpendRadii.pillRadius,
                          boxShadow: [
                            BoxShadow(
                              color: progressColor.withValues(alpha: 0.5),
                              blurRadius: 6,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${clampedPct.toStringAsFixed(0)}% of limit used',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.12)),
            const SizedBox(height: 16),
          ] else ...[
            const SizedBox(height: 16),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.12)),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: _SpendSplitTile(
                  label: 'SHARED',
                  amountPaisa: sharedSpendingPaisa,
                  icon: Icons.trending_up_rounded,
                  iconColor: CoSpendColors.jadeGreen,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.15)),
              Expanded(
                child: _SpendSplitTile(
                  label: 'INDIVIDUAL',
                  amountPaisa: individualSpendingPaisa,
                  icon: Icons.trending_down_rounded,
                  iconColor: const Color(0xFF93C5FD),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpendSplitTile extends StatelessWidget {
  const _SpendSplitTile({
    required this.label,
    required this.amountPaisa,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final int amountPaisa;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                Money.format(amountPaisa),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
