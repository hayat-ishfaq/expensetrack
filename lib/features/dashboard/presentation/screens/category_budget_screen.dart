import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/errors/firebase_error_mapper.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/models/household.dart';
import '../../../../shared/models/household_member.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../expenses/domain/expense_category.dart';
import '../../../expenses/presentation/widgets/create_category_sheet.dart';
import '../../../household/presentation/providers/household_providers.dart';
import '../../domain/dashboard_stats.dart';
import '../providers/dashboard_providers.dart';

class _BudgetCategoryItem {
  const _BudgetCategoryItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    this.isCustom = false,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final bool isCustom;
}

class CategoryBudgetScreen extends ConsumerStatefulWidget {
  const CategoryBudgetScreen({super.key});

  @override
  ConsumerState<CategoryBudgetScreen> createState() =>
      _CategoryBudgetScreenState();
}

class _CategoryBudgetScreenState extends ConsumerState<CategoryBudgetScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, Map<String, TextEditingController>> _memberControllers = {};
  final Set<String> _expandedCategories = {};
  bool _initialized = false;

  List<_BudgetCategoryItem> _getCategoryItems(Household? household) {
    final list = <_BudgetCategoryItem>[];
    if (household != null && household.customCategories.isNotEmpty) {
      for (final custom in household.customCategories) {
        list.add(_BudgetCategoryItem(
          id: custom.id,
          label: custom.label,
          icon: custom.icon,
          color: custom.color,
          isCustom: true,
        ));
      }
    }
    for (final cat in ExpenseCategory.values) {
      list.add(_BudgetCategoryItem(
        id: cat.id,
        label: cat.label,
        icon: cat.icon,
        color: cat.color,
        isCustom: false,
      ));
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    for (final cat in ExpenseCategory.values) {
      _controllers[cat.id] = TextEditingController();
      _memberControllers[cat.id] = {};
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final m in _memberControllers.values) {
      for (final c in m.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  void _populateFromHousehold() {
    if (_initialized) return;
    final household = ref.read(currentHouseholdProvider).value;
    final members = ref.read(householdMembersProvider).value ?? const [];
    if (household == null) return;

    final items = _getCategoryItems(household);
    for (final item in items) {
      final paisa = household.categoryBudgetsPaisa[item.id] ?? 0;
      _controllers[item.id] ??= TextEditingController();
      if (paisa > 0) {
        final rupees = (paisa / 100).round();
        _controllers[item.id]!.text = rupees.toString();
      }

      _memberControllers[item.id] ??= {};
      for (final member in members) {
        final memberPaisa =
            household.getMemberCategoryBudget(item.id, member.id);
        var ctrl = _memberControllers[item.id]?[member.id];
        if (ctrl == null) {
          ctrl = TextEditingController(
            text:
                memberPaisa > 0 ? (memberPaisa / 100).round().toString() : '',
          );
          _memberControllers[item.id]![member.id] = ctrl;
        } else if (memberPaisa > 0) {
          ctrl.text = (memberPaisa / 100).round().toString();
        }
      }
    }
    _initialized = true;
  }

  int _calculateTotalBudgetPaisa() {
    int total = 0;
    for (final c in _controllers.values) {
      final val = int.tryParse(c.text.trim()) ?? 0;
      total += val * 100;
    }
    return total;
  }

  void _splitEqually(String catId, List<HouseholdMember> members) {
    final catRupees = int.tryParse(_controllers[catId]?.text.trim() ?? '') ?? 0;
    if (catRupees <= 0 || members.isEmpty) return;

    final sharePerMember = (catRupees / members.length).round();
    for (final member in members) {
      var ctrl = _memberControllers[catId]?[member.id];
      if (ctrl == null) {
        ctrl = TextEditingController();
        _memberControllers[catId]![member.id] = ctrl;
      }
      ctrl.text = sharePerMember.toString();
    }
    _expandedCategories.add(catId);
    setState(() {});
  }

  Future<void> _saveBudgets() async {
    final household = ref.read(currentHouseholdProvider).value;
    if (household == null) return;

    final session = ref.read(sessionProvider).value;
    final currentUserId = session?.user?.id ?? '';
    final isOwner =
        household.ownerId.isEmpty || household.ownerId == currentUserId;
    if (!isOwner) {
      showAppSnack(
        context,
        'Only the flat owner can adjust budgets.',
        error: true,
      );
      return;
    }

    final Map<String, int> categoryBudgetsPaisa = {};
    final Map<String, Map<String, int>> memberCategoryBudgetsPaisa = {};

    for (final entry in _controllers.entries) {
      final rupees = int.tryParse(entry.value.text.trim()) ?? 0;
      if (rupees > 0) {
        categoryBudgetsPaisa[entry.key] = rupees * 100;

        final memberMap = _memberControllers[entry.key];
        if (memberMap != null) {
          final userBudgets = <String, int>{};
          for (final mEntry in memberMap.entries) {
            final mRupees = int.tryParse(mEntry.value.text.trim()) ?? 0;
            if (mRupees > 0) {
              userBudgets[mEntry.key] = mRupees * 100;
            }
          }
          if (userBudgets.isNotEmpty) {
            memberCategoryBudgetsPaisa[entry.key] = userBudgets;
          }
        }
      }
    }

    try {
      await ref.read(householdActionsProvider.notifier).updateCategoryBudgets(
            householdId: household.id,
            categoryBudgetsPaisa: categoryBudgetsPaisa,
            memberCategoryBudgetsPaisa: memberCategoryBudgetsPaisa,
          );

      if (!mounted) return;
      showAppSnack(context, 'Budgets updated successfully');
    } catch (e) {
      if (!mounted) return;
      showAppSnack(context, FirebaseErrorMapper.messageFor(e));
    }
  }

  void _addAmount(String catId, int deltaRupees) {
    final c = _controllers[catId];
    if (c == null) return;
    final current = int.tryParse(c.text.trim()) ?? 0;
    final updated = (current + deltaRupees).clamp(0, 10000000);
    c.text = updated > 0 ? updated.toString() : '';
    setState(() {});
  }

  void _bulkAdjustPercent(int percent, List<_BudgetCategoryItem> items) {
    HapticFeedback.mediumImpact();
    int count = 0;
    for (final item in items) {
      final ctrl = _controllers[item.id];
      if (ctrl != null) {
        final current = int.tryParse(ctrl.text.trim()) ?? 0;
        if (current > 0) {
          final updated = ((current * (100 + percent)) / 100).round();
          ctrl.text = updated > 0 ? updated.toString() : '';
          count++;
        }
      }
    }
    setState(() {});
    if (mounted) {
      showAppSnack(
        context,
        percent > 0
            ? 'Increased $count category limits by +$percent%'
            : 'Decreased $count category limits by $percent%',
      );
    }
  }

  void _autoDistributeBudget(int targetRupees, List<_BudgetCategoryItem> items) {
    if (items.isEmpty || targetRupees <= 0) return;
    HapticFeedback.mediumImpact();
    final perCat = (targetRupees / items.length).round();
    for (final item in items) {
      _controllers[item.id] ??= TextEditingController();
      _controllers[item.id]!.text = perCat.toString();
    }
    setState(() {});
    if (mounted) {
      showAppSnack(
        context,
        'Auto-distributed Rs. $targetRupees across ${items.length} categories',
      );
    }
  }

  void _splitAllEqually(
    List<_BudgetCategoryItem> items,
    List<HouseholdMember> members,
  ) {
    if (members.isEmpty) return;
    HapticFeedback.mediumImpact();
    int splitCount = 0;
    for (final item in items) {
      final catRupees = int.tryParse(_controllers[item.id]?.text.trim() ?? '') ?? 0;
      if (catRupees > 0) {
        final share = (catRupees / members.length).round();
        for (final m in members) {
          _memberControllers[item.id] ??= {};
          var mCtrl = _memberControllers[item.id]?[m.id];
          if (mCtrl == null) {
            mCtrl = TextEditingController(text: share.toString());
            _memberControllers[item.id]![m.id] = mCtrl;
          } else {
            mCtrl.text = share.toString();
          }
        }
        splitCount++;
      }
    }
    setState(() {});
    if (mounted) {
      showAppSnack(
        context,
        'Equally split $splitCount active category budgets among ${members.length} roommates',
      );
    }
  }

  void _clearAllBudgets(List<_BudgetCategoryItem> items) {
    HapticFeedback.heavyImpact();
    for (final item in items) {
      _controllers[item.id]?.clear();
      final m = _memberControllers[item.id];
      if (m != null) {
        for (final c in m.values) {
          c.clear();
        }
      }
    }
    setState(() {});
    if (mounted) {
      showAppSnack(context, 'Cleared all category budgets');
    }
  }

  void _matchCurrentSpending(
    List<_BudgetCategoryItem> items,
    DashboardStats stats,
  ) {
    HapticFeedback.mediumImpact();
    int updatedCount = 0;
    for (final item in items) {
      final spentPaisa = stats.categoryIdBreakdown[item.id] ?? 0;
      if (spentPaisa > 0) {
        final spentRupees = (spentPaisa / 100).ceil();
        // Round up to nearest 500 or 1000
        final rounded = spentRupees <= 1000
            ? ((spentRupees + 99) ~/ 100) * 100
            : ((spentRupees + 499) ~/ 500) * 500;
        _controllers[item.id] ??= TextEditingController();
        _controllers[item.id]!.text = rounded.toString();
        updatedCount++;
      }
    }
    setState(() {});
    if (mounted) {
      showAppSnack(
        context,
        'Matched $updatedCount category limits to actual spending',
      );
    }
  }

  void _toggleExpandAll(List<_BudgetCategoryItem> categoryItems) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_expandedCategories.length == categoryItems.length) {
        _expandedCategories.clear();
      } else {
        _expandedCategories.clear();
        _expandedCategories.addAll(categoryItems.map((e) => e.id));
      }
    });
  }

  void _openSpendingTrendsSheet({
    required BuildContext context,
    required DashboardStats stats,
    required List<_BudgetCategoryItem> categoryItems,
    required int totalBudgetPaisa,
    required int totalSpentPaisa,
    required bool isDark,
  }) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SpendingTrendsSheet(
        stats: stats,
        categoryItems: categoryItems,
        totalBudgetPaisa: totalBudgetPaisa,
        totalSpentPaisa: totalSpentPaisa,
        isDark: isDark,
      ),
    );
  }

  void _openManageLimitsSheet({
    required BuildContext context,
    required bool isOwner,
    required bool isDark,
    required List<HouseholdMember> members,
    required List<_BudgetCategoryItem> categoryItems,
    required int totalBudgetPaisa,
  }) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ManageLimitsSheet(
        isOwner: isOwner,
        isDark: isDark,
        members: members,
        categoryItems: categoryItems,
        totalBudgetPaisa: totalBudgetPaisa,
        onSave: () async {
          Navigator.pop(ctx);
          await _saveBudgets();
        },
        onBulkAdjustPercent: (percent) {
          Navigator.pop(ctx);
          _bulkAdjustPercent(percent, categoryItems);
        },
        onAutoDistribute: (targetRupees) {
          Navigator.pop(ctx);
          _autoDistributeBudget(targetRupees, categoryItems);
        },
        onSplitAllEqually: () {
          Navigator.pop(ctx);
          _splitAllEqually(categoryItems, members);
        },
        onClearAll: () {
          Navigator.pop(ctx);
          _clearAllBudgets(categoryItems);
        },
        onMatchCurrentSpending: () {
          Navigator.pop(ctx);
          _matchCurrentSpending(categoryItems, ref.read(dashboardStatsProvider));
        },
      ),
    );
  }

  void _openBudgetGuideSheet({
    required BuildContext context,
    required bool isDark,
  }) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BudgetGuideSheet(isDark: isDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final household = ref.watch(currentHouseholdProvider).value;
    final members = ref.watch(householdMembersProvider).value ?? const [];
    final session = ref.watch(sessionProvider).value;
    final currentUser = ref.watch(currentUserProvider).value ?? session?.user;
    final currentUserId = currentUser?.id ?? '';
    final isOwner = household != null &&
        (household.ownerId == currentUserId || household.ownerId.isEmpty);

    ref.listen(currentHouseholdProvider, (prev, next) {
      if (!_initialized && next.value != null) {
        setState(_populateFromHousehold);
      }
    });

    if (!_initialized) {
      _populateFromHousehold();
    }

    final categoryItems = _getCategoryItems(household);

    for (final catItem in categoryItems) {
      _controllers[catItem.id] ??= TextEditingController();
      _memberControllers[catItem.id] ??= {};
      for (final member in members) {
        if (!_memberControllers[catItem.id]!.containsKey(member.id)) {
          final memberPaisa =
              household?.getMemberCategoryBudget(catItem.id, member.id) ?? 0;
          _memberControllers[catItem.id]![member.id] = TextEditingController(
            text:
                memberPaisa > 0 ? (memberPaisa / 100).round().toString() : '',
          );
        }
      }
    }

    final stats = ref.watch(dashboardStatsProvider);
    final isSaving = ref.watch(householdActionsProvider).isLoading;
    final totalBudgetPaisa = _calculateTotalBudgetPaisa();
    final totalSpentPaisa = stats.totalSpendingPaisa;
    final remainingPaisa = totalBudgetPaisa - totalSpentPaisa;
    final pct = totalBudgetPaisa > 0
        ? ((totalSpentPaisa / totalBudgetPaisa) * 100).clamp(0.0, 100.0)
        : 0.0;
    final isOverall = totalBudgetPaisa > 0 && totalSpentPaisa > totalBudgetPaisa;
    final isApproachingOverall =
        totalBudgetPaisa > 0 && pct >= 80.0 && !isOverall;

    final statusLabel = isOverall
        ? 'OVER BUDGET'
        : isApproachingOverall
            ? 'APPROACHING'
            : 'ON TRACK';
    final statusColor = isOverall
        ? CoSpendColors.alertRed
        : isApproachingOverall
            ? CoSpendColors.warningAmber
            : CoSpendColors.jadeGreen;

    // Find exceeded categories for budget alert
    final exceededCategories = categoryItems.where((item) {
      final budgetPaisa =
          (int.tryParse(_controllers[item.id]?.text.trim() ?? '') ?? 0) * 100;
      final spentPaisa = stats.categoryIdBreakdown[item.id] ?? 0;
      return budgetPaisa > 0 && spentPaisa > budgetPaisa;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? CoSpendColors.darkCanvas : CoSpendColors.canvas,
      appBar: AppBar(
        backgroundColor: isDark ? CoSpendColors.darkCanvas : CoSpendColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  size: 18,
                  color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                ),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          'BUDGETS HUB',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
            color: isDark ? Colors.white : CoSpendColors.prussianBlue,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: isDark ? Colors.white70 : CoSpendColors.textMuted,
              size: 22,
            ),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => context.push(Routes.profile),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: CoSpendColors.jadeGreen,
                    width: 2,
                  ),
                ),
                child: AppAvatar(
                  name: currentUser?.name ?? 'User',
                  photoUrl: currentUser?.photoUrl,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              children: [
                // ── Summary Card ───────────────────────────────────────────
                _SummaryCard(
                  totalBudgetPaisa: totalBudgetPaisa,
                  totalSpentPaisa: totalSpentPaisa,
                  remainingPaisa: remainingPaisa,
                  pct: pct,
                  statusLabel: statusLabel,
                  statusColor: statusColor,
                  isDark: isDark,
                ),
                const SizedBox(height: 14),

                // ── Action Buttons Row ─────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.trending_up_rounded,
                        label: 'Spending Trends',
                        isDark: isDark,
                        onTap: () => _openSpendingTrendsSheet(
                          context: context,
                          stats: stats,
                          categoryItems: categoryItems,
                          totalBudgetPaisa: totalBudgetPaisa,
                          totalSpentPaisa: totalSpentPaisa,
                          isDark: isDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.tune_rounded,
                        label: 'Manage Limits',
                        isDark: isDark,
                        isLoading: isSaving,
                        onTap: () => _openManageLimitsSheet(
                          context: context,
                          isOwner: isOwner,
                          isDark: isDark,
                          members: members,
                          categoryItems: categoryItems,
                          totalBudgetPaisa: totalBudgetPaisa,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _ActionButton(
                      icon: Icons.info_outline_rounded,
                      label: '',
                      isDark: isDark,
                      isIconOnly: true,
                      onTap: () => _openBudgetGuideSheet(
                        context: context,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Categories Header ──────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _toggleExpandAll(categoryItems),
                      child: Row(
                        children: [
                          Text(
                            _expandedCategories.length == categoryItems.length
                                ? 'Collapse All'
                                : 'See All',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: CoSpendColors.jadeGreen,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            _expandedCategories.length == categoryItems.length
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.arrow_forward_rounded,
                            size: 15,
                            color: CoSpendColors.jadeGreen,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Category Cards ─────────────────────────────────────────
                for (final catItem in categoryItems) ...[
                  _CategoryBudgetCard(
                    catItem: catItem,
                    controller: _controllers[catItem.id]!,
                    memberControllers: _memberControllers[catItem.id] ?? {},
                    members: members,
                    spentPaisa: stats.categoryIdBreakdown[catItem.id] ?? 0,
                    isOwner: isOwner,
                    isExpanded: _expandedCategories.contains(catItem.id),
                    isDark: isDark,
                    onToggleExpand: () {
                      setState(() {
                        if (_expandedCategories.contains(catItem.id)) {
                          _expandedCategories.remove(catItem.id);
                        } else {
                          _expandedCategories.add(catItem.id);
                        }
                      });
                    },
                    onAmountChanged: () => setState(() {}),
                    onAddAmount: (delta) => _addAmount(catItem.id, delta),
                    onSplitEqually: () =>
                        _splitEqually(catItem.id, members),
                  ),
                  const SizedBox(height: 10),
                ],

                // ── Add New Category Button ────────────────────────────────
                if (isOwner) ...[
                  GestureDetector(
                    onTap: () async {
                      final created = await CreateCategorySheet.show(context);
                      if (created != null && mounted) {
                        setState(() => _initialized = false);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark ? CoSpendColors.darkCard : CoSpendColors.white,
                        borderRadius: CoSpendRadii.cardRadius,
                        border: Border.all(
                          color: isDark
                              ? CoSpendColors.darkBorder
                              : CoSpendColors.borderLight,
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_circle_outline_rounded,
                            size: 20,
                            color: isDark
                                ? CoSpendColors.darkTextMuted
                                : CoSpendColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Add New Category',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? CoSpendColors.darkTextMuted
                                  : CoSpendColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Budget Alert Card ──────────────────────────────────────
                if (exceededCategories.isNotEmpty) ...[
                  _BudgetAlertCard(
                    exceededCategory: exceededCategories.first,
                    spentPaisa: stats.categoryIdBreakdown[exceededCategories.first.id] ?? 0,
                    budgetPaisa: (int.tryParse(
                                  _controllers[exceededCategories.first.id]
                                          ?.text
                                          .trim() ??
                                      '',
                                ) ??
                                0) *
                            100,
                    onResolve: () => _saveBudgets(),
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: CoSpendShadows.floating,
        ),
        child: FloatingActionButton(
          onPressed: () async {
            final created = await CreateCategorySheet.show(context);
            if (created != null && mounted) {
              setState(() => _initialized = false);
            }
          },
          backgroundColor: CoSpendColors.jadeGreen,
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary Card with Donut Chart
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.totalBudgetPaisa,
    required this.totalSpentPaisa,
    required this.remainingPaisa,
    required this.pct,
    required this.statusLabel,
    required this.statusColor,
    required this.isDark,
  });

  final int totalBudgetPaisa;
  final int totalSpentPaisa;
  final int remainingPaisa;
  final double pct;
  final String statusLabel;
  final Color statusColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthLabel =
        '${_monthName(now.month)} ${now.year} Budget Cycle';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? CoSpendColors.darkCard : CoSpendColors.white,
        borderRadius: CoSpendRadii.cardLargeRadius,
        border: Border.all(
          color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
          width: 0.8,
        ),
        boxShadow: isDark ? null : CoSpendShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row + status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Household\nSpending',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        height: 1.25,
                        color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      monthLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? CoSpendColors.darkTextMuted
                            : CoSpendColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: CoSpendRadii.pillRadius,
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      statusLabel == 'ON TRACK'
                          ? Icons.check_circle_rounded
                          : Icons.warning_amber_rounded,
                      size: 12,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Donut chart
          Center(
            child: SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(160, 160),
                    painter: _DonutPainter(
                      progress: pct / 100.0,
                      foregroundColor: statusColor,
                      backgroundColor: isDark
                          ? CoSpendColors.darkBorder
                          : const Color(0xFFEEF2F7),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${pct.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                        ),
                      ),
                      Text(
                        'SPENT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: isDark
                              ? CoSpendColors.darkTextMuted
                              : CoSpendColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Total spent / remaining row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'TOTAL SPENT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: isDark
                                ? CoSpendColors.darkTextMuted
                                : CoSpendColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Money.format(totalSpentPaisa),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'REMAINING',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: isDark
                              ? CoSpendColors.darkTextMuted
                              : CoSpendColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        totalBudgetPaisa > 0
                            ? Money.format(remainingPaisa.abs())
                            : 'No budget set',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: remainingPaisa < 0
                              ? CoSpendColors.alertRed
                              : (isDark
                                  ? Colors.white
                                  : CoSpendColors.prussianBlue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _monthName(int month) {
  const names = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  return names[(month - 1).clamp(0, 11)];
}

// ─────────────────────────────────────────────────────────────────────────────
// Donut Chart Painter
// ─────────────────────────────────────────────────────────────────────────────

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.progress,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final double progress;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 18.0;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = foregroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.foregroundColor != foregroundColor;
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Button
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isDark,
    this.onTap,
    this.isLoading = false,
    this.isIconOnly = false,
  });

  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isIconOnly;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isIconOnly ? 14 : 12,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: isDark ? CoSpendColors.darkCard : CoSpendColors.white,
          borderRadius: CoSpendRadii.cardRadius,
          border: Border.all(
            color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
            width: 0.8,
          ),
          boxShadow: isDark ? null : CoSpendShadows.cardSubtle,
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: CoSpendColors.jadeGreen,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isDark
                        ? CoSpendColors.darkTextMuted
                        : CoSpendColors.textMuted,
                  ),
                  if (!isIconOnly && label.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? CoSpendColors.darkTextMuted
                              : CoSpendColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category Budget Card
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryBudgetCard extends StatelessWidget {
  const _CategoryBudgetCard({
    required this.catItem,
    required this.controller,
    required this.memberControllers,
    required this.members,
    required this.spentPaisa,
    required this.isOwner,
    required this.isExpanded,
    required this.isDark,
    required this.onToggleExpand,
    required this.onAmountChanged,
    required this.onAddAmount,
    required this.onSplitEqually,
  });

  final _BudgetCategoryItem catItem;
  final TextEditingController controller;
  final Map<String, TextEditingController> memberControllers;
  final List<HouseholdMember> members;
  final int spentPaisa;
  final bool isOwner;
  final bool isExpanded;
  final bool isDark;
  final VoidCallback onToggleExpand;
  final VoidCallback onAmountChanged;
  final void Function(int delta) onAddAmount;
  final VoidCallback onSplitEqually;

  @override
  Widget build(BuildContext context) {
    final catBudgetRupees = int.tryParse(controller.text.trim()) ?? 0;
    final catBudgetPaisa = catBudgetRupees * 100;
    final isOver = catBudgetPaisa > 0 && spentPaisa > catBudgetPaisa;
    final isApproaching =
        catBudgetPaisa > 0 && !isOver && spentPaisa >= catBudgetPaisa * 0.8;

    final pct = catBudgetPaisa > 0
        ? (spentPaisa / catBudgetPaisa * 100).clamp(0.0, 100.0)
        : 0.0;
    final progressColor = isOver
        ? CoSpendColors.alertRed
        : isApproaching
            ? CoSpendColors.warningAmber
            : CoSpendColors.jadeGreen;

    final remaining = catBudgetPaisa - spentPaisa;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? CoSpendColors.darkCard : CoSpendColors.white,
        borderRadius: CoSpendRadii.cardRadius,
        border: Border.all(
          color: isOver
              ? CoSpendColors.alertRed.withValues(alpha: 0.3)
              : (isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight),
          width: isOver ? 1.2 : 0.8,
        ),
        boxShadow: isDark ? null : CoSpendShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: icon + name + amounts
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: catItem.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(catItem.icon, color: catItem.color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            catItem.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: isDark
                                  ? Colors.white
                                  : CoSpendColors.prussianBlue,
                            ),
                          ),
                          Text(
                            'Monthly Limit',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? CoSpendColors.darkTextMuted
                                  : CoSpendColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Amount column
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (isOwner)
                          SizedBox(
                            width: 120,
                            child: TextField(
                              controller: controller,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: isDark
                                    ? Colors.white
                                    : CoSpendColors.prussianBlue,
                              ),
                              decoration: InputDecoration(
                                prefixText: 'Rs. ',
                                prefixStyle: TextStyle(
                                  color: isDark
                                      ? CoSpendColors.darkTextMuted
                                      : CoSpendColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                hintText: '0',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? CoSpendColors.darkCanvas
                                    : const Color(0xFFF7F8FA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? CoSpendColors.darkBorder
                                        : const Color(0x1F0A2542),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: CoSpendColors.jadeGreen,
                                    width: 1.5,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? CoSpendColors.darkBorder
                                        : const Color(0x1F0A2542),
                                  ),
                                ),
                              ),
                              onChanged: (_) => onAmountChanged(),
                            ),
                          )
                        else ...[
                          Text(
                            catBudgetPaisa > 0
                                ? Money.format(spentPaisa)
                                : Money.format(spentPaisa),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              letterSpacing: -0.3,
                              color: isOver
                                  ? CoSpendColors.alertRed
                                  : (isDark
                                      ? Colors.white
                                      : CoSpendColors.prussianBlue),
                            ),
                          ),
                          if (catBudgetPaisa > 0)
                            Text(
                              'of ${Money.format(catBudgetPaisa)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? CoSpendColors.darkTextMuted
                                    : CoSpendColors.textMuted,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ],
                ),

                if (isOwner) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _QuickChip(
                        label: '+1,000',
                        onTap: () => onAddAmount(1000),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 6),
                      _QuickChip(
                        label: '+5,000',
                        onTap: () => onAddAmount(5000),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 6),
                      _QuickChip(
                        label: '+10,000',
                        onTap: () => onAddAmount(10000),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],

                if (catBudgetPaisa > 0) ...[
                  const SizedBox(height: 12),
                  // Progress bar
                  ClipRRect(
                    borderRadius: CoSpendRadii.pillRadius,
                    child: Stack(
                      children: [
                        Container(
                          height: 7,
                          color: isDark
                              ? CoSpendColors.darkBorder
                              : const Color(0xFFEEF2F7),
                        ),
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          tween: Tween<double>(begin: 0, end: pct / 100.0),
                          builder: (context, value, _) => FractionallySizedBox(
                            widthFactor: value,
                            child: Container(
                              height: 7,
                              decoration: BoxDecoration(
                                color: progressColor,
                                borderRadius: CoSpendRadii.pillRadius,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isOver
                            ? 'OVER BUDGET'
                            : '${pct.toStringAsFixed(0)}% CONSUMED',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          color: progressColor,
                        ),
                      ),
                      Text(
                        isOver
                            ? '+${Money.format(-remaining)}'
                            : '${Money.format(remaining)} LEFT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isOver
                              ? CoSpendColors.alertRed
                              : (isDark
                                  ? CoSpendColors.darkTextMuted
                                  : CoSpendColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ],

                // Member quotas expand section
                if (isOwner && members.isNotEmpty && catBudgetPaisa > 0) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onToggleExpand,
                    child: Row(
                      children: [
                        Text(
                          isExpanded
                              ? 'Hide member quotas'
                              : 'Set member quotas',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: CoSpendColors.jadeGreen,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: CoSpendColors.jadeGreen,
                        ),
                      ],
                    ),
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: 10),
                    ...members.map((member) {
                      final ctrl =
                          memberControllers[member.id] ??
                              TextEditingController();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor:
                                  CoSpendColors.jadeGreen.withValues(alpha: 0.2),
                              child: Text(
                                member.name.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: CoSpendColors.jadeGreen,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                member.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : CoSpendColors.prussianBlue,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 110,
                              child: TextField(
                                controller: ctrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white
                                      : CoSpendColors.prussianBlue,
                                ),
                                decoration: InputDecoration(
                                  prefixText: 'Rs. ',
                                  prefixStyle: TextStyle(
                                    color: isDark
                                        ? CoSpendColors.darkTextMuted
                                        : CoSpendColors.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  hintText: '0',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? CoSpendColors.darkCanvas
                                      : const Color(0xFFF7F8FA),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: isDark
                                          ? CoSpendColors.darkBorder
                                          : const Color(0x1F0A2542),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: CoSpendColors.jadeGreen,
                                      width: 1.5,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: isDark
                                          ? CoSpendColors.darkBorder
                                          : const Color(0x1F0A2542),
                                    ),
                                  ),
                                ),
                                onChanged: (_) => onAmountChanged(),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    TextButton.icon(
                      onPressed: onSplitEqually,
                      icon: const Icon(
                        Icons.call_split_rounded,
                        size: 16,
                        color: CoSpendColors.jadeGreen,
                      ),
                      label: const Text(
                        'Split equally',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: CoSpendColors.jadeGreen,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Amount Chip
// ─────────────────────────────────────────────────────────────────────────────

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  final String label;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: CoSpendColors.jadeGreen.withValues(alpha: 0.1),
          borderRadius: CoSpendRadii.pillRadius,
          border: Border.all(
            color: CoSpendColors.jadeGreen.withValues(alpha: 0.25),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: CoSpendColors.jadeGreen,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Budget Alert Card
// ─────────────────────────────────────────────────────────────────────────────

class _BudgetAlertCard extends StatelessWidget {
  const _BudgetAlertCard({
    required this.exceededCategory,
    required this.spentPaisa,
    required this.budgetPaisa,
    required this.onResolve,
  });

  final _BudgetCategoryItem exceededCategory;
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

// ─────────────────────────────────────────────────────────────────────────────
// 1. Spending Trends Bottom Sheet with fl_chart Daily Trend
// ─────────────────────────────────────────────────────────────────────────────

class _SpendingTrendsSheet extends StatelessWidget {
  const _SpendingTrendsSheet({
    required this.stats,
    required this.categoryItems,
    required this.totalBudgetPaisa,
    required this.totalSpentPaisa,
    required this.isDark,
  });

  final DashboardStats stats;
  final List<_BudgetCategoryItem> categoryItems;
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

    final sortedCategories = List<_BudgetCategoryItem>.from(categoryItems)
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

// ─────────────────────────────────────────────────────────────────────────────
// 2. Manage Limits Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ManageLimitsSheet extends StatefulWidget {
  const _ManageLimitsSheet({
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
  final List<_BudgetCategoryItem> categoryItems;
  final int totalBudgetPaisa;
  final VoidCallback onSave;
  final ValueChanged<int> onBulkAdjustPercent;
  final ValueChanged<int> onAutoDistribute;
  final VoidCallback onSplitAllEqually;
  final VoidCallback onClearAll;
  final VoidCallback onMatchCurrentSpending;

  @override
  State<_ManageLimitsSheet> createState() => _ManageLimitsSheetState();
}

class _ManageLimitsSheetState extends State<_ManageLimitsSheet> {
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
                          style: TextStyle(
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

// ─────────────────────────────────────────────────────────────────────────────
// 3. Budget Guide Bottom Sheet (Info Button)
// ─────────────────────────────────────────────────────────────────────────────

class _BudgetGuideSheet extends StatelessWidget {
  const _BudgetGuideSheet({required this.isDark});

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

