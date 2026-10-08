import 'package:flutter/material.dart';

import '../../../../core/theme/design_system.dart';

/// Inline alert banner displayed for each budget category the user has exceeded.
class HomeBudgetAlertBanner extends StatelessWidget {
  const HomeBudgetAlertBanner({
    super.key,
    required this.label,
    required this.mySpentPaisa,
    required this.myBudgetPaisa,
    required this.isDark,
    this.onTap,
  });

  final String label;
  final int mySpentPaisa;
  final int myBudgetPaisa;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pct = myBudgetPaisa > 0
        ? ((mySpentPaisa / myBudgetPaisa) * 100).round()
        : 85;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2B1015) : const Color(0xFFFFF5F5),
          borderRadius: CoSpendRadii.cardRadius,
          border: Border.all(
            color: CoSpendColors.alertRed.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: CoSpendColors.alertRed.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.error_outline_rounded,
                color: CoSpendColors.alertRed,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budget Alert: $label Spending',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: CoSpendColors.alertRed,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your group has spent $pct% of the $label budget. '
                    'Tap to view and adjust budget limits.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: CoSpendColors.alertRed,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: CoSpendColors.alertRed,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
