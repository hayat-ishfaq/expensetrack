import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/utils/money.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final flatCategoryStatuses = ref.watch(categoryBudgetsStatusProvider);
    final myCategoryStatuses = ref.watch(myCategoryBudgetsStatusProvider);

    final budgetStatus = widget.budgetStatus;
    final pct = budgetStatus.percentage.clamp(0.0, 100.0);
    final isExceeded = budgetStatus.isExceeded;
    final isApproaching = budgetStatus.isApproaching;

    final barColor = isExceeded
        ? const Color(0xFFEF4444)
        : isApproaching
            ? const Color(0xFFF59E0B)
            : const Color(0xFF10B981);

    final statusTag = isExceeded
        ? 'Budget exceeded'
        : isApproaching
            ? 'Approaching limit'
            : 'On track';

    final tagBg = barColor.withValues(alpha: 0.15);

    final hasMyQuotas = myCategoryStatuses.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExceeded
              ? const Color(0xFFEF4444).withValues(alpha: 0.4)
              : scheme.outlineVariant.withValues(alpha: 0.4),
        ),
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: barColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.savings_rounded, size: 16, color: barColor),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'HOUSEHOLD BUDGET',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: tagBg,
                      borderRadius: BorderRadius.circular(20),
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
                    icon: const Icon(Icons.tune_rounded, size: 18),
                    tooltip: 'Adjust Budgets',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => context.push(Routes.categoryBudgets),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Total spending vs budget amounts
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                Money.format(budgetStatus.spentPaisa),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                ' / ${Money.format(budgetStatus.budgetPaisa)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                '${budgetStatus.percentage.toStringAsFixed(0)}% used',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Total Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct / 100.0,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 8),

          // Remaining / Over budget label
          Text(
            isExceeded
                ? 'Over budget by ${Money.format(-budgetStatus.remainingPaisa)}'
                : 'Remaining: ${Money.format(budgetStatus.remainingPaisa)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isExceeded ? const Color(0xFFEF4444) : scheme.onSurfaceVariant,
              fontWeight: isExceeded ? FontWeight.w700 : FontWeight.w500,
            ),
          ),

          // Category Budgets Breakdown Section
          if (flatCategoryStatuses.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(
              height: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 10),

            // Toggle Tabs: Flat Totals vs My Quotas
            Row(
              children: [
                InkWell(
                  onTap: () => setState(() => _showMyQuotas = false),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: !_showMyQuotas
                          ? scheme.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Flat Totals (${flatCategoryStatuses.length})',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: !_showMyQuotas
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                if (hasMyQuotas) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => setState(() => _showMyQuotas = true),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _showMyQuotas
                            ? scheme.primary.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'My Quotas (${myCategoryStatuses.length})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _showMyQuotas
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                InkWell(
                  onTap: () => context.push(Routes.categoryBudgets),
                  child: Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (!_showMyQuotas) ...[
              // Flat-wide category breakdown
              ...flatCategoryStatuses.map((catStatus) {
                final catPct = catStatus.percentage.clamp(0.0, 100.0);
                final catColor = catStatus.isExceeded
                    ? const Color(0xFFEF4444)
                    : catStatus.isApproaching
                        ? const Color(0xFFF59E0B)
                        : catStatus.color;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            catStatus.icon,
                            size: 15,
                            color: catStatus.color,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              catStatus.label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${Money.format(catStatus.spentPaisa)} / ${Money.format(catStatus.budgetPaisa)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${catStatus.percentage.toStringAsFixed(0)}%',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: catColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: catPct / 100.0,
                          minHeight: 5,
                          backgroundColor: scheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(catColor),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ] else ...[
              // Current user's individual quotas
              ...myCategoryStatuses.map((myStatus) {
                final myPct = myStatus.myPercentage.clamp(0.0, 100.0);
                final isOver = myStatus.isExceeded;
                final myColor = isOver
                    ? const Color(0xFFEF4444)
                    : myStatus.isApproaching
                        ? const Color(0xFFF59E0B)
                        : myStatus.color;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            myStatus.icon,
                            size: 15,
                            color: myStatus.color,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              myStatus.label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${Money.format(myStatus.mySpentPaisa)} / ${Money.format(myStatus.myBudgetPaisa)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isOver
                                  ? const Color(0xFFEF4444)
                                  : scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${myStatus.myPercentage.toStringAsFixed(0)}%',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: myColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: myPct / 100.0,
                          minHeight: 5,
                          backgroundColor: scheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(myColor),
                        ),
                      ),
                      if (isOver) ...[
                        const SizedBox(height: 2),
                        Text(
                          'You spent your full ${myStatus.label} budget (Over by ${Money.format(-myStatus.myRemainingPaisa)})',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFEF4444),
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
            InkWell(
              onTap: () => context.push(Routes.categoryBudgets),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline_rounded,
                      size: 16,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Set category budgets (Food, Bills, etc.)',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: scheme.primary,
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
