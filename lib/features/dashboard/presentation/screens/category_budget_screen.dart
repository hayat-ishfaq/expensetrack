import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/firebase_error_mapper.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/models/household.dart';
import '../../../../shared/models/household_member.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../expenses/domain/expense_category.dart';
import '../../../expenses/presentation/widgets/create_category_sheet.dart';
import '../../../household/presentation/providers/household_providers.dart';
import '../providers/dashboard_providers.dart';

/// Representation of standard and custom category items for budgeting.
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

enum _BudgetHealthState {
  uncapped,
  healthy,
  approaching,
  exceeded,
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

      // Member controllers
      _memberControllers[item.id] ??= {};
      for (final member in members) {
        final memberPaisa =
            household.getMemberCategoryBudget(item.id, member.id);
        var ctrl = _memberControllers[item.id]?[member.id];
        if (ctrl == null) {
          ctrl = TextEditingController(
            text: memberPaisa > 0 ? (memberPaisa / 100).round().toString() : '',
          );
          _memberControllers[item.id]![member.id] = ctrl;
        } else if (memberPaisa > 0) {
          ctrl.text = (memberPaisa / 100).round().toString();
        }
      }
    }
    _initialized = true;
  }

  int _calculateTotalBudgetRupees() {
    int total = 0;
    for (final c in _controllers.values) {
      final val = int.tryParse(c.text.trim()) ?? 0;
      total += val;
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

  void _addAmount(String catId, int deltaRupees) {
    final c = _controllers[catId];
    if (c == null) return;
    final current = int.tryParse(c.text.trim()) ?? 0;
    final updated = (current + deltaRupees).clamp(0, 100000000);
    c.text = updated > 0 ? updated.toString() : '';
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
      showAppSnack(
        context,
        'Category and individual budgets updated successfully',
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      showAppSnack(context, FirebaseErrorMapper.messageFor(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final household = ref.watch(currentHouseholdProvider).value;
    final members = ref.watch(householdMembersProvider).value ?? const [];
    final session = ref.watch(sessionProvider).value;
    final currentUserId = session?.user?.id ?? '';
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

    // Ensure all joined members and categories have controllers
    for (final catItem in categoryItems) {
      _controllers[catItem.id] ??= TextEditingController();
      _memberControllers[catItem.id] ??= {};
      for (final member in members) {
        if (!_memberControllers[catItem.id]!.containsKey(member.id)) {
          final memberPaisa =
              household?.getMemberCategoryBudget(catItem.id, member.id) ?? 0;
          _memberControllers[catItem.id]![member.id] = TextEditingController(
            text: memberPaisa > 0 ? (memberPaisa / 100).round().toString() : '',
          );
        }
      }
    }

    final stats = ref.watch(dashboardStatsProvider);
    final isSaving = ref.watch(householdActionsProvider).isLoading;
    final totalBudgetRupees = _calculateTotalBudgetRupees();
    final totalSpentPaisa = stats.totalSpendingPaisa;
    final totalBudgetPaisa = totalBudgetRupees * 100;

    return Scaffold(
      backgroundColor: isDark ? CoSpendColors.darkCanvas : CoSpendColors.canvas,
      appBar: AppBar(
        title: const Text('Budgets & Allocations'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (isOwner) ...[
            IconButton(
              key: const Key('add_custom_category_btn'),
              onPressed: () async {
                final created = await CreateCategorySheet.show(context);
                if (created != null && mounted) {
                  setState(() {
                    _initialized = false;
                  });
                }
              },
              icon: const Icon(Icons.add_circle_outline_rounded),
              tooltip: 'Add Custom Category',
            ),
            TextButton(
              key: const Key('clear_all_budgets_btn'),
              onPressed: () {
                for (final c in _controllers.values) {
                  c.clear();
                }
                for (final m in _memberControllers.values) {
                  for (final c in m.values) {
                    c.clear();
                  }
                }
                setState(() {});
              },
              child: const Text('Clear All'),
            ),
            const SizedBox(width: 4),
          ],
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          isOwner ? 108 : 32,
        ),
        children: [
          // Total Monthly Target Hero Card
          _TotalBudgetHeroCard(
            totalBudgetPaisa: totalBudgetPaisa,
            totalSpentPaisa: totalSpentPaisa,
            configuredCategoriesCount: _controllers.values
                .where((c) => (int.tryParse(c.text.trim()) ?? 0) > 0)
                .length,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Member View-Only Explanatory Banner (Strictly Non-Disabled)
          if (!isOwner) ...[
            _MemberManagedBanner(isDark: isDark),
            const SizedBox(height: 16),
          ],

          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CATEGORY BREAKDOWN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: isDark
                      ? CoSpendColors.darkTextMuted
                      : CoSpendColors.textMuted,
                ),
              ),
              Text(
                '${categoryItems.length} Categories',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? CoSpendColors.darkTextSubtle
                      : CoSpendColors.textSubtle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Categories List
          ...categoryItems.map((catItem) {
            final controller = _controllers[catItem.id]!;
            final spentPaisa = stats.categoryIdBreakdown[catItem.id] ?? 0;
            final mySpentPaisa = stats.userCategoryIdBreakdown[catItem.id] ?? 0;
            final catBudgetRupees = int.tryParse(controller.text.trim()) ?? 0;
            final catBudgetPaisa = catBudgetRupees * 100;
            final isExpanded = _expandedCategories.contains(catItem.id);
            final memberMap = _memberControllers[catItem.id] ?? {};

            // Current member's specific allocated budget
            final myBudgetRupees =
                int.tryParse(memberMap[currentUserId]?.text.trim() ?? '') ?? 0;
            final myBudgetPaisa = myBudgetRupees * 100;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _CategoryBudgetCard(
                key: ValueKey('category_card_${catItem.id}'),
                catItem: catItem,
                controller: controller,
                spentPaisa: spentPaisa,
                catBudgetPaisa: catBudgetPaisa,
                catBudgetRupees: catBudgetRupees,
                mySpentPaisa: mySpentPaisa,
                myBudgetPaisa: myBudgetPaisa,
                members: members,
                memberControllers: memberMap,
                currentUserId: currentUserId,
                isOwner: isOwner,
                isExpanded: isExpanded,
                isDark: isDark,
                onToggleExpand: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedCategories.remove(catItem.id);
                    } else {
                      _expandedCategories.add(catItem.id);
                    }
                  });
                },
                onQuickAdd: (amount) => _addAmount(catItem.id, amount),
                onClearCategory: () {
                  controller.clear();
                  for (final c in memberMap.values) {
                    c.clear();
                  }
                  setState(() {});
                },
                onSplitEqually: () => _splitEqually(catItem.id, members),
                onAmountChanged: (_) => setState(() {}),
              ),
            );
          }),
        ],
      ),
      bottomSheet: isOwner
          ? Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: isDark ? CoSpendColors.darkCard : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? CoSpendColors.darkBorder
                        : CoSpendColors.borderLight,
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Semantics(
                  button: true,
                  label: isSaving ? 'Saving Budgets...' : 'Save Budgets & Allocations',
                  enabled: !isSaving,
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      key: const Key('save_budgets_button'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CoSpendColors.jadeGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      onPressed: isSaving ? null : _saveBudgets,
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_rounded, size: 20),
                      label: Text(
                        isSaving ? 'Saving Budgets...' : 'Save Budgets & Allocations',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

// =============================================================================
// TOTAL MONTHLY TARGET HERO CARD
// =============================================================================

class _TotalBudgetHeroCard extends StatelessWidget {
  const _TotalBudgetHeroCard({
    required this.totalBudgetPaisa,
    required this.totalSpentPaisa,
    required this.configuredCategoriesCount,
    required this.isDark,
  });

  final int totalBudgetPaisa;
  final int totalSpentPaisa;
  final int configuredCategoriesCount;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final hasBudget = totalBudgetPaisa > 0;
    final progress = hasBudget
        ? (totalSpentPaisa / totalBudgetPaisa).clamp(0.0, 1.0)
        : 0.0;
    final isExceeded = hasBudget && totalSpentPaisa > totalBudgetPaisa;
    final isApproaching =
        hasBudget && !isExceeded && (totalSpentPaisa >= totalBudgetPaisa * 0.80);
    final remainingPaisa = totalBudgetPaisa - totalSpentPaisa;

    final progressColor = isExceeded
        ? CoSpendColors.alertRed
        : (isApproaching
            ? CoSpendColors.warningAmber
            : CoSpendColors.jadeGreen);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [
                  Color(0xFF0F3156),
                  Color(0xFF0A223C),
                ]
              : const [
                  CoSpendColors.prussianBlue,
                  Color(0xFF133863),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: CoSpendShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'TOTAL MONTHLY BUDGET',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$configuredCategoriesCount active caps',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Total Budget Amount (dominant typography with flex safety)
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              hasBudget ? Money.format(totalBudgetPaisa) : 'Rs. 0 (Uncapped)',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.0,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Animated Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 8,
              width: double.infinity,
              color: Colors.white.withValues(alpha: 0.15),
              alignment: Alignment.centerLeft,
              child: AnimatedFractionallySizedBox(
                duration: CoSpendAnimations.medium,
                curve: CoSpendAnimations.curveDefault,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: progressColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Real-time comparison metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spent this month',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        Money.format(totalSpentPaisa),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isExceeded ? 'Exceeded by' : 'Remaining balance',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        hasBudget
                            ? Money.format(remainingPaisa.abs())
                            : 'No limit',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isExceeded
                              ? const Color(0xFFFF8B8B)
                              : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// MEMBER MANAGED EXPLANATORY BANNER
// =============================================================================

class _MemberManagedBanner extends StatelessWidget {
  const _MemberManagedBanner({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? CoSpendColors.prussianBlueMedium.withValues(alpha: 0.4)
            : const Color(0xFFF0F5FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? CoSpendColors.darkBorder
              : const Color(0x1F0A2542),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? CoSpendColors.prussianBlueLight
                  : CoSpendColors.prussianBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.admin_panel_settings_rounded,
              size: 20,
              color: isDark
                  ? Colors.white
                  : CoSpendColors.prussianBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Managed by household owner',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? CoSpendColors.darkTextPrimary
                        : CoSpendColors.prussianBlue,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Monthly caps and member quotas are configured by the flat owner. Below is your household\'s spending progress and your allocated share.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: isDark
                        ? CoSpendColors.darkTextMuted
                        : CoSpendColors.textMuted,
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

// =============================================================================
// CATEGORY BUDGET CARD
// =============================================================================

class _CategoryBudgetCard extends StatelessWidget {
  const _CategoryBudgetCard({
    super.key,
    required this.catItem,
    required this.controller,
    required this.spentPaisa,
    required this.catBudgetPaisa,
    required this.catBudgetRupees,
    required this.mySpentPaisa,
    required this.myBudgetPaisa,
    required this.members,
    required this.memberControllers,
    required this.currentUserId,
    required this.isOwner,
    required this.isExpanded,
    required this.isDark,
    required this.onToggleExpand,
    required this.onQuickAdd,
    required this.onClearCategory,
    required this.onSplitEqually,
    required this.onAmountChanged,
  });

  final _BudgetCategoryItem catItem;
  final TextEditingController controller;
  final int spentPaisa;
  final int catBudgetPaisa;
  final int catBudgetRupees;
  final int mySpentPaisa;
  final int myBudgetPaisa;
  final List<HouseholdMember> members;
  final Map<String, TextEditingController> memberControllers;
  final String currentUserId;
  final bool isOwner;
  final bool isExpanded;
  final bool isDark;
  final VoidCallback onToggleExpand;
  final ValueChanged<int> onQuickAdd;
  final VoidCallback onClearCategory;
  final VoidCallback onSplitEqually;
  final ValueChanged<String> onAmountChanged;

  _BudgetHealthState get _healthState {
    if (catBudgetPaisa <= 0) return _BudgetHealthState.uncapped;
    if (spentPaisa > catBudgetPaisa) return _BudgetHealthState.exceeded;
    if (spentPaisa >= (catBudgetPaisa * 0.80)) {
      return _BudgetHealthState.approaching;
    }
    return _BudgetHealthState.healthy;
  }

  @override
  Widget build(BuildContext context) {
    final health = _healthState;
    final hasBudget = catBudgetPaisa > 0;
    final progress = hasBudget
        ? (spentPaisa / catBudgetPaisa).clamp(0.0, 1.0)
        : 0.0;
    final remainingPaisa = catBudgetPaisa - spentPaisa;

    // Total allocated across members
    int totalMemberAllocatedRupees = 0;
    for (final ctrl in memberControllers.values) {
      totalMemberAllocatedRupees += int.tryParse(ctrl.text.trim()) ?? 0;
    }

    Color borderColor;
    if (health == _BudgetHealthState.exceeded) {
      borderColor = CoSpendColors.alertRed.withValues(alpha: 0.5);
    } else if (health == _BudgetHealthState.approaching) {
      borderColor = CoSpendColors.warningAmber.withValues(alpha: 0.4);
    } else if (hasBudget) {
      borderColor = CoSpendColors.jadeGreen.withValues(alpha: 0.3);
    } else {
      borderColor = isDark ? CoSpendColors.darkBorder : const Color(0x140A2542);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? CoSpendColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: health == _BudgetHealthState.exceeded ? 1.5 : 1.0,
        ),
        boxShadow: CoSpendShadows.softCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category Icon, Name, Custom Tag, Multi-attribute Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TintedIcon(
                icon: catItem.icon,
                color: catItem.color,
                size: 22,
                containerSize: 42,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            catItem.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: isDark
                                  ? CoSpendColors.darkTextPrimary
                                  : CoSpendColors.prussianBlue,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (catItem.isCustom) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: catItem.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'CUSTOM',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: catItem.color,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    // Multi-attribute Status Indicator
                    _BudgetStatusBadge(
                      state: health,
                      spentPaisa: spentPaisa,
                      budgetPaisa: catBudgetPaisa,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Owner Edit Input or Member Read-Only Amount
              if (isOwner)
                SizedBox(
                  width: 130,
                  child: Semantics(
                    label: '${catItem.label} monthly budget in Rupees',
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
                            ? CoSpendColors.darkTextPrimary
                            : CoSpendColors.prussianBlue,
                      ),
                      decoration: InputDecoration(
                        prefixText: 'Rs. ',
                        prefixStyle: TextStyle(
                          color: isDark
                              ? CoSpendColors.darkTextSubtle
                              : const Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        hintText: '0',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? CoSpendColors.darkCardElevated
                            : const Color(0xFFF7F8FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isDark
                                ? CoSpendColors.darkBorder
                                : const Color(0x1F0A2542),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: CoSpendColors.jadeGreen,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: onAmountChanged,
                    ),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      catBudgetRupees > 0
                          ? Money.format(catBudgetPaisa)
                          : 'Uncapped',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: catBudgetRupees > 0
                            ? (isDark
                                ? CoSpendColors.darkTextPrimary
                                : CoSpendColors.prussianBlue)
                            : (isDark
                                ? CoSpendColors.darkTextMuted
                                : const Color(0xFF9CA3AF)),
                      ),
                    ),
                    Text(
                      'monthly cap',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? CoSpendColors.darkTextMuted
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Animated Progress Bar
          Semantics(
            label: '${catItem.label} budget progress: ${(progress * 100).toStringAsFixed(0)}% used, ${health.name}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: 6,
                width: double.infinity,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0x140A2542),
                alignment: Alignment.centerLeft,
                child: AnimatedFractionallySizedBox(
                  duration: isReducedMotionEnabled(context)
                      ? Duration.zero
                      : CoSpendAnimations.medium,
                  curve: CoSpendAnimations.curveDefault,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: health == _BudgetHealthState.exceeded
                          ? CoSpendColors.alertRed
                          : (health == _BudgetHealthState.approaching
                              ? CoSpendColors.warningAmber
                              : CoSpendColors.jadeGreen),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Spending Metrics Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Flat spent: ${Money.format(spentPaisa)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: health == _BudgetHealthState.exceeded
                        ? CoSpendColors.alertRed
                        : (isDark
                            ? CoSpendColors.darkTextMuted
                            : const Color(0xFF6B7280)),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  hasBudget
                      ? (remainingPaisa >= 0
                          ? '${Money.format(remainingPaisa)} left'
                          : 'Exceeded by ${Money.format(remainingPaisa.abs())}')
                      : 'No limit set',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: health == _BudgetHealthState.exceeded
                        ? FontWeight.w700
                        : FontWeight.w600,
                    color: health == _BudgetHealthState.exceeded
                        ? CoSpendColors.alertRed
                        : (health == _BudgetHealthState.approaching
                            ? CoSpendColors.warningAmber
                            : (isDark
                                ? CoSpendColors.darkTextMuted
                                : const Color(0xFF6B7280))),
                  ),
                ),
              ),
            ],
          ),

          // Quick Increment Chips (Owner Only)
          if (isOwner) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _QuickChip(
                    label: '+1,000',
                    onTap: () => onQuickAdd(1000),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 6),
                  _QuickChip(
                    label: '+5,000',
                    onTap: () => onQuickAdd(5000),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 6),
                  _QuickChip(
                    label: '+10,000',
                    onTap: () => onQuickAdd(10000),
                    isDark: isDark,
                  ),
                  if (catBudgetRupees > 0) ...[
                    const SizedBox(width: 6),
                    _QuickChip(
                      label: '✕ Clear',
                      isDanger: true,
                      onTap: onClearCategory,
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Member View-Only: Personal Allocation Highlight Card
          if (!isOwner) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? CoSpendColors.darkCardElevated.withValues(alpha: 0.5)
                    : const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? CoSpendColors.darkBorder
                      : const Color(0x140A2542),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: CoSpendColors.jadeGreen.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      size: 16,
                      color: CoSpendColors.jadeGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Member Quota',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? CoSpendColors.darkTextMuted
                                : CoSpendColors.textMuted,
                          ),
                        ),
                        Text(
                          myBudgetPaisa > 0
                              ? Money.format(myBudgetPaisa)
                              : 'Shared flat pool',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? CoSpendColors.darkTextPrimary
                                : CoSpendColors.prussianBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Your spending',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? CoSpendColors.darkTextMuted
                              : CoSpendColors.textMuted,
                        ),
                      ),
                      Text(
                        Money.format(mySpentPaisa),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: myBudgetPaisa > 0 && mySpentPaisa > myBudgetPaisa
                              ? CoSpendColors.alertRed
                              : (isDark
                                  ? CoSpendColors.darkTextPrimary
                                  : CoSpendColors.prussianBlue),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Member Allocation Accordion Section (For Owner and Read-only for Members)
          if (catBudgetRupees > 0 && members.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: isDark
                  ? CoSpendColors.darkBorder
                  : const Color(0x140A2542),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: onToggleExpand,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: isDark
                          ? CoSpendColors.darkTextPrimary
                          : CoSpendColors.prussianBlue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Member Allocations',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? CoSpendColors.darkTextPrimary
                            : CoSpendColors.prussianBlue,
                      ),
                    ),
                    const Spacer(),
                    if (totalMemberAllocatedRupees > 0)
                      Text(
                        'Allocated: Rs. $totalMemberAllocatedRupees / $catBudgetRupees',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: totalMemberAllocatedRupees == catBudgetRupees
                              ? CoSpendColors.jadeGreen
                              : CoSpendColors.warningAmber,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            if (isExpanded) ...[
              const SizedBox(height: 8),
              if (isOwner && members.length > 1) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onSplitEqually,
                    icon: const Icon(
                      Icons.call_split_rounded,
                      size: 14,
                    ),
                    label: const Text('Divide Equally'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],

              // Flatmates breakdown rows
              ...members.map((member) {
                final mCtrl =
                    memberControllers[member.id] ?? TextEditingController();
                final isMe = member.id == currentUserId;
                final mSpent = isMe ? mySpentPaisa : 0;
                final mBudgetRupees = int.tryParse(mCtrl.text.trim()) ?? 0;
                final mBudgetPaisa = mBudgetRupees * 100;
                final mExceeded = mBudgetPaisa > 0 && mSpent > mBudgetPaisa;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: isDark
                            ? CoSpendColors.prussianBlueLight
                            : CoSpendColors.prussianBlue.withValues(alpha: 0.12),
                        child: Text(
                          member.name.isNotEmpty
                              ? member.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : CoSpendColors.prussianBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${member.name}${isMe ? ' (You)' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isMe
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isDark
                                    ? CoSpendColors.darkTextPrimary
                                    : CoSpendColors.prussianBlue,
                              ),
                            ),
                            if (isMe)
                              Text(
                                'Spent: ${Money.format(mySpentPaisa)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: mExceeded
                                      ? CoSpendColors.alertRed
                                      : (isDark
                                          ? CoSpendColors.darkTextMuted
                                          : const Color(0xFF6B7280)),
                                  fontWeight: mExceeded
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Owner has editable field, member has clean read-only amount
                      if (isOwner)
                        SizedBox(
                          width: 105,
                          child: TextField(
                            controller: mCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: isDark
                                  ? CoSpendColors.darkTextPrimary
                                  : CoSpendColors.prussianBlue,
                            ),
                            decoration: InputDecoration(
                              prefixText: 'Rs. ',
                              prefixStyle: TextStyle(
                                color: isDark
                                    ? CoSpendColors.darkTextSubtle
                                    : const Color(0xFF6B7280),
                                fontSize: 12,
                              ),
                              hintText: '0',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? CoSpendColors.darkCardElevated
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
                                  width: 2,
                                ),
                              ),
                            ),
                            onChanged: onAmountChanged,
                          ),
                        )
                      else
                        Text(
                          mBudgetRupees > 0
                              ? Money.format(mBudgetPaisa)
                              : 'Not allocated',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            color: mBudgetRupees > 0
                                ? (isDark
                                    ? CoSpendColors.darkTextPrimary
                                    : CoSpendColors.prussianBlue)
                                : (isDark
                                    ? CoSpendColors.darkTextMuted
                                    : const Color(0xFF9CA3AF)),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// MULTI-ATTRIBUTE STATUS BADGE (ICON + TEXT + COLOR)
// =============================================================================

class _BudgetStatusBadge extends StatelessWidget {
  const _BudgetStatusBadge({
    required this.state,
    required this.spentPaisa,
    required this.budgetPaisa,
    required this.isDark,
  });

  final _BudgetHealthState state;
  final int spentPaisa;
  final int budgetPaisa;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String label;
    Color color;
    Color bgColor;

    switch (state) {
      case _BudgetHealthState.uncapped:
        icon = Icons.all_inclusive_rounded;
        label = 'UNCAPPED';
        color = isDark ? CoSpendColors.darkTextMuted : const Color(0xFF64748B);
        bgColor = color.withValues(alpha: 0.12);
        break;

      case _BudgetHealthState.healthy:
        icon = Icons.check_circle_rounded;
        final pct = budgetPaisa > 0 ? (spentPaisa / budgetPaisa * 100).round() : 0;
        label = 'ON TRACK ($pct%)';
        color = CoSpendColors.jadeGreen;
        bgColor = CoSpendColors.jadeGreen.withValues(alpha: 0.12);
        break;

      case _BudgetHealthState.approaching:
        icon = Icons.warning_amber_rounded;
        final pct = budgetPaisa > 0 ? (spentPaisa / budgetPaisa * 100).round() : 0;
        label = 'APPROACHING ($pct%)';
        color = CoSpendColors.warningAmber;
        bgColor = CoSpendColors.warningAmber.withValues(alpha: 0.14);
        break;

      case _BudgetHealthState.exceeded:
        icon = Icons.error_outline_rounded;
        final excess = spentPaisa - budgetPaisa;
        label = 'EXCEEDED BY ${Money.format(excess)}';
        color = CoSpendColors.alertRed;
        bgColor = CoSpendColors.alertRed.withValues(alpha: 0.12);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 0.4,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// QUICK INCREMENT CHIP (FINTECH PILL)
// =============================================================================

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.onTap,
    required this.isDark,
    this.isDanger = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final textColor = isDanger
        ? CoSpendColors.alertRed
        : (isDark
            ? CoSpendColors.darkTextPrimary
            : CoSpendColors.prussianBlue);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDanger
              ? CoSpendColors.alertRed.withValues(alpha: 0.1)
              : (isDark
                  ? CoSpendColors.darkCardElevated
                  : const Color(0xFFF7F8FA)),
          border: Border.all(
            color: isDanger
                ? CoSpendColors.alertRed.withValues(alpha: 0.3)
                : (isDark
                    ? CoSpendColors.darkBorder
                    : const Color(0x1F0A2542)),
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
