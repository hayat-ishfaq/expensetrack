import 'package:flutter/material.dart';

import '../../../../core/utils/money.dart';
import '../../../expenses/domain/expense_category.dart';
import '../../domain/dashboard_stats.dart';

class CategoryBreakdownCard extends StatelessWidget {
  const CategoryBreakdownCard({
    super.key,
    required this.stats,
  });

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (stats.categoryBreakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = stats.totalSpendingPaisa;

    // Sort categories by highest spending descending
    final sortedEntries = stats.categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CATEGORY BREAKDOWN',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (stats.highestCategory != null)
                Text(
                  'Top: ${stats.highestCategory!.label}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: stats.highestCategory!.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Multi-color segmented distribution bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  for (final entry in sortedEntries)
                    Flexible(
                      flex: total > 0 ? (entry.value * 1000 ~/ total) : 0,
                      child: Container(color: entry.key.color),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Itemized Category Rows
          for (final entry in sortedEntries)
            _CategoryRow(
              category: entry.key,
              amountPaisa: entry.value,
              percentage: total > 0 ? (entry.value / total) * 100 : 0,
            ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.amountPaisa,
    required this.percentage,
  });

  final ExpenseCategory category;
  final int amountPaisa;
  final double percentage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(category.icon, size: 16, color: category.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.label,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  '${percentage.toStringAsFixed(0)}% of total',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            Money.format(amountPaisa),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
