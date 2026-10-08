import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/money.dart';
import '../../domain/dashboard_stats.dart';
import 'budget_category_item.dart';

String _monthName(int month) {
  const names = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  return (month >= 1 && month <= 12) ? names[month - 1] : '';
}

class SpendingTrendsSheet extends StatelessWidget {
  const SpendingTrendsSheet({
    super.key,
    required this.stats,
    required this.categoryItems,
    required this.totalBudgetPaisa,
    required this.totalSpentPaisa,
    required this.isDark,
  });

  final DashboardStats stats;
  final List<BudgetCategoryItem> categoryItems;
  final int totalBudgetPaisa;
  final int totalSpentPaisa;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final currentDay = now.day.clamp(1, daysInMonth);
    final remainingDays = math.max(1, daysInMonth - currentDay);

    final dailyAvgPaisa = (totalSpentPaisa / currentDay).round();
    final projectedSpendPaisa = dailyAvgPaisa * daysInMonth;
    final remainingBudgetPaisa = totalBudgetPaisa - totalSpentPaisa;
    final remainingDailyAllowancePaisa =
        remainingBudgetPaisa > 0 ? (remainingBudgetPaisa / remainingDays).round() : 0;

    int peakDay = 1;
    int peakPaisa = 0;
    for (final entry in stats.dailySpending.entries) {
      if (entry.value > peakPaisa) {
        peakPaisa = entry.value;
        peakDay = entry.key;
      }
    }

    final sortedCategories = List<BudgetCategoryItem>.from(categoryItems)
      ..sort((a, b) {
        final spentA = stats.categoryIdBreakdown[a.id] ?? 0;
        final spentB = stats.categoryIdBreakdown[b.id] ?? 0;
        return spentB.compareTo(spentA);
      });

    final maxDailyPaisa = stats.dailySpending.values.fold(0, math.max);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? CoSpendColors.darkCanvas : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Drag handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: CoSpendColors.jadeGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.trending_up_rounded,
                      color: CoSpendColors.jadeGreen,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spending Trends & Velocity',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_monthName(now.month)} ${now.year} Cycle Analysis',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white70 : CoSpendColors.textMuted,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  // ── Key Metrics Cards ────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          label: 'DAILY AVERAGE',
                          value: Money.format(dailyAvgPaisa),
                          subtitle: 'Through day $currentDay',
                          icon: Icons.calendar_today_rounded,
                          color: CoSpendColors.prussianBlue,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricCard(
                          label: 'PROJECTED SPEND',
                          value: Money.format(projectedSpendPaisa),
                          subtitle: 'By month end',
                          icon: Icons.speed_rounded,
                          color: CoSpendColors.jadeGreen,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          label: 'PEAK SPENDING DAY',
                          value: peakPaisa > 0 ? 'Day $peakDay' : 'No data',
                          subtitle: peakPaisa > 0 ? Money.format(peakPaisa) : 'Rs. 0',
                          icon: Icons.local_fire_department_rounded,
                          color: CoSpendColors.warningAmber,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricCard(
                          label: 'DAILY ALLOWANCE',
                          value: remainingBudgetPaisa > 0
                              ? Money.format(remainingDailyAllowancePaisa)
                              : 'Rs. 0',
                          subtitle: 'Next $remainingDays days',
                          icon: Icons.savings_outlined,
                          color: remainingBudgetPaisa > 0
                              ? CoSpendColors.jadeGreen
                              : CoSpendColors.alertRed,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Daily Spending Chart ─────────────────────────────────
                  Text(
                    'DAILY SPENDING FLOW',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 200,
                    padding: const EdgeInsets.fromLTRB(12, 16, 16, 10),
                    decoration: BoxDecoration(
                      color: isDark ? CoSpendColors.darkCard : CoSpendColors.white,
                      borderRadius: CoSpendRadii.cardRadius,
                      border: Border.all(
                        color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
                        width: 0.8,
                      ),
                    ),
                    child: stats.dailySpending.isEmpty
                        ? Center(
                            child: Text(
                              'No daily expenses recorded for this cycle yet.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? CoSpendColors.darkTextMuted
                                    : CoSpendColors.textMuted,
                              ),
                            ),
                          )
                        : BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: (maxDailyPaisa * 1.25).toDouble(),
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipColor: (_) => CoSpendColors.prussianBlue,
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    return BarTooltipItem(
                                      'Day ${group.x}\n${Money.format(rod.toY.toInt())}',
                                      const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final day = value.toInt();
                                      if (day == 1 ||
                                          day == 5 ||
                                          day == 10 ||
                                          day == 15 ||
                                          day == 20 ||
                                          day == 25 ||
                                          day == daysInMonth) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            '$day',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isDark
                                                  ? CoSpendColors.darkTextMuted
                                                  : CoSpendColors.textMuted,
                                            ),
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: (maxDailyPaisa / 3).clamp(1.0, double.infinity),
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                  strokeWidth: 1,
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: [
                                for (var day = 1; day <= daysInMonth; day++)
                                  BarChartGroupData(
                                    x: day,
                                    barRods: [
                                      BarChartRodData(
                                        toY: (stats.dailySpending[day] ?? 0).toDouble(),
                                        color: (stats.dailySpending[day] ?? 0) == maxDailyPaisa &&
                                                maxDailyPaisa > 0
                                            ? CoSpendColors.jadeGreen
                                            : CoSpendColors.jadeGreen.withValues(alpha: 0.4),
                                        width: daysInMonth > 28 ? 5.5 : 7,
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(3),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),

                  // ── Category Spend Distribution ──────────────────────────
                  Text(
                    'CATEGORY SPEND DISTRIBUTION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...sortedCategories.map((item) {
                    final spent = stats.categoryIdBreakdown[item.id] ?? 0;
                    final sharePct = totalSpentPaisa > 0
                        ? ((spent / totalSpentPaisa) * 100).clamp(0.0, 100.0)
                        : 0.0;
                    if (spent <= 0 && totalSpentPaisa > 0) return const SizedBox.shrink();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? CoSpendColors.darkCard : CoSpendColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: item.color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(item.icon, size: 16, color: item.color),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                                  ),
                                ),
                              ),
                              Text(
                                Money.format(spent),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${sharePct.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? CoSpendColors.darkTextMuted
                                      : CoSpendColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: sharePct / 100.0,
                              minHeight: 5,
                              backgroundColor:
                                  isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                              valueColor: AlwaysStoppedAnimation<Color>(item.color),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? CoSpendColors.darkCard : CoSpendColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                ),
              ),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
              color: isDark ? Colors.white : CoSpendColors.prussianBlue,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
