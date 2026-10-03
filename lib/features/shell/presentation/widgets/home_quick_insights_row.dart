import 'package:flutter/material.dart';

import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/money.dart';

/// Quick insights row showing settlement and balance state at a glance.
class HomeQuickInsightsRow extends StatelessWidget {
  const HomeQuickInsightsRow({
    super.key,
    required this.myBalance,
    required this.memberNameMap,
    required this.settlement,
    required this.currentUserId,
    required this.isDark,
  });

  final int myBalance;
  final Map<String, String> memberNameMap;
  final dynamic settlement;
  final String currentUserId;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    String owesTo = '';
    int owesAmount = 0;
    String owedBy = '';
    int owedAmount = 0;

    if (settlement != null) {
      for (final transfer in settlement!.transfers) {
        if (transfer.fromMemberId == currentUserId) {
          owesTo = memberNameMap[transfer.toMemberId] ?? 'Flatmate';
          owesAmount = transfer.amountPaisa;
          break;
        }
      }
      for (final transfer in settlement!.transfers) {
        if (transfer.toMemberId == currentUserId) {
          owedBy = memberNameMap[transfer.fromMemberId] ?? 'Flatmate';
          owedAmount = transfer.amountPaisa;
          break;
        }
      }
    }

    final cardBg = isDark ? CoSpendColors.darkCard : CoSpendColors.white;
    final borderColor = isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: CoSpendRadii.cardRadius,
        border: Border.all(color: borderColor, width: 0.8),
        boxShadow: isDark ? null : CoSpendShadows.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.trending_down_rounded,
                        size: 15,
                        color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'SETTLEMENTS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    owedAmount > 0
                        ? '${owedBy.split(' ').first} owes you'
                        : 'All settled up',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    owedAmount > 0 ? Money.format(owedAmount) : Money.format(0),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: owedAmount > 0
                          ? CoSpendColors.jadeGreen
                          : (isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 1,
            height: 80,
            color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.trending_up_rounded,
                        size: 15,
                        color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'BALANCE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    owesAmount > 0
                        ? 'You owe ${owesTo.split(' ').first}'
                        : 'No pending dues',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    owesAmount > 0 ? Money.format(owesAmount) : Money.format(0),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: owesAmount > 0
                          ? CoSpendColors.alertRed
                          : (isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted),
                    ),
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
