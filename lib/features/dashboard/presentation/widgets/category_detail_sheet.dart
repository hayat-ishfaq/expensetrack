import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/models/household_member.dart';
import 'budget_category_item.dart';

class CategoryDetailSheet extends StatelessWidget {
  const CategoryDetailSheet({
    super.key,
    required this.catItem,
    required this.budgetPaisa,
    required this.spentPaisa,
    required this.members,
    required this.memberControllers,
    required this.isDark,
    required this.isOwner,
  });

  final BudgetCategoryItem catItem;
  final int budgetPaisa;
  final int spentPaisa;
  final List<HouseholdMember> members;
  final Map<String, TextEditingController> memberControllers;
  final bool isDark;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final isOver = budgetPaisa > 0 && spentPaisa > budgetPaisa;
    final isApproaching =
        budgetPaisa > 0 && !isOver && spentPaisa >= budgetPaisa * 0.8;
    final pct = budgetPaisa > 0
        ? (spentPaisa / budgetPaisa * 100).clamp(0.0, 100.0)
        : 0.0;
    final remainingPaisa = budgetPaisa - spentPaisa;

    final statusColor = isOver
        ? CoSpendColors.alertRed
        : isApproaching
            ? CoSpendColors.warningAmber
            : CoSpendColors.jadeGreen;

    final statusLabel = budgetPaisa == 0
        ? 'NO LIMIT SET'
        : isOver
            ? 'OVER BUDGET'
            : isApproaching
                ? 'APPROACHING LIMIT'
                : 'ON TRACK';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? CoSpendColors.darkCanvas : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : const Color(0xFFDDE3EA),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: catItem.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Icon(catItem.icon, color: catItem.color, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          catItem.label,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color:
                                isDark ? Colors.white : CoSpendColors.prussianBlue,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          catItem.isCustom
                              ? 'Custom household category'
                              : 'Standard category',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark
                                ? CoSpendColors.darkTextMuted
                                : CoSpendColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white60 : CoSpendColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),

            // Body content
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                shrinkWrap: true,
                children: [
                  // Status badge and summary card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color:
                          isDark ? CoSpendColors.darkCard : const Color(0xFFF7F9FC),
                      borderRadius: CoSpendRadii.cardRadius,
                      border: Border.all(
                        color: isDark
                            ? CoSpendColors.darkBorder
                            : CoSpendColors.borderLight,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Budget Health',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? CoSpendColors.darkTextMuted
                                    : CoSpendColors.textMuted,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: CoSpendRadii.pillRadius,
                                border: Border.all(
                                  color: statusColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Spent This Cycle',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark
                                          ? CoSpendColors.darkTextMuted
                                          : CoSpendColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    Money.format(spentPaisa),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: isOver
                                          ? CoSpendColors.alertRed
                                          : (isDark
                                              ? Colors.white
                                              : CoSpendColors.prussianBlue),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 38,
                              color: isDark
                                  ? CoSpendColors.darkBorder
                                  : CoSpendColors.borderLight,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Allocated Limit',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark
                                          ? CoSpendColors.darkTextMuted
                                          : CoSpendColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    budgetPaisa > 0
                                        ? Money.format(budgetPaisa)
                                        : 'Not set',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? Colors.white
                                          : CoSpendColors.prussianBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (budgetPaisa > 0) ...[
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: CoSpendRadii.pillRadius,
                            child: LinearProgressIndicator(
                              value: (pct / 100.0).clamp(0.0, 1.0),
                              minHeight: 7,
                              backgroundColor: isDark
                                  ? CoSpendColors.darkBorder
                                  : const Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation(statusColor),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${pct.toStringAsFixed(0)}% consumed',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                              Text(
                                isOver
                                    ? 'Exceeded by ${Money.format(-remainingPaisa)}'
                                    : '${Money.format(remainingPaisa)} left',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? CoSpendColors.darkTextMuted
                                      : CoSpendColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Roommate allocations breakdown
                  Text(
                    'Roommate Quota Allocations',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (members.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No roommates in household yet.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? CoSpendColors.darkTextMuted
                              : CoSpendColors.textMuted,
                        ),
                      ),
                    )
                  else
                    ...members.map((member) {
                      final ctrl = memberControllers[member.id];
                      final memberRupees =
                          int.tryParse(ctrl?.text.trim() ?? '') ?? 0;
                      final memberPaisa = memberRupees * 100;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? CoSpendColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? CoSpendColors.darkBorder
                                : CoSpendColors.borderLight,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: CoSpendColors.jadeGreen
                                  .withValues(alpha: 0.15),
                              child: Text(
                                member.name.isEmpty
                                    ? '?'
                                    : member.name[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: CoSpendColors.jadeGreen,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                member.name,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : CoSpendColors.prussianBlue,
                                ),
                              ),
                            ),
                            Text(
                              memberPaisa > 0
                                  ? Money.format(memberPaisa)
                                  : 'Flexible',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: memberPaisa > 0
                                    ? (isDark
                                        ? Colors.white
                                        : CoSpendColors.prussianBlue)
                                    : (isDark
                                        ? CoSpendColors.darkTextMuted
                                        : CoSpendColors.textMuted),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 16),

                  // Actions
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push(Routes.expenses);
                    },
                    icon: const Icon(Icons.receipt_long_rounded, size: 18),
                    label: Text('View ${catItem.label} Expenses'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CoSpendColors.jadeGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
