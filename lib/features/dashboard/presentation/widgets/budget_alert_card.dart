import 'package:flutter/material.dart';

import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/money.dart';
import 'budget_category_item.dart';

class BudgetAlertCard extends StatelessWidget {
  const BudgetAlertCard({
    super.key,
    required this.exceededCategory,
    required this.spentPaisa,
    required this.budgetPaisa,
    required this.onResolve,
  });

  final BudgetCategoryItem exceededCategory;
  final int spentPaisa;
  final int budgetPaisa;
  final VoidCallback onResolve;

  @override
  Widget build(BuildContext context) {
    final overBy = spentPaisa - budgetPaisa;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A1F3D), Color(0xFF0E2D5A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: CoSpendRadii.cardLargeRadius,
        boxShadow: [
          BoxShadow(
            color: CoSpendColors.prussianBlue.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: CoSpendColors.alertRed.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: CoSpendColors.alertRed,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Budget Alert',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.5,
              ),
              children: [
                const TextSpan(text: 'Your '),
                TextSpan(
                  text: exceededCategory.label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text:
                      ' budget has exceeded its limit by ${Money.format(overBy)} this cycle.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onResolve,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              decoration: BoxDecoration(
                color: CoSpendColors.jadeGreen,
                borderRadius: CoSpendRadii.pillRadius,
                boxShadow: [
                  BoxShadow(
                    color: CoSpendColors.jadeGreen.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Resolve Now',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_outward_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
