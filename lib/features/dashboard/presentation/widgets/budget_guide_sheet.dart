import 'package:flutter/material.dart';

import '../../../../core/theme/design_system.dart';

class BudgetGuideSheet extends StatelessWidget {
  const BudgetGuideSheet({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
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
          children: [
            const SizedBox(height: 10),
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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: CoSpendColors.prussianBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: CoSpendColors.prussianBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How Budgets Work',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Limits, member quotas & health indicators',
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

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  Text(
                    'HEALTH INDICATOR THRESHOLDS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // On Track
                  _ThresholdCard(
                    status: 'ON TRACK',
                    range: '< 80% Spent',
                    description: 'Household spending is healthy and well below the planned target.',
                    color: CoSpendColors.jadeGreen,
                    icon: Icons.check_circle_rounded,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),

                  // Approaching
                  _ThresholdCard(
                    status: 'APPROACHING',
                    range: '80% – 99% Spent',
                    description: 'Caution zone. 80% or more of the budget has been reached. Alerts are displayed.',
                    color: CoSpendColors.warningAmber,
                    icon: Icons.warning_rounded,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),

                  // Over Budget
                  _ThresholdCard(
                    status: 'OVER BUDGET',
                    range: '100%+ Spent',
                    description: 'Exceeded. Spending has surpassed the target limit. Highlighted in red in reports.',
                    color: CoSpendColors.alertRed,
                    icon: Icons.error_rounded,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'KEY FEATURES & RULES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _GuideItem(
                    icon: Icons.category_rounded,
                    title: 'Category Limits',
                    description:
                        'Set monthly spending caps for individual categories like Rent, Food, Utilities, and custom categories.',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),

                  _GuideItem(
                    icon: Icons.group_rounded,
                    title: 'Member Quotas',
                    description:
                        'Flat owners can allocate custom or equal portions of a category budget to specific roommates.',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),

                  _GuideItem(
                    icon: Icons.autorenew_rounded,
                    title: 'Automatic Monthly Reset',
                    description:
                        'Budgets automatically renew on the 1st of each calendar month. Past spending is preserved in history.',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),

                  _GuideItem(
                    icon: Icons.admin_panel_settings_rounded,
                    title: 'Owner Permissions',
                    description:
                        'Only the flat owner can adjust and save budget limits, while all flatmates have real-time visibility.',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: CoSpendColors.jadeGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Got It',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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

class _ThresholdCard extends StatelessWidget {
  const _ThresholdCard({
    required this.status,
    required this.range,
    required this.description,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  final String status;
  final String range;
  final String description;
  final Color color;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? CoSpendColors.darkCard : CoSpendColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    Text(
                      range,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideItem extends StatelessWidget {
  const _GuideItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.isDark,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: CoSpendColors.jadeGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: CoSpendColors.jadeGreen),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
