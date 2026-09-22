import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/firebase_error_mapper.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/models/household.dart';
import '../../../../shared/models/household_member.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../expenses/domain/custom_category.dart';
import '../../../expenses/domain/expense_category.dart';
import '../../../expenses/presentation/widgets/create_category_sheet.dart';
import '../../../household/presentation/providers/household_providers.dart';
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

  Future<void> _saveBudgets() async {
    final household = ref.read(currentHouseholdProvider).value;
    if (household == null) return;

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
      showAppSnack(context, 'Category and individual budgets updated successfully');
      context.pop();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
      appBar: AppBar(
        title: const Text('Category Budgets'),
        actions: [
          if (isOwner) ...[
            IconButton(
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
          ],
        ],
      ),
      body: Column(
        children: [
          // Total Budget Summary Header Card
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primaryContainer,
                  scheme.surfaceContainerHigh,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL MONTHLY TARGET',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_controllers.values.where((c) => (int.tryParse(c.text.trim()) ?? 0) > 0).length} categories set',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  Money.format(totalBudgetPaisa),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  totalBudgetPaisa > 0
                      ? 'Spent this month: ${Money.format(totalSpentPaisa)} (${((totalSpentPaisa / totalBudgetPaisa) * 100).toStringAsFixed(0)}% used)'
                      : 'Set individual category limits below to establish your flat\'s total monthly spending cap.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (!isOwner) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 16, color: scheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Budgets are configured by the flat owner. You can view your allocated limits below.',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Category List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              itemCount: categoryItems.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final catItem = categoryItems[index];
                final controller = _controllers[catItem.id]!;
                final spentPaisa = stats.categoryIdBreakdown[catItem.id] ?? 0;
                final mySpentPaisa =
                    stats.userCategoryIdBreakdown[catItem.id] ?? 0;
                final catBudgetRupees =
                    int.tryParse(controller.text.trim()) ?? 0;
                final catBudgetPaisa = catBudgetRupees * 100;

                final isOver =
                    catBudgetPaisa > 0 && spentPaisa > catBudgetPaisa;

                final isExpanded = _expandedCategories.contains(catItem.id);

                // Compute total member allocation sum for this category
                int allocatedMemberRupees = 0;
                final memberMap = _memberControllers[catItem.id] ?? {};
                for (final ctrl in memberMap.values) {
                  allocatedMemberRupees += int.tryParse(ctrl.text.trim()) ?? 0;
                }

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isOver
                          ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                          : catBudgetPaisa > 0
                              ? scheme.primary.withValues(alpha: 0.3)
                              : scheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: catItem.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              catItem.icon,
                              size: 20,
                              color: catItem.color,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      catItem.label,
                                      style:
                                          theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (catItem.isCustom) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: catItem.color
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'CUSTOM',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: catItem.color,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  'Flat spent: ${Money.format(spentPaisa)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isOver
                                        ? const Color(0xFFEF4444)
                                        : scheme.onSurfaceVariant,
                                    fontWeight: isOver
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 140,
                            child: TextField(
                              controller: controller,
                              enabled: isOwner,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                              decoration: InputDecoration(
                                prefixText: 'Rs. ',
                                prefixStyle: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                hintText: '0',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                                filled: true,
                                fillColor: scheme.surfaceContainerHigh,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),

                      if (isOwner) ...[
                        const SizedBox(height: 8),
                        // Quick increment buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _QuickChip(
                              label: '+1,000',
                              onTap: () => _addAmount(catItem.id, 1000),
                            ),
                            const SizedBox(width: 6),
                            _QuickChip(
                              label: '+5,000',
                              onTap: () => _addAmount(catItem.id, 5000),
                            ),
                            const SizedBox(width: 6),
                            _QuickChip(
                              label: '+10,000',
                              onTap: () => _addAmount(catItem.id, 10000),
                            ),
                            if (catBudgetRupees > 0) ...[
                              const SizedBox(width: 6),
                              _QuickChip(
                                label: '✕',
                                isDanger: true,
                                onTap: () {
                                  controller.clear();
                                  for (final c in memberMap.values) {
                                    c.clear();
                                  }
                                  setState(() {});
                                },
                              ),
                            ],
                          ],
                        ),
                      ],

                      // Member budget allocation section
                      if (catBudgetRupees > 0 && members.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Divider(
                          height: 1,
                          color: scheme.outlineVariant.withValues(alpha: 0.25),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () {
                            setState(() {
                              if (isExpanded) {
                                _expandedCategories.remove(catItem.id);
                              } else {
                                _expandedCategories.add(catItem.id);
                              }
                            });
                          },
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
                                  color: scheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Member Division',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: scheme.primary,
                                  ),
                                ),
                                const Spacer(),
                                if (allocatedMemberRupees > 0)
                                  Text(
                                    'Allocated: Rs. $allocatedMemberRupees / $catBudgetRupees',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: allocatedMemberRupees == catBudgetRupees
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFF59E0B),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        if (isExpanded) ...[
                          const SizedBox(height: 6),
                          if (isOwner && members.length > 1) ...[
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () =>
                                    _splitEqually(catItem.id, members),
                                icon: const Icon(Icons.call_split_rounded,
                                    size: 14),
                                label: const Text('Divide Equally'),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  textStyle: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          ...members.map((member) {
                            final mCtrl = memberMap[member.id] ??
                                TextEditingController();
                            final isMe = member.id == currentUserId;
                            final mSpent = isMe ? mySpentPaisa : 0;
                            final mBudgetRupees =
                                int.tryParse(mCtrl.text.trim()) ?? 0;
                            final mBudgetPaisa = mBudgetRupees * 100;
                            final mExceeded =
                                mBudgetPaisa > 0 && mSpent > mBudgetPaisa;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor:
                                        scheme.primary.withValues(alpha: 0.15),
                                    child: Text(
                                      member.name.isNotEmpty
                                          ? member.name[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: scheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${member.name}${isMe ? ' (You)' : ''}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isMe
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                          ),
                                        ),
                                        if (isMe)
                                          Text(
                                            'Spent: ${Money.format(mySpentPaisa)}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: mExceeded
                                                  ? const Color(0xFFEF4444)
                                                  : scheme.onSurfaceVariant,
                                              fontWeight: mExceeded
                                                  ? FontWeight.w700
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 110,
                                    child: TextField(
                                      controller: mCtrl,
                                      enabled: isOwner,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      textAlign: TextAlign.end,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                      decoration: InputDecoration(
                                        prefixText: 'Rs. ',
                                        prefixStyle: TextStyle(
                                          color: scheme.onSurfaceVariant,
                                          fontSize: 12,
                                        ),
                                        hintText: '0',
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8,
                                        ),
                                        filled: true,
                                        fillColor:
                                            scheme.surfaceContainerHighest,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      onChanged: (_) => setState(() {}),
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
              },
            ),
          ),
        ],
      ),
      bottomSheet: isOwner
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
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
                        : const Icon(Icons.check_circle_outline_rounded),
                    label: Text(
                      isSaving ? 'Saving...' : 'Save Category & Member Budgets',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
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

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDanger
              ? const Color(0xFFEF4444).withValues(alpha: 0.12)
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDanger ? const Color(0xFFEF4444) : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
