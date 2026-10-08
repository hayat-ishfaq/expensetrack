import 'package:flutter/material.dart';

import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/models/household_member.dart';
import 'budget_category_item.dart';

class ManageLimitsSheet extends StatefulWidget {
  const ManageLimitsSheet({
    super.key,
    required this.isOwner,
    required this.isDark,
    required this.members,
    required this.categoryItems,
    required this.totalBudgetPaisa,
    required this.onSave,
    required this.onBulkAdjustPercent,
    required this.onAutoDistribute,
    required this.onSplitAllEqually,
    required this.onClearAll,
    required this.onMatchCurrentSpending,
  });

  final bool isOwner;
  final bool isDark;
  final List<HouseholdMember> members;
  final List<BudgetCategoryItem> categoryItems;
  final int totalBudgetPaisa;
  final VoidCallback onSave;
  final ValueChanged<int> onBulkAdjustPercent;
  final ValueChanged<int> onAutoDistribute;
  final VoidCallback onSplitAllEqually;
  final VoidCallback onClearAll;
  final VoidCallback onMatchCurrentSpending;

  @override
  State<ManageLimitsSheet> createState() => _ManageLimitsSheetState();
}

class _ManageLimitsSheetState extends State<ManageLimitsSheet> {
  final TextEditingController _targetBudgetController = TextEditingController();

  @override
  void dispose() {
    _targetBudgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: widget.isDark ? CoSpendColors.darkCanvas : Colors.white,
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
                  color: widget.isDark ? Colors.white24 : Colors.black12,
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
                      Icons.tune_rounded,
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
                          'Manage Budget Limits',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: widget.isDark ? Colors.white : CoSpendColors.prussianBlue,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total Budget: ${Money.format(widget.totalBudgetPaisa)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: CoSpendColors.jadeGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: widget.isDark ? Colors.white70 : CoSpendColors.textMuted,
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
                  if (!widget.isOwner) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CoSpendColors.warningAmber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: CoSpendColors.warningAmber.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lock_outline_rounded,
                            size: 18,
                            color: CoSpendColors.warningAmber,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Only flat owners can modify and save budget limits.',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: widget.isDark
                                    ? Colors.amber.shade200
                                    : CoSpendColors.prussianBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Save Limits Primary Action ────────────────────────────
                  if (widget.isOwner) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: widget.onSave,
                        style: FilledButton.styleFrom(
                          backgroundColor: CoSpendColors.jadeGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                        label: const Text(
                          'Save & Apply Limits',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Quick Percentage Adjustments ─────────────────────────
                  Text(
                    'QUICK BULK ADJUSTMENT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: widget.isDark
                          ? CoSpendColors.darkTextMuted
                          : CoSpendColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ManageLimitChip(
                        label: '+10%',
                        isDark: widget.isDark,
                        onTap: widget.isOwner ? () => widget.onBulkAdjustPercent(10) : null,
                      ),
                      _ManageLimitChip(
                        label: '+20%',
                        isDark: widget.isDark,
                        onTap: widget.isOwner ? () => widget.onBulkAdjustPercent(20) : null,
                      ),
                      _ManageLimitChip(
                        label: '+50%',
                        isDark: widget.isDark,
                        onTap: widget.isOwner ? () => widget.onBulkAdjustPercent(50) : null,
                      ),
                      _ManageLimitChip(
                        label: '-10%',
                        isDark: widget.isDark,
                        onTap: widget.isOwner ? () => widget.onBulkAdjustPercent(-10) : null,
                      ),
                      _ManageLimitChip(
                        label: '-25%',
                        isDark: widget.isDark,
                        onTap: widget.isOwner ? () => widget.onBulkAdjustPercent(-25) : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Auto-Distribute Total Budget ─────────────────────────
                  Text(
                    'AUTO-DISTRIBUTE TOTAL BUDGET',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: widget.isDark
                          ? CoSpendColors.darkTextMuted
                          : CoSpendColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: widget.isDark ? CoSpendColors.darkCard : CoSpendColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: widget.isDark
                            ? CoSpendColors.darkBorder
                            : CoSpendColors.borderLight,
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Evenly spread a monthly flat budget across all categories:',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: widget.isDark
                                ? CoSpendColors.darkTextMuted
                                : CoSpendColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _targetBudgetController,
                                keyboardType: TextInputType.number,
                                enabled: widget.isOwner,
                                decoration: InputDecoration(
                                  hintText: 'e.g. 50000',
                                  prefixText: 'Rs. ',
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            FilledButton(
                              onPressed: widget.isOwner
                                  ? () {
                                      final target =
                                          int.tryParse(_targetBudgetController.text.trim()) ?? 0;
                                      if (target > 0) {
                                        widget.onAutoDistribute(target);
                                      }
                                    }
                                  : null,
                              style: FilledButton.styleFrom(
                                backgroundColor: CoSpendColors.prussianBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Apply'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Roommate Split & Sync Actions ─────────────────────────
                  Text(
                    'ROOMMATE & SPENDING TOOLS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: widget.isDark
                          ? CoSpendColors.darkTextMuted
                          : CoSpendColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ActionTile(
                    icon: Icons.group_outlined,
                    title: 'Split All Limits Equally Among Roommates',
                    subtitle: 'Divide each category budget equally for all ${widget.members.length} members',
                    isDark: widget.isDark,
                    onTap: widget.isOwner ? widget.onSplitAllEqually : null,
                  ),
                  const SizedBox(height: 8),
                  _ActionTile(
                    icon: Icons.sync_rounded,
                    title: 'Match Actual Monthly Spending',
                    subtitle: 'Set category budgets to round up to current expenses',
                    isDark: widget.isDark,
                    onTap: widget.isOwner ? widget.onMatchCurrentSpending : null,
                  ),
                  const SizedBox(height: 8),
                  _ActionTile(
                    icon: Icons.delete_outline_rounded,
                    title: 'Clear All Limits',
                    subtitle: 'Reset all category and member budget numbers to 0',
                    isDark: widget.isDark,
                    isDestructive: true,
                    onTap: widget.isOwner
                        ? () {
                            showDialog<void>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Clear All Budgets?'),
                                content: const Text(
                                  'This will reset all category limits and member quotas to zero.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: CoSpendColors.alertRed,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      widget.onClearAll();
                                    },
                                    child: const Text('Clear All'),
                                  ),
                                ],
                              ),
                            );
                          }
                        : null,
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

class _ManageLimitChip extends StatelessWidget {
  const _ManageLimitChip({
    required this.label,
    required this.isDark,
    this.onTap,
  });

  final String label;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? CoSpendColors.darkCard : CoSpendColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: onTap != null
                ? (isDark ? Colors.white : CoSpendColors.prussianBlue)
                : Colors.grey,
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    this.isDestructive = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final bool isDestructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? CoSpendColors.alertRed
        : (isDark ? Colors.white : CoSpendColors.prussianBlue);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? CoSpendColors.darkCard : CoSpendColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDestructive
                    ? CoSpendColors.alertRed.withValues(alpha: 0.1)
                    : CoSpendColors.jadeGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isDestructive ? CoSpendColors.alertRed : CoSpendColors.jadeGreen,
              ),
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
                      color: onTap != null ? color : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
