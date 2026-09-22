import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/money.dart';
import '../../domain/dashboard_stats.dart';

class MonthlySpendingChart extends StatelessWidget {
  const MonthlySpendingChart({
    super.key,
    required this.stats,
    required this.selectedMonth,
  });

  final DashboardStats stats;
  final DateTime selectedMonth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (stats.dailySpending.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded, size: 36, color: scheme.outline),
            const SizedBox(height: 8),
            Text(
              'No spending trend yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final daysInMonth =
        DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;

    var maxPaisa = 1;
    for (final amount in stats.dailySpending.values) {
      maxPaisa = max(maxPaisa, amount);
    }

    final barGroups = <BarChartGroupData>[];
    for (var day = 1; day <= daysInMonth; day++) {
      final amount = stats.dailySpending[day] ?? 0;
      final isPeak = amount == maxPaisa && amount > 0;
      barGroups.add(
        BarChartGroupData(
          x: day,
          barRods: [
            BarChartRodData(
              toY: amount.toDouble(),
              color: isPeak
                  ? scheme.primary
                  : scheme.primary.withValues(alpha: 0.35),
              width: daysInMonth > 28 ? 6 : 8,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
                'SPENDING TREND',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (stats.highestSpendingDay != null)
                Text(
                  'Peak: Day ${stats.highestSpendingDay}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxPaisa * 1.15,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final day = value.toInt();
                        if (day == 1 ||
                            day == 5 ||
                            day == 10 ||
                            day == 15 ||
                            day == 20 ||
                            day == 25 ||
                            day == daysInMonth) {
                          return Text(
                            '$day',
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => scheme.inverseSurface,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final amount = rod.toY.toInt();
                      return BarTooltipItem(
                        'Day ${group.x}\n',
                        TextStyle(
                          color: scheme.onInverseSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                        children: [
                          TextSpan(
                            text: Money.format(amount),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
