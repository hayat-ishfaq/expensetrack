import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/money.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../household/presentation/providers/household_providers.dart';
import '../providers/dashboard_providers.dart';

class BudgetProgressCard extends ConsumerStatefulWidget {
  const BudgetProgressCard({
    super.key,
    required this.budgetStatus,
  });

  final BudgetStatus budgetStatus;

  @override
  ConsumerState<BudgetProgressCard> createState() => _BudgetProgressCardState();
}

class _BudgetProgressCardState extends ConsumerState<BudgetProgressCard> {
  bool _showMyQuotas = false;

  Color _progressColorFor(double pct, bool isExceeded) {
    if (isExceeded || pct >= 100.0) return CoSpendColors.alertRed;
    if (pct >= 80.0) return CoSpendColors.warningAmber;
    return CoSpendColors.jadeGreen;
  }

  @override
  Widget build(BuildContext context) {
    final household = ref.watch(currentHouseholdProvider).value;
    final session = ref.watch(sessionProvider).value;
    final currentUserId = session?.user?.id ?? '';
    final isOwner = household != null &&
        (household.ownerId.isEmpty || household.ownerId == currentUserId);

    final flatCategoryStatuses = ref.watch(categoryBudgetsStatusProvider);
    final myCategoryStatuses = ref.watch(myCategoryBudgetsStatusProvider);

    final budgetStatus = widget.budgetStatus;
    final pct = budgetStatus.percentage.clamp(0.0, 100.0);
    final isExceeded = budgetStatus.isExceeded;
    final isApproaching = budgetStatus.isApproaching;

    final barColor = _progressColorFor(budgetStatus.percentage, isExceeded);

    final statusTag = isExceeded
        ? 'Exceeded'
        : isApproaching
            ? 'Approaching limit'
            : 'On track';

    final hasMyQuotas = myCategoryStatuses.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: CoSpendRadii.cardRadius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A2542),
            Color(0xFF133863),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: CoSpendColors.prussianBlue.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 16,
                      color: CoSpendColors.jadeGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'HOUSEHOLD BUDGET',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: Color(0xFF93C5FD),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: barColor.withValues(alpha: 0.2),
                      borderRadius: CoSpendRadii.pillRadius,
                      border: Border.all(
                        color: barColor.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      statusTag,
                      style: TextStyle(
                        color: barColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(
                      isOwner ? Icons.tune_rounded : Icons.visibility_outlined,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    tooltip: isOwner
                        ? 'Adjust Budgets'
                        : 'View Category Budgets (Owner Managed)',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => context.push(Routes.categoryBudgets),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Total spending vs budget amounts
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                Money.format(budgetStatus.spentPaisa),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                ' / ${Money.format(budgetStatus.budgetPaisa)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              Text(
                '${budgetStatus.percentage.toStringAsFixed(0)}% used',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Animated Progress Bar
          ClipRRect(
            borderRadius: CoSpendRadii.pillRadius,
            child: Stack(
              children: [
                Container(
                  height: 8,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(begin: 0, end: pct / 100.0),
                  builder: (context, value, child) => FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: CoSpendRadii.pillRadius,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Remaining / Over budget label
          Text(
            isExceeded
                ? 'Over budget by ${Money.format(-budgetStatus.remainingPaisa)}'
                : 'Remaining: ${Money.format(budgetStatus.remainingPaisa)}',
            style: TextStyle(
              fontSize: 12,
              color: isExceeded ? CoSpendColors.alertRed : Colors.white.withValues(alpha: 0.8),
              fontWeight: isExceeded ? FontWeight.w700 : FontWeight.w500,
            ),
          ),

          // Category Budgets Breakdown Section
          if (flatCategoryStatuses.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(
              height: 1,
              color: Colors.white.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 12),

            // Toggle Tabs: Flat Totals vs My Quotas
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _showMyQuotas = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: !_showMyQuotas
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: CoSpendRadii.pillRadius,
                    ),
                    child: Text(
                      'Flat Totals (${flatCategoryStatuses.length})',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: !_showMyQuotas
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
                if (hasMyQuotas) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _showMyQuotas = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _showMyQuotas
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: CoSpendRadii.pillRadius,
                      ),
                      child: Text(
                        'My Quotas (${myCategoryStatuses.length})',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: _showMyQuotas
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                GestureDetector(
                  onTap: () => context.push(Routes.categoryBudgets),
                  child: const Text(
                    'Details →',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF93C5FD),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (!_showMyQuotas) ...[
              // Flat-wide category breakdown using single-hue progress system
              ...flatCategoryStatuses.map((catStatus) {
                final catPct = catStatus.percentage.clamp(0.0, 100.0);
                final rowColor = _progressColorFor(catStatus.percentage, catStatus.isExceeded);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            catStatus.icon,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              catStatus.label,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${Money.format(catStatus.spentPaisa)} / ${Money.format(catStatus.budgetPaisa)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.75),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${catStatus.percentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: rowColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: CoSpendRadii.pillRadius,
                        child: Stack(
                          children: [
                            Container(
                              height: 5,
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                            FractionallySizedBox(
                              widthFactor: catPct / 100.0,
                              child: Container(
                                height: 5,
                                decoration: BoxDecoration(
                                  color: rowColor,
                                  borderRadius: CoSpendRadii.pillRadius,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ] else ...[
              // Current user's individual quotas using single-hue progress system
              ...myCategoryStatuses.map((myStatus) {
                final myPct = myStatus.myPercentage.clamp(0.0, 100.0);
                final isOver = myStatus.isExceeded;
                final rowColor = _progressColorFor(myStatus.myPercentage, isOver);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            myStatus.icon,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              myStatus.label,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${Money.format(myStatus.mySpentPaisa)} / ${Money.format(myStatus.myBudgetPaisa)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isOver ? CoSpendColors.alertRed : Colors.white.withValues(alpha: 0.75),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${myStatus.myPercentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: rowColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: CoSpendRadii.pillRadius,
                        child: Stack(
                          children: [
                            Container(
                              height: 5,
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                            FractionallySizedBox(
                              widthFactor: myPct / 100.0,
                              child: Container(
                                height: 5,
                                decoration: BoxDecoration(
                                  color: rowColor,
                                  borderRadius: CoSpendRadii.pillRadius,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isOver) ...[
                        const SizedBox(height: 3),
                        Text(
                          'You spent your full ${myStatus.label} quota (Over by ${Money.format(-myStatus.myRemainingPaisa)})',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: CoSpendColors.alertRed,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ] else ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => context.push(Routes.categoryBudgets),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: CoSpendRadii.pillRadius,
                ),
                child: Row(
                  children: [
                    Icon(
                      isOwner ? Icons.add_circle_outline_rounded : Icons.visibility_outlined,
                      size: 15,
                      color: const Color(0xFF93C5FD),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOwner
                          ? 'Set category budgets (Food, Bills, etc.)'
                          : 'View category budgets & limits',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF93C5FD),
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Color(0xFF93C5FD),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
